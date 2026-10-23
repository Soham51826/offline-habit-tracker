import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import 'database_helper.dart';

class SampleDataSeeder {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static const _uuid = Uuid();

  /// Seeds 21 days of realistic habit logs across 5 varied habits to showcase
  /// the Local Behavioral Insights Engine, streaks, charts, and heatmap.
  static Future<void> seedRealisticDemoData({DatabaseHelper? dbHelper}) async {
    final db = dbHelper ?? DatabaseHelper.instance;

    // Clear existing data first
    await db.clearAllData();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Habit: Anchor Habit - "Morning Espresso & Meditation" (Mindfulness, 95% completion)
    final h1 = Habit(
      id: 'demo-anchor-espresso',
      title: 'Morning Espresso & Meditation',
      description: 'Mindful breathing after morning coffee',
      category: 'Mindfulness & Mental',
      colorValue: 0xFFF59E0B, // Amber
      iconName: 'self_improvement',
      frequencyType: 'daily',
      targetCount: 1,
      unit: 'times',
      reminderTime: '07:30',
      createdAt: today.subtract(const Duration(days: 25)),
      updatedAt: today,
    );

    // 2. Habit: Struggling Habit - "5-Minute Evening Journaling" (Learning, 35% completion, unanchored)
    final h2 = Habit(
      id: 'demo-struggling-journal',
      title: '5-Minute Evening Journaling',
      description: 'Reflect on key wins and lessons of the day',
      category: 'Learning & Reading',
      colorValue: 0xFF06B6D4, // Cyan
      iconName: 'menu_book',
      frequencyType: 'daily',
      targetCount: 1,
      unit: 'times',
      reminderTime: '21:30',
      createdAt: today.subtract(const Duration(days: 22)),
      updatedAt: today,
    );

    // 3. Habit: Weekend Slump Habit - "Daily 30-min Reading" (Productivity, Mon-Fri 90%, Sat-Sun 15%)
    final h3 = Habit(
      id: 'demo-weekend-slump-read',
      title: 'Daily 30-min Reading',
      description: 'Read non-fiction or psychology book',
      category: 'Productivity & Focus',
      colorValue: 0xFF6366F1, // Indigo
      iconName: 'menu_book',
      frequencyType: 'daily',
      targetCount: 30,
      unit: 'minutes',
      reminderTime: '20:00',
      latitude: 19.0790,
      longitude: 72.8800,
      locationName: 'University Central Library',
      geofenceRadius: 150.0,
      createdAt: today.subtract(const Duration(days: 24)),
      updatedAt: today,
    );

    // 4. Habit: Circadian Friction Habit - "HIIT Workout" (Fitness, mostly done in morning 07:00)
    final h4 = Habit(
      id: 'demo-friction-workout',
      title: 'Bodyweight HIIT Workout',
      description: 'Pushups, pullups, and core circuits',
      category: 'Fitness & Movement',
      colorValue: 0xFFF43F5E, // Rose
      iconName: 'fitness_center',
      frequencyType: 'daily',
      targetCount: 1,
      unit: 'times',
      reminderTime: '08:00',
      latitude: 19.0760,
      longitude: 72.8777,
      locationName: 'Campus Fitness Center',
      geofenceRadius: 200.0,
      createdAt: today.subtract(const Duration(days: 21)),
      updatedAt: today,
    );

    // 5. Habit: Numeric Counter - "Hydrate 8 Glasses" (Health, targetCount = 8)
    final h5 = Habit(
      id: 'demo-counter-water',
      title: 'Drink 8 Glasses of Water',
      description: 'Stay hydrated throughout the day',
      category: 'Health & Wellness',
      colorValue: 0xFF10B981, // Emerald
      iconName: 'water_drop',
      frequencyType: 'daily',
      targetCount: 8,
      unit: 'glasses',
      reminderTime: '10:00',
      createdAt: today.subtract(const Duration(days: 21)),
      updatedAt: today,
    );

    await db.insertHabit(h1);
    await db.insertHabit(h2);
    await db.insertHabit(h3);
    await db.insertHabit(h4);
    await db.insertHabit(h5);

    // Generate 21 days of historical logs
    for (int dayOffset = 21; dayOffset >= 0; dayOffset--) {
      final date = today.subtract(Duration(days: dayOffset));
      final dateStr = _dateFormat.format(date);
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final isToday = dayOffset == 0;

      // 1. Anchor Espresso: completes 20 out of 21 days
      if (dayOffset != 14) {
        final loggedTime = DateTime(date.year, date.month, date.day, 7, 45);
        await db.insertOrUpdateLog(HabitLog(
          id: _uuid.v4(),
          habitId: h1.id,
          date: dateStr,
          status: 'completed',
          value: 1,
          notes: 'Great calm start to the morning',
          loggedAt: loggedTime,
          moodScore: 5,
        ));
      }

      // 2. Struggling Journal: only completed on a few scattered days (~35%)
      if (dayOffset == 20 || dayOffset == 18 || dayOffset == 15 || dayOffset == 10 || dayOffset == 7 || dayOffset == 4) {
        final loggedTime = DateTime(date.year, date.month, date.day, 22, 10);
        await db.insertOrUpdateLog(HabitLog(
          id: _uuid.v4(),
          habitId: h2.id,
          date: dateStr,
          status: 'completed',
          value: 1,
          notes: 'Quick notes before bed',
          loggedAt: loggedTime,
          moodScore: 3,
        ));
      }

      // 3. Weekend Slump Reading: completes Mon-Fri (85%), skips nearly all Sat/Sun
      if (!isWeekend) {
        // Mon-Fri: completes 90% of the time
        if (dayOffset != 11 && dayOffset != 3) {
          final loggedTime = DateTime(date.year, date.month, date.day, 20, 30);
          await db.insertOrUpdateLog(HabitLog(
            id: _uuid.v4(),
            habitId: h3.id,
            date: dateStr,
            status: 'completed',
            value: 30,
            notes: 'Read chapter on Atomic Habits',
            loggedAt: loggedTime,
            moodScore: 4,
          ));
        }
      } else {
        // Weekends: only completed once in 3 weekends
        if (dayOffset == 1) {
          final loggedTime = DateTime(date.year, date.month, date.day, 16, 0);
          await db.insertOrUpdateLog(HabitLog(
            id: _uuid.v4(),
            habitId: h3.id,
            date: dateStr,
            status: 'completed',
            value: 15,
            notes: 'Short read',
            loggedAt: loggedTime,
            moodScore: 2,
          ));
        }
      }

      // 4. Friction Workout: Completed in the morning 8:00 AM 14 times
      if (dayOffset % 3 != 0) {
        final loggedTime = DateTime(date.year, date.month, date.day, 8, 15);
        await db.insertOrUpdateLog(HabitLog(
          id: _uuid.v4(),
          habitId: h4.id,
          date: dateStr,
          status: 'completed',
          value: 1,
          notes: 'High energy workout',
          loggedAt: loggedTime,
          moodScore: 5,
        ));
      }

      // 5. Water: Completed regularly with 6-8 glasses
      if (!isToday || now.hour >= 12) {
        final val = isToday ? 5 : 8;
        final loggedTime = DateTime(date.year, date.month, date.day, 18, 0);
        await db.insertOrUpdateLog(HabitLog(
          id: _uuid.v4(),
          habitId: h5.id,
          date: dateStr,
          status: val >= 8 ? 'completed' : 'in_progress',
          value: val,
          notes: 'Hydrated properly',
          loggedAt: loggedTime,
          moodScore: 4,
        ));
      }
    }
  }
}
