import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TimerNotificationService {
  static final TimerNotificationService instance = TimerNotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  TimerNotificationService._init();

  Future<void> init() async {
    if (_isInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    try {
      await _notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
    } catch (_) {}
  }

  Future<void> enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  Future<void> disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'nutmate_timer_channel',
      'Session & Cleanup Timers',
      channelDescription: 'Notifications for live session and cleanup timers in NutMate',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    try {
      await _notificationsPlugin.show(id, title, body, notificationDetails);
    } catch (_) {}
  }
}
