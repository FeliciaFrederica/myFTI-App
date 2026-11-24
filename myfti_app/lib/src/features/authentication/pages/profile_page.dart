import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../../notification/pages/notification_page.dart';
import 'edit_profile_page.dart';
import '../widgets/user_avatar.dart';

const Color _kCardColor = Color(0xFFF3EEFC);

const double _kNavBarSpace = 100;

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

  // Terhubung ke halaman edit profil, data akan dimuat ulang setelah berhasil menyimpan perubahan data
  Future<void> _openEditPage(UserModel user) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
    );

    if (saved == true) {
      _reload();
      _showSnack('Profil berhasil diperbarui', success: true);
    }
  }

  void _openNotification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }

  Future<void> _confirmLogout() async {
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
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: UserAvatar(
                          initials: user.initials,
                          avatar: user.avatar,
                          radius: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(user.name.toUpperCase(),
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
                            _info(
                                Icons.account_balance_wallet_outlined,
                                'Wallet ID',
                                user.walletId.isEmpty ? '-' : user.walletId),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Menu Edit Profil dan Notifikasi
                      Card(
                        color: _kCardColor,
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            _menu(Icons.edit_outlined, 'Edit Profil',
                                () => _openEditPage(user)),
                            const Divider(height: 1),
                            _menu(Icons.notifications_outlined, 'Notifikasi',
                                _openNotification),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, _kNavBarSpace),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _menu(IconData icon, String title, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}