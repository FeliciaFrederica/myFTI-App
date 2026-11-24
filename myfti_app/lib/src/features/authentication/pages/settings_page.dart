import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)
                ),
            child: ListTile(
              leading:
                  const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('Tentang Aplikasi'),
              subtitle: const Text('myFTI v1.0.0'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'myFTI',
                applicationVersion: '1.0.0',
                children: const [
                  Text('Aplikasi keuangan digital simulasi untuk mahasiswa FTI.')
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}