import 'package:flutter/material.dart';

import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

enum SortOption { newest, oldest }

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isFetching = false;
  String? _refreshErrorMessage;
  SortOption _sortOption = SortOption.newest;

  final TransactionService _transactionService = TransactionService();
  final ScrollController _scrollController = ScrollController();

  List<TransactionModel> _transactions = [];

  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTransactions();
    _startAutoRefresh();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadTransactions() async {
    if (!mounted || _isFetching) return;

    _isFetching = true;

    if (_transactions.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await _transactionService.getTransactions(
        sort: _sortOption == SortOption.oldest ? 'asc' : 'desc',
      );

      if (!mounted) return;

      setState(() {
        _transactions = result.transactions;
        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
        _errorMessage = null;
        _refreshErrorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        if (_transactions.isEmpty) {
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
        } else {
          _refreshErrorMessage = error.toString().replaceFirst(
            'Exception: ',
            '',
          );
        }

        _isLoading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshTransactionsSilently(),
    );
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _transactionService.getTransactions(
        cursor: _nextCursor,
        sort: _sortOption == SortOption.oldest ? 'asc' : 'desc',
      );

      if (!mounted) return;

      setState(() {
        final existingIds = _transactions.map((e) => e.id).toSet();

        _transactions.addAll(
          result.transactions.where((e) => !existingIds.contains(e.id)),
        );

        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _refreshErrorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTransactionsSilently();
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  Future<void> _refreshTransactionsSilently() async {
    if (!mounted || _isFetching) return;

    _isFetching = true;

    try {
      final result = await _transactionService.getTransactions(
        sort: _sortOption == SortOption.oldest ? 'asc' : 'desc',
      );

      if (!mounted) return;

      setState(() {
        final updated = {
          for (final transaction in _transactions) transaction.id: transaction,
        };

        for (final transaction in result.transactions) {
          updated[transaction.id] = transaction;
        }

        _transactions = updated.values.toList()
          ..sort(
            (a, b) => _sortOption == SortOption.oldest
                ? a.createdAt.compareTo(b.createdAt)
                : b.createdAt.compareTo(a.createdAt),
          );

        if (_nextCursor == null) {
          _nextCursor = result.nextCursor;
          _hasMore = result.hasMore;
        }

        _errorMessage = null;
        _refreshErrorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _refreshErrorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
            Icon(Icons.receipt_long_outlined, size: 55, color: Colors.grey),
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
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: transactions.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      controller: _scrollController,
      itemBuilder: (context, index) {
        if (index >= transactions.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

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

    final String sign = isFailed ? '' : (isIncoming ? '+' : '-');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.card.withValues(alpha: 0.7)),
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
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),

                const SizedBox(height: 5),

                Text(
                  '${_formatDate(transaction.createdAt)} • ${_formatTime(transaction.createdAt)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                  color: isFailed ? AppColors.error : AppColors.success,
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
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTransactions,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  if (_refreshErrorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.orange.withValues(alpha: 0.08),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sync_problem,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Unable to refresh transactions. Showing previous data.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTransactionList('all'),
                        _buildTransactionList('incoming'),
                        _buildTransactionList('outgoing'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
