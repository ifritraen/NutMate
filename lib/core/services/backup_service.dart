import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/exercise_entry.dart';
import '../../domain/models/log_entry.dart';
import '../../domain/models/watch_entry.dart';
import '../database/db_helper.dart';
import '../../presentation/providers/app_providers.dart';

class ParsedBackup {
  final List<LogEntry> logs;
  final List<WatchEntry> watchLogs;
  final List<ExerciseEntry> exerciseLogs;

  ParsedBackup({
    required this.logs,
    this.watchLogs = const [],
    this.exerciseLogs = const [],
  });
}

class BackupResult {
  final bool success;
  final String path;
  final int logCount;
  final int watchCount;
  final int exerciseCount;
  final String? error;

  BackupResult({
    required this.success,
    required this.path,
    this.logCount = 0,
    this.watchCount = 0,
    this.exerciseCount = 0,
    this.error,
  });
}

class BackupService {
  static const _storageChannel = MethodChannel('com.raen.nutmate/storage');

  /// Check if the app has All Files Access (MANAGE_EXTERNAL_STORAGE on Android 11+)
  static Future<bool> hasAllFilesAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? granted = await _storageChannel.invokeMethod<bool>('hasAllFilesAccess');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open system Settings to grant All Files Access
  static Future<void> requestAllFilesAccess() async {
    if (!Platform.isAndroid) return;
    try {
      await _storageChannel.invokeMethod('requestAllFilesAccess');
    } catch (_) {}
  }

  /// Native database file restore from external storage
  static Future<bool> restoreDatabaseFromExternal([String? sourcePath]) async {
    try {
      final bool? success = await _storageChannel.invokeMethod<bool>('restoreDatabaseFromExternal', {
        if (sourcePath != null) 'sourcePath': sourcePath,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Primary backup directory on external storage
  static Future<Directory> getBackupDirectory() async {
    const publicPath = '/storage/emulated/0/NutMate/Backups';
    final publicDir = Directory(publicPath);

    try {
      if (!await publicDir.exists()) {
        await publicDir.create(recursive: true);
      }
      return publicDir;
    } catch (_) {
      // Fallback if public storage not directly writable yet
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final fallback = Directory('${ext.path}/Backups');
        if (!await fallback.exists()) await fallback.create(recursive: true);
        return fallback;
      }
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Export logs, watchLogs, and exerciseLogs to JSON string
  static String exportToJson(
    List<LogEntry> logs, {
    List<WatchEntry> watchLogs = const [],
    List<ExerciseEntry> exerciseLogs = const [],
  }) {
    final list = logs.map((e) => e.toJson()).toList();
    final watchList = watchLogs.map((e) => e.toJson()).toList();
    final exerciseList = exerciseLogs.map((e) => e.toMap()).toList();
    final data = {
      'app': 'Nutmate',
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'logs': list,
      'watchLogs': watchList,
      'exerciseLogs': exerciseList,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import logs from JSON string
  static ParsedBackup importFromJson(String jsonStr) {
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    if (!decoded.containsKey('logs')) {
      throw const FormatException('Invalid Nutmate backup JSON format.');
    }
    final List<dynamic> logsList = decoded['logs'] as List<dynamic>? ?? [];
    final List<dynamic> watchList = decoded['watchLogs'] as List<dynamic>? ?? [];
    final List<dynamic> exerciseList = decoded['exerciseLogs'] as List<dynamic>? ?? [];

    return ParsedBackup(
      logs: logsList.map((e) => LogEntry.fromJson(Map<String, dynamic>.from(e))).toList(),
      watchLogs: watchList.map((e) => WatchEntry.fromMap(Map<String, dynamic>.from(e))).toList(),
      exerciseLogs: exerciseList.map((e) => ExerciseEntry.fromMap(Map<String, dynamic>.from(e))).toList(),
    );
  }

  /// Perform a complete, persistent backup (both JSON & SQLite .db) to public storage
  static Future<BackupResult> performFullBackup({
    List<LogEntry>? logs,
    List<WatchEntry>? watchLogs,
    List<ExerciseEntry>? exerciseLogs,
  }) async {
    try {
      final allLogs = logs ?? await DBHelper.instance.getAllLogs();
      final allWatchLogs = watchLogs ?? await DBHelper.instance.getAllWatchLogs();
      final allExerciseLogs = exerciseLogs ?? await DBHelper.instance.getAllExerciseLogs();

      final backupDir = await getBackupDirectory();
      final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      // 1. JSON Exports
      final jsonContent = exportToJson(allLogs, watchLogs: allWatchLogs, exerciseLogs: allExerciseLogs);
      final latestJsonFile = File('${backupDir.path}/nutmate_backup_latest.json');
      final timestampJsonFile = File('${backupDir.path}/nutmate_backup_$timeStamp.json');

      await latestJsonFile.writeAsString(jsonContent);
      await timestampJsonFile.writeAsString(jsonContent);

      // 2. Native SQLite DB file copy
      try {
        await _storageChannel.invokeMethod('copyDatabaseToExternal');
      } catch (_) {}

      // 3. Clean up older backups (keep latest 10 timestamped files)
      await _cleanOldBackups(backupDir);

      return BackupResult(
        success: true,
        path: backupDir.path,
        logCount: allLogs.length,
        watchCount: allWatchLogs.length,
        exerciseCount: allExerciseLogs.length,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        path: '',
        error: e.toString(),
      );
    }
  }

  /// Automatically check if an auto-backup is due and execute it
  static Future<void> checkAndPerformAutoBackup(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.autoBackupIntervalHours <= 0) return;

    final lastBackup = settings.lastAutoBackupTime;
    final now = DateTime.now();

    if (lastBackup == null || now.difference(lastBackup).inHours >= settings.autoBackupIntervalHours) {
      final result = await performFullBackup();
      if (result.success) {
        await ref.read(settingsProvider.notifier).setLastAutoBackupTime(now);
      }
    }
  }

  /// Clean up older timestamped backups, keeping the newest 10
  static Future<void> _cleanOldBackups(Directory dir) async {
    try {
      final files = await dir.list().toList();
      final jsonBackups = files
          .whereType<File>()
          .where((f) => f.path.contains('nutmate_backup_20') && f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (jsonBackups.length > 10) {
        for (var i = 10; i < jsonBackups.length; i++) {
          try {
            await jsonBackups[i].delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
