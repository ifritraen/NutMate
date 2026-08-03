import 'dart:convert';

enum SessionType { masturbation, edging, arousal }

class LogEntry {
  final int? id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SessionType type;

  // Pre-Nut (Within 2 Hours Before) - Masturbation Only
  final String preWater; // 'None', '250 ml', '500 ml', '1L+'
  final String preWorkout; // 'None', 'Stretch', 'Walk', 'Cardio', 'Gym'
  final bool preMeditation;
  final int preMeditationDuration; // mins (0 = none)
  final int preSleepQuality; // 1-10
  final double preSleepHours;
  final int preNapDuration; // mins (0 = none)
  final String preMeal; // 'None', 'Light', 'Heavy'
  final bool preCoffee;
  final bool preAlcohol;

  // Before Session
  final int urge; // 1-10
  final String mood;
  final String trigger;
  final bool isPlanned; // Planned / Impulsive
  final String location;
  final List<String> tags;
  final String beforeNotes;
  final String timeSinceLastOrgasmText;
  final int lastEdgingCount;

  // During Session
  final DateTime startTime;
  final DateTime endTime;
  final double durationMinutes;
  final String method;
  final List<String> contentUsed;
  final String stimulus; // Media / Stimulus type consumed during session
  final String position; // 'Lying', 'Sitting', 'Standing', 'Other'
  final String duringNotes;

  // After Session (Masturbation)
  final int satisfaction; // 1-10
  final int orgasmQuality; // 1-10
  final int regret; // 1-10
  final int cleanupDurationSeconds;
  final String afterNotes;

  // Post-Nut (Within 1 Hour After Orgasm) - Masturbation Only
  final String postWater; // 'None', '250 ml', '500 ml', '1L+'
  final bool postStretch;
  final int postStretchDuration; // mins (0 = none)
  final String postMeal; // 'None', 'Light', 'Heavy' (matches Pre-Nut)
  final bool postNap;
  final int postNapDuration; // mins (0 = none)
  final bool postMeditation;
  final int postMeditationDuration; // mins (0 = none)

  // Edging Specific & Session Counts
  final int edgingCountBeforeOrgasm;
  final int arousalCountBeforeOrgasm;
  final int nearOrgasmCount;
  final bool didOrgasmOccur;
  final String endingReason;

  LogEntry({
    this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    this.preWater = 'None',
    this.preWorkout = 'None',
    this.preMeditation = false,
    this.preMeditationDuration = 0,
    this.preSleepQuality = 5,
    this.preSleepHours = 7.0,
    this.preNapDuration = 0,
    this.preMeal = 'None',
    this.preCoffee = false,
    this.preAlcohol = false,
    this.urge = 5,
    this.mood = '',
    this.trigger = '',
    this.isPlanned = false,
    this.location = 'Home',
    this.tags = const [],
    this.beforeNotes = '',
    this.timeSinceLastOrgasmText = '',
    this.lastEdgingCount = 0,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.method = '',
    this.contentUsed = const [],
    this.stimulus = '💭 Pure Imagination / Fantasy',
    this.position = 'Lying',
    this.duringNotes = '',
    this.satisfaction = 5,
    this.orgasmQuality = 5,
    this.regret = 1,
    this.cleanupDurationSeconds = 0,
    this.afterNotes = '',
    this.postWater = 'None',
    this.postStretch = false,
    this.postStretchDuration = 0,
    this.postMeal = 'None',
    this.postNap = false,
    this.postNapDuration = 0,
    this.postMeditation = false,
    this.postMeditationDuration = 0,
    this.edgingCountBeforeOrgasm = 0,
    this.arousalCountBeforeOrgasm = 0,
    this.nearOrgasmCount = 0,
    this.didOrgasmOccur = false,
    this.endingReason = '',
  });

  // Backward compatibility getters
  int get waterBeforeMl {
    if (preWater == '250 ml') return 250;
    if (preWater == '500 ml') return 500;
    if (preWater == '1L+') return 1000;
    return 0;
  }

  int get waterAfterMl {
    if (postWater == '250 ml') return 250;
    if (postWater == '500 ml') return 500;
    if (postWater == '1L+') return 1000;
    return 0;
  }

  int get sleepQuality => preSleepQuality;
  double get sleepDurationHours => preSleepHours;
  String get reason => trigger.isNotEmpty ? trigger : (mood.isNotEmpty ? mood : 'Unspecified');
  String get exerciseDone => preWorkout;
  int get exerciseMinutes => postStretchDuration;
  int get meditationDone => preMeditation ? 1 : 0;
  int get meditationMinutes => preMeditationDuration;
  String get mealEaten => preMeal;
  int get napTaken => preNapDuration > 0 ? 1 : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.name,
      'preWater': preWater,
      'preWorkout': preWorkout,
      'preMeditation': preMeditation ? 1 : 0,
      'preMeditationDuration': preMeditationDuration,
      'preSleepQuality': preSleepQuality,
      'preSleepHours': preSleepHours,
      'preNapDuration': preNapDuration,
      'preMeal': preMeal,
      'preCoffee': preCoffee ? 1 : 0,
      'preAlcohol': preAlcohol ? 1 : 0,
      'urge': urge,
      'mood': mood,
      'trigger': trigger,
      'isPlanned': isPlanned ? 1 : 0,
      'location': location,
      'tags': jsonEncode(tags),
      'beforeNotes': beforeNotes,
      'timeSinceLastOrgasmText': timeSinceLastOrgasmText,
      'lastEdgingCount': lastEdgingCount,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'method': method,
      'contentUsed': jsonEncode(contentUsed),
      'stimulus': stimulus,
      'position': position,
      'duringNotes': duringNotes,
      'satisfaction': satisfaction,
      'orgasmQuality': orgasmQuality,
      'regret': regret,
      'cleanupDurationSeconds': cleanupDurationSeconds,
      'afterNotes': afterNotes,
      'postWater': postWater,
      'postStretch': postStretch ? 1 : 0,
      'postStretchDuration': postStretchDuration,
      'postMeal': postMeal,
      'postNap': postNap ? 1 : 0,
      'postNapDuration': postNapDuration,
      'postMeditation': postMeditation ? 1 : 0,
      'postMeditationDuration': postMeditationDuration,
      'edgingCountBeforeOrgasm': edgingCountBeforeOrgasm,
      'arousalCountBeforeOrgasm': arousalCountBeforeOrgasm,
      'nearOrgasmCount': nearOrgasmCount,
      'didOrgasmOccur': didOrgasmOccur ? 1 : 0,
      'endingReason': endingReason,

      // Legacy table schema columns compatibility:
      'waterBeforeMl': waterBeforeMl,
      'waterAfterMl': waterAfterMl,
      'sleepQuality': preSleepQuality,
      'sleepDurationHours': preSleepHours,
      'reason': reason,
      'exerciseDone': exerciseDone,
      'exerciseMinutes': exerciseMinutes,
      'meditationDone': meditationDone,
      'meditationMinutes': meditationMinutes,
      'mealEaten': mealEaten,
      'napTaken': napTaken,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    List<String> parsedContent = [];
    if (map['contentUsed'] != null && map['contentUsed'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['contentUsed']);
        if (decoded is List) parsedContent = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    List<String> parsedTags = [];
    if (map['tags'] != null && map['tags'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['tags']);
        if (decoded is List) parsedTags = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    // Handle postMeal legacy boolean migration safely
    String parsedPostMeal = 'None';
    if (map['postMeal'] != null) {
      if (map['postMeal'] is int) {
        parsedPostMeal = (map['postMeal'] == 1) ? 'Light' : 'None';
      } else {
        parsedPostMeal = map['postMeal'].toString();
      }
    }

    return LogEntry(
      id: map['id'] as int?,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      type: SessionType.values.firstWhere((e) => e.name == map['type'], orElse: () => SessionType.masturbation),
      preWater: map['preWater'] ?? 'None',
      preWorkout: map['preWorkout'] ?? (map['exerciseDone'] ?? 'None'),
      preMeditation: (map['preMeditation'] ?? (map['meditationDone'] ?? 0)) == 1,
      preMeditationDuration: map['preMeditationDuration'] ?? (map['meditationMinutes'] ?? 0),
      preSleepQuality: map['preSleepQuality'] ?? (map['sleepQuality'] ?? 5),
      preSleepHours: (map['preSleepHours'] as num?)?.toDouble() ?? ((map['sleepDurationHours'] as num?)?.toDouble() ?? 7.0),
      preNapDuration: map['preNapDuration'] ?? 0,
      preMeal: map['preMeal'] ?? (map['mealEaten'] ?? 'None'),
      preCoffee: (map['preCoffee'] ?? 0) == 1,
      preAlcohol: (map['preAlcohol'] ?? 0) == 1,
      urge: map['urge'] ?? 5,
      mood: map['mood'] ?? '',
      trigger: map['trigger'] ?? (map['reason'] ?? ''),
      isPlanned: (map['isPlanned'] ?? 0) == 1,
      location: map['location'] ?? 'Home',
      tags: parsedTags,
      beforeNotes: map['beforeNotes'] ?? '',
      timeSinceLastOrgasmText: map['timeSinceLastOrgasmText'] ?? '',
      lastEdgingCount: map['lastEdgingCount'] ?? 0,
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      durationMinutes: (map['durationMinutes'] as num?)?.toDouble() ?? 0.0,
      method: map['method'] ?? '',
      contentUsed: parsedContent,
      stimulus: map['stimulus'] ?? '💭 Pure Imagination / Fantasy',
      position: map['position'] ?? 'Lying',
      duringNotes: map['duringNotes'] ?? '',
      satisfaction: map['satisfaction'] ?? 5,
      orgasmQuality: map['orgasmQuality'] ?? 5,
      regret: map['regret'] ?? 1,
      cleanupDurationSeconds: map['cleanupDurationSeconds'] ?? 0,
      afterNotes: map['afterNotes'] ?? '',
      postWater: map['postWater'] ?? 'None',
      postStretch: (map['postStretch'] ?? 0) == 1,
      postStretchDuration: map['postStretchDuration'] ?? (map['exerciseMinutes'] ?? 0),
      postMeal: parsedPostMeal,
      postNap: (map['postNap'] ?? (map['napTaken'] ?? 0)) == 1,
      postNapDuration: map['postNapDuration'] ?? 0,
      postMeditation: (map['postMeditation'] ?? 0) == 1,
      postMeditationDuration: map['postMeditationDuration'] ?? 0,
      edgingCountBeforeOrgasm: map['edgingCountBeforeOrgasm'] ?? 0,
      arousalCountBeforeOrgasm: map['arousalCountBeforeOrgasm'] ?? 0,
      nearOrgasmCount: map['nearOrgasmCount'] ?? 0,
      didOrgasmOccur: (map['didOrgasmOccur'] ?? 0) == 1,
      endingReason: map['endingReason'] ?? '',
    );
  }


  Map<String, dynamic> toJson() => toMap();
  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry.fromMap(json);
}
