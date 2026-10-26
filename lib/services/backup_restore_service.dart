import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../data/datasources/database_helper.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';

/// Service responsible for exporting all habit data to a portable JSON backup file
/// and restoring from such a backup — implementing full offline data sovereignty.
///
/// Backup format (habitforge_backup_`date`.json):
/// ```json
/// {
///   "version": 3,
///   "exported_at": "...",
///   "habits": [...],
///   "logs": [...]
/// }
/// ```
class BackupRestoreService {
  static final BackupRestoreService instance = BackupRestoreService._internal();
  BackupRestoreService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const int _backupVersion = 3;

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Exports all habits and logs into a timestamped JSON file in the device's
  /// Documents directory. Returns the full file path on success.
  Future<String?> exportBackup() async {
    try {
      final habits = await _db.getAllHabits(includeArchived: true);
      final logs = await _db.getAllLogs();

      final payload = {
        'version': _backupVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'habit_count': habits.length,
        'log_count': logs.length,
        'habits': habits.map((h) => h.toJson()).toList(),
        'logs': logs.map((l) => l.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(payload);

      final dir = await _getBackupDirectory();
      final dateTag = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final file = File('${dir.path}/habitforge_backup_$dateTag.json');

      await file.writeAsString(jsonString, encoding: utf8);
      debugPrint('[BackupRestore] Exported ${habits.length} habits, ${logs.length} logs → ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[BackupRestore] Export failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Import / Restore
  // ---------------------------------------------------------------------------

  /// Reads a HabitForge JSON backup file and merges it into the local database.
  /// Returns a [RestoreResult] describing how many records were imported.
  Future<RestoreResult> importBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return RestoreResult.error('File not found: $filePath');
      }

      final raw = await file.readAsString(encoding: utf8);
      final Map<String, dynamic> payload = json.decode(raw);

      final int backupVersion = (payload['version'] as num?)?.toInt() ?? 1;
      if (backupVersion > _backupVersion) {
        return RestoreResult.error(
          'Backup was created by a newer version of HabitForge ($backupVersion). '
          'Please update the app first.',
        );
      }

      final List<dynamic> habitsMaps = payload['habits'] ?? [];
      final List<dynamic> logsMaps = payload['logs'] ?? [];

      final habits = habitsMaps
          .map((m) => Habit.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      final logs = logsMaps
          .map((m) => HabitLog.fromJson(Map<String, dynamic>.from(m)))
          .toList();

      // Merge strategy: replace existing records with backup (UPSERT)
      await _db.batchInsertHabits(habits);
      await _db.batchInsertLogs(logs);

      debugPrint('[BackupRestore] Restored ${habits.length} habits, ${logs.length} logs');
      return RestoreResult.success(
        habitCount: habits.length,
        logCount: logs.length,
        exportedAt: payload['exported_at'] as String?,
      );
    } catch (e) {
      debugPrint('[BackupRestore] Import failed: $e');
      return RestoreResult.error('Restore failed: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // List existing backups
  // ---------------------------------------------------------------------------

  /// Lists all backup files in the backup directory sorted newest-first.
  Future<List<File>> listBackups() async {
    try {
      final dir = await _getBackupDirectory();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json') && f.uri.pathSegments.last.startsWith('habitforge_backup_'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Deletes a backup file.
  Future<bool> deleteBackup(String filePath) async {
    try {
      await File(filePath).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<Directory> _getBackupDirectory() async {
    if (kIsWeb) throw UnsupportedError('Backup not supported on web');
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/HabitForge/backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> getBackupDirectoryPath() async {
    final dir = await _getBackupDirectory();
    return dir.path;
  }
}

/// Result object for a restore operation.
class RestoreResult {
  final bool success;
  final int habitCount;
  final int logCount;
  final String? exportedAt;
  final String? errorMessage;

  const RestoreResult._({
    required this.success,
    this.habitCount = 0,
    this.logCount = 0,
    this.exportedAt,
    this.errorMessage,
  });

  factory RestoreResult.success({
    required int habitCount,
    required int logCount,
    String? exportedAt,
  }) =>
      RestoreResult._(
        success: true,
        habitCount: habitCount,
        logCount: logCount,
        exportedAt: exportedAt,
      );

  factory RestoreResult.error(String message) =>
      RestoreResult._(success: false, errorMessage: message);
}
