import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../services/auth_service.dart';

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key, this.isForTransaction = false});

  final bool isForTransaction;

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
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pinC.addListener(_onPinChanged);
  }

  void _onPinChanged() {
    if (!mounted) return;

    setState(() => _errorMessage = null);

    if (_pinC.text.length == 6 && !_loading && !_isProcessing) {
      _isProcessing = true;

      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;

        if (_pinC.text.length == 6 && !_loading) {
          _continue();
        }

        if (mounted) {
          setState(() => _isProcessing = false);
        }
      });
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
    if (_pinC.text.length != 6 || _loading) return;

    if (!_isConfirming) {
      _firstPin = _pinC.text;
      _pinC.clear();

      setState(() {
        _isConfirming = true;
        _errorMessage = null;
      });

      _pinFocus.requestFocus();
      return;
    }

    if (_pinC.text != _firstPin) {
      _pinC.clear();

      setState(() {
        _errorMessage = 'PIN tidak cocok. Silakan coba lagi.';
      });

      _pinFocus.requestFocus();
      return;
    }

    _submit();
  }

  Future<void> _submit() async {
    // Setup PIN saat registrasi tetap menggunakan setupToken.
    if (!widget.isForTransaction &&
        (_setupToken == null || _setupToken!.isEmpty)) {
      setState(() {
        _errorMessage =
            'Sesi pembuatan PIN tidak valid. Silakan registrasi ulang.';
      });
      return;
    }

    setState(() => _loading = true);

    String? errorMessage;

    try {
      if (widget.isForTransaction) {
        // User lama yang belum memiliki PIN.
        await AuthService.createPin(pin: _firstPin!);
        await SessionService.markHasPin();
      } else {
        // Alur registrasi lama: tidak diubah.
        await AuthService.setupPin(pin: _firstPin!, setupToken: _setupToken!);
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;

    setState(() => _loading = false);

    if (errorMessage != null) {
      _pinC.clear();

      setState(() {
        _errorMessage = errorMessage;
      });

      _pinFocus.requestFocus();
      return;
    }

    if (widget.isForTransaction) {
      // Kembalikan PIN yang baru dibuat agar transaksi langsung dilanjutkan.
      Navigator.pop(context, _firstPin);
      return;
    }

    // Perilaku registrasi tetap seperti sebelumnya.
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

  Widget _buildMegaMendung() {
    return Positioned.fill(
      child: Align(
        alignment: const Alignment(0, 2.5),
        child: IgnorePointer(
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
    );
  }

  Widget _buildCloudItem({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double width,
    required double angle,
    bool flipX = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
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
    final title = _isConfirming ? 'Konfirmasi PIN' : 'Buat PIN Transaksi';

    final description = _isConfirming
        ? 'Masukkan kembali PIN transaksi Anda'
        : 'Masukkan 6 digit PIN untuk mengamankan transaksi Anda';

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: (_loading || _isProcessing)
              ? null
              : () {
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
        child: Stack(
          children: [
            _buildMegaMendung(),

            SingleChildScrollView(
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
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
