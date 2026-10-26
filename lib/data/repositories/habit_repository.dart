import 'dart:math';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../datasources/database_helper.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_stats.dart';

/// Presentation-ready wrapper pairing a habit definition with its day log and statistics.
class HabitWithLog {
  final Habit habit;
  final HabitLog? log;
  final HabitStats stats;

  const HabitWithLog({
    required this.habit,
    this.log,
    required this.stats,
  });

  /// True if completed for the evaluated date.
  bool get isCompletedToday => log != null && log!.isCompleted;

  /// Current progress counter for numeric habits.
  int get currentCount => log?.value ?? 0;

  /// Progress ratio clamped between 0.0 and 1.0.
  double get progressPercentage {
    if (habit.targetCount <= 0) return 0.0;
    return (currentCount / habit.targetCount).clamp(0.0, 1.0);
  }
}

/// Repository managing habit operations, daily logs, and mathematical analytics.
class HabitRepository {
  final DatabaseHelper _dbHelper;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final _uuid = const Uuid();

  HabitRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  String formatDate(DateTime date) => _dateFormat.format(date);

  Future<List<Habit>> getAllHabits() async {
    return await _dbHelper.getAllHabits();
  }

  Future<Habit?> getHabitById(String id) async {
    return await _dbHelper.getHabitById(id);
  }

  Future<void> saveHabit(Habit habit) async {
    await _dbHelper.insertHabit(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    await _dbHelper.updateHabit(habit);
  }

  Future<void> deleteHabit(String id) async {
    await _dbHelper.deleteHabit(id);
  }

  /// Soft-archives a habit (hides from daily checklist but preserves history).
  Future<void> archiveHabit(String id) async {
    final habit = await _dbHelper.getHabitById(id);
    if (habit == null) return;
    await _dbHelper.updateHabit(
      habit.copyWith(isArchived: true, updatedAt: DateTime.now()),
    );
  }

  /// Restores an archived habit back to the active checklist.
  Future<void> restoreHabit(String id) async {
    final habit = await _dbHelper.getHabitById(id);
    if (habit == null) return;
    await _dbHelper.updateHabit(
      habit.copyWith(isArchived: false, updatedAt: DateTime.now()),
    );
  }

  Future<List<Habit>> getArchivedHabits() async {
    return await _dbHelper.getArchivedHabits();
  }

  /// Updates sort order for all habits after a drag-and-drop reorder.
  Future<void> reorderHabits(List<String> orderedIds) async {
    final updates = orderedIds
        .asMap()
        .entries
        .map((e) => {'id': e.value, 'sort_order': e.key})
        .toList();
    await _dbHelper.updateSortOrders(updates);
  }

  /// Applies a streak freeze to today if the habit has freezes remaining.
  /// Returns true if the freeze was successfully applied.
  Future<bool> applyStreakFreeze(String habitId, DateTime date) async {
    final dateStr = formatDate(date);
    final habit = await _dbHelper.getHabitById(habitId);
    if (habit == null || habit.streakFreezesRemaining <= 0) return false;

    // Only freeze if the day is not already completed
    final existingLog = await _dbHelper.getLog(habitId, dateStr);
    if (existingLog != null && existingLog.isCompleted) return false;

    final freezeLog = HabitLog(
      id: existingLog?.id ?? _uuid.v4(),
      habitId: habitId,
      date: dateStr,
      status: 'frozen',
      value: 0,
      loggedAt: DateTime.now(),
      notes: '❄️ Streak Freeze Applied',
    );
    await _dbHelper.insertOrUpdateLog(freezeLog);

    // Decrement remaining freezes on the habit
    await _dbHelper.updateHabit(
      habit.copyWith(
        streakFreezesRemaining: habit.streakFreezesRemaining - 1,
        updatedAt: DateTime.now(),
      ),
    );
    return true;
  }

  /// Retrieves scheduled habits for a specific date together with logs and updated stats.
  Future<List<HabitWithLog>> getHabitsForDate(DateTime date) async {
    final habits = await _dbHelper.getAllHabits();
    final dateStr = formatDate(date);
    final logs = await _dbHelper.getLogsForDate(dateStr);
    final logMap = {for (var log in logs) log.habitId: log};

    final List<HabitWithLog> result = [];
    for (final habit in habits) {
      if (!habit.isScheduledForWeekday(date.weekday)) continue;

      final log = logMap[habit.id];
      final stats = await calculateStats(habit.id);
      result.add(HabitWithLog(habit: habit, log: log, stats: stats));
    }

    return result;
  }

  /// Toggles habit completion on or off for a designated date.
  Future<void> toggleHabitCompletion(
    String habitId,
    DateTime date, {
    int? moodScore,
    String? notes,
  }) async {
    final dateStr = formatDate(date);
    final habit = await _dbHelper.getHabitById(habitId);
    if (habit == null) return;

    final existingLog = await _dbHelper.getLog(habitId, dateStr);

    if (existingLog != null && existingLog.isCompleted) {
      // Toggle off / remove log
      await _dbHelper.deleteLog(habitId, dateStr);
    } else {
      // Mark completed
      final newLog = HabitLog(
        id: existingLog?.id ?? _uuid.v4(),
        habitId: habitId,
        date: dateStr,
        status: 'completed',
        value: habit.targetCount,
        loggedAt: DateTime.now(),
        moodScore: moodScore ?? existingLog?.moodScore,
        notes: notes ?? existingLog?.notes,
      );
      await _dbHelper.insertOrUpdateLog(newLog);
    }
  }

  /// Updates increment/decrement counter for numeric target habits.
  Future<void> updateHabitProgress(String habitId, DateTime date, int delta) async {
    final dateStr = formatDate(date);
    final habit = await _dbHelper.getHabitById(habitId);
    if (habit == null) return;

    final existingLog = await _dbHelper.getLog(habitId, dateStr);
    final currentVal = existingLog?.value ?? 0;
    final newVal = (currentVal + delta).clamp(0, habit.targetCount * 2);

    if (newVal <= 0) {
      await _dbHelper.deleteLog(habitId, dateStr);
      return;
    }

    final isCompleted = newVal >= habit.targetCount;
    final log = HabitLog(
      id: existingLog?.id ?? _uuid.v4(),
      habitId: habitId,
      date: dateStr,
      status: isCompleted ? 'completed' : 'in_progress',
      value: newVal,
      loggedAt: DateTime.now(),
      moodScore: existingLog?.moodScore,
      notes: existingLog?.notes,
    );
    await _dbHelper.insertOrUpdateLog(log);
  }

  /// Calculates mathematically accurate streaks and 7-day/30-day rolling completion ratios.
  /// Treats 'frozen' log entries as streak-preserving (not a break).
  Future<HabitStats> calculateStats(String habitId) async {
    final habit = await _dbHelper.getHabitById(habitId);
    if (habit == null) return HabitStats.empty(habitId);

    final logs = await _dbHelper.getLogsForHabit(habitId);
    if (logs.isEmpty) return HabitStats.empty(habitId);

    final completedLogs = logs.where((l) => l.isCompleted).toList();
    final totalCompletions = completedLogs.length;
    final completedDateStrings = completedLogs.map((l) => l.date).toSet();
    // Dates that count as "not broken" for streak purposes (completed OR frozen)
    final streakSafeDates = logs
        .where((l) => l.isCompleted || l.isFrozen)
        .map((l) => l.date)
        .toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = formatDate(today);

    // 1. Mathematically Accurate Current Streak Calculation
    // Frozen days count as safe (streak continues through them).
    int currentStreak = 0;
    DateTime cursor = today;

    // Check if today was completed or frozen
    final completedOrFrozenToday = streakSafeDates.contains(todayStr);

    if (!completedOrFrozenToday) {
      // If today is scheduled but not completed/frozen, streak is intact if previous scheduled day was safe
      cursor = today.subtract(const Duration(days: 1));
      while (!habit.isScheduledForWeekday(cursor.weekday) &&
          cursor.isAfter(today.subtract(const Duration(days: 14)))) {
        cursor = cursor.subtract(const Duration(days: 1));
      }

      if (!streakSafeDates.contains(formatDate(cursor))) {
        currentStreak = 0;
      } else {
        while (true) {
          if (habit.isScheduledForWeekday(cursor.weekday)) {
            if (streakSafeDates.contains(formatDate(cursor))) {
              currentStreak++;
            } else {
              break;
            }
          }
          cursor = cursor.subtract(const Duration(days: 1));
          if (cursor.difference(today).inDays.abs() > 365) break;
        }
      }
    } else {
      // Completed/frozen today: count today and walk backward
      while (true) {
        if (habit.isScheduledForWeekday(cursor.weekday)) {
          if (streakSafeDates.contains(formatDate(cursor))) {
            currentStreak++;
          } else {
            break;
          }
        }
        cursor = cursor.subtract(const Duration(days: 1));
        if (cursor.difference(today).inDays.abs() > 365) break;
      }
    }

    // 2. Longest Streak Calculation
    int longestStreak = currentStreak;
    if (completedDateStrings.isNotEmpty) {
      final sortedDates = completedDateStrings
          .map((s) => DateTime.parse(s))
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));

      if (sortedDates.isNotEmpty) {
        int tempStreak = 1;
        if (tempStreak > longestStreak) longestStreak = tempStreak;

        for (int i = 1; i < sortedDates.length; i++) {
          final prev = sortedDates[i - 1];
          final curr = sortedDates[i];
          final diff = curr.difference(prev).inDays;

          if (diff == 1) {
            tempStreak++;
          } else if (diff > 1) {
            // Check if intermediate days were all non-scheduled days
            bool allNonScheduled = true;
            for (int d = 1; d < diff; d++) {
              final intermediate = prev.add(Duration(days: d));
              if (habit.isScheduledForWeekday(intermediate.weekday)) {
                allNonScheduled = false;
                break;
              }
            }
            if (allNonScheduled) {
              tempStreak++;
            } else {
              tempStreak = 1;
            }
          }
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        }
      }
    }

    // 3. Exact Rolling Window Ratios (7 Days & 30 Days)
    final habitCreatedDay = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final daysActive = max(1, today.difference(habitCreatedDay).inDays + 1);

    // 7-Day Window (capped by days active if habit is younger than 7 days)
    final window7 = min(7, daysActive);
    int scheduled7 = 0;
    int completed7 = 0;
    for (int i = 0; i < window7; i++) {
      final d = today.subtract(Duration(days: i));
      if (habit.isScheduledForWeekday(d.weekday)) {
        scheduled7++;
        if (completedDateStrings.contains(formatDate(d))) {
          completed7++;
        }
      }
    }
    final rate7 = scheduled7 > 0 ? (completed7 / scheduled7).clamp(0.0, 1.0) : 0.0;

    // 30-Day Window (capped by days active if habit is younger than 30 days)
    final window30 = min(30, daysActive);
    int scheduled30 = 0;
    int completed30 = 0;
    for (int i = 0; i < window30; i++) {
      final d = today.subtract(Duration(days: i));
      if (habit.isScheduledForWeekday(d.weekday)) {
        scheduled30++;
        if (completedDateStrings.contains(formatDate(d))) {
          completed30++;
        }
      }
    }
    final rate30 = scheduled30 > 0 ? (completed30 / scheduled30).clamp(0.0, 1.0) : 0.0;

    // All-time completion calculation
    int totalScheduledAllTime = 0;
    for (int i = 0; i < daysActive; i++) {
      final d = today.subtract(Duration(days: i));
      if (habit.isScheduledForWeekday(d.weekday)) {
        totalScheduledAllTime++;
      }
    }
    final allTimeRate = totalScheduledAllTime > 0
        ? (totalCompletions / totalScheduledAllTime).clamp(0.0, 1.0)
        : 0.0;

    // Weighted consistency score: 60% weight on recent 7-day habituation + 40% on 30-day baseline
    final consistency = ((rate7 * 0.6 + rate30 * 0.4) * 100).clamp(0.0, 100.0);

    return HabitStats(
      habitId: habitId,
      currentStreak: currentStreak,
      longestStreak: max(longestStreak, currentStreak),
      totalCompletions: totalCompletions,
      completionRate7Days: rate7,
      completionRate30Days: rate30,
      allTimeCompletionRate: allTimeRate,
      consistencyScore: consistency,
      lastCompletedDate: completedLogs.isNotEmpty ? completedLogs.first.loggedAt : null,
    );
  }

  Future<List<HabitLog>> getAllLogs() async {
    return await _dbHelper.getAllLogs();
  }

  Future<List<HabitLog>> getLogsDateRange(DateTime start, DateTime end) async {
    return await _dbHelper.getLogsDateRange(formatDate(start), formatDate(end));
  }

  Future<void> clearAllData() async {
    await _dbHelper.clearAllData();
  }
}
