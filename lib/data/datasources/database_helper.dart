import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/behavioral_insight.dart';

/// Single source of truth for the on-device SQLite database.
///
/// Manages schema creation, migrations, table indices, and performant ACID-compliant
/// transactions for habits, daily execution logs, behavioral insights, and app preferences.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  /// Returns the singleton database handle, lazily initializing on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes SQLite database with cross-platform desktop/web/mobile support.
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      final factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        'offline_habit_tracker.db',
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _createDb,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'offline_habit_tracker.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  /// Handles schema migrations across versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE habits ADD COLUMN latitude REAL');
        await db.execute('ALTER TABLE habits ADD COLUMN longitude REAL');
        await db.execute('ALTER TABLE habits ADD COLUMN location_name TEXT');
        await db.execute('ALTER TABLE habits ADD COLUMN geofence_radius REAL DEFAULT 150.0');
      } catch (e) {
        debugPrint('v2 columns may already exist: $e');
      }
    }
    if (oldVersion < 3) {
      // v3: Flexible frequency, negative habits, drag-order, streak freeze
      try {
        await db.execute('ALTER TABLE habits ADD COLUMN frequency_target_days INTEGER DEFAULT 3');
        await db.execute("ALTER TABLE habits ADD COLUMN habit_type TEXT DEFAULT 'positive'");
        await db.execute('ALTER TABLE habits ADD COLUMN sort_order INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE habits ADD COLUMN streak_freezes_remaining INTEGER DEFAULT 2');
        debugPrint('v3 migration complete');
      } catch (e) {
        debugPrint('v3 columns may already exist: $e');
      }
    }
  }

  /// Creates all application tables with relational constraints and indexing.
  Future<void> _createDb(Database db, int version) async {
    // 1. Habits Table (v3 schema)
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_name TEXT NOT NULL,
        frequency_type TEXT NOT NULL DEFAULT 'daily',
        custom_days TEXT DEFAULT '1,2,3,4,5,6,7',
        frequency_target_days INTEGER DEFAULT 3,
        target_count INTEGER DEFAULT 1,
        unit TEXT DEFAULT 'times',
        reminder_time TEXT,
        anchor_habit_id TEXT,
        is_archived INTEGER DEFAULT 0,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        geofence_radius REAL DEFAULT 150.0,
        habit_type TEXT DEFAULT 'positive',
        sort_order INTEGER DEFAULT 0,
        streak_freezes_remaining INTEGER DEFAULT 2,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Habit Logs Table
    await db.execute('''
      CREATE TABLE habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        value INTEGER DEFAULT 1,
        notes TEXT,
        logged_at TEXT NOT NULL,
        mood_score INTEGER,
        UNIQUE(habit_id, date),
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    // High-performance B-tree indexes for zero-latency queries
    await db.execute('CREATE INDEX idx_logs_habit_id ON habit_logs(habit_id)');
    await db.execute('CREATE INDEX idx_logs_date ON habit_logs(date)');
    await db.execute('CREATE INDEX idx_logs_habit_date ON habit_logs(habit_id, date)');
    await db.execute('CREATE INDEX idx_logs_status ON habit_logs(status)');

    // 3. Behavioral Insights Table
    await db.execute('''
      CREATE TABLE behavioral_insights (
        id TEXT PRIMARY KEY,
        habit_id TEXT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        actionable_step TEXT NOT NULL,
        psychology_principle TEXT NOT NULL,
        severity TEXT NOT NULL,
        generated_at TEXT NOT NULL,
        is_dismissed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_insights_type ON behavioral_insights(type)');
    await db.execute('CREATE INDEX idx_insights_dismissed ON behavioral_insights(is_dismissed)');

    // 4. Key-Value App Settings Table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // -------------------------------------------------------------
  // Habits CRUD Operations
  // -------------------------------------------------------------

  /// Inserts a new habit or updates an existing habit record.
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates an existing habit definition.
  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Deletes a habit and all associated daily logs via cascade deletion.
  Future<int> deleteHabit(String habitId) async {
    final db = await database;
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [habitId]);
    return await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  /// Retrieves a specific habit by its unique identifier.
  Future<Habit?> getHabitById(String id) async {
    final db = await database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Habit.fromMap(maps.first);
    }
    return null;
  }

  /// Retrieves all habits, sorted by user-defined sort_order, then creation time.
  Future<List<Habit>> getAllHabits({bool includeArchived = false}) async {
    final db = await database;
    final where = includeArchived ? null : 'is_archived = 0';
    final result = await db.query(
      'habits',
      where: where,
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return result.map((m) => Habit.fromMap(m)).toList();
  }

  /// Returns only archived habits for the archive vault screen.
  Future<List<Habit>> getArchivedHabits() async {
    final db = await database;
    final result = await db.query(
      'habits',
      where: 'is_archived = 1',
      orderBy: 'updated_at DESC',
    );
    return result.map((m) => Habit.fromMap(m)).toList();
  }

  /// Atomically updates sort_order for multiple habits (drag-and-drop).
  Future<void> updateSortOrders(List<Map<String, dynamic>> updates) async {
    final db = await database;
    final batch = db.batch();
    for (final u in updates) {
      batch.update(
        'habits',
        {'sort_order': u['sort_order']},
        where: 'id = ?',
        whereArgs: [u['id']],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Batch inserts habits for restore operation.
  Future<void> batchInsertHabits(List<Habit> habits) async {
    final db = await database;
    final batch = db.batch();
    for (final h in habits) {
      batch.insert('habits', h.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Batch inserts logs for restore operation.
  Future<void> batchInsertLogs(List<HabitLog> logs) async {
    final db = await database;
    final batch = db.batch();
    for (final l in logs) {
      batch.insert('habit_logs', l.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // -------------------------------------------------------------
  // Habit Logs CRUD Operations & Optimized Queries
  // -------------------------------------------------------------

  /// Inserts or updates a daily log execution for a habit.
  Future<int> insertOrUpdateLog(HabitLog log) async {
    final db = await database;
    return await db.insert(
      'habit_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a specific day's log for a habit.
  Future<int> deleteLog(String habitId, String date) async {
    final db = await database;
    return await db.delete(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );
  }

  /// Retrieves a specific day's log for a habit.
  Future<HabitLog?> getLog(String habitId, String date) async {
    final db = await database;
    final maps = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );
    if (maps.isNotEmpty) {
      return HabitLog.fromMap(maps.first);
    }
    return null;
  }

  /// Retrieves all habit logs recorded on a specific date (YYYY-MM-DD).
  Future<List<HabitLog>> getLogsForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((m) => HabitLog.fromMap(m)).toList();
  }

  /// Retrieves history logs for a specific habit.
  Future<List<HabitLog>> getLogsForHabit(String habitId, {int? limit}) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return result.map((m) => HabitLog.fromMap(m)).toList();
  }

  /// Returns all logs within an inclusive date range (YYYY-MM-DD).
  Future<List<HabitLog>> getLogsDateRange(String startDate, String endDate) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return result.map((m) => HabitLog.fromMap(m)).toList();
  }

  /// Fast SQL aggregate query counting completed sessions for a habit in a date window.
  Future<int> getCompletionsCountInDateRange(String habitId, String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM habit_logs 
      WHERE habit_id = ? 
        AND date >= ? 
        AND date <= ? 
        AND status = 'completed'
      ''',
      [habitId, startDate, endDate],
    );
    if (result.isNotEmpty && result.first['count'] != null) {
      return (result.first['count'] as num).toInt();
    }
    return 0;
  }

  /// Retrieves all habit logs across the entire database.
  Future<List<HabitLog>> getAllLogs() async {
    final db = await database;
    final result = await db.query('habit_logs', orderBy: 'date ASC');
    return result.map((m) => HabitLog.fromMap(m)).toList();
  }

  // -------------------------------------------------------------
  // Behavioral Insights CRUD Operations
  // -------------------------------------------------------------

  /// Batches insertions of fresh behavioral insights.
  Future<void> saveInsights(List<BehavioralInsight> insights) async {
    final db = await database;
    final batch = db.batch();
    for (final insight in insights) {
      batch.insert(
        'behavioral_insights',
        insight.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Retrieves all active (non-dismissed) behavioral insights.
  Future<List<BehavioralInsight>> getActiveInsights() async {
    final db = await database;
    final result = await db.query(
      'behavioral_insights',
      where: 'is_dismissed = 0',
      orderBy: 'generated_at DESC',
    );
    return result.map((m) => BehavioralInsight.fromMap(m)).toList();
  }

  /// Marks a behavioral insight as dismissed by the user.
  Future<int> dismissInsight(String insightId) async {
    final db = await database;
    return await db.update(
      'behavioral_insights',
      {'is_dismissed': 1},
      where: 'id = ?',
      whereArgs: [insightId],
    );
  }

  /// Clears all stored insights.
  Future<int> clearAllInsights() async {
    final db = await database;
    return await db.delete('behavioral_insights');
  }

  // -------------------------------------------------------------
  // App Settings CRUD Operations
  // -------------------------------------------------------------

  /// Sets a persistent key-value configuration.
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a persistent key-value configuration.
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  // -------------------------------------------------------------
  // Maintenance & Nuclear Reset
  // -------------------------------------------------------------

  /// Permanently deletes all records across all tables.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('habit_logs');
    await db.delete('behavioral_insights');
    await db.delete('habits');
    await db.delete('app_settings');
  }
}
