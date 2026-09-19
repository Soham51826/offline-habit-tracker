import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/habit_log.dart';
import '../../data/models/habit_stats.dart';
import '../../data/repositories/habit_repository.dart';

class DailyCompletionMetric {
  final DateTime date;
  final String dayLabel; // e.g. "Mon", "Tue"
  final int completed;
  final int scheduled;
  final double percentage;

  DailyCompletionMetric({
    required this.date,
    required this.dayLabel,
    required this.completed,
    required this.scheduled,
    required this.percentage,
  });
}

class HeatmapDayCell {
  final DateTime date;
  final int completionCount;
  final double intensity; // 0.0 (none) to 1.0 (all completed)

  HeatmapDayCell({
    required this.date,
    required this.completionCount,
    required this.intensity,
  });
}

class CategoryBreakdown {
  final String category;
  final int count;
  final Color color;

  CategoryBreakdown({
    required this.category,
    required this.count,
    required this.color,
  });
}

class StatsViewModel extends ChangeNotifier {
  final HabitRepository _repository;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _shortDayFormat = DateFormat('E');

  StatsViewModel({HabitRepository? repository})
      : _repository = repository ?? HabitRepository();

  bool _isLoading = false;
  List<DailyCompletionMetric> _sevenDayMetrics = [];
  List<DailyCompletionMetric> _thirtyDayMetrics = [];
  List<HeatmapDayCell> _heatmapCells = [];
  List<CategoryBreakdown> _categoryBreakdown = [];
  Map<String, HabitStats> _habitStats = {};
  int _bestStreak = 0;
  int _totalCompletionsAllTime = 0;
  double _overallConsistency = 0.0;

  bool get isLoading => _isLoading;
  List<DailyCompletionMetric> get sevenDayMetrics => _sevenDayMetrics;
  List<DailyCompletionMetric> get thirtyDayMetrics => _thirtyDayMetrics;
  List<HeatmapDayCell> get heatmapCells => _heatmapCells;
  List<CategoryBreakdown> get categoryBreakdown => _categoryBreakdown;
  Map<String, HabitStats> get habitStats => _habitStats;
  int get bestStreak => _bestStreak;
  int get totalCompletionsAllTime => _totalCompletionsAllTime;
  double get overallConsistency => _overallConsistency;

  Future<void> loadAnalytics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final habits = await _repository.getAllHabits();
      final logs = await _repository.getAllLogs();
      final now = DateTime.now();

      // Compute habit stats
      _habitStats = {};
      int maxStreak = 0;
      int totalCompletions = 0;
      double totalConsistency = 0;

      for (final habit in habits) {
        final stats = await _repository.calculateStats(habit.id);
        _habitStats[habit.id] = stats;
        if (stats.longestStreak > maxStreak) maxStreak = stats.longestStreak;
        totalCompletions += stats.totalCompletions;
        totalConsistency += stats.consistencyScore;
      }

      _bestStreak = maxStreak;
      _totalCompletionsAllTime = totalCompletions;
      _overallConsistency = habits.isNotEmpty ? (totalConsistency / habits.length) : 0.0;

      // Group logs by date
      final Map<String, List<HabitLog>> logsByDate = {};
      for (final log in logs) {
        logsByDate.putIfAbsent(log.date, () => []).add(log);
      }

      // 1. Last 7 Days Metrics
      final List<DailyCompletionMetric> last7 = [];
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dStr = _dateFormat.format(d);
        final dateLogs = logsByDate[dStr] ?? [];
        final completed = dateLogs.where((l) => l.isCompleted).length;

        int scheduled = 0;
        for (final h in habits) {
          if (h.isScheduledForWeekday(d.weekday)) scheduled++;
        }

        final pct = scheduled > 0 ? (completed / scheduled).clamp(0.0, 1.0) : 0.0;
        last7.add(DailyCompletionMetric(
          date: d,
          dayLabel: _shortDayFormat.format(d),
          completed: completed,
          scheduled: scheduled,
          percentage: pct,
        ));
      }
      _sevenDayMetrics = last7;

      // 2. Last 30 Days Metrics
      final List<DailyCompletionMetric> last30 = [];
      for (int i = 29; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dStr = _dateFormat.format(d);
        final dateLogs = logsByDate[dStr] ?? [];
        final completed = dateLogs.where((l) => l.isCompleted).length;

        int scheduled = 0;
        for (final h in habits) {
          if (h.isScheduledForWeekday(d.weekday)) scheduled++;
        }

        final pct = scheduled > 0 ? (completed / scheduled).clamp(0.0, 1.0) : 0.0;
        last30.add(DailyCompletionMetric(
          date: d,
          dayLabel: '${d.day}/${d.month}',
          completed: completed,
          scheduled: scheduled,
          percentage: pct,
        ));
      }
      _thirtyDayMetrics = last30;

      // 3. 28-Day Heatmap (4 weeks x 7 days)
      final List<HeatmapDayCell> cells = [];
      for (int i = 27; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dStr = _dateFormat.format(d);
        final dateLogs = logsByDate[dStr] ?? [];
        final completed = dateLogs.where((l) => l.isCompleted).length;

        int scheduled = 0;
        for (final h in habits) {
          if (h.isScheduledForWeekday(d.weekday)) scheduled++;
        }

        final intensity = scheduled > 0 ? (completed / scheduled).clamp(0.0, 1.0) : 0.0;
        cells.add(HeatmapDayCell(
          date: d,
          completionCount: completed,
          intensity: intensity,
        ));
      }
      _heatmapCells = cells;

      // 4. Category Breakdown
      final Map<String, int> catCounts = {};
      final Map<String, Color> catColors = {};
      for (final h in habits) {
        catCounts[h.category] = (catCounts[h.category] ?? 0) + 1;
        catColors[h.category] = Color(h.colorValue);
      }

      _categoryBreakdown = catCounts.entries.map((e) {
        return CategoryBreakdown(
          category: e.key,
          count: e.value,
          color: catColors[e.key] ?? const Color(0xFF10B981),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
