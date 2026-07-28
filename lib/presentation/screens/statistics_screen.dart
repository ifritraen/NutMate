import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/pattern_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/log_entry.dart';
import '../../domain/models/stats_summary.dart';
import '../providers/app_providers.dart';
import '../widgets/floating_top_bar.dart';
import '../widgets/glass_card.dart';
import 'ai_export_dialog.dart';

enum DateRangeFilter { week, month, threeMonths, sixMonths, year, allTime }

class StatisticsScreen extends ConsumerStatefulWidget {
  final bool isNavVisible;

  const StatisticsScreen({super.key, this.isNavVisible = true});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateRangeFilter _range = DateRangeFilter.month;

  List<LogEntry> _filterLogsByRange(List<LogEntry> logs) {
    if (_range == DateRangeFilter.allTime) return logs;

    final now = DateTime.now();
    late DateTime cutoff;
    switch (_range) {
      case DateRangeFilter.week:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case DateRangeFilter.month:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case DateRangeFilter.threeMonths:
        cutoff = now.subtract(const Duration(days: 90));
        break;
      case DateRangeFilter.sixMonths:
        cutoff = now.subtract(const Duration(days: 180));
        break;
      case DateRangeFilter.year:
        cutoff = now.subtract(const Duration(days: 365));
        break;
      case DateRangeFilter.allTime:
        return logs;
    }
    return logs.where((e) => e.createdAt.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final allLogs = ref.watch(logsProvider);
    final filteredLogs = _filterLogsByRange(allLogs);
    final stats = StatsSummary.fromLogs(filteredLogs, activeEdgeCount: settings.currentEdgeCount, activeArousalCount: settings.currentArousalCount);
    final observations = PatternEngine.generateObservations(filteredLogs, stats);

    final sortedLogs = List<LogEntry>.from(filteredLogs)..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 90, left: 16, right: 16, bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRangeChip('Week', DateRangeFilter.week, theme),
                      _buildRangeChip('Month', DateRangeFilter.month, theme),
                      _buildRangeChip('3 Months', DateRangeFilter.threeMonths, theme),
                      _buildRangeChip('6 Months', DateRangeFilter.sixMonths, theme),
                      _buildRangeChip('Year', DateRangeFilter.year, theme),
                      _buildRangeChip('All Time', DateRangeFilter.allTime, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text('Pattern Detection & Insights', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                GlassCard(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppTheme.secondaryCyan, size: 20),
                          const SizedBox(width: 8),
                          Text('Descriptive Observations', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...observations.map(
                        (obs) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: TextStyle(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold)),
                              Expanded(child: Text(obs, style: const TextStyle(color: Colors.white70, height: 1.4))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Personal Bests & Highest Records', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.emoji_events,
                              iconColor: Colors.amber,
                              title: 'Highest Interval',
                              value: '${stats.maxIntervalDays.toStringAsFixed(1)}d',
                            ),
                          ),
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.timer,
                              iconColor: AppTheme.secondaryCyan,
                              title: 'Longest Session',
                              value: '${stats.maxSessionDurationMinutes.toStringAsFixed(0)}m',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.bolt,
                              iconColor: Colors.amberAccent,
                              title: 'Max Edges',
                              value: '${stats.maxEdgeCount}',
                            ),
                          ),
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.star,
                              iconColor: Colors.purpleAccent,
                              title: 'Max Satisfaction',
                              value: '${stats.maxSatisfaction}/10',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Urge vs. Satisfaction Trends', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                GlassCard(
                  child: SizedBox(
                    height: 220,
                    child: sortedLogs.isEmpty
                        ? const Center(child: Text('Log entries to view trend lines', style: TextStyle(color: Colors.white38)))
                        : LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(sortedLogs.length, (i) => FlSpot(i.toDouble(), sortedLogs[i].urge.toDouble())),
                                  isCurved: true,
                                  color: Colors.amber,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                ),
                                LineChartBarData(
                                  spots: List.generate(sortedLogs.length, (i) => FlSpot(i.toDouble(), sortedLogs[i].satisfaction.toDouble())),
                                  isCurved: true,
                                  color: AppTheme.secondaryCyan,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Satisfaction vs. Regret Breakdown', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                GlassCard(
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10,
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                if (val == 0) return const Text('Satisfaction', style: TextStyle(color: Colors.white70, fontSize: 12));
                                if (val == 1) return const Text('Regret', style: TextStyle(color: Colors.white70, fontSize: 12));
                                if (val == 2) return const Text('Orgasm Qual', style: TextStyle(color: Colors.white70, fontSize: 12));
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: stats.avgSatisfaction, color: AppTheme.secondaryCyan, width: 22)]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: stats.avgRegret, color: AppTheme.accentRose, width: 22)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: stats.avgOrgasmQuality, color: AppTheme.primaryViolet, width: 22)]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingTopBar(
              title: settings.stealthMode ? 'Activity Summary' : 'Interactive Statistics',
              isVisible: widget.isNavVisible,
              actions: [
                IconButton(
                  icon: Icon(Icons.share, color: AppTheme.secondaryCyan),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AiExportDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, DateRangeFilter value, ThemeData theme) {
    final isSelected = _range == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: theme.colorScheme.primary.withOpacity(0.4),
        onSelected: (val) {
          if (val) setState(() => _range = value);
        },
      ),
    );
  }

  Widget _buildMetricTile({required IconData icon, required Color iconColor, required String title, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
