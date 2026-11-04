import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfti_app/src/features/wallet/services/wallet_service.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color backgroundColor = Color(0xFFF8F6FC);
  static const Color textColor = Color(0xFF2D1B46);

  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();

  bool _isLoading = false;
  // menunggu token tersedia
  final String token = 'YOUR_AUTH_TOKEN';
  final List<int> _amountOptions = [
    50000,
    100000,
    200000,
    500000,
  ];

  int? _selectedAmount;
  String? _amountError;

  int get _amount {
    return int.tryParse(_amountController.text) ?? 0;
  }

  String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  void _selectAmount(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.clear();
      _amountError = null;
    });
  }

  void _onCustomAmountChanged(String value) {
    setState(() {
      _selectedAmount = null;

      if (_amountError != null) {
        final amount = int.tryParse(value) ?? 0;

        if (value.isEmpty) {
          _amountError = 'Nominal wajib diisi.';
        } else if (amount < 10000) {
          _amountError = 'Minimal Top Up adalah Rp 10.000.';
        } else {
          _amountError = null;
        }
      }
    });
  }

  void _showConfirmation() {
    final amount = _selectedAmount ?? _amount;

      if (amount <= 0) {
        setState(() {
          _amountError = 'Nominal wajib diisi.';
        });
        return;
      }

    if (amount < 10000) {
      setState(() {
        _amountError = 'Minimal Top Up adalah Rp 10.000.';
      });
      return;
    }

    setState(() {
      _amountError = null;
    });

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Top Up'),
          content: Text(
            'Kamu akan melakukan Top Up sebesar '
            '${_formatRupiah(amount)}.\n\n'
            'Lanjutkan Top Up?',
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
                _submitTopUp(amount, token);
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitTopUp(int amount, String token) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _walletService.topUp(token, amount);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Top Up ${_formatRupiah(amount)} berhasil!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      print('Updated wallet: ${result['wallet']}');
      print('Transaction: ${result['transaction']}');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedAmount = _selectedAmount ?? _amount;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Top Up',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Isi Saldo Wallet',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pilih nominal saldo yang ingin kamu tambahkan '
              'ke myFTI Wallet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            // Current balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Saat Ini',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rp 1.500.000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Amount options
            const Text(
              'Pilih Nominal',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _amountOptions.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, index) {
                final amount = _amountOptions[index];
                final isSelected = _selectedAmount == amount;

                return OutlinedButton(
                  onPressed: () => _selectAmount(amount),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                      ? const Color(0xFFF3EEFC)
                      : Colors.white,
                  foregroundColor: primaryPurple,
                  side: BorderSide(
                    color: isSelected
                        ? primaryPurple
                        : const Color(0xFFD1C4E9),
                    width: isSelected ? 1.5 : 1,
                  ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _formatRupiah(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Custom amount
            const Text(
              'Atau Masukkan Nominal Lain',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: _onCustomAmountChanged,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: 'Masukkan nominal',
                errorText: _amountError,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFD1C4E9),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFD1C4E9),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: primaryPurple,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.red,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Summary
            Container(
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
                    'Ringkasan Top Up',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nominal Top Up'),
                      Text(
                        _formatRupiah(displayedAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Biaya Admin'),
                      Text('Rp 0'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Confirmation button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
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
      ),
    );
  }
}