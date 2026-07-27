import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background FCM message: ${message.messageId}');
  final notification = message.notification;
  if (notification != null) {
    NotificationService().showChatPushNotification(
      senderName: notification.title ?? 'New Message',
      messageText: notification.body ?? '',
    );
  }
}

/// Central Push Notification Service backed by Flutter Local Notifications & FCM
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _isInitialized = false;

  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
      );

      // Request system push notification permissions for closed app state
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized && userId != null && userId.isNotEmpty) {
        final token = await _fcm.getToken();
        if (token != null) {
          debugPrint('FCM Token registered: $token');
        }
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          showChatPushNotification(
            senderName: notification.title ?? 'New Message',
            messageText: notification.body ?? '',
          );
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Note: Error initializing NotificationService: $e');
    }
  }

  /// Triggers a sleek push banner notification for incoming chat messages
  Future<void> showChatPushNotification({
    required String senderName,
    required String messageText,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isChatEnabled = prefs.getBool('chat_notifications_enabled') ?? true;
      if (!isChatEnabled) return;

      const androidDetails = AndroidNotificationDetails(
        'nexus_messages_channel',
        'Chat Messages',
        channelDescription: 'Real-time direct messages notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: senderName,
        body: messageText,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error triggering push notification: $e');
    }
  }
}
