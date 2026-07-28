import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/biometric_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _enteredPin = '';
  late List<String> _keypadNumbers;

  @override
  void initState() {
    super.initState();
    _keypadNumbers = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    _keypadNumbers.shuffle();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final settings = ref.read(settingsProvider);
    if (settings.biometricEnabled) {
      final success = await BiometricService.authenticateBiometric();
      if (success) {
        ref.read(isLockedProvider.notifier).setLocked(false);
      }
    }
  }

  void _onKeyPress(String val) {
    HapticService.selectionClick();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    HapticService.selectionClick();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    final settings = ref.read(settingsProvider);

    final isCustomDecoy = settings.decoyPinEnabled && settings.decoyPinHash != null && BiometricService.verifyPin(_enteredPin, settings.decoyPinHash!);
    final isDefaultDecoy = !settings.decoyPinEnabled && _enteredPin == '0000';

    if (isCustomDecoy || isDefaultDecoy) {
      HapticService.heavyImpact();
      ref.read(isLockedProvider.notifier).setLocked(false);
      return;
    }

    if (settings.pinHash != null && BiometricService.verifyPin(_enteredPin, settings.pinHash!)) {
      HapticService.mediumImpact();
      ref.read(isLockedProvider.notifier).setLocked(false);
    } else {
      HapticService.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN'), backgroundColor: Colors.redAccent),
      );
      setState(() {
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.lock_outline, size: 64, color: AppTheme.secondaryCyan),
            const SizedBox(height: 16),
            Text('Nutmate Locked', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Scrambled Stealth Keypad Enabled', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppTheme.secondaryCyan : Colors.white24,
                  ),
                );
              }),
            ),
            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_keypadNumbers[0], _keypadNumbers[1], _keypadNumbers[2]].map(_buildKey).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_keypadNumbers[3], _keypadNumbers[4], _keypadNumbers[5]].map(_buildKey).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_keypadNumbers[6], _keypadNumbers[7], _keypadNumbers[8]].map(_buildKey).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (settings.biometricEnabled)
                        IconButton(
                          icon: Icon(Icons.fingerprint, size: 36, color: AppTheme.secondaryCyan),
                          onPressed: _checkBiometrics,
                        )
                      else
                        const SizedBox(width: 64),
                      _buildKey(_keypadNumbers[9]),
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, size: 28, color: Colors.white70),
                        onPressed: _onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String val) {
    return SizedBox(
      width: 64,
      height: 64,
      child: GlassCard(
        padding: EdgeInsets.zero,
        onTap: () => _onKeyPress(val),
        child: Center(
          child: Text(
            val,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
