import 'package:flutter/material.dart';

import '../../transaction/models/transaction_model.dart';
import '../../transaction/pages/transaction_detail_page.dart';
import '../services/merchant_dashboard_service.dart';

class MerchantTransactionHistoryPage extends StatefulWidget {
  const MerchantTransactionHistoryPage({
    super.key,
    this.initialPeriod = 'monthly',
    this.initialFrom,
    this.initialTo,
    this.initialSubcategory,
  });

  final String initialPeriod;
  final DateTime? initialFrom;
  final DateTime? initialTo;
  final String? initialSubcategory;

  @override
  State<MerchantTransactionHistoryPage> createState() =>
      MerchantTransactionHistoryPageState();
}

class MerchantTransactionHistoryPageState
    extends State<MerchantTransactionHistoryPage> {
  static const Color _purple = Color(0xFF673AB7);
  static const Color _text = Color(0xFF2D1B46);
  static const Color _border = Color(0xFFD1C4E9);
  static const String _allCategories = '__all__';

  static const Map<String, String> _periods = {
    'weekly': 'Mingguan',
    'monthly': 'Bulanan',
    'yearly': 'Tahunan',
  };

  final MerchantDashboardService _service = MerchantDashboardService();
  final List<TransactionModel> _transactions = [];

  late String _period;
  late String _selectedCategory;
  DateTimeRange? _customRange;

  List<MerchantCategoryData> _categories = [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();

    _period = _periods.containsKey(widget.initialPeriod)
        ? widget.initialPeriod
        : 'monthly';
    _selectedCategory = widget.initialSubcategory ?? _allCategories;

    if (widget.initialFrom != null && widget.initialTo != null) {
      _period = 'custom';
      _customRange = DateTimeRange(
        start: widget.initialFrom!,
        end: widget.initialTo!,
      );
    }

    _loadCategories();
    _loadMore();
  }

  Future<void> _loadCategories() async {
    try {
      final dashboard = await _service.getDashboard(period: 'yearly');
      if (!mounted) return;

      setState(() {
        _categories = dashboard.categories;
      });
    } catch (_) {
      // Riwayat bisa menampilkan semua kategori
    }
  }

  // mengarahakan Riwayat dari home ke page ini
  void selectCategory(String? subcategory) {
    final nextCategory = subcategory ?? _allCategories;
    if (_selectedCategory == nextCategory) return;

    setState(() {
      _selectedCategory = nextCategory;
    });
    _loadMore(reset: true);
  }

  Future<void> _changePeriod(String? value) async {
    if (value == null || value == 'custom') return;

    setState(() {
      _period = value;
      _customRange = null;
    });

    await _loadMore(reset: true);
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
              primary: _purple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _text,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliestDate = DateTime(2024, 1, 1);

    var startDate = _customRange?.start ?? DateTime(now.year, now.month, 1);
    var endDate = _customRange?.end ?? today;

    if (endDate.isAfter(today)) endDate = today;
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
                        color: _text,
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
                      value: _formatSingleDate(startDate),
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
                      value: _formatSingleDate(endDate),
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
                                foregroundColor: _text,
                                side: const BorderSide(color: _border),
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
                                backgroundColor: _purple,
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

    if (selectedRange == null) return;

    setState(() {
      _period = 'custom';
      _customRange = selectedRange;
    });

    await _loadMore(reset: true);
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
            color: _text,
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
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: _purple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: _purple,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading || (!_hasMore && !reset)) return;

    setState(() {
      _loading = true;
      _error = null;

      if (reset) {
        _transactions.clear();
        _nextCursor = null;
        _hasMore = true;
      }
    });

    try {
      final page = await _service.getIncomingPayments(
        cursor: _nextCursor,
        period: _period,
        from: _customRange?.start,
        to: _customRange?.end,
        subcategory: _selectedCategory == _allCategories
            ? null
            : _selectedCategory,
      );

      if (!mounted) return;

      setState(() {
        _transactions.addAll(page.transactions);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _loadMore(reset: true);

  String _formatRupiah(int amount) {
    final digits = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $digits';
  }

  String _formatSingleDate(DateTime date) {
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

  String _formatDateTime(DateTime date) {
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day ${_formatSingleDate(localDate).split(' ').skip(1).join(' ')}'
        ' • $hour:$minute';
  }

  Widget _buildFilters() {
    final isCustom = _customRange != null;

    final categoryOptions = <String, String>{
      _allCategories: 'Semua kategori',
      for (final category in _categories)
        (category.subcategory ?? category.name): category.name,
    };

    final selectedCategory = categoryOptions.containsKey(_selectedCategory)
        ? _selectedCategory
        : _allCategories;

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
                  border: Border.all(color: isCustom ? _border : _purple),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: isCustom ? 'custom' : _period,
                    isDense: true,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _purple,
                      size: 20,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _text,
                    ),
                    items: [
                      ..._periods.entries.map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      ),
                      if (isCustom)
                        const DropdownMenuItem(
                          value: 'custom',
                          child: Text('Custom'),
                        ),
                    ],
                    onChanged: _changePeriod,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _pickDateRange,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isCustom ? const Color(0xFFF3EEFC) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCustom ? _border : const Color(0xFFE6E0EE),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 17,
                          color: _purple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isCustom
                                ? '${_formatSingleDate(_customRange!.start)} – '
                                      '${_formatSingleDate(_customRange!.end)}'
                                : 'Pilih tanggal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _text,
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
                value: selectedCategory,
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(Icons.filter_list_rounded, color: _purple),
                style: const TextStyle(
                  fontSize: 13,
                  color: _text,
                  fontWeight: FontWeight.w600,
                ),
                items: categoryOptions.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value != null) selectCategory(value);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isWithdraw = transaction.type == 'WITHDRAW';
    final isSuccess = transaction.status == 'SUCCESS';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                TransactionDetailPage(transactionId: transaction.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isWithdraw
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  color: _purple,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWithdraw
                          ? 'Pencairan Otomatis'
                          : transaction.counterpartName ??
                                'Pembayaran pelanggan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.description ??
                          (isWithdraw
                              ? 'Pencairan saldo merchant'
                              : 'Pembayaran masuk'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatDateTime(transaction.createdAt),
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
                    '${isWithdraw ? '−' : '+'} ${_formatRupiah(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isWithdraw ? _purple : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isSuccess ? 'Berhasil' : transaction.status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSuccess ? Colors.green : Colors.redAccent,
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

  Widget _buildList() {
    if (_transactions.isEmpty && _loading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator(color: _purple)),
        ],
      );
    }

    if (_transactions.isEmpty && _error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 130),
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _refresh,
              child: const Text('Coba lagi'),
            ),
          ),
        ],
      );
    }

    if (_transactions.isEmpty) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 130),
          Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 44),
          SizedBox(height: 12),
          Center(child: Text('Belum ada transaksi pada periode ini.')),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount:
          _transactions.length +
          (_hasMore || _loading || _error != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _transactions.length) {
          if (_error != null) {
            return TextButton(
              onPressed: _loadMore,
              child: const Text('Gagal memuat. Coba lagi'),
            );
          }

          if (_loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: _purple)),
            );
          }

          return TextButton(
            onPressed: _loadMore,
            child: const Text('Muat transaksi lainnya'),
          );
        }

        return _buildTransactionCard(_transactions[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(color: _text, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F6FC),
        foregroundColor: _text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              color: _purple,
              onRefresh: _refresh,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }
}
