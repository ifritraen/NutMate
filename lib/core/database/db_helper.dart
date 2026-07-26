import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/log_entry.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nutmate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        type TEXT NOT NULL,
        preWater TEXT DEFAULT 'None',
        preWorkout TEXT DEFAULT 'None',
        preMeditation INTEGER NOT NULL DEFAULT 0,
        preMeditationDuration INTEGER NOT NULL DEFAULT 0,
        preSleepQuality INTEGER NOT NULL DEFAULT 5,
        preSleepHours REAL NOT NULL DEFAULT 7.0,
        preNapDuration INTEGER NOT NULL DEFAULT 0,
        preMeal TEXT DEFAULT 'None',
        preCoffee INTEGER NOT NULL DEFAULT 0,
        preAlcohol INTEGER NOT NULL DEFAULT 0,
        urge INTEGER NOT NULL DEFAULT 5,
        mood TEXT DEFAULT '',
        trigger TEXT DEFAULT '',
        isPlanned INTEGER NOT NULL DEFAULT 0,
        location TEXT DEFAULT 'Home',
        tags TEXT DEFAULT '[]',
        beforeNotes TEXT DEFAULT '',
        timeSinceLastOrgasmText TEXT DEFAULT '',
        lastEdgingCount INTEGER NOT NULL DEFAULT 0,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        durationMinutes REAL NOT NULL DEFAULT 15.0,
        method TEXT DEFAULT '',
        contentUsed TEXT DEFAULT '[]',
        position TEXT DEFAULT 'Lying',
        duringNotes TEXT DEFAULT '',
        satisfaction INTEGER NOT NULL DEFAULT 5,
        orgasmQuality INTEGER NOT NULL DEFAULT 5,
        regret INTEGER NOT NULL DEFAULT 1,
        cleanupDurationSeconds INTEGER NOT NULL DEFAULT 0,
        afterNotes TEXT DEFAULT '',
        postWater TEXT DEFAULT 'None',
        postStretch INTEGER NOT NULL DEFAULT 0,
        postStretchDuration INTEGER NOT NULL DEFAULT 0,
        postMeal TEXT DEFAULT 'None',
        postNap INTEGER NOT NULL DEFAULT 0,
        postNapDuration INTEGER NOT NULL DEFAULT 0,
        postMeditation INTEGER NOT NULL DEFAULT 0,
        postMeditationDuration INTEGER NOT NULL DEFAULT 0,
        edgingCountBeforeOrgasm INTEGER NOT NULL DEFAULT 0,
        nearOrgasmCount INTEGER NOT NULL DEFAULT 0,
        didOrgasmOccur INTEGER NOT NULL DEFAULT 0,
        endingReason TEXT DEFAULT '',
        waterBeforeMl INTEGER NOT NULL DEFAULT 0,
        waterAfterMl INTEGER NOT NULL DEFAULT 0,
        sleepQuality INTEGER NOT NULL DEFAULT 5,
        sleepDurationHours REAL NOT NULL DEFAULT 7.0,
        reason TEXT DEFAULT '',
        exerciseDone TEXT DEFAULT 'None',
        exerciseMinutes INTEGER NOT NULL DEFAULT 0,
        meditationDone INTEGER NOT NULL DEFAULT 0,
        meditationMinutes INTEGER NOT NULL DEFAULT 0,
        mealEaten TEXT DEFAULT 'None',
        napTaken INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final allPossibleColumns = [
      'ALTER TABLE logs ADD COLUMN preWater TEXT DEFAULT \'None\'',
      'ALTER TABLE logs ADD COLUMN preWorkout TEXT DEFAULT \'None\'',
      'ALTER TABLE logs ADD COLUMN preMeditation INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN preMeditationDuration INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN preSleepQuality INTEGER NOT NULL DEFAULT 5',
      'ALTER TABLE logs ADD COLUMN preSleepHours REAL NOT NULL DEFAULT 7.0',
      'ALTER TABLE logs ADD COLUMN preNapDuration INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN preMeal TEXT DEFAULT \'None\'',
      'ALTER TABLE logs ADD COLUMN preCoffee INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN preAlcohol INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN urge INTEGER NOT NULL DEFAULT 5',
      'ALTER TABLE logs ADD COLUMN mood TEXT DEFAULT \'\'',
      'ALTER TABLE logs ADD COLUMN trigger TEXT DEFAULT \'\'',
      'ALTER TABLE logs ADD COLUMN isPlanned INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN location TEXT DEFAULT \'Home\'',
      'ALTER TABLE logs ADD COLUMN tags TEXT DEFAULT \'[]\'',
      'ALTER TABLE logs ADD COLUMN beforeNotes TEXT DEFAULT \'\'',
      'ALTER TABLE logs ADD COLUMN timeSinceLastOrgasmText TEXT DEFAULT \'\'',
      'ALTER TABLE logs ADD COLUMN lastEdgingCount INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN durationMinutes REAL NOT NULL DEFAULT 15.0',
      'ALTER TABLE logs ADD COLUMN method TEXT DEFAULT \'\'',
      'ALTER TABLE logs ADD COLUMN contentUsed TEXT DEFAULT \'[]\'',
      'ALTER TABLE logs ADD COLUMN position TEXT DEFAULT \'Lying\'',
      'ALTER TABLE logs ADD COLUMN duringNotes TEXT DEFAULT \'\'',
      'ALTER TABLE logs ADD COLUMN satisfaction INTEGER NOT NULL DEFAULT 5',
      'ALTER TABLE logs ADD COLUMN orgasmQuality INTEGER NOT NULL DEFAULT 5',
      'ALTER TABLE logs ADD COLUMN regret INTEGER NOT NULL DEFAULT 1',
      'ALTER TABLE logs ADD COLUMN cleanupDurationSeconds INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN afterNotes TEXT DEFAULT \'\'',
      'ALTER TABLE logs ADD COLUMN postWater TEXT DEFAULT \'None\'',
      'ALTER TABLE logs ADD COLUMN postStretch INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN postStretchDuration INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN postMeal TEXT DEFAULT \'None\'',
      'ALTER TABLE logs ADD COLUMN postNap INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN postNapDuration INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN postMeditation INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN postMeditationDuration INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN edgingCountBeforeOrgasm INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN nearOrgasmCount INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN didOrgasmOccur INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN endingReason TEXT DEFAULT \'\'',
      'ALTER TABLE logs ADD COLUMN waterBeforeMl INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN waterAfterMl INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN sleepQuality INTEGER NOT NULL DEFAULT 5',
      'ALTER TABLE logs ADD COLUMN sleepDurationHours REAL NOT NULL DEFAULT 7.0',
      'ALTER TABLE logs ADD COLUMN reason TEXT DEFAULT \'\'',
      'ALTER TABLE logs ADD COLUMN exerciseDone TEXT DEFAULT \'None\'',
      'ALTER TABLE logs ADD COLUMN exerciseMinutes INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN meditationDone INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN meditationMinutes INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN mealEaten TEXT DEFAULT \'None\'',
      'ALTER TABLE logs ADD COLUMN napTaken INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE logs ADD COLUMN stimulus TEXT DEFAULT \'💭 Pure Imagination / Fantasy\'',
    ];

    for (var col in allPossibleColumns) {
      try {
        await db.execute(col);
      } catch (_) {}
    }
  }

  /// Inspects the disk table PRAGMA to dynamically populate missing NOT NULL columns.
  Future<Map<String, dynamic>> _sanitizeMapForLogs(Database db, Map<String, dynamic> inputMap) async {
    final map = Map<String, dynamic>.from(inputMap);
    if (map['id'] == null) {
      map.remove('id');
    }
    final columns = await db.rawQuery('PRAGMA table_info(logs)');

    for (var col in columns) {
      final String name = col['name'] as String;
      final bool isNotNull = (col['notnull'] as int?) == 1;
      final dynamic dfltVal = col['dflt_value'];

      if (!map.containsKey(name) || map[name] == null) {
        if (name == 'id') continue;

        final String type = (col['type'] as String? ?? '').toUpperCase();
        if (isNotNull || dfltVal != null) {
          if (type.contains('INT')) {
            map[name] = dfltVal != null ? int.tryParse(dfltVal.toString()) ?? 0 : 0;
          } else if (type.contains('REAL') || type.contains('NUM') || type.contains('DOUBLE') || type.contains('FLOAT')) {
            map[name] = dfltVal != null ? double.tryParse(dfltVal.toString()) ?? 0.0 : 0.0;
          } else {
            map[name] = dfltVal != null ? dfltVal.toString().replaceAll("'", "") : '';
          }
        }
      }
    }
    map.removeWhere((key, value) => value == null && key != 'id');
    return map;
  }

  // --- LOG CRUD ---

  Future<int> insertLog(LogEntry log) async {
    final db = await instance.database;
    final map = await _sanitizeMapForLogs(db, log.toMap());

    final id = await db.insert('logs', map, conflictAlgorithm: ConflictAlgorithm.replace);

    if (log.type == SessionType.masturbation) {
      await saveSetting('lastStreakResetTime', log.createdAt.toIso8601String());
      await saveSetting('currentEdgeCount', '0');
      await saveSetting('currentArousalCount', '0');
    } else if (log.type == SessionType.edging) {
      final currentEdge = await getSettingInt('currentEdgeCount') ?? 0;
      await saveSetting('currentEdgeCount', (currentEdge + 1).toString());
    } else if (log.type == SessionType.arousal) {
      final currentArousal = await getSettingInt('currentArousalCount') ?? 0;
      await saveSetting('currentArousalCount', (currentArousal + 1).toString());
    }

    return id;
  }

  Future<List<LogEntry>> getAllLogs() async {
    final db = await instance.database;
    final maps = await db.query('logs', orderBy: 'createdAt DESC');
    return maps.map((e) => LogEntry.fromMap(e)).toList();
  }

  Future<int> updateLog(LogEntry log) async {
    final db = await instance.database;
    final map = await _sanitizeMapForLogs(db, log.toMap());

    return await db.update('logs', map, where: 'id = ?', whereArgs: [log.id]);
  }

  Future<int> deleteLog(int id) async {
    final db = await instance.database;
    return await db.delete('logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllLogs() async {
    final db = await instance.database;
    await db.delete('logs');
    await saveSetting('lastStreakResetTime', '');
    await saveSetting('currentEdgeCount', '0');
    await saveSetting('currentArousalCount', '0');
  }

  // --- SETTINGS CRUD ---

  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) return maps.first['value'] as String?;
    return null;
  }

  Future<int?> getSettingInt(String key) async {
    final val = await getSetting(key);
    if (val != null) return int.tryParse(val);
    return null;
  }

  Future<AppSettings> loadAppSettings() async {
    final themeStr = await getSetting('themeMode') ?? 'dark';
    final pinEnabledStr = await getSetting('pinEnabled') ?? 'false';
    final pinHash = await getSetting('pinHash');
    final biometricStr = await getSetting('biometricEnabled') ?? 'false';
    final streakStr = await getSetting('lastStreakResetTime');
    final edgeCount = await getSettingInt('currentEdgeCount') ?? 0;
    final arousalCount = await getSettingInt('currentArousalCount') ?? 0;

    return AppSettings(
      themeMode: themeStr == 'amoled' ? AppThemeMode.amoled : AppThemeMode.dark,
      pinEnabled: pinEnabledStr == 'true',
      pinHash: pinHash,
      biometricEnabled: biometricStr == 'true',
      lastStreakResetTime: streakStr != null && streakStr.isNotEmpty ? DateTime.tryParse(streakStr) : null,
      currentEdgeCount: edgeCount,
      currentArousalCount: arousalCount,
    );
  }
}
