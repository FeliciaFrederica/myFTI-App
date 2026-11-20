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
}