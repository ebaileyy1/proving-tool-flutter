import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/dashboard/widgets/terminal_breakdown.dart';
import 'package:proving_tool/screens/dashboard/widgets/trial_trends.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/dates.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/section_card.dart';
import 'package:proving_tool/widgets/status_badge.dart';

const _titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
const _subtitleStyle = TextStyle(fontSize: 12, color: AppColors.otherText);

class _MonthBucket {
  const _MonthBucket({required this.label, required this.statusCounts});

  final String label;
  final Map<String, int> statusCounts;

  int get total => statusCounts.values.fold(0, (a, b) => a + b);

  // Null when nothing resolved, so the trend line skips it instead of showing 0%.
  double? get completionRate =>
      TrialTrends.completionRate(statusCounts['Completed'] ?? 0, statusCounts['Failed'] ?? 0);
}

/// Trends over time: monthly volume, completion rate and all-time breakdowns.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final TrialRepository _repo;
  bool _repoInitialized = false;
  List<TrialListItem> _allItems = [];
  bool _isLoading = true;

  static const _monthsToShow = 6;

  final Map<String, Color> _typeColors = {
    'Desktop': const Color(0xFF5C6BC0),
    'Dimensional': const Color(0xFF26A69A),
    'First of Type': const Color(0xFFEF5350),
    'Unit Trial': const Color(0xFFFFA726),
    'Basic Trial': const Color(0xFF66BB6A),
    'Advanced Trial': const Color(0xFFAB47BC),
    'Live Rehearsal': const Color(0xFF29B6F6),
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

  List<Map<String, dynamic>> get _allTrials => _allItems.map((i) => i.data).toList();

  List<_MonthBucket> get _monthlyBuckets {
    final now = DateTime.now();
    final months = <_MonthBucket>[];
    for (var i = _monthsToShow - 1; i >= 0; i--) {
      final start = DateTime(now.year, now.month - i, 1);
      final end = DateTime(start.year, start.month + 1, 1);
      final inMonth = _allTrials.where((trial) {
        final createdAt = DateTime.tryParse(trial['created_at']?.toString() ?? '');
        return createdAt != null && !createdAt.isBefore(start) && createdAt.isBefore(end);
      });
      months.add(
        _MonthBucket(
          label:
              '${monthNames[start.month - 1].substring(0, 3)} ${start.year.toString().substring(2)}',
          statusCounts: TrialTrends.statusCounts(inMonth),
        ),
      );
    }
    return months;
  }

  Map<String, int> _countsBy(String field) => TrialTrends.countsBy(_allTrials, field, 'Unknown');

  double? get _overallCompletionRate {
    final counts = TrialTrends.statusCounts(_allTrials);
    return TrialTrends.completionRate(counts['Completed'] ?? 0, counts['Failed'] ?? 0);
  }

  MapEntry<String, int>? _topEntry(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }

  Widget _insightChip({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = _monthlyBuckets;

    return Scaffold(
      appBar: _appBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _insightChipsRow(),

                      const SizedBox(height: 16),

                      _monthlyVolumeChart(months),

                      const SizedBox(height: 16),

                      _completionRateChart(months),

                      const SizedBox(height: 16),

                      _breakdownsRow(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  AppHeader _appBar() {
    return AppHeader(
      title: 'Analytics',
      actions: [
        HeaderIconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _loadTrials,
        ),
      ],
    );
  }

  Widget _insightChipsRow() {
    final busiestTerminal = _topEntry(_countsBy('terminal_of_trial'));
    final commonType = _topEntry(_countsBy('type_of_trial'));
    final completionRate = _overallCompletionRate;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _insightChip(
          icon: Icons.bar_chart,
          text: '${_allTrials.length} trials all-time',
          color: AppColors.lightNavy,
        ),
        if (completionRate != null)
          _insightChip(
            icon: Icons.trending_up,
            text: '${completionRate.round()}% completion rate',
            color: AppColors.success,
          ),
        if (busiestTerminal != null)
          _insightChip(
            icon: Icons.location_on_outlined,
            text: '${busiestTerminal.key} is busiest (${busiestTerminal.value})',
            color: AppColors.accent,
          ),
        if (commonType != null)
          _insightChip(
            icon: Icons.science_outlined,
            text: 'Most common: ${commonType.key}',
            color: AppColors.midNavy,
          ),
      ],
    );
  }

  FlTitlesData _titles(
    List<_MonthBucket> months, {
    required double reservedSize,
    required double interval,
    String suffix = '',
  }) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: reservedSize,
          interval: interval,
          getTitlesWidget: (value, meta) =>
              Text('${value.toInt()}$suffix', style: const TextStyle(fontSize: 11)),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= months.length) {
              return const Text('');
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(months[i].label, style: const TextStyle(fontSize: 11)),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _monthlyVolumeChart(List<_MonthBucket> months) {
    final maxMonthTotal = months.isEmpty
        ? 1.0
        : months.map((m) => m.total).reduce((a, b) => a > b ? a : b).toDouble() + 1;
    final yInterval = maxMonthTotal <= 10 ? 1.0 : (maxMonthTotal / 8).ceilToDouble();

    return SectionCard(
      children: [
        const Text('Trials by Month', style: _titleStyle),
        const SizedBox(height: 4),
        const Text('Last 6 months, colored by outcome', style: _subtitleStyle),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: months.every((m) => m.total == 0)
              ? const Center(child: Text('No data yet'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxMonthTotal,
                    titlesData: _titles(months, reservedSize: 28, interval: yInterval),
                    borderData: FlBorderData(show: false),
                    barGroups: months.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bucket = entry.value;
                      double cumulative = 0;
                      final stackItems = <BarChartRodStackItem>[];
                      for (final status in const [
                        'Pending',
                        'In Progress',
                        'Completed',
                        'Failed',
                      ]) {
                        final count = (bucket.statusCounts[status] ?? 0).toDouble();
                        if (count <= 0) continue;
                        stackItems.add(
                          BarChartRodStackItem(
                            cumulative,
                            cumulative + count,
                            colorForStatus(status),
                          ),
                        );
                        cumulative += count;
                      }
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: cumulative,
                            rodStackItems: stackItems,
                            width: 32,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: kStatusColors.entries
              .map(
                (e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: e.value, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(e.key, style: const TextStyle(fontSize: 12, color: AppColors.otherText)),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _completionRateChart(List<_MonthBucket> months) {
    return SectionCard(
      children: [
        const Text('Completion Rate Trend', style: _titleStyle),
        const SizedBox(height: 4),
        const Text(
          'Completed ÷ (Completed + Failed), months with no resolved trials are skipped',
          style: _subtitleStyle,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: months.every((m) => m.completionRate == null)
              ? const Center(child: Text('Not enough resolved trials yet'))
              : LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    titlesData: _titles(months, reservedSize: 36, interval: 25, suffix: '%'),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(drawVerticalLine: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < months.length; i++)
                            if (months[i].completionRate != null)
                              FlSpot(i.toDouble(), months[i].completionRate!),
                        ],
                        isCurved: true,
                        color: AppColors.accent,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.accent.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _breakdownsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _terminalBreakdownCard()),
        const SizedBox(width: 12),
        Expanded(child: _typeBreakdownCard()),
      ],
    );
  }

  Widget _terminalBreakdownCard() {
    return TerminalBreakdown(
      counts: _countsBy('terminal_of_trial'),
      total: _allTrials.length,
      title: 'By Terminal (all-time)',
      barColor: AppColors.lightNavy,
      emptyStyle: const TextStyle(color: AppColors.otherText),
    );
  }

  Widget _typeBreakdownCard() {
    final counts = _countsBy('type_of_trial');
    return SectionCard(
      children: [
        const Text('By Type (all-time)', style: _titleStyle),
        const SizedBox(height: 12),
        counts.isEmpty
            ? const Text('No data', style: TextStyle(color: AppColors.otherText))
            : SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sections: counts.entries.map((entry) {
                      final color = _typeColors[entry.key] ?? AppColors.otherText;
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: entry.value.toString(),
                        color: color,
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                  ),
                ),
              ),
        const SizedBox(height: 8),
        ...counts.entries.map(
          (entry) => Padding(
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
                Text(entry.key),
                const Spacer(),
                Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
