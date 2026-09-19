import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/behavioral_insight.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      final factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        'offline_habit_tracker.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDb,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'offline_habit_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Habits Table
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
        target_count INTEGER DEFAULT 1,
        unit TEXT DEFAULT 'times',
        reminder_time TEXT,
        anchor_habit_id TEXT,
        is_archived INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Habit Logs Table
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

    // Indexes for fast querying
    await db.execute('CREATE INDEX idx_logs_habit_id ON habit_logs(habit_id)');
    await db.execute('CREATE INDEX idx_logs_date ON habit_logs(date)');
    await db.execute('CREATE INDEX idx_logs_habit_date ON habit_logs(habit_id, date)');

    // Behavioral Insights Table
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

    // Key-Value App Settings Table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // -------------------------------------------------------------
  // Habits CRUD
  // -------------------------------------------------------------
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(String habitId) async {
    final db = await database;
    // SQLite cascade will handle habit_logs
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [habitId]);
    return await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  Future<Habit?> getHabitById(String id) async {
    final db = await database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Habit.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Habit>> getAllHabits({bool includeArchived = false}) async {
    final db = await database;
    final where = includeArchived ? null : 'is_archived = 0';
    final result = await db.query(
      'habits',
      where: where,
      orderBy: 'created_at ASC',
    );
    return result.map((m) => Habit.fromMap(m)).toList();
  }

  // -------------------------------------------------------------
  // Habit Logs CRUD
  // -------------------------------------------------------------
  Future<int> insertOrUpdateLog(HabitLog log) async {
    final db = await database;
    return await db.insert(
      'habit_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteLog(String habitId, String date) async {
    final db = await database;
    return await db.delete(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );
  }

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

  Future<List<HabitLog>> getLogsForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'habit_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((m) => HabitLog.fromMap(m)).toList();
  }

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

  Future<List<HabitLog>> getAllLogs() async {
    final db = await database;
    final result = await db.query('habit_logs', orderBy: 'date ASC');
    return result.map((m) => HabitLog.fromMap(m)).toList();
  }

  // -------------------------------------------------------------
  // Behavioral Insights CRUD
  // -------------------------------------------------------------
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

  Future<List<BehavioralInsight>> getActiveInsights() async {
    final db = await database;
    final result = await db.query(
      'behavioral_insights',
      where: 'is_dismissed = 0',
      orderBy: 'generated_at DESC',
    );
    return result.map((m) => BehavioralInsight.fromMap(m)).toList();
  }

  Future<int> dismissInsight(String insightId) async {
    final db = await database;
    return await db.update(
      'behavioral_insights',
      {'is_dismissed': 1},
      where: 'id = ?',
      whereArgs: [insightId],
    );
  }

  Future<int> clearAllInsights() async {
    final db = await database;
    return await db.delete('behavioral_insights');
  }

  // -------------------------------------------------------------
  // App Settings CRUD
  // -------------------------------------------------------------
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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
  // Maintenance & Reset
  // -------------------------------------------------------------
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('habit_logs');
    await db.delete('behavioral_insights');
    await db.delete('habits');
    await db.delete('app_settings');
  }
}
