import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun myFTI?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;

    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.card,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined,
                      color: AppColors.primary),
                  title: const Text('Notifikasi'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/notification'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: AppColors.primary),
                  title: const Text('Tentang Aplikasi'),
                  subtitle: const Text('myFTI v1.0.0'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'myFTI',
                    applicationVersion: '1.0.0',
                    children: const [
                      Text(
                          'Aplikasi keuangan digital simulasi untuk mahasiswa FTI.')
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}