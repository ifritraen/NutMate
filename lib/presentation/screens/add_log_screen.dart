import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/log_entry.dart';
import '../providers/app_providers.dart';
import '../widgets/chip_selector.dart';
import '../widgets/cleanup_timer_modal.dart';
import '../widgets/floating_top_bar.dart';
import '../widgets/glass_card.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  final LogEntry? existingLog;
  final bool isNavVisible;
  final VoidCallback? onSaved;

  const AddLogScreen({
    super.key,
    this.existingLog,
    this.isNavVisible = true,
    this.onSaved,
  });

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  SessionType _sessionType = SessionType.masturbation;

  // Section Collapsible Toggles
  bool _isPreNutExpanded = true;
  bool _isBeforeExpanded = true;
  bool _isDuringExpanded = true;
  bool _isAfterExpanded = true;
  bool _isPostNutExpanded = true;

  // Pre-Nut (within 2h before) - Masturbation Only
  String _preWater = 'None';
  String _preWorkout = 'None';
  bool _preMeditation = false;
  double _preMeditationDuration = 0.0;
  double _preSleepQuality = 5.0;
  double _preSleepHours = 7.0;
  double _preNapDuration = 0.0;
  String _preMeal = 'None';
  bool _preCoffee = false;
  bool _preAlcohol = false;

  // Before
  double _urge = 5.0;
  String _mood = 'Relaxed';
  String _trigger = '🧠 Stress & Anxiety';
  bool _isPlanned = false;
  String _location = 'Home';
  List<String> _tags = [];
  final TextEditingController _beforeNotesController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  // During
  late DateTime _startTime;
  late DateTime _endTime;
  double _durationMinutes = 15.0;
  String _method = 'Hand';
  List<String> _contentUsed = [];
  String _stimulus = '💭 Pure Imagination / Fantasy';
  String _position = 'Lying';

  // Live Timer / Stopwatch State
  bool _isTimerRunning = false;
  int _timerSeconds = 0;
  Timer? _stopwatchTimer;

  // After (Masturbation)
  double _satisfaction = 5.0;
  double _orgasmQuality = 5.0;
  double _regret = 1.0;
  double _cleanupDurationMinutes = 0.0;

  // Post-Nut (within 1h after orgasm) - Masturbation Only
  String _postWater = 'None';
  bool _postStretch = false;
  double _postStretchDuration = 0.0;
  String _postMeal = 'None';
  bool _postNap = false;
  double _postNapDuration = 0.0;
  bool _postMeditation = false;
  double _postMeditationDuration = 0.0;

  // Edging Specific
  double _nearOrgasmCount = 1.0;
  String _endingReason = '';

  // Session DateTime for Backdating/Editing
  DateTime _sessionDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _resetForm();
  }

  void _resetForm() {
    final now = DateTime.now();
    _endTime = now;
    _startTime = now.subtract(const Duration(minutes: 15));
    _sessionDateTime = widget.existingLog?.createdAt ?? now;

    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _sessionType = log.type;

      _preWater = log.preWater.isEmpty ? 'None' : log.preWater;
      _preWorkout = log.preWorkout.isEmpty ? 'None' : log.preWorkout;
      _preMeditation = log.preMeditation;
      _preMeditationDuration = log.preMeditationDuration.toDouble();
      _preSleepQuality = log.preSleepQuality.toDouble();
      _preSleepHours = log.preSleepHours;
      _preNapDuration = log.preNapDuration.toDouble();
      _preMeal = log.preMeal.isEmpty ? 'None' : log.preMeal;
      _preCoffee = log.preCoffee;
      _preAlcohol = log.preAlcohol;

      _urge = log.urge.toDouble();
      _mood = log.mood.isEmpty ? 'Relaxed' : log.mood;
      _trigger = log.trigger.isEmpty ? '🧠 Stress & Anxiety' : log.trigger;
      _location = log.location.isEmpty ? 'Home' : log.location;
      _tags = List<String>.from(log.tags);
      _isPlanned = log.isPlanned;
      _beforeNotesController.text = log.beforeNotes;

      _startTime = log.startTime;
      _endTime = log.endTime;
      _durationMinutes = log.durationMinutes <= 0 ? 15.0 : log.durationMinutes;
      _method = log.method.isEmpty ? 'Hand' : log.method;
      _contentUsed = List<String>.from(log.contentUsed);
      _stimulus = log.stimulus.isEmpty ? '💭 Pure Imagination / Fantasy' : log.stimulus;
      _position = log.position.isEmpty ? 'Lying' : log.position;

      _satisfaction = log.satisfaction.toDouble();
      _orgasmQuality = log.orgasmQuality.toDouble();
      _regret = log.regret.toDouble();
      _cleanupDurationMinutes = (log.cleanupDurationSeconds / 60.0).clamp(0.0, 30.0);

      _postWater = log.postWater.isEmpty ? 'None' : log.postWater;
      _postStretch = log.postStretch;
      _postStretchDuration = log.postStretchDuration.toDouble();
      _postMeal = log.postMeal.isEmpty ? 'None' : log.postMeal;
      _postNap = log.postNap;
      _postNapDuration = log.postNapDuration.toDouble();
      _postMeditation = log.postMeditation;
      _postMeditationDuration = log.postMeditationDuration.toDouble();

      _nearOrgasmCount = log.nearOrgasmCount.toDouble();
      _endingReason = log.endingReason;
    } else {
      _sessionType = SessionType.masturbation;
      _preWater = 'None';
      _preWorkout = 'None';
      _preMeditation = false;
      _preMeditationDuration = 0.0;
      _preSleepQuality = 5.0;
      _preSleepHours = 7.0;
      _preNapDuration = 0.0;
      _preMeal = 'None';
      _preCoffee = false;
      _preAlcohol = false;

      _urge = 5.0;
      _mood = 'Relaxed';
      _trigger = '🧠 Stress & Anxiety';
      _isPlanned = false;
      _location = 'Home';
      _tags = [];
      _beforeNotesController.clear();

      _durationMinutes = 15.0;
      _method = 'Hand';
      _contentUsed = [];
      _stimulus = '💭 Pure Imagination / Fantasy';
      _position = 'Lying';
      _timerSeconds = 0;
      _isTimerRunning = false;

      _satisfaction = 5.0;
      _orgasmQuality = 5.0;
      _regret = 1.0;
      _cleanupDurationMinutes = 0.0;

      _postWater = 'None';
      _postStretch = false;
      _postStretchDuration = 0.0;
      _postMeal = 'None';
      _postNap = false;
      _postNapDuration = 0.0;
      _postMeditation = false;
      _postMeditationDuration = 0.0;

      _nearOrgasmCount = 1.0;
      _endingReason = '';
    }
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _beforeNotesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _toggleLiveTimer() {
    HapticService.selectionClick();
    if (_isTimerRunning) {
      _stopwatchTimer?.cancel();
      setState(() {
        _isTimerRunning = false;
        _durationMinutes = (_timerSeconds / 60.0).clamp(1.0, 240.0);
      });
    } else {
      setState(() {
        _isTimerRunning = true;
        _startTime = DateTime.now();
      });
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _timerSeconds++;
          _durationMinutes = (_timerSeconds / 60.0).clamp(1.0, 240.0);
        });
      });
    }
  }

  void _addTag(String tag) {
    var cleaned = tag.trim().replaceAll(' ', '_');
    if (!cleaned.startsWith('#')) cleaned = '#$cleaned';
    if (cleaned.length > 1 && !_tags.contains(cleaned)) {
      setState(() {
        _tags.add(cleaned);
        _tagController.clear();
      });
    }
  }

  void _openCleanupTimerModal() {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CleanupTimerModal(
        onFinished: (secs) {
          setState(() {
            _cleanupDurationMinutes = (secs / 60.0).clamp(0.0, 30.0);
          });
        },
      ),
    );
  }

  Future<void> _saveLog() async {
    try {
      HapticService.heavyImpact();
      final settings = ref.read(settingsProvider);
      final stats = ref.read(statsProvider);
      final now = DateTime.now();

      final lastReset = settings.lastStreakResetTime;
      final streak = lastReset != null ? now.difference(lastReset) : stats.currentStreak;
      final streakText = streak != null ? '${streak.inDays}d ${streak.inHours % 24}h ${streak.inMinutes % 60}m' : '0d 0h 0m';

      final log = LogEntry(
        id: widget.existingLog?.id,
        createdAt: _sessionDateTime,
        updatedAt: now,
        type: _sessionType,
        preWater: _preWater.trim().isEmpty ? 'None' : _preWater,
        preWorkout: _preWorkout.trim().isEmpty ? 'None' : _preWorkout,
        preMeditation: _preMeditation,
        preMeditationDuration: _preMeditationDuration.round(),
        preSleepQuality: _preSleepQuality.round(),
        preSleepHours: _preSleepHours,
        preNapDuration: _preNapDuration.round(),
        preMeal: _preMeal.trim().isEmpty ? 'None' : _preMeal,
        preCoffee: _preCoffee,
        preAlcohol: _preAlcohol,
        urge: _urge.round(),
        mood: _mood.trim().isEmpty ? 'Relaxed' : _mood,
        trigger: _trigger.trim().isEmpty ? '🧠 Stress & Anxiety' : _trigger,
        isPlanned: _isPlanned,
        location: _location.trim().isEmpty ? 'Home' : _location,
        tags: _tags,
        beforeNotes: _beforeNotesController.text,
        timeSinceLastOrgasmText: streakText,
        lastEdgingCount: settings.currentEdgeCount,
        startTime: _sessionDateTime.subtract(Duration(minutes: _durationMinutes.round())),
        endTime: _sessionDateTime,
        durationMinutes: _durationMinutes,
        method: _method.trim().isEmpty ? 'Hand' : _method,
        contentUsed: _contentUsed,
        stimulus: _stimulus,
        position: _position.trim().isEmpty ? 'Lying' : _position,
        satisfaction: _satisfaction.round(),
        orgasmQuality: _orgasmQuality.round(),
        regret: _regret.round(),
        cleanupDurationSeconds: (_cleanupDurationMinutes * 60).round(),
        postWater: _postWater.trim().isEmpty ? 'None' : _postWater,
        postStretch: _postStretch,
        postStretchDuration: _postStretchDuration.round(),
        postMeal: _postMeal.trim().isEmpty ? 'None' : _postMeal,
        postNap: _postNap,
        postNapDuration: _postNapDuration.round(),
        postMeditation: _postMeditation,
        postMeditationDuration: _postMeditationDuration.round(),
        edgingCountBeforeOrgasm: _sessionType == SessionType.masturbation ? settings.currentEdgeCount : 0,
        nearOrgasmCount: _nearOrgasmCount.round(),
        endingReason: _endingReason,
      );

      if (widget.existingLog != null) {
        await ref.read(logsProvider.notifier).updateLog(log);
      } else {
        await ref.read(logsProvider.notifier).addLog(log);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _sessionType == SessionType.masturbation
                  ? 'Masturbation session saved successfully!'
                  : (_sessionType == SessionType.edging ? 'Edging session saved successfully!' : 'Arousal session saved successfully!'),
            ),
            backgroundColor: AppTheme.primaryViolet,
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          setState(() {
            _resetForm();
          });
          widget.onSaved?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save log: $errorString',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'COPY',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: errorString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error log copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final stats = ref.watch(statsProvider);

    final lastReset = settings.lastStreakResetTime;
    final streak = lastReset != null ? DateTime.now().difference(lastReset) : stats.currentStreak;
    final timeSinceOrgasmText = streak != null ? '${streak.inDays}d ${streak.inHours % 24}h ${streak.inMinutes % 60}m' : '0d 0h 0m';

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 90, left: 16, right: 16, bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SESSION TYPE SELECTOR ---
                GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('💦 Masturbation')),
                          selected: _sessionType == SessionType.masturbation,
                          selectedColor: theme.colorScheme.primary.withOpacity(0.4),
                          onSelected: (val) {
                            if (val) {
                              HapticService.selectionClick();
                              setState(() => _sessionType = SessionType.masturbation);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('⚡ Edging')),
                          selected: _sessionType == SessionType.edging,
                          selectedColor: Colors.amber.withOpacity(0.4),
                          onSelected: (val) {
                            if (val) {
                              HapticService.selectionClick();
                              setState(() => _sessionType = SessionType.edging);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('🔥 Arousal')),
                          selected: _sessionType == SessionType.arousal,
                          selectedColor: Colors.deepOrange.withOpacity(0.4),
                          onSelected: (val) {
                            if (val) {
                              HapticService.selectionClick();
                              setState(() => _sessionType = SessionType.arousal);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // --- SESSION DATE & TIME SELECTOR ---
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_outlined, color: AppTheme.secondaryCyan, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Session Date & Time',
                            style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Adjust date and time if editing or backdating a past session',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      Row(
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
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(_sessionDateTime),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.white70),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('hh:mm a').format(_sessionDateTime),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ==========================================
                // 1. PRE-NUT SECTION (COLLAPSIBLE)
                // ==========================================
                if (_sessionType == SessionType.masturbation) ...[
                  _buildSectionHeader(
                    title: 'Pre-Nut (Within 2h Before)',
                    subtitle: 'Short-window habits recorded close to session',
                    isExpanded: _isPreNutExpanded,
                    onToggle: () => setState(() => _isPreNutExpanded = !_isPreNutExpanded),
                  ),
                  if (_isPreNutExpanded) ...[
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChipSelector(
                            title: 'Water Intake',
                            options: const ['None', '250 ml', '500 ml', '1L+'],
                            selectedSingle: _preWater,
                            onSingleSelected: (val) => setState(() => _preWater = val),
                          ),
                          const SizedBox(height: 16),
                          ChipSelector(
                            title: 'Workout / Activity',
                            options: const ['None', 'Stretch', 'Walk', 'Cardio', 'Gym'],
                            selectedSingle: _preWorkout,
                            onSingleSelected: (val) => setState(() => _preWorkout = val),
                          ),
                          const SizedBox(height: 16),
                          ChipSelector(
                            title: 'Meal Intake',
                            options: const ['None', 'Light', 'Heavy'],
                            selectedSingle: _preMeal,
                            onSingleSelected: (val) => setState(() => _preMeal = val),
                          ),
                          const SizedBox(height: 16),
                          Text('Pre-Nut Meditation: ${_preMeditationDuration.round()} mins', style: theme.textTheme.titleMedium),
                          Slider(
                            value: _preMeditationDuration,
                            min: 0,
                            max: 60,
                            divisions: 60,
                            onChanged: (val) {
                              HapticService.selectionClick();
                              setState(() {
                                _preMeditationDuration = val;
                                _preMeditation = val > 0;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Text('Pre-Nut Nap / Sleep: ${_preNapDuration.round()} mins', style: theme.textTheme.titleMedium),
                          Slider(
                            value: _preNapDuration,
                            min: 0,
                            max: 120,
                            divisions: 120,
                            onChanged: (val) => setState(() => _preNapDuration = val),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Coffee', style: TextStyle(fontSize: 14)),
                                  value: _preCoffee,
                                  activeColor: AppTheme.secondaryCyan,
                                  onChanged: (val) => setState(() => _preCoffee = val),
                                ),
                              ),
                              Expanded(
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Alcohol', style: TextStyle(fontSize: 14)),
                                  value: _preAlcohol,
                                  activeColor: AppTheme.secondaryCyan,
                                  onChanged: (val) => setState(() => _preAlcohol = val),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],

                // ==========================================
                // 2. BEFORE SECTION (COLLAPSIBLE)
                // ==========================================
                _buildSectionHeader(
                  title: 'Before Session',
                  subtitle: 'Mood, trigger, and habit stats',
                  isExpanded: _isBeforeExpanded,
                  onToggle: () => setState(() => _isBeforeExpanded = !_isBeforeExpanded),
                ),
                if (_isBeforeExpanded) ...[
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Time Since Last Orgasm', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(timeSinceOrgasmText, style: const TextStyle(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              Container(width: 1, height: 28, color: Colors.white12),
                              Column(
                                children: [
                                  const Text('Last Edging Count', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text('${settings.currentEdgeCount} times', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ChipSelector(
                          title: 'Mood',
                          options: const ['Relaxed', 'Stressed', 'Anxious', 'Excited', 'Tired', 'Bored', 'Lonely'],
                          selectedSingle: _mood,
                          onSingleSelected: (val) => setState(() => _mood = val),
                        ),
                        const SizedBox(height: 16),
                        ChipSelector(
                          title: 'Trigger',
                          options: const [
                            '🧠 Stress & Anxiety',
                            '🎬 Adult Content / NSFW',
                            '📱 Social Media Scrolling',
                            '🥱 Boredom / Free Time',
                            '🛌 Bedtime Routine',
                            '🔞 Erotic Fantasy',
                            '⚡ Physical Touch',
                          ],
                          selectedSingle: _trigger,
                          onSingleSelected: (val) => setState(() => _trigger = val),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Planned or Impulsive?'),
                          subtitle: Text(_isPlanned ? 'Planned ahead' : 'Impulsive urge'),
                          value: _isPlanned,
                          activeColor: AppTheme.secondaryCyan,
                          onChanged: (val) => setState(() => _isPlanned = val),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // ==========================================
                // 3. DURING SECTION (COLLAPSIBLE)
                // ==========================================
                _buildSectionHeader(
                  title: 'During Session',
                  subtitle: 'Body position, live timer & cleanup options',
                  isExpanded: _isDuringExpanded,
                  onToggle: () => setState(() => _isDuringExpanded = !_isDuringExpanded),
                ),
                if (_isDuringExpanded) ...[
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChipSelector(
                          title: 'Stimulus / Content Used',
                          options: const [
                            '🎬 Adult Video / Porn',
                            '🖼️ Erotic Images / Photos',
                            '🎨 Hentai / Manga / 2D',
                            '📚 Erotic Stories / Erotica',
                            '🎧 Audio / Erotic ASMR',
                            '💭 Pure Imagination / Fantasy',
                            '📱 Social Media / Feeds',
                          ],
                          selectedSingle: _stimulus,
                          onSingleSelected: (val) => setState(() => _stimulus = val),
                        ),
                        const SizedBox(height: 16),
                        ChipSelector(
                          title: 'Body Position',
                          options: const ['Lying', 'Sitting', 'Standing'],
                          selectedSingle: _position,
                          onSingleSelected: (val) => setState(() => _position = val),
                        ),
                        const SizedBox(height: 20),

                        // Live Session Stopwatch Widget
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.timer, color: AppTheme.secondaryCyan, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Session Live Timer', style: theme.textTheme.titleMedium),
                                    ],
                                  ),
                                  Text(
                                    '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isTimerRunning ? Colors.redAccent : theme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _toggleLiveTimer,
                                      icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                                      label: Text(_isTimerRunning ? 'Pause Timer' : 'Start Timer'),
                                    ),
                                  ),
                                  if (_timerSeconds > 0) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.refresh, color: Colors.white70),
                                      onPressed: () {
                                        _stopwatchTimer?.cancel();
                                        setState(() {
                                          _isTimerRunning = false;
                                          _timerSeconds = 0;
                                          _durationMinutes = 15.0;
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Session Duration: ${_durationMinutes.round()} mins', style: theme.textTheme.titleMedium),
                        Slider(
                          value: _durationMinutes,
                          min: 1,
                          max: 120,
                          divisions: 119,
                          onChanged: (val) {
                            HapticService.selectionClick();
                            setState(() => _durationMinutes = val);
                          },
                        ),
                        const SizedBox(height: 20),

                        // Post-Session Cleanup Section (Slider + Live Timer Modal Button)
                        Text('Post-Session Cleanup Time: ${_cleanupDurationMinutes.toStringAsFixed(1)} mins', style: theme.textTheme.titleMedium),
                        Slider(
                          value: _cleanupDurationMinutes,
                          min: 0,
                          max: 30,
                          divisions: 60,
                          onChanged: (val) {
                            HapticService.selectionClick();
                            setState(() => _cleanupDurationMinutes = val);
                          },
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.secondaryCyan,
                              side: BorderSide(color: AppTheme.secondaryCyan.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _openCleanupTimerModal,
                            icon: const Icon(Icons.timer_outlined, size: 18),
                            label: Text(_cleanupDurationMinutes > 0 ? 'Retake Live Cleanup Timer' : 'Start Live Cleanup Timer Modal'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // ==========================================
                // 4. AFTER & POST-NUT SECTIONS (MASTURBATION ONLY)
                // ==========================================
                if (_sessionType == SessionType.masturbation) ...[
                  _buildSectionHeader(
                    title: 'After Session',
                    subtitle: 'Satisfaction, orgasm quality & regret',
                    isExpanded: _isAfterExpanded,
                    onToggle: () => setState(() => _isAfterExpanded = !_isAfterExpanded),
                  ),
                  if (_isAfterExpanded) ...[
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Satisfaction Level: ${_satisfaction.round()}/10', style: theme.textTheme.titleMedium),
                          Slider(
                            value: _satisfaction,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (val) => setState(() => _satisfaction = val),
                          ),
                          const SizedBox(height: 12),
                          Text('Orgasm Quality: ${_orgasmQuality.round()}/10', style: theme.textTheme.titleMedium),
                          Slider(
                            value: _orgasmQuality,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (val) => setState(() => _orgasmQuality = val),
                          ),
                          const SizedBox(height: 12),
                          Text('Regret Level: ${_regret.round()}/10', style: theme.textTheme.titleMedium),
                          Slider(
                            value: _regret,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (val) => setState(() => _regret = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // POST-NUT SECTION (COLLAPSIBLE)
                  _buildSectionHeader(
                    title: 'Post-Nut (Within 1h After Orgasm)',
                    subtitle: 'Recovery habits, meal & activity sliders',
                    isExpanded: _isPostNutExpanded,
                    onToggle: () => setState(() => _isPostNutExpanded = !_isPostNutExpanded),
                  ),
                  if (_isPostNutExpanded) ...[
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChipSelector(
                            title: 'Water Intake',
                            options: const ['None', '250 ml', '500 ml', '1L+'],
                            selectedSingle: _postWater,
                            onSingleSelected: (val) => setState(() => _postWater = val),
                          ),
                          const SizedBox(height: 16),
                          ChipSelector(
                            title: 'Meal Intake',
                            options: const ['None', 'Light', 'Heavy'],
                            selectedSingle: _postMeal,
                            onSingleSelected: (val) => setState(() => _postMeal = val),
                          ),
                          const SizedBox(height: 16),
                          Text('Post-Nut Stretch: ${_postStretchDuration.round()} mins', style: theme.textTheme.titleMedium),
                          Slider(
                            value: _postStretchDuration,
                            min: 0,
                            max: 60,
                            divisions: 60,
                            onChanged: (val) {
                              HapticService.selectionClick();
                              setState(() {
                                _postStretchDuration = val;
                                _postStretch = val > 0;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Text('Post-Nut Nap / Sleep: ${_postNapDuration.round()} mins', style: theme.textTheme.titleMedium),
                          Slider(
                            value: _postNapDuration,
                            min: 0,
                            max: 120,
                            divisions: 120,
                            onChanged: (val) {
                              HapticService.selectionClick();
                              setState(() {
                                _postNapDuration = val;
                                _postNap = val > 0;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Text('Post-Nut Meditation: ${_postMeditationDuration.round()} mins', style: theme.textTheme.titleMedium),
                          Slider(
                            value: _postMeditationDuration,
                            min: 0,
                            max: 60,
                            divisions: 60,
                            onChanged: (val) {
                              HapticService.selectionClick();
                              setState(() {
                                _postMeditationDuration = val;
                                _postMeditation = val > 0;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saveLog,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(widget.existingLog != null ? 'Update Log Entry' : 'Save Log Entry', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FloatingTopBar(
              title: widget.existingLog != null ? 'Edit Log Entry' : 'Log New Session',
              isVisible: widget.isNavVisible,
              actions: [
                IconButton(
                  icon: Icon(Icons.check, color: AppTheme.secondaryCyan, size: 28),
                  onPressed: _saveLog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        HapticService.selectionClick();
        onToggle();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppTheme.secondaryCyan,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
