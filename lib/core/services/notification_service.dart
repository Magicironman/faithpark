import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const _parkingChannelId = 'parking_alerts_v3';
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) {
      return;
    }

    tzdata.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Los_Angeles'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
    await _plugin.initialize(settings);

    final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlatform?.requestNotificationsPermission();
    await androidPlatform?.requestExactAlarmsPermission();
    await androidPlatform?.createNotificationChannel(
      const AndroidNotificationChannel(
        _parkingChannelId,
        'Parking Alerts',
        description: 'Parking reminders, due-time alerts, and alarms',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    await _plugin.show(id, title, body, _details);
  }

  Future<void> scheduleParkingAlert({
    required String sessionId,
    required DateTime parkingExpiresAt,
    required int leadMinutes,
    required String label,
  }) async {
    if (kIsWeb) {
      return;
    }

    await cancelParkingAlert(sessionId: sessionId);

    final scheduledAt =
        parkingExpiresAt.subtract(Duration(minutes: leadMinutes));
    if (!scheduledAt.isAfter(DateTime.now())) {
      return;
    }

    final tzTime = tz.TZDateTime.from(scheduledAt, tz.local);
    final body = label.isEmpty
        ? 'Your parking session is ending in $leadMinutes minutes.'
        : '$label will end in $leadMinutes minutes.';

    await _plugin.zonedSchedule(
      _notificationIdsFor(sessionId).first,
      'Parking alert',
      body,
      tzTime,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleParkingAlerts({
    required String sessionId,
    required DateTime parkingExpiresAt,
    required List<int> leadMinutesList,
    required String label,
  }) async {
    if (kIsWeb) {
      return;
    }

    await cancelParkingAlert(sessionId: sessionId);

    final ids = _notificationIdsFor(sessionId);
    final sortedMinutes = leadMinutesList.toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    for (var i = 0; i < sortedMinutes.length && i < ids.length; i++) {
      final leadMinutes = sortedMinutes[i];
      final scheduledAt =
          parkingExpiresAt.subtract(Duration(minutes: leadMinutes));
      if (!scheduledAt.isAfter(DateTime.now())) {
        continue;
      }

      final tzTime = tz.TZDateTime.from(scheduledAt, tz.local);
      final body = label.isEmpty
          ? 'Your parking session is ending in $leadMinutes minutes.'
          : '$label will end in $leadMinutes minutes.';

      await _plugin.zonedSchedule(
        ids[i],
        'Parking alert',
        body,
        tzTime,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    final dueAt = tz.TZDateTime.from(parkingExpiresAt, tz.local);
    if (dueAt.isAfter(tz.TZDateTime.now(tz.local))) {
      final dueBody = label.isEmpty
          ? 'Your parking time is due now.'
          : '$label is due now.';
      await _plugin.zonedSchedule(
        ids.last,
        'Parking time due',
        dueBody,
        dueAt,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelParkingAlert({required String sessionId}) async {
    if (kIsWeb) {
      return;
    }
    for (final id in _notificationIdsFor(sessionId)) {
      await _plugin.cancel(id);
    }
  }

  List<int> _notificationIdsFor(String sessionId) {
    final hash = sessionId.hashCode.abs() % 1000000;
    final base = 1000000 + (hash * 10);
    return [base + 1, base + 2, base + 3];
  }

  NotificationDetails get _details {
    const android = AndroidNotificationDetails(
      _parkingChannelId,
      'Parking Alerts',
      channelDescription: 'Parking reminders, due-time alerts, and alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      ticker: 'Parking alert',
    );
    const darwin = DarwinNotificationDetails();
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }
}
