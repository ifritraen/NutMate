import 'package:home_widget/home_widget.dart';
import '../../domain/models/stats_summary.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.raen.nutmate';
  static const String androidWidgetProvider = 'NutmateWidgetProvider';

  static Future<void> updateHomeWidget(StatsSummary stats) async {
    try {
      final streakText = stats.currentStreak != null
          ? '${stats.currentStreak!.inDays}d ${stats.currentStreak!.inHours % 24}h ${stats.currentStreak!.inMinutes % 60}m'
          : '0 Days';

      await HomeWidget.saveWidgetData<String>('streak_text', streakText);
      await HomeWidget.saveWidgetData<int>('edge_count', stats.currentEdgeCount);
      await HomeWidget.saveWidgetData<String>('avg_interval', '${stats.avgIntervalDays.toStringAsFixed(1)}d');
      await HomeWidget.saveWidgetData<String>('avg_satisfaction', '${stats.avgSatisfaction.toStringAsFixed(1)}/10');

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
}
