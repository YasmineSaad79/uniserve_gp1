import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static final FlutterLocalNotificationsPlugin fln =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // الاسم الظاهر للمستخدم
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableLights: true,
    enableVibration: true,
    ticker: 'ticker',
    icon: '@mipmap/ic_launcher',
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _androidDetails);

  /// تهيئة الإشعارات المحلية مرة واحدة
  static Future<void> initLocal() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await fln.initialize(initSettings,
        onDidReceiveNotificationResponse: (resp) {
      // هنا ممكن تضيفي نافيجيشن أو معالجة الضغط على الإشعار
    });

    final android = fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);

    // إذن الإشعارات لأندرويد 13+
    try {
      await android?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// عرض إشعار "عائم" من النظام
  static Future<void> showSimple(String title, String body,
      {String? payload}) async {
    await fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _details,
      payload: payload,
    );
  }
}
