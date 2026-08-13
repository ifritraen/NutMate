import 'package:intl/intl.dart';
import '../../domain/models/log_entry.dart';
import '../../domain/models/stats_summary.dart';
import '../../domain/models/watch_entry.dart';

class AiExportService {
  /// Generates a comprehensive, chronological record containing all session details,
  /// execution methods, stimulus, body positions, pre/post habits, counts, watch logs, and notes.
  static String generateFullHistoryReport({
    required List<LogEntry> logs,
    List<WatchEntry> watchLogs = const [],
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final rangeFormat = DateFormat('MMM dd, yyyy');

    final filteredLogs = logs.where((e) =>
      e.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
      e.createdAt.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    // Sort chronologically (oldest to newest for narrative review)
    filteredLogs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final sb = StringBuffer();
    sb.writeln('# NutMate Comprehensive AI & Activity Export');
    sb.writeln('**Date Range:** ${rangeFormat.format(startDate)} – ${rangeFormat.format(endDate)}');
    sb.writeln('**Total Logged Sessions:** ${filteredLogs.length}');
    sb.writeln('**Generated On:** ${rangeFormat.format(DateTime.now())}');
    sb.writeln();
    sb.writeln('> This document contains the exhaustive, complete chronological history of every logged activity, including execution methods, stimulus, body positions, pre/post-session physical habits, counts, and user notes for deep AI pattern analysis.');
    sb.writeln();

    if (filteredLogs.isEmpty) {
      sb.writeln('No entries recorded in this date range.');
    } else {
      for (int i = 0; i < filteredLogs.length; i++) {
        final log = filteredLogs[i];
        final typeEmoji = log.type == SessionType.masturbation
            ? '💦 Masturbation Session'
            : (log.type == SessionType.edging ? '⚡ Edging Session' : '🔥 Arousal Session');

        sb.writeln('---');
        sb.writeln('## Entry #${i + 1}: ${dateFormat.format(log.createdAt)} — $typeEmoji');
        sb.writeln();

        // Timing & Duration
        sb.writeln('### ⏱️ Session Timing');
        sb.writeln('- **Logged At:** ${dateFormat.format(log.createdAt)}');
        sb.writeln('- **Start Time:** ${dateFormat.format(log.startTime)}');
        sb.writeln('- **End Time:** ${dateFormat.format(log.endTime)}');
        sb.writeln('- **Active Duration:** ${log.durationMinutes.toStringAsFixed(1)} minutes');
        if (log.timeSinceLastOrgasmText.isNotEmpty) {
          sb.writeln('- **Streak / Time Since Last Orgasm:** ${log.timeSinceLastOrgasmText}');
        }
        sb.writeln();

        // Execution & Context
        sb.writeln('### ✋ Execution & Methods');
        sb.writeln('- **Method Used:** ${log.method.isEmpty ? "Hand" : log.method}');
        sb.writeln('- **Stimulus / Media Used:** ${log.stimulus.isEmpty ? "Pure Imagination" : log.stimulus}');
        sb.writeln('- **Body Position:** ${log.position.isEmpty ? "Lying" : log.position}');
        sb.writeln('- **Location:** ${log.location.isEmpty ? "Home" : log.location}');
        sb.writeln('- **Session Planning:** ${log.isPlanned ? "Planned" : "Impulsive / Spontaneous"}');
        if (log.contentUsed.isNotEmpty) {
          sb.writeln('- **Specific Content / Material:** ${log.contentUsed.join(", ")}');
        }
        if (log.tags.isNotEmpty) {
          sb.writeln('- **Tags:** ${log.tags.join(" ")}');
        }
        sb.writeln();

        // State Before Session & Counts
        sb.writeln('### 🧠 State & Counts Before Session');
        sb.writeln('- **Urge Intensity Level:** ${log.urge}/10');
        sb.writeln('- **Urge Count (Pre-Orgasm Urges Experienced):** ${log.urgeCountBeforeOrgasm}');
        sb.writeln('- **Edging Count Before Orgasm:** ${log.edgingCountBeforeOrgasm}');
        sb.writeln('- **Arousal Count Before Orgasm:** ${log.arousalCountBeforeOrgasm}');
        sb.writeln('- **Mood:** ${log.mood.isEmpty ? "Unspecified" : log.mood}');
        sb.writeln('- **Trigger / Reason:** ${log.trigger.isNotEmpty ? log.trigger : (log.reason.isNotEmpty ? log.reason : "Unspecified")}');
        sb.writeln();

        // Pre-Nut Habits
        sb.writeln('### 💧 Pre-Session Lifestyle Habits (Within 2 Hours Before)');
        sb.writeln('- **Hydration / Water Intake:** ${log.preWater}');
        sb.writeln('- **Workout / Physical Activity:** ${log.preWorkout}');
        sb.writeln('- **Meditation:** ${log.preMeditation ? "Yes (${log.preMeditationDuration} mins)" : "None"}');
        sb.writeln('- **Sleep Quality:** ${log.preSleepQuality}/10 (${log.preSleepHours.toStringAsFixed(1)} hours of sleep)');
        sb.writeln('- **Nap Taken:** ${log.preNapDuration > 0 ? "Yes (${log.preNapDuration} mins)" : "No"}');
        sb.writeln('- **Pre-Meal:** ${log.preMeal}');
        sb.writeln('- **Coffee / Caffeine:** ${log.preCoffee ? "Yes" : "No"} | **Alcohol:** ${log.preAlcohol ? "Yes" : "No"}');
        if (log.preContentDuration > 0 || log.preContentTypes.isNotEmpty) {
          sb.writeln('- **Pre-Session Content Consumed:** ${log.preContentDuration} mins${log.preContentTypes.isNotEmpty ? " (${log.preContentTypes.join(', ')})" : ""}');
        }
        sb.writeln();

        // Experience & Outcome
        sb.writeln('### 🌟 Post-Session Outcome & Ratings');
        if (log.type == SessionType.masturbation) {
          sb.writeln('- **Satisfaction Level:** ${log.satisfaction}/10');
          sb.writeln('- **Orgasm Quality:** ${log.orgasmQuality}/10');
          sb.writeln('- **Regret Level:** ${log.regret}/10');
          sb.writeln('- **Cleanup Duration:** ${(log.cleanupDurationSeconds / 60.0).toStringAsFixed(1)} minutes (${log.cleanupDurationSeconds} seconds)');
        }
        if (log.nearOrgasmCount > 0 || log.type == SessionType.edging) {
          sb.writeln('- **Near-Orgasm / Edge Points Reached:** ${log.nearOrgasmCount}');
          sb.writeln('- **Orgasm Occurred:** ${log.didOrgasmOccur ? "Yes" : "No"}');
          if (log.endingReason.isNotEmpty) {
            sb.writeln('- **Ending Reason:** ${log.endingReason}');
          }
        }
        sb.writeln();

        // Post-Nut Habits
        sb.writeln('### 🧘 Post-Session Habits (Within 1 Hour After)');
        sb.writeln('- **Post-Hydration Water:** ${log.postWater}');
        sb.writeln('- **Stretching / Cool-down:** ${log.postStretch ? "Yes (${log.postStretchDuration} mins)" : "None"}');
        sb.writeln('- **Post-Meal:** ${log.postMeal}');
        sb.writeln('- **Post-Nap:** ${log.postNap ? "Yes (${log.postNapDuration} mins)" : "None"}');
        sb.writeln('- **Post-Meditation:** ${log.postMeditation ? "Yes (${log.postMeditationDuration} mins)" : "None"}');
        sb.writeln();
        // Notes
        if (log.beforeNotes.isNotEmpty || log.duringNotes.isNotEmpty || log.afterNotes.isNotEmpty) {
          sb.writeln('### 📝 Personal Notes');
          if (log.beforeNotes.isNotEmpty) sb.writeln('- **Before Session Note:** ${log.beforeNotes}');
          if (log.duringNotes.isNotEmpty) sb.writeln('- **During Session Note:** ${log.duringNotes}');
          if (log.afterNotes.isNotEmpty) sb.writeln('- **After Session Note:** ${log.afterNotes}');
          sb.writeln();
        }
      }
    }

    if (watchLogs.isNotEmpty) {
      final filteredWatch = watchLogs.where((e) =>
        e.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        e.createdAt.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();

      if (filteredWatch.isNotEmpty) {
        filteredWatch.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        sb.writeln('---');
        sb.writeln('## 🎬 NSFW Media & Watch Sessions (${filteredWatch.length} entries)');
        sb.writeln();

        for (int j = 0; j < filteredWatch.length; j++) {
          final w = filteredWatch[j];
          sb.writeln('### Watch Log #${j + 1}: ${dateFormat.format(w.createdAt)} — ${w.platform}');
          sb.writeln('- **Duration:** ${w.durationMinutes.toStringAsFixed(0)} mins (${dateFormat.format(w.startTime)} – ${dateFormat.format(w.endTime)})');
          sb.writeln('- **Media Consumed:** ${w.contentTypes.isEmpty ? "Adult Content" : w.contentTypes.join(", ")}');
          sb.writeln('- **Platform:** ${w.platform} | **Location:** ${w.location}');
          sb.writeln('- **Urge Before:** ${w.urgeBefore}/10 | **Initial Trigger:** ${w.trigger}');
          sb.writeln('- **Intent:** ${w.intent} | **Outcome:** ${w.outcome}');
          sb.writeln('- **Post-Watch Feeling:** ${w.feelingAfter}');
          if (w.notes.isNotEmpty) sb.writeln('- **Notes:** ${w.notes}');
          if (w.tags.isNotEmpty) sb.writeln('- **Tags:** ${w.tags.join(" ")}');
          sb.writeln();
        }
      }
    }

    sb.writeln('---');
    sb.writeln('## Suggested AI Analysis Prompts');
    sb.writeln('1. *"Analyze my complete habit and media watch history, identify repeating patterns or triggers, and correlate execution methods/stimulus with regret and satisfaction levels."*');
    sb.writeln('2. *"How do pre-session lifestyle factors (sleep hours/quality, hydration, meals, workouts) and watch browsing time directly impact my urge intensity and orgasm quality?"*');
    sb.writeln('3. *"Provide actionable behavioral insights based on my streaks, media watch outcomes (resisted vs relapse), and time-of-day trends."*');

    return sb.toString();
  }

  /// Generates a summary analytics report focusing on key aggregated stats and high-level patterns.
  static String generateReport({
    required List<LogEntry> logs,
    List<WatchEntry> watchLogs = const [],
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final rangeFormat = DateFormat('MMM dd, yyyy');

    final filteredLogs = logs.where((e) =>
      e.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
      e.createdAt.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
    final stats = StatsSummary.fromLogs(filteredLogs);

    final sb = StringBuffer();

    sb.writeln('# NutMate Summary Analytics & Habit Report');
    sb.writeln('**Date Range:** ${rangeFormat.format(startDate)} – ${rangeFormat.format(endDate)}');
    sb.writeln('**Total Entries:** ${filteredLogs.length}');
    sb.writeln('**Generated On:** ${rangeFormat.format(DateTime.now())}');
    sb.writeln();

    sb.writeln('## Aggregated Key Statistics');
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
    sb.writeln('- **Most Common Stimulus:** ${stats.mostCommonStimulus}');
    sb.writeln('- **Most Common Reason:** ${stats.mostCommonReason}');
    sb.writeln();

    sb.writeln('## Recent Session Timeline Overview');
    if (filteredLogs.isEmpty) {
      sb.writeln('No entries logged in this date range.');
    } else {
      for (var log in filteredLogs) {
        final typeEmoji = log.type == SessionType.masturbation ? '💦 Masturbation' : '⚡ Edging';
        sb.writeln('### ${dateFormat.format(log.createdAt)} - $typeEmoji');
        sb.writeln('- **Duration:** ${log.durationMinutes.toStringAsFixed(1)} mins | **Method:** ${log.method.isEmpty ? "Hand" : log.method} | **Position:** ${log.position}');
        sb.writeln('- **Stimulus:** ${log.stimulus} | **Location:** ${log.location}');
        sb.writeln('- **Urge:** ${log.urge}/10 (Count: ${log.urgeCountBeforeOrgasm}) | **Mood:** ${log.mood.isEmpty ? "N/A" : log.mood} | **Trigger:** ${log.trigger.isEmpty ? "N/A" : log.trigger}');
        if (log.type == SessionType.masturbation) {
          sb.writeln('- **Satisfaction:** ${log.satisfaction}/10 | **Regret:** ${log.regret}/10 | **Orgasm Quality:** ${log.orgasmQuality}/10 | **Cleanup:** ${(log.cleanupDurationSeconds / 60).toStringAsFixed(1)}m');
        }
        if (log.beforeNotes.isNotEmpty || log.afterNotes.isNotEmpty) {
          sb.writeln('- **Notes:** ${[log.beforeNotes, log.afterNotes].where((s) => s.isNotEmpty).join(" | ")}');
        }
        sb.writeln();
      }
    }

    sb.writeln('---');
    sb.writeln('## Suggested Analysis Prompts for AI');
    sb.writeln('1. *"Please analyze my habit trends, triggers, and execution methods neutrally based on this summary data."*');
    sb.writeln('2. *"What lifestyle factors (sleep, hydration, workout) appear to correlate with higher satisfaction or lower regret?"*');
    sb.writeln('3. *"Give me recommendations to manage high urge periods effectively."*');

    return sb.toString();
  }

  /// Generates a full CSV data export containing every single database column for spreadsheet analysis.
  static String generateCsv(List<LogEntry> logs, [List<WatchEntry> watchLogs = const []]) {
    final sb = StringBuffer();
    sb.writeln(
      'id,createdAt,updatedAt,type,startTime,endTime,durationMinutes,timeSinceLastOrgasmText,'
      'method,stimulus,position,location,isPlanned,tags,contentUsed,'
      'urge,mood,trigger,reason,lastEdgingCount,edgingCountBeforeOrgasm,arousalCountBeforeOrgasm,urgeCountBeforeOrgasm,'
      'satisfaction,orgasmQuality,regret,cleanupDurationSeconds,nearOrgasmCount,didOrgasmOccur,endingReason,'
      'preWater,preWorkout,preMeditation,preMeditationDuration,preSleepQuality,preSleepHours,preNapDuration,preMeal,preCoffee,preAlcohol,preContentDuration,preContentTypes,'
      'postWater,postStretch,postStretchDuration,postMeal,postNap,postNapDuration,postMeditation,postMeditationDuration,'
      'beforeNotes,duringNotes,afterNotes'
    );

    String escapeCsv(dynamic val) {
      if (val == null) return '""';
      final str = val.toString().replaceAll('"', '""');
      return '"$str"';
    }

    for (var log in logs) {
      sb.writeln([
        log.id ?? '',
        log.createdAt.toIso8601String(),
        log.updatedAt.toIso8601String(),
        log.type.name,
        log.startTime.toIso8601String(),
        log.endTime.toIso8601String(),
        log.durationMinutes,
        escapeCsv(log.timeSinceLastOrgasmText),
        escapeCsv(log.method),
        escapeCsv(log.stimulus),
        escapeCsv(log.position),
        escapeCsv(log.location),
        log.isPlanned ? 1 : 0,
        escapeCsv(log.tags.join(',')),
        escapeCsv(log.contentUsed.join(',')),
        log.urge,
        escapeCsv(log.mood),
        escapeCsv(log.trigger),
        escapeCsv(log.reason),
        log.lastEdgingCount,
        log.edgingCountBeforeOrgasm,
        log.arousalCountBeforeOrgasm,
        log.urgeCountBeforeOrgasm,
        log.satisfaction,
        log.orgasmQuality,
        log.regret,
        log.cleanupDurationSeconds,
        log.nearOrgasmCount,
        log.didOrgasmOccur ? 1 : 0,
        escapeCsv(log.endingReason),
        escapeCsv(log.preWater),
        escapeCsv(log.preWorkout),
        log.preMeditation ? 1 : 0,
        log.preMeditationDuration,
        log.preSleepQuality,
        log.preSleepHours,
        log.preNapDuration,
        escapeCsv(log.preMeal),
        log.preCoffee ? 1 : 0,
        log.preAlcohol ? 1 : 0,
        log.preContentDuration,
        escapeCsv(log.preContentTypes.join(';')),
        escapeCsv(log.postWater),
        log.postStretch ? 1 : 0,
        log.postStretchDuration,
        escapeCsv(log.postMeal),
        log.postNap ? 1 : 0,
        log.postNapDuration,
        log.postMeditation ? 1 : 0,
        log.postMeditationDuration,
        escapeCsv(log.beforeNotes),
        escapeCsv(log.duringNotes),
        escapeCsv(log.afterNotes),
      ].join(','));
    }

    if (watchLogs.isNotEmpty) {
      sb.writeln();
      sb.writeln('# --- WATCH & MEDIA SESSIONS ---');
      sb.writeln('watch_id,createdAt,updatedAt,startTime,endTime,durationMinutes,contentTypes,platform,urgeBefore,trigger,location,intent,outcome,feelingAfter,notes,tags');
      for (var w in watchLogs) {
        sb.writeln([
          w.id ?? '',
          w.createdAt.toIso8601String(),
          w.updatedAt.toIso8601String(),
          w.startTime.toIso8601String(),
          w.endTime.toIso8601String(),
          w.durationMinutes,
          escapeCsv(w.contentTypes.join(';')),
          escapeCsv(w.platform),
          w.urgeBefore,
          escapeCsv(w.trigger),
          escapeCsv(w.location),
          escapeCsv(w.intent),
          escapeCsv(w.outcome),
          escapeCsv(w.feelingAfter),
          escapeCsv(w.notes),
          escapeCsv(w.tags.join(';')),
        ].join(','));
      }
    }

    return sb.toString();
  }

  /// Generates a comprehensive HTML report document.
  static String generateHtml(List<LogEntry> logs, [List<WatchEntry> watchLogs = const []]) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final sb = StringBuffer();

    sb.writeln('<!DOCTYPE html><html><head><meta charset="utf-8">');
    sb.writeln('<title>NutMate Activity & Habit Report</title>');
    sb.writeln('''
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0F0E17; color: #FFF; padding: 32px; line-height: 1.6; }
  h1 { color: #00F5D4; font-size: 28px; margin-bottom: 8px; }
  h2 { color: #FF8906; font-size: 22px; margin-top: 32px; margin-bottom: 16px; border-bottom: 1px solid #2E2D3D; padding-bottom: 8px; }
  .meta { color: #A7A9BE; font-size: 14px; margin-bottom: 24px; }
  .card { background: #1B1A26; border-radius: 12px; padding: 20px; margin-bottom: 20px; border: 1px solid #2E2D3D; }
  .card-title { font-size: 18px; font-weight: bold; color: #FF8906; margin-bottom: 12px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px; }
  .badge { display: inline-block; padding: 3px 8px; border-radius: 6px; font-size: 12px; font-weight: bold; }
  .badge-mast { background: rgba(0, 245, 212, 0.2); color: #00F5D4; }
  .badge-edge { background: rgba(255, 137, 6, 0.2); color: #FF8906; }
  .badge-watch { background: rgba(229, 49, 112, 0.2); color: #E53170; }
  .field-label { color: #A7A9BE; font-size: 12px; }
  .field-value { font-size: 14px; font-weight: 600; color: #FFF; }
  .notes { margin-top: 12px; padding-top: 12px; border-top: 1px solid #2E2D3D; font-size: 13px; color: #E53170; }
</style>
</head><body>
''');
    sb.writeln('<h1>NutMate Activity & Habit Report</h1>');
    sb.writeln('<div class="meta">Generated: ${dateFormat.format(DateTime.now())} | Total Sessions: ${logs.length} | Watch Logs: ${watchLogs.length}</div>');

    sb.writeln('<h2>Habit Sessions (${logs.length})</h2>');
    for (var log in logs) {
      final isMast = log.type == SessionType.masturbation;
      sb.writeln('<div class="card">');
      sb.writeln('<div class="card-title">');
      sb.writeln('<span class="badge ${isMast ? "badge-mast" : "badge-edge"}">${isMast ? "💦 Masturbation" : "⚡ Edging"}</span> ');
      sb.writeln('${dateFormat.format(log.createdAt)} (${log.durationMinutes.toStringAsFixed(1)} mins)');
      sb.writeln('</div>');

      sb.writeln('<div class="grid">');
      sb.writeln('<div><div class="field-label">Method</div><div class="field-value">${log.method.isEmpty ? "Hand" : log.method}</div></div>');
      sb.writeln('<div><div class="field-label">Stimulus</div><div class="field-value">${log.stimulus}</div></div>');
      sb.writeln('<div><div class="field-label">Position</div><div class="field-value">${log.position}</div></div>');
      sb.writeln('<div><div class="field-label">Urge</div><div class="field-value">${log.urge}/10 (Count: ${log.urgeCountBeforeOrgasm})</div></div>');
      sb.writeln('<div><div class="field-label">Satisfaction</div><div class="field-value">${log.satisfaction}/10</div></div>');
      sb.writeln('<div><div class="field-label">Regret</div><div class="field-value">${log.regret}/10</div></div>');
      sb.writeln('<div><div class="field-label">Trigger</div><div class="field-value">${log.trigger.isNotEmpty ? log.trigger : "None"}</div></div>');
      sb.writeln('<div><div class="field-label">Sleep</div><div class="field-value">${log.preSleepQuality}/10 (${log.preSleepHours}h)</div></div>');
      if (log.preContentDuration > 0 || log.preContentTypes.isNotEmpty) {
        sb.writeln('<div><div class="field-label">Pre-Content</div><div class="field-value">${log.preContentDuration}m (${log.preContentTypes.join(", ")})</div></div>');
      }
      sb.writeln('</div>');

      if (log.beforeNotes.isNotEmpty || log.duringNotes.isNotEmpty || log.afterNotes.isNotEmpty) {
        sb.writeln('<div class="notes">');
        if (log.beforeNotes.isNotEmpty) sb.writeln('<div><strong>Before:</strong> ${log.beforeNotes}</div>');
        if (log.duringNotes.isNotEmpty) sb.writeln('<div><strong>During:</strong> ${log.duringNotes}</div>');
        if (log.afterNotes.isNotEmpty) sb.writeln('<div><strong>After:</strong> ${log.afterNotes}</div>');
        sb.writeln('</div>');
      }

      sb.writeln('</div>');
    }

    if (watchLogs.isNotEmpty) {
      sb.writeln('<h2>🎬 Watch & Media Sessions (${watchLogs.length})</h2>');
      for (var w in watchLogs) {
        sb.writeln('<div class="card">');
        sb.writeln('<div class="card-title">');
        sb.writeln('<span class="badge badge-watch">🎬 Watch Log</span> ');
        sb.writeln('${dateFormat.format(w.createdAt)} (${w.durationMinutes.toStringAsFixed(0)} mins) — ${w.platform}');
        sb.writeln('</div>');

        sb.writeln('<div class="grid">');
        sb.writeln('<div><div class="field-label">Media</div><div class="field-value">${w.contentTypes.join(", ")}</div></div>');
        sb.writeln('<div><div class="field-label">Platform</div><div class="field-value">${w.platform}</div></div>');
        sb.writeln('<div><div class="field-label">Location</div><div class="field-value">${w.location}</div></div>');
        sb.writeln('<div><div class="field-label">Urge Before</div><div class="field-value">${w.urgeBefore}/10</div></div>');
        sb.writeln('<div><div class="field-label">Trigger</div><div class="field-value">${w.trigger}</div></div>');
        sb.writeln('<div><div class="field-label">Intent</div><div class="field-value">${w.intent}</div></div>');
        sb.writeln('<div><div class="field-label">Outcome</div><div class="field-value">${w.outcome}</div></div>');
        sb.writeln('<div><div class="field-label">Feeling After</div><div class="field-value">${w.feelingAfter}</div></div>');
        sb.writeln('</div>');

        if (w.notes.isNotEmpty) {
          sb.writeln('<div class="notes">');
          sb.writeln('<div><strong>Reflection:</strong> ${w.notes}</div>');
          sb.writeln('</div>');
        }

        sb.writeln('</div>');
      }
    }

    sb.writeln('</body></html>');
    return sb.toString();
  }
}
}
