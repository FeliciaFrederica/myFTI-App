import 'package:flutter/material.dart';
import 'package:myfti_app/src/features/wallet/services/wallet_service.dart';
import 'package:myfti_app/src/features/transaction/services/transaction_service.dart';
import 'package:myfti_app/src/features/transaction/models/transaction_model.dart';

import 'top_up_page.dart';
import '../../transfer/pages/transfer_page.dart';
import '../../payment/pages/payment_page.dart';
import '../../withdraw/pages/withdraw_page.dart';
import '../../notification/widgets/notification_bell_button.dart';
import '../../summary/pages/financial_summary_page.dart';
import '../../authentication/models/user_model.dart';
import '../../authentication/services/auth_service.dart';
import '../../authentication/widgets/user_avatar.dart';
import '../../transaction/pages/transaction_history_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onHistoryTap;

  const HomePage({super.key, this.onProfileTap, this.onHistoryTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color textColor = Color(0xFF2D1B46);

  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();

  late Future<Map<String, dynamic>> _walletFuture;
  late Future<TransactionPageResult> _transactionFuture;
  late Future<UserModel> _userFuture;

  bool _isBalanceVisible = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _userFuture = AuthService.getProfile();
  }

  // Memuat saldo dan transaksi dari API
  void _loadData() {
    _walletFuture = _walletService.getWallet();
    _transactionFuture = _transactionService.getTransactions();
  }

  // Memuat ulang saldo, profil, dan transaksi
  Future<void> _refreshData() async {
    setState(() {
      _loadData();
      _userFuture = AuthService.getProfile();
    });

    try {
      await Future.wait([_walletFuture, _transactionFuture, _userFuture]);
    } catch (_) {
      // Error ditampilkan pada bagian data masing-masing
    }
  }

  // Mengubah nominal menjadi format Rupiah
  String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  // Mengubah tanggal menjadi format yang mudah dibaca
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year • $hour:$minute';
  }

  // Menampilkan konfirmasi sebelum logout
  Future<void> _confirmLogout() async {
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
            color: textColor,
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
                backgroundColor: primaryPurple,
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

  // Menampilkan foto profil pengguna
  Widget _buildHeaderAvatar(UserModel? user) {
    if (user != null) {
      return UserAvatar(
        initials: user.initials,
        avatar: user.avatar,
        radius: 20,
      );
    }

    return const CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFFEDE7F6),
      child: Icon(Icons.person, color: primaryPurple),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: primaryPurple,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: widget.onProfileTap,
                        borderRadius: BorderRadius.circular(30),
                        child: FutureBuilder<UserModel>(
                          future: _userFuture,
                          builder: (context, snapshot) {
                            final user = snapshot.data;

                            final String name;
                            if (snapshot.hasError) {
                              name = 'Mahasiswa FTI!';
                            } else if (user != null) {
                              name = '${user.name}!';
                            } else {
                              name = 'Memuat profil...';
                            }

                            return Row(
                              children: [
                                _buildHeaderAvatar(user),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Selamat Datang,',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const NotificationBellButton(),
                    IconButton(
                      onPressed: _confirmLogout,
                      tooltip: 'Logout',
                      icon: const Icon(Icons.logout, color: primaryPurple),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Kartu saldo wallet
                _buildBalanceCard(),

                const SizedBox(height: 16),

                // Shortcut ringkasan keuangan
                _buildSummaryShortcut(context),

                const SizedBox(height: 28),

                // Menu utama
                const Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAction(
                      icon: Icons.add_circle_outline,
                      label: 'Isi Saldo',
                      onTap: _openTopUp,
                    ),
                    _buildAction(
                      icon: Icons.send_outlined,
                      label: 'Transfer',
                      onTap: _openTransfer,
                    ),
                    _buildAction(
                      icon: Icons.payment_outlined,
                      label: 'Pembayaran',
                      onTap: _openPayment,
                    ),
                    _buildAction(
                      icon: Icons.account_balance_outlined,
                      label: 'Tarik Saldo',
                      onTap: _openWithdraw,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Transaksi terakhir
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaksi Terakhir',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          widget.onHistoryTap ??
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TransactionHistoryPage(
                                      showBackButton: true,
                                    ),
                              ),
                            );
                          },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(color: primaryPurple),
                      ),
                    ),
                  ],
                ),

                _buildRecentTransactions(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Menampilkan kartu saldo wallet
  Widget _buildBalanceCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _walletFuture,
      builder: (context, snapshot) {
        String balanceText = 'Memuat saldo...';

        if (snapshot.hasData) {
          final balance = (snapshot.data!['balance'] as num).toInt();

          balanceText = _isBalanceVisible
              ? _formatRupiah(balance)
              : 'Rp ••••••••';
        } else if (snapshot.hasError) {
          balanceText = 'Gagal memuat saldo';
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: primaryPurple,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
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

                // Informasi saldo
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
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: snapshot.hasError
                                ? Text(
                                    balanceText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      balanceText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                          if (snapshot.hasError)
                            IconButton(
                              onPressed: _refreshData,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              tooltip: 'Muat ulang saldo',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (snapshot.hasData)
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
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Menampilkan ornamen awan megamendung
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

  // Membuka halaman ringkasan keuangan
  Widget _buildSummaryShortcut(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinancialSummaryPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insights_outlined, color: primaryPurple),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Keuangan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Rekap pemasukan & pengeluaran',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Membuat tombol menu utama
  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primaryPurple, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan tiga transaksi terakhir dari API
  Widget _buildRecentTransactions() {
    return FutureBuilder<TransactionPageResult>(
      future: _transactionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: primaryPurple),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gagal memuat transaksi.',
                  style: TextStyle(color: textColor),
                ),
                TextButton(
                  onPressed: _refreshData,
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(color: primaryPurple),
                  ),
                ),
              ],
            ),
          );
        }

        final transactions = snapshot.data?.transactions ?? [];

        if (transactions.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 36),
                SizedBox(height: 10),
                Text(
                  'Belum ada transaksi.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Mengambil tiga transaksi paling baru
        final recentTransactions = transactions.take(3).toList();

        return Column(
          children: recentTransactions.map((transaction) {
            final isIncoming = transaction.isIncoming;
            final isSuccess = transaction.status == 'SUCCESS';

            final title = _getTransactionTitle(transaction.type);
            final icon = _getTransactionIcon(transaction.type);

            final amount = _formatRupiah(transaction.amount);
            final displayAmount = isIncoming ? '+ $amount' : '- $amount';

            return Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEDE7F6),
                  child: Icon(icon, color: primaryPurple),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(transaction.createdAt)),
                    const SizedBox(height: 3),
                    Text(
                      isSuccess ? 'Berhasil' : 'Gagal',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  displayAmount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: !isSuccess
                        ? Colors.grey
                        : isIncoming
                        ? Colors.green
                        : Colors.redAccent,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Menentukan nama transaksi berdasarkan jenisnya
  String _getTransactionTitle(String type) {
    switch (type) {
      case 'TOP_UP':
        return 'Isi Saldo';
      case 'TRANSFER_IN':
        return 'Transfer Masuk';
      case 'TRANSFER_OUT':
        return 'Transfer Keluar';
      case 'PAYMENT':
        return 'Pembayaran';
      case 'WITHDRAW':
        return 'Tarik Saldo';
      default:
        return 'Transaksi';
    }
  }

  // Menentukan ikon transaksi berdasarkan jenisnya
  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'TOP_UP':
        return Icons.add_circle_outline;
      case 'TRANSFER_IN':
      case 'TRANSFER_OUT':
        return Icons.send_outlined;
      case 'PAYMENT':
        return Icons.payment_outlined;
      case 'WITHDRAW':
        return Icons.account_balance_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  // Membuka halaman Isi Saldo dan memperbarui data setelah berhasil
  Future<void> _openTopUp() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TopUpPage()),
    );

    if (result == true && mounted) {
      await _refreshData();
    }
  }

  // Membuka halaman Transfer dan memperbarui data setelah berhasil
  Future<void> _openTransfer() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TransferPage()),
    );

    if (result == true && mounted) {
      await _refreshData();
    }
  }

  // Membuka halaman Pembayaran dan memperbarui data setelah berhasil
  Future<void> _openPayment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PaymentPage()),
    );

    if (result == true && mounted) {
      await _refreshData();
    }
  }

  // Membuka halaman Tarik Saldo dan memperbarui data setelah berhasil
  Future<void> _openWithdraw() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WithdrawPage()),
    );

    if (result == true && mounted) {
      await _refreshData();
    }
  }
}
