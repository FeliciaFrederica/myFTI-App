import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class TransactionPinPage extends StatefulWidget {
  const TransactionPinPage({super.key});

  @override
  State<TransactionPinPage> createState() => _TransactionPinPageState();
}

class _TransactionPinPageState extends State<TransactionPinPage> {
  final _pinC = TextEditingController();
  final _pinFocus = FocusNode();

  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pinC.addListener(_onPinChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocus.requestFocus();
    });
  }

  void _onPinChanged() {
    if (mounted) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void dispose() {
    _pinC.removeListener(_onPinChanged);
    _pinC.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSubmitting || _pinC.text.length != 6) return;

    _isSubmitting = true;
    Navigator.pop(context, _pinC.text);
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
            onChanged: (value) {
              if (value.length == 6) {
                _submit();
              }
            },
          ),
        ),
      ],
    );
  }

  // widget awan megamendung
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
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Motif dekoratif Mega Mendung
            Positioned.fill(
              child: Center(
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

            // Judul dan PIN tetap di atas meskipun keyboard muncul.
            Positioned(
              top: 28,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'Masukkan PIN Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 32),
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
