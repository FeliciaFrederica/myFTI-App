import 'dart:convert';

import '../../../core/services/api_client.dart';
import '../../../core/services/session_service.dart';

class PaymentService {
  static Future<List<Map<String, dynamic>>> getRecipients() async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session tidak ditemukan. Silakan login kembali.');
    }

    final response = await ApiClient.get('/payments/recipients', token: token);

    if (response.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Session berakhir. Silakan login kembali.');
    }

    final responseData = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        responseData['success'] != true) {
      throw Exception(
        responseData['message'] ?? 'Gagal mengambil daftar merchant.',
      );
    }

    final List<dynamic> recipients = responseData['data'];

    return recipients.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<Map<String, dynamic>> createPayment({
    required String merchantId,
    required int amount,
    required String pin,
    String? description,
  }) async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session tidak ditemukan. Silakan login kembali.');
    }

    final response = await ApiClient.post(
      '/payments',
      token: token,
      body: {
        'merchantId': merchantId,
        'amount': amount,
        'description': description ?? '',
        'pin': pin,
      },
    );

    if (response.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Session berakhir. Silakan login kembali.');
    }

    final responseData = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        responseData['success'] != true) {
      throw Exception(responseData['message'] ?? 'Payment gagal diproses.');
    }

    return Map<String, dynamic>.from(responseData['data']);
  }
}
