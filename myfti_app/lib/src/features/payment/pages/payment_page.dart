import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:myfti_app/src/features/wallet/services/wallet_service.dart';

import '../services/payment_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color backgroundColor = Color(0xFFF8F6FC);
  static const Color textColor = Color(0xFF2D1B46);
  static const Color borderColor = Color(0xFFD1C4E9);

  static const Map<String, String> _categoryValues = {
    'Alleyway': 'ALLEYWAY',
    'Print': 'PRINT',
    'Kantin': 'KANTIN',
    'Jukel & PO': 'JUKEL_PO',
    'Akademik': 'AKADEMIK',
  };

  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _categories = [
    'Alleyway',
    'Print',
    'Kantin',
    'Jukel & PO',
    'Akademik',
  ];

  Map<String, dynamic>? _wallet;

  String? _selectedCategory;

  String? _categoryError;
  String? _amountError;

  bool _isLoading = true;
  bool _isPaying = false;
  String? _loadError;

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  int get _balance => (_wallet?['balance'] as num?)?.toInt() ?? 0;

  String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final wallet = await _walletService.getWallet();

      if (!mounted) return;

      setState(() {
        _wallet = wallet;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _categoryError = null;
    });
  }
  
  void _onAmountChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _amountError = null;
      } else if (_amount <= 0) {
        _amountError = 'Nominal harus lebih dari Rp 0.';
      } else if (_amount > _balance) {
        _amountError = 'Saldo kamu tidak mencukupi.';
      } else {
        _amountError = null;
      }
    });
  }

  bool _validateForm() {
    bool isValid = true;

    setState(() {
      _categoryError = null;
      _amountError = null;

      if (_selectedCategory == null) {
        _categoryError = 'Pilih kategori pembayaran.';
        isValid = false;
      }

      if (_amount <= 0) {
        _amountError = 'Masukkan nominal pembayaran.';
        isValid = false;
      } else if (_amount > _balance) {
        _amountError = 'Saldo kamu tidak mencukupi.';
        isValid = false;
      }
    });

    return isValid;
  }

  void _showConfirmation() {
    if (!_validateForm()) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _confirmationRow('Kategori', _selectedCategory!),
              const SizedBox(height: 10),
              _confirmationRow('Nominal', _formatRupiah(_amount)),
              const SizedBox(height: 10),
              _confirmationRow('Sisa saldo', _formatRupiah(_balance - _amount)),
              if (_notesController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _confirmationRow('Catatan', _notesController.text.trim()),
              ],
              const SizedBox(height: 16),
              const Text('Pastikan detail pembayaran sudah benar.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _submitPayment();
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );
  }

  Widget _confirmationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitPayment() async {
    setState(() {
      _isPaying = true;
    });

    try {
      final result = await PaymentService.createPayment(
        category: _categoryValues[_selectedCategory]!,
        amount: _amount,
        description: _notesController.text.trim(),
      );

      if (!mounted) return;

      final updatedBalance = result['balance'];

      if (updatedBalance is num) {
        _wallet = {...?_wallet, 'balance': updatedBalance};
      }

      setState(() {
        _isPaying = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Payment Berhasil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatRupiah(_amount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Kepada ${result['merchant']}'),
                const SizedBox(height: 8),
                Text('Sisa saldo: ${_formatRupiah(_balance)}'),
                const SizedBox(height: 8),
                Text(
                  'Ref: ${result['reference']}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isPaying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildWarning(String? message) {
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? errorText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo Saat Ini', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            _formatRupiah(_balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Kategori Pembayaran'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;

            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _selectCategory(category),
              selectedColor: const Color(0xFFEDE7F6),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? primaryPurple : textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(color: isSelected ? primaryPurple : borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }).toList(),
        ),
        _buildWarning(_categoryError),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Nominal Pembayaran'),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _onAmountChanged,
          decoration:
              _inputDecoration(
                hint: 'Masukkan nominal',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 15, right: 8),
                  child: Text(
                    'Rp',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                errorText: _amountError,
              ).copyWith(
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 45,
                  minHeight: 0,
                ),
              ),
        ),
        _buildWarning(_amountError),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Catatan (Opsional)'),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          maxLength: 150,
          decoration: _inputDecoration(hint: 'Tambahkan catatan pembayaran')
              .copyWith(counterStyle: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final remainingBalance = _balance - _amount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Payment',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nominal Pembayaran'),
              Text(
                _formatRupiah(_amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Biaya Admin'), const Text('Rp 0')],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sisa Saldo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatRupiah(remainingBalance < 0 ? 0 : remainingBalance),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pembayaran',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih kategori pembayaran, lalu masukkan '
            'nominal dan keterangan pembayaran.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          _buildBalanceCard(),
          const SizedBox(height: 28),

          _buildCategorySelector(),
          const SizedBox(height: 24),

          _buildAmountField(),
          const SizedBox(height: 24),

          _buildNotesField(),
          const SizedBox(height: 12),

          _buildSummary(),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isPaying ? null : _showConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isPaying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _buildPaymentForm(),
    );
  }
}
