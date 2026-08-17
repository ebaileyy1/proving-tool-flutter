import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/trials/add_trial_screen.dart';
import 'package:proving_tool/screens/trials/view_trial_screen.dart';
import 'package:proving_tool/screens/admin/admin_screen.dart';
import 'package:proving_tool/screens/profile/profile_screen.dart';
import 'package:proving_tool/screens/notifications/notifications_screen.dart';
import 'package:proving_tool/screens/sync/pending_uploads_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/widgets/add_outcome_sheet.dart';
import 'package:proving_tool/widgets/pending_sync_chip.dart';
import 'package:proving_tool/widgets/section_header.dart';
import 'package:proving_tool/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  late final TrialRepository _repo;
  bool _repoInitialized = false;
  List<TrialListItem> _allItems = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedTerminal;
  String? _selectedStatusFilter;
  String? _selectedTypeFilter;

  final List<String> _terminals = ['All', 'T1', 'T2', 'T3', 'T4', 'T5'];
  final List<String> _months = [
    'All', 'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August', 'September',
    'October', 'November', 'December'
  ];

  // Matches the colors the trial detail screen uses for the same statuses
  // (AppColors.success/error/warning), so a status looks identical
  // wherever it's shown.
  final Map<String, Color> _statusColors = {
    'Completed': AppColors.success,
    'In Progress': AppColors.lightNavy,
    'Pending': AppColors.warning,
    'Failed': AppColors.error,
  };

  final Map<String, Color> _typeColors = {
    'Desktop': const Color(0xFF5C6BC0),
    'Dimensional': const Color(0xFF26A69A),
    'First of Type': const Color(0xFFEF5350),
    'Unit Trial': const Color(0xFFFFA726),
    'Basic Trial': const Color(0xFF66BB6A),
    'Advanced Trial': const Color(0xFFAB47BC),
    'Live Rehearsal': const Color(0xFF29B6F6),
    // Kept so trials created before this list changed still render in
    // color on the chart instead of falling back to grey.
    'Functional': const Color(0xFF5C6BC0),
    'Operational': const Color(0xFF26A69A),
    'Technical': const Color(0xFFEF5350),
  };

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_repoInitialized) {
      _repoInitialized = true;
      _repo = AppServices.of(context).trialRepository;
      _allItems = _repo.trials.value;
      _repo.trials.addListener(_onTrialsChanged);
      _loadTrials();
    }
  }

  @override
  void dispose() {
    _repo.trials.removeListener(_onTrialsChanged);
    super.dispose();
  }

  void _onTrialsChanged() {
    if (mounted) setState(() => _allItems = _repo.trials.value);
  }

  Future<void> _loadTrials() async {
    setState(() => _isLoading = true);
    await _repo.refresh();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_read', false);
      setState(() => _unreadCount = (response as List).length);
    } catch (e) {
      logError('Error loading unread count', e);
    }
  }

  Future<void> _exportCsv() async {
    final rows = <List<dynamic>>[
      ['Name', 'Type', 'Terminal', 'Status', 'Start Date', 'End Date'],
      for (final item in _fullyFilteredItems)
        [
          item.data['fullname'] ?? '',
          item.data['type_of_trial'] ?? '',
          item.data['terminal_of_trial'] ?? '',
          item.data['status_of_trial'] ?? '',
          item.data['date_of_start']?.toString().split('T').first ?? '',
          item.data['date_of_completion']?.toString().split('T').first ?? '',
        ],
    ];
    final bytes = Uint8List.fromList(
      utf8.encode(const CsvEncoder(addBom: true).convert(rows)),
    );

    // file_picker's saveFile writes [bytes] for you on mobile (there's no
    // real filesystem path to write to there); on desktop it just returns
    // a chosen path and the caller has to write the file itself — passing
    // bytes there is unsupported (and throws on macOS).
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export trials as CSV',
        fileName: 'trials_export.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: isMobile ? bytes : null,
      );
      if (path == null) return;

      if (!isMobile) {
        await File(path).writeAsBytes(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trials exported to CSV')),
        );
      }
    } catch (e) {
      logError('Error exporting CSV', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting CSV: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _allTrials =>
      _allItems.map((item) => item.data).toList();

  List<TrialListItem> get _dateFilteredItems {
    return _allItems.where((item) {
      final trial = item.data;
      final createdAt = trial['created_at']?.toString();
      if (createdAt == null) return false;
      final date = DateTime.tryParse(createdAt);
      if (date == null) return false;

      if (_selectedYear != null && _selectedYear != 'All') {
        if (date.year.toString() != _selectedYear) return false;
      }
      if (_selectedMonth != null && _selectedMonth != 'All') {
        final monthIndex = _months.indexOf(_selectedMonth!);
        if (date.month != monthIndex) return false;
      }
      if (_selectedTerminal != null && _selectedTerminal != 'All') {
        if (trial['terminal_of_trial'] != _selectedTerminal) return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _dateFilteredTrials =>
      _dateFilteredItems.map((item) => item.data).toList();

  List<TrialListItem> get _fullyFilteredItems {
    return _dateFilteredItems.where((item) {
      final trial = item.data;
      if (_selectedStatusFilter != null) {
        if (trial['status_of_trial'] != _selectedStatusFilter) return false;
      }
      if (_selectedTypeFilter != null) {
        if (trial['type_of_trial'] != _selectedTypeFilter) return false;
      }
      return true;
    }).toList();
  }

  Map<String, int> get _statusCounts {
    final counts = <String, int>{
      'Completed': 0,
      'In Progress': 0,
      'Pending': 0,
      'Failed': 0,
    };
    for (final trial in _dateFilteredTrials) {
      final status = trial['status_of_trial']?.toString() ?? 'Pending';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get _typeCounts {
    final counts = <String, int>{};
    for (final trial in _dateFilteredTrials) {
      final type = trial['type_of_trial']?.toString() ?? 'Unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get _terminalCounts {
    final counts = <String, int>{};
    for (final trial in _dateFilteredTrials) {
      final terminal = trial['terminal_of_trial']?.toString() ?? 'Unknown';
      counts[terminal] = (counts[terminal] ?? 0) + 1;
    }
    return counts;
  }

  List<String> get _years {
    final years = _allTrials
        .map((t) => DateTime.tryParse(t['created_at']?.toString() ?? '')?.year.toString())
        .whereType<String>()
        .toSet()
        .toList();
    years.sort();
    return ['All', ...years];
  }

  static bool _isNotYetResolved(Map<String, dynamic> trial) {
    final status = trial['status_of_trial']?.toString();
    return status == 'Pending' || status == 'In Progress';
  }

  static DateTime? _startDateOnly(Map<String, dynamic> trial) {
    final date = DateTime.tryParse(trial['date_of_start']?.toString() ?? '');
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  static int _compareByStartDate(TrialListItem a, TrialListItem b) {
    return _startDateOnly(a.data)!.compareTo(_startDateOnly(b.data)!);
  }

  /// Trials due today or overdue: not yet marked Completed/Failed and
  /// their start date has already arrived. These are the ones that need
  /// an outcome logged.
  List<TrialListItem> get _dueItems {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final items = _allItems.where((item) {
      if (!_isNotYetResolved(item.data)) return false;
      final date = _startDateOnly(item.data);
      return date != null && !date.isAfter(todayDate);
    }).toList();
    items.sort(_compareByStartDate);
    return items;
  }

  /// Trials starting in the next 7 days (not counting today).
  List<TrialListItem> get _upcomingItems {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final windowEnd = todayDate.add(const Duration(days: 7));
    final items = _allItems.where((item) {
      if (!_isNotYetResolved(item.data)) return false;
      final date = _startDateOnly(item.data);
      return date != null && date.isAfter(todayDate) && !date.isAfter(windowEnd);
    }).toList();
    items.sort(_compareByStartDate);
    return items;
  }

  Widget _upcomingSection() {
    final due = _dueItems;
    final upcoming = _upcomingItems;
    if (due.isEmpty && upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (due.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('Today'),
                  const SizedBox(height: 12),
                  for (final item in due) _dueTrialTile(item),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (upcoming.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('This Week'),
                  const SizedBox(height: 12),
                  for (final item in upcoming) _upcomingTrialTile(item),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _dueTrialTile(TrialListItem item) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final date = _startDateOnly(item.data);
    final isOverdue = date != null && date.isBefore(todayDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.data['fullname']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _tag(isOverdue ? 'Overdue' : 'Today', isOverdue ? AppColors.error : AppColors.lightNavy),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.data['type_of_trial'] ?? ''} · ${item.data['terminal_of_trial'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.otherText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final saved = await showAddOutcomeSheet(context, item);
              if (saved == true) _repo.refresh();
            },
            child: const Text('Add Outcome'),
          ),
        ],
      ),
    );
  }

  Widget _upcomingTrialTile(TrialListItem item) {
    final date = _startDateOnly(item.data);
    final dateLabel = date == null ? '' : '${date.day}/${date.month}';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ViewTrialScreen(item: item)),
        );
        if (result == true) _repo.refresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.data['fullname']?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.navy),
              ),
            ),
            const SizedBox(width: 8),
            Text(dateLabel, style: const TextStyle(fontSize: 12, color: AppColors.otherText)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.otherText),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _fullyFilteredItems;
    final statusKeys = _statusCounts.keys.toList();
    final maxY = _statusCounts.values.isEmpty
        ? 1.0
        : _statusCounts.values.reduce((a, b) => a > b ? a : b).toDouble() + 1;
    // Trial counts are always whole numbers, so the axis should only ever
    // label whole numbers too — capped so it doesn't cram in a label per
    // count once totals get large.
    final yAxisInterval = maxY <= 10 ? 1.0 : (maxY / 10).ceilToDouble();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/abclogo.jpg', height: 32),
            const SizedBox(width: 10),
            const Text('Proving Tool'),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                  _loadUnreadCount();
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          ValueListenableBuilder<SyncSummary>(
            valueListenable: _repo.syncSummary,
            builder: (context, summary, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.cloud_sync),
                    tooltip: 'Pending uploads',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PendingUploadsScreen()),
                      );
                    },
                  ),
                  if (summary.totalQueued > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: summary.hasErrors ? AppColors.error : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          summary.totalQueued > 9 ? '9+' : summary.totalQueued.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrials,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export filtered trials as CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Trials due today/overdue and starting this week
                  _upcomingSection(),

                  // Filters
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedYear ?? 'All',
                                    decoration: const InputDecoration(
                                      labelText: 'Year',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                    onChanged: (v) => setState(() => _selectedYear = v),
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedMonth ?? 'All',
                                    decoration: const InputDecoration(
                                      labelText: 'Month',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                    onChanged: (v) => setState(() => _selectedMonth = v),
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedTerminal ?? 'All',
                                    decoration: const InputDecoration(
                                      labelText: 'Terminal',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: _terminals.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                    onChanged: (v) => setState(() => _selectedTerminal = v),
                                  ),
                                ),
                                if (_selectedStatusFilter != null || _selectedTypeFilter != null ||
                                    (_selectedYear != null && _selectedYear != 'All') ||
                                    (_selectedMonth != null && _selectedMonth != 'All') ||
                                    (_selectedTerminal != null && _selectedTerminal != 'All'))
                                  TextButton.icon(
                                    onPressed: () => setState(() {
                                      _selectedYear = null;
                                      _selectedMonth = null;
                                      _selectedTerminal = null;
                                      _selectedStatusFilter = null;
                                      _selectedTypeFilter = null;
                                    }),
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Clear all'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Summary cards
                  Row(
                    children: [
                      StatCard(
                        label: 'Total',
                        value: _dateFilteredTrials.length.toString(),
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 8),
                      for (final status in const [
                        'Completed',
                        'In Progress',
                        'Failed',
                        'Pending',
                      ]) ...[
                        StatCard(
                          label: status,
                          value: _statusCounts[status].toString(),
                          color: _statusColors[status]!,
                          isSelected: _selectedStatusFilter == status,
                          onTap: () => setState(() {
                            _selectedStatusFilter =
                                _selectedStatusFilter == status ? null : status;
                          }),
                        ),
                        if (status != 'Pending') const SizedBox(width: 8),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Charts row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status bar chart
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Trials by Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    if (_selectedStatusFilter != null) ...[
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(_selectedStatusFilter!),
                                        onDeleted: () => setState(() => _selectedStatusFilter = null),
                                        backgroundColor: _statusColors[_selectedStatusFilter]?.withValues(alpha: 0.2),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text('Tap a bar to filter trials', style: TextStyle(fontSize: 12, color: AppColors.otherText)),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 220,
                                  child: _dateFilteredTrials.isEmpty
                                      ? const Center(child: Text('No data'))
                                      : BarChart(
                                          BarChartData(
                                            alignment: BarChartAlignment.spaceAround,
                                            maxY: maxY,
                                            barTouchData: BarTouchData(
                                              enabled: true,
                                              touchCallback: (event, response) {
                                                if (event is FlTapUpEvent && response?.spot != null) {
                                                  final index = response!.spot!.touchedBarGroupIndex;
                                                  if (index >= 0 && index < statusKeys.length) {
                                                    final tapped = statusKeys[index];
                                                    setState(() {
                                                      _selectedStatusFilter = _selectedStatusFilter == tapped ? null : tapped;
                                                    });
                                                  }
                                                }
                                              },
                                            ),
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 28,
                                                  // Without a fixed interval, fl_chart picks a "nice"
                                                  // fractional step (e.g. 0.5) when the range is small, and
                                                  // truncating those to int for the label repeats digits
                                                  // (0, 0, 1, 1...).
                                                  interval: yAxisInterval,
                                                  getTitlesWidget: (value, meta) => Text(
                                                    value.toInt().toString(),
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    if (value.toInt() >= statusKeys.length) return const Text('');
                                                    return Padding(
                                                      padding: const EdgeInsets.only(top: 8),
                                                      child: Text(
                                                        statusKeys[value.toInt()],
                                                        style: const TextStyle(fontSize: 10),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            ),
                                            borderData: FlBorderData(show: false),
                                            barGroups: _statusCounts.entries.toList().asMap().entries.map((entry) {
                                              final index = entry.key;
                                              final status = entry.value.key;
                                              final count = entry.value.value;
                                              final isSelected = _selectedStatusFilter == status;
                                              return BarChartGroupData(
                                                x: index,
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: count.toDouble(),
                                                    color: (_statusColors[status] ?? AppColors.otherText).withValues(alpha: isSelected ? 1.0 : 0.7),
                                                    width: 40,
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                                    backDrawRodData: BackgroundBarChartRodData(
                                                      show: isSelected,
                                                      toY: maxY,
                                                      color: (_statusColors[status] ?? AppColors.otherText).withValues(alpha: 0.1),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Right column - pie chart + terminal
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            // Pie chart
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('By Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    const Text('Tap a slice to filter', style: TextStyle(fontSize: 12, color: AppColors.otherText)),
                                    const SizedBox(height: 12),
                                    _dateFilteredTrials.isEmpty
                                        ? const Text('No data')
                                        : SizedBox(
                                            height: 160,
                                            child: PieChart(
                                              PieChartData(
                                                pieTouchData: PieTouchData(
                                                  touchCallback: (event, response) {
                                                    if (event is FlTapUpEvent && response?.touchedSection != null) {
                                                      final index = response!.touchedSection!.touchedSectionIndex;
                                                      final types = _typeCounts.keys.toList();
                                                      if (index >= 0 && index < types.length) {
                                                        final tapped = types[index];
                                                        setState(() {
                                                          _selectedTypeFilter = _selectedTypeFilter == tapped ? null : tapped;
                                                        });
                                                      }
                                                    }
                                                  },
                                                ),
                                                sections: _typeCounts.entries.toList().asMap().entries.map((entry) {
                                                  final type = entry.value.key;
                                                  final count = entry.value.value;
                                                  final isSelected = _selectedTypeFilter == type;
                                                  final color = _typeColors[type] ?? AppColors.otherText;
                                                  return PieChartSectionData(
                                                    value: count.toDouble(),
                                                    title: count.toString(),
                                                    color: color.withValues(alpha: isSelected ? 1.0 : 0.7),
                                                    radius: isSelected ? 70 : 60,
                                                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                                  );
                                                }).toList(),
                                                sectionsSpace: 2,
                                              ),
                                            ),
                                          ),
                                    const SizedBox(height: 8),
                                    ..._typeCounts.entries.map((entry) => GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedTypeFilter = _selectedTypeFilter == entry.key ? null : entry.key;
                                      }),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: _typeColors[entry.key] ?? AppColors.otherText,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              entry.key,
                                              style: TextStyle(
                                                fontWeight: _selectedTypeFilter == entry.key ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Terminal breakdown
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('By Terminal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    _dateFilteredTrials.isEmpty
                                        ? const Text('No data')
                                        : Column(
                                            children: _terminalCounts.entries.map((entry) {
                                              final total = _dateFilteredTrials.length;
                                              final percent = total == 0 ? 0.0 : entry.value / total;
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 10),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                        Text('${entry.value} (${(percent * 100).toStringAsFixed(0)}%)'),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: LinearProgressIndicator(
                                                        value: percent,
                                                        minHeight: 8,
                                                        backgroundColor: AppColors.subBackground,
                                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Active filters banner
                  if (_selectedStatusFilter != null || _selectedTypeFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text(
                            'Showing: ${[
                              ?_selectedStatusFilter,
                              ?_selectedTypeFilter,
                            ].join(' + ')} trials',
                            style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedStatusFilter = null;
                              _selectedTypeFilter = null;
                            }),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),

                  // Trials list
                  const Text('Trials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  filteredItems.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No trials match the selected filters')),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final trial = item.data;
                            final status = trial['status_of_trial']?.toString() ?? 'Pending';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _statusColors[status] ?? AppColors.otherText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(
                                  trial['fullname']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${trial['type_of_trial'] ?? ''} · ${trial['terminal_of_trial'] ?? ''} · $status',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (item.isPending) ...[
                                      PendingSyncChip(hasError: item.hasSyncError),
                                      const SizedBox(width: 8),
                                    ],
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ViewTrialScreen(item: item),
                                    ),
                                  );
                                  if (result == true) _loadTrials();
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTrialScreen()),
          );
          if (result == true) _loadTrials();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

}