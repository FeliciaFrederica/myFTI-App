import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfti_app/src/core/widgets/top_notice.dart';

import '../../notification/services/local_notification_service.dart';
import '../../wallet/services/wallet_service.dart';
import '../../transaction/pages/transaction_confirmation_page.dart';
import '../../transaction/pages/transaction_success_page.dart';
import '../../transaction/services/transaction_pin_flow.dart';

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

  Map<String, dynamic>? _wallet;

  bool _isWalletLoading = true;
  bool _isRefreshingWallet = false;
  bool _isLoading = false;

  String? _loadErrorTitle;
  String? _loadErrorMessage;

  final List<int> _amountOptions = [50000, 100000, 200000, 500000];

  int? _selectedAmount;
  String? _amountError;

  int get _amount {
    return int.tryParse(_amountController.text) ?? 0;
  }

  int get _balance => (_wallet?['balance'] as num?)?.toInt() ?? 0;

  // Memeriksa apakah tombol lanjutkan dapat digunakan
  bool get _canContinueTopUp {
    return _wallet != null &&
        _loadErrorTitle == null &&
        !_isWalletLoading &&
        !_isRefreshingWallet &&
        !_isLoading;
  }

  @override
  void initState() {
    super.initState();
    _loadWallet(showPageLoading: true);
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

  // Menentukan pesan error saat proses isi saldo
  String _getTopUpErrorMessage(Object error) {
    final errorMessage = error.toString().toLowerCase();

    if (_isServerError(errorMessage)) {
      return 'Layanan sedang bermasalah. '
          'Server tidak merespons saat memproses isi saldo. '
          'Silakan coba lagi beberapa saat.';
    } else if (_isConnectionError(errorMessage)) {
      return 'Koneksi internet bermasalah. '
          'Periksa koneksi internet Anda, lalu coba lagi.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  // Memuat saldo wallet
  Future<void> _loadWallet({bool showPageLoading = false}) async {
    if (showPageLoading) {
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

  // Mengubah nominal menjadi format Rupiah
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

      final amount = int.tryParse(value) ?? 0;

      if (value.isEmpty) {
        _amountError = null;
      } else if (amount < 10000) {
        _amountError = 'Minimal isi saldo adalah Rp 10.000.';
      } else {
        _amountError = null;
      }
    });
  }

  // Menampilkan konfirmasi isi saldo
  Future<void> _showConfirmation() async {
    if (!_canContinueTopUp) return;

    final amount = _selectedAmount ?? _amount;

    if (amount <= 0) {
      setState(() {
        _amountError = 'Nominal wajib diisi.';
      });
      return;
    }

    if (amount < 10000) {
      setState(() {
        _amountError = 'Minimal isi saldo adalah Rp 10.000.';
      });
      return;
    }

    setState(() {
      _amountError = null;
    });

    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionConfirmationPage(
          title: 'Konfirmasi Isi Saldo',
          amount: amount,
          details: [
            MapEntry('Saldo saat ini', _formatRupiah(_balance)),
            MapEntry(
              'Saldo setelah isi saldo',
              _formatRupiah(_balance + amount),
            ),
          ],
          message: 'Pastikan nominal isi saldo sudah benar.',
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _submitTopUp(amount);
    }
  }

  // Memproses top up menggunakan PIN transaksi
  Future<void> _submitTopUp(int amount) async {
    final pin = await TransactionPinFlow.requestPin(context);

    if (!mounted || pin == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _walletService.topUp(amount, pin);

      if (!mounted) return;

      LocalNotificationService.checkNow();

      final transaction = result['transaction'];
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TransactionSuccessPage(
            title: 'Isi Saldo Berhasil',
            amount: amount,
            recipient: 'Saldo myFTI',
            reference: transaction is Map
                ? transaction['reference']?.toString() ?? '-'
                : '-',
            recipientLabel: 'Masuk ke',
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      TopNotice.show(context, _getTopUpErrorMessage(error), success: false);
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

  // Menampilkan kartu saldo wallet
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
                        _wallet != null
                            ? _formatRupiah(_balance)
                            : 'Memuat saldo...',
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

  // Form utama top up
  Widget _buildTopUpForm() {
    final displayedAmount = _selectedAmount ?? _amount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saldo tersedia
          _buildBalanceCard(),

          const SizedBox(height: 28),

          // Pilihan nominal
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final amount = _amountOptions[index];
              final isSelected = _selectedAmount == amount;

              return OutlinedButton(
                onPressed: _isLoading ? null : () => _selectAmount(amount),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFFF3EEFC)
                      : Colors.white,
                  foregroundColor: primaryPurple,
                  side: BorderSide(
                    color: isSelected ? primaryPurple : const Color(0xFFD1C4E9),
                    width: isSelected ? 1.5 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _formatRupiah(amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Nominal manual
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
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                borderSide: const BorderSide(color: Color(0xFFD1C4E9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD1C4E9)),
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
            ),
          ),

          const SizedBox(height: 24),

          // Ringkasan
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
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol konfirmasi
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canContinueTopUp ? _showConfirmation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Isi Saldo',
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
            : _buildTopUpForm(),
      ),
    );
  }
}
