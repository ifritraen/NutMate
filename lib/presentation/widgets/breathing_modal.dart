import 'dart:async';
import 'package:flutter/material.dart';

class BreathingModal extends StatefulWidget {
  const BreathingModal({super.key});

  @override
  State<BreathingModal> createState() => _BreathingModalState();
}

class _BreathingModalState extends State<BreathingModal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  Timer? _phaseTimer;
  String _phaseText = 'Inhale...';
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _sizeAnimation = Tween<double>(begin: 100.0, end: 200.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        setState(() => _phaseText = 'Inhale deeply...');
      } else if (status == AnimationStatus.reverse) {
        setState(() => _phaseText = 'Exhale slowly...');
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('1-Minute Box Breathing Recovery', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Focus on your breath to ground your nervous system', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _sizeAnimation,
            builder: (context, child) {
              return Container(
                width: _sizeAnimation.value,
                height: _sizeAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  border: Border.all(color: theme.colorScheme.secondary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${_secondsRemaining}s',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Text(_phaseText, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
            onPressed: () => Navigator.pop(context),
            child: const Text('Finish Recovery Session'),
          ),
        ],
      ),
    );
  }
}
