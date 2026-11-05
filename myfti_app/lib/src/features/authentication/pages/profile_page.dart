import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_field.dart';

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

  void _openEditSheet(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final nameC = TextEditingController(text: user.name);
    final emailC = TextEditingController(text: user.email);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit Profil',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                const SizedBox(height: 20),
                AuthField(
                  controller: nameC,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Nama minimal 3 karakter'
                      : null,
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: emailC,
                  label: 'Email',
                  icon: Icons.email_outlined,
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() => saving = true);
                            try {
                              await AuthService.updateProfile(
                                name: nameC.text.trim(),
                                email: emailC.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _reload();
                              _showSnack('Profil berhasil diperbarui',
                                  success: true);
                            } catch (e) {
                              if (ctx.mounted) setSheet(() => saving = false);
                              _showSnack(_errorText(e), success: false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
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
                  color: AppColors.card,
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
                    onPressed: () => _openEditSheet(user),
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