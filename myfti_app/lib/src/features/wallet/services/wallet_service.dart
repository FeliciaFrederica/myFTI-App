import 'dart:convert';

import 'package:myfti_app/src/core/services/api_client.dart';
import 'package:myfti_app/src/core/services/session_service.dart';
class WalletService {
  Future<String> _getToken() async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    return token;
  }

  Map<String, dynamic> _handleResponse(
    dynamic response,
    String fallbackMessage,
  ) {
    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        responseData['success'] == true) {
      return Map<String, dynamic>.from(responseData['data']);
    }

    if (response.statusCode == 401) {
      throw Exception('Sesi login berakhir. Silakan login kembali.');
    }

    throw Exception(
      responseData['message'] ?? fallbackMessage,
    );
  }

  Future<Map<String, dynamic>> getWallet() async {
    final token = await _getToken();

    final response = await ApiClient.get(
      '/wallet',
      token: token,
    );

    return _handleResponse(
      response,
      'Gagal mengambil data wallet.',
    );
  }

  Future<Map<String, dynamic>> topUp(int amount) async {
    final token = await _getToken();

    final response = await ApiClient.post(
      '/wallet/top-up',
      token: token,
      body: {'amount': amount},
    );

    return _handleResponse(
      response,
      'Top Up gagal.',
    );
  }
}
