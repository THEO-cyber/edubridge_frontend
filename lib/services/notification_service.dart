import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../core/secure_storage.dart';
import '../core/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    const androidChannel = AndroidNotificationChannel(
      'edubridge_default',
      'EduBridge Notifications',
      description: 'Course and session alerts',
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      _localNotif.show(
        n.hashCode,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'edubridge_default',
            'EduBridge Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['actionUrl'],
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  static Future<void> registerToken(String authToken) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.registerFcmToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token, 'platform': 'android'}),
      );

      _fcm.onTokenRefresh.listen((newToken) async {
        final currentToken = await SecureStorage.getToken();
        if (currentToken == null) return;
        await http.post(
          Uri.parse(ApiConstants.baseUrl + ApiConstants.registerFcmToken),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $currentToken',
          },
          body: jsonEncode({'token': newToken, 'platform': 'android'}),
        );
      });
    } catch (_) {}
  }

  static Future<void> unregisterToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      final authToken = await SecureStorage.getToken();
      if (authToken == null) return;

      await http.delete(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.registerFcmToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );

      await _fcm.deleteToken();
    } catch (_) {}
  }

  static void _onNotificationTap(NotificationResponse response) {
    final url = response.payload;
    if (url != null) AppRouter.navigateTo(url);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final url = message.data['actionUrl'] as String?;
    if (url != null) AppRouter.navigateTo(url);
  }
}
