import 'package:flutter/material.dart';

import '../../authentication/models/user_model.dart';
import '../../authentication/services/auth_service.dart';
import '../../authentication/widgets/user_avatar.dart';
import '../../notification/widgets/notification_bell_button.dart';
import '../../payment/pages/payment_page.dart';
import '../../summary/pages/financial_summary_page.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/pages/transaction_history_page.dart';
import '../../transaction/services/transaction_service.dart';
import '../../transfer/pages/transfer_page.dart';
import '../../wallet/services/wallet_service.dart';
import '../../withdraw/pages/withdraw_page.dart';
import 'top_up_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _purple = Color(0xFF673AB7);
  static const Color _text = Color(0xFF2D1B46);

  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();

  late Future<Map<String, dynamic>> _walletFuture;
  late Future<TransactionPageResult> _transactionFuture;
  late Future<UserModel> _userFuture;

  bool _balanceVisible = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _walletFuture = _walletService.getWallet();
    _transactionFuture = _transactionService.getTransactions();
    _userFuture = AuthService.getProfile();
  }

  Future<void> _refreshData() async {
    setState(_loadData);

    try {
      await Future.wait([_walletFuture, _transactionFuture, _userFuture]);
    } catch (_) {
      // Error ditampilkan pada bagian data yang gagal dimuat.
    }
  }

  String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
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
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day ${months[date.month - 1]} ${date.year} • $hour:$minute';
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFF3EEFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _text,
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
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

    if (confirmed != true) return;

    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

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
      child: Icon(Icons.person, color: _purple),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _purple,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                _buildBalanceCard(),
                const SizedBox(height: 16),
                _buildSummaryShortcut(),
                const SizedBox(height: 28),
                const Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActions(),
                const SizedBox(height: 28),
                _buildRecentTransactionsHeader(),
                _buildRecentTransactions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: widget.onProfileTap,
            borderRadius: BorderRadius.circular(30),
            child: FutureBuilder<UserModel>(
              future: _userFuture,
              builder: (context, snapshot) {
                final user = snapshot.data;
                final name = snapshot.hasError
                    ? 'Mahasiswa FTI!'
                    : user != null
                    ? '${user.name}!'
                    : 'Memuat profil...';

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
                              color: _text,
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
          icon: const Icon(Icons.logout, color: _purple),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _walletFuture,
      builder: (context, snapshot) {
        final rawBalance = snapshot.data?['balance'];
        final balance = rawBalance is num ? rawBalance.toInt() : 0;

        final String balanceText;
        if (snapshot.hasError) {
          balanceText = 'Gagal memuat saldo';
        } else if (!snapshot.hasData) {
          balanceText = 'Memuat saldo...';
        } else {
          balanceText = _balanceVisible
              ? _formatRupiah(balance)
              : 'Rp ••••••••';
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _purple,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -20,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.13,
                      child: Image.asset(
                        'assets/images/mega_mendung.png',
                        width: 230,
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(width: 10),
                          Text(
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
                        children: [
                          Expanded(
                            child: Text(
                              balanceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (snapshot.hasData)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _balanceVisible = !_balanceVisible;
                                });
                              },
                              tooltip: _balanceVisible
                                  ? 'Sembunyikan saldo'
                                  : 'Tampilkan saldo',
                              icon: Icon(
                                _balanceVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white,
                              ),
                            ),
                          if (snapshot.hasError)
                            IconButton(
                              onPressed: _refreshData,
                              tooltip: 'Muat ulang saldo',
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
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

  Widget _buildSummaryShortcut() {
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
        child: const Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFEDE7F6),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.insights_outlined, color: _purple),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Keuangan',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _text),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Rekap pemasukan & pengeluaran',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
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
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required Future<void> Function() onTap,
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
              child: Icon(icon, color: _purple, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Transaksi Terakhir',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _text,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const TransactionHistoryPage(showBackButton: true),
              ),
            );
          },
          child: const Text('Lihat Semua', style: TextStyle(color: _purple)),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return FutureBuilder<TransactionPageResult>(
      future: _transactionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: _purple)),
          );
        }

        if (snapshot.hasError) {
          return _transactionMessage(
            icon: Icons.error_outline,
            message: 'Gagal memuat transaksi.',
            action: TextButton(
              onPressed: _refreshData,
              child: const Text('Coba Lagi', style: TextStyle(color: _purple)),
            ),
          );
        }

        final transactions = snapshot.data?.transactions ?? [];

        if (transactions.isEmpty) {
          return _transactionMessage(
            icon: Icons.receipt_long_outlined,
            message: 'Belum ada transaksi.',
          );
        }

        return Column(
          children: transactions.take(3).map((transaction) {
            final isIncoming = transaction.isIncoming;
            final isSuccess = transaction.status == 'SUCCESS';
            final amount = _formatRupiah(transaction.amount);

            return Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEDE7F6),
                  child: Icon(
                    _transactionIcon(transaction.type),
                    color: _purple,
                  ),
                ),
                title: Text(
                  _transactionTitle(transaction.type),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _text,
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
                  isIncoming ? '+ $amount' : '- $amount',
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

  Widget _transactionMessage({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  String _transactionTitle(String type) {
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

  IconData _transactionIcon(String type) {
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

  Future<void> _openTopUp() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TopUpPage()),
    );
    if (result == true && mounted) await _refreshData();
  }

  Future<void> _openTransfer() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TransferPage()),
    );
    if (result == true && mounted) await _refreshData();
  }

  Future<void> _openPayment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PaymentPage()),
    );
    if (result == true && mounted) await _refreshData();
  }

  Future<void> _openWithdraw() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WithdrawPage()),
    );
    if (result == true && mounted) await _refreshData();
  }
}
