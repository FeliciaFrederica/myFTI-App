import 'dart:convert';

import '../../../core/services/api_client.dart';
import '../../../core/services/api_config.dart';
import '../../../core/services/session_service.dart';

class WithdrawService {
  static const int minWithdraw = 10000;

  // Mengambil daftar rekening bank yang tersimpan
  Future<List<Map<String, dynamic>>> getSavedBankAccounts() async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Silakan masuk kembali ke akun Anda.');
    }

    final response = await ApiClient.get(
      '/withdrawals/bank-accounts',
      token: token,
    ).timeout(ApiConfig.timeout);

    final result = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw Exception('Sesi Anda telah berakhir. Silakan masuk kembali.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(
        result['message'] ?? 'Gagal mengambil daftar rekening.',
      );
    }

    final data = result['data'];

    if (data is! List) {
      throw Exception('Data rekening tidak valid.');
    }

    return data
        .map((account) => Map<String, dynamic>.from(account))
        .toList();
  }

  // Memproses penarikan saldo ke rekening bank
  Future<Map<String, dynamic>> withdraw({
    required int amount,
    required String pin,
    String? bankAccountId,
    String? bankCode,
    String? accountNumber,
    bool saveAccount = false,
  }) async {
    if (amount < minWithdraw) {
      throw Exception('Minimal withdraw adalah Rp10.000.');
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw Exception('PIN harus terdiri dari 6 angka.');
    }

    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Silakan masuk kembali ke akun Anda.');
    }

    final body = <String, dynamic>{
      'amount': amount,
      'pin': pin,
    };

    // Menggunakan rekening yang sudah tersimpan
    if (bankAccountId != null && bankAccountId.trim().isNotEmpty) {
      body['bankAccountId'] = bankAccountId.trim();
    } else {
      // Menggunakan rekening baru
      if (bankCode == null || bankCode.trim().isEmpty) {
        throw Exception('Pilih bank tujuan terlebih dahulu.');
      }

      if (accountNumber == null ||
          !RegExp(r'^\d{10,16}$').hasMatch(accountNumber)) {
        throw Exception('Nomor rekening harus 10–16 digit angka.');
      }

      body['bankCode'] = bankCode;
      body['accountNumber'] = accountNumber;
      body['saveAccount'] = saveAccount;
    }

    final response = await ApiClient.post(
      '/withdrawals',
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
      throw Exception(
        result['message'] ?? 'Withdraw gagal dilakukan.',
      );
    }

    return Map<String, dynamic>.from(result['data']);
  }
}
