import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/transaction_model.dart';

enum SortOption {
  newest,
  oldest,
}

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

class _TransactionHistoryPageState
    extends State<TransactionHistoryPage> {
  SortOption _sortOption = SortOption.newest;

  // Temporary mock data
  // Nanti akan diganti dengan data dari GET /transactions
  final List<TransactionModel> _transactions = [
    TransactionModel(
      id: '1',
      reference: 'TOPUP-001',
      type: 'TOP_UP',
      status: 'SUCCESS',
      amount: 200000,
      description: 'Top Up saldo myFTI',
      createdAt: DateTime(2026, 11, 11, 10, 30),
    ),
    TransactionModel(
      id: '2',
      reference: 'PAY-001',
      type: 'PAYMENT',
      status: 'SUCCESS',
      amount: 50000,
      description: 'Pembayaran Kantin FTI',
      createdAt: DateTime(2026, 11, 10, 14, 20),
    ),
    TransactionModel(
      id: '3',
      reference: 'TRF-001',
      type: 'TRANSFER_OUT',
      status: 'SUCCESS',
      amount: 100000,
      description: 'Transfer ke teman',
      counterpartName: 'Jonathan',
      createdAt: DateTime(2026, 11, 9, 9, 15),
    ),
    TransactionModel(
      id: '4',
      reference: 'TRF-002',
      type: 'TRANSFER_IN',
      status: 'SUCCESS',
      amount: 75000,
      description: 'Transfer diterima',
      counterpartName: 'Michelle',
      createdAt: DateTime(2026, 11, 8, 16, 45),
    ),
    TransactionModel(
      id: '5',
      reference: 'WD-001',
      type: 'WITHDRAW',
      status: 'FAILED',
      amount: 50000,
      description: 'Withdraw ke rekening bank',
      createdAt: DateTime(2026, 11, 7, 11, 0),
    ),
  ];

  List<TransactionModel> _getTransactions(String category) {
    List<TransactionModel> result = List.from(_transactions);

    if (category == 'incoming') {
      result = result.where((item) => item.isIncoming).toList();
    } else if (category == 'outgoing') {
      result = result.where((item) => item.isOutgoing).toList();
    }

    result.sort((a, b) {
      if (_sortOption == SortOption.newest) {
        return b.createdAt.compareTo(a.createdAt);
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    return result;
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _getTitle(TransactionModel transaction) {
    switch (transaction.type) {
      case 'TOP_UP':
        return 'Top Up';
      case 'TRANSFER_IN':
        return 'Transfer Received';
      case 'TRANSFER_OUT':
        return 'Transfer';
      case 'PAYMENT':
        return 'Payment';
      case 'WITHDRAW':
        return 'Withdraw';
      default:
        return 'Transaction';
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'TOP_UP':
        return Icons.add_circle_outline;
      case 'TRANSFER_IN':
      case 'TRANSFER_OUT':
        return Icons.swap_horiz_rounded;
      case 'PAYMENT':
        return Icons.shopping_bag_outlined;
      case 'WITHDRAW':
        return Icons.account_balance_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _buildTransactionList(String category) {
    final transactions = _getTransactions(category);

    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 55,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Your transactions will appear here.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      itemCount: transactions.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTransactionCard(transactions[index]);
      },
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIncoming = transaction.isIncoming;
    final isFailed = transaction.status == 'FAILED';

    final Color transactionColor = isFailed
        ? Colors.grey
        : isIncoming
            ? AppColors.success
            : AppColors.error;

    final String sign = isIncoming ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.card.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: transactionColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIcon(transaction.type),
              color: transactionColor,
              size: 23,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(transaction),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  transaction.counterpartName ??
                      transaction.description ??
                      'myFTI Transaction',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${_formatDate(transaction.createdAt)} • ${_formatTime(transaction.createdAt)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${_formatCurrency(transaction.amount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: transactionColor,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                transaction.status,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isFailed
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Transaction History',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<SortOption>(
              icon: const Icon(
                Icons.filter_list_rounded,
                color: AppColors.primary,
              ),
              tooltip: 'Sort transactions',
              onSelected: (value) {
                setState(() {
                  _sortOption = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SortOption.newest,
                  child: Text('Newest first'),
                ),
                const PopupMenuItem(
                  value: SortOption.oldest,
                  child: Text('Oldest first'),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTransactionList('all'),
            _buildTransactionList('incoming'),
            _buildTransactionList('outgoing'),
          ],
        ),
      ),
    );
  }
}
