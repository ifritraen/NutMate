import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import '../../domain/models/stats_summary.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.raen.nutmate';
  static const MethodChannel _channel = MethodChannel('com.raen.nutmate/widget_update');

  static Future<void> updateHomeWidget(StatsSummary stats, {DateTime? lastOrgasmTime, bool isFrozen = false}) async {
    try {
      final streakText = stats.currentStreak != null
          ? '${stats.currentStreak!.inDays}d ${stats.currentStreak!.inHours % 24}h ${stats.currentStreak!.inMinutes % 60}m'
          : '0d 0h 0m';

      await HomeWidget.saveWidgetData<String>('streak_text', streakText);
      await HomeWidget.saveWidgetData<int>('edge_count', stats.currentEdgeCount);
      await HomeWidget.saveWidgetData<String>('avg_interval', '${stats.avgIntervalDays.toStringAsFixed(1)}d');
      await HomeWidget.saveWidgetData<String>('avg_satisfaction', '${stats.avgSatisfaction.toStringAsFixed(1)}/10');
      await HomeWidget.saveWidgetData<int>('last_reset_millis', lastOrgasmTime?.millisecondsSinceEpoch ?? 0);
      await HomeWidget.saveWidgetData<bool>('streak_frozen', isFrozen);
      await HomeWidget.saveWidgetData<int>('frozen_streak_millis', stats.currentStreak?.inMilliseconds ?? 0);

      final providers = [
        'NutmateWidgetProvider',
        'NutmateMasterWidgetProvider',
        'NutmateCompactWidgetProvider',
        'NutmateMinimalWidgetProvider',
      ];

      for (var provider in providers) {
        await HomeWidget.updateWidget(
          name: provider,
          androidName: provider,
        );
      }
    } catch (_) {
      // Gracefully handle platform/widget errors if widgets are not installed
    }
  }

  static Future<void> setUpdateInterval(int intervalMinutes) async {
    try {
      await _channel.invokeMethod('setUpdateInterval', {'intervalMinutes': intervalMinutes});
    } catch (_) {}
  }
}
