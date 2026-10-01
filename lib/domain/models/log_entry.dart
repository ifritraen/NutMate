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
  final int preContentDuration; // mins (0 = none)
  final List<String> preContentTypes; // Content types consumed pre-session

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
  final int urgeCountBeforeOrgasm;
  final int nearOrgasmCount;
  final bool didOrgasmOccur;
  final String endingReason;

  // Exercise & General Reflections
  final String exerciseType; // 'None', 'Gym / Weights', 'Cardio', 'Stretching / Yoga', 'Walk / Run', 'Bodyweight'
  final int exerciseDurationMinutes; // mins
  final String exerciseTiming; // 'Pre-Session', 'Post-Session', 'Earlier Today'
  final String generalNotes; // Notable observations & general reflections

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
    this.preContentDuration = 0,
    this.preContentTypes = const [],
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
    this.urgeCountBeforeOrgasm = 0,
    this.nearOrgasmCount = 0,
    this.didOrgasmOccur = false,
    this.endingReason = '',
    this.exerciseType = 'None',
    this.exerciseDurationMinutes = 0,
    this.exerciseTiming = 'Pre-Session',
    this.generalNotes = '',
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
  String get exerciseDone => exerciseType.isNotEmpty ? exerciseType : preWorkout;
  int get exerciseMinutes => exerciseDurationMinutes > 0 ? exerciseDurationMinutes : postStretchDuration;
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
      'preContentDuration': preContentDuration,
      'preContentTypes': jsonEncode(preContentTypes),
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
      'urgeCountBeforeOrgasm': urgeCountBeforeOrgasm,
      'nearOrgasmCount': nearOrgasmCount,
      'didOrgasmOccur': didOrgasmOccur ? 1 : 0,
      'endingReason': endingReason,

      // New first-class Exercise & General Notes fields
      'exerciseType': exerciseType,
      'exerciseDurationMinutes': exerciseDurationMinutes,
      'exerciseTiming': exerciseTiming,
      'generalNotes': generalNotes,

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

    List<String> parsedPreContentTypes = [];
    if (map['preContentTypes'] != null && map['preContentTypes'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['preContentTypes']);
        if (decoded is List) parsedPreContentTypes = decoded.map((e) => e.toString()).toList();
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

    final exType = map['exerciseType'] as String? ?? (map['exerciseDone'] as String? ?? (map['preWorkout'] as String? ?? 'None'));
    final exMins = (map['exerciseDurationMinutes'] as num?)?.toInt() ?? ((map['exerciseMinutes'] as num?)?.toInt() ?? 0);
    final exTiming = map['exerciseTiming'] as String? ?? 'Pre-Session';
    final gNotes = map['generalNotes'] as String? ?? (map['beforeNotes'] as String? ?? '');

    return LogEntry(
      id: map['id'] as int?,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      type: SessionType.values.firstWhere((e) => e.name == map['type'], orElse: () => SessionType.masturbation),
      preWater: map['preWater'] ?? 'None',
      preWorkout: map['preWorkout'] ?? exType,
      preMeditation: (map['preMeditation'] ?? (map['meditationDone'] ?? 0)) == 1,
      preMeditationDuration: map['preMeditationDuration'] ?? (map['meditationMinutes'] ?? 0),
      preSleepQuality: map['preSleepQuality'] ?? (map['sleepQuality'] ?? 5),
      preSleepHours: (map['preSleepHours'] as num?)?.toDouble() ?? ((map['sleepDurationHours'] as num?)?.toDouble() ?? 7.0),
      preNapDuration: map['preNapDuration'] ?? 0,
      preMeal: map['preMeal'] ?? (map['mealEaten'] ?? 'None'),
      preCoffee: (map['preCoffee'] ?? 0) == 1,
      preAlcohol: (map['preAlcohol'] ?? 0) == 1,
      preContentDuration: map['preContentDuration'] ?? 0,
      preContentTypes: parsedPreContentTypes,
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
      urgeCountBeforeOrgasm: map['urgeCountBeforeOrgasm'] ?? 0,
      nearOrgasmCount: map['nearOrgasmCount'] ?? 0,
      didOrgasmOccur: (map['didOrgasmOccur'] ?? 0) == 1,
      endingReason: map['endingReason'] ?? '',
      exerciseType: exType,
      exerciseDurationMinutes: exMins,
      exerciseTiming: exTiming,
      generalNotes: gNotes,
    );
  }

  LogEntry copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SessionType? type,
    String? preWater,
    String? preWorkout,
    bool? preMeditation,
    int? preMeditationDuration,
    int? preSleepQuality,
    double? preSleepHours,
    int? preNapDuration,
    String? preMeal,
    bool? preCoffee,
    bool? preAlcohol,
    int? preContentDuration,
    List<String>? preContentTypes,
    int? urge,
    String? mood,
    String? trigger,
    bool? isPlanned,
    String? location,
    List<String>? tags,
    String? beforeNotes,
    String? timeSinceLastOrgasmText,
    int? lastEdgingCount,
    DateTime? startTime,
    DateTime? endTime,
    double? durationMinutes,
    String? method,
    List<String>? contentUsed,
    String? stimulus,
    String? position,
    String? duringNotes,
    int? satisfaction,
    int? orgasmQuality,
    int? regret,
    int? cleanupDurationSeconds,
    String? afterNotes,
    String? postWater,
    bool? postStretch,
    int? postStretchDuration,
    String? postMeal,
    bool? postNap,
    int? postNapDuration,
    bool? postMeditation,
    int? postMeditationDuration,
    int? edgingCountBeforeOrgasm,
    int? arousalCountBeforeOrgasm,
    int? urgeCountBeforeOrgasm,
    int? nearOrgasmCount,
    bool? didOrgasmOccur,
    String? endingReason,
    String? exerciseType,
    int? exerciseDurationMinutes,
    String? exerciseTiming,
    String? generalNotes,
  }) {
    return LogEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      preWater: preWater ?? this.preWater,
      preWorkout: preWorkout ?? this.preWorkout,
      preMeditation: preMeditation ?? this.preMeditation,
      preMeditationDuration: preMeditationDuration ?? this.preMeditationDuration,
      preSleepQuality: preSleepQuality ?? this.preSleepQuality,
      preSleepHours: preSleepHours ?? this.preSleepHours,
      preNapDuration: preNapDuration ?? this.preNapDuration,
      preMeal: preMeal ?? this.preMeal,
      preCoffee: preCoffee ?? this.preCoffee,
      preAlcohol: preAlcohol ?? this.preAlcohol,
      preContentDuration: preContentDuration ?? this.preContentDuration,
      preContentTypes: preContentTypes ?? this.preContentTypes,
      urge: urge ?? this.urge,
      mood: mood ?? this.mood,
      trigger: trigger ?? this.trigger,
      isPlanned: isPlanned ?? this.isPlanned,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      beforeNotes: beforeNotes ?? this.beforeNotes,
      timeSinceLastOrgasmText: timeSinceLastOrgasmText ?? this.timeSinceLastOrgasmText,
      lastEdgingCount: lastEdgingCount ?? this.lastEdgingCount,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      method: method ?? this.method,
      contentUsed: contentUsed ?? this.contentUsed,
      stimulus: stimulus ?? this.stimulus,
      position: position ?? this.position,
      duringNotes: duringNotes ?? this.duringNotes,
      satisfaction: satisfaction ?? this.satisfaction,
      orgasmQuality: orgasmQuality ?? this.orgasmQuality,
      regret: regret ?? this.regret,
      cleanupDurationSeconds: cleanupDurationSeconds ?? this.cleanupDurationSeconds,
      afterNotes: afterNotes ?? this.afterNotes,
      postWater: postWater ?? this.postWater,
      postStretch: postStretch ?? this.postStretch,
      postStretchDuration: postStretchDuration ?? this.postStretchDuration,
      postMeal: postMeal ?? this.postMeal,
      postNap: postNap ?? this.postNap,
      postNapDuration: postNapDuration ?? this.postNapDuration,
      postMeditation: postMeditation ?? this.postMeditation,
      postMeditationDuration: postMeditationDuration ?? this.postMeditationDuration,
      edgingCountBeforeOrgasm: edgingCountBeforeOrgasm ?? this.edgingCountBeforeOrgasm,
      arousalCountBeforeOrgasm: arousalCountBeforeOrgasm ?? this.arousalCountBeforeOrgasm,
      urgeCountBeforeOrgasm: urgeCountBeforeOrgasm ?? this.urgeCountBeforeOrgasm,
      nearOrgasmCount: nearOrgasmCount ?? this.nearOrgasmCount,
      didOrgasmOccur: didOrgasmOccur ?? this.didOrgasmOccur,
      endingReason: endingReason ?? this.endingReason,
      exerciseType: exerciseType ?? this.exerciseType,
      exerciseDurationMinutes: exerciseDurationMinutes ?? this.exerciseDurationMinutes,
      exerciseTiming: exerciseTiming ?? this.exerciseTiming,
      generalNotes: generalNotes ?? this.generalNotes,
    );
  }


  Map<String, dynamic> toJson() => toMap();
  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry.fromMap(json);
}
