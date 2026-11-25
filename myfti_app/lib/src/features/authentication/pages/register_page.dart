import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_field.dart';

const int _kMinName = 4;
const int _kMinPassword = 8;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  final _nameC = TextEditingController();
  final _nimC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_nameC, _nimC, _emailC, _passC, _confirmC]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    String? errorMessage;
    String? setupToken;

    try {
      setupToken = await AuthService.register(
        name: _nameC.text.trim(),
        nim: _nimC.text.trim(),
        email: _emailC.text.trim(),
        password: _passC.text,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;

    setState(() => _loading = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      '/create-pin',
      arguments: setupToken,
    );
  }

  Widget _eye(bool obscured, VoidCallback onTap) => IconButton(
        icon: Icon(obscured ? Icons.visibility_off : Icons.visibility,
            color: AppColors.secondary),
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 44,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Buat Akun myFTI',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Dompet digital dibuat otomatis setelah daftar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 28),

                                // Nama Lengkap
                                AuthField(
                                  controller: _nameC,
                                  label: 'Nama Lengkap',
                                  icon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null ||
                                        v.trim().length < _kMinName) {
                                      return 'Nama lengkap minimal $_kMinName karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // NIM
                                AuthField(
                                  controller: _nimC,
                                  label: 'NIM',
                                  icon: Icons.badge_outlined,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    final nim = v?.trim() ?? '';
                                    if (nim.isEmpty) {
                                      return 'NIM wajib diisi';
                                    }
                                    // NIM FTI wajib diawali 535 / 825
                                    if (!(nim.startsWith('535') ||
                                        nim.startsWith('825'))) {
                                      return 'NIM wajib diawali 535/825';
                                    }
                                    if (!RegExp(r'^\d{9}$').hasMatch(nim)) {
                                      return 'NIM harus 9 digit angka';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Email
                                AuthField(
                                  controller: _emailC,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    final ok = RegExp(
                                            r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$')
                                        .hasMatch(v?.trim() ?? '');
                                    return ok
                                        ? null
                                        : 'Masukkan alamat email dengan format yang benar';
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Password
                                AuthField(
                                  controller: _passC,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscure: _obscure,
                                  textInputAction: TextInputAction.next,
                                  suffix: _eye(
                                      _obscure,
                                      () =>
                                          setState(() => _obscure = !_obscure)),
                                  // Cek ulang konfirmasi setiap password berubah
                                  onChanged: (_) {
                                    if (_confirmC.text.isNotEmpty) {
                                      _confirmKey.currentState?.validate();
                                    }
                                  },
                                  validator: (v) {
                                    if (v == null || v.length < _kMinPassword) {
                                      return 'Password minimal $_kMinPassword karakter';
                                    }
                                    if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
                                      return 'Password harus mengandung huruf';
                                    }
                                    if (!RegExp(r'\d').hasMatch(v)) {
                                      return 'Password harus mengandung angka';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Konfirmasi Password
                                AuthField(
                                  fieldKey: _confirmKey,
                                  controller: _confirmC,
                                  label: 'Konfirmasi Password',
                                  icon: Icons.lock_reset,
                                  obscure: _obscureConfirm,
                                  suffix: _eye(
                                      _obscureConfirm,
                                      () => setState(() =>
                                          _obscureConfirm = !_obscureConfirm)),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Konfirmasi password wajib diisi';
                                    }
                                    if (v != _passC.text) {
                                      return 'Konfirmasi password tidak cocok';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 28),

                                // Tombol Daftar
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Daftar',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Sudah punya akun? ',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                top: 4,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}