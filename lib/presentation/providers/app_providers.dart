import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/db_helper.dart';
import '../../core/services/home_widget_service.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/log_entry.dart';
import '../../domain/models/stats_summary.dart';
import '../../domain/models/watch_entry.dart';

// --- LOGS NOTIFIER ---
class LogsNotifier extends Notifier<List<LogEntry>> {
  @override
  List<LogEntry> build() {
    loadLogs();
    return [];
  }

  Future<void> loadLogs() async {
    final logs = await DBHelper.instance.getAllLogs();
    state = logs;
  }

  Future<void> addLog(LogEntry log) async {
    await DBHelper.instance.insertLog(log);
    await loadLogs();
    await ref.read(settingsProvider.notifier).loadSettings();
  }

  Future<void> updateLog(LogEntry log) async {
    await DBHelper.instance.updateLog(log);
    await loadLogs();
    await ref.read(settingsProvider.notifier).loadSettings();
  }

  Future<void> deleteLog(int id) async {
    await DBHelper.instance.deleteLog(id);
    await loadLogs();
    await ref.read(settingsProvider.notifier).loadSettings();
  }

  Future<void> clearAll() async {
    await DBHelper.instance.clearAllLogs();
    state = [];
    await ref.read(settingsProvider.notifier).loadSettings();
  }
}

final logsProvider = NotifierProvider<LogsNotifier, List<LogEntry>>(LogsNotifier.new);

// --- WATCH LOGS NOTIFIER ---
class WatchLogsNotifier extends Notifier<List<WatchEntry>> {
  @override
  List<WatchEntry> build() {
    loadWatchLogs();
    return [];
  }

  Future<void> loadWatchLogs() async {
    final watchLogs = await DBHelper.instance.getAllWatchLogs();
    state = watchLogs;
  }

  Future<void> addWatchLog(WatchEntry watchLog) async {
    await DBHelper.instance.insertWatchLog(watchLog);
    await loadWatchLogs();
  }

  Future<void> updateWatchLog(WatchEntry watchLog) async {
    await DBHelper.instance.updateWatchLog(watchLog);
    await loadWatchLogs();
  }

  Future<void> deleteWatchLog(int id) async {
    await DBHelper.instance.deleteWatchLog(id);
    await loadWatchLogs();
  }

  Future<void> clearAll() async {
    await DBHelper.instance.clearAllWatchLogs();
    state = [];
  }
}

final watchLogsProvider = NotifierProvider<WatchLogsNotifier, List<WatchEntry>>(WatchLogsNotifier.new);

// --- SETTINGS NOTIFIER ---
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    loadSettings();
    return AppSettings();
  }

  Future<void> loadSettings() async {
    final baseSettings = await DBHelper.instance.loadAppSettings();
    final accentStr = await DBHelper.instance.getSetting('accentColor') ?? 'cyan';
    final stealthStr = await DBHelper.instance.getSetting('stealthMode') ?? 'false';
    final frozenStr = await DBHelper.instance.getSetting('streakFrozen') ?? 'false';
    final anonStr = await DBHelper.instance.getSetting('anonymizeExports') ?? 'false';
    final compactStr = await DBHelper.instance.getSetting('compactTimeline') ?? 'false';

    final accent = AppAccentColor.values.firstWhere(
      (e) => e.name == accentStr,
      orElse: () => AppAccentColor.cyan,
    );

    state = baseSettings.copyWith(
      accentColor: accent,
      stealthMode: stealthStr == 'true',
      streakFrozen: frozenStr == 'true',
      anonymizeExports: anonStr == 'true',
      compactTimeline: compactStr == 'true',
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await DBHelper.instance.saveSetting('themeMode', mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setAccentColor(AppAccentColor accent) async {
    await DBHelper.instance.saveSetting('accentColor', accent.name);
    state = state.copyWith(accentColor: accent);
  }

  Future<void> setStealthMode(bool enabled) async {
    await DBHelper.instance.saveSetting('stealthMode', enabled ? 'true' : 'false');
    state = state.copyWith(stealthMode: enabled);
  }

  Future<void> setStreakFrozen(bool frozen) async {
    await DBHelper.instance.saveSetting('streakFrozen', frozen ? 'true' : 'false');
    state = state.copyWith(streakFrozen: frozen);
  }

  Future<void> setAnonymizeExports(bool anon) async {
    await DBHelper.instance.saveSetting('anonymizeExports', anon ? 'true' : 'false');
    state = state.copyWith(anonymizeExports: anon);
  }

  Future<void> setCompactTimeline(bool compact) async {
    await DBHelper.instance.saveSetting('compactTimeline', compact ? 'true' : 'false');
    state = state.copyWith(compactTimeline: compact);
  }

  Future<void> setPin(String? pin) async {
    if (pin == null || pin.isEmpty) {
      await DBHelper.instance.saveSetting('pinEnabled', 'false');
      await DBHelper.instance.saveSetting('pinHash', '');
      state = state.copyWith(pinEnabled: false, pinHash: null);
    } else {
      await DBHelper.instance.saveSetting('pinEnabled', 'true');
      await DBHelper.instance.saveSetting('pinHash', pin);
      state = state.copyWith(pinEnabled: true, pinHash: pin);
    }
  }

  Future<void> setDecoyPin(String? pin) async {
    if (pin == null || pin.isEmpty) {
      await DBHelper.instance.saveSetting('decoyPinEnabled', 'false');
      await DBHelper.instance.saveSetting('decoyPinHash', '');
      state = state.copyWith(decoyPinEnabled: false, decoyPinHash: null);
    } else {
      await DBHelper.instance.saveSetting('decoyPinEnabled', 'true');
      await DBHelper.instance.saveSetting('decoyPinHash', pin);
      state = state.copyWith(decoyPinEnabled: true, decoyPinHash: pin);
    }
  }

  Future<void> setBiometric(bool enabled) async {
    await DBHelper.instance.saveSetting('biometricEnabled', enabled ? 'true' : 'false');
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<void> setWidgetUpdateIntervalMinutes(int minutes) async {
    await DBHelper.instance.saveSetting('widgetUpdateIntervalMinutes', minutes.toString());
    state = state.copyWith(widgetUpdateIntervalMinutes: minutes);
    await HomeWidgetService.setUpdateInterval(minutes);
  }

  Future<void> updateEdgeCount(int count) async {
    await DBHelper.instance.saveSetting('currentEdgeCount', count.toString());
    state = state.copyWith(currentEdgeCount: count);
  }

  Future<void> updateArousalCount(int count) async {
    await DBHelper.instance.saveSetting('currentArousalCount', count.toString());
    state = state.copyWith(currentArousalCount: count);
  }

  Future<void> updateUrgeCount(int count) async {
    await DBHelper.instance.saveSetting('currentUrgeCount', count.toString());
    state = state.copyWith(currentUrgeCount: count);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// --- STATS COMPUTED PROVIDER ---
final statsProvider = Provider<StatsSummary>((ref) {
  final logs = ref.watch(logsProvider);
  final settings = ref.watch(settingsProvider);

  final summary = StatsSummary.fromLogs(
    logs,
    lastOrgasmTime: settings.lastStreakResetTime,
    activeEdgeCount: settings.currentEdgeCount,
    activeArousalCount: settings.currentArousalCount,
  );

  HomeWidgetService.updateHomeWidget(
    summary,
    lastOrgasmTime: settings.lastStreakResetTime,
    isFrozen: settings.streakFrozen,
  );
  return summary;
});


// --- LOCK STATE NOTIFIER ---
class IsLockedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final settings = ref.watch(settingsProvider);
    return settings.pinEnabled;
  }

  void setLocked(bool val) => state = val;
}

final isLockedProvider = NotifierProvider<IsLockedNotifier, bool>(IsLockedNotifier.new);
