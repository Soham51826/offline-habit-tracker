import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_log.dart';
import '../../data/models/behavioral_insight.dart';
import '../../data/models/habit_stats.dart';
import 'local_coach_prompts.dart';

/// Pure Dart on-device Behavioral Intelligence Engine.
///
/// Runs deterministic heuristics across SQLite habits and logs to synthesize personalized,
/// actionable coaching experiments without sending any data to cloud servers. Grounded in:
/// - James Clear (Atomic Habits: Habit Stacking, "Never Miss Twice")
/// - Dr. BJ Fogg (Tiny Habits: Weekend Ability Scaling)
/// - Roy Baumeister (Ego Depletion: Circadian Timing Alignment)
/// - Daniel Kahneman (Prospect Theory: Streak Loss Aversion)
/// - Phillippa Lally (Automaticity Milestones)
class BehavioralInsightsEngine {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static const _uuid = Uuid();

  /// Analyzes local habit data and returns an ordered list of high-impact behavioral interventions.
  static List<BehavioralInsight> analyzeAll({
    required List<Habit> habits,
    required List<HabitLog> logs,
    required Map<String, HabitStats> statsMap,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final List<BehavioralInsight> insights = [];

    if (habits.isEmpty) return insights;

    // Group logs by habit
    final Map<String, List<HabitLog>> logsByHabit = {};
    for (final log in logs) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
    }

    // -------------------------------------------------------------
    // 1. Streak-at-Risk, "Never Miss Twice", and Milestone Celebrations
    // -------------------------------------------------------------
    for (final habit in habits) {
      final stats = statsMap[habit.id];
      if (stats == null) continue;

      final habitLogs = logsByHabit[habit.id] ?? [];
      final todayStr = _dateFormat.format(now);
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = _dateFormat.format(yesterday);

      final completedDates = habitLogs.where((l) => l.isCompleted).map((l) => l.date).toSet();
      final hasCompletedToday = completedDates.contains(todayStr);
      final hasCompletedYesterday = completedDates.contains(yesterdayStr);

      // Rule A: Streak-at-Risk (Loss Aversion)
      // If current streak >= 3, not completed today, and local time is afternoon/evening (>= 14:00)
      if (stats.currentStreak >= 3 && !hasCompletedToday && now.hour >= 14) {
        final content = LocalCoachPrompts.formatStreakAtRisk(
          habitTitle: habit.title,
          streakDays: stats.currentStreak,
        );
        insights.add(BehavioralInsight(
          id: _uuid.v4(),
          habitId: habit.id,
          type: InsightType.streakRisk,
          title: content['title']!,
          message: content['message']!,
          actionableStep: content['actionable_step']!,
          psychologyPrinciple: content['psychology_principle']!,
          severity: InsightSeverity.urgent,
          generatedAt: now,
        ));
      }

      // Rule B: Never Miss Twice (James Clear)
      // If yesterday was scheduled and missed, and today is scheduled and pending
      if (habit.isScheduledForWeekday(yesterday.weekday) &&
          !hasCompletedYesterday &&
          habit.isScheduledForWeekday(now.weekday) &&
          !hasCompletedToday &&
          stats.currentStreak == 0 &&
          stats.totalCompletions >= 3) {
        final content = LocalCoachPrompts.formatNeverMissTwice(
          habitTitle: habit.title,
        );
        insights.add(BehavioralInsight(
          id: _uuid.v4(),
          habitId: habit.id,
          type: InsightType.recoveryOpportunity,
          title: content['title']!,
          message: content['message']!,
          actionableStep: content['actionable_step']!,
          psychologyPrinciple: content['psychology_principle']!,
          severity: InsightSeverity.warning,
          generatedAt: now,
        ));
      }

      // Rule C: Milestone Celebration (Automaticity Curve - 7, 14, 21, 30, 66, 100 days)
      const milestones = [7, 14, 21, 30, 66, 100];
      if (milestones.contains(stats.currentStreak) && hasCompletedToday) {
        final content = LocalCoachPrompts.formatMilestoneCelebration(
          habitTitle: habit.title,
          streakDays: stats.currentStreak,
        );
        insights.add(BehavioralInsight(
          id: _uuid.v4(),
          habitId: habit.id,
          type: InsightType.momentumMilestone,
          title: content['title']!,
          message: content['message']!,
          actionableStep: content['actionable_step']!,
          psychologyPrinciple: content['psychology_principle']!,
          severity: InsightSeverity.celebration,
          generatedAt: now,
        ));
      }
    }

    // -------------------------------------------------------------
    // 2. Habit Stacking Heuristic (Procedural Memory Anchoring)
    // -------------------------------------------------------------
    final anchorCandidates = habits.where((h) {
      final stats = statsMap[h.id];
      return stats != null && stats.completionRate30Days >= 0.75 && stats.totalCompletions >= 5;
    }).toList();

    final needyHabits = habits.where((h) {
      final stats = statsMap[h.id];
      return stats != null &&
          stats.completionRate30Days < 0.60 &&
          h.anchorHabitId == null &&
          stats.totalCompletions >= 2;
    }).toList();

    if (anchorCandidates.isNotEmpty && needyHabits.isNotEmpty) {
      anchorCandidates.sort((a, b) =>
          (statsMap[b.id]?.completionRate30Days ?? 0).compareTo(statsMap[a.id]?.completionRate30Days ?? 0));
      final bestAnchor = anchorCandidates.first;
      final anchorStats = statsMap[bestAnchor.id]!;

      needyHabits.sort((a, b) =>
          (statsMap[a.id]?.completionRate30Days ?? 0).compareTo(statsMap[b.id]?.completionRate30Days ?? 0));
      final targetHabit = needyHabits.first;
      final targetStats = statsMap[targetHabit.id]!;

      final content = LocalCoachPrompts.formatHabitStacking(
        anchorHabitTitle: bestAnchor.title,
        targetHabitTitle: targetHabit.title,
        anchorConsistency: anchorStats.completionRate30Days,
        targetConsistency: targetStats.completionRate30Days,
      );

      insights.add(BehavioralInsight(
        id: _uuid.v4(),
        habitId: targetHabit.id,
        type: InsightType.habitStacking,
        title: content['title']!,
        message: content['message']!,
        actionableStep: content['actionable_step']!,
        psychologyPrinciple: content['psychology_principle']!,
        severity: InsightSeverity.suggestion,
        generatedAt: now,
      ));
    }

    // -------------------------------------------------------------
    // 3. Weekend Slump Detection (Fogg Behavior Model: Ability Scaling)
    // -------------------------------------------------------------
    for (final habit in habits) {
      if (habit.frequencyType == 'weekdays') continue; // Skip weekday-only habits

      final habitLogs = logsByHabit[habit.id] ?? [];
      if (habitLogs.length < 6) continue;

      int weekdayScheduled = 0;
      int weekdayCompleted = 0;
      int weekendScheduled = 0;
      int weekendCompleted = 0;

      final completedSet = habitLogs.where((l) => l.isCompleted).map((l) => l.date).toSet();

      // Analyze rolling 21-day window
      for (int i = 0; i < 21; i++) {
        final d = now.subtract(Duration(days: i));
        final dStr = _dateFormat.format(d);
        if (!habit.isScheduledForWeekday(d.weekday)) continue;

        if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
          weekendScheduled++;
          if (completedSet.contains(dStr)) weekendCompleted++;
        } else {
          weekdayScheduled++;
          if (completedSet.contains(dStr)) weekdayCompleted++;
        }
      }

      if (weekdayScheduled >= 5 && weekendScheduled >= 3) {
        final weekdayRate = weekdayCompleted / weekdayScheduled;
        final weekendRate = weekendCompleted / weekendScheduled;

        if (weekdayRate >= 0.65 && weekendRate < (weekdayRate - 0.25)) {
          final drop = ((weekdayRate - weekendRate) / weekdayRate) * 100;
          final content = LocalCoachPrompts.formatWeekendSlump(
            habitTitle: habit.title,
            weekdayRate: weekdayRate,
            weekendRate: weekendRate,
            dropPercent: drop,
          );

          insights.add(BehavioralInsight(
            id: _uuid.v4(),
            habitId: habit.id,
            type: InsightType.weekendSlump,
            title: content['title']!,
            message: content['message']!,
            actionableStep: content['actionable_step']!,
            psychologyPrinciple: content['psychology_principle']!,
            severity: InsightSeverity.warning,
            generatedAt: now,
          ));
        }
      }
    }

    // -------------------------------------------------------------
    // 4. Circadian Friction / Optimal Timing (Roy Baumeister: Ego Depletion)
    // -------------------------------------------------------------
    for (final habit in habits) {
      final habitLogs = logsByHabit[habit.id] ?? [];
      final completedLogs = habitLogs.where((l) => l.isCompleted).toList();
      if (completedLogs.length < 7) continue;

      int morningCount = 0;   // 05:00 - 11:59
      int afternoonCount = 0; // 12:00 - 16:59
      int eveningCount = 0;   // 17:00 - 04:59

      for (final log in completedLogs) {
        final h = log.loggedAt.hour;
        if (h >= 5 && h < 12) {
          morningCount++;
        } else if (h >= 12 && h < 17) {
          afternoonCount++;
        } else {
          eveningCount++;
        }
      }

      final total = completedLogs.length;
      final mRate = morningCount / total;
      final aRate = afternoonCount / total;
      final eRate = eveningCount / total;

      String? bestWindow;
      double bestRate = 0.0;
      String? worstWindow;
      double worstRate = 1.0;

      final rates = {
        'Morning (5am-12pm)': mRate,
        'Afternoon (12pm-5pm)': aRate,
        'Evening/Night': eRate,
      };

      for (final entry in rates.entries) {
        if (entry.value > bestRate) {
          bestRate = entry.value;
          bestWindow = entry.key;
        }
        if (entry.value < worstRate) {
          worstRate = entry.value;
          worstWindow = entry.key;
        }
      }

      if (bestRate >= 0.65 && worstRate <= 0.15 && bestWindow != null && worstWindow != null) {
        final content = LocalCoachPrompts.formatOptimalTiming(
          habitTitle: habit.title,
          bestWindowName: bestWindow,
          bestRate: bestRate,
          worstWindowName: worstWindow,
          worstRate: worstRate,
        );

        insights.add(BehavioralInsight(
          id: _uuid.v4(),
          habitId: habit.id,
          type: InsightType.optimalTiming,
          title: content['title']!,
          message: content['message']!,
          actionableStep: content['actionable_step']!,
          psychologyPrinciple: content['psychology_principle']!,
          severity: InsightSeverity.suggestion,
          generatedAt: now,
        ));
      }
    }

    // -------------------------------------------------------------
    // 5. Cognitive Overload Detection (Willpower Budgeting)
    // -------------------------------------------------------------
    if (habits.length >= 6) {
      double total30DayRateSum = 0;
      for (final habit in habits) {
        total30DayRateSum += statsMap[habit.id]?.completionRate30Days ?? 0.0;
      }
      final avgRate = total30DayRateSum / habits.length;

      if (avgRate < 0.50) {
        final content = LocalCoachPrompts.formatCognitiveOverload(
          totalHabits: habits.length,
          overallRate: avgRate,
        );

        insights.add(BehavioralInsight(
          id: _uuid.v4(),
          type: InsightType.overloadWarning,
          title: content['title']!,
          message: content['message']!,
          actionableStep: content['actionable_step']!,
          psychologyPrinciple: content['psychology_principle']!,
          severity: InsightSeverity.warning,
          generatedAt: now,
        ));
      }
    }

    // Deduplicate insights with identical type and habitId
    final Map<String, BehavioralInsight> uniqueMap = {};
    for (final insight in insights) {
      final key = '${insight.type}_${insight.habitId}';
      uniqueMap[key] = insight;
    }

    final uniqueList = uniqueMap.values.toList();

    // Priority sorting: urgent > warning > suggestion > celebration
    uniqueList.sort((a, b) => a.severity.index.compareTo(b.severity.index));

    return uniqueList;
  }
}
