import 'package:flutter/material.dart';

class TransactionSuccessPage extends StatelessWidget {
  const TransactionSuccessPage({
    super.key,
    required this.title,
    required this.amount,
    required this.recipient,
    required this.reference,
    this.recipientLabel = 'Kepada',
    this.referenceLabel = 'ID Transaksi',
  });

  final String title;
  final int amount;
  final String recipient;
  final String reference;
  final String recipientLabel;
  final String referenceLabel;

  static const Color _primaryPurple = Color(0xFF673AB7);
  static const Color _textColor = Color(0xFF2D1B46);
  static const Color _backgroundColor = Color(0xFFF3EEFC);

  String _formatRupiah(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $formatted';
  }

  Widget _detailRow(String label, String value, {bool isReference = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isReference ? 13 : 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isReference ? 12 : 14,
              fontWeight: isReference ? FontWeight.normal : FontWeight.w600,
              color: isReference ? Colors.grey.shade600 : _textColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _primaryPurple,
                  size: 72,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _formatRupiah(amount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: _primaryPurple,
                  ),
                ),
                const SizedBox(height: 32),
                _detailRow(recipientLabel, recipient),
                const SizedBox(height: 16),
                _detailRow(referenceLabel, reference, isReference: true),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
