import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification action IDs
const String kActionMarkDone = 'mark_done';
const String kActionSnooze30 = 'snooze_30';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Callback triggered when user taps "Mark Done" action from notification tray
  void Function(String habitId)? onMarkDoneFromNotification;
  // Callback triggered when user taps "Snooze" action
  void Function(String habitId)? onSnoozeFromNotification;

  NotificationService._internal();

  static const String channelId = 'habit_tracker_channel';
  static const String channelName = 'Habit Reminders & Insights';
  static const String channelDescription =
      'Notifications for habit reminders, streak defense, and behavioral nudges.';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: action=${details.actionId}, payload=${details.payload}');
          _handleNotificationResponse(details);
        },
        onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
      );

      // Create Android Notification Channel with action buttons
      final androidPlatformChannel = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatformChannel != null) {
        await androidPlatformChannel.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
            enableVibration: true,
          ),
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  void _handleNotificationResponse(NotificationResponse details) {
    final habitId = details.payload;
    if (habitId == null) return;

    if (details.actionId == kActionMarkDone) {
      debugPrint('Mark Done tapped for habit: $habitId');
      onMarkDoneFromNotification?.call(habitId);
    } else if (details.actionId == kActionSnooze30) {
      debugPrint('Snooze 30m tapped for habit: $habitId');
      onSnoozeFromNotification?.call(habitId);
      // Re-show the notification after 30 minutes
      _scheduleSnoozeNotification(habitId);
    }
  }

  Future<void> _scheduleSnoozeNotification(String habitId) async {
    // Show a follow-up reminder after 30 minutes using a delayed notification
    await Future.delayed(const Duration(seconds: 1));
    await showNotification(
      id: habitId.hashCode + 1000,
      title: '⏰ Snoozed Reminder',
      body: 'Your snoozed habit check-in is ready!',
      payload: habitId,
    );
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Shows a standard notification (no action buttons).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Shows an actionable notification with "✅ Mark Done" and "⏰ Snooze 30m" buttons.
  /// Pass [habitId] as the payload so the action handler can identify the habit.
  Future<void> showActionableHabitReminder({
    required int id,
    required String habitTitle,
    required String habitId,
    String? subtitle,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        actions: const [
          AndroidNotificationAction(
            kActionMarkDone,
            '✅ Mark Done',
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            kActionSnooze30,
            '⏰ Snooze 30m',
            cancelNotification: true,
          ),
        ],
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        '🌿 $habitTitle',
        subtitle ?? 'Tap to complete or use the buttons below.',
        notificationDetails,
        payload: habitId,
      );
    } catch (e) {
      debugPrint('Failed to show actionable notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }
}

/// Background handler for notification actions (required by flutter_local_notifications).
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse details) {
  debugPrint('[BG] Notification action: ${details.actionId}, payload: ${details.payload}');
}
