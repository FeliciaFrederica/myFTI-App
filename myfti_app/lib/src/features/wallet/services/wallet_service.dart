import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  Future<Map<String, dynamic>> getWallet(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return responseData['data'];
    }

    throw Exception(
      responseData['message'] ?? 'Gagal mengambil data wallet.',
    );
  }

  Future<Map<String, dynamic>> topUp(String token, int amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/top-up'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return responseData['data'];
    }

    throw Exception(
      responseData['message'] ?? 'Top Up gagal.',
    );
  }

}
