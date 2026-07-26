enum AppThemeMode { dark, amoled }

enum AppAccentColor { cyan, violet, gold, emerald }

class AppSettings {
  final AppThemeMode themeMode;
  final AppAccentColor accentColor;
  final bool pinEnabled;
  final String? pinHash;
  final bool biometricEnabled;
  final DateTime? lastStreakResetTime;
  final int currentEdgeCount;
  final int currentArousalCount;
  final bool stealthMode;
  final bool streakFrozen;
  final bool anonymizeExports;
  final bool compactTimeline;

  AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.accentColor = AppAccentColor.cyan,
    this.pinEnabled = false,
    this.pinHash,
    this.biometricEnabled = false,
    this.lastStreakResetTime,
    this.currentEdgeCount = 0,
    this.currentArousalCount = 0,
    this.stealthMode = false,
    this.streakFrozen = false,
    this.anonymizeExports = false,
    this.compactTimeline = false,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppAccentColor? accentColor,
    bool? pinEnabled,
    String? pinHash,
    bool? biometricEnabled,
    DateTime? lastStreakResetTime,
    int? currentEdgeCount,
    int? currentArousalCount,
    bool? stealthMode,
    bool? streakFrozen,
    bool? anonymizeExports,
    bool? compactTimeline,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinHash: pinHash ?? this.pinHash,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lastStreakResetTime: lastStreakResetTime ?? this.lastStreakResetTime,
      currentEdgeCount: currentEdgeCount ?? this.currentEdgeCount,
      currentArousalCount: currentArousalCount ?? this.currentArousalCount,
      stealthMode: stealthMode ?? this.stealthMode,
      streakFrozen: streakFrozen ?? this.streakFrozen,
      anonymizeExports: anonymizeExports ?? this.anonymizeExports,
      compactTimeline: compactTimeline ?? this.compactTimeline,
    );
  }
}
