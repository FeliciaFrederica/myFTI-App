import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _port = '3000';
  static const String _prefix = '/api';

  // IP laptop di jaringan yang sama dengan HP.
  static const String _laptopIp = '127.0.0.1';

  // Opsional: timpa lewat --dart-define
  // Contoh: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const Duration timeout = Duration(seconds: 15);

  static String get baseUrl {
    final url = _resolve();
    debugPrint('API baseUrl: $url');
    return url;
  }

  static String _resolve() {
    // Jika diisi lewat --dart-define, selalu dipakai
    if (_override.isNotEmpty) return _override;

    final String host;
    if (kIsWeb) {
      host = 'localhost'; // Chrome di laptop yang sama dengan server
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      host = _laptopIp; // HP asli (untuk emulator, pakai --dart-define 10.0.2.2)
    } else {
      host = 'localhost'; // iOS simulator / desktop
    }

    return 'http://$host:$_port$_prefix';
  }
}