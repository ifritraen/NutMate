import 'dart:convert';

class WatchEntry {
  final int? id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime startTime;
  final DateTime endTime;
  final double durationMinutes;
  final List<String> contentTypes;
  final String platform;
  final int urgeBefore; // 1-10
  final String trigger;
  final String location;
  final String intent; // '⚡ Accidental / Peek', '🎯 Intentional Binge', '🔄 Habitual Routine'
  final String outcome; // '✅ Closed Cleanly / Resisted Urge', '⚡ Led to Edging', '💦 Led to Masturbation / Orgasm'
  final String feelingAfter;
  final String notes;
  final List<String> tags;
  final bool isPlanned;

  WatchEntry({
    this.id,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.contentTypes = const [],
    this.platform = 'Browser / Web',
    this.urgeBefore = 5,
    this.trigger = '🥱 Boredom / Free Time',
    this.location = 'Bedroom',
    this.intent = '⚡ Accidental / Peek',
    this.outcome = '✅ Closed Cleanly / Resisted Urge',
    this.feelingAfter = 'Neutral',
    this.notes = '',
    this.tags = const [],
    this.isPlanned = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'contentTypes': jsonEncode(contentTypes),
      'platform': platform,
      'urgeBefore': urgeBefore,
      'trigger': trigger,
      'location': location,
      'intent': intent,
      'outcome': outcome,
      'feelingAfter': feelingAfter,
      'notes': notes,
      'tags': jsonEncode(tags),
      'isPlanned': isPlanned ? 1 : 0,
    };
  }

  factory WatchEntry.fromMap(Map<String, dynamic> map) {
    List<String> parsedContent = [];
    if (map['contentTypes'] != null && map['contentTypes'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['contentTypes']);
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

    return WatchEntry(
      id: map['id'] as int?,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      durationMinutes: (map['durationMinutes'] as num?)?.toDouble() ?? 0.0,
      contentTypes: parsedContent,
      platform: map['platform'] ?? 'Browser / Web',
      urgeBefore: map['urgeBefore'] ?? 5,
      trigger: map['trigger'] ?? '🥱 Boredom / Free Time',
      location: map['location'] ?? 'Bedroom',
      intent: map['intent'] ?? '⚡ Accidental / Peek',
      outcome: map['outcome'] ?? '✅ Closed Cleanly / Resisted Urge',
      feelingAfter: map['feelingAfter'] ?? 'Neutral',
      notes: map['notes'] ?? '',
      tags: parsedTags,
      isPlanned: (map['isPlanned'] ?? 0) == 1,
    );
  }

  WatchEntry copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startTime,
    DateTime? endTime,
    double? durationMinutes,
    List<String>? contentTypes,
    String? platform,
    int? urgeBefore,
    String? trigger,
    String? location,
    String? intent,
    String? outcome,
    String? feelingAfter,
    String? notes,
    List<String>? tags,
    bool? isPlanned,
  }) {
    return WatchEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      contentTypes: contentTypes ?? this.contentTypes,
      platform: platform ?? this.platform,
      urgeBefore: urgeBefore ?? this.urgeBefore,
      trigger: trigger ?? this.trigger,
      location: location ?? this.location,
      intent: intent ?? this.intent,
      outcome: outcome ?? this.outcome,
      feelingAfter: feelingAfter ?? this.feelingAfter,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isPlanned: isPlanned ?? this.isPlanned,
    );
  }
}
