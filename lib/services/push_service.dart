import 'dart:convert';
import 'dart:io';

import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

const _channel = AndroidNotificationChannel(
  'cargoline_alerts',
  'CargoLine',
  description: 'Статус груза ва паёмҳо',
  importance: Importance.high,
);

final _local = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Registers the phone with Firebase and sends the token to the API.
class PushService {
  static bool _ready = false;
  static Future<void>? _starting;
  static String? _access;

  static Future<void> start() async {
    if (_ready) return;
    if (_starting != null) {
      await _starting;
      return;
    }
    _starting = _start();
    try {
      await _starting;
    } catch (_) {
      _starting = null;
    }
  }

  static Future<void> _start() async {
    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_notify');
    try {
      await _local.initialize(const InitializationSettings(android: androidInit));
    } catch (_) {}
    if (Platform.isAndroid) {
      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        await android?.createNotificationChannel(_channel);
        await android?.requestNotificationsPermission();
      } catch (_) {}
    }
    try {
      await Firebase.initializeApp();
    } catch (_) {
      return;
    }
    _ready = true;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}
    if (Platform.isIOS) {
      try {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}
    }
    FirebaseMessaging.onMessage.listen((message) async {
      if (Platform.isIOS) return;
      final note = message.notification;
      final title = note?.title ?? message.data['title'];
      final body = note?.body ?? message.data['body'];
      if (title == null && body == null) return;
      await _local.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notify',
          ),
        ),
      );
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      _upload();
    });
  }

  static Future<void> sync(String? accessToken) async {
    _access = accessToken;
    await start();
    await _upload();
  }

  static Future<void> _upload() async {
    final access = _access;
    if (!_ready || access == null || access.isEmpty) return;
    if (Platform.isIOS) {
      for (var i = 0; i < 12; i++) {
        String? apns;
        try {
          apns = await FirebaseMessaging.instance.getAPNSToken();
        } catch (_) {}
        if (apns != null && apns.isNotEmpty) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    String? token;
    for (var i = 0; i < 5 && (token == null || token.isEmpty); i++) {
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (_) {}
      if (token == null || token.isEmpty) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    if (token == null || token.isEmpty) return;
    try {
      await http
          .post(
            Uri.parse('${BrandConstants.apiBaseUrl}/api/v1/push-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $access',
            },
            body: jsonEncode({
              'token': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
