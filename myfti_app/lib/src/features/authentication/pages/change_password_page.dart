import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';

const int _kMinPassword = 8;

const Color _kBackgroundColor = Color(0xFFF8F6FC);
const Color _kBorderColor = Color(0xFFD1C4E9);
const Color _kErrorFillColor = Color(0xFFFDF4F4);

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldKey = GlobalKey<FormFieldState<String>>();
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  final _oldC = TextEditingController();
  final _newC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _saving = false;

  String? _error;

  // Error dari server khusus password lama, akan tampil di bawah field password lama
  String? _oldServerError;

  @override
  void dispose() {
    _oldC.dispose();
    _newC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Mengosongkan error server sebelumnya agar bisa dicek ulang oleh server
    _oldServerError = null;

    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await AuthService.changePassword(
        currentPassword: _oldC.text,
        newPassword: _newC.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        _saving = false;

        if (message.toLowerCase().contains('password lama')) {
          _oldServerError = message;
          _error = null;
        } else {
          _error = message;
        }
      });

      // Jalankan ulang validasi field password lama 
      if (_oldServerError != null) {
        _oldKey.currentState?.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: _kBackgroundColor,
        appBar: AppBar(
          backgroundColor: _kBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: _saving ? null : () => Navigator.pop(context),
          ),
          title: const Text(
            'Ubah Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _PasswordField(
                        fieldKey: _oldKey,
                        controller: _oldC,
                        label: 'Password Lama',
                        action: TextInputAction.next,
                        // Menghapus error server saat user mengubah isi field
                        onChanged: (_) => _oldServerError = null,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password lama wajib diisi';
                          }
                          return _oldServerError;
                        },
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        controller: _newC,
                        label: 'Password Baru',
                        action: TextInputAction.next,
                        // Memeriksa ulang konfirmasi setiap password baru berubah
                        onChanged: (_) {
                          if (_confirmC.text.isNotEmpty) {
                            _confirmKey.currentState?.validate();
                          }
                        },
                        validator: (v) {
                          if (v == null || v.length < _kMinPassword) {
                            return 'Password minimal $_kMinPassword karakter';
                          }
                          if (v == _oldC.text) {
                            return 'Password baru harus berbeda';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        fieldKey: _confirmKey,
                        controller: _confirmC,
                        label: 'Konfirmasi Password Baru',
                        action: TextInputAction.done,
                        validator: (v) => v != _newC.text
                            ? 'Konfirmasi password tidak cocok'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Field password dengan tombol lihat/sembunyikan
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputAction action;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;
  final GlobalKey<FormFieldState<String>>? fieldKey;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.action,
    required this.validator,
    this.onChanged,
    this.fieldKey,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  // Menandai apakah field sedang error
  bool _invalid = false;

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  String? _validate(String? value) {
    final result = widget.validator(value);
    final invalid = result != null;

    if (invalid != _invalid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _invalid = invalid);
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          obscureText: _hidden,
          textInputAction: widget.action,
          validator: _validate,
          onChanged: widget.onChanged,
          // Validasi otomatis pada saat user mulai mengetik
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            filled: true,
            fillColor: _invalid ? _kErrorFillColor : Colors.white,
            prefixIcon:
                const Icon(Icons.lock_outline, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _hidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.secondary,
              ),
              onPressed: () => setState(() => _hidden = !_hidden),
            ),
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
            ),
            border: _border(_kBorderColor, 1),
            enabledBorder: _border(_kBorderColor, 1),
            focusedBorder: _border(AppColors.primary, 1.5),
            errorBorder: _border(AppColors.error, 1.5),
            focusedErrorBorder: _border(AppColors.error, 2),
          ),
        ),
      ],
    );
  }
}