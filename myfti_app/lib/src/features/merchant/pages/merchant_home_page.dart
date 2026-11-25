import 'package:flutter/material.dart';

import '../../../core/services/session_service.dart';
import '../../authentication/models/user_model.dart';
import '../../authentication/services/auth_service.dart';
import '../../authentication/widgets/user_avatar.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/services/transaction_service.dart';
import '../../wallet/services/wallet_service.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
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

  // Memuat saldo dan transaksi merchant.
  void _loadData() {
    _walletFuture = _walletService.getWallet();
    _transactionFuture = _transactionService.getTransactions();
  }

  // Memuat ulang saldo, profil, dan transaksi.
  Future<void> _refreshData() async {
    setState(() {
      _loadData();
      _userFuture = AuthService.getProfile();
    });

    try {
      await Future.wait([_walletFuture, _transactionFuture, _userFuture]);
    } catch (_) {
      // Error ditampilkan melalui FutureBuilder masing-masing.
    }
  }

  String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

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

  String _formatTransactionStatus(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return 'Berhasil';
      case 'PENDING':
        return 'Diproses';
      case 'FAILED':
        return 'Gagal';
      default:
        return status;
    }
  }

  int? _getBalance(Map<String, dynamic>? data) {
    final value = data?['balance'];

    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);

    return null;
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun myFTI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: Colors.redAccent),
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

  // Avatar merchant.
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
      child: Icon(Icons.store_outlined, color: primaryPurple),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: primaryPurple,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header merchant.
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<UserModel>(
                        future: _userFuture,
                        builder: (context, snapshot) {
                          final user = snapshot.data;

                          final String name;
                          if (snapshot.hasError) {
                            name = 'Merchant!';
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    if (user != null)
                                      Text(
                                        user.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
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
                    IconButton(
                      onPressed: _confirmLogout,
                      tooltip: 'Keluar',
                      icon: const Icon(Icons.logout, color: primaryPurple),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Saldo merchant.
                _buildBalanceCard(),

                const SizedBox(height: 28),

                // Pembayaran masuk.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pembayaran Masuk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Terbaru',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _buildRecentPayments(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Kartu saldo merchant.
  Widget _buildBalanceCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _walletFuture,
      builder: (context, snapshot) {
        String balanceText = 'Memuat saldo...';

        if (snapshot.hasData) {
          final balance = _getBalance(snapshot.data);

          if (balance != null) {
            balanceText = _isBalanceVisible
                ? _formatRupiah(balance)
                : 'Rp ••••••••';
          } else {
            balanceText = 'Saldo tidak tersedia';
          }
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

                          if (snapshot.hasData &&
                              _getBalance(snapshot.data) != null)
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

  // Ornamen awan Megamendung.
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

  // Tiga pembayaran masuk terbaru.
  Widget _buildRecentPayments() {
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
                  'Gagal memuat pembayaran masuk.',
                  textAlign: TextAlign.center,
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

        final payments =
            (snapshot.data?.transactions ?? [])
                .where((transaction) => transaction.type == 'PAYMENT_IN')
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (payments.isEmpty) {
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
                  'Belum ada pembayaran masuk.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final recentPayments = payments.take(3).toList();

        return Column(
          children: recentPayments.map((transaction) {
            final isSuccess = transaction.status == 'SUCCESS';
            final isPending = transaction.status == 'PENDING';

            final statusColor = isSuccess
                ? Colors.green
                : isPending
                ? Colors.orange
                : Colors.red;

            return Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(Icons.south_west_rounded, color: primaryPurple),
                ),
                title: Text(
                  transaction.counterpartName ?? 'Pembayaran Mahasiswa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                      _formatTransactionStatus(transaction.status),
                      style: TextStyle(fontSize: 11, color: statusColor),
                    ),
                  ],
                ),
                trailing: Text(
                  '+ ${_formatRupiah(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSuccess ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
