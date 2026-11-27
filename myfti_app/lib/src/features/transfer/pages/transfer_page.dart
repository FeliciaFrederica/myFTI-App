import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfti_app/src/core/widgets/top_notice.dart';

import '../../notification/services/local_notification_service.dart';
import '../../wallet/services/wallet_service.dart';
import '../../transaction/pages/transaction_confirmation_page.dart';
import '../../transaction/pages/transaction_detail_page.dart';
import '../../transaction/services/transaction_pin_flow.dart';
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

  static const int maxDescriptionLength = 150;

  final TransferService _transferService = TransferService();
  final WalletService _walletService = WalletService();

  // Controller untuk input transfer
  final TextEditingController _walletIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Data saldo dan penerima
  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _recipient;

  // Status proses halaman
  bool _isWalletLoading = true;
  bool _isRefreshingWallet = false;
  bool _isSearching = false;
  bool _isTransferring = false;

  // Pesan error pengambilan saldo
  String? _loadErrorTitle;
  String? _loadErrorMessage;

  // Pesan validasi input
  String? _walletIdError;
  String? _amountError;
  String? _descriptionError;

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  int get _balance => (_wallet?['balance'] as num?)?.toInt() ?? 0;

  // Transfer hanya bisa dilanjutkan setelah saldo tersedia dan input valid
  bool get _canContinueTransfer {
    return _wallet != null &&
        _loadErrorTitle == null &&
        _descriptionError == null &&
        !_isRefreshingWallet &&
        !_isTransferring;
  }

  @override
  void initState() {
    super.initState();
    _loadWallet(showLoading: true);
  }

  // Memeriksa apakah error berasal dari koneksi
  bool _isConnectionError(String message) {
    const keywords = [
      'failed host lookup',
      'network is unreachable',
      'no address associated',
      'no internet',
      'network request failed',
      'failed to fetch',
      'xmlhttprequest error',
      'socketexception',
      'clientexception',
      'connection error',
    ];

    return keywords.any(message.contains);
  }

  // Memeriksa apakah server tidak merespons
  bool _isServerError(String message) {
    const keywords = [
      'connection refused',
      'connection reset',
      'connection closed',
      'handshakeexception',
      'timed out',
      'timeout',
      'internal server error',
      'bad gateway',
      'service unavailable',
      'gateway timeout',
      'status code 500',
      'status code 502',
      'status code 503',
      'status code 504',
    ];

    return keywords.any(message.contains);
  }

  // Menentukan pesan berdasarkan penyebab kegagalan API
  void _setWalletLoadError(Object error) {
    final errorMessage = error.toString().toLowerCase();

    if (_isServerError(errorMessage)) {
      _loadErrorTitle = 'Layanan sedang bermasalah';
      _loadErrorMessage =
          'Server tidak merespons saat mengambil saldo. '
          'Silakan coba lagi beberapa saat.';
    } else if (_isConnectionError(errorMessage)) {
      _loadErrorTitle = 'Koneksi internet bermasalah';
      _loadErrorMessage =
          'Periksa koneksi internet Anda, lalu coba muat ulang.';
    } else {
      _loadErrorTitle = 'Saldo belum tersedia';
      _loadErrorMessage =
          'Terjadi kendala saat mengambil data saldo. '
          'Silakan coba lagi.';
    }
  }

  // Memuat saldo wallet
  Future<void> _loadWallet({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _isWalletLoading = true;
        _loadErrorTitle = null;
        _loadErrorMessage = null;
        _isRefreshingWallet = false;
      });
    } else {
      setState(() {
        _isRefreshingWallet = true;
      });
    }

    try {
      final wallet = await _walletService.getWallet();

      if (!mounted) return;

      setState(() {
        _wallet = wallet;
        _loadErrorTitle = null;
        _loadErrorMessage = null;
        _isWalletLoading = false;
        _isRefreshingWallet = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _setWalletLoadError(error);
        _isWalletLoading = false;
        _isRefreshingWallet = false;
      });
    }
  }

  @override
  void dispose() {
    _walletIdController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Mengubah nominal menjadi format Rupiah
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

  // Memeriksa panjang catatan transfer
  void _onDescriptionChanged(String value) {
    setState(() {
      _descriptionError = value.length >= maxDescriptionLength
          ? 'Catatan sudah mencapai batas maksimal 150 karakter.'
          : null;
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
    if (!_canContinueTransfer) return;

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

    // Memeriksa kecukupan saldo sebelum konfirmasi dan verifikasi PIN
    if (_amount > _balance) {
      TopNotice.show(context, 'Saldo kamu tidak mencukupi.', success: false);
      return;
    }

    setState(() {
      _walletIdError = null;
      _amountError = null;
    });

    // Tutup keyboard sebelum dialog mengambil alih layar pada perangkat kecil.
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionConfirmationPage(
          title: 'Konfirmasi Transfer',
          amount: _amount,
          details: [
            MapEntry('Penerima', _recipient?['fullName']?.toString() ?? '-'),
            MapEntry('ID Dompet', _recipient?['walletId']?.toString() ?? '-'),
          ],
          message: 'Pastikan informasi transfer sudah benar.',
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _submitTransfer();
    }
  }

  // Memproses transfer dengan verifikasi PIN transaksi
  Future<void> _submitTransfer() async {
    if (!_canContinueTransfer || _recipient == null) return;

    setState(() {
      _isTransferring = true;
    });

    try {
      // Meminta PIN transaksi melalui alur PIN yang digunakan Payment
      final pin = await TransactionPinFlow.requestPin(context);

      if (!mounted || pin == null) return;

      // Mengirim data transfer beserta PIN ke backend
      final result = await _transferService.transfer(
        recipientWalletId: _walletIdController.text.trim(),
        amount: _amount,
        description: _descriptionController.text.trim(),
        pin: pin,
      );

      if (!mounted) return;

      LocalNotificationService.checkNow();

      final transactions = result['transactions'];
      final senderTransaction = transactions is Map
          ? transactions['sender']
          : null;
      final transactionId = senderTransaction is Map
          ? senderTransaction['id']?.toString()
          : null;

      if (transactionId == null || transactionId.isEmpty) {
        throw Exception('ID transaksi transfer tidak ditemukan.');
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TransactionDetailPage(transactionId: transactionId),
        ),
      );

      if (!mounted) return;
      TopNotice.show(context, 'Transfer berhasil dilakukan!', success: true);
      Navigator.pop(context, true);
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  // Menampilkan pesan peringatan input
  Widget _buildWarning(String? message) {
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  // Kartu saldo tersedia
  Widget _buildBalanceCard() {
    final hasError = _loadErrorTitle != null;

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
          const Text('Saldo Tersedia', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: hasError
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _loadErrorTitle!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isRefreshingWallet
                                ? 'Sedang mencoba memuat ulang...'
                                : _loadErrorMessage!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _formatRupiah(_balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (hasError)
                IconButton(
                  onPressed: _isRefreshingWallet ? null : () => _loadWallet(),
                  icon: _isRefreshingWallet
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
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
  }

  // Kolom catatan transfer
  Widget _buildDescriptionField() {
    final currentLength = _descriptionController.text.length;
    final isAtLimit = currentLength >= maxDescriptionLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul dan penghitung karakter dalam satu baris
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Catatan (Opsional)',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              '$currentLength/$maxDescriptionLength',
              style: TextStyle(
                fontSize: 11,
                color: isAtLimit ? Colors.red : Colors.grey,
                fontWeight: isAtLimit ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          enabled: !_isTransferring,
          maxLines: 2,
          maxLength: maxDescriptionLength,
          onChanged: _onDescriptionChanged,

          // Menyembunyikan counter bawaan Flutter
          buildCounter:
              (
                context, {
                required int currentLength,
                required bool isFocused,
                int? maxLength,
              }) {
                return null;
              },

          decoration: _inputDecoration(hintText: 'Tambahkan catatan transfer')
              .copyWith(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isAtLimit ? Colors.red : borderColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isAtLimit ? Colors.red : borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isAtLimit ? Colors.red : primaryPurple,
                    width: 1.5,
                  ),
                ),
              ),
        ),
        _buildWarning(_descriptionError),
      ],
    );
  }

  // Form utama transfer
  Widget _buildTransferForm() {
    final displayedAmount = _amount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _walletIdController,
                      enabled: !_isTransferring,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: _onWalletIdChanged,
                      decoration:
                          _inputDecoration(
                            hintText: 'Masukkan ID Penerima',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: primaryPurple,
                            ),
                          ).copyWith(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _walletIdError != null
                                    ? Colors.red
                                    : borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _walletIdError != null
                                    ? Colors.red
                                    : borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _walletIdError != null
                                    ? Colors.red
                                    : primaryPurple,
                                width: 1.5,
                              ),
                            ),
                          ),
                    ),
                    if (_walletIdError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _walletIdError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _isSearching || _isTransferring
                        ? null
                        : _searchRecipient,
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
                    child: Icon(Icons.person, color: primaryPurple),
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
                  const Icon(Icons.check_circle, color: Colors.green),
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
            enabled: !_isTransferring,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onAmountChanged,
            decoration: _inputDecoration(hintText: 'Masukkan nominal transfer')
                .copyWith(
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amountError != null ? Colors.red : borderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amountError != null ? Colors.red : borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amountError != null ? Colors.red : primaryPurple,
                      width: 1.5,
                    ),
                  ),
                ),
          ),

          if (_amountError != null) ...[
            const SizedBox(height: 6),
            Text(
              _amountError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],

          const SizedBox(height: 20),

          _buildDescriptionField(),

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
              onPressed: _canContinueTransfer ? _showConfirmation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Transfer',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: _isWalletLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryPurple),
              )
            : _buildTransferForm(),
      ),
    );
  }
}
