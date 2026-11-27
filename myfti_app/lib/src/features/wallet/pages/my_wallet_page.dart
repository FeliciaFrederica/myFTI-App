import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfti_app/src/features/wallet/services/wallet_service.dart';
import 'package:myfti_app/src/core/widgets/top_notice.dart';

import 'top_up_page.dart';

class MyWalletPage extends StatefulWidget {
  final VoidCallback? onHistoryTap;
  final bool readOnly;

  const MyWalletPage({super.key, this.onHistoryTap, this.readOnly = false});

  @override
  MyWalletPageState createState() => MyWalletPageState();
}

class MyWalletPageState extends State<MyWalletPage> {
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color backgroundColor = Color(0xFFF8F6FC);
  static const Color textColor = Color(0xFF2D1B46);

  final WalletService _walletService = WalletService();

  late Future<Map<String, dynamic>> _walletFuture;

  bool _isBalanceVisible = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  void _loadWallet() {
    _walletFuture = _walletService.getWallet();
  }

  void hideBalance() {
    if (!mounted) return;

    setState(() {
      _isBalanceVisible = false;
    });
  }

  String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Dompet Saya',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _walletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryPurple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gagal mengambil data wallet.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _loadWallet();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Coba Lagi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }

          final wallet = snapshot.data!;
          final int balance = wallet['balance'] as int;
          final String walletId = wallet['walletId'] as String;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 170,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet Balance
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryPurple,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Dekorasi Mega Mendung
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Colors.white,
                                    Colors.white54,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.42, 0.72],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: Opacity(
                                opacity: 0.16,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildCloudItem(
                                      right: -25,
                                      top: -20,
                                      width: 170,
                                      angle: -0.15,
                                    ),
                                    _buildCloudItem(
                                      right: -15,
                                      bottom: -25,
                                      width: 150,
                                      angle: 0.2,
                                      flipX: true,
                                    ),
                                    _buildCloudItem(
                                      right: 110,
                                      top: 10,
                                      width: 105,
                                      angle: 0.25,
                                      flipX: true,
                                    ),
                                    _buildCloudItem(
                                      right: 95,
                                      bottom: 5,
                                      width: 120,
                                      angle: -0.2,
                                    ),
                                    _buildCloudItem(
                                      right: 185,
                                      top: 45,
                                      width: 85,
                                      angle: -0.35,
                                      flipX: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // saldo
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Dompet Digital myFTI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Saldo Tersedia',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _isBalanceVisible
                                            ? _formatRupiah(balance)
                                            : 'Rp ••••••••',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isBalanceVisible = !_isBalanceVisible;
                                      });
                                    },
                                    icon: Icon(
                                      _isBalanceVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.white,
                                    ),
                                    tooltip: _isBalanceVisible
                                        ? 'Sembunyikan saldo'
                                        : 'Tampilkan saldo',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Informasi Wallet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: Colors.white,
                  elevation: 0,
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.credit_card,
                        title: 'ID Dompet',
                        subtitle: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(walletId),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: walletId),
                                );

                                if (!context.mounted) return;

                                TopNotice.show(
                                  context,
                                  'ID Dompet berhasil disalin!',
                                  success: true,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              child: const Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildInfoTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Status Dompet',
                        subtitle: Text('Aktif'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildInfoTile(
                        icon: Icons.account_balance_outlined,
                        title: 'Jenis Akun',
                        subtitle: Text(
                          widget.readOnly
                              ? 'Dompet Merchant'
                              : 'Dompet Mahasiswa',
                        ),
                      ),
                    ],
                  ),
                ),

                if (!widget.readOnly) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'Menu Dompet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.add_circle_outline,
                          label: 'Top Up',
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TopUpPage(),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(_loadWallet);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.receipt_long_outlined,
                          label: 'Riwayat',
                          onTap: widget.onHistoryTap ?? () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloudItem({
    double? top,
    double? bottom,
    double? right,
    double? left,
    required double width,
    double angle = 0,
    bool flipX = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      right: right,
      left: left,
      child: Transform.rotate(
        angle: angle,
        child: Transform.flip(
          flipX: flipX,
          child: Image.asset(
            'assets/images/mega_mendung.png',
            width: width,
            fit: BoxFit.contain,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required Widget subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryPurple),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: subtitle,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPurple,
        side: const BorderSide(color: primaryPurple),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
