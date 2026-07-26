import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/pin_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: NutmateApp(),
    ),
  );
}

class NutmateApp extends ConsumerWidget {
  const NutmateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isLocked = ref.watch(isLockedProvider);

    return MaterialApp(
      title: settings.stealthMode ? 'Daily Notes' : 'Nutmate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getDarkTheme(settings),
      darkTheme: AppTheme.getDarkTheme(settings),
      themeMode: ThemeMode.dark,
      home: isLocked ? const PinLockScreen() : const MainScreen(),
    );
  }
}
