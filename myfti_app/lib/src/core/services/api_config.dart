import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _port = '3000';
  static const String _prefix = '/api';

  // Diisi lewat --dart-define (lihat .vscode/launch.json).
  // Contoh: flutter run --dart-define=API_BASE_URL=http://10.17.226.24:3000/api
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const Duration timeout = Duration(seconds: 15);

  static String get baseUrl {
    final url = _resolve();
    debugPrint('API baseUrl: $url');
    return url;
  }

  static String _resolve() {
    // Jika diisi lewat --dart-define, selalu dipakai (HP asli, server online, dll.)
    if (_override.isNotEmpty) return _override;

    // Default otomatis per platform
    final String host;
    if (kIsWeb) {
      host = 'localhost'; // Chrome
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      host = '10.0.2.2'; // emulator Android
    } else {
      host = 'localhost'; // iOS simulator / desktop
    }

    return 'http://$host:$_port$_prefix';
  }
}