import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfti_app/src/features/authentication/models/user_model.dart';

class SessionService {
  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user_data';

  static Future<void> saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}