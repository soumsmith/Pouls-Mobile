import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  final StreamController<Map<String, dynamic>> _notificationController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  Future<String?> getTokenAsync() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  Future<void> _handleNotificationUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      if (urlString.startsWith('http://') || urlString.startsWith('https://')) {
        final uri = Uri.parse(urlString);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        // Try parsing payload as JSON
        final data = json.decode(urlString);
        if (data is Map<String, dynamic>) {
          final url = data['url'] ?? data['link'] ?? data['store_url'];
          if (url != null && url is String && (url.startsWith('http://') || url.startsWith('https://'))) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error launching URL from notification: $e');
    }
  }

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked! Payload: ${response.payload}');
        _handleNotificationUrl(response.payload);
      },
    );

    // ── Configuration de Firebase Messaging ──────────────────────────────────
    
    // 1. Écouter les messages au premier plan (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground message received: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        String? payload;
        final data = message.data;
        final url = data['url'] ?? data['link'] ?? data['store_url'];
        if (url != null) {
          payload = url.toString();
        } else if (data.isNotEmpty) {
          payload = json.encode(data);
        }

        showNotification(
          id: notification.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: payload,
        );
      }
    });

    // 2. Écouter les clics sur les notifications en arrière-plan (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Notification clicked from background! Data: ${message.data}');
      final url = message.data['url'] ?? message.data['link'] ?? message.data['store_url'];
      if (url != null) {
        _handleNotificationUrl(url.toString());
      }
    });

    // 3. Écouter le clic sur une notification ayant lancé l'application (Terminated)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCM Notification clicked from terminated state! Data: ${message.data}');
        final url = message.data['url'] ?? message.data['link'] ?? message.data['store_url'];
        if (url != null) {
          _handleNotificationUrl(url.toString());
        }
      }
    });
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_channel',
      'Commandes',
      channelDescription: 'Notifications relatives aux commandes passées.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: const Color(0xFFE65100),
      styleInformation: BigTextStyleInformation(body),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }
}
