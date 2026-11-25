import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key});

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  final _pinC = TextEditingController();
  final _pinFocus = FocusNode();

  String? _setupToken;
  String? _firstPin;
  String? _errorMessage;

  bool _isConfirming = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pinC.addListener(_onPinChanged);
  }

  void _onPinChanged() {
    if (mounted) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is String) {
      _setupToken ??= args;
    }
  }

  @override
  void dispose() {
    _pinC.removeListener(_onPinChanged);
    _pinC.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _continue() {
    if (_pinC.text.length != 6) {
      setState(() {
        _errorMessage = 'PIN harus terdiri dari 6 angka';
      });
      return;
    }

    if (!_isConfirming) {
      setState(() {
        _firstPin = _pinC.text;
        _isConfirming = true;
        _errorMessage = null;
        _pinC.clear();
      });

      return;
    }

    if (_pinC.text != _firstPin) {
      setState(() {
        _errorMessage = 'PIN tidak cocok. Silakan coba lagi.';
        _pinC.clear();
      });
      return;
    }

    _submit();
  }

  Future<void> _submit() async {
    if (_setupToken == null || _setupToken!.isEmpty) {
      setState(() {
        _errorMessage =
            'Sesi pembuatan PIN tidak valid. Silakan registrasi ulang.';
      });
      return;
    }

    setState(() => _loading = true);

    String? errorMessage;

    try {
      await AuthService.setupPin(pin: _firstPin!, setupToken: _setupToken!);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;

    setState(() => _loading = false);

    if (errorMessage != null) {
      setState(() => _errorMessage = errorMessage);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    messenger.showSnackBar(
      const SnackBar(content: Text('PIN berhasil dibuat. Silakan login.')),
    );
  }

  Widget _buildPinInput() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final filled = index < _pinC.text.length;

              return Container(
                width: 36,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: filled ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: filled ? AppColors.primary : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: filled
                    ? const Center(
                        child: Icon(Icons.circle, size: 9, color: AppColors.background),
                      )
                    : null,
              );
            }),
          ),
        ),

        SizedBox(
          height: 54,
          child: TextField(
            controller: _pinC,
            focusNode: _pinFocus,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.transparent),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isConfirming ? 'Konfirmasi PIN' : 'Buat PIN Transaksi';

    final description = _isConfirming
        ? 'Masukkan kembali PIN transaksi Anda'
        : 'Masukkan 6 digit PIN untuk mengamankan transaksi Anda';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isConfirming) {
              setState(() {
                _isConfirming = false;
                _firstPin = null;
                _pinC.clear();
                _errorMessage = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              Icon(
                Icons.lock_outline_rounded,
                size: 52,
                color: AppColors.primary,
              ),

              const SizedBox(height: 28),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.text),
              ),

              const SizedBox(height: 48),

              _buildPinInput(),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isConfirming ? 'Simpan PIN' : 'Lanjut',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
