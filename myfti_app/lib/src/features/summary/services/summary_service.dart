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

class MonthlyComparison {
  final int year;
  final int month;
  final String label;
  final int income;
  final int expense;
  final int difference;

  const MonthlyComparison({
    required this.year,
    required this.month,
    required this.label,
    required this.income,
    required this.expense,
    required this.difference,
  });

  factory MonthlyComparison.fromJson(Map<String, dynamic> json) {
    return MonthlyComparison(
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString() ?? '',
      income: (json['income'] as num?)?.toInt() ?? 0,
      expense: (json['expense'] as num?)?.toInt() ?? 0,
      difference: (json['difference'] as num?)?.toInt() ?? 0,
    );
  }
}

class FinancialSummary {
  final String period;
  final DateTime? from;
  final DateTime? to;
  final int income;
  final int expense;
  final int difference;
  final double expensePercentage;
  final List<SummaryBreakdown> breakdown;
  final List<MonthlyComparison> monthlyComparison;

  const FinancialSummary({
    required this.period,
    this.from,
    this.to,
    required this.income,
    required this.expense,
    required this.difference,
    required this.expensePercentage,
    required this.breakdown,
    this.monthlyComparison = const [],
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'];
    final rawMonthly = json['monthlyComparison'];

    return FinancialSummary(
      period: json['period']?.toString() ?? 'monthly',
      from: json['from'] != null
          ? DateTime.tryParse(json['from'].toString())
          : null,
      to: json['to'] != null ? DateTime.tryParse(json['to'].toString()) : null,
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
      monthlyComparison: rawMonthly is List
          ? rawMonthly
              .whereType<Map<String, dynamic>>()
              .map(MonthlyComparison.fromJson)
              .toList()
          : const [],
    );
  }
}

class SummaryService {
  static String _formatYmd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<FinancialSummary> getSummary({
    String period = 'monthly',
    DateTime? from,
    DateTime? to,
  }) async {
    final token = await SessionService.getToken();

    final endpoint = (from != null && to != null)
        ? '/financial-summary?from=${_formatYmd(from)}&to=${_formatYmd(to)}'
        : '/financial-summary?period=$period';

    final res = await ApiClient.get(
      endpoint,
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
