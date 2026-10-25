
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class ForegroundNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'shield_alerts',
    'SHIELD Alerts',
    description: 'Safety alerts and notifications from SHIELD',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings : settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      if (notification == null) {
        debugPrint('SHIELD: Foreground message has no notification payload');
        return;
      }

     await _notifications.show(
  id: message.messageId.hashCode,
  title: notification.title ?? 'SHIELD Alert',
  body: notification.body ?? 'You have a new notification.',
  notificationDetails: NotificationDetails(
    android: AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  ),
);

      debugPrint('SHIELD: Foreground notification displayed');
    });
  }
}
