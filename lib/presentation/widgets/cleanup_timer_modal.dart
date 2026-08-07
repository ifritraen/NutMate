import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/timer_notification_service.dart';
import 'glass_card.dart';

class CleanupTimerModal extends StatefulWidget {
  final ValueChanged<int> onFinished;

  const CleanupTimerModal({super.key, required this.onFinished});

  @override
  State<CleanupTimerModal> createState() => _CleanupTimerModalState();
}

class _CleanupTimerModalState extends State<CleanupTimerModal> with WidgetsBindingObserver {
  late DateTime _timerStartTime;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timerStartTime = DateTime.now();
    TimerNotificationService.instance.enableWakelock();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds = DateTime.now().difference(_timerStartTime).inSeconds;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _seconds = DateTime.now().difference(_timerStartTime).inSeconds;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    TimerNotificationService.instance.disableWakelock();
    super.dispose();
  }

  String get _formattedTime {
    final mins = _seconds ~/ 60;
    final secs = _seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cleanup Timer Active',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Timer running in background with wake-lock active',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 48),
            child: Text(
              _formattedTime,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              _timer?.cancel();
              final mins = (_seconds / 60.0).toStringAsFixed(1);
              TimerNotificationService.instance.showNotification(
                id: 101,
                title: 'Cleanup Finished ⏱️',
                body: 'Recorded $mins mins of cleanup time in NutMate.',
              );
              widget.onFinished(_seconds);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Cleanup Finished', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
