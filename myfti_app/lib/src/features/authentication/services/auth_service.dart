import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/session_service.dart';
import '../models/user_model.dart';

class AuthService {
  static const Duration _timeout = Duration(seconds: 15);

  static const String _register = '/auth/register';
  static const String _login = '/auth/login';
  static const String _logout = '/auth/logout';
  static const String _profile = '/auth/profile';

  static Future<http.Response> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final token = auth ? await SessionService.getToken() : null;
    switch (method) {
      case 'GET':
        return ApiClient.get(endpoint, token: token);
      case 'PUT':
        return ApiClient.put(endpoint, body: body, token: token);
      default:
        return ApiClient.post(endpoint, body: body, token: token);
    }
  }

  // ---------- helper internal ----------

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

  static Map<String, dynamic> _userMap(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        if (data['wallet'] is Map && user['wallet'] == null) {
          return {...user, 'wallet': data['wallet']};
        }
        return user;
      }
      return data;
    }
    return body;
  }

  static Future<http.Response> _guard(Future<http.Response> request) async {
    try {
      return await request.timeout(_timeout);
    } on TimeoutException catch (e) {
      debugPrint('AUTH TIMEOUT: $e');
      throw Exception('Server tidak merespons, coba lagi');
    } catch (e) {
      debugPrint('AUTH CONNECTION ERROR: $e');
      throw Exception('Tidak dapat terhubung ke server');
    }
  }

  // ---------- API ----------

  static Future<void> register({
    required String name,
    required String nim,
    required String email,
    required String password,
  }) async {
    final res = await _guard(_send('POST', _register, body: {
      'fullName': name,
      'nim': nim,
      'email': email,
      'password': password,
    }));

    final ok = res.statusCode == 200 || res.statusCode == 201;
    if (!ok) {
      debugPrint('REGISTER ${res.statusCode}: ${res.body}');
      throw Exception(_message(_decode(res), 'Registrasi gagal'));
    }
  }

  static Future<void> login(String email, String password) async {
    final res = await _guard(_send('POST', _login, body: {
      'email': email,
      'password': password,
    }));

    final body = _decode(res);
    final data = body['data'];
    final token = (data is Map ? data['token'] : null) ??
        body['token'] ??
        body['access_token'];

    if (res.statusCode != 200 || token == null) {
      debugPrint('LOGIN ${res.statusCode}: ${res.body}');
      throw Exception(_message(body, 'Email atau password salah'));
    }

    await SessionService.saveSession(
      token.toString(),
      UserModel.fromJson(_userMap(body)),
    );
  }

  static Future<void> logout() async {
    try {
      await _send('POST', _logout, auth: true).timeout(_timeout);
    } catch (_) {
      // tetap hapus sesi lokal walau server tidak terjangkau
    }
    await SessionService.clear();
  }

  static Future<UserModel> getProfile() async {
    final res = await _guard(_send('GET', _profile, auth: true));
    final body = _decode(res);

    if (res.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Sesi berakhir, silakan login lagi');
    }
    if (res.statusCode != 200) {
      throw Exception(_message(body, 'Gagal memuat profil'));
    }

    final user = UserModel.fromJson(_userMap(body));
    await SessionService.saveUser(user);
    return user;
  }

  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final res = await _guard(_send('PUT', _profile,
        body: {'fullName': name, 'email': email}, auth: true));
    final body = _decode(res);

    if (res.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Sesi berakhir, silakan login lagi');
    }
    if (res.statusCode != 200) {
      throw Exception(_message(body, 'Gagal memperbarui profil'));
    }

    await SessionService.saveUser(UserModel.fromJson(_userMap(body)));
  }

  static Future<bool> isLoggedIn() async {
    final token = await SessionService.getToken();
    return token != null && token.isNotEmpty;
  }
}