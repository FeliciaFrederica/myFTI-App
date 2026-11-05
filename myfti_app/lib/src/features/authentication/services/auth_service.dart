import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/session_service.dart';
import '../models/user_model.dart';

class AuthService {
  static const Duration _timeout = Duration(seconds: 15);

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

  // Ambil pesan error dari server, atau pakai pesan cadangan.
  static String _message(Map<String, dynamic> body, String fallback) {
    final msg = body['message'] ?? body['error'];
    return msg == null ? fallback : msg.toString();
  }

  // Ambil objek user dari berbagai kemungkinan bentuk respons:
  // {data:{user:{...}}}, {data:{...}}, atau {...}
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
    } catch (_) {
      throw Exception('Tidak dapat terhubung ke server');
    }
  }

  // ---------- API ----------

  // Register akun baru. Tidak otomatis login; user diarahkan ke halaman login.
  // Wallet ID dan saldo awal (Rp 0) dibuat oleh backend.
  static Future<void> register({
    required String name,
    required String nim,
    required String email,
    required String password,
  }) async {
    final res = await _guard(_send('POST', '/register', body: {
      'name': name,
      'nim': nim,
      'email': email,
      'password': password,
    }));

    final ok = res.statusCode == 200 || res.statusCode == 201;
    if (!ok) {
      throw Exception(_message(_decode(res), 'Registrasi gagal'));
    }
  }

  // Login, lalu simpan token JWT + data user ke SessionService.
  static Future<void> login(String email, String password) async {
    final res = await _guard(_send('POST', '/login', body: {
      'email': email,
      'password': password,
    }));

    final body = _decode(res);
    final data = body['data'];
    final token = (data is Map ? data['token'] : null) ??
        body['token'] ??
        body['access_token'];

    if (res.statusCode != 200 || token == null) {
      throw Exception(_message(body, 'Email atau password salah'));
    }

    await SessionService.saveSession(
      token.toString(),
      UserModel.fromJson(_userMap(body)),
    );
  }

  // Logout: beri tahu server (jika bisa), lalu hapus sesi lokal.
  static Future<void> logout() async {
    try {
      await _send('POST', '/logout', auth: true).timeout(_timeout);
    } catch (_) {
      // tetap hapus sesi lokal walau server tidak terjangkau
    }
    await SessionService.clear();
  }

  // Ambil data profil user yang sedang login dari server.
  static Future<UserModel> getProfile() async {
    final res = await _guard(_send('GET', '/profile', auth: true));
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

  // Perbarui nama dan email user yang sedang login.
  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final res = await _guard(_send('PUT', '/profile',
        body: {'name': name, 'email': email}, auth: true));
    final body = _decode(res);

    if (res.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Sesi berakhir, silakan login lagi');
    }
    if (res.statusCode != 200) {
      throw Exception(_message(body, 'Gagal memperbarui profil'));
    }

    // sinkronkan data user di SessionService
    await SessionService.saveUser(UserModel.fromJson(_userMap(body)));
  }

  // Dipakai splash screen untuk menentukan ke login atau home.
  static Future<bool> isLoggedIn() async {
    final token = await SessionService.getToken();
    return token != null && token.isNotEmpty;
  }
}