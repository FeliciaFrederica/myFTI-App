import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    String? errorMessage;
    try {
      // login menerima 2 argumen posisional: email, password
      await AuthService.login(
        _emailC.text.trim(),
        _passC.text,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (errorMessage == null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          size: 44, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text('Selamat Datang di myFTI',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('Masuk untuk melanjutkan',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 32),
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
                      suffix: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.secondary),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password wajib diisi';
                        }
                        if (v.length < 6) return 'Password minimal 6 karakter';
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
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5))
                            : const Text('Login',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum punya akun? ',
                            style: TextStyle(color: Colors.white70)),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text('Daftar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}