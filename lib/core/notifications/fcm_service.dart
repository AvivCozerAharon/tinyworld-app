import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final fcmServiceProvider = Provider<FCMService>((ref) => FCMService(ref));

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
  await flutterLocalNotificationsPlugin.initialize(settings);

  if (Platform.isAndroid) {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
      'tinyworld_messages',
      'Mensagens',
      description: 'Notificacoes de mensagens e conexoes',
      importance: Importance.high,
    ));
  }

  final notification = message.notification;
  if (notification == null) return;

  final type = message.data['type'] ?? '';
  final simId = message.data['sim_id'] ?? '';
  flutterLocalNotificationsPlugin.show(
    message.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'tinyworld_messages',
        'Mensagens',
        channelDescription: 'Notificacoes de mensagens e conexoes',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: '$type|$simId',
  );
}

class FCMService {
  final Ref _ref;
  static String? _pendingRoute;

  FCMService(this._ref);

  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  Future<void> init() async {
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _scheduleNavigation(initialMessage.data);
    }

    messaging.onTokenRefresh.listen(_registerToken);

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
        'tinyworld_messages',
        'Mensagens',
        description: 'Notificacoes de mensagens e conexoes',
        importance: Importance.high,
      ));
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'tinyworld_messages',
          'Mensagens',
          channelDescription: 'Notificacoes de mensagens e conexoes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _buildPayload(message.data),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null || response.payload!.isEmpty) return;
    final parts = response.payload!.split('|');
    if (parts.length >= 2) {
      _navigateFromData({'type': parts[0], 'sim_id': parts[1]});
    }
  }

  String _buildPayload(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final simId = data['sim_id'] ?? '';
    return '$type|$simId';
  }

  static void _scheduleNavigation(Map<String, dynamic> data) {
    final simId = data['sim_id'] ?? '';
    if (simId.isEmpty) return;
    _pendingRoute = '/chats/$simId';
  }

  static void _navigateFromData(Map<String, dynamic> data) {
    _scheduleNavigation(data);
  }

  Future<void> _registerToken(String token) async {
    try {
      await apiClient.post('/profile/device-token', data: {'token': token});
    } catch (_) {}
  }
}
