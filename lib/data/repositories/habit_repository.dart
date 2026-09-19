import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../datasources/database_helper.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_stats.dart';

class HabitWithLog {
  final Habit habit;
  final HabitLog? log;
  final HabitStats stats;

  const HabitWithLog({
    required this.habit,
    this.log,
    required this.stats,
  });

  bool get isCompletedToday => log != null && log!.isCompleted;
  int get currentCount => log?.value ?? 0;
  double get progressPercentage {
    if (habit.targetCount <= 0) return 0.0;
    return (currentCount / habit.targetCount).clamp(0.0, 1.0);
  }
}

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

  Future<void> toggleHabitCompletion(String habitId, DateTime date, {int? moodScore, String? notes}) async {
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

  Future<HabitStats> calculateStats(String habitId) async {
    final habit = await _dbHelper.getHabitById(habitId);
    if (habit == null) return HabitStats.empty(habitId);

    final logs = await _dbHelper.getLogsForHabit(habitId);
    if (logs.isEmpty) return HabitStats.empty(habitId);

    final completedLogs = logs.where((l) => l.isCompleted).toList();
    final totalCompletions = completedLogs.length;

    // Set of completed date strings
    final completedDateStrings = completedLogs.map((l) => l.date).toSet();

    // 1. Current Streak Calculation
    int currentStreak = 0;
    final now = DateTime.now();
    final todayStr = formatDate(now);
    final yesterdayStr = formatDate(now.subtract(const Duration(days: 1)));

    DateTime checkDate;
    if (completedDateStrings.contains(todayStr)) {
      checkDate = now;
    } else if (completedDateStrings.contains(yesterdayStr)) {
      checkDate = now.subtract(const Duration(days: 1));
    } else {
      checkDate = now; // streak is 0 if neither today nor yesterday completed
    }

    if (completedDateStrings.contains(formatDate(checkDate))) {
      while (true) {
        final dStr = formatDate(checkDate);
        if (completedDateStrings.contains(dStr)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          // If custom frequency, check if day was scheduled
          if (!habit.isScheduledForWeekday(checkDate.weekday)) {
            // Skipped non-scheduled day doesn't break streak
            checkDate = checkDate.subtract(const Duration(days: 1));
            continue;
          }
          break;
        }
      }
    }

    // 2. Longest Streak Calculation
    int longestStreak = 0;
    int tempStreak = 0;
    if (completedDateStrings.isNotEmpty) {
      final sortedDates = completedDateStrings.map((s) => DateTime.parse(s)).toList()
        ..sort((a, b) => a.compareTo(b));

      if (sortedDates.isNotEmpty) {
        tempStreak = 1;
        longestStreak = 1;
        for (int i = 1; i < sortedDates.length; i++) {
          final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
          if (diff == 1) {
            tempStreak++;
          } else if (diff > 1) {
            // Check if intermediate days were non-scheduled
            bool allNonScheduled = true;
            for (int d = 1; d < diff; d++) {
              final intermediate = sortedDates[i - 1].add(Duration(days: d));
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

    // 3. Completion Rates (7 Days & 30 Days)
    int scheduled7 = 0;
    int completed7 = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      if (habit.isScheduledForWeekday(day.weekday)) {
        scheduled7++;
        if (completedDateStrings.contains(formatDate(day))) {
          completed7++;
        }
      }
    }
    final rate7 = scheduled7 > 0 ? completed7 / scheduled7 : 0.0;

    int scheduled30 = 0;
    int completed30 = 0;
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      if (habit.isScheduledForWeekday(day.weekday)) {
        scheduled30++;
        if (completedDateStrings.contains(formatDate(day))) {
          completed30++;
        }
      }
    }
    final rate30 = scheduled30 > 0 ? completed30 / scheduled30 : 0.0;

    // All-time completion rate from habit creation
    final daysSinceCreation = now.difference(habit.createdAt).inDays + 1;
    final totalScheduled = (daysSinceCreation * (scheduled7 / (7 > 0 ? 7 : 1))).round().clamp(1, 99999);
    final allTimeRate = (totalCompletions / totalScheduled).clamp(0.0, 1.0);

    // Consistency score (weighted 60% 7-day rate + 40% 30-day rate)
    final consistency = ((rate7 * 0.6 + rate30 * 0.4) * 100).clamp(0.0, 100.0);

    return HabitStats(
      habitId: habitId,
      currentStreak: currentStreak,
      longestStreak: longestStreak > currentStreak ? longestStreak : currentStreak,
      totalCompletions: totalCompletions,
      completionRate7Days: rate7,
      completionRate30Days: rate30,
      allTimeCompletionRate: allTimeRate,
      consistencyScore: consistency,
      lastCompletedDate: completedLogs.isNotEmpty
          ? completedLogs.first.loggedAt
          : null,
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
