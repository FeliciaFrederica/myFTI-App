import 'package:flutter/material.dart';

import '../../../core/services/session_service.dart';
import '../../authentication/pages/create_pin_page.dart';
import '../pages/transaction_pin_page.dart';

class TransactionPinFlow {
  static Future<String?> requestPin(BuildContext context) async {
    final user = await SessionService.getUser();

    if (!context.mounted) return null;

    // User belum memiliki PIN: buat PIN terlebih dahulu.
    if (user?.hasPin != true) {
      return Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const CreatePinPage(isForTransaction: true),
        ),
      );
    }

    // User sudah memiliki PIN: minta PIN transaksi.
    return Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const TransactionPinPage()),
    );
  }
}
