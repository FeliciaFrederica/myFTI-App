import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/session_service.dart';
import 'notification_service.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static const String _channelId = 'myfti_transactions';
  static const String _channelName = 'Notifikasi Transaksi myFTI';
  static const String _channelDesc =
      'Pemberitahuan Top Up, Transfer, Pembayaran, dan Withdraw';
  static const String _seenKeyPrefix = 'seen_system_notif_ids_';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _checking = false;
  static Timer? _pollTimer;

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings: initSettings);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService init error: $e');
    }
  }

  static Future<void> show({
    required String title,
    required String body,
    int? id,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF673AB7),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final notifId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

    try {
      await _plugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('LocalNotificationService show error: $e');
    }
  }

  static void startPolling({Duration interval = const Duration(seconds: 10)}) {
    if (kIsWeb) return;
    _pollTimer?.cancel();
    checkNow();
    _pollTimer = Timer.periodic(interval, (_) => checkNow());
  }

  static void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  static Future<void> checkNow() async {
    if (kIsWeb || _checking) return;
    _checking = true;

    try {
      final token = await SessionService.getToken();
      if (token == null || token.isEmpty) return;

      final user = await SessionService.getUser();
      final userKey = '$_seenKeyPrefix${user?.id ?? 'default'}';

      final items = await NotificationService.list();
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList(userKey);

      if (savedIds == null) {
        await prefs.setStringList(
          userKey,
          items.map((e) => e.id).toList(),
        );
        return;
      }

      final seenSet = savedIds.toSet();
      final newItems = items
          .where((item) => !item.isRead && !seenSet.contains(item.id))
          .toList();

      for (final item in newItems.reversed) {
        await show(
          id: item.id.hashCode & 0x7fffffff,
          title: item.title,
          body: item.message,
        );
        seenSet.add(item.id);
      }

      if (newItems.isNotEmpty) {
        final trimmed = seenSet.toList();
        if (trimmed.length > 200) {
          trimmed.removeRange(0, trimmed.length - 200);
        }
        await prefs.setStringList(userKey, trimmed);
      }
    } catch (_) {
    } finally {
      _checking = false;
    }
  }
}
