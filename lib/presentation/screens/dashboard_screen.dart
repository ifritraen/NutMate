import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme.dart';

import '../providers/app_providers.dart';
import '../widgets/breathing_modal.dart';
import '../widgets/floating_top_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/heatmap_calendar.dart';
import '../../core/services/timer_notification_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final void Function({
    double? initialDurationMinutes,
    DateTime? initialStartTime,
    DateTime? initialEndTime,
  }) onAddLogTap;
  final Function({
    double? initialDurationMinutes,
    DateTime? initialStartTime,
    DateTime? initialEndTime,
    String? initialCategory,
  })? onLogExerciseTap;
  final bool isNavVisible;

  const DashboardScreen({
    super.key,
    required this.onAddLogTap,
    this.onLogExerciseTap,
    this.isNavVisible = true,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver {
  Timer? _timer;

  // Quick Session Stopwatch State
  bool _isStopwatchRunning = false;
  int _stopwatchSeconds = 0;
  DateTime? _stopwatchStartTime;
  Timer? _stopwatchTimer;

  // Exercise Stopwatch State
  bool _isExerciseStopwatchRunning = false;
  int _exerciseStopwatchSeconds = 0;
  DateTime? _exerciseStopwatchStartTime;
  Timer? _exerciseStopwatchTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      if (_isStopwatchRunning && _stopwatchStartTime != null) {
        setState(() {
          _stopwatchSeconds = DateTime.now().difference(_stopwatchStartTime!).inSeconds;
        });
      }
      if (_isExerciseStopwatchRunning && _exerciseStopwatchStartTime != null) {
        setState(() {
          _exerciseStopwatchSeconds = DateTime.now().difference(_exerciseStopwatchStartTime!).inSeconds;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _stopwatchTimer?.cancel();
    _exerciseStopwatchTimer?.cancel();
    TimerNotificationService.instance.disableWakelock();
    super.dispose();
  }

  void _startStopwatch() {
    HapticService.selectionClick();
    _stopwatchStartTime = DateTime.now().subtract(Duration(seconds: _stopwatchSeconds));
    setState(() {
      _isStopwatchRunning = true;
    });
    TimerNotificationService.instance.enableWakelock();
    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isStopwatchRunning && _stopwatchStartTime != null) {
        setState(() {
          _stopwatchSeconds = DateTime.now().difference(_stopwatchStartTime!).inSeconds;
        });
      }
    });
  }

  void _toggleStopwatch() {
    HapticService.selectionClick();
    if (_isStopwatchRunning) {
      _stopwatchTimer?.cancel();
      setState(() {
        _isStopwatchRunning = false;
      });
      TimerNotificationService.instance.disableWakelock();
    } else {
      _startStopwatch();
    }
  }

  void _resetStopwatch() {
    HapticService.selectionClick();
    _stopwatchTimer?.cancel();
    setState(() {
      _isStopwatchRunning = false;
      _stopwatchSeconds = 0;
      _stopwatchStartTime = null;
    });
    TimerNotificationService.instance.disableWakelock();
  }

  void _finishAndLogStopwatch() {
    HapticService.heavyImpact();
    final totalSecs = _stopwatchSeconds;
    final durationMins = (totalSecs / 60.0).clamp(1.0, 360.0);
    final start = _stopwatchStartTime ?? DateTime.now().subtract(Duration(seconds: totalSecs));
    final end = DateTime.now();

    _stopwatchTimer?.cancel();
    setState(() {
      _isStopwatchRunning = false;
      _stopwatchSeconds = 0;
      _stopwatchStartTime = null;
    });
    TimerNotificationService.instance.disableWakelock();

    widget.onAddLogTap(
      initialDurationMinutes: durationMins,
      initialStartTime: start,
      initialEndTime: end,
    );
  }

  void _startExerciseStopwatch() {
    HapticService.selectionClick();
    _exerciseStopwatchStartTime = DateTime.now().subtract(Duration(seconds: _exerciseStopwatchSeconds));
    setState(() {
      _isExerciseStopwatchRunning = true;
    });
    TimerNotificationService.instance.enableWakelock();
    _exerciseStopwatchTimer?.cancel();
    _exerciseStopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isExerciseStopwatchRunning && _exerciseStopwatchStartTime != null) {
        setState(() {
          _exerciseStopwatchSeconds = DateTime.now().difference(_exerciseStopwatchStartTime!).inSeconds;
        });
      }
    });
  }

  void _toggleExerciseStopwatch() {
    HapticService.selectionClick();
    if (_isExerciseStopwatchRunning) {
      _exerciseStopwatchTimer?.cancel();
      setState(() {
        _isExerciseStopwatchRunning = false;
      });
      TimerNotificationService.instance.disableWakelock();
    } else {
      _startExerciseStopwatch();
    }
  }

  void _resetExerciseStopwatch() {
    HapticService.selectionClick();
    _exerciseStopwatchTimer?.cancel();
    setState(() {
      _isExerciseStopwatchRunning = false;
      _exerciseStopwatchSeconds = 0;
      _exerciseStopwatchStartTime = null;
    });
    TimerNotificationService.instance.disableWakelock();
  }

  void _finishAndLogExerciseStopwatch() {
    HapticService.heavyImpact();
    final totalSecs = _exerciseStopwatchSeconds;
    final durationMins = (totalSecs / 60.0).clamp(1.0, 360.0);
    final start = _exerciseStopwatchStartTime ?? DateTime.now().subtract(Duration(seconds: totalSecs));
    final end = DateTime.now();

    _exerciseStopwatchTimer?.cancel();
    setState(() {
      _isExerciseStopwatchRunning = false;
      _exerciseStopwatchSeconds = 0;
      _exerciseStopwatchStartTime = null;
    });
    TimerNotificationService.instance.disableWakelock();

    widget.onLogExerciseTap?.call(
      initialDurationMinutes: durationMins,
      initialStartTime: start,
      initialEndTime: end,
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = ref.watch(statsProvider);
    final settings = ref.watch(settingsProvider);
    final allLogs = ref.watch(logsProvider);

    final now = DateTime.now();
    final lastReset = settings.lastStreakResetTime;
    final streak = stats.currentStreak ?? (lastReset != null ? now.difference(lastReset) : null);

    final days = streak?.inDays ?? 0;
    final hours = (streak?.inHours ?? 0) % 24;
    final minutes = (streak?.inMinutes ?? 0) % 60;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 90, left: 16, right: 16, bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_outlined, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Current Streak', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimerUnit(days.toString(), 'Days', theme),
                          _buildTimerUnit(hours.toString().padLeft(2, '0'), 'Hours', theme),
                          _buildTimerUnit(minutes.toString().padLeft(2, '0'), 'Minutes', theme),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Time since last masturbation session', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Session Stopwatch Card
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  color: theme.colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _isStopwatchRunning ? AppTheme.secondaryCyan.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: _isStopwatchRunning ? AppTheme.secondaryCyan : theme.colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                settings.stealthMode ? 'Focus Stopwatch' : 'Session Stopwatch',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isStopwatchRunning
                                  ? Colors.greenAccent.withOpacity(0.15)
                                  : (_stopwatchSeconds > 0 ? Colors.amberAccent.withOpacity(0.15) : Colors.white.withOpacity(0.06)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isStopwatchRunning
                                    ? Colors.greenAccent.withOpacity(0.4)
                                    : (_stopwatchSeconds > 0 ? Colors.amberAccent.withOpacity(0.4) : Colors.white10),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _isStopwatchRunning
                                        ? Colors.greenAccent
                                        : (_stopwatchSeconds > 0 ? Colors.amberAccent : Colors.white38),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isStopwatchRunning ? 'ACTIVE' : (_stopwatchSeconds > 0 ? 'PAUSED' : 'READY'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: _isStopwatchRunning
                                        ? Colors.greenAccent
                                        : (_stopwatchSeconds > 0 ? Colors.amberAccent : Colors.white54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Monospace Time Display
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isStopwatchRunning ? AppTheme.secondaryCyan.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Text(
                            _formatStopwatchTime(_stopwatchSeconds),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 2.0,
                              color: _isStopwatchRunning ? AppTheme.secondaryCyan : (_stopwatchSeconds > 0 ? Colors.white : Colors.white70),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Control Buttons
                      if (!_isStopwatchRunning && _stopwatchSeconds == 0)
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _startStopwatch,
                            icon: const Icon(Icons.play_arrow_rounded, size: 22),
                            label: Text(
                              settings.stealthMode ? 'Start Focus Session' : 'Start Session Stopwatch',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _isStopwatchRunning ? Colors.amberAccent : Colors.white,
                                  side: BorderSide(
                                    color: _isStopwatchRunning ? Colors.amberAccent.withOpacity(0.5) : Colors.white24,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: _toggleStopwatch,
                                icon: Icon(_isStopwatchRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                                label: Text(_isStopwatchRunning ? 'Pause' : 'Resume', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white60),
                              tooltip: 'Reset Timer',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.06),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _resetStopwatch,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondaryCyan,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: _finishAndLogStopwatch,
                                icon: const Icon(Icons.check_circle_rounded, size: 18),
                                label: const Text('Finish & Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Exercise Stopwatch Card
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  color: theme.colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _isExerciseStopwatchRunning ? AppTheme.secondaryCyan.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    color: _isExerciseStopwatchRunning ? AppTheme.secondaryCyan : Colors.white70,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    settings.stealthMode ? 'Fitness Stopwatch' : 'Exercise Stopwatch',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isExerciseStopwatchRunning
                                  ? Colors.greenAccent.withOpacity(0.15)
                                  : (_exerciseStopwatchSeconds > 0 ? Colors.amberAccent.withOpacity(0.15) : Colors.white.withOpacity(0.06)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isExerciseStopwatchRunning
                                    ? Colors.greenAccent.withOpacity(0.4)
                                    : (_exerciseStopwatchSeconds > 0 ? Colors.amberAccent.withOpacity(0.4) : Colors.white10),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _isExerciseStopwatchRunning
                                        ? Colors.greenAccent
                                        : (_exerciseStopwatchSeconds > 0 ? Colors.amberAccent : Colors.white38),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isExerciseStopwatchRunning
                                      ? 'ACTIVE'
                                      : (_exerciseStopwatchSeconds > 0 ? 'PAUSED' : 'READY'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: _isExerciseStopwatchRunning
                                        ? Colors.greenAccent
                                        : (_exerciseStopwatchSeconds > 0 ? Colors.amberAccent : Colors.white54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _formatStopwatchTime(_exerciseStopwatchSeconds),
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: _isExerciseStopwatchRunning ? AppTheme.secondaryCyan : Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_isExerciseStopwatchRunning && _exerciseStopwatchSeconds == 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryCyan.withOpacity(0.2),
                              foregroundColor: AppTheme.secondaryCyan,
                              side: const BorderSide(color: AppTheme.secondaryCyan, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: _startExerciseStopwatch,
                            icon: const Icon(Icons.play_arrow_rounded, size: 22),
                            label: Text(
                              settings.stealthMode ? 'Start Workout Timer' : 'Start Exercise Stopwatch',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _isExerciseStopwatchRunning ? Colors.amberAccent : Colors.white,
                                  side: BorderSide(
                                    color: _isExerciseStopwatchRunning ? Colors.amberAccent.withOpacity(0.5) : Colors.white24,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: _toggleExerciseStopwatch,
                                icon: Icon(_isExerciseStopwatchRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                                label: Text(_isExerciseStopwatchRunning ? 'Pause' : 'Resume', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white60),
                              tooltip: 'Reset Timer',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.06),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _resetExerciseStopwatch,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondaryCyan,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: _finishAndLogExerciseStopwatch,
                                icon: const Icon(Icons.check_circle_rounded, size: 18),
                                label: const Text('Log Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _buildInteractiveCounterCard(
                      title: 'Edge',
                      count: settings.currentEdgeCount,
                      icon: Icons.bolt,
                      accentColor: Colors.amberAccent,
                      backgroundColor: Colors.amber.withOpacity(0.08),
                      onIncrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateEdgeCount(settings.currentEdgeCount + 1);
                      },
                      onDecrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateEdgeCount((settings.currentEdgeCount - 1).clamp(0, 999));
                      },
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildInteractiveCounterCard(
                      title: 'Arousal',
                      count: settings.currentArousalCount,
                      icon: Icons.local_fire_department,
                      accentColor: Colors.deepOrangeAccent,
                      backgroundColor: Colors.deepOrange.withOpacity(0.08),
                      onIncrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateArousalCount(settings.currentArousalCount + 1);
                      },
                      onDecrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateArousalCount((settings.currentArousalCount - 1).clamp(0, 999));
                      },
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildInteractiveCounterCard(
                      title: 'Urge',
                      count: settings.currentUrgeCount,
                      icon: Icons.whatshot,
                      accentColor: Colors.redAccent,
                      backgroundColor: Colors.red.withOpacity(0.08),
                      onIncrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateUrgeCount(settings.currentUrgeCount + 1);
                      },
                      onDecrement: () {
                        HapticService.selectionClick();
                        ref.read(settingsProvider.notifier).updateUrgeCount((settings.currentUrgeCount - 1).clamp(0, 999));
                      },
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                GlassCard(
                  child: HeatmapCalendar(logs: allLogs),
                ),
                const SizedBox(height: 24),

                Text('Personal Bests & All-Time Highs', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                GlassCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Highest Interval', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('${stats.maxIntervalDays.toStringAsFixed(1)} Days', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text('Max Edges Recorded', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('${stats.maxEdgeCount}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.white12),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Longest Session', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('${stats.maxSessionDurationMinutes.toStringAsFixed(0)} Mins', style: const TextStyle(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text('Max Satisfaction', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('${stats.maxSatisfaction} / 10', style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Habit Insights & Averages', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _buildStatCard('Avg Interval', '${stats.avgIntervalDays.toStringAsFixed(1)} Days', Icons.calendar_month, theme),
                    _buildStatCard('Avg Duration', '${stats.avgSessionDurationMinutes.toStringAsFixed(1)} Mins', Icons.schedule, theme),
                    _buildStatCard('Edging / Session', stats.avgEdgingBeforeOrgasm.toStringAsFixed(1), Icons.bolt, theme),
                    _buildStatCard('Avg Cleanup', '${(stats.avgCleanupTimeSeconds / 60).toStringAsFixed(1)} Mins', Icons.cleaning_services, theme),
                    _buildStatCard('Satisfaction', '${stats.avgSatisfaction.toStringAsFixed(1)} / 10', Icons.sentiment_satisfied, theme),
                    _buildStatCard('Regret', '${stats.avgRegret.toStringAsFixed(1)} / 10', Icons.sentiment_neutral, theme),
                    _buildStatCard('Avg Urge', '${stats.avgUrge.toStringAsFixed(1)} / 10', Icons.local_fire_department, theme),
                    _buildStatCard('Orgasm Quality', '${stats.avgOrgasmQuality.toStringAsFixed(1)} / 10', Icons.star_outline, theme),
                    _buildStatCard('Top Trigger', stats.mostCommonTrigger, Icons.bolt_outlined, theme),
                    _buildStatCard('Top Stimulus', stats.mostCommonStimulus, Icons.movie_outlined, theme),
                    _buildStatCard('Top Reason', stats.mostCommonReason, Icons.psychology_outlined, theme),
                    _buildStatCard('Top Mood', stats.mostCommonMood, Icons.mood, theme),
                    _buildStatCard('Water Before', '${stats.avgWaterBeforeMl.toStringAsFixed(0)} ml', Icons.water_drop_outlined, theme),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingTopBar(
              title: settings.stealthMode ? 'Daily Notes Dashboard' : 'Nutmate Dashboard',
              isVisible: widget.isNavVisible,
              actions: [
                IconButton(
                  icon: Icon(Icons.self_improvement, color: AppTheme.secondaryCyan),
                  onPressed: () {
                    HapticService.selectionClick();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const BreathingModal(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: AppTheme.secondaryCyan),
                  onPressed: () {
                    HapticService.lightImpact();
                    widget.onAddLogTap();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerUnit(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInteractiveCounterCard({
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
    required Color backgroundColor,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required ThemeData theme,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        color: backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      count == 1 ? 'time' : 'times',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: count > 0 ? onDecrement : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(count > 0 ? 0.1 : 0.03),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.remove, size: 16, color: count > 0 ? Colors.white70 : Colors.white24),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onIncrement,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.add, size: 16, color: accentColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
