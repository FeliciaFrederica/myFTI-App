import 'dart:convert';

import '../../../core/services/api_client.dart';
import '../../../core/services/session_service.dart';
import '../../transaction/models/transaction_model.dart';

class MerchantDashboardData {
  final int totalCount;
  final int totalAmount;
  final List<MerchantCategoryData> categories;
  final List<TransactionModel> recentPayments;
  final String period;

  const MerchantDashboardData({
    required this.totalCount,
    required this.totalAmount,
    required this.categories,
    required this.recentPayments,
    required this.period,
  });
}

class MerchantCategoryData {
  final String name;
  final String? subcategory;
  final int count;
  final int amount;

  const MerchantCategoryData({
    required this.name,
    required this.subcategory,
    required this.count,
    required this.amount,
  });
}

class MerchantDashboardService {
  String _dateOnly(DateTime? date) =>
      date == null ? '' : date.toIso8601String().substring(0, 10);

  Future<MerchantDashboardData> getDashboard({
    String period = 'daily',
    DateTime? from,
    DateTime? to,
  }) async {
    final token = await SessionService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi berakhir. Silakan login kembali.');
    }

    final query = Uri(
      queryParameters: {
        'period': period,
        if (period == 'custom') 'from': _dateOnly(from),
        if (period == 'custom') 'to': _dateOnly(to),
      },
    ).query;
    final response = await ApiClient.get(
      '/financial-summary/merchant-dashboard?$query',
      token: token,
    ).timeout(const Duration(seconds: 15));
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map) {
      final message = decoded is Map ? decoded['message'] : null;
      throw Exception(message ?? 'Gagal memuat ringkasan merchant.');
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final total = Map<String, dynamic>.from(data['total'] as Map? ?? {});
    final categories = (data['categories'] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          final row = Map<String, dynamic>.from(item);
          return MerchantCategoryData(
            name: row['name']?.toString() ?? 'Lainnya',
            subcategory: row['subcategory']?.toString(),
            count: (row['count'] as num?)?.toInt() ?? 0,
            amount: (row['amount'] as num?)?.toInt() ?? 0,
          );
        })
        .toList();
    final payments = (data['recentPayments'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => TransactionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return MerchantDashboardData(
      totalCount: (total['count'] as num?)?.toInt() ?? 0,
      totalAmount: (total['amount'] as num?)?.toInt() ?? 0,
      categories: categories,
      recentPayments: payments,
      period: data['period']?.toString() ?? period,
    );
  }

  Future<MerchantTransactionPage> getIncomingPayments({
    String? cursor,
    String period = 'daily',
    DateTime? from,
    DateTime? to,
    String? subcategory,
  }) async {
    final token = await SessionService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi berakhir. Silakan login kembali.');
    }

    final query = Uri(
      queryParameters: {
        'limit': '20',
        'period': period,
        'cursor': ?cursor,
        if (period == 'custom') 'from': _dateOnly(from),
        if (period == 'custom') 'to': _dateOnly(to),
        'subcategory': ?subcategory,
      },
    ).query;
    final response = await ApiClient.get(
      '/transactions/incoming?$query',
      token: token,
    ).timeout(const Duration(seconds: 15));
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! List ||
        decoded['pagination'] is! Map) {
      final message = decoded is Map ? decoded['message'] : null;
      throw Exception(message ?? 'Gagal memuat riwayat pembayaran.');
    }

    final payments = (decoded['data'] as List)
        .whereType<Map>()
        .map(
          (item) => TransactionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    final pagination = Map<String, dynamic>.from(decoded['pagination'] as Map);

    return MerchantTransactionPage(
      transactions: payments,
      nextCursor: pagination['nextCursor'] as String?,
      hasMore: pagination['hasMore'] == true,
    );
  }
}

class MerchantTransactionPage {
  final List<TransactionModel> transactions;
  final String? nextCursor;
  final bool hasMore;

  const MerchantTransactionPage({
    required this.transactions,
    required this.nextCursor,
    required this.hasMore,
  });
}
