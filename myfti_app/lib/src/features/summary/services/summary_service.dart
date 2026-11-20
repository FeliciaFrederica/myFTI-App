import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/session_service.dart';

class SummaryBreakdown {
  final String type;
  final int total;

  const SummaryBreakdown({required this.type, required this.total});

  factory SummaryBreakdown.fromJson(Map<String, dynamic> json) {
    return SummaryBreakdown(
      type: json['type']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class FinancialSummary {
  final String period;
  final int income;
  final int expense;
  final int difference;
  final double expensePercentage;
  final List<SummaryBreakdown> breakdown;

  const FinancialSummary({
    required this.period,
    required this.income,
    required this.expense,
    required this.difference,
    required this.expensePercentage,
    required this.breakdown,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'];

    return FinancialSummary(
      period: json['period']?.toString() ?? 'monthly',
      income: (json['income'] as num?)?.toInt() ?? 0,
      expense: (json['expense'] as num?)?.toInt() ?? 0,
      difference: (json['difference'] as num?)?.toInt() ?? 0,
      expensePercentage:
          (json['expensePercentage'] as num?)?.toDouble() ?? 0,
      breakdown: rawBreakdown is List
          ? rawBreakdown
              .whereType<Map<String, dynamic>>()
              .map(SummaryBreakdown.fromJson)
              .toList()
          : const [],
    );
  }
}

class SummaryService {
  static Future<FinancialSummary> getSummary({
    String period = 'monthly',
  }) async {
    final token = await SessionService.getToken();

    final res = await ApiClient.get(
      '/financial-summary?period=$period',
      token: token,
    ).timeout(const Duration(seconds: 15));

    final body = _decode(res);

    if (res.statusCode == 401) {
      await SessionService.clear();
      throw Exception('Sesi berakhir, silakan login lagi');
    }

    if (res.statusCode != 200) {
      throw Exception(_message(body, 'Gagal memuat ringkasan keuangan'));
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Format respons ringkasan tidak dikenali');
    }

    return FinancialSummary.fromJson(data);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static String _message(Map<String, dynamic> body, String fallback) {
    final msg = body['message'] ?? body['error'];
    return msg == null ? fallback : msg.toString();
  }
}
