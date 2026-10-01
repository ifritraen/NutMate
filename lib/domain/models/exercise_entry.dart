import 'dart:convert';

class ExerciseEntry {
  final int? id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime startTime;
  final DateTime endTime;
  final double durationMinutes;
  final String category; // 'Gym / Weights', 'Cardio', 'Walk / Run', 'Stretching / Yoga', 'Bodyweight', 'Swimming', 'Sports', 'Other'
  final String timing; // 'Standalone', 'Pre-Habit', 'Post-Habit', 'Earlier Today'
  final String intensity; // 'Light', 'Moderate', 'High', 'Intense'
  final String notes;
  final int caloriesBurned;
  final List<String> tags;

  ExerciseEntry({
    this.id,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.category = 'Gym / Weights',
    this.timing = 'Standalone',
    this.intensity = 'Moderate',
    this.notes = '',
    this.caloriesBurned = 0,
    this.tags = const [],
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
      'category': category,
      'timing': timing,
      'intensity': intensity,
      'notes': notes,
      'caloriesBurned': caloriesBurned,
      'tags': jsonEncode(tags),
    };
  }

  factory ExerciseEntry.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null && map['tags'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['tags']);
        if (decoded is List) parsedTags = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return ExerciseEntry(
      id: map['id'] as int?,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      startTime: DateTime.tryParse(map['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(map['endTime']?.toString() ?? '') ?? DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toDouble() ?? 15.0,
      category: map['category']?.toString() ?? 'Gym / Weights',
      timing: map['timing']?.toString() ?? 'Standalone',
      intensity: map['intensity']?.toString() ?? 'Moderate',
      notes: map['notes']?.toString() ?? '',
      caloriesBurned: (map['caloriesBurned'] as num?)?.toInt() ?? 0,
      tags: parsedTags,
    );
  }

  ExerciseEntry copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startTime,
    DateTime? endTime,
    double? durationMinutes,
    String? category,
    String? timing,
    String? intensity,
    String? notes,
    int? caloriesBurned,
    List<String>? tags,
  }) {
    return ExerciseEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      timing: timing ?? this.timing,
      intensity: intensity ?? this.intensity,
      notes: notes ?? this.notes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      tags: tags ?? this.tags,
    );
  }
}
