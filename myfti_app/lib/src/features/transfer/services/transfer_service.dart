import 'dart:convert';

import '../../../core/services/api_client.dart';
import '../../../core/services/api_config.dart';
import '../../../core/services/session_service.dart';

class TransferService {
  static const int minTransfer = 10000;

  // Mengambil informasi penerima berdasarkan ID Dompet
  Future<Map<String, dynamic>> getRecipient(String walletId) async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Silakan masuk kembali ke akun Anda.');
    }

    final response = await ApiClient.get(
      '/users/recipient/${Uri.encodeComponent(walletId.trim())}',
      token: token,
    ).timeout(ApiConfig.timeout);

    final result = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw Exception('Sesi Anda telah berakhir. Silakan masuk kembali.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(result['message'] ?? 'Gagal mencari penerima.');
    }

    return Map<String, dynamic>.from(result['data']);
  }

  // Mengirim saldo ke dompet penerima
  Future<Map<String, dynamic>> transfer({
    required String recipientWalletId,
    required int amount,
    String? description,
  }) async {
    if (amount < minTransfer) {
      throw Exception('Minimal transfer adalah Rp10.000.');
    }

    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Silakan masuk kembali ke akun Anda.');
    }

    final body = <String, dynamic>{
      'recipientWalletId': recipientWalletId.trim(),
      'amount': amount,
    };

    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }

    final response = await ApiClient.post(
      '/transfers',
      token: token,
      body: body,
    ).timeout(ApiConfig.timeout);

    final result = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw Exception('Sesi Anda telah berakhir. Silakan masuk kembali.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(result['message'] ?? 'Transfer gagal dilakukan.');
    }

    return Map<String, dynamic>.from(result['data']);
  }
}