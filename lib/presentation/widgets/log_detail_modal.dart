import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/log_entry.dart';
import '../providers/app_providers.dart';
import '../screens/add_log_screen.dart';
import 'glass_card.dart';

class LogDetailModal extends ConsumerWidget {
  final LogEntry log;
  final String intervalText;

  const LogDetailModal({
    super.key,
    required this.log,
    required this.intervalText,
  });

  static void show(BuildContext context, LogEntry log, String intervalText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogDetailModal(log: log, intervalText: intervalText),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMast = log.type == SessionType.masturbation;
    final iconEmoji = isMast ? '💦' : (log.type == SessionType.edging ? '⚡' : '🔥');
    final titleText = isMast ? 'Masturbation Session' : (log.type == SessionType.edging ? 'Edging Session' : 'Arousal Session');
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy • hh:mm a');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(iconEmoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(dateFormat.format(log.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                      tooltip: 'Delete Log',
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddLogScreen(existingLog: log)),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interval badge
                  if (intervalText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryCyan.withOpacity(0.15),
                        border: Border.all(color: AppTheme.secondaryCyan.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: AppTheme.secondaryCyan, size: 18),
                          const SizedBox(width: 8),
                          Text(intervalText, style: const TextStyle(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Session Overview Card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Session Overview', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildDetailRow('Duration', '${log.durationMinutes.toStringAsFixed(0)} mins'),
                        _buildDetailRow('Urge Level', '🔥 ${log.urge}/10'),
                        _buildDetailRow('Method Used', log.method.isEmpty ? 'Hand' : log.method),
                        _buildDetailRow('Location', log.location.isEmpty ? 'Home' : log.location),
                        _buildDetailRow('Sleep Quality', '🌙 ${log.preSleepQuality}/10 (${log.preSleepHours}h)'),
                        _buildDetailRow('Mood', log.mood.isEmpty ? 'N/A' : log.mood),
                        _buildDetailRow('Trigger', log.trigger.isEmpty ? 'N/A' : log.trigger),
                        _buildDetailRow('Stimulus / Media', log.stimulus.isEmpty ? 'N/A' : log.stimulus),
                        _buildDetailRow('Body Position', log.position),
                        _buildDetailRow('Session Type', log.isPlanned ? 'Planned' : 'Impulsive'),
                        if (log.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: log.tags.map((t) => Chip(
                              label: Text(t, style: const TextStyle(fontSize: 11, color: Colors.cyanAccent)),
                              backgroundColor: Colors.cyan.withOpacity(0.15),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pre-Nut Habits Card
                  if (isMast) ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pre-Nut Habits (2h Before)', style: theme.textTheme.titleSmall?.copyWith(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildDetailRow('Water Intake', log.preWater),
                          _buildDetailRow('Workout / Activity', log.preWorkout),
                          _buildDetailRow('Meal Intake', log.preMeal),
                          _buildDetailRow('Meditation', log.preMeditation ? '${log.preMeditationDuration} mins' : 'None'),
                          _buildDetailRow('Nap / Sleep', log.preNapDuration > 0 ? '${log.preNapDuration} mins' : 'None'),
                          _buildDetailRow('Coffee', log.preCoffee ? 'Yes' : 'No'),
                          _buildDetailRow('Alcohol', log.preAlcohol ? 'Yes' : 'No'),
                          _buildDetailRow('Sleep Quality (Prior Night)', '${log.preSleepQuality}/10 (${log.preSleepHours}h)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // After & Post-Nut Habits Card (Masturbation)
                  if (isMast) ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Post-Nut Recovery (1h After)', style: theme.textTheme.titleSmall?.copyWith(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildDetailRow('Satisfaction', '${log.satisfaction}/10'),
                          _buildDetailRow('Orgasm Quality', '${log.orgasmQuality}/10'),
                          _buildDetailRow('Regret Level', '${log.regret}/10'),
                          _buildDetailRow('Cleanup Duration', '${(log.cleanupDurationSeconds / 60.0).toStringAsFixed(1)} mins'),
                          _buildDetailRow('Post-Nut Water', log.postWater),
                          _buildDetailRow('Post-Nut Meal', log.postMeal),
                          _buildDetailRow('Stretch Duration', log.postStretch ? '${log.postStretchDuration} mins' : 'None'),
                          _buildDetailRow('Nap Duration', log.postNap ? '${log.postNapDuration} mins' : 'None'),
                          _buildDetailRow('Meditation Duration', log.postMeditation ? '${log.postMeditationDuration} mins' : 'None'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Edging Details Card
                  if (log.type == SessionType.edging) ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edging Details', style: theme.textTheme.titleSmall?.copyWith(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildDetailRow('Near Orgasm Count', '${log.nearOrgasmCount} times'),
                          _buildDetailRow('Did Orgasm Occur?', log.didOrgasmOccur ? 'Yes' : 'No'),
                          if (log.endingReason.isNotEmpty) _buildDetailRow('Ending Reason', log.endingReason),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes Card
                  if (log.beforeNotes.isNotEmpty || log.duringNotes.isNotEmpty || log.afterNotes.isNotEmpty)
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notes', style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (log.beforeNotes.isNotEmpty) ...[
                            const Text('Before Notes:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(log.beforeNotes, style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                          ],
                          if (log.duringNotes.isNotEmpty) ...[
                            const Text('During Notes:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(log.duringNotes, style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                          ],
                          if (log.afterNotes.isNotEmpty) ...[
                            const Text('After Notes:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(log.afterNotes, style: const TextStyle(color: Colors.white)),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Delete Log Entry?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete this log entry? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              if (log.id != null) {
                await ref.read(logsProvider.notifier).deleteLog(log.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Log entry deleted successfully')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
