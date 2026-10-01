import 'dart:async';
import 'package:flutter/services.dart';

class ReminderService {
  static const MethodChannel _channel = MethodChannel('com.raen.nutmate/reminder');
  static final StreamController<int> _notificationClickController = StreamController<int>.broadcast();

  static Stream<int> get onNotificationClicked => _notificationClickController.stream;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationClicked') {
        final logId = call.arguments['logId'] as int?;
        if (logId != null && logId != -1) {
          _notificationClickController.add(logId);
        }
      }
    });
  }

  static Future<bool> schedulePostNutReminder({
    required int logId,
    required bool isStealth,
    int delayMinutes = 120,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('schedulePostNutReminder', {
        'logId': logId,
        'isStealth': isStealth,
        'delayMinutes': delayMinutes,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelPostNutReminder(int logId) async {
    try {
      final res = await _channel.invokeMethod<bool>('cancelPostNutReminder', {
        'logId': logId,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<int?> getPendingPostNutLogId() async {
    try {
      final id = await _channel.invokeMethod<int>('getPendingPostNutLogId');
      if (id != null && id != -1) {
        return id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
