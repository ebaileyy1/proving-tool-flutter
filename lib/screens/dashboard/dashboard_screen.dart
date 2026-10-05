import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/dashboard/widgets/active_filters_banner.dart';
import 'package:proving_tool/screens/dashboard/widgets/charts_row.dart';
import 'package:proving_tool/screens/dashboard/widgets/dashboard_app_bar.dart';
import 'package:proving_tool/screens/dashboard/widgets/filters_card.dart';
import 'package:proving_tool/screens/dashboard/widgets/insight_bar.dart';
import 'package:proving_tool/screens/dashboard/widgets/stat_cards_row.dart';
import 'package:proving_tool/screens/dashboard/widgets/trial_dates.dart';
import 'package:proving_tool/screens/dashboard/widgets/trial_trends.dart';
import 'package:proving_tool/screens/dashboard/widgets/trials_list_section.dart';
import 'package:proving_tool/screens/dashboard/widgets/upcoming_section.dart';
import 'package:proving_tool/screens/pdf/trial_pdf.dart';
import 'package:proving_tool/screens/trials/add_trial_screen.dart';
import 'package:proving_tool/screens/trials/view_trial_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/utils/dates.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/add_outcome_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _isSet(String? filter) => filter != null && filter != 'All';

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
  bool _isExportingPdfs = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedTerminal;
  String? _selectedSubArea;
  String? _selectedStatusFilter;
  String? _selectedTypeFilter;

  final List<String> _terminals = ['All', 'T1', 'T2', 'T3', 'T4', 'T5'];
  final Map<String, Color> _typeColors = {
    'Desktop': const Color(0xFF5C6BC0),
    'Dimensional': const Color(0xFF26A69A),
    'First of Type': const Color(0xFFEF5350),
    'Unit Trial': const Color(0xFFFFA726),
    'Basic Trial': const Color(0xFF66BB6A),
    'Advanced Trial': const Color(0xFFAB47BC),
    'Live Rehearsal': const Color(0xFF29B6F6),
    // Legacy types, so older trials still get a chart color.
    'Functional': const Color(0xFF5C6BC0),
    'Operational': const Color(0xFF26A69A),
    'Technical': const Color(0xFFEF5350),
  };

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
    _searchController.dispose();
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

  Future<void> _exportCsv() async {
    final rows = <List<dynamic>>[
      ['Name', 'Type', 'Terminal', 'Sub-Area', 'Status', 'Start Date', 'End Date'],
      for (final item in _fullyFilteredItems)
        [
          item.data['fullname'] ?? '',
          item.data['type_of_trial'] ?? '',
          item.data['terminal_of_trial'] ?? '',
          item.data['sub_area_of_trial'] ?? '',
          item.data['status_of_trial'] ?? '',
          item.data['date_of_start']?.toString().split('T').first ?? '',
          item.data['date_of_completion']?.toString().split('T').first ?? '',
        ],
    ];
    final bytes = Uint8List.fromList(utf8.encode(const CsvEncoder(addBom: true).convert(rows)));

    // Mobile saveFile writes the bytes itself. Desktop only returns a path, so we
    // write the file ourselves (passing bytes there throws on macOS).
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

      if (mounted) showMessage(context, 'Trials exported to CSV');
    } catch (e) {
      logError('Error exporting CSV', e);
      if (mounted) showMessage(context, 'Error exporting CSV: $e');
    }
  }

  // Trials still queued offline have no server id, so they're skipped.
  Future<void> _exportPdfs() async {
    final items = _fullyFilteredItems.where((item) => item.remoteId != null).toList();
    if (items.isEmpty) {
      showMessage(context, 'No synced trials to export in the current filter');
      return;
    }

    setState(() => _isExportingPdfs = true);
    try {
      final bundles = <TrialPdfBundle>[];
      for (final item in items) {
        final remoteId = item.remoteId!;
        final observations = await _supabase
            .from('observations_with_profiles')
            .select()
            .eq('topic_id', remoteId)
            .order('created_at', ascending: true);
        final files = await _supabase
            .from('files')
            .select()
            .eq('topic_id', remoteId)
            .order('uploaded_at', ascending: false);
        bundles.add(
          TrialPdfBundle(
            trial: item.data,
            observations: List<Map<String, dynamic>>.from(observations),
            files: List<Map<String, dynamic>>.from(files),
          ),
        );
      }
      await TrialPdf.generateBatch(trials: bundles, supabase: _supabase);
    } catch (e) {
      logError('Error exporting PDFs', e);
      if (mounted) showMessage(context, 'Error exporting PDFs: $e');
    } finally {
      if (mounted) setState(() => _isExportingPdfs = false);
    }
  }

  List<Map<String, dynamic>> get _allTrials => _allItems.map((item) => item.data).toList();

  List<TrialListItem> get _dateFilteredItems {
    return _allItems.where((item) {
      final trial = item.data;
      final createdAt = trial['created_at']?.toString();
      if (createdAt == null) return false;
      final date = DateTime.tryParse(createdAt);
      if (date == null) return false;

      if (_isSet(_selectedYear) && date.year.toString() != _selectedYear) {
        return false;
      }
      if (_isSet(_selectedMonth) && date.month != monthNames.indexOf(_selectedMonth!) + 1) {
        return false;
      }
      if (_isSet(_selectedTerminal) && trial['terminal_of_trial'] != _selectedTerminal) {
        return false;
      }
      if (_isSet(_selectedSubArea) && trial['sub_area_of_trial'] != _selectedSubArea) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _dateFilteredTrials =>
      _dateFilteredItems.map((item) => item.data).toList();

  List<String> get _subAreaOptions {
    final areas = _allTrials
        .where(
          (t) =>
              _selectedTerminal == null ||
              _selectedTerminal == 'All' ||
              t['terminal_of_trial'] == _selectedTerminal,
        )
        .map((t) => t['sub_area_of_trial']?.toString().trim())
        .where((a) => a != null && a.isNotEmpty)
        .map((a) => a!)
        .toSet()
        .toList();
    areas.sort();
    return ['All', ...areas];
  }

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

  List<String> get _years {
    final years = _allTrials
        .map((t) => DateTime.tryParse(t['created_at']?.toString() ?? '')?.year.toString())
        .whereType<String>()
        .toSet()
        .toList();
    years.sort();
    return ['All', ...years];
  }

  bool get _hasDateFilters =>
      _isSet(_selectedYear) ||
      _isSet(_selectedMonth) ||
      _isSet(_selectedTerminal) ||
      _isSet(_selectedSubArea);

  List<TrialListItem> get _dueItems => TrialDates.dueItems(_allItems);

  List<TrialListItem> get _upcomingItems => TrialDates.upcomingItems(_allItems);

  int get _overdueCount => TrialDates.overdueCount(_dueItems);

  List<String> get _upcomingTerminals => TrialDates.upcomingTerminals(_upcomingItems);

  @override
  Widget build(BuildContext context) {
    final filteredItems = _searchQuery.isEmpty
        ? _fullyFilteredItems
        : _fullyFilteredItems
              .where(
                (item) => (item.data['fullname']?.toString() ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    // Deltas compare the last 30 days to the 30 before, across all trials, so they
    // only show while the filters are at All.
    final now = DateTime.now();
    final currentWindowStart = now.subtract(const Duration(days: 30));
    final previousWindowStart = now.subtract(const Duration(days: 60));
    String? trendFor({String? status}) => TrialTrends.percentChangeLabel(
      TrialTrends.countInWindow(_allItems, currentWindowStart, now, status: status),
      TrialTrends.countInWindow(_allItems, previousWindowStart, currentWindowStart, status: status),
    );
    final showTrends = !_hasDateFilters;

    return Scaffold(
      appBar: buildDashboardAppBar(
        context,
        isExportingPdfs: _isExportingPdfs,
        onRefresh: _loadTrials,
        onExportCsv: _exportCsv,
        onExportPdfs: _exportPdfs,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Bottom padding keeps the FAB off the last card's badge.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _insightBar(),

                  UpcomingSection(
                    due: _dueItems,
                    upcoming: _upcomingItems,
                    onOpen: (item) => _openTrial(item, _repo.refresh),
                    onAddOutcome: _addOutcome,
                  ),

                  _filtersCard(),

                  const SizedBox(height: 12),

                  StatCardsRow(
                    total: _dateFilteredTrials.length,
                    statusCounts: TrialTrends.statusCounts(_dateFilteredTrials),
                    selectedStatus: _selectedStatusFilter,
                    totalTrend: showTrends ? trendFor() : null,
                    completedTrend: showTrends ? trendFor(status: 'Completed') : null,
                    failedTrend: showTrends ? trendFor(status: 'Failed') : null,
                    onStatusTap: (status) => setState(() {
                      _selectedStatusFilter = _selectedStatusFilter == status ? null : status;
                    }),
                  ),

                  const SizedBox(height: 12),

                  ChartsRow(
                    total: _dateFilteredTrials.length,
                    statusCounts: TrialTrends.statusCounts(_dateFilteredTrials),
                    typeCounts: TrialTrends.countsBy(
                      _dateFilteredTrials,
                      'type_of_trial',
                      'Unknown',
                    ),
                    terminalCounts: TrialTrends.countsBy(
                      _dateFilteredTrials,
                      'terminal_of_trial',
                      'Unknown',
                    ),
                    typeColors: _typeColors,
                    selectedStatus: _selectedStatusFilter,
                    selectedType: _selectedTypeFilter,
                    onStatusSelect: (status) => setState(() => _selectedStatusFilter = status),
                    onTypeSelect: (type) => setState(() => _selectedTypeFilter = type),
                  ),

                  const SizedBox(height: 16),

                  ActiveFiltersBanner(
                    statusFilter: _selectedStatusFilter,
                    typeFilter: _selectedTypeFilter,
                    onClear: () => setState(() {
                      _selectedStatusFilter = null;
                      _selectedTypeFilter = null;
                    }),
                  ),

                  TrialsListSection(
                    items: filteredItems,
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    onSearchChanged: (value) => setState(() => _searchQuery = value),
                    onSearchCleared: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    onOpen: (item) => _openTrial(item, _loadTrials),
                  ),
                ],
              ),
            ),
      floatingActionButton: _newTrialFab(),
    );
  }

  Future<void> _openTrial(TrialListItem item, VoidCallback onChanged) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ViewTrialScreen(item: item)));
    if (result == true) onChanged();
  }

  Future<void> _addOutcome(TrialListItem item) async {
    final saved = await showAddOutcomeSheet(context, item);
    if (saved == true) _repo.refresh();
  }

  Widget _insightBar() {
    final now = DateTime.now();
    return InsightBar(
      dueCount: _dueItems.length,
      overdueCount: _overdueCount,
      currentRate: TrialTrends.completionRateForWindow(
        _allItems,
        now.subtract(const Duration(days: 30)),
        now,
      ),
      previousRate: TrialTrends.completionRateForWindow(
        _allItems,
        now.subtract(const Duration(days: 60)),
        now.subtract(const Duration(days: 30)),
      ),
      weekCount: _upcomingItems.length,
      weekTerminals: _upcomingTerminals,
    );
  }

  Widget _filtersCard() {
    return FiltersCard(
      options: FilterOptions(
        years: _years,
        months: ['All', ...monthNames],
        terminals: _terminals,
        subAreas: _subAreaOptions,
      ),
      selection: FilterSelection(
        year: _selectedYear,
        month: _selectedMonth,
        terminal: _selectedTerminal,
        subArea: _selectedSubArea,
      ),
      showClear: _selectedStatusFilter != null || _selectedTypeFilter != null || _hasDateFilters,
      onYearChanged: (v) => setState(() => _selectedYear = v),
      onMonthChanged: (v) => setState(() => _selectedMonth = v),
      onTerminalChanged: (v) => setState(() {
        _selectedTerminal = v;
        // Sub-areas are terminal-scoped, so clear it when the terminal changes.
        _selectedSubArea = null;
      }),
      onSubAreaChanged: (v) => setState(() => _selectedSubArea = v),
      onClear: () => setState(() {
        _selectedYear = null;
        _selectedMonth = null;
        _selectedTerminal = null;
        _selectedSubArea = null;
        _selectedStatusFilter = null;
        _selectedTypeFilter = null;
      }),
    );
  }

  Widget _newTrialFab() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddTrialScreen()));
        if (result == true) _loadTrials();
      },
      icon: const Icon(Icons.add),
      label: const Text('New Trial'),
    );
  }
}
