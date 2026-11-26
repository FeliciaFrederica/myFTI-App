import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiClient {
  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

  static Uri _uri(String endpoint) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    debugPrint('API REQUEST: $uri');
    return uri;
  }

  static Future<http.Response> get(String endpoint, {String? token}) {
    return http.get(_uri(endpoint), headers: _headers(token));
  }

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return http.post(
      _uri(endpoint),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    );
  }

  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return http.put(
      _uri(endpoint),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String endpoint, {String? token}) {
    return http.delete(_uri(endpoint), headers: _headers(token));
  }
}