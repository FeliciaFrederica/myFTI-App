import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_field.dart';
import '../models/user_model.dart';
import '../../../core/services/session_service.dart';

// Batas percobaan login dan lama waktu tunggu
const int _kMaxAttempts = 3;
const int _kLockSeconds = 30;

const Color _kErrorFillColor = Color(0xFFFDF4F4);

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

  int _failedAttempts = 0;
  int _remainingSeconds = 0;
  Timer? _lockTimer;

  // Pesan peringatan akan tampil di bawah field password
  String? _loginError;

  // Menyimpan isi terakhir field, untuk mendeteksi user mengetik ulang
  String _lastEmail = '';
  String _lastPass = '';

  bool get _isLocked => _remainingSeconds > 0;

  @override
  void initState() {
    super.initState();
    _emailC.addListener(_onInputChanged);
    _passC.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  // Peringatan akan terhapus pada saat user mengubah email/password
  void _onInputChanged() {
    final changed = _emailC.text != _lastEmail || _passC.text != _lastPass;
    _lastEmail = _emailC.text;
    _lastPass = _passC.text;

    if (changed && _loginError != null && !_isLocked) {
      setState(() => _loginError = null);
    }
  }

  // Mulai hitung mundur 30 detik, setelah selesai percobaan di-reset
  void _startLockout() {
    _lockTimer?.cancel();
    setState(() {
      _remainingSeconds = _kLockSeconds;
      _loginError = 'Terlalu banyak percobaan. Silakan tunggu sebentar.';
    });

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _remainingSeconds--);

      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _failedAttempts = 0;
          _loginError = null;
        });
      }
    });
  }

  Future<void> _submit() async {
    if (_isLocked || _loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _loginError = null;
    });

    String? errorMessage;
    bool loginFailed = false;
    UserModel? user;

    try {
      // untuk login harus memasukkan email dan password yang benar
      try {
        await AuthService.login(_emailC.text.trim(), _passC.text);
      } catch (_) {
        // Hanya kegagalan di proses login yang dihitung sebagai percobaan
        loginFailed = true;
        rethrow;
      }

      user = await SessionService.getUser();

      if (user == null) {
        throw Exception('Data pengguna tidak ditemukan');
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (errorMessage == null && user != null) {
      _failedAttempts = 0;

      final destination =
          user.role.toUpperCase() == 'MERCHANT' ? '/merchant' : '/home';

      Navigator.pushReplacementNamed(context, destination);
      return;
    }

    if (loginFailed) {
      _failedAttempts++;

      // Sudah 3x gagal maka login akan terkunci selama 30 detik
      if (_failedAttempts >= _kMaxAttempts) {
        _startLockout();
        return;
      }
    }

    setState(() => _loginError = errorMessage ?? 'Login gagal');
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kErrorFillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
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
                              'Selamat Datang di myFTI',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Masuk untuk melanjutkan',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 32),
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
                            const SizedBox(height: 16),
                            AuthField(
                              controller: _passC,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.secondary,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 8) {
                                  return 'Password minimal 8 karakter';
                                }
                                return null;
                              },
                            ),

                            // Peringatan login gagal / terkunci
                            if (_loginError != null) ...[
                              const SizedBox(height: 12),
                              _buildErrorBox(_loginError!),
                            ],

                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                // Nonaktif saat loading atau sedang terkunci
                                onPressed:
                                    (_loading || _isLocked) ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  disabledBackgroundColor: Colors.white60,
                                  disabledForegroundColor: AppColors.primary,
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
                                    : Text(
                                        _isLocked
                                            ? 'Coba lagi dalam $_remainingSeconds detik'
                                            : 'Masuk',
                                        style: const TextStyle(
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
                                  'Belum punya akun? ',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                      context, '/register'),
                                  child: const Text(
                                    'Daftar',
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
        ),
      ),
    );
  }
}