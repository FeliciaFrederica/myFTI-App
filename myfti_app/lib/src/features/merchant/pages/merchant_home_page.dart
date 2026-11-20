import 'package:flutter/material.dart';

import 'dart:async';

import '../../../core/services/session_service.dart';
import '../../authentication/models/user_model.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/services/transaction_service.dart';
import '../../wallet/services/wallet_service.dart';
import '../../authentication/services/auth_service.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  String _selectedFilter = 'All Time';
  static const Color primaryPurple = Color(0xFF673AB7);

  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();

  late Future<UserModel?> _userFuture;

  Map<String, dynamic>? _wallet;
  List<TransactionModel> _transactions = [];

  bool _isLoadingWallet = true;
  bool _isLoadingTransactions = true;

  String? _walletError;
  String? _transactionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userFuture = SessionService.getUser();
    _loadDashboard();
    _startAutoRefresh();
  }

  Future<void> _loadDashboard() async {
    await Future.wait([_loadWallet(), _loadTransactions()]);
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshDashboardSilently(),
    );
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDashboardSilently();
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  Future<void> _refreshDashboardSilently() async {
    if (!mounted || _isRefreshing) return;

    _isRefreshing = true;

    try {
      try {
        final wallet = await _walletService.getWallet();

        if (mounted) {
          setState(() {
            _wallet = wallet;
            _walletError = null;
          });
        }
      } catch (error) {
        if (mounted) {
          setState(() {
            _walletError = error.toString().replaceFirst('Exception: ', '');
          });
        }
      }

      try {
        final result = await _transactionService.getTransactions();

        if (!mounted) return;

        setState(() {
          _transactions = result.transactions
              .where((transaction) => transaction.type == 'PAYMENT')
              .toList();
          _isLoadingTransactions = false;
        });
      } catch (error) {
        if (mounted) {
          setState(() {
            _transactionError = error.toString().replaceFirst(
              'Exception: ',
              '',
            );
          });
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoadingWallet = true;
      _walletError = null;
    });

    try {
      final wallet = await _walletService.getWallet();

      if (!mounted) return;

      setState(() {
        _wallet = wallet;
        _isLoadingWallet = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _walletError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingWallet = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
      _transactionError = null;
    });

    try {
      final result = await _transactionService.getTransactions();

      if (mounted) {
        setState(() {
          _transactions = result.transactions
              .where((item) => item.type == 'PAYMENT')
              .toList();
          _transactionError = null;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _transactionError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingTransactions = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadDashboard();
  }

  Future<void> _logout(BuildContext context) async {
    _stopAutoRefresh();

    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp$formatted';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day} ${months[date.month - 1]} ${date.year} • $hour:$minute';
  }

  int? get _balance {
    final value = _wallet?['balance'];

    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);

    return null;
  }

  List<TransactionModel> get _filteredTransactions {
    final now = DateTime.now();

    if (_selectedFilter == 'All Time') {
      return _transactions;
    }

    if (_selectedFilter == 'This Month') {
      return _transactions.where((transaction) {
        final date = transaction.createdAt;

        return date.year == now.year && date.month == now.month;
      }).toList();
    }

    if (_selectedFilter == 'This Week') {
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final startOfNextWeek = startOfWeek.add(const Duration(days: 7));

      return _transactions.where((transaction) {
        final date = transaction.createdAt;

        return !date.isBefore(startOfWeek) && date.isBefore(startOfNextWeek);
      }).toList();
    }

    return _transactions;
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF9575CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
              ),
              SizedBox(width: 8),
              Text(
                'Merchant Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingWallet)
            const SizedBox(
              height: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (_walletError != null)
            Text(_walletError!, style: const TextStyle(color: Colors.white))
          else
            Text(
              _balance == null
                  ? 'Balance unavailable'
                  : _formatCurrency(_balance!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Your merchant account',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isFailed = transaction.status == 'FAILED';

    final color = isFailed ? Colors.grey : Colors.green;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.south_west_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.counterpartName ?? 'Student Payment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description ?? 'Payment received',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(transaction.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_formatCurrency(transaction.amount)}',
                style: TextStyle(
                  color: isFailed ? Colors.grey : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                transaction.status,
                style: TextStyle(
                  color: isFailed ? Colors.red : Colors.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection() {
    if (_isLoadingTransactions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_transactionError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(_transactionError!, textAlign: TextAlign.center),
              TextButton(
                onPressed: _loadTransactions,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 35),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Text(
              'No payments received yet',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              'Incoming student payments will appear here.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredTransactions.map((transaction) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTransactionCard(transaction),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionFilter() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('All Time'),
          selected: _selectedFilter == 'All Time',
          onSelected: (_) {
            setState(() => _selectedFilter = 'All Time');
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('This Week'),
          selected: _selectedFilter == 'This Week',
          onSelected: (_) {
            setState(() => _selectedFilter = 'This Week');
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('This Month'),
          selected: _selectedFilter == 'This Month',
          onSelected: (_) {
            setState(() => _selectedFilter = 'This Month');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F6FC),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF673AB7)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F6FC),
            appBar: AppBar(
              title: const Text('Merchant Dashboard'),
              backgroundColor: const Color(0xFFF8F6FC),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load user information.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _userFuture = SessionService.getUser();
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F6FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F6FC),
            elevation: 0,
            title: const Text(
              'Merchant Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF673AB7),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            color: primaryPurple,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Welcome back, ${user?.name ?? 'Merchant'}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                _buildBalanceCard(),
                const SizedBox(height: 28),
                const Text(
                  'Incoming Payments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _buildTransactionFilter(),
                const SizedBox(height: 12),
                _buildTransactionSection(),
              ],
            ),
          ),
        );
      },
    );
  }
}
