import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  // sesuai dengan backend yang digunakan
  static const String _port = '3000'; 
  static const String _prefix = '/api'; 
  static const String _lanIp = '10.17.226.24'; // sesuai dengan IP address laptop
  static const bool _useRealDevice = true; // true karena pakai real device, false jika pakai emulator / simulator

  // flutter run --dart-define=API_BASE_URL=https://api-kamu.com/api
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    final String host;
    if (kIsWeb) {
      host = 'localhost'; // Chrome
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      host = _useRealDevice ? _lanIp : '10.0.2.2'; // emulator Android
    } else {
      host = _useRealDevice ? _lanIp : 'localhost'; // iOS simulator / desktop
    }

    return 'http://$host:$_port$_prefix';
  }
}