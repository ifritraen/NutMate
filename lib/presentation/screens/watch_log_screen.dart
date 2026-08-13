import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/haptic_service.dart';
import '../../core/services/timer_notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/watch_entry.dart';
import '../providers/app_providers.dart';
import '../widgets/chip_selector.dart';
import '../widgets/glass_card.dart';

class WatchLogScreen extends ConsumerStatefulWidget {
  final bool isNavVisible;
  final Function(double durationMinutes, List<String> contentTypes)? onBridgeToMasturbation;
  final WatchEntry? existingEntry;

  const WatchLogScreen({
    super.key,
    this.isNavVisible = true,
    this.onBridgeToMasturbation,
    this.existingEntry,
  });

  @override
  ConsumerState<WatchLogScreen> createState() => _WatchLogScreenState();
}

class _WatchLogScreenState extends ConsumerState<WatchLogScreen> with WidgetsBindingObserver {
  // Session Timing
  DateTime _sessionDateTime = DateTime.now();
  double _durationMinutes = 15.0;
  bool _isTimerRunning = false;
  int _timerSeconds = 0;
  DateTime? _timerStartTime;
  Timer? _stopwatchTimer;

  // Content Details
  List<String> _contentTypes = ['🎬 Adult Video / Porn'];
  String _platform = '🌐 Browser / Web';

  // State Before Watching
  double _urgeBefore = 5.0;
  String _trigger = '🥱 Boredom / Free Time';
  String _location = 'Bedroom';
  String _intent = '⚡ Accidental / Peek';

  // Outcome
  String _outcome = '✅ Closed Cleanly / Resisted Urge';

  // Post-Watch Reflection
  String _feelingAfter = 'Neutral';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];

  bool _isRecentHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TimerNotificationService.instance.enableWakelock();
    _initFromExisting();
  }

  void _initFromExisting() {
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _sessionDateTime = entry.createdAt;
      _durationMinutes = entry.durationMinutes;
      _contentTypes = List<String>.from(entry.contentTypes);
      _platform = entry.platform.isEmpty ? '🌐 Browser / Web' : entry.platform;
      _urgeBefore = entry.urgeBefore.toDouble();
      _trigger = entry.trigger.isEmpty ? '🥱 Boredom / Free Time' : entry.trigger;
      _location = entry.location.isEmpty ? 'Bedroom' : entry.location;
      _intent = entry.intent.isEmpty ? '⚡ Accidental / Peek' : entry.intent;
      _outcome = entry.outcome.isEmpty ? '✅ Closed Cleanly / Resisted Urge' : entry.outcome;
      _feelingAfter = entry.feelingAfter.isEmpty ? 'Neutral' : entry.feelingAfter;
      _notesController.text = entry.notes;
      _tags = List<String>.from(entry.tags);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isTimerRunning && _timerStartTime != null && mounted) {
      setState(() {
        _timerSeconds = DateTime.now().difference(_timerStartTime!).inSeconds;
        _durationMinutes = (_timerSeconds / 60.0).clamp(1.0, 240.0);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatchTimer?.cancel();
    TimerNotificationService.instance.disableWakelock();
    _notesController.dispose();
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
      final mins = (_timerSeconds / 60.0).toStringAsFixed(1);
      TimerNotificationService.instance.showNotification(
        id: 105,
        title: 'Watch Session Timer Paused ⏱️',
        body: 'Duration so far: $mins mins.',
      );
    } else {
      _timerStartTime = DateTime.now().subtract(Duration(seconds: _timerSeconds));
      setState(() {
        _isTimerRunning = true;
      });
      TimerNotificationService.instance.showNotification(
        id: 105,
        title: 'Watch Session Active 🎬',
        body: 'Watch timer running with screen wake-lock.',
      );
      _stopwatchTimer?.cancel();
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isTimerRunning && _timerStartTime != null) {
          setState(() {
            _timerSeconds = DateTime.now().difference(_timerStartTime!).inSeconds;
            _durationMinutes = (_timerSeconds / 60.0).clamp(1.0, 240.0);
          });
        }
      });
    }
  }

  void _resetTimer() {
    HapticService.lightImpact();
    _stopwatchTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerSeconds = 0;
      _timerStartTime = null;
      _durationMinutes = 15.0;
    });
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

  Future<void> _saveWatchLog() async {
    try {
      HapticService.heavyImpact();
      final now = DateTime.now();
      final startTime = _sessionDateTime.subtract(Duration(minutes: _durationMinutes.round()));

      final entry = WatchEntry(
        id: widget.existingEntry?.id,
        createdAt: _sessionDateTime,
        updatedAt: now,
        startTime: startTime,
        endTime: _sessionDateTime,
        durationMinutes: _durationMinutes,
        contentTypes: _contentTypes,
        platform: _platform,
        urgeBefore: _urgeBefore.round(),
        trigger: _trigger,
        location: _location,
        intent: _intent,
        outcome: _outcome,
        feelingAfter: _feelingAfter,
        notes: _notesController.text.trim(),
        tags: _tags,
      );

      if (widget.existingEntry != null) {
        await ref.read(watchLogsProvider.notifier).updateWatchLog(entry);
      } else {
        await ref.read(watchLogsProvider.notifier).addWatchLog(entry);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎬 Watch log saved successfully!'),
            backgroundColor: AppTheme.secondaryCyan,
          ),
        );
        _resetTimer();
        setState(() {
          _notesController.clear();
          _tags = [];
          _outcome = '✅ Closed Cleanly / Resisted Urge';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save watch log: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _bridgeToMasturbation() {
    HapticService.heavyImpact();
    widget.onBridgeToMasturbation?.call(_durationMinutes, _contentTypes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final watchLogs = ref.watch(watchLogsProvider);

    final timerDisplay = '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}';
    final isLedToMast = _outcome.contains('Masturbation') || _outcome.contains('Orgasm');

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.stealthMode ? 'Media Watch Log' : '🎬 Porn / Media Watch Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Timer & Form',
            onPressed: _resetTimer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, widget.isNavVisible ? 100 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. LIVE WATCH TIMER & STOPWATCH
            // ==========================================
            GlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isTimerRunning ? Icons.timer : Icons.timer_outlined,
                            color: _isTimerRunning ? Colors.greenAccent : AppTheme.secondaryCyan,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isTimerRunning ? 'Live Watch Timer (Active)' : 'Live Watch Timer',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _isTimerRunning ? Colors.greenAccent : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_timerSeconds > 0)
                        IconButton(
                          icon: const Icon(Icons.stop_circle_outlined, color: Colors.white60, size: 20),
                          tooltip: 'Reset',
                          onPressed: _resetTimer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timerDisplay,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: _isTimerRunning ? AppTheme.secondaryCyan : Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTimerRunning ? Colors.amber.shade700 : AppTheme.secondaryCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _toggleLiveTimer,
                          icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                          label: Text(
                            _isTimerRunning ? 'Pause Stopwatch' : (_timerSeconds > 0 ? 'Resume Stopwatch' : 'Start Watch Stopwatch'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration: ${_durationMinutes.toStringAsFixed(0)} mins', style: theme.textTheme.titleMedium),
                      Text('${(_durationMinutes / 60).toStringAsFixed(1)} hrs', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  Slider(
                    value: _durationMinutes.clamp(1.0, 240.0),
                    min: 1.0,
                    max: 240.0,
                    divisions: 48,
                    onChanged: (val) {
                      HapticService.selectionClick();
                      setState(() => _durationMinutes = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // 2. CONTENT TYPE & PLATFORM
            // ==========================================
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChipSelector(
                    title: '🎬 Content / Media Types',
                    isMultiSelect: true,
                    options: const [
                      '🎬 Adult Video / Porn',
                      '🎬 Hentai / Animated Video',
                      '🎨 Hentai / Manga / Comic / Doujin',
                      '🖼️ Erotic Images / Photos / Cosplay',
                      '📱 Social Media Feeds (Reddit / X / Reels)',
                      '📚 Erotic Stories / Novels',
                      '🎧 Audio / Erotic ASMR',
                      '💬 NSFW Chat / AI Roleplay',
                      '💭 Pure Fantasy',
                    ],
                    selectedMulti: _contentTypes,
                    onMultiSelected: (list) => setState(() => _contentTypes = list),
                  ),
                  const SizedBox(height: 16),
                  ChipSelector(
                    title: '🌐 Platform / Source',
                    options: const [
                      '🌐 Browser / Web',
                      '📱 Reddit / X (Twitter)',
                      '📖 Manga / Comic App',
                      '📁 Local Storage / Gallery',
                      '💬 Discord / Telegram',
                      '🤖 AI App',
                      '📱 Instagram / TikTok',
                    ],
                    selectedSingle: _platform,
                    onSingleSelected: (val) => setState(() => _platform = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // 3. PRE-WATCH STATE & TRIGGERS
            // ==========================================
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔥 Urge Level Before: ${_urgeBefore.round()}/10', style: theme.textTheme.titleMedium),
                  Slider(
                    value: _urgeBefore,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (val) {
                      HapticService.selectionClick();
                      setState(() => _urgeBefore = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  ChipSelector(
                    title: '⚡ Initial Trigger',
                    options: const [
                      '🥱 Boredom / Free Time',
                      '🧠 Stress & Anxiety',
                      '🛌 Bedtime / Waking Up',
                      '⚡ Random Curiosity / Peeking',
                      '🔥 Physical Arousal',
                      '💔 Loneliness / Emotional',
                      '📱 Accidental NSFW Feed Encounter',
                    ],
                    selectedSingle: _trigger,
                    onSingleSelected: (val) => setState(() => _trigger = val),
                  ),
                  const SizedBox(height: 16),
                  ChipSelector(
                    title: '📍 Location',
                    options: const [
                      'Bedroom',
                      'Bathroom',
                      'Living Room',
                      'Desk / PC',
                      'Outside / Commute',
                    ],
                    selectedSingle: _location,
                    onSingleSelected: (val) => setState(() => _location = val),
                  ),
                  const SizedBox(height: 16),
                  ChipSelector(
                    title: '🎯 Intent',
                    options: const [
                      '⚡ Accidental / Peek',
                      '🎯 Intentional Binge',
                      '🔄 Habitual Routine',
                    ],
                    selectedSingle: _intent,
                    onSingleSelected: (val) => setState(() => _intent = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // 4. OUTCOME & BRIDGE CARD
            // ==========================================
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChipSelector(
                    title: '🏁 Watch Session Outcome',
                    options: const [
                      '✅ Closed Cleanly / Resisted Urge',
                      '⚡ Led to Edging',
                      '💦 Led to Masturbation / Orgasm',
                    ],
                    selectedSingle: _outcome,
                    onSingleSelected: (val) => setState(() => _outcome = val),
                  ),
                  if (isLedToMast) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryViolet.withOpacity(0.35),
                            Colors.pinkAccent.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.flash_on, color: Colors.pinkAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Bridge to Masturbation Session',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pre-fills ${_durationMinutes.toStringAsFixed(0)} mins and your selected content types into the Pre-Nut section of Add Log.',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                _saveWatchLog();
                                _bridgeToMasturbation();
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Save & Open Masturbation Log', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // 5. POST-WATCH REFLECTION & NOTES
            // ==========================================
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChipSelector(
                    title: '💭 Post-Watch Feeling',
                    options: const [
                      'Relieved',
                      'Guilty / Regretful',
                      'Drained',
                      'Numb',
                      'Neutral',
                      'Turned On',
                    ],
                    selectedSingle: _feelingAfter,
                    onSingleSelected: (val) => setState(() => _feelingAfter = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Personal Notes / Reflection',
                      hintText: 'What triggered this watch session? How did you react?',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            hintText: 'Add tag (e.g. #night_peek)',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onSubmitted: _addTag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppTheme.secondaryCyan),
                        onPressed: () => _addTag(_tagController.text),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: _tags.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        onDeleted: () => setState(() => _tags.remove(t)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveWatchLog,
                icon: const Icon(Icons.save),
                label: const Text('Save Watch Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 6. RECENT WATCH HISTORY (COLLAPSIBLE)
            // ==========================================
            InkWell(
              onTap: () => setState(() => _isRecentHistoryExpanded = !_isRecentHistoryExpanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Watch History (${watchLogs.length})', style: theme.textTheme.titleMedium),
                  Icon(_isRecentHistoryExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white70),
                ],
              ),
            ),
            if (_isRecentHistoryExpanded) ...[
              const SizedBox(height: 8),
              if (watchLogs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No watch logs recorded yet.', style: TextStyle(color: Colors.white54)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: watchLogs.length.clamp(0, 10),
                  itemBuilder: (ctx, idx) {
                    final item = watchLogs[idx];
                    final dateStr = DateFormat('MMM dd, hh:mm a').format(item.createdAt);
                    return Card(
                      color: const Color(0xFF1E1E2C),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Icon(Icons.movie_filter_outlined, color: AppTheme.secondaryCyan, size: 20),
                        ),
                        title: Text('${item.durationMinutes.toStringAsFixed(0)} mins — ${item.platform}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('$dateStr\n${item.contentTypes.join(", ")} | ${item.outcome}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          onPressed: () => ref.read(watchLogsProvider.notifier).deleteWatchLog(item.id!),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
