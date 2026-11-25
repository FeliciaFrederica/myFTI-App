import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  // helper internal

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  // Untuk mengambil pesan error dari server
  static String _message(Map<String, dynamic> body, String fallback) {
    final msg = body['message'] ?? body['error'];
    return msg == null ? fallback : msg.toString();
  }

  // Mengambil objek user dari berbagai bentuk respons server.
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
    } on http.ClientException catch (e) {
      debugPrint('AUTH CLIENT ERROR: $e');
      throw Exception('Tidak dapat terhubung ke server');
    } catch (e, st) {
      final type = e.runtimeType.toString();
      if (type.contains('SocketException') ||
          type.contains('HandshakeException')) {
        debugPrint('AUTH SOCKET ERROR: $e');
        throw Exception('Tidak dapat terhubung ke server');
      }
      debugPrint('AUTH UNEXPECTED ERROR: $e\n$st');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // ---------- API ----------

  // Pada saat register akun baru, user tidak akan otomatis login.
  // Wallet ID dan saldo awal otomatis (Rp 0).
  static Future<String> register({
    required String name,
    required String nim,
    required String email,
    required String password,
  }) async {
    final res = await _guard(
      _send(
        'POST',
        '/auth/register',
        body: {
          'fullName': name,
          'nim': nim,
          'email': email,
          'password': password,
        },
      ),
    );

    final body = _decode(res);
    final data = body['data'];

    final setupToken = data is Map ? data['setupToken'] : null;

    if ((res.statusCode != 200 && res.statusCode != 201) ||
        setupToken == null ||
        setupToken.toString().isEmpty) {
      throw Exception(_message(body, 'Registrasi gagal'));
    }

    return setupToken.toString();
  }

  // Membuat PIN menggunakan token sementara dari proses registrasi.
  static Future<void> setupPin({
    required String pin,
    required String setupToken,
  }) async {
    final res = await _guard(
      ApiClient.post(
        '/auth/pin/setup',
        body: {'pin': pin},
        token: setupToken,
      ),
    );

    final body = _decode(res);

    if (res.statusCode != 201) {
      throw Exception(_message(body, 'Gagal membuat PIN'));
    }
  }

  // Login, lalu simpan token JWT + data user ke SessionService.
  static Future<void> login(String email, String password) async {
    final res = await _guard(
      _send(
        'POST',
        '/auth/login',
        body: {'email': email, 'password': password},
      ),
    );

    final body = _decode(res);
    final data = body['data'];
    final token =
        (data is Map ? data['token'] : null) ??
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

  // Logout
  static Future<void> logout() async {
    try {
      await _send('POST', '/logout', auth: true).timeout(_timeout);
    } catch (_) {
      // tetap hapus sesi lokal walau server tidak dapat di jangkau
    }
    await SessionService.clear();
  }

  // Mengambil data profil user yang sedang login dari server.
  static Future<UserModel> getProfile() async {
    final res = await _guard(_send('GET', '/auth/profile', auth: true));
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

  // Memperbarui nama dan email user yang sedang login.
  // Nama user bisa lebih dari satu kata (contoh: "Vianlienra Hung").
  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final res = await _guard(
      _send(
        'PUT',
        '/auth/profile',
        body: {'fullName': name, 'email': email},
        auth: true,
      ),
    );
    final body = _decode(res);

    if (res.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Sesi berakhir, silakan login lagi');
    }
    if (res.statusCode != 200) {
      throw Exception(_message(body, 'Gagal memperbarui profil'));
    }

    // Memperbarui data user di SessionService.
    try {
      await SessionService.saveUser(UserModel.fromJson(_userMap(body)));
    } catch (e) {
      debugPrint('UPDATE PROFILE: gagal sinkron sesi lokal: $e');
    }
  }

  // Mengubah foto profil, kirim null untuk menghapus foto.
  // Isi avatar berupa data URL base64
  static Future<void> updateAvatar(String? avatar) async {
    final res = await _guard(
      _send(
        'PUT',
        '/auth/profile/avatar',
        body: {'avatar': avatar},
        auth: true,
      ),
    );
    final body = _decode(res);

    if (res.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Sesi berakhir, silakan login lagi');
    }
    if (res.statusCode != 200) {
      throw Exception(_message(body, 'Gagal memperbarui foto profil'));
    }

    try {
      await SessionService.saveUser(UserModel.fromJson(_userMap(body)));
    } catch (e) {
      debugPrint('UPDATE AVATAR: gagal sinkron sesi lokal: $e');
    }
  }

  // Mengubah password user yang sedang login
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _guard(
      _send(
        'PUT',
        '/auth/password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        auth: true,
      ),
    );
    final body = _decode(res);

    if (res.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Sesi berakhir, silakan login lagi');
    }
    if (res.statusCode != 200) {
      throw Exception(_message(body, 'Gagal mengubah password'));
    }
  }

  // Splash screen digunakan untuk memeriksa apakah user sudah login atau belum.
  static Future<bool> isLoggedIn() async {
    final token = await SessionService.getToken();
    return token != null && token.isNotEmpty;
  }
}