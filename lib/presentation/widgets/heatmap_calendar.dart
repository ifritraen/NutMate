import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/log_entry.dart';

class HeatmapCalendar extends StatelessWidget {
  final List<LogEntry> logs;
  final int weeksCount;

  const HeatmapCalendar({super.key, required this.logs, this.weeksCount = 18});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Map logs by date string (yyyy-MM-dd)
    final logMap = <String, int>{};
    for (var log in logs) {
      final key = '${log.createdAt.year}-${log.createdAt.month.toString().padLeft(2, '0')}-${log.createdAt.day.toString().padLeft(2, '0')}';
      logMap[key] = (logMap[key] ?? 0) + 1;
    }

    // Determine starting date (Monday of the earliest week)
    final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
    final thisMonday = now.subtract(Duration(days: currentWeekday - 1));
    final startMonday = thisMonday.subtract(Duration(days: (weeksCount - 1) * 7));

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Habit Activity Heatmap', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('Last $weeksCount Weeks', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day of week labels (M T W T F S S)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (rowIdx) {
                return Container(
                  height: 14,
                  margin: const EdgeInsets.only(bottom: 4),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dayLabels[rowIdx],
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            // Horizontal GitHub Grid (7 rows x weeksCount columns)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // Scroll to most recent on right
                child: Row(
                  children: List.generate(weeksCount, (weekIdx) {
                    final weekStart = startMonday.add(Duration(days: weekIdx * 7));
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: Column(
                        children: List.generate(7, (dayIdx) {
                          final date = weekStart.add(Duration(days: dayIdx));
                          final isFuture = date.isAfter(now);
                          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          final count = isFuture ? 0 : (logMap[key] ?? 0);

                          Color cellColor = Colors.white.withOpacity(0.04);
                          if (count == 1) cellColor = AppTheme.primaryViolet.withOpacity(0.4);
                          if (count == 2) cellColor = AppTheme.primaryViolet.withOpacity(0.8);
                          if (count >= 3) cellColor = AppTheme.secondaryCyan;
                          if (isFuture) cellColor = Colors.transparent;

                          return Tooltip(
                            message: isFuture ? '' : '$key: $count sessions',
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
