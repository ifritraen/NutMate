import 'log_entry.dart';

class StatsSummary {
  final Duration? currentStreak;
  final int currentEdgeCount;
  final int currentArousalCount;
  final double avgIntervalDays;
  final double maxIntervalDays;
  final double avgSessionDurationMinutes;
  final double maxSessionDurationMinutes;
  final double avgEdgingBeforeOrgasm;
  final int maxEdgeCount;
  final double avgCleanupTimeSeconds;
  final double avgSatisfaction;
  final int maxSatisfaction;
  final double avgRegret;
  final double avgUrge;
  final int maxUrge;
  final double avgOrgasmQuality;
  final int maxOrgasmQuality;
  final String mostCommonTrigger;
  final String mostCommonReason;
  final String mostCommonMood;
  final String mostCommonStimulus;
  final double avgWaterBeforeMl;
  final double avgWaterAfterMl;
  final double avgSleepQuality;
  final double avgSleepDuration;
  final double avgEdgingDurationMinutes;
  final double avgArousalDurationMinutes;
  final double avgNearOrgasmCount;
  final Map<String, int> contentUsageCounts;
  final int totalMasturbationSessions;
  final int totalEdgingSessions;
  final int totalArousalSessions;

  StatsSummary({
    this.currentStreak,
    this.currentEdgeCount = 0,
    this.currentArousalCount = 0,
    this.avgIntervalDays = 0.0,
    this.maxIntervalDays = 0.0,
    this.avgSessionDurationMinutes = 0.0,
    this.maxSessionDurationMinutes = 0.0,
    this.avgEdgingBeforeOrgasm = 0.0,
    this.maxEdgeCount = 0,
    this.avgCleanupTimeSeconds = 0.0,
    this.avgSatisfaction = 0.0,
    this.maxSatisfaction = 0,
    this.avgRegret = 0.0,
    this.avgUrge = 0.0,
    this.maxUrge = 0,
    this.avgOrgasmQuality = 0.0,
    this.maxOrgasmQuality = 0,
    this.mostCommonTrigger = 'N/A',
    this.mostCommonReason = 'N/A',
    this.mostCommonMood = 'N/A',
    this.mostCommonStimulus = 'N/A',
    this.avgWaterBeforeMl = 0.0,
    this.avgWaterAfterMl = 0.0,
    this.avgSleepQuality = 0.0,
    this.avgSleepDuration = 0.0,
    this.avgEdgingDurationMinutes = 0.0,
    this.avgArousalDurationMinutes = 0.0,
    this.avgNearOrgasmCount = 0.0,
    this.contentUsageCounts = const {},
    this.totalMasturbationSessions = 0,
    this.totalEdgingSessions = 0,
    this.totalArousalSessions = 0,
  });

  factory StatsSummary.fromLogs(List<LogEntry> logs, {DateTime? lastOrgasmTime, int activeEdgeCount = 0, int activeArousalCount = 0}) {
    if (logs.isEmpty) {
      return StatsSummary(
        currentStreak: lastOrgasmTime != null ? DateTime.now().difference(lastOrgasmTime) : null,
        currentEdgeCount: activeEdgeCount,
        currentArousalCount: activeArousalCount,
      );
    }

    final masturbationLogs = logs.where((e) => e.type == SessionType.masturbation).toList();
    final edgingLogs = logs.where((e) => e.type == SessionType.edging).toList();
    final arousalLogs = logs.where((e) => e.type == SessionType.arousal).toList();

    // Sort by createdAt ascending for streak/interval math
    final sortedMasturbation = List<LogEntry>.from(masturbationLogs)..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Calculate current streak
    DateTime? lastOrgasm = lastOrgasmTime;
    if (sortedMasturbation.isNotEmpty) {
      lastOrgasm = sortedMasturbation.last.createdAt;
    }
    final streak = lastOrgasm != null ? DateTime.now().difference(lastOrgasm) : null;

    // Average & Max interval between masturbation sessions
    double totalIntervalDays = 0.0;
    double highestIntervalDays = 0.0;
    if (sortedMasturbation.length > 1) {
      for (int i = 1; i < sortedMasturbation.length; i++) {
        final diffHours = sortedMasturbation[i].createdAt.difference(sortedMasturbation[i - 1].createdAt).inHours / 24.0;
        totalIntervalDays += diffHours;
        if (diffHours > highestIntervalDays) highestIntervalDays = diffHours;
      }
    }
    if (streak != null) {
      final currentStreakDays = streak.inHours / 24.0;
      if (currentStreakDays > highestIntervalDays) highestIntervalDays = currentStreakDays;
    }

    final avgInterval = sortedMasturbation.length > 1 ? totalIntervalDays / (sortedMasturbation.length - 1) : 0.0;

    double avgDuration = 0.0;
    double maxDuration = 0.0;
    if (logs.isNotEmpty) {
      for (var l in logs) {
        if (l.durationMinutes > maxDuration) maxDuration = l.durationMinutes;
      }
    }
    if (masturbationLogs.isNotEmpty) {
      avgDuration = masturbationLogs.fold(0.0, (sum, e) => sum + e.durationMinutes) / masturbationLogs.length;
    }

    double avgEdgeCountBeforeOrgasm = 0.0;
    int maxEdges = activeEdgeCount;
    if (masturbationLogs.isNotEmpty) {
      avgEdgeCountBeforeOrgasm = masturbationLogs.fold(0.0, (sum, e) => sum + e.edgingCountBeforeOrgasm) / masturbationLogs.length;
      for (var l in masturbationLogs) {
        if (l.edgingCountBeforeOrgasm > maxEdges) maxEdges = l.edgingCountBeforeOrgasm;
      }
    }

    double avgCleanupSec = 0.0;
    if (masturbationLogs.isNotEmpty) {
      avgCleanupSec = masturbationLogs.fold(0.0, (sum, e) => sum + e.cleanupDurationSeconds) / masturbationLogs.length;
    }

    double avgSat = 0.0;
    double avgReg = 0.0;
    double avgOrgQual = 0.0;
    int maxSatVal = 0;
    int maxOrgQualVal = 0;
    if (masturbationLogs.isNotEmpty) {
      avgSat = masturbationLogs.fold(0.0, (sum, e) => sum + e.satisfaction) / masturbationLogs.length;
      avgReg = masturbationLogs.fold(0.0, (sum, e) => sum + e.regret) / masturbationLogs.length;
      avgOrgQual = masturbationLogs.fold(0.0, (sum, e) => sum + e.orgasmQuality) / masturbationLogs.length;
      for (var l in masturbationLogs) {
        if (l.satisfaction > maxSatVal) maxSatVal = l.satisfaction;
        if (l.orgasmQuality > maxOrgQualVal) maxOrgQualVal = l.orgasmQuality;
      }
    }

    double avgUrgeVal = logs.isNotEmpty ? logs.fold(0.0, (sum, e) => sum + e.urge) / logs.length : 0.0;
    int maxUrgeVal = 0;
    for (var l in logs) {
      if (l.urge > maxUrgeVal) maxUrgeVal = l.urge;
    }

    double avgWaterBef = logs.isNotEmpty ? logs.fold(0.0, (sum, e) => sum + e.waterBeforeMl) / logs.length : 0.0;
    double avgWaterAft = masturbationLogs.isNotEmpty ? masturbationLogs.fold(0.0, (sum, e) => sum + e.waterAfterMl) / masturbationLogs.length : 0.0;
    double avgSleepQual = logs.isNotEmpty ? logs.fold(0.0, (sum, e) => sum + e.sleepQuality) / logs.length : 0.0;
    double avgSleepDur = logs.isNotEmpty ? logs.fold(0.0, (sum, e) => sum + e.sleepDurationHours) / logs.length : 0.0;

    double avgEdgeDur = edgingLogs.isNotEmpty ? edgingLogs.fold(0.0, (sum, e) => sum + e.durationMinutes) / edgingLogs.length : 0.0;
    double avgArousalDur = arousalLogs.isNotEmpty ? arousalLogs.fold(0.0, (sum, e) => sum + e.durationMinutes) / arousalLogs.length : 0.0;
    double avgNearOrg = edgingLogs.isNotEmpty ? edgingLogs.fold(0.0, (sum, e) => sum + e.nearOrgasmCount) / edgingLogs.length : 0.0;

    String mode(Iterable<String> items) {
      final valid = items.where((s) => s.trim().isNotEmpty).toList();
      if (valid.isEmpty) return 'N/A';
      final counts = <String, int>{};
      for (var item in valid) {
        counts[item] = (counts[item] ?? 0) + 1;
      }
      return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final contentCounts = <String, int>{};
    for (var log in logs) {
      for (var c in log.contentUsed) {
        if (c.trim().isNotEmpty) {
          contentCounts[c] = (contentCounts[c] ?? 0) + 1;
        }
      }
    }

    return StatsSummary(
      currentStreak: streak,
      currentEdgeCount: activeEdgeCount,
      currentArousalCount: activeArousalCount,
      avgIntervalDays: avgInterval,
      maxIntervalDays: highestIntervalDays,
      avgSessionDurationMinutes: avgDuration,
      maxSessionDurationMinutes: maxDuration,
      avgEdgingBeforeOrgasm: avgEdgeCountBeforeOrgasm,
      maxEdgeCount: maxEdges,
      avgCleanupTimeSeconds: avgCleanupSec,
      avgSatisfaction: avgSat,
      maxSatisfaction: maxSatVal,
      avgRegret: avgReg,
      avgUrge: avgUrgeVal,
      maxUrge: maxUrgeVal,
      avgOrgasmQuality: avgOrgQual,
      maxOrgasmQuality: maxOrgQualVal,
      mostCommonTrigger: mode(logs.map((e) => e.trigger)),
      mostCommonReason: mode(logs.map((e) => e.reason)),
      mostCommonMood: mode(logs.map((e) => e.mood)),
      mostCommonStimulus: mode(logs.map((e) => e.stimulus)),
      avgWaterBeforeMl: avgWaterBef,
      avgWaterAfterMl: avgWaterAft,
      avgSleepQuality: avgSleepQual,
      avgSleepDuration: avgSleepDur,
      avgEdgingDurationMinutes: avgEdgeDur,
      avgArousalDurationMinutes: avgArousalDur,
      avgNearOrgasmCount: avgNearOrg,
      contentUsageCounts: contentCounts,
      totalMasturbationSessions: masturbationLogs.length,
      totalEdgingSessions: edgingLogs.length,
      totalArousalSessions: arousalLogs.length,
    );
  }
}
