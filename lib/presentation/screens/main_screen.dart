import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import 'add_log_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'timeline_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  bool _isNavVisible = true;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final accentColor = AppTheme.getAccentColor(settings.accentColor);

    final screens = [
      DashboardScreen(
        onAddLogTap: () => setState(() => _currentIndex = 1),
        isNavVisible: _isNavVisible,
      ),
      AddLogScreen(
        isNavVisible: _isNavVisible,
        onSaved: () => setState(() => _currentIndex = 0),
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
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            borderRadius: BorderRadius.circular(30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, settings.stealthMode ? 'Home' : 'Dashboard', accentColor),
                _buildNavItem(1, Icons.add_circle_outline, Icons.add_circle, 'Add Log', accentColor),
                _buildNavItem(2, Icons.history_outlined, Icons.history, settings.stealthMode ? 'Notes' : 'Timeline', accentColor),
                _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart, 'Stats', accentColor),
                _buildNavItem(4, Icons.settings_outlined, Icons.settings, 'Settings', accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, Color accentColor) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? accentColor : Colors.white54,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accentColor : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
