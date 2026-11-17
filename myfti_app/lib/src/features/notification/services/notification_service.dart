import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/session_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class NotificationService {
  static Future<List<AppNotification>> list({bool unreadOnly = false}) async {
    final token = await SessionService.getToken();

    final res = await ApiClient.get(
      '/notifications${unreadOnly ? '?unread=true' : ''}',
      token: token,
    ).timeout(const Duration(seconds: 15));

    final body = _decode(res);

    if (res.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Sesi berakhir, silakan login lagi');
    }

    if (res.statusCode != 200) {
      throw Exception(_message(body, 'Gagal memuat notifikasi'));
    }

    final data = body['data'];
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  static Future<void> markAsRead(String id) async {
    final token = await SessionService.getToken();

    final res = await ApiClient.put(
      '/notifications/$id/read',
      token: token,
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Sesi berakhir, silakan login lagi');
    }

    if (res.statusCode != 200) {
      throw Exception(
        _message(_decode(res), 'Gagal menandai notifikasi'),
      );
    }
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static String _message(Map<String, dynamic> body, String fallback) {
    final msg = body['message'] ?? body['error'];
    return msg == null ? fallback : msg.toString();
  }
}
