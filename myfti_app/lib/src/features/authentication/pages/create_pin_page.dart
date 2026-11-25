
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key});

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  final _formKey = GlobalKey<FormState>();

  final _pinC = TextEditingController();
  final _confirmPinC = TextEditingController();

  final _pinFocus = FocusNode();
  final _confirmPinFocus = FocusNode();

  String? _setupToken;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _pinC.addListener(_onPinChanged);
    _confirmPinC.addListener(_onPinChanged);

    _pinFocus.addListener(_onPinChanged);
    _confirmPinFocus.addListener(_onPinChanged);
  }

  void _onPinChanged() {
    if (mounted) {
      setState(() {});
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
    _confirmPinC.removeListener(_onPinChanged);

    _pinFocus.removeListener(_onPinChanged);
    _confirmPinFocus.removeListener(_onPinChanged);

    _pinC.dispose();
    _confirmPinC.dispose();

    _pinFocus.dispose();
    _confirmPinFocus.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_setupToken == null || _setupToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesi pembuatan PIN tidak valid. Silakan registrasi ulang.',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    String? errorMessage;

    try {
      await AuthService.setupPin(
        pin: _pinC.text,
        setupToken: _setupToken!,
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
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    // Kembali ke halaman Login setelah PIN berhasil dibuat.
    Navigator.pop(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('PIN berhasil dibuat. Silakan login.'),
      ),
    );
  }

  Widget _buildPinField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  final filled = index < controller.text.length;
                  final active =
                      focusNode.hasFocus &&
                      index == controller.text.length;

                  return Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              obscureText: true,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(
                color: Colors.transparent,
              ),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
              validator: validator ??
                  (value) {
                    if (value == null || value.length != 6) {
                      return 'PIN harus terdiri dari 6 angka';
                    }
                    return null;
                  },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_setupToken == null || _setupToken!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Buat PIN'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sesi pembuatan PIN tidak ditemukan. '
                  'Silakan kembali ke halaman login.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  child: const Text('Kembali ke Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat PIN Transaksi'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                const Icon(
                  Icons.lock_outline,
                  size: 64,
                ),

                const SizedBox(height: 24),

                Text(
                  'Buat PIN Transaksi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Buat PIN 6 digit untuk mengamankan '
                  'setiap transaksi Anda.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 40),

                _buildPinField(
                  label: 'PIN Transaksi',
                  controller: _pinC,
                  focusNode: _pinFocus,
                ),

                const SizedBox(height: 32),

                _buildPinField(
                  label: 'Konfirmasi PIN',
                  controller: _confirmPinC,
                  focusNode: _confirmPinFocus,
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'Konfirmasi PIN harus terdiri dari 6 angka';
                    }

                    if (value != _pinC.text) {
                      return 'PIN tidak cocok';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 36),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan PIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
