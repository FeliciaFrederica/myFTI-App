import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
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
    try {
      await AuthService.register(
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

    final success = errorMessage == null;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Registrasi berhasil, silakan login' : errorMessage),
      backgroundColor: success ? AppColors.success : AppColors.error,
    ));
    if (success) Navigator.pop(context);
  }

  Widget _eye(bool obscured, VoidCallback onTap) => IconButton(
        icon: Icon(obscured ? Icons.visibility_off : Icons.visibility,
            color: AppColors.secondary),
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text('Buat Akun myFTI',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('Dompet digital dibuat otomatis setelah daftar',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 28),
                  AuthField(
                    controller: _nameC,
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama wajib diisi';
                      }
                      if (v.trim().length < 3) return 'Nama minimal 3 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthField(
                    controller: _nimC,
                    label: 'NIM',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'NIM wajib diisi';
                      }
                      // NIM FTI diawali 535 / 825, total 9 digit (sesuaikan jika beda)
                      if (!RegExp(r'^(535|825)\d{6}$').hasMatch(v.trim())) {
                        return 'NIM tidak valid (535xxxxxx / 825xxxxxx)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthField(
                    controller: _emailC,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      final ok = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$')
                          .hasMatch(v.trim());
                      return ok ? null : 'Format email tidak valid';
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthField(
                    controller: _passC,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    textInputAction: TextInputAction.next,
                    suffix: _eye(
                        _obscure, () => setState(() => _obscure = !_obscure)),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (v.length < 6) return 'Password minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthField(
                    controller: _confirmC,
                    label: 'Konfirmasi Password',
                    icon: Icons.lock_reset,
                    obscure: _obscureConfirm,
                    suffix: _eye(
                        _obscureConfirm,
                        () => setState(
                            () => _obscureConfirm = !_obscureConfirm)),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      if (v != _passC.text) return 'Password tidak sama';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5))
                          : const Text('Daftar',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun? ',
                          style: TextStyle(color: Colors.white70)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Login',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}