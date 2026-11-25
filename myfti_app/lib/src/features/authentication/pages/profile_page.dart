import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/top_notice.dart';
import '../services/auth_service.dart';
import '../../notification/pages/notification_page.dart';
import 'edit_profile_page.dart';
import '../widgets/user_avatar.dart';
import 'change_pin_page.dart';

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

  // Notifikasi tampil di bagian atas halaman
  void _showNotice(String message, {required bool success}) {
    if (!mounted) return;
    TopNotice.show(context, message, success: success);
  }

  // Terhubung ke halaman edit profil, data akan dimuat ulang setelah berhasil menyimpan perubahan data
  Future<void> _openEditPage(UserModel user) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
    );

    if (saved == true) {
      _reload();
      _showNotice('Profil berhasil diperbarui', success: true);
    }
  }

  Future<void> _openChangePin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ChangePinPage()),
    );

    if (ok == true && mounted) {
      TopNotice.show(context, 'PIN transaksi berhasil diubah', success: true);
    }
  }

  void _openNotification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('myFTI'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1.0.0'),
            SizedBox(height: 16),
            Text('Aplikasi keuangan digital simulasi untuk mahasiswa FTI.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              showLicensePage(
                context: context,
                applicationName: 'myFTI',
                applicationVersion: '1.0.0',
              );
            },
            child: const Text('Lihat lisensi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
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
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
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
      ),
      body: FutureBuilder<UserModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
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
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          final user = snap.data!;

          return RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Center(
                        child: UserAvatar(
                          initials: user.initials,
                          avatar: user.avatar,
                          radius: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          user.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Akun
                      _sectionTitle('Akun'),
                      Card(
                        color: _kCardColor,
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _info(Icons.badge_outlined, 'NIM', user.nim),
                            const Divider(height: 1),
                            _info(Icons.email_outlined, 'Email', user.email),
                            const Divider(height: 1),
                            _info(
                              Icons.account_balance_wallet_outlined,
                              'Wallet ID',
                              user.walletId.isEmpty ? '-' : user.walletId,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pengaturan
                      _sectionTitle('Pengaturan'),
                      Card(
                        color: _kCardColor,
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _menu(
                              Icons.edit_outlined,
                              'Edit Profil',
                              () => _openEditPage(user),
                            ),
                            const Divider(height: 1),
                            _menu(
                              Icons.pin_outlined,
                              'Ubah PIN Transaksi',
                              _openChangePin,
                            ),
                            const Divider(height: 1),
                            _menu(
                              Icons.notifications_outlined,
                              'Notifikasi',
                              _openNotification,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mengenai
                      _sectionTitle('Mengenai'),
                      Card(
                        color: _kCardColor,
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _menu(
                          Icons.info_outline,
                          'Tentang Aplikasi',
                          _showAbout,
                          subtitle: 'myFTI v1.0.0',
                        ),
                      ),
                    ]),
                  ),
                ),

                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      _kNavBarSpace,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
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
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      ),
    ),
  );

  Widget _info(IconData icon, String title, String value) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(
      title,
      style: const TextStyle(fontSize: 12, color: AppColors.secondary),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _menu(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
  }) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
