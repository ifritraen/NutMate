import 'package:intl/intl.dart';
import '../../domain/models/log_entry.dart';
import '../../domain/models/stats_summary.dart';

class AiExportService {
  static String generateReport({
    required List<LogEntry> logs,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final rangeFormat = DateFormat('MMM dd, yyyy');

    final filteredLogs = logs.where((e) => e.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) && e.createdAt.isBefore(endDate.add(const Duration(days: 1)))).toList();
    final stats = StatsSummary.fromLogs(filteredLogs);

    final sb = StringBuffer();

    sb.writeln('# Nutmate Privacy-Preserving Habit Export');
    sb.writeln('**Date Range:** ${rangeFormat.format(startDate)} – ${rangeFormat.format(endDate)}');
    sb.writeln('**Generated On:** ${rangeFormat.format(DateTime.now())}');
    sb.writeln();

    sb.writeln('## Summary Statistics');
    sb.writeln('- **Total Masturbation Sessions:** ${stats.totalMasturbationSessions}');
    sb.writeln('- **Total Edging Sessions:** ${stats.totalEdgingSessions}');
    sb.writeln('- **Average Masturbation Interval:** ${stats.avgIntervalDays > 0 ? "${stats.avgIntervalDays.toStringAsFixed(1)} days" : "N/A"}');
    sb.writeln('- **Average Session Duration:** ${stats.avgSessionDurationMinutes.toStringAsFixed(1)} minutes');
    sb.writeln('- **Average Satisfaction:** ${stats.avgSatisfaction.toStringAsFixed(1)} / 10');
    sb.writeln('- **Average Orgasm Quality:** ${stats.avgOrgasmQuality.toStringAsFixed(1)} / 10');
    sb.writeln('- **Average Regret Level:** ${stats.avgRegret.toStringAsFixed(1)} / 10');
    sb.writeln('- **Average Urge Intensity:** ${stats.avgUrge.toStringAsFixed(1)} / 10');
    sb.writeln('- **Average Cleanup Time:** ${(stats.avgCleanupTimeSeconds / 60).toStringAsFixed(1)} minutes');
    sb.writeln('- **Average Water Before:** ${stats.avgWaterBeforeMl.toStringAsFixed(0)} ml');
    sb.writeln('- **Average Water After:** ${stats.avgWaterAfterMl.toStringAsFixed(0)} ml');
    sb.writeln('- **Average Sleep Quality:** ${stats.avgSleepQuality.toStringAsFixed(1)} / 10');
    sb.writeln('- **Average Sleep Duration:** ${stats.avgSleepDuration.toStringAsFixed(1)} hours');
    sb.writeln('- **Most Common Mood:** ${stats.mostCommonMood}');
    sb.writeln('- **Most Common Trigger:** ${stats.mostCommonTrigger}');
    sb.writeln('- **Most Common Reason:** ${stats.mostCommonReason}');
    sb.writeln();

    sb.writeln('## Detailed Daily Log Entries');
    if (filteredLogs.isEmpty) {
      sb.writeln('No entries logged in this date range.');
    } else {
      for (var log in filteredLogs) {
        final typeEmoji = log.type == SessionType.masturbation ? '💦 Masturbation' : '⚡ Edging';
        sb.writeln('### ${dateFormat.format(log.createdAt)} - $typeEmoji');
        sb.writeln('- **Duration:** ${log.durationMinutes.toStringAsFixed(1)} mins');
        sb.writeln('- **Urge:** ${log.urge}/10 | **Mood:** ${log.mood.isEmpty ? "N/A" : log.mood}');
        sb.writeln('- **Reason:** ${log.reason.isEmpty ? "N/A" : log.reason} | **Trigger:** ${log.trigger.isEmpty ? "N/A" : log.trigger}');
        sb.writeln('- **Content Used:** ${log.contentUsed.isEmpty ? "None" : log.contentUsed.join(", ")}');
        if (log.type == SessionType.masturbation) {
          sb.writeln('- **Satisfaction:** ${log.satisfaction}/10 | **Regret:** ${log.regret}/10 | **Orgasm Quality:** ${log.orgasmQuality}/10');
        }
        sb.writeln();
      }
    }

    sb.writeln('---');
    sb.writeln('## Suggested Analysis Prompts for AI');
    sb.writeln('1. *"Please analyze my masturbation and edging habits neutrally based on this log data."*');
    sb.writeln('2. *"Do you notice any triggers or patterns related to boredom, stress, or time of day?"*');
    sb.writeln('3. *"What lifestyle factors (such as hydration or sleep duration) appear to correlate with higher satisfaction or lower regret?"*');

    return sb.toString();
  }

  static String generateCsv(List<LogEntry> logs) {
    final sb = StringBuffer();
    sb.writeln('id,createdAt,type,durationMinutes,urge,satisfaction,regret,reason,trigger,mood,waterBeforeMl');
    for (var log in logs) {
      sb.writeln('${log.id ?? ""},${log.createdAt.toIso8601String()},${log.type.name},${log.durationMinutes},${log.urge},${log.satisfaction},${log.regret},"${log.reason}","${log.trigger}","${log.mood}",${log.waterBeforeMl}');
    }
    return sb.toString();
  }

  static String generateHtml(List<LogEntry> logs) {
    final sb = StringBuffer();
    sb.writeln('<!DOCTYPE html><html><head><meta charset="utf-8"><title>Nutmate Report</title>');
    sb.writeln('<style>body{font-family:sans-serif;background:#0F0E17;color:#FFF;padding:24px;}h1{color:#00F5D4;}table{width:100%;border-collapse:collapse;}th,td{padding:10px;border:1px solid #333;}</style></head><body>');
    sb.writeln('<h1>Nutmate Wellness Report</h1>');
    sb.writeln('<table><tr><th>Date</th><th>Type</th><th>Duration</th><th>Satisfaction</th><th>Regret</th><th>Trigger</th></tr>');
    for (var log in logs) {
      sb.writeln('<tr><td>${log.createdAt}</td><td>${log.type.name}</td><td>${log.durationMinutes}m</td><td>${log.satisfaction}/10</td><td>${log.regret}/10</td><td>${log.trigger}</td></tr>');
    }
    sb.writeln('</table></body></html>');
    return sb.toString();
  }
}
