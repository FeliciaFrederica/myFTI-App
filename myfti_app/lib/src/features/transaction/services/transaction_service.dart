import 'dart:convert';

import 'package:myfti_app/src/core/services/api_client.dart';
import 'package:myfti_app/src/core/services/session_service.dart';
import 'package:myfti_app/src/features/transaction/models/transaction_model.dart';

class TransactionPageResult {
  final List<TransactionModel> transactions;
  final String? nextCursor;
  final bool hasMore;

  const TransactionPageResult({
    required this.transactions,
    required this.nextCursor,
    required this.hasMore,
  });
}

class TransactionService {
  Future<TransactionPageResult> getTransactions({
    String? cursor,
    String sort = 'desc',
  }) async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesi berakhir. Silakan login kembali.');
    }

    final queryParameters = <String, String>{
      'limit': '10',
      'sort': sort,
      if (cursor != null) 'cursor': cursor,
    };

    final query = Uri(queryParameters: queryParameters).query;
    final response = await ApiClient.get(
      '/transactions?$query',
      token: token,
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        responseData['success'] == true) {
      final List<dynamic> data = responseData['data'];
      final pagination = responseData['pagination'];

      return TransactionPageResult(
        transactions: data
            .map(
              (item) => TransactionModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
        nextCursor: pagination['nextCursor'] as String?,
        hasMore: pagination['hasMore'] as bool,
      );
    }

    if (response.statusCode == 401) {
      throw Exception('Sesi berakhir. Silakan login kembali.');
    }

    throw Exception(
      responseData['message'] ?? 'Gagal mengambil riwayat transaksi.',
    );
  }
}