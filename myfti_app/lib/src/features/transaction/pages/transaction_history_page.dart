import 'package:flutter/material.dart';

import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'transaction_detail_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  final bool showBackButton;

  const TransactionHistoryPage({super.key, this.showBackButton = false});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isFetching = false;
  String? _refreshErrorMessage;
  String _period = 'monthly';
  DateTimeRange? _customRange;
  String _selectedFlow = 'all';
  int _requestVersion = 0;

  final TransactionService _transactionService = TransactionService();
  final ScrollController _scrollController = ScrollController();

  List<TransactionModel> _transactions = [];

  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool _isLoading = true;
  String? _errorMessage;

  DateTime get _dateFrom {
    if (_customRange != null) return _customRange!.start;

    final now = DateTime.now();

    switch (_period) {
      case 'weekly':
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));

      case 'yearly':
        return DateTime(now.year);

      default:
        return DateTime(now.year, now.month);
    }
  }

  DateTime get _dateTo {
    if (_customRange != null) {
      return DateTime(
        _customRange!.end.year,
        _customRange!.end.month,
        _customRange!.end.day,
        23,
        59,
        59,
        999,
      );
    }

    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _loadTransactions();
    _startAutoRefresh();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadTransactions() async {
    final requestVersion = ++_requestVersion;

    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _nextCursor = null;
      _hasMore = true;
      _errorMessage = null;
      _refreshErrorMessage = null;
    });

    try {
      final result = await _transactionService.getTransactions(
        sort: 'desc',
        from: _dateFrom,
        to: _dateTo,
      );

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        _transactions = result.transactions;
        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        _errorMessage = 'Gagal memuat riwayat transaksi. Silakan coba lagi.';
        _isLoading = false;
      });
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
    if (_isLoading || _isLoadingMore || !_hasMore || _nextCursor == null) {
      return;
    }

    final requestVersion = _requestVersion;
    final cursor = _nextCursor;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _transactionService.getTransactions(
        cursor: cursor,
        sort: 'desc',
        from: _dateFrom,
        to: _dateTo,
      );

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        final existingIds = _transactions.map((item) => item.id).toSet();

        _transactions.addAll(
          result.transactions.where((item) => !existingIds.contains(item.id)),
        );

        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        _refreshErrorMessage =
            'Gagal memuat transaksi lainnya. Silakan coba lagi.';
        _isLoadingMore = false;
      });
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
    if (!mounted || _isFetching || _isLoading || _isLoadingMore) return;

    _isFetching = true;
    final requestVersion = _requestVersion;

    try {
      final result = await _transactionService.getTransactions(
        sort: 'desc',
        from: _dateFrom,
        to: _dateTo,
      );

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        final updated = {
          for (final transaction in _transactions) transaction.id: transaction,
        };

        for (final transaction in result.transactions) {
          updated[transaction.id] = transaction;
        }

        _transactions = updated.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (_nextCursor == null) {
          _nextCursor = result.nextCursor;
          _hasMore = result.hasMore;
        }

        _refreshErrorMessage = null;
      });
    } catch (_) {
      if (mounted && requestVersion == _requestVersion) {
        setState(() {
          _refreshErrorMessage =
              'Gagal memperbarui riwayat transaksi. Silakan coba lagi.';
        });
      }
    } finally {
      _isFetching = false;
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

  List<TransactionModel> _getTransactions() {
    List<TransactionModel> result = List.from(_transactions);

    if (_selectedFlow == 'incoming') {
      result = result.where((item) => item.isIncoming).toList();
    } else if (_selectedFlow == 'outgoing') {
      result = result.where((item) => item.isOutgoing).toList();
    }

    result = result.where((item) {
      final date = item.createdAt;
      return !date.isBefore(_dateFrom) && !date.isAfter(_dateTo);
    }).toList();

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<DateTime?> _showDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String helpText,
  }) {
    final safeInitialDate = initialDate.isBefore(firstDate)
        ? firstDate
        : initialDate.isAfter(lastDate)
        ? lastDate
        : initialDate;

    return showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF673AB7),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2D1B46),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliestDate = DateTime(2024, 1, 1);

    var startDate = _customRange?.start ?? DateTime(now.year, now.month, 1);
    var endDate = _customRange?.end ?? today;

    if (endDate.isAfter(today)) endDate = today;
    if (startDate.isBefore(earliestDate)) startDate = earliestDate;
    if (startDate.isAfter(endDate)) startDate = endDate;

    final selectedRange = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Pilih Rentang Tanggal',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D1B46),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tentukan tanggal mulai dan akhir riwayat.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 18),
                    _datePickerField(
                      label: 'Tanggal Mulai',
                      value: _formatDate(startDate),
                      onTap: () async {
                        final picked = await _showDatePicker(
                          initialDate: startDate,
                          firstDate: earliestDate,
                          lastDate: today,
                          helpText: 'Pilih Tanggal Mulai',
                        );

                        if (picked == null) return;

                        setSheetState(() {
                          startDate = picked;

                          if (endDate.isBefore(startDate)) {
                            endDate = startDate;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _datePickerField(
                      label: 'Tanggal Akhir',
                      value: _formatDate(endDate),
                      onTap: () async {
                        final picked = await _showDatePicker(
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: today,
                          helpText: 'Pilih Tanggal Akhir',
                        );

                        if (picked == null) return;

                        setSheetState(() {
                          endDate = picked;
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2D1B46),
                                side: const BorderSide(
                                  color: Color(0xFFD1C4E9),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(
                                  sheetContext,
                                  DateTimeRange(start: startDate, end: endDate),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF673AB7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Terapkan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selectedRange == null || !mounted) return;

    setState(() {
      _period = 'custom';
      _customRange = selectedRange;
      _nextCursor = null;
      _hasMore = true;
    });

    await _loadTransactions();
  }

  Widget _datePickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D1B46),
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: const Color(0xFFF8F6FC),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD1C4E9)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFF673AB7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D1B46),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: Color(0xFF673AB7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilters() {
    final label = _customRange == null
        ? null
        : '${_formatDate(_customRange!.start)} – ${_formatDate(_customRange!.end)}';

    const flowOptions = <String, String>{
      'all': 'Semua transaksi',
      'incoming': 'Pemasukan',
      'outgoing': 'Pengeluaran',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _customRange != null
                        ? const Color(0xFFD1C4E9)
                        : AppColors.primary,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _customRange != null ? 'custom' : _period,
                    isDense: true,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Mingguan'),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Bulanan'),
                      ),
                      DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      if (value == 'custom') {
                        _selectDateRange();
                        return;
                      }

                      setState(() {
                        _period = value;
                        _customRange = null;
                        _nextCursor = null;
                        _hasMore = true;
                      });

                      _loadTransactions();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _selectDateRange,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _customRange != null
                          ? const Color(0xFFF3EEFC)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _customRange != null
                            ? const Color(0xFFD1C4E9)
                            : const Color(0xFFE6E0EE),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 17,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label ?? 'Pilih tanggal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6E0EE)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFlow,
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.primary,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
                items: flowOptions.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedFlow = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle(TransactionModel transaction) {
    switch (transaction.type) {
      case 'TOP_UP':
        return 'Isi Saldo';
      case 'TRANSFER_IN':
        return 'Transfer Masuk';
      case 'TRANSFER_OUT':
        return 'Transfer Keluar';
      case 'PAYMENT':
        return 'Pembayaran';
      case 'WITHDRAW':
        return 'Tarik Tunai';
      default:
        return 'Transaksi';
    }
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

  Widget _buildTransactionList() {
    final transactions = _getTransactions();

    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 55, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Tidak ada transaksi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Transaksi Anda akan muncul di sini.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    final status = transaction.status.toUpperCase();
    final isFailed = transaction.status == 'FAILED';

    final statusColor = switch (status) {
      'SUCCESS' => AppColors.success,
      'PENDING' => Colors.orange.shade700,
      'FAILED' => AppColors.error,
      _ => Colors.grey,
    };

    final Color transactionColor = isFailed
        ? Colors.grey
        : isIncoming
        ? AppColors.success
        : AppColors.error;

    final String sign = isFailed ? '' : (isIncoming ? '+' : '-');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TransactionDetailPage(transactionId: transaction.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
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
                          'Transaksi myFTI',
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
                    _formatTransactionStatus(transaction.status),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                _buildDateFilters(),
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
                            'Gagal memperbarui transaksi. Menampilkan data sebelumnya.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildTransactionList()),
              ],
            ),
    );
  }
}
