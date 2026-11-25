import 'dart:convert';

import 'package:myfti_app/src/core/services/api_client.dart';
import 'package:myfti_app/src/core/services/session_service.dart';
import 'package:myfti_app/src/features/transaction/models/transaction_model.dart';

class TransactionService {
  Future<List<TransactionModel>> getTransactions() async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    final response = await ApiClient.get(
      '/transactions',
      token: token,
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        responseData['success'] == true) {
      final List<dynamic> transactions = responseData['data'];

      return transactions
          .map(
            (item) => TransactionModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Sesi login berakhir. Silakan login kembali.',
      );
    }

    throw Exception(
      responseData['message'] ?? 'Gagal mengambil riwayat transaksi.',
    );
  }

  Future<TransactionModel> getTransactionDetail(String transactionId) async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    final response = await ApiClient.get(
      '/transactions/$transactionId',
      token: token,
    ).timeout(const Duration(seconds: 15));

    Map<String, dynamic> responseData = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        responseData = decoded;
      }
    } catch (_) {}

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        responseData['success'] == true &&
        responseData['data'] is Map) {
      return TransactionModel.fromJson(
        Map<String, dynamic>.from(responseData['data'] as Map),
      );
    }

    if (response.statusCode == 401) {
      await SessionService.clear();
      throw Exception(
        'Sesi login berakhir. Silakan login kembali.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        responseData['message'] ?? 'Transaksi tidak ditemukan.',
      );
    }

    throw Exception(
      responseData['message'] ?? 'Gagal mengambil detail transaksi.',
    );
  }
}