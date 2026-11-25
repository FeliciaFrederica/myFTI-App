import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final _pinC = TextEditingController();
  final _pinFocus = FocusNode();

  String? _currentPin;
  String? _newPin;
  String? _errorMessage;

  int _step = 0;
  bool _loading = false;
  bool _isProcessing = false;

  final List<String> _titles = [
    'PIN Saat Ini',
    'PIN Baru',
    'Konfirmasi PIN Baru',
  ];

  final List<String> _descriptions = [
    'Masukkan PIN transaksi Anda saat ini',
    'Masukkan 6 digit PIN transaksi yang baru',
    'Masukkan kembali PIN baru Anda',
  ];

  @override
  void initState() {
    super.initState();
    _pinC.addListener(_onPinChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocus.requestFocus();
    });
  }

  void _onPinChanged() {
    if (!mounted) return;

    if (_errorMessage != null && _pinC.text.isNotEmpty) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }

    if (_pinC.text.length == 6 && !_loading && !_isProcessing) {
      _isProcessing = true;

      // Let the sixth PIN indicator render before advancing.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        if (_pinC.text.length == 6) {
          await Future.delayed(const Duration(milliseconds: 350));

          if (!mounted) return;

          _continue();
        }

        _isProcessing = false;
      });
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
    if (_loading) return;

    final pin = _pinC.text;

    if (pin.length != 6) return;

    if (_step == 0) {
      _currentPin = pin;
      _nextStep();
      return;
    }

    if (_step == 1) {
      if (pin == _currentPin) {
        _pinC.clear();

        setState(() {
          _errorMessage = 'PIN baru tidak boleh sama dengan PIN lama.';
        });

        return;
      }

      _newPin = pin;
      _nextStep();
      return;
    }

    if (pin != _newPin) {
      _pinC.clear();

      setState(() {
        _errorMessage =
            'PIN tidak cocok. Silakan masukkan kembali PIN baru Anda.';
      });

      return;
    }

    _submit();
  }

  void _nextStep() {
    setState(() {
      _step++;
      _pinC.clear();
      _errorMessage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocus.requestFocus();
    });
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.changePin(currentPin: _currentPin!, newPin: _newPin!);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _step = 0;
        _currentPin = null;
        _newPin = null;
        _pinC.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pinFocus.requestFocus();
      });
    }
  }

  void _goBack() {
    if (_loading || _isProcessing) return;

    if (_step > 0) {
      setState(() {
        _step--;
        _pinC.clear();
        _errorMessage = null;

        if (_step == 0) {
          _currentPin = null;
          _newPin = null;
        } else if (_step == 1) {
          _newPin = null;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pinFocus.requestFocus();
      });
    } else {
      Navigator.pop(context);
    }
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
                        child: Icon(
                          Icons.circle,
                          size: 9,
                          color: AppColors.background,
                        ),
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
            textInputAction: TextInputAction.done,
            obscureText: true,
            maxLength: 6,
            autocorrect: false,
            enableSuggestions: false,
            showCursor: false,
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

  Widget _buildCloudItem({
    double? top,
    double? bottom,
    double? right,
    double? left,
    required double width,
    double angle = 0,
    bool flipX = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      right: right,
      left: left,
      child: Transform.rotate(
        angle: angle,
        child: Transform.flip(
          flipX: flipX,
          child: Image.asset(
            'assets/images/mega_mendung.png',
            width: width,
            fit: BoxFit.contain,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading && !_isProcessing,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _loading || _isProcessing ? null : _goBack,
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Decorative Mega Mendung motif.
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, 3),
                  child: Opacity(
                    opacity: 0.13,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 240,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildCloudItem(
                            right: -25,
                            top: -75,
                            width: 170,
                            angle: -0.15,
                          ),
                          _buildCloudItem(
                            left: -15,
                            bottom: -20,
                            width: 150,
                            angle: 0.2,
                            flipX: true,
                          ),
                          _buildCloudItem(
                            right: 80,
                            top: -10,
                            width: 105,
                            angle: 0.25,
                            flipX: true,
                          ),
                          _buildCloudItem(
                            left: 75,
                            bottom: 40,
                            width: 120,
                            angle: -0.2,
                          ),
                          _buildCloudItem(
                            right: 150,
                            top: 40,
                            width: 85,
                            angle: -0.35,
                            flipX: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // PIN form.
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 52,
                      color: AppColors.primary,
                    ),

                    const SizedBox(height: 28),

                    Text(
                      _titles[_step],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _descriptions[_step],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),

                    const SizedBox(height: 48),

                    _buildPinInput(),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    if (_loading) ...[
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 12),
                      const Text(
                        'Menyimpan PIN...',
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
