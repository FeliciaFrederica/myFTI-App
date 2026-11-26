import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:myfti_app/src/features/wallet/services/wallet_service.dart';
import 'package:myfti_app/src/core/widgets/top_notice.dart';

import '../../notification/services/local_notification_service.dart';
import '../../transaction/pages/transaction_confirmation_page.dart';
import '../../transaction/pages/transaction_success_page.dart';
import '../../transaction/services/transaction_pin_flow.dart';
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
  static const Color cardColor = Color(0xFFEDE7F6);

  static const int minPayment = 10000;
  static const int maxNotesLength = 150;

  static const Map<String, String> _categoryValues = {
    'Alleyway': 'ALLEYWAY',
    'Print': 'PRINT',
    'Kantin': 'KANTIN',
    'Jukel & PO': 'JUKEL_PO',
    'Akademik': 'AKADEMIK',
  };

  static const Map<String, List<String>> _subcategoryOptions = {
    'KANTIN': ['Warmindo', 'Kantin Teknik', 'Kantin Cuweg'],
    'JUKEL_PO': ['Jukel DPM', 'PO BEM', 'PO DPM'],
    'AKADEMIK': ['BPP', 'SPP'],
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
  List<Map<String, dynamic>> _recipients = [];

  String? _selectedCategory;
  String? _selectedSubcategory;

  String? _categoryError;
  String? _merchantError;
  String? _subcategoryError;
  String? _amountError;
  String? _notesError;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isPaying = false;

  String? _loadErrorTitle;
  String? _loadErrorMessage;

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  int get _balance => (_wallet?['balance'] as num?)?.toInt() ?? 0;

  String? get _categoryValue => _categoryValues[_selectedCategory];

  List<String> get _availableSubcategories {
    if (_categoryValue == null) return [];
    return _subcategoryOptions[_categoryValue] ?? [];
  }

  String? get _selectedMerchantIdForCategory {
    if (_categoryValue == null) return null;

    for (final merchant in _recipients) {
      if (merchant['category'] == _categoryValue) {
        return merchant['id'] as String?;
      }
    }

    return null;
  }

  String? get _paymentDestination {
    return _selectedSubcategory ?? _selectedCategory;
  }

  // Pembayaran hanya bisa dilanjutkan jika data berhasil dimuat
  bool get _canContinuePayment {
    return _wallet != null &&
        _loadErrorTitle == null &&
        !_isRefreshing &&
        !_isPaying &&
        _notesController.text.length < maxNotesLength;
  }

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
    _loadData(showLoading: true);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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
  void _setLoadError(Object error) {
    final errorMessage = error.toString().toLowerCase();

    if (_isServerError(errorMessage)) {
      _loadErrorTitle = 'Layanan sedang bermasalah';
      _loadErrorMessage =
          'Server tidak merespons saat mengambil data pembayaran. '
          'Silakan coba lagi beberapa saat.';
    } else if (_isConnectionError(errorMessage)) {
      _loadErrorTitle = 'Koneksi internet bermasalah';
      _loadErrorMessage =
          'Periksa koneksi internet Anda, lalu coba muat ulang.';
    } else {
      _loadErrorTitle = 'Data pembayaran belum tersedia';
      _loadErrorMessage =
          'Terjadi kendala saat mengambil data pembayaran. '
          'Silakan coba lagi.';
    }
  }

  // Memuat saldo dan daftar merchant
  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _loadErrorTitle = null;
        _loadErrorMessage = null;
        _isRefreshing = false;
      });
    } else {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final wallet = await _walletService.getWallet();
      final recipients = await PaymentService.getRecipients();

      if (!mounted) return;

      setState(() {
        _wallet = wallet;
        _recipients = recipients;
        _loadErrorTitle = null;
        _loadErrorMessage = null;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _setLoadError(error);
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedSubcategory = null;

      _categoryError = null;
      _merchantError = null;
      _subcategoryError = null;
    });
  }

  // Memeriksa panjang catatan pembayaran
  void _onNotesChanged(String value) {
    setState(() {
      _notesError = value.length >= maxNotesLength
          ? 'Catatan sudah mencapai batas maksimal 150 karakter.'
          : null;
    });
  }

  // Memeriksa seluruh input pembayaran
  bool _validateForm() {
    bool isValid = true;

    setState(() {
      _categoryError = null;
      _merchantError = null;
      _subcategoryError = null;
      _amountError = null;
      _notesError = null;

      if (_selectedCategory == null) {
        _categoryError = 'Pilih kategori pembayaran.';
        isValid = false;
      }

      if (_selectedCategory != null && _selectedMerchantIdForCategory == null) {
        _merchantError = 'Merchant untuk kategori ini belum tersedia.';
        isValid = false;
      }

      if (_availableSubcategories.isNotEmpty && _selectedSubcategory == null) {
        _subcategoryError = 'Pilih subkategori pembayaran.';
        isValid = false;
      }

      if (_amount <= 0) {
        _amountError = 'Masukkan nominal pembayaran.';
        isValid = false;
      } else if (_amount < minPayment) {
        _amountError = 'Minimal pembayaran adalah Rp10.000.';
        isValid = false;
      }

      if (_notesController.text.length >= maxNotesLength) {
        _notesError = 'Catatan sudah mencapai batas maksimal 150 karakter.';
        isValid = false;
      }

      if (_loadErrorTitle != null || _wallet == null) {
        isValid = false;
      }
    });

    return isValid;
  }

  // Menampilkan konfirmasi pembayaran
  Future<void> _showConfirmation() async {
    if (!_canContinuePayment) return;
    if (!_validateForm()) return;

    // Memeriksa kecukupan saldo sebelum konfirmasi dan PIN
    if (_amount > _balance) {
      TopNotice.show(context, 'Saldo kamu tidak mencukupi.', success: false);
      return;
    }

    // Tutup keyboard sebelum dialog mengambil alih layar pada perangkat kecil.
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionConfirmationPage(
          title: 'Konfirmasi Pembayaran',
          amount: _amount,
          details: [
            MapEntry('Kategori', _selectedCategory!),
            MapEntry('Tujuan', _paymentDestination ?? '-'),
            MapEntry('Sisa saldo', _formatRupiah(_balance - _amount)),
            if (_notesController.text.trim().isNotEmpty)
              MapEntry('Catatan', _notesController.text.trim()),
          ],
          message: 'Pastikan detail pembayaran sudah benar.',
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _submitPayment();
    }
  }

  Widget _buildSubcategorySelector() {
    final options = _availableSubcategories;

    if (_selectedCategory == null || options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pilih Subkategori'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((subcategory) {
            final isSelected = _selectedSubcategory == subcategory;

            return ChoiceChip(
              label: Text(subcategory),
              selected: isSelected,
              onSelected: _isPaying
                  ? null
                  : (_) {
                      setState(() {
                        _selectedSubcategory = subcategory;
                        _subcategoryError = null;
                      });
                    },
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
        _buildWarning(_subcategoryError),
      ],
    );
  }

  // Memproses pembayaran dengan verifikasi PIN transaksi
  Future<void> _submitPayment() async {
    if (!_canContinuePayment) return;

    final merchantId = _selectedMerchantIdForCategory;

    if (merchantId == null) {
      TopNotice.show(
        context,
        'Merchant untuk kategori ini belum tersedia.',
        success: false,
      );
      return;
    }

    // Memastikan nominal memenuhi batas minimum sebelum PIN
    if (_amount <= 0) {
      setState(() {
        _amountError = 'Masukkan nominal pembayaran.';
      });
      return;
    }

    if (_amount < minPayment) {
      setState(() {
        _amountError = 'Minimal pembayaran adalah Rp10.000.';
      });
      return;
    }

    // Memeriksa kecukupan saldo sebelum verifikasi PIN
    if (_amount > _balance) {
      TopNotice.show(context, 'Saldo kamu tidak mencukupi.', success: false);
      return;
    }

    if (_notesController.text.length >= maxNotesLength) {
      setState(() {
        _notesError = 'Catatan sudah mencapai batas maksimal 150 karakter.';
      });
      return;
    }

    setState(() {
      _isPaying = true;
    });

    try {
      final pin = await TransactionPinFlow.requestPin(context);

      if (!mounted || pin == null) return;

      final result = await PaymentService.createPayment(
        merchantId: merchantId,
        amount: _amount,
        description: _notesController.text.trim(),
        subcategory: _selectedSubcategory,
        pin: pin,
      );

      if (!mounted) return;

      final updatedBalance = result['balance'];

      if (updatedBalance is num) {
        setState(() {
          _wallet = {...?_wallet, 'balance': updatedBalance};
        });
      }

      LocalNotificationService.checkNow();

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TransactionSuccessPage(
            title: 'Pembayaran Berhasil',
            amount: _amount,
            recipient: result['merchant']?.toString() ?? '-',
            reference: result['reference']?.toString() ?? '-',
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      final errorMessage = error.toString();
      final lowerError = errorMessage.toLowerCase();

      final message =
          _isConnectionError(lowerError) ||
              lowerError.contains('connection refused')
          ? 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.'
          : errorMessage
                .replaceFirst('Exception: ', '')
                .replaceAll('Payment successful', 'Pembayaran berhasil')
                .replaceAll('Insufficient balance', 'Saldo tidak mencukupi')
                .replaceAll('Merchant not found', 'Merchant tidak ditemukan')
                .replaceAll(
                  'Invalid payment amount',
                  'Nominal pembayaran tidak valid',
                )
                .replaceAll(
                  'Pilih submerchant pembayaran yang valid.',
                  'Pilih subkategori pembayaran yang valid.',
                );

      TopNotice.show(context, message, success: false);
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  // Menampilkan pesan peringatan input, sejajar dari kiri
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

  // Mengatur tampilan kolom input
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
          const Text('Saldo Saat Ini', style: TextStyle(color: Colors.white70)),
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
                            _isRefreshing
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
                  onPressed: _isRefreshing ? null : () => _loadData(),
                  icon: _isRefreshing
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
                  tooltip: 'Muat ulang data',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
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
              onSelected: _isPaying ? null : (_) => _selectCategory(category),
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
        _buildWarning(_merchantError),
      ],
    );
  }

  // Kolom nominal pembayaran
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Nominal Pembayaran'),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          enabled: !_isPaying,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration:
              _inputDecoration(
                hint: 'Masukkan nominal pembayaran',
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
              ).copyWith(
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
      ],
    );
  }

  // Kolom catatan pembayaran
  Widget _buildNotesField() {
    final hasNotesError = _notesError != null;
    final currentLength = _notesController.text.length;
    final isAtLimit = currentLength >= maxNotesLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle('Catatan (Opsional)'),
            Text(
              '$currentLength/$maxNotesLength',
              style: TextStyle(
                fontSize: 11,
                color: hasNotesError ? Colors.red : Colors.grey,
                fontWeight: isAtLimit ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          enabled: !_isPaying,
          maxLines: 2,
          maxLength: maxNotesLength,
          onChanged: _onNotesChanged,
          decoration: _inputDecoration(hint: 'Tambahkan catatan pembayaran')
              .copyWith(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: hasNotesError ? Colors.red : borderColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: hasNotesError ? Colors.red : borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: hasNotesError ? Colors.red : primaryPurple,
                    width: 1.5,
                  ),
                ),
              ),
        ),
        _buildWarning(_notesError),
      ],
    );
  }

  Widget _buildSummary() {
    final remainingBalance = _balance - _amount;

    return Container(
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
            'Ringkasan Pembayaran',
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

  // Form utama pembayaran
  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 28),

          _buildCategorySelector(),

          if (_selectedCategory != null &&
              _availableSubcategories.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSubcategorySelector(),
          ],

          const SizedBox(height: 24),
          _buildAmountField(),
          const SizedBox(height: 20),

          _buildNotesField(),
          const SizedBox(height: 24),

          _buildSummary(),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canContinuePayment ? _showConfirmation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
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
          'Pembayaran',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryPurple),
              )
            : _buildPaymentForm(),
      ),
    );
  }
}
