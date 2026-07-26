import '../../domain/models/log_entry.dart';
import '../../domain/models/stats_summary.dart';

class PatternEngine {
  static List<String> generateObservations(List<LogEntry> logs, StatsSummary stats) {
    if (logs.isEmpty) {
      return ['Keep logging sessions to reveal pattern observations!'];
    }

    final observations = <String>[];

    // 1. Time of day preference
    final hourCounts = <String, int>{
      'late at night (11 PM - 4 AM)': 0,
      'in the morning (5 AM - 11 AM)': 0,
      'in the afternoon (12 PM - 5 PM)': 0,
      'in the evening (6 PM - 10 PM)': 0,
    };

    for (var log in logs) {
      final hour = log.startTime.hour;
      if (hour >= 23 || hour < 5) {
        hourCounts['late at night (11 PM - 4 AM)'] = hourCounts['late at night (11 PM - 4 AM)']! + 1;
      } else if (hour >= 5 && hour < 12) {
        hourCounts['in the morning (5 AM - 11 AM)'] = hourCounts['in the morning (5 AM - 11 AM)']! + 1;
      } else if (hour >= 12 && hour < 18) {
        hourCounts['in the afternoon (12 PM - 5 PM)'] = hourCounts['in the afternoon (12 PM - 5 PM)']! + 1;
      } else {
        hourCounts['in the evening (6 PM - 10 PM)'] = hourCounts['in the evening (6 PM - 10 PM)']! + 1;
      }
    }

    final topTime = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (topTime.value > 0) {
      observations.add('You most frequently log sessions ${topTime.key}.');
    }

    // 2. Hydration & Satisfaction
    final hydrated = logs.where((e) => e.waterBeforeMl > 250 && e.type == SessionType.masturbation).toList();
    final nonHydrated = logs.where((e) => e.waterBeforeMl <= 250 && e.type == SessionType.masturbation).toList();

    if (hydrated.isNotEmpty && nonHydrated.isNotEmpty) {
      final hydSat = hydrated.fold(0.0, (s, e) => s + e.satisfaction) / hydrated.length;
      final nonHydSat = nonHydrated.fold(0.0, (s, e) => s + e.satisfaction) / nonHydrated.length;
      if (hydSat > nonHydSat + 0.5) {
        observations.add('You report higher average satisfaction (${hydSat.toStringAsFixed(1)}/10) when drinking water beforehand compared to without (${nonHydSat.toStringAsFixed(1)}/10).');
      }
    }

    // 3. Boredom / Trigger impact
    if (stats.mostCommonReason != 'N/A') {
      observations.add('Most recorded sessions occur when your reported reason is "${stats.mostCommonReason}".');
    }
    if (stats.mostCommonTrigger != 'N/A') {
      observations.add('Your most frequent trigger is "${stats.mostCommonTrigger}".');
    }

    // 4. Sleep duration & Edging count
    final shortSleep = logs.where((e) => e.sleepDurationHours < 6.0).toList();
    final normalSleep = logs.where((e) => e.sleepDurationHours >= 6.0).toList();
    if (shortSleep.isNotEmpty && normalSleep.isNotEmpty) {
      final shortEdge = shortSleep.fold(0.0, (s, e) => s + (e.type == SessionType.edging ? e.nearOrgasmCount : e.edgingCountBeforeOrgasm)) / shortSleep.length;
      final normEdge = normalSleep.fold(0.0, (s, e) => s + (e.type == SessionType.edging ? e.nearOrgasmCount : e.edgingCountBeforeOrgasm)) / normalSleep.length;
      if (shortEdge > normEdge + 0.5) {
        observations.add('Average edging count increases after nights with under 6 hours of sleep (${shortEdge.toStringAsFixed(1)} vs ${normEdge.toStringAsFixed(1)}).');
      }
    }

    // 5. Cleanup time
    if (stats.avgCleanupTimeSeconds > 0) {
      final mins = (stats.avgCleanupTimeSeconds / 60).toStringAsFixed(1);
      observations.add('Your average cleanup routine duration is $mins minutes.');
    }

    if (observations.isEmpty) {
      observations.add('Session logs show consistent habits across various conditions.');
    }

    return observations;
  }
}
