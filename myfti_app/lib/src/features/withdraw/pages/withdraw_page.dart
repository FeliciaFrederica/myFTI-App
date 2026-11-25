import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfti_app/src/core/widgets/top_notice.dart';

import '../../wallet/services/wallet_service.dart';
import '../../transaction/services/transaction_pin_flow.dart';
import '../../notification/services/local_notification_service.dart';
import '../services/withdraw_service.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color secondaryPurple = Color(0xFF9575CD);
  static const Color backgroundColor = Color(0xFFF8F6FC);
  static const Color textColor = Color(0xFF2D1B46);
  static const Color borderColor = Color(0xFFD1C4E9);
  static const Color cardColor = Color(0xFFEDE7F6);

  static const Map<String, String> _banks = {
    'ABC': 'ABC',
    'MANDIRIW': 'Mandiriw',
    'BNN': 'BNN',
  };

  final WalletService _walletService = WalletService();
  final WithdrawService _withdrawService = WithdrawService();

  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _amountController =
      TextEditingController();

  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _savedAccounts = [];

  String? _selectedBankAccountId;
  String? _selectedBankCode = 'ABC';

  bool _useSavedAccount = false;
  bool _saveAccount = false;

  bool _isLoading = true;
  bool _isRefreshingWallet = false;
  bool _isWithdrawing = false;

  String? _loadErrorTitle;
  String? _loadErrorMessage;
  String? _accountError;
  String? _amountError;
  String? _savedAccountError;

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  int get _balance => (_wallet?['balance'] as num?)?.toInt() ?? 0;

  String get _selectedBankName => _banks[_selectedBankCode] ?? '-';

  // Memeriksa apakah tombol lanjutkan dapat digunakan
  bool get _canContinueWithdraw {
    return _wallet != null &&
        _loadErrorTitle == null &&
        !_isLoading &&
        !_isRefreshingWallet &&
        !_isWithdrawing;
  }

  String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  String _bankName(String code) {
    return _banks[code] ?? code;
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;

    final lastDigits = accountNumber.substring(
      accountNumber.length - 4,
    );

    return '${'*' * (accountNumber.length - 4)}$lastDigits';
  }

  @override
  void initState() {
    super.initState();
    _loadData(showPageLoading: true);
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
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
          'Server tidak merespons saat mengambil data. '
          'Silakan coba lagi beberapa saat.';
    } else if (_isConnectionError(errorMessage)) {
      _loadErrorTitle = 'Koneksi internet bermasalah';
      _loadErrorMessage =
          'Periksa koneksi internet Anda, lalu coba muat ulang.';
    } else {
      _loadErrorTitle = 'Data belum tersedia';
      _loadErrorMessage =
          'Terjadi kendala saat mengambil data. '
          'Silakan coba lagi.';
    }
  }

  // Mengambil data wallet dan rekening tersimpan
  Future<void> _loadData({bool showPageLoading = false}) async {
    if (showPageLoading) {
      setState(() {
        _isLoading = true;
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
      final accounts = await _withdrawService.getSavedBankAccounts();

      if (!mounted) return;

      setState(() {
        _wallet = wallet;
        _savedAccounts = accounts;

        if (accounts.isNotEmpty) {
          if (_selectedBankAccountId == null ||
              !accounts.any(
                (account) =>
                    account['id']?.toString() ==
                    _selectedBankAccountId,
              )) {
            _selectedBankAccountId =
                accounts.first['id']?.toString();
          }

          _useSavedAccount = true;
        } else {
          _useSavedAccount = false;
          _selectedBankAccountId = null;
        }

        _loadErrorTitle = null;
        _loadErrorMessage = null;
        _isLoading = false;
        _isRefreshingWallet = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _setLoadError(error);
        _isLoading = false;
        _isRefreshingWallet = false;
      });
    }
  }

  // Memeriksa perubahan nomor rekening
  void _onAccountNumberChanged(String value) {
    setState(() {
      if (_accountError != null) {
        if (value.isEmpty) {
          _accountError = null;
        } else if (!RegExp(r'^\d{10,16}$').hasMatch(value)) {
          _accountError =
              'Nomor rekening harus terdiri dari 10–16 digit.';
        } else {
          _accountError = null;
        }
      }
    });
  }

  // Memeriksa perubahan nominal
  void _onAmountChanged(String value) {
    final amount = int.tryParse(value) ?? 0;

    setState(() {
      if (value.trim().isEmpty) {
        _amountError = null;
      } else if (amount < WithdrawService.minWithdraw) {
        _amountError = 'Minimal penarikan saldo adalah Rp10.000.';
      } else {
        _amountError = null;
      }
    });
  }

  // Mengatur pilihan rekening
  void _selectAccountType(bool useSavedAccount) {
    setState(() {
      _useSavedAccount = useSavedAccount;
      _accountError = null;
      _savedAccountError = null;
    });
  }

  // Memvalidasi form withdraw
  bool _validateForm() {
    if (!_canContinueWithdraw) return false;

    bool isValid = true;

    setState(() {
      _accountError = null;
      _amountError = null;
      _savedAccountError = null;

      if (_useSavedAccount) {
        if (_selectedBankAccountId == null ||
            !_savedAccounts.any(
              (account) =>
                  account['id']?.toString() ==
                  _selectedBankAccountId,
            )) {
          _savedAccountError =
              'Pilih rekening tujuan terlebih dahulu.';
          isValid = false;
        }
      } else {
        final accountNumber =
            _accountNumberController.text.trim();

        if (_selectedBankCode == null ||
            !_banks.containsKey(_selectedBankCode)) {
          _accountError = 'Pilih bank tujuan terlebih dahulu.';
          isValid = false;
        } else if (!RegExp(r'^\d{10,16}$')
            .hasMatch(accountNumber)) {
          _accountError =
              'Nomor rekening harus terdiri dari 10–16 digit.';
          isValid = false;
        }
      }

      if (_amount <= 0) {
        _amountError = 'Masukkan nominal withdraw.';
        isValid = false;
      } else if (_amount < WithdrawService.minWithdraw) {
        _amountError = 'Minimal penarikan saldo adalah Rp10.000.';
        isValid = false;
      }
    });

    return isValid;
  }

  // Mengambil informasi rekening tujuan
  Map<String, String> _getDestination() {
    if (_useSavedAccount) {
      final account = _savedAccounts.firstWhere(
        (item) =>
            item['id']?.toString() == _selectedBankAccountId,
      );

      final bankCode = account['bankCode'].toString();
      final accountNumber = account['accountNumber'].toString();

      return {
        'bankCode': bankCode,
        'bankName': _bankName(bankCode),
        'accountNumber': accountNumber,
      };
    }

    return {
      'bankCode': _selectedBankCode!,
      'bankName': _selectedBankName,
      'accountNumber': _accountNumberController.text.trim(),
    };
  }

  // Menampilkan konfirmasi withdraw
  Future<void> _showConfirmation() async {
    if (!_canContinueWithdraw || !_validateForm()) return;

    // Memeriksa kecukupan saldo sebelum konfirmasi dan verifikasi PIN
    if (_amount > _balance) {
      TopNotice.show(
        context,
        'Saldo kamu tidak mencukupi.',
        success: false,
      );
      return;
    }

    final destination = _getDestination();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF3EEFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Konfirmasi Tarik Saldo',
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
                'Pastikan informasi penarikan sudah benar.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _confirmationRow(
                'Bank Tujuan',
                destination['bankName']!,
              ),
              const SizedBox(height: 10),
              _confirmationRow(
                'Nomor Rekening',
                _maskAccountNumber(
                  destination['accountNumber']!,
                ),
              ),
              const SizedBox(height: 10),
              _confirmationRow(
                'Nominal Withdraw',
                _formatRupiah(_amount),
              ),
              const SizedBox(height: 10),
              _confirmationRow(
                'Sisa Saldo',
                _formatRupiah(_balance - _amount),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
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
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
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
      await _submitWithdraw();
    }
  }

  Widget _confirmationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
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

  // Memproses withdraw menggunakan PIN transaksi
  Future<void> _submitWithdraw() async {
    if (!_canContinueWithdraw) return;

    setState(() {
      _isWithdrawing = true;
    });

    try {
      final pin = await TransactionPinFlow.requestPin(context);

      if (!mounted || pin == null) return;

      if (_useSavedAccount) {
        await _withdrawService.withdraw(
          amount: _amount,
          pin: pin,
          bankAccountId: _selectedBankAccountId,
        );
      } else {
        await _withdrawService.withdraw(
          amount: _amount,
          pin: pin,
          bankCode: _selectedBankCode,
          accountNumber: _accountNumberController.text.trim(),
          saveAccount: _saveAccount,
        );
      }

      if (!mounted) return;

      LocalNotificationService.checkNow();

      Navigator.pop(context, true);

      TopNotice.show(
        context,
        'Penarikan ${_formatRupiah(_amount)} berhasil!',
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
          _isWithdrawing = false;
        });
      }
    }
  }

  // Tampilan pesan validasi
  Widget _buildWarning(String? message) {
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
    );
  }

  // Judul setiap bagian form
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

  // Dekorasi input
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
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
          const Text(
            'Saldo Tersedia',
            style: TextStyle(color: Colors.white70),
          ),
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
                  onPressed: _isRefreshingWallet
                      ? null
                      : () => _loadData(),
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

  // Daftar pilihan rekening tersimpan
  Widget _buildSavedAccountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pilih Rekening Tersimpan'),
        const SizedBox(height: 12),
        ..._savedAccounts.map((account) {
          final accountId = account['id'].toString();
          final bankCode = account['bankCode'].toString();
          final accountNumber =
              account['accountNumber'].toString();
          final isSelected =
              accountId == _selectedBankAccountId;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? primaryPurple : borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: RadioListTile<String>(
              value: accountId,
              groupValue: _selectedBankAccountId,
              activeColor: primaryPurple,
              onChanged: _isWithdrawing
                  ? null
                  : (value) {
                      setState(() {
                        _selectedBankAccountId = value;
                        _savedAccountError = null;
                      });
                    },
              title: Text(
                _bankName(bankCode),
                style: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                _maskAccountNumber(accountNumber),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          );
        }),
        _buildWarning(_savedAccountError),
      ],
    );
  }

  // Form rekening baru
  Widget _buildNewAccountForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bank Tujuan'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedBankCode,
          isExpanded: true,
          decoration: _inputDecoration(
            hint: 'Pilih bank tujuan',
            prefixIcon: const Icon(
              Icons.account_balance_outlined,
              color: primaryPurple,
            ),
          ),
          items: _banks.entries.map((bank) {
            return DropdownMenuItem<String>(
              value: bank.key,
              child: Text(bank.value),
            );
          }).toList(),
          onChanged: _isWithdrawing
              ? null
              : (value) {
                  setState(() {
                    _selectedBankCode = value;
                    _accountError = null;
                  });
                },
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Nomor Rekening'),
        const SizedBox(height: 12),
        TextField(
          controller: _accountNumberController,
          enabled: !_isWithdrawing,
          keyboardType: TextInputType.number,
          maxLength: 16,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          onChanged: _onAccountNumberChanged,
          decoration: _inputDecoration(
            hint: 'Masukkan nomor rekening',
            prefixIcon: const Icon(
              Icons.credit_card_outlined,
              color: primaryPurple,
            ),
          ).copyWith(
            counterText: '',
          ),
        ),
        _buildWarning(_accountError),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _saveAccount,
          onChanged: _isWithdrawing
              ? null
              : (value) {
                  setState(() {
                    _saveAccount = value ?? false;
                  });
                },
          activeColor: primaryPurple,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Simpan rekening untuk transaksi berikutnya',
            style: TextStyle(
              fontSize: 13,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // Pilihan rekening tujuan
  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rekening Tujuan'),
        const SizedBox(height: 12),
        if (_savedAccounts.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: !_useSavedAccount
                    ? borderColor
                    : primaryPurple,
              ),
            ),
            child: RadioListTile<bool>(
              value: true,
              groupValue: _useSavedAccount,
              activeColor: primaryPurple,
              onChanged: _isWithdrawing
                  ? null
                  : (value) {
                      if (value != null) {
                        _selectAccountType(value);
                      }
                    },
              title: const Text(
                'Rekening Tersimpan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              subtitle: const Text(
                'Gunakan rekening yang pernah disimpan',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _useSavedAccount
                    ? borderColor
                    : primaryPurple,
              ),
            ),
            child: RadioListTile<bool>(
              value: false,
              groupValue: _useSavedAccount,
              activeColor: primaryPurple,
              onChanged: _isWithdrawing
                  ? null
                  : (value) {
                      if (value != null) {
                        _selectAccountType(value);
                      }
                    },
              title: const Text(
                'Rekening Baru',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              subtitle: const Text(
                'Gunakan rekening bank lainnya',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_useSavedAccount)
            _buildSavedAccountSelector()
          else
            _buildNewAccountForm(),
        ] else ...[
          const Text(
            'Belum ada rekening tersimpan. Tambahkan rekening baru untuk melakukan penarikan.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildNewAccountForm(),
        ],
      ],
    );
  }

  // Input nominal withdraw
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Nominal Penarikan'),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          enabled: !_isWithdrawing,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: _onAmountChanged,
          decoration: _inputDecoration(
            hint: 'Masukkan nominal penarikan',
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _amountError != null
                    ? Colors.red
                    : borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _amountError != null
                    ? Colors.red
                    : borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _amountError != null
                    ? Colors.red
                    : primaryPurple,
                width: 1.5,
              ),
            ),
          ),
        ),
        _buildWarning(_amountError),
      ],
    );
  }

  // Ringkasan withdraw
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
            'Ringkasan Penarikan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nominal Penarikan'),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Biaya Admin'),
              Text('Rp 0'),
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
                _formatRupiah(
                  remainingBalance < 0 ? 0 : remainingBalance,
                ),
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

  // Form utama withdraw
  Widget _buildWithdrawForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 28),

          _buildAccountSection(),
          const SizedBox(height: 28),

          _buildAmountField(),
          const SizedBox(height: 24),

          _buildSummary(),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canContinueWithdraw
                  ? _showConfirmation
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isWithdrawing
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
          'Tarik Saldo',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryPurple,
              ),
            )
          : SafeArea(
              child: _buildWithdrawForm(),
            ),
    );
  }
}
