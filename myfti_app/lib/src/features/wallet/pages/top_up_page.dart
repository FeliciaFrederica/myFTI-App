import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfti_app/src/features/wallet/services/wallet_service.dart';
import 'package:myfti_app/src/core/widgets/top_notice.dart';

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

  late Future<Map<String, dynamic>> _walletFuture;

  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  void _loadWallet() {
    _walletFuture = _walletService.getWallet();
  }

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
          _amountError = 'Minimal Saldo adalah Rp 10.000.';
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
        _amountError = 'Minimal Saldo adalah Rp 10.000.';
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
          backgroundColor: const Color(0xFFF3EEFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Konfirmasi Isi Saldo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: 'Kamu akan menambahkan saldo sebesar ',
                ),
                TextSpan(
                  text: _formatRupiah(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _submitTopUp(amount);
                },
                child: const Text(
                  'Konfirmasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitTopUp(int amount) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _walletService.topUp(amount);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);

      Navigator.pop(context, true);

      TopNotice.show(
        context, 
        'Isi Saldo ${_formatRupiah(amount)} berhasil!',
        success: true,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
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
          'Isi Saldo',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current balance
              FutureBuilder<Map<String, dynamic>>(
                future: _walletFuture,
                builder: (context, snapshot) {
                  String balanceText = 'Memuat saldo...';

                  if (snapshot.hasData) {
                    final balance = (snapshot.data!['balance'] as num).toInt();
                    balanceText = _formatRupiah(balance);
                  } else if (snapshot.hasError) {
                    balanceText = 'Gagal memuat saldo';
                  }

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
                        const Text(
                          'Saldo Tersedia',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          balanceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (snapshot.hasError)
                          TextButton(
                            onPressed: () {
                              setState(_loadWallet);
                            },
                            child: const Text(
                              'Coba Lagi',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  );
                },
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

              const SizedBox(height: 16),

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
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 8),
                    child: Text(
                      'Rp ',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minHeight: 0,
                    minWidth: 0,
                  ),
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
                      'Ringkasan Isi Saldo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nominal Isi Saldo'),
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
                          'Lanjutkan',
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
      ),
    );
  }
}