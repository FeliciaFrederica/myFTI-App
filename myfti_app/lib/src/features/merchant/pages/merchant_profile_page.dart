import 'package:flutter/material.dart';

import '../../authentication/models/user_model.dart';
import '../../authentication/services/auth_service.dart';
import '../../authentication/widgets/user_avatar.dart';
import '../../../core/theme/app_theme.dart';

class MerchantProfilePage extends StatefulWidget {
  const MerchantProfilePage({super.key});

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  static const Color _purple = Color(0xFF673AB7);
  static const Color _text = Color(0xFF2D1B46);

  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService.getProfile();
  }

  Future<void> _refresh() async {
    setState(() => _userFuture = AuthService.getProfile());
    try {
      await _userFuture;
    } catch (_) {}
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFF3EEFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        content: const Text(
          'Yakin ingin keluar dari akun myFTI?',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _info(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _purple),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      subtitle: Text(
        value.isEmpty ? '-' : value,
        style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(color: _text, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F6FC),
        foregroundColor: _text,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: _purple,
        onRefresh: _refresh,
        child: FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator(color: _purple)),
                ],
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return ListView(
                children: [
                  const SizedBox(height: 170),
                  const Center(child: Text('Profil gagal dimuat.')),
                  Center(
                    child: TextButton(
                      onPressed: _refresh,
                      child: const Text('Coba lagi'),
                    ),
                  ),
                ],
              );
            }

            final user = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                Center(
                  child: UserAvatar(
                    initials: user.initials,
                    avatar: user.avatar,
                    radius: 46,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _text,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Colors.white,
                  elevation: 0,
                  child: Column(
                    children: [
                      _info('Jenis akun', 'Merchant', Icons.store_outlined),
                      const Divider(height: 1),
                      _info('Email', user.email, Icons.email_outlined),
                      const Divider(height: 1),
                      _info(
                        'ID Dompet',
                        user.walletId,
                        Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                    style: OutlinedButton.styleFrom(foregroundColor: _purple),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
