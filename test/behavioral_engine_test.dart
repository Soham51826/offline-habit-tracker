import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/models/habit.dart';
import 'package:habit_tracker/data/models/habit_log.dart';
import 'package:habit_tracker/data/models/behavioral_insight.dart';
import 'package:habit_tracker/data/models/habit_stats.dart';
import 'package:habit_tracker/domain/engine/behavioral_engine.dart';
import 'package:intl/intl.dart';

void main() {
  final dateFormat = DateFormat('yyyy-MM-dd');
  final testDate = DateTime(2026, 9, 5, 17, 0); // Saturday 5:00 PM

  group('BehavioralInsightsEngine Tests', () {
    test('Detects Streak-at-Risk when active streak >= 3 and not logged by afternoon', () {
      final habit = Habit(
        id: 'habit-1',
        title: 'Meditation',
        category: 'Mindfulness & Mental',
        colorValue: 0xFFF59E0B,
        iconName: 'self_improvement',
        createdAt: testDate.subtract(const Duration(days: 10)),
        updatedAt: testDate,
      );

      final stats = HabitStats(
        habitId: habit.id,
        currentStreak: 5,
        longestStreak: 5,
        totalCompletions: 5,
        completionRate7Days: 0.8,
        completionRate30Days: 0.8,
        allTimeCompletionRate: 0.8,
        consistencyScore: 80,
      );

      // Today is not logged in completedLogs
      final logs = [
        HabitLog(
          id: 'l1',
          habitId: habit.id,
          date: dateFormat.format(testDate.subtract(const Duration(days: 1))),
          status: 'completed',
          loggedAt: testDate.subtract(const Duration(days: 1)),
        ),
      ];

      final insights = BehavioralInsightsEngine.analyzeAll(
        habits: [habit],
        logs: logs,
        statsMap: {habit.id: stats},
        referenceTime: testDate,
      );

      expect(insights.any((i) => i.type == InsightType.streakRisk), isTrue);
      final riskInsight = insights.firstWhere((i) => i.type == InsightType.streakRisk);
      expect(riskInsight.severity, equals(InsightSeverity.urgent));
      expect(riskInsight.title, contains('Streak Defense Alert'));
      expect(riskInsight.psychologyPrinciple, contains('Kahneman'));
    });

    test('Detects Habit Stacking Opportunity between anchor and struggling habits', () {
      final anchorHabit = Habit(
        id: 'anchor-1',
        title: 'Morning Espresso',
        category: 'Health & Wellness',
        colorValue: 0xFF10B981,
        iconName: 'coffee',
        createdAt: testDate.subtract(const Duration(days: 30)),
        updatedAt: testDate,
      );

      final needyHabit = Habit(
        id: 'needy-1',
        title: '5-Minute Journaling',
        category: 'Mindfulness & Mental',
        colorValue: 0xFF6366F1,
        iconName: 'edit_note',
        createdAt: testDate.subtract(const Duration(days: 20)),
        updatedAt: testDate,
      );

      final anchorStats = HabitStats(
        habitId: anchorHabit.id,
        currentStreak: 12,
        longestStreak: 15,
        totalCompletions: 25,
        completionRate7Days: 0.9,
        completionRate30Days: 0.88, // Anchor consistency >= 75%
        allTimeCompletionRate: 0.88,
        consistencyScore: 88,
      );

      final needyStats = HabitStats(
        habitId: needyHabit.id,
        currentStreak: 1,
        longestStreak: 2,
        totalCompletions: 4,
        completionRate7Days: 0.25,
        completionRate30Days: 0.35, // Struggling < 60%
        allTimeCompletionRate: 0.35,
        consistencyScore: 35,
      );

      final insights = BehavioralInsightsEngine.analyzeAll(
        habits: [anchorHabit, needyHabit],
        logs: [],
        statsMap: {
          anchorHabit.id: anchorStats,
          needyHabit.id: needyStats,
        },
        referenceTime: testDate,
      );

      expect(insights.any((i) => i.type == InsightType.habitStacking), isTrue);
      final stacking = insights.firstWhere((i) => i.type == InsightType.habitStacking);
      expect(stacking.message, contains('Morning Espresso'));
      expect(stacking.message, contains('5-Minute Journaling'));
      expect(stacking.psychologyPrinciple, contains('James Clear'));
    });

    test('Detects Weekend Slump when weekend completion drops significantly', () {
      final habit = Habit(
        id: 'read-1',
        title: 'Deep Reading',
        category: 'Learning & Reading',
        colorValue: 0xFF06B6D4,
        iconName: 'menu_book',
        frequencyType: 'daily',
        createdAt: testDate.subtract(const Duration(days: 25)),
        updatedAt: testDate,
      );

      final List<HabitLog> logs = [];

      // 21 days: complete Monday through Friday, skip Saturday & Sunday
      for (int i = 0; i < 21; i++) {
        final d = testDate.subtract(Duration(days: i));
        final isWeekend = d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
        if (!isWeekend) {
          logs.add(HabitLog(
            id: 'log-$i',
            habitId: habit.id,
            date: dateFormat.format(d),
            status: 'completed',
            loggedAt: d,
          ));
        }
      }

      final stats = HabitStats(
        habitId: habit.id,
        currentStreak: 0,
        longestStreak: 5,
        totalCompletions: 15,
        completionRate7Days: 0.7,
        completionRate30Days: 0.7,
        allTimeCompletionRate: 0.7,
        consistencyScore: 70,
      );

      final insights = BehavioralInsightsEngine.analyzeAll(
        habits: [habit],
        logs: logs,
        statsMap: {habit.id: stats},
        referenceTime: testDate,
      );

      expect(insights.any((i) => i.type == InsightType.weekendSlump), isTrue);
      final slump = insights.firstWhere((i) => i.type == InsightType.weekendSlump);
      expect(slump.title, contains('Weekend Slump Detected'));
      expect(slump.psychologyPrinciple, contains('BJ Fogg'));
    });

    test('Detects Circadian / Optimal Timing alignment', () {
      final habit = Habit(
        id: 'workout-1',
        title: 'HIIT Workout',
        category: 'Fitness & Movement',
        colorValue: 0xFFF43F5E,
        iconName: 'fitness_center',
        createdAt: testDate.subtract(const Duration(days: 20)),
        updatedAt: testDate,
      );

      final List<HabitLog> logs = [];
      // 8 logs in the morning at 7:30 AM
      for (int i = 1; i <= 8; i++) {
        final d = testDate.subtract(Duration(days: i));
        logs.add(HabitLog(
          id: 'w-$i',
          habitId: habit.id,
          date: dateFormat.format(d),
          status: 'completed',
          loggedAt: DateTime(d.year, d.month, d.day, 7, 30),
        ));
      }

      final stats = HabitStats(
        habitId: habit.id,
        currentStreak: 4,
        longestStreak: 6,
        totalCompletions: 8,
        completionRate7Days: 0.8,
        completionRate30Days: 0.8,
        allTimeCompletionRate: 0.8,
        consistencyScore: 80,
      );

      final insights = BehavioralInsightsEngine.analyzeAll(
        habits: [habit],
        logs: logs,
        statsMap: {habit.id: stats},
        referenceTime: testDate,
      );

      expect(insights.any((i) => i.type == InsightType.optimalTiming), isTrue);
      final timing = insights.firstWhere((i) => i.type == InsightType.optimalTiming);
      expect(timing.title, contains('Circadian Friction Alert'));
      expect(timing.message, contains('Morning'));
    });

    test('Detects Momentum Milestone Celebrations at key thresholds (e.g. 21 days)', () {
      final habit = Habit(
        id: 'run-1',
        title: 'Morning 5K',
        category: 'Fitness & Movement',
        colorValue: 0xFF10B981,
        iconName: 'directions_walk',
        createdAt: testDate.subtract(const Duration(days: 25)),
        updatedAt: testDate,
      );

      final todayStr = dateFormat.format(testDate);
      final logs = [
        HabitLog(
          id: 'today-log',
          habitId: habit.id,
          date: todayStr,
          status: 'completed',
          loggedAt: testDate,
        ),
      ];

      final stats = HabitStats(
        habitId: habit.id,
        currentStreak: 21,
        longestStreak: 21,
        totalCompletions: 21,
        completionRate7Days: 1.0,
        completionRate30Days: 1.0,
        allTimeCompletionRate: 1.0,
        consistencyScore: 100,
      );

      final insights = BehavioralInsightsEngine.analyzeAll(
        habits: [habit],
        logs: logs,
        statsMap: {habit.id: stats},
        referenceTime: testDate,
      );

      expect(insights.any((i) => i.type == InsightType.momentumMilestone), isTrue);
      final milestone = insights.firstWhere((i) => i.type == InsightType.momentumMilestone);
      expect(milestone.severity, equals(InsightSeverity.celebration));
      expect(milestone.title, contains('21-Day Streak Milestone'));
      expect(milestone.psychologyPrinciple, contains('Automaticity'));
    });
  });

  group('Model Serialization Tests', () {
    test('Habit toMap and fromMap roundtrip preserves data', () {
      final original = Habit(
        id: 'test-123',
        title: 'Hydration',
        description: 'Drink water',
        category: 'Health & Wellness',
        colorValue: 0xFF10B981,
        iconName: 'water_drop',
        frequencyType: 'custom',
        customDays: '1,3,5',
        targetCount: 8,
        unit: 'glasses',
        reminderTime: '09:00',
        anchorHabitId: 'anchor-456',
        isArchived: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final map = original.toMap();
      final reconstructed = Habit.fromMap(map);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.targetCount, equals(8));
      expect(reconstructed.unit, equals('glasses'));
      expect(reconstructed.isNumeric, isTrue);
      expect(reconstructed.isScheduledForWeekday(1), isTrue);
      expect(reconstructed.isScheduledForWeekday(2), isFalse);
    });

    test('HabitLog toMap and fromMap roundtrip preserves data', () {
      final log = HabitLog(
        id: 'log-999',
        habitId: 'habit-123',
        date: '2026-09-05',
        status: 'completed',
        value: 5,
        notes: 'Felt great today',
        loggedAt: DateTime(2026, 9, 5, 14, 30),
        moodScore: 5,
      );

      final map = log.toMap();
      final reconstructed = HabitLog.fromMap(map);

      expect(reconstructed.id, equals(log.id));
      expect(reconstructed.habitId, equals(log.habitId));
      expect(reconstructed.isCompleted, isTrue);
      expect(reconstructed.value, equals(5));
      expect(reconstructed.notes, equals('Felt great today'));
      expect(reconstructed.moodScore, equals(5));
    });

    test('Habit with Google Maps geofence toMap and fromMap roundtrip preserves location data', () {
      final geoHabit = Habit(
        id: 'geo-habit-1',
        title: 'Gym Workout',
        category: 'Fitness & Movement',
        colorValue: 0xFFF43F5E,
        iconName: 'fitness_center',
        latitude: 19.0760,
        longitude: 72.8777,
        locationName: 'Campus Fitness Center',
        geofenceRadius: 200.0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final map = geoHabit.toMap();
      final reconstructed = Habit.fromMap(map);

      expect(reconstructed.hasLocation, isTrue);
      expect(reconstructed.latitude, equals(19.0760));
      expect(reconstructed.longitude, equals(72.8777));
      expect(reconstructed.locationName, equals('Campus Fitness Center'));
      expect(reconstructed.geofenceRadius, equals(200.0));
    });
  });
}
