import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

 static Future<void> init() async {
    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Makassar'));
    debugPrint("✅ Time Zone set to: ${tz.local.name}");

    // Android settings - GANTI KE launcher_icon
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/launcher_icon'); // ← PERBAIKAN 1

    const DarwinInitializationSettings iosInit =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        // Handle notification tap here
      },
    );

    debugPrint("✅ Notification service initialized");
  }

  static Future<void> showExceedNotification({
    required String unitName,
    required String parameter,
    required double value,
    required double limit,
  }) async {
    try {
      await _notifications.show(
        parameter.hashCode,
        '⚠️ CEMS Alert: $unitName',
        '$parameter: $value (limit $limit)',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cems_alert',
            'CEMS Alert',
            channelDescription: 'Notifikasi saat parameter CEMS melebihi batas',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/launcher_icon',
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to show CEMS notification: $e');
    }
  }

  static Future<void> requestNotificationPermission() async {
  final plugin = _notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (plugin == null) return;

  final bool? granted = await plugin.requestNotificationsPermission();

  if (granted == true) {
    debugPrint('Notification permission granted');
  } else {
    debugPrint('Notification permission denied');
  }
}
  // Hitung waktu notifikasi berikutnya
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Jika waktu sudah lewat hari ini, jadwalkan besok
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    debugPrint('📅 Next notification scheduled at: $scheduled');
    return scheduled;
  }

  // Schedule daily reminder
  static Future<void> scheduleDailyReminder() async {
    try {
      await _notifications.zonedSchedule(
        88, // notification id
        'MSW ePlant Monitor', // ← PERBAIKAN 2: Judul lebih jelas
        'Jangan lupa cek kondisi plant hari ini! 🔥⚡',
        _nextInstanceOfTime(8, 0), // 8:00 AM - PERBAIKAN 3: Waktu jelas
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_v2', // ← PERBAIKAN 4: Ganti channel ID
            'Daily Plant Reminder',
            channelDescription: 'Reminder harian untuk cek kondisi plant',
            importance: Importance.max, // ← PERBAIKAN 5: Max importance
            priority: Priority.high, // ← PERBAIKAN 6: High priority
            icon: '@mipmap/launcher_icon', // ← PERBAIKAN 7
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(
              'Jangan lupa cek kondisi plant hari ini! 🔥⚡',
            ),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ← PERBAIKAN 8
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ Daily reminder scheduled successfully at 8:00 AM');
    } catch (e) {
      debugPrint('❌ Failed to schedule daily reminder: $e');
    }
  }

static Future<void> scheduleTestNotification() async {
  final scheduledTime =
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 3));

  try {
    await _notifications.zonedSchedule(
      1001,
        'MSW Power Plant Monitor',
        'Jangan lupa cek kondisi plant hari ini.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel_v4',
          'Test Channel',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  } on PlatformException catch (e) {
    if (e.code == 'exact_alarms_not_permitted') {
      // fallback
      await _notifications.zonedSchedule(
        1002,
        'MSW Power Plant Monitor',
        'Jangan lupa cek kondisi plant hari ini.',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel_v4',
            'Test Channel',
            importance: Importance.max,
            priority: Priority.max,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}



}

