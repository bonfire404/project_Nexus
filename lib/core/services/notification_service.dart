import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus/core/services/firestore_service.dart';
import 'package:nexus/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('Handling background FCM message in terminated/killed state: ${message.messageId}');
    
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? message.data['senderName'] ?? 'New Message';
    final body = notification?.body ?? message.data['body'] ?? message.data['messageText'] ?? '';

    if (title.isNotEmpty || body.isNotEmpty) {
      final service = NotificationService();
      await service.initializeBackground();
      
      // Only display manual local notification if it's a data-only payload (Android automatically displays notification-payload messages)
      if (message.notification == null) {
        await service.showChatPushNotification(
          senderName: title,
          messageText: body,
        );
      }
    }
  } catch (e) {
    debugPrint('Error in background FCM message handler: $e');
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
  bool _isBackgroundInitialized = false;

  /// Lightweight initialization specifically safe for headless background isolates (No UI/Permissions dialogs)
  Future<void> initializeBackground() async {
    if (_isBackgroundInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosSettings = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
      );

      // Create High Priority Android Notification Channel for Zero-Delay & Terminated State (Android 8.0+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'nexus_messages_channel',
        'Chat Messages',
        description: 'Real-time direct messages notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      _isBackgroundInitialized = true;
    } catch (e) {
      debugPrint('Error initializing background NotificationService: $e');
    }
  }

  Future<void> initialize({String? userId}) async {
    await initializeBackground();
    if (_isInitialized) return;

    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      // Configure Foreground Presentation Options for Zero Delay
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request system push notification permissions (Android 13+ & iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _fcm.getToken();
        if (token != null) {
          debugPrint('FCM Token registered: $token');
          if (userId != null && userId.isNotEmpty) {
            await _updateUserFcmToken(userId, token);
          }
        }

        _fcm.onTokenRefresh.listen((newToken) async {
          debugPrint('FCM Token refreshed: $newToken');
          if (userId != null && userId.isNotEmpty) {
            await _updateUserFcmToken(userId, newToken);
          }
        });
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title ?? message.data['title'] ?? message.data['senderName'] ?? 'New Message';
        final body = notification?.body ?? message.data['body'] ?? message.data['messageText'] ?? '';

        if (title.isNotEmpty || body.isNotEmpty) {
          showChatPushNotification(
            senderName: title,
            messageText: body,
          );
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Note: Error initializing NotificationService: $e');
    }
  }

  Future<void> _updateUserFcmToken(String userId, String token) async {
    try {
      final firestore = FirestoreService();
      await firestore.updateDocument('users', userId, {
        'fcmToken': token,
        'fcmUpdatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving FCM Token to Firestore: $e');
    }
  }

  /// Triggers a sleek push banner notification for incoming chat messages
  Future<void> showChatPushNotification({
    required String senderName,
    required String messageText,
    bool isAnnouncement = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isChatEnabled = prefs.getBool('chat_notifications_enabled') ?? true;
      final isAnnouncementsEnabled = prefs.getBool('announcements_enabled') ?? true;

      if (isAnnouncement && !isAnnouncementsEnabled) return;
      if (!isAnnouncement && !isChatEnabled) return;

      final soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
      final vibrationEnabled = prefs.getBool('notification_vibration_enabled') ?? true;

      final androidDetails = AndroidNotificationDetails(
        'nexus_messages_channel',
        'Chat Messages',
        channelDescription: 'Real-time direct messages notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/launcher_icon',
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
        styleInformation: BigTextStyleInformation(
          messageText,
          contentTitle: senderName,
        ),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundEnabled,
      );

      final notificationDetails = NotificationDetails(
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
