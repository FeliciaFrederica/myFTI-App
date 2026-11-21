import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_field.dart';

const Color _kCardColor = Color(0xFFF3EEFC);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserModel> _future;

  @override
  void initState() {
    super.initState();
    _future = AuthService.getProfile();
  }

  Future<void> _reload() async {
    setState(() {
      _future = AuthService.getProfile();
    });
    try {
      await _future;
    } catch (_) {
      // error ditampilkan oleh FutureBuilder
    }
  }

  String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _showSnack(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: success ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _openEditDialog(UserModel user) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditProfileDialog(user: user),
    );

    if (saved == true) {
      _reload();
      _showSnack('Profil berhasil diperbarui', success: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const Text(
          'Profil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<UserModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      snap.hasError
                          ? _errorText(snap.error!)
                          : 'Terjadi kesalahan',
                      style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _reload, child: const Text('Coba Lagi')),
                ],
              ),
            );
          }
          final user = snap.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary,
                    child: Text(user.initials,
                        style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(user.name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text)),
                ),
                const SizedBox(height: 24),
                Card(
                  color: _kCardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _info(Icons.badge_outlined, 'NIM', user.nim),
                      const Divider(height: 1),
                      _info(Icons.email_outlined, 'Email', user.email),
                      const Divider(height: 1),
                      _info(Icons.account_balance_wallet_outlined, 'Wallet ID',
                          user.walletId.isEmpty ? '-' : user.walletId),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _openEditDialog(user),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) => ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title,
            style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 15,
                color: AppColors.text,
                fontWeight: FontWeight.w500)),
      );
}

// Pop up edit profil.
class _EditProfileDialog extends StatefulWidget {
  final UserModel user;
  const _EditProfileDialog({required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _emailC;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.user.name);
    _emailC = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await AuthService.updateProfile(
        name: _nameC.text.trim(),
        email: _emailC.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Dialog tidak bisa ditutup saat sedang menyimpan
      canPop: !_saving,
      child: Dialog(
        backgroundColor: _kCardColor,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 20),
                AuthField(
                  controller: _nameC,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                  onLight: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Nama minimal 3 karakter'
                      : null,
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: _emailC,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  onLight: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email wajib diisi';
                    }
                    final ok = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$')
                        .hasMatch(v.trim());
                    return ok ? null : 'Format email tidak valid';
                  },
                ),

                // Error dari server tampil di dalam dialog
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

                const SizedBox(height: 24),

                // Tombol Simpan (atas, penuh)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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

                const SizedBox(height: 8),

                // Tombol Batal (bawah, teks abu-abu)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      disabledForegroundColor: Colors.grey.shade400,
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}