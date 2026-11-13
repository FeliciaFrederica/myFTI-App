import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final url = _resolve();
    debugPrint('API baseUrl: $url');
    return url;
  }

  static String _resolve() {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api'; // emulator Android
    return 'http://localhost:3000/api'; // iOS simulator / desktop
  }

  static const Duration timeout = Duration(seconds: 10);
}