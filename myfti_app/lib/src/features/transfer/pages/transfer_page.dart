import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfti_app/src/core/widgets/top_notice.dart';

import '../../wallet/services/wallet_service.dart';
import '../services/transfer_service.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color backgroundColor = Color(0xFFF8F6FC);
  static const Color textColor = Color(0xFF2D1B46);
  static const Color borderColor = Color(0xFFD1C4E9);
  static const Color cardColor = Color(0xFFEDE7F6);

  final TransferService _transferService = TransferService();
  final WalletService _walletService = WalletService();

  final TextEditingController _walletIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();

  late Future<Map<String, dynamic>> _walletFuture;

  Map<String, dynamic>? _recipient;

  bool _isSearching = false;
  bool _isTransferring = false;

  String? _walletIdError;
  String? _amountError;

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  void _loadWallet() {
    _walletFuture = _walletService.getWallet();
  }

  @override
  void dispose() {
    _walletIdController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  // Memeriksa perubahan ID penerima
  void _onWalletIdChanged(String value) {
    setState(() {
      _recipient = null;

      if (_walletIdError != null) {
        _walletIdError = value.trim().isEmpty
            ? 'ID Dompet penerima wajib diisi.'
            : null;
      }
    });
  }

  // Memeriksa perubahan nominal transfer
  void _onAmountChanged(String value) {
    final amount = int.tryParse(value) ?? 0;

    setState(() {
      if (value.trim().isEmpty) {
        _amountError = null;
      } else if (amount < TransferService.minTransfer) {
        _amountError = 'Minimal transfer adalah Rp10.000.';
      } else {
        _amountError = null;
      }
    });
  }

  // Mencari penerima berdasarkan ID Dompet
  Future<void> _searchRecipient() async {
    final walletId = _walletIdController.text.trim();

    if (walletId.isEmpty) {
      setState(() {
        _walletIdError = 'ID Dompet penerima wajib diisi.';
        _recipient = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _walletIdError = null;
      _recipient = null;
    });

    try {
      final recipient = await _transferService.getRecipient(walletId);

      if (!mounted) return;

      setState(() {
        _recipient = recipient;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _walletIdError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Memeriksa nominal dan menampilkan konfirmasi transfer
  Future<void> _showConfirmation() async {
    if (_recipient == null) {
      setState(() {
        _walletIdError = _walletIdController.text.trim().isEmpty
            ? 'ID Dompet penerima wajib diisi.'
            : 'Periksa ID Dompet penerima terlebih dahulu.';
      });
      return;
    }

    if (_amount <= 0) {
      setState(() {
        _amountError = 'Nominal transfer wajib diisi.';
      });
      return;
    }

    if (_amount < TransferService.minTransfer) {
      setState(() {
        _amountError = 'Minimal transfer adalah Rp10.000.';
      });
      return;
    }

    setState(() {
      _walletIdError = null;
      _amountError = null;
    });

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF3EEFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Konfirmasi Transfer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kamu akan mengirim saldo kepada:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _recipient?['fullName']?.toString() ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'ID Dompet: ${_recipient?['walletId'] ?? '-'}',
              ),
              const SizedBox(height: 16),
              const Text('Nominal Transfer'),
              const SizedBox(height: 4),
              Text(
                _formatRupiah(_amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                onPressed: () => Navigator.pop(dialogContext, false),
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

    if (confirmed == true && mounted) {
      await _submitTransfer();
    }
  }

  // Memproses transfer dan kembali ke halaman sebelumnya jika berhasil
  Future<void> _submitTransfer() async {
    setState(() {
      _isTransferring = true;
    });

    try {
      await _transferService.transfer(
        recipientWalletId: _walletIdController.text.trim(),
        amount: _amount,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      TopNotice.show(
        context,
        'Transfer berhasil dilakukan!',
        success: true,
      );
    } catch (error) {
      if (!mounted) return;

      TopNotice.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTransferring = false;
        });
      }
    }
  }

  // Mengatur tampilan kolom input
  InputDecoration _inputDecoration({
    required String hintText,
    String? errorText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
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
        borderSide: const BorderSide(
          color: primaryPurple,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedAmount = _amount;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Transfer',
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
              // Saldo tersedia
              FutureBuilder<Map<String, dynamic>>(
                future: _walletFuture,
                builder: (context, snapshot) {
                  String balanceText = 'Memuat saldo...';

                  if (snapshot.hasData) {
                    final balance =
                        (snapshot.data!['balance'] as num).toInt();

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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                balanceText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: snapshot.hasError ? 22 : 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (snapshot.hasError)
                              IconButton(
                                onPressed: () {
                                  setState(_loadWallet);
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                tooltip: 'Muat ulang saldo',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              const Text(
                'Informasi Penerima',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              // Kolom ID Dompet dan tombol pencarian
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _walletIdController,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: _onWalletIdChanged,
                      decoration: _inputDecoration(
                        hintText: 'Masukkan ID Penerima',
                        errorText: _walletIdError,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: primaryPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: OutlinedButton(
                        onPressed:
                            _isSearching ? null : _searchRecipient,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryPurple,
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: primaryPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryPurple,
                                ),
                              )
                            : const Icon(Icons.search, size: 25),
                      ),
                    ),
                  ),
                ],
              ),

              if (_recipient != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          color: primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recipient!['fullName']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID Dompet: ${_recipient!['walletId'] ?? '-'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              const Text(
                'Nominal Transfer',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: _onAmountChanged,
                decoration: _inputDecoration(
                  hintText: 'Masukkan nominal transfer',
                ).copyWith(
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
                  errorText: _amountError,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Deskripsi (Opsional)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),

              // Kolom deskripsi
              TextField(
                controller: _descriptionController,
                maxLength: 100,
                maxLines: 3,
                decoration: _inputDecoration(
                  hintText: 'Tambahkan catatan transfer',
                ).copyWith(
                  alignLabelWithHint: true,
                  counterText: '',
                ),
              ),

              const SizedBox(height: 24),

              // Ringkasan transfer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Transfer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nominal Transfer'),
                        Text(
                          _formatRupiah(displayedAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tombol konfirmasi
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isTransferring ? null : _showConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isTransferring
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
