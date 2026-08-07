import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme.dart';

import '../providers/app_providers.dart';
import '../widgets/breathing_modal.dart';
import '../widgets/floating_top_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/heatmap_calendar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onAddLogTap;
  final bool isNavVisible;

  const DashboardScreen({
    super.key,
    required this.onAddLogTap,
    this.isNavVisible = true,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = ref.watch(statsProvider);
    final settings = ref.watch(settingsProvider);
    final allLogs = ref.watch(logsProvider);

    final now = DateTime.now();
    final lastReset = settings.lastStreakResetTime;
    final streak = lastReset != null ? now.difference(lastReset) : stats.currentStreak;

    final days = streak?.inDays ?? 0;
    final hours = (streak?.inHours ?? 0) % 24;
    final minutes = (streak?.inMinutes ?? 0) % 60;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 90, left: 16, right: 16, bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_outlined, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Current Streak', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimerUnit(days.toString(), 'Days', theme),
                          _buildTimerUnit(hours.toString().padLeft(2, '0'), 'Hours', theme),
                          _buildTimerUnit(minutes.toString().padLeft(2, '0'), 'Minutes', theme),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Time since last masturbation session', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _buildInteractiveCounterCard(
                      title: 'Edge',
                      count: settings.currentEdgeCount,
                      icon: Icons.bolt,
                      accentColor: Colors.amberAccent,
                      backgroundColor: Colors.amber.withOpacity(0.08),
                      onIncrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateEdgeCount(settings.currentEdgeCount + 1);
                      },
                      onDecrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateEdgeCount((settings.currentEdgeCount - 1).clamp(0, 999));
                      },
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildInteractiveCounterCard(
                      title: 'Arousal',
                      count: settings.currentArousalCount,
                      icon: Icons.local_fire_department,
                      accentColor: Colors.deepOrangeAccent,
                      backgroundColor: Colors.deepOrange.withOpacity(0.08),
                      onIncrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateArousalCount(settings.currentArousalCount + 1);
                      },
                      onDecrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateArousalCount((settings.currentArousalCount - 1).clamp(0, 999));
                      },
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildInteractiveCounterCard(
                      title: 'Urge',
                      count: settings.currentUrgeCount,
                      icon: Icons.whatshot,
                      accentColor: Colors.redAccent,
                      backgroundColor: Colors.red.withOpacity(0.08),
                      onIncrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateUrgeCount(settings.currentUrgeCount + 1);
                      },
                      onDecrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateUrgeCount((settings.currentUrgeCount - 1).clamp(0, 999));
                      },
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                GlassCard(
                  child: HeatmapCalendar(logs: allLogs),
                ),
                const SizedBox(height: 24),

                Text('Personal Bests & All-Time Highs', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                GlassCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Highest Interval', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('${stats.maxIntervalDays.toStringAsFixed(1)} Days', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text('Max Edges Recorded', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('${stats.maxEdgeCount}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.white12),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Longest Session', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('${stats.maxSessionDurationMinutes.toStringAsFixed(0)} Mins', style: const TextStyle(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text('Max Satisfaction', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('${stats.maxSatisfaction} / 10', style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Habit Insights & Averages', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _buildStatCard('Avg Interval', '${stats.avgIntervalDays.toStringAsFixed(1)} Days', Icons.calendar_month, theme),
                    _buildStatCard('Avg Duration', '${stats.avgSessionDurationMinutes.toStringAsFixed(1)} Mins', Icons.schedule, theme),
                    _buildStatCard('Edging / Session', stats.avgEdgingBeforeOrgasm.toStringAsFixed(1), Icons.bolt, theme),
                    _buildStatCard('Avg Cleanup', '${(stats.avgCleanupTimeSeconds / 60).toStringAsFixed(1)} Mins', Icons.cleaning_services, theme),
                    _buildStatCard('Satisfaction', '${stats.avgSatisfaction.toStringAsFixed(1)} / 10', Icons.sentiment_satisfied, theme),
                    _buildStatCard('Regret', '${stats.avgRegret.toStringAsFixed(1)} / 10', Icons.sentiment_neutral, theme),
                    _buildStatCard('Avg Urge', '${stats.avgUrge.toStringAsFixed(1)} / 10', Icons.local_fire_department, theme),
                    _buildStatCard('Orgasm Quality', '${stats.avgOrgasmQuality.toStringAsFixed(1)} / 10', Icons.star_outline, theme),
                    _buildStatCard('Top Trigger', stats.mostCommonTrigger, Icons.bolt_outlined, theme),
                    _buildStatCard('Top Stimulus', stats.mostCommonStimulus, Icons.movie_outlined, theme),
                    _buildStatCard('Top Reason', stats.mostCommonReason, Icons.psychology_outlined, theme),
                    _buildStatCard('Top Mood', stats.mostCommonMood, Icons.mood, theme),
                    _buildStatCard('Water Before', '${stats.avgWaterBeforeMl.toStringAsFixed(0)} ml', Icons.water_drop_outlined, theme),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingTopBar(
              title: settings.stealthMode ? 'Daily Notes Dashboard' : 'Nutmate Dashboard',
              isVisible: widget.isNavVisible,
              actions: [
                IconButton(
                  icon: Icon(Icons.self_improvement, color: AppTheme.secondaryCyan),
                  onPressed: () {
                    HapticService.selectionClick();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const BreathingModal(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: AppTheme.secondaryCyan),
                  onPressed: () {
                    HapticService.lightImpact();
                    widget.onAddLogTap();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerUnit(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInteractiveCounterCard({
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
    required Color backgroundColor,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required ThemeData theme,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        color: backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      count == 1 ? 'time' : 'times',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: count > 0 ? onDecrement : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(count > 0 ? 0.1 : 0.03),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.remove, size: 16, color: count > 0 ? Colors.white70 : Colors.white24),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onIncrement,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.add, size: 16, color: accentColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
