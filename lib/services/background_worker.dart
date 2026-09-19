import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';
import '../data/datasources/database_helper.dart';
import 'notification_service.dart';

const String habitPeriodicTaskKey = 'com.offlinetracker.habits.periodic_check';
const String habitStreakDefenseTaskKey = 'com.offlinetracker.habits.streak_defense';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);

      final db = DatabaseHelper.instance;
      final habits = await db.getAllHabits();
      final logs = await db.getLogsForDate(dateStr);
      final completedHabitIds = logs.where((l) => l.isCompleted).map((l) => l.habitId).toSet();

      // Find pending habits scheduled for today
      final pendingHabits = habits.where((h) {
        return h.isScheduledForWeekday(now.weekday) && !completedHabitIds.contains(h.id);
      }).toList();

      if (pendingHabits.isNotEmpty) {
        final count = pendingHabits.length;
        final firstTitle = pendingHabits.first.title;

        String title = '🔥 Habit Check-In Reminder';
        String body = count == 1
            ? 'Don\'t forget to complete "$firstTitle" today!'
            : 'You have $count pending habits for today, including "$firstTitle".';

        // If it's evening, emphasize streak defense
        if (now.hour >= 18) {
          title = '🛡️ Streak Defense Alert';
          body = 'Keep your momentum alive! $count habits remain unfinished today.';
        }

        await NotificationService.instance.showNotification(
          id: 1001,
          title: title,
          body: body,
        );
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('Background worker error: $e');
      return Future.value(false);
    }
  });
}

class BackgroundWorkerService {
  static final BackgroundWorkerService instance = BackgroundWorkerService._internal();

  BackgroundWorkerService._internal();

  Future<void> initialize() async {
    // WorkManager is primarily designed for Android & iOS
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    } catch (e) {
      debugPrint('Workmanager init failed: $e');
    }
  }

  Future<void> schedulePeriodicHabitCheck() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      // WorkManager periodic minimum interval on Android is 15 minutes
      await Workmanager().registerPeriodicTask(
        habitPeriodicTaskKey,
        habitPeriodicTaskKey,
        frequency: const Duration(hours: 3),
        initialDelay: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      debugPrint('Periodic WorkManager habit task registered successfully.');
    } catch (e) {
      debugPrint('Failed to register WorkManager task: $e');
    }
  }

  Future<void> cancelAllTasks() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel WorkManager tasks: $e');
    }
  }
}
