import 'package:flutter/foundation.dart';
import '../../data/models/behavioral_insight.dart';
import '../../data/models/habit_stats.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/insights_repository.dart';
import '../../domain/engine/behavioral_engine.dart';

class InsightsViewModel extends ChangeNotifier {
  final HabitRepository _habitRepository;
  final InsightsRepository _insightsRepository;

  InsightsViewModel({
    HabitRepository? habitRepository,
    InsightsRepository? insightsRepository,
  })  : _habitRepository = habitRepository ?? HabitRepository(),
        _insightsRepository = insightsRepository ?? InsightsRepository();

  List<BehavioralInsight> _insights = [];
  bool _isAnalyzing = false;
  String _filterType = 'All'; // 'All', 'Stacking', 'Timing', 'Weekend', 'Momentum'
  double _momentumIndex = 0.0;

  List<BehavioralInsight> get insights => _insights;
  bool get isAnalyzing => _isAnalyzing;
  String get filterType => _filterType;
  double get momentumIndex => _momentumIndex;

  List<BehavioralInsight> get filteredInsights {
    if (_filterType == 'All') return _insights;
    if (_filterType == 'Stacking') {
      return _insights.where((i) => i.type == InsightType.habitStacking).toList();
    }
    if (_filterType == 'Timing') {
      return _insights.where((i) => i.type == InsightType.optimalTiming).toList();
    }
    if (_filterType == 'Weekend') {
      return _insights.where((i) => i.type == InsightType.weekendSlump).toList();
    }
    if (_filterType == 'Momentum') {
      return _insights
          .where((i) =>
              i.type == InsightType.streakRisk ||
              i.type == InsightType.momentumMilestone ||
              i.type == InsightType.recoveryOpportunity)
          .toList();
    }
    return _insights;
  }

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  Future<void> runBehavioralAnalysis() async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      final habits = await _habitRepository.getAllHabits();
      final logs = await _habitRepository.getAllLogs();

      // Compute stats for all habits
      final Map<String, HabitStats> statsMap = {};
      double totalConsistency = 0;
      for (final habit in habits) {
        final stats = await _habitRepository.calculateStats(habit.id);
        statsMap[habit.id] = stats;
        totalConsistency += stats.consistencyScore;
      }

      if (habits.isNotEmpty) {
        _momentumIndex = (totalConsistency / habits.length).clamp(0.0, 100.0);
      } else {
        _momentumIndex = 0.0;
      }

      // Run local rule-based heuristics
      final freshInsights = BehavioralInsightsEngine.analyzeAll(
        habits: habits,
        logs: logs,
        statsMap: statsMap,
      );

      // Save to SQLite
      await _insightsRepository.clearAllInsights();
      await _insightsRepository.saveInsights(freshInsights);

      _insights = await _insightsRepository.getActiveInsights();
    } catch (e) {
      debugPrint('Error running behavioral analysis: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> dismissInsight(String id) async {
    try {
      await _insightsRepository.dismissInsight(id);
      _insights.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error dismissing insight: $e');
    }
  }
}
