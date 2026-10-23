import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';
import '../data/datasources/database_helper.dart';
import 'notification_service.dart';

const String habitPeriodicTaskKey = 'com.offlinetracker.habits.periodic_check';
const String habitStreakDefenseTaskKey = 'com.offlinetracker.habits.midnight_streak_defense';

/// Top-level background execution dispatcher for Android WorkManager.
///
/// Runs in a separate background isolate when Android OS triggers scheduled tasks,
/// even when the main app process has been suspended or killed.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

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

      if (taskName == habitStreakDefenseTaskKey) {
        // Late-night streak defense intervention
        if (pendingHabits.isNotEmpty && now.hour >= 20) {
          final count = pendingHabits.length;
          final title = '🛡️ Final Streak Defense Alert';
          final body = count == 1
              ? 'Only 1 habit remaining before midnight! Log "${pendingHabits.first.title}" now.'
              : '$count habits remain incomplete today. Check in before midnight to protect your streaks!';

          await NotificationService.instance.showNotification(
            id: 1002,
            title: title,
            body: body,
          );
        }
        return Future.value(true);
      }

      // Default periodic check
      if (pendingHabits.isNotEmpty) {
        final count = pendingHabits.length;
        final firstTitle = pendingHabits.first.title;

        String title = '🔥 Habit Check-In Reminder';
        String body = count == 1
            ? 'Don\'t forget to complete "$firstTitle" today!'
            : 'You have $count pending habits for today, including "$firstTitle".';

        // Afternoon/evening streak defense escalation
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
      debugPrint('WorkManager background execution error: $e');
      return Future.value(false);
    }
  });
}

/// Service orchestrating background scheduling and periodic streak checks.
class BackgroundWorkerService {
  static final BackgroundWorkerService instance = BackgroundWorkerService._internal();

  BackgroundWorkerService._internal();

  /// Initializes WorkManager across Android and iOS platforms.
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );
    } catch (e) {
      debugPrint('Workmanager initialization failed: $e');
    }
  }

  /// Schedules periodic background checks (frequency: 3 hours, initialDelay: 15 mins).
  ///
  /// Configured without network constraints so tasks execute purely offline on-device.
  Future<void> schedulePeriodicHabitCheck() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      await Workmanager().registerPeriodicTask(
        habitPeriodicTaskKey,
        habitPeriodicTaskKey,
        frequency: const Duration(hours: 3),
        initialDelay: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // Register late evening streak audit check
      await Workmanager().registerPeriodicTask(
        habitStreakDefenseTaskKey,
        habitStreakDefenseTaskKey,
        frequency: const Duration(hours: 6),
        initialDelay: const Duration(hours: 2),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      debugPrint('Periodic WorkManager habit tasks registered successfully.');
    } catch (e) {
      debugPrint('Failed to register WorkManager task: $e');
    }
  }

  /// Cancels all background tasks.
  Future<void> cancelAllTasks() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel WorkManager tasks: $e');
    }
  }
}
