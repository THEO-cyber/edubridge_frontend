import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../core/secure_storage.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  static final _fln = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Local notifications channel (Android 8+)
    const androidChannel = AndroidNotificationChannel(
      'edubridge_high',
      'EduBridge Notifications',
      description: 'Live sessions, payments, certificates',
      importance: Importance.high,
    );

    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _fln.initialize(initSettings);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Request permission
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null && android != null) {
        _fln.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'edubridge_high',
              'EduBridge Notifications',
              channelDescription:
                  'Live sessions, payments, certificates',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    _initialized = true;
  }

  /// Returns the FCM device token — send this to your backend to target
  /// this specific device for push notifications.
  static Future<String?> getDeviceToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Gets the FCM token and registers it with the NestJS backend.
  /// Call this after a successful login or register.
  static Future<void> registerTokenWithBackend() async {
    try {
      final fcmToken = await getDeviceToken();
      if (fcmToken == null) return;
      final authToken = await SecureStorage.getToken();
      if (authToken == null) return;
      await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.registerFcmToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );
    } catch (_) {}
  }

  /// Subscribe to a topic (e.g. 'instructor_<id>', 'student_<id>')
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {}
  }
}
