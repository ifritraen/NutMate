import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/haptic_service.dart';
import '../../core/services/timer_notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/exercise_entry.dart';
import '../providers/app_providers.dart';
import '../widgets/chip_selector.dart';
import '../widgets/glass_card.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  final bool isNavVisible;
  final Function(double durationMinutes, String category)? onBridgeToHabit;
  final ExerciseEntry? existingEntry;
  final double? initialDurationMinutes;
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;
  final String? initialCategory;

  const ExerciseScreen({
    super.key,
    this.isNavVisible = true,
    this.onBridgeToHabit,
    this.existingEntry,
    this.initialDurationMinutes,
    this.initialStartTime,
    this.initialEndTime,
    this.initialCategory,
  });

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> with WidgetsBindingObserver {
  // Session Timing
  DateTime _sessionDateTime = DateTime.now();
  double _durationMinutes = 30.0;
  bool _isTimerRunning = false;
  int _timerSeconds = 0;
  DateTime? _timerStartTime;
  Timer? _stopwatchTimer;

  // Category & Intensity
  String _category = 'Gym / Weights';
  String _timing = 'Standalone';
  String _intensity = 'Moderate';
  int _caloriesBurned = 0;

  // Notes & Details
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  bool _isRecentHistoryExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TimerNotificationService.instance.enableWakelock();
    _initValues();
  }

  void _initValues() {
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _sessionDateTime = entry.createdAt;
      _durationMinutes = entry.durationMinutes;
      _category = entry.category.isEmpty ? 'Gym / Weights' : entry.category;
      _timing = entry.timing.isEmpty ? 'Standalone' : entry.timing;
      _intensity = entry.intensity.isEmpty ? 'Moderate' : entry.intensity;
      _caloriesBurned = entry.caloriesBurned;
      _notesController.text = entry.notes;
      if (_caloriesBurned > 0) _caloriesController.text = '$_caloriesBurned';
      _timerSeconds = (entry.durationMinutes * 60).round();
    } else {
      if (widget.initialDurationMinutes != null && widget.initialDurationMinutes! > 0) {
        _durationMinutes = widget.initialDurationMinutes!;
        _timerSeconds = (widget.initialDurationMinutes! * 60).round();
      }
      if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
        _category = widget.initialCategory!;
      }
      if (widget.initialStartTime != null) {
        _sessionDateTime = widget.initialStartTime!;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatchTimer?.cancel();
    _notesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _toggleStopwatch() {
    HapticService.selectionClick();
    setState(() {
      _isTimerRunning = !_isTimerRunning;
      if (_isTimerRunning) {
        _timerStartTime ??= DateTime.now();
        _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _timerSeconds++;
            _durationMinutes = (_timerSeconds / 60.0).clamp(1.0, 180.0);
          });
        });
      } else {
        _stopwatchTimer?.cancel();
      }
    });
  }

  void _resetStopwatch() {
    HapticService.selectionClick();
    _stopwatchTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerSeconds = 0;
      _timerStartTime = null;
      _durationMinutes = 30.0;
    });
  }

  String _formatStopwatchTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity) {
      case 'Light':
        return Colors.greenAccent;
      case 'Moderate':
        return AppTheme.secondaryCyan;
      case 'High':
        return Colors.amberAccent;
      case 'Intense':
        return Colors.redAccent;
      default:
        return AppTheme.secondaryCyan;
    }
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('Gym') || category.contains('Weights')) return Icons.fitness_center;
    if (category.contains('Cardio')) return Icons.directions_bike;
    if (category.contains('Run') || category.contains('Walk')) return Icons.directions_run;
    if (category.contains('Yoga') || category.contains('Stretch')) return Icons.self_improvement;
    if (category.contains('Bodyweight')) return Icons.accessibility_new;
    if (category.contains('Swimming')) return Icons.pool;
    if (category.contains('Sports')) return Icons.sports_basketball;
    return Icons.fitness_center;
  }

  Future<void> _saveWorkout() async {
    HapticService.selectionClick();

    final startTime = _timerStartTime ?? _sessionDateTime.subtract(Duration(minutes: _durationMinutes.round()));
    final endTime = _sessionDateTime;
    final cal = int.tryParse(_caloriesController.text.trim()) ?? _caloriesBurned;

    final entry = ExerciseEntry(
      id: widget.existingEntry?.id,
      createdAt: _sessionDateTime,
      updatedAt: DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      durationMinutes: _durationMinutes,
      category: _category,
      timing: _timing,
      intensity: _intensity,
      notes: _notesController.text.trim(),
      caloriesBurned: cal,
    );

    if (widget.existingEntry != null) {
      await ref.read(exerciseLogsProvider.notifier).updateExerciseLog(entry);
    } else {
      await ref.read(exerciseLogsProvider.notifier).addExerciseLog(entry);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingEntry != null ? 'Workout log updated' : 'Workout saved successfully!'),
          backgroundColor: AppTheme.secondaryCyan,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.existingEntry != null) {
        Navigator.pop(context);
      } else {
        _resetStopwatch();
        _notesController.clear();
        _caloriesController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final exerciseLogs = ref.watch(exerciseLogsProvider);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 90, left: 16, right: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Live Stopwatch Banner
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isTimerRunning ? AppTheme.secondaryCyan.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.timer,
                                    color: _isTimerRunning ? AppTheme.secondaryCyan : Colors.white70,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        settings.stealthMode ? 'Workout Timer' : 'Exercise Stopwatch',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _isTimerRunning ? 'Timer active' : (_timerSeconds > 0 ? 'Paused' : 'Ready to train'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _isTimerRunning ? AppTheme.secondaryCyan : Colors.white54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isTimerRunning
                                  ? Colors.greenAccent.withOpacity(0.15)
                                  : (_timerSeconds > 0 ? Colors.amberAccent.withOpacity(0.15) : Colors.white.withOpacity(0.06)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isTimerRunning
                                    ? Colors.greenAccent.withOpacity(0.4)
                                    : (_timerSeconds > 0 ? Colors.amberAccent.withOpacity(0.4) : Colors.white12),
                              ),
                            ),
                            child: Text(
                              _formatStopwatchTime(_timerSeconds),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: _isTimerRunning ? AppTheme.secondaryCyan : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTimerRunning ? Colors.redAccent.withOpacity(0.2) : AppTheme.secondaryCyan,
                                foregroundColor: _isTimerRunning ? Colors.redAccent : Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _toggleStopwatch,
                              icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                              label: Text(
                                _isTimerRunning ? 'Pause Workout' : (_timerSeconds > 0 ? 'Resume Workout' : 'Start Workout'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          if (_timerSeconds > 0) ...[
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white70),
                              tooltip: 'Reset Stopwatch',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.06),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.all(12),
                              ),
                              onPressed: _resetStopwatch,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Workout Configuration Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Time Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _sessionDateTime,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 1)),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    _sessionDateTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      _sessionDateTime.hour,
                                      _sessionDateTime.minute,
                                    );
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        DateFormat('MMM dd, yyyy').format(_sessionDateTime),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(_sessionDateTime),
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    _sessionDateTime = DateTime(
                                      _sessionDateTime.year,
                                      _sessionDateTime.month,
                                      _sessionDateTime.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        DateFormat('hh:mm a').format(_sessionDateTime),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category Chips
                      ChipSelector(
                        title: 'Exercise Category',
                        options: const [
                          'Gym / Weights',
                          'Cardio',
                          'Walk / Run',
                          'Stretching / Yoga',
                          'Bodyweight',
                          'Swimming',
                          'Sports',
                          'Other',
                        ],
                        selectedSingle: _category,
                        onSingleSelected: (val) {
                          HapticService.selectionClick();
                          setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Duration Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Duration: ${_durationMinutes.round()} mins',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _durationMinutes.clamp(1.0, 180.0),
                        min: 1,
                        max: 180,
                        divisions: 36,
                        onChanged: (val) {
                          HapticService.selectionClick();
                          setState(() {
                            _durationMinutes = val;
                            _timerSeconds = (val * 60).round();
                          });
                        },
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [15, 30, 45, 60].map((mins) {
                          return ActionChip(
                            label: Text('+$mins min', style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.white.withOpacity(0.06),
                            onPressed: () {
                              HapticService.selectionClick();
                              setState(() {
                                _durationMinutes = (_durationMinutes + mins).clamp(1.0, 180.0);
                                _timerSeconds = (_durationMinutes * 60).round();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Intensity Chips
                      ChipSelector(
                        title: 'Workout Intensity',
                        options: const ['Light', 'Moderate', 'High', 'Intense'],
                        selectedSingle: _intensity,
                        onSingleSelected: (val) {
                          HapticService.selectionClick();
                          setState(() => _intensity = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Timing Chips
                      ChipSelector(
                        title: 'Timing Relative to Habit',
                        options: const ['Standalone', 'Pre-Habit', 'Post-Habit', 'Earlier Today'],
                        selectedSingle: _timing,
                        onSingleSelected: (val) {
                          HapticService.selectionClick();
                          setState(() => _timing = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes Input
                      Text('Workout Notes & Sets', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Exercises performed, weights, reps, energy level, physical sensations...',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _saveWorkout,
                          icon: const Icon(Icons.check, size: 20),
                          label: Text(
                            widget.existingEntry != null ? 'Update Workout' : 'Save Workout Log',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      if (widget.onBridgeToHabit != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.secondaryCyan,
                              side: const BorderSide(color: AppTheme.secondaryCyan, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              HapticService.selectionClick();
                              widget.onBridgeToHabit?.call(_durationMinutes, _category);
                            },
                            icon: const Icon(Icons.link, size: 18),
                            label: const Text(
                              'Bridge to Habit / Masturbation Log',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Recent Workout History
                InkWell(
                  onTap: () {
                    HapticService.selectionClick();
                    setState(() => _isRecentHistoryExpanded = !_isRecentHistoryExpanded);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.history, color: AppTheme.secondaryCyan, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Workout History (${exerciseLogs.length})',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _isRecentHistoryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppTheme.secondaryCyan,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isRecentHistoryExpanded) ...[
                  const SizedBox(height: 8),
                  if (exerciseLogs.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.fitness_center_outlined, size: 40, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 10),
                            const Text('No workout logs yet', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            const SizedBox(height: 4),
                            const Text('Track live stopwatch or log your sessions above', style: TextStyle(color: Colors.white30, fontSize: 11)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...exerciseLogs.map((log) {
                      final intensityColor = _getIntensityColor(log.intensity);
                      final categoryIcon = _getCategoryIcon(log.category);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryCyan.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(categoryIcon, color: AppTheme.secondaryCyan, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.category,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          DateFormat('MMM dd, yyyy • hh:mm a').format(log.createdAt),
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 18),
                                    tooltip: 'Delete Workout',
                                    onPressed: () async {
                                      if (log.id != null) {
                                        HapticService.selectionClick();
                                        await ref.read(exerciseLogsProvider.notifier).deleteExerciseLog(log.id!);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '⏱️ ${log.durationMinutes.round()} mins',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: intensityColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: intensityColor.withOpacity(0.3), width: 0.8),
                                    ),
                                    child: Text(
                                      '🔥 ${log.intensity}',
                                      style: TextStyle(color: intensityColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (log.timing.isNotEmpty && log.timing != 'Standalone')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.purpleAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        log.timing,
                                        style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                              if (log.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  log.notes,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor.withOpacity(0.95),
                    theme.scaffoldBackgroundColor.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      settings.stealthMode ? 'Fitness & Activity' : '🏃 Exercise & Workout',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
