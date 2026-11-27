import 'package:flutter/material.dart';

import '../../authentication/models/user_model.dart';
import '../../authentication/services/auth_service.dart';
import '../../authentication/widgets/user_avatar.dart';
import '../../../core/theme/app_theme.dart';
import '../../withdraw/services/withdraw_service.dart';

class MerchantProfilePage extends StatefulWidget {
  const MerchantProfilePage({super.key});

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  static const Color _purple = Color(0xFF673AB7);
  static const Color _text = Color(0xFF2D1B46);

  late Future<UserModel> _userFuture;
  Future<List<Map<String, dynamic>>> _bankAccountsFuture = Future.value(
    const <Map<String, dynamic>>[],
  );
  final WithdrawService _withdrawService = WithdrawService();

  static const Map<String, String> _bankNames = {
    'ABC': 'ABC',
    'MANDIRIW': 'Mandiriw',
    'BNN': 'BNN',
  };

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService.getProfile();
    _bankAccountsFuture = _withdrawService.getSavedBankAccounts();
  }

  Future<void> _refresh() async {
    setState(() {
      _userFuture = AuthService.getProfile();
      _bankAccountsFuture = _withdrawService.getSavedBankAccounts();
    });
    try {
      await Future.wait([_userFuture, _bankAccountsFuture]);
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

  Widget _bankAccounts() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bankAccountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: _purple)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('Rekening bank gagal dimuat.'),
              trailing: IconButton(
                tooltip: 'Coba lagi',
                onPressed: () => setState(() {
                  _bankAccountsFuture = _withdrawService.getSavedBankAccounts();
                }),
                icon: const Icon(Icons.refresh),
              ),
            ),
          );
        }

        final accounts = snapshot.data ?? [];
        if (accounts.isEmpty) {
          return const Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.account_balance_outlined, color: _purple),
              title: Text('Belum ada rekening tersimpan'),
              subtitle: Text('Rekening yang disimpan akan muncul di sini.'),
            ),
          );
        }

        return Card(
          color: Colors.white,
          elevation: 0,
          child: Column(
            children: [
              for (var index = 0; index < accounts.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.account_balance_outlined,
                    color: _purple,
                  ),
                  title: Text(
                    _bankNames[accounts[index]['bankCode']
                            ?.toString()
                            .toUpperCase()] ??
                        accounts[index]['bankCode']?.toString() ??
                        'Bank',
                  ),
                  subtitle: Text(
                    accounts[index]['accountNumber']?.toString() ?? '-',
                    style: const TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                140 + MediaQuery.of(context).padding.bottom,
              ),
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
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Rekening Bank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _text,
                    ),
                  ),
                ),
                _bankAccounts(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
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
              ],
            );
          },
        ),
      ),
    );
  }
}
