import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/db_helper.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/reminder_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/log_entry.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import 'add_log_screen.dart';
import 'dashboard_screen.dart';
import 'exercise_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'timeline_screen.dart';
import 'watch_log_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isNavVisible = true;
  double? _bridgedPreContentDuration;
  List<String>? _bridgedPreContentTypes;
  double? _bridgedSessionDuration;
  DateTime? _bridgedSessionStartTime;
  DateTime? _bridgedSessionEndTime;
  double? _bridgedExerciseDuration;
  DateTime? _bridgedExerciseStartTime;
  DateTime? _bridgedExerciseEndTime;
  String? _bridgedExerciseCategory;
  double? _exerciseDurationForAddLog;
  String? _exerciseCategoryForAddLog;
  LogEntry? _editingLogFromNotification;
  bool _focusPostNutFromNotification = false;
  StreamSubscription<int>? _notificationSubscription;
  Key _addLogKey = UniqueKey();
  Key _exerciseKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ReminderService.initialize();
    _notificationSubscription = ReminderService.onNotificationClicked.listen((logId) {
      _handleNotificationClick(logId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BackupService.checkAndPerformAutoBackup(ref);
      _checkPendingNotificationLaunch();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BackupService.checkAndPerformAutoBackup(ref);
      _checkPendingNotificationLaunch();
    }
  }

  Future<void> _checkPendingNotificationLaunch() async {
    final logId = await ReminderService.getPendingPostNutLogId();
    if (logId != null && logId > 0) {
      _handleNotificationClick(logId);
    }
  }

  Future<void> _handleNotificationClick(int logId) async {
    try {
      final allLogs = ref.read(logsProvider);
      LogEntry? targetLog;
      for (final l in allLogs) {
        if (l.id == logId) {
          targetLog = l;
          break;
        }
      }
      if (targetLog == null) {
        final dbLogs = await DBHelper.instance.getAllLogs();
        for (final l in dbLogs) {
          if (l.id == logId) {
            targetLog = l;
            break;
          }
        }
      }
      if (targetLog != null && mounted) {
        setState(() {
          _editingLogFromNotification = targetLog;
          _focusPostNutFromNotification = true;
          _addLogKey = UniqueKey();
          _currentIndex = 2;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final accentColor = AppTheme.getAccentColor(settings.accentColor);

    final screens = [
      DashboardScreen(
        onAddLogTap: ({initialDurationMinutes, initialStartTime, initialEndTime}) {
          setState(() {
            _bridgedSessionDuration = initialDurationMinutes;
            _bridgedSessionStartTime = initialStartTime;
            _bridgedSessionEndTime = initialEndTime;
            _editingLogFromNotification = null;
            _focusPostNutFromNotification = false;
            _addLogKey = UniqueKey();
            _currentIndex = 2;
          });
        },
        onLogExerciseTap: ({initialDurationMinutes, initialStartTime, initialEndTime, initialCategory}) {
          setState(() {
            _bridgedExerciseDuration = initialDurationMinutes;
            _bridgedExerciseStartTime = initialStartTime;
            _bridgedExerciseEndTime = initialEndTime;
            _bridgedExerciseCategory = initialCategory;
            _exerciseKey = UniqueKey();
            _currentIndex = 1;
          });
        },
        isNavVisible: _isNavVisible,
      ),
      ExerciseScreen(
        key: _exerciseKey,
        isNavVisible: _isNavVisible,
        initialDurationMinutes: _bridgedExerciseDuration,
        initialStartTime: _bridgedExerciseStartTime,
        initialEndTime: _bridgedExerciseEndTime,
        initialCategory: _bridgedExerciseCategory,
        onBridgeToHabit: (duration, category) {
          setState(() {
            _exerciseDurationForAddLog = duration;
            _exerciseCategoryForAddLog = category;
            _addLogKey = UniqueKey();
            _currentIndex = 2;
          });
        },
      ),
      AddLogScreen(
        key: _addLogKey,
        existingLog: _editingLogFromNotification,
        focusPostNut: _focusPostNutFromNotification,
        isNavVisible: _isNavVisible,
        initialPreContentDuration: _bridgedPreContentDuration,
        initialPreContentTypes: _bridgedPreContentTypes,
        initialSessionDuration: _bridgedSessionDuration,
        initialSessionStartTime: _bridgedSessionStartTime,
        initialSessionEndTime: _bridgedSessionEndTime,
        initialExerciseDuration: _exerciseDurationForAddLog,
        initialExerciseCategory: _exerciseCategoryForAddLog,
        onSaved: () {
          setState(() {
            _bridgedPreContentDuration = null;
            _bridgedPreContentTypes = null;
            _bridgedSessionDuration = null;
            _bridgedSessionStartTime = null;
            _bridgedSessionEndTime = null;
            _exerciseDurationForAddLog = null;
            _exerciseCategoryForAddLog = null;
            _editingLogFromNotification = null;
            _focusPostNutFromNotification = false;
            _addLogKey = UniqueKey();
            _currentIndex = 0;
          });
        },
      ),
      WatchLogScreen(
        isNavVisible: _isNavVisible,
        onBridgeToMasturbation: (duration, types) {
          setState(() {
            _bridgedPreContentDuration = duration;
            _bridgedPreContentTypes = types;
            _addLogKey = UniqueKey();
            _currentIndex = 2;
          });
        },
      ),
      TimelineScreen(isNavVisible: _isNavVisible),
      StatisticsScreen(isNavVisible: _isNavVisible),
      SettingsScreen(isNavVisible: _isNavVisible),
    ];

    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isNavVisible) setState(() => _isNavVisible = false);
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isNavVisible) setState(() => _isNavVisible = true);
          }
          return true;
        },
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        offset: _isNavVisible ? Offset.zero : const Offset(0, 1.5),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            borderRadius: BorderRadius.circular(30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, settings.stealthMode ? 'Home' : 'Dashboard', accentColor),
                _buildNavItem(1, Icons.fitness_center_outlined, Icons.fitness_center, settings.stealthMode ? 'Fitness' : 'Exercise', accentColor),
                _buildNavItem(2, Icons.add_circle_outline, Icons.add_circle, '+ Habit', accentColor),
                _buildNavItem(3, Icons.movie_filter_outlined, Icons.movie_filter, settings.stealthMode ? 'Media' : '🎬 Watch', accentColor),
                _buildNavItem(4, Icons.history_outlined, Icons.history, settings.stealthMode ? 'Notes' : 'Timeline', accentColor),
                _buildNavItem(5, Icons.bar_chart_outlined, Icons.bar_chart, 'Stats', accentColor),
                _buildNavItem(6, Icons.settings_outlined, Icons.settings, 'Settings', accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, Color accentColor) {
    final isSelected = _currentIndex == index;
    return Flexible(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? accentColor : Colors.white54,
                size: 19,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? accentColor : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
