import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../services/summary_service.dart';

class FinancialSummaryPage extends StatefulWidget {
  const FinancialSummaryPage({super.key});

  @override
  State<FinancialSummaryPage> createState() => _FinancialSummaryPageState();
}

class _CategoryMeta {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _ChartSegment {
  final String label;
  final int amount;
  final Color color;

  const _ChartSegment({
    required this.label,
    required this.amount,
    required this.color,
  });
}

class _FinancialSummaryPageState extends State<FinancialSummaryPage> {
  static const Color _borderColor = Color(0xFFD1C4E9);
  static const Color _calmError = Color(0xFFD9534F);
  static const Color _warningAmber = Color(0xFFF9A825);

  static const Set<String> _incomeTypes = {
    'TOP_UP',
    'TRANSFER_IN',
    'PAYMENT_IN',
  };

  static const Map<String, String> _presetPeriods = {
    'weekly': 'Mingguan',
    'monthly': 'Bulanan',
    'yearly': 'Tahunan',
  };

  String _period = 'monthly';
  DateTimeRange? _customRange;
  bool _showIncomeTab = false;
  bool _loading = true;
  String? _error;
  FinancialSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await SummaryService.getSummary(
        period: _period,
        from: _customRange?.start,
        to: _customRange?.end,
      );

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _changePreset(String? value) {
    if (value == null || value == 'custom') return;
    if (value == _period && _customRange == null) return;
    setState(() {
      _period = value;
      _customRange = null;
    });
    _load();
  }

  Future<DateTime?> _showSystemDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String helpText,
  }) {
    final safeInitial = initialDate.isBefore(firstDate)
        ? firstDate
        : (initialDate.isAfter(lastDate) ? lastDate : initialDate);

    return showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.text,
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
    final earliest = DateTime(2024, 1, 1);

    DateTime startDate;
    DateTime endDate;

    if (_customRange != null) {
      startDate = _customRange!.start;
      endDate = _customRange!.end;
    } else if (_summary?.from != null && _summary?.to != null) {
      final f = _summary!.from!.toLocal();
      final t = _summary!.to!.toLocal();
      startDate = DateTime(f.year, f.month, f.day);
      endDate = DateTime(t.year, t.month, t.day);
    } else {
      startDate = DateTime(now.year, now.month, 1);
      endDate = today;
    }

    if (endDate.isAfter(today)) endDate = today;
    if (startDate.isAfter(endDate)) startDate = endDate;

    final picked = await showModalBottomSheet<DateTimeRange>(
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
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tentukan tanggal mulai dan akhir laporan keuangan.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 18),
                    _datePickerField(
                      label: 'Tanggal Mulai',
                      value: _formatSingleDate(startDate),
                      onTap: () async {
                        final selected = await _showSystemDatePicker(
                          initialDate: startDate,
                          firstDate: earliest,
                          lastDate: today,
                          helpText: 'Pilih Tanggal Mulai',
                        );
                        if (selected == null) return;
                        setSheetState(() {
                          startDate = selected;
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
                        final selected = await _showSystemDatePicker(
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: today,
                          helpText: 'Pilih Tanggal Akhir',
                        );
                        if (selected == null) return;
                        setSheetState(() => endDate = selected);
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
                                foregroundColor: AppColors.text,
                                side: const BorderSide(color: _borderColor),
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
                              onPressed: () => Navigator.pop(
                                sheetContext,
                                DateTimeRange(start: startDate, end: endDate),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
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

    if (picked == null || !mounted) return;

    setState(() {
      _customRange = picked;
      _period = 'custom';
    });
    _load();
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
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatSingleDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  _CategoryMeta _metaFor(String type) {
    switch (type) {
      case 'TOP_UP':
        return const _CategoryMeta(
          label: 'Top Up',
          icon: Icons.add_circle_outline_rounded,
          color: Color(0xFF43A047),
        );
      case 'TRANSFER_IN':
        return const _CategoryMeta(
          label: 'Transfer Masuk',
          icon: Icons.south_west_rounded,
          color: Color(0xFF26A69A),
        );
      case 'PAYMENT_IN':
        return const _CategoryMeta(
          label: 'Pembayaran Masuk',
          icon: Icons.storefront_outlined,
          color: Color(0xFF7E57C2),
        );
      case 'PAYMENT':
        return const _CategoryMeta(
          label: 'Pembayaran',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.primary,
        );
      case 'TRANSFER_OUT':
        return const _CategoryMeta(
          label: 'Transfer Keluar',
          icon: Icons.send_rounded,
          color: AppColors.secondary,
        );
      case 'WITHDRAW':
        return const _CategoryMeta(
          label: 'Withdraw',
          icon: Icons.account_balance_outlined,
          color: _calmError,
        );
      default:
        return _CategoryMeta(
          label: type,
          icon: Icons.receipt_long_outlined,
          color: AppColors.secondary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Financial Summary',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTopFilterBar(null),
          const SizedBox(height: 40),
          _buildError(),
        ],
      );
    }

    final summary = _summary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _buildTopFilterBar(summary),
        const SizedBox(height: 16),
        _buildSummaryHeroCard(summary),
        const SizedBox(height: 18),
        _buildCategoryAnalysisCard(summary),
        const SizedBox(height: 18),
        _buildMonthlyComparisonTile(summary),
      ],
    );
  }

  Widget _buildTopFilterBar(FinancialSummary? summary) {
    final isCustom = _customRange != null;
    final dateText = _customRange != null
        ? _formatDateRange(_customRange!.start, _customRange!.end)
        : _formatDateRange(summary?.from, summary?.to);

    final dropdownEntries = <MapEntry<String, String>>[
      ..._presetPeriods.entries,
      if (isCustom) const MapEntry('custom', 'Custom'),
    ];

    return Row(
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustom ? _borderColor : AppColors.primary,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: isCustom ? 'custom' : _period,
              isDense: true,
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
              items: dropdownEntries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: _changePreset,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: isCustom ? AppColors.card : Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _pickDateRange,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCustom ? AppColors.primary : _borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          dateText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isCustom
                                ? AppColors.primary
                                : AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeroCard(FinancialSummary summary) {
    final ratio = (summary.expensePercentage / 100).clamp(0.0, 1.0);
    final statusColor = ratio < 0.5
        ? AppColors.success
        : ratio < 0.8
            ? _warningAmber
            : _calmError;
    final statusLabel = ratio < 0.5
        ? 'Aman'
        : ratio < 0.8
            ? 'Waspada'
            : 'Tinggi';

    final diffSign = summary.difference > 0 ? '+ ' : '';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF7E57C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Selisih',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$diffSign${formatRupiah(summary.difference)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _heroStatItem(
                        label: 'Pemasukan',
                        amount: summary.income,
                        icon: Icons.south_west_rounded,
                        badgeColor: const Color(0xFF81C784),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _heroStatItem(
                        label: 'Pengeluaran',
                        amount: summary.expense,
                        icon: Icons.north_east_rounded,
                        badgeColor: const Color(0xFFEF9A9A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Persentase Pengeluaran',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      '${summary.expensePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: AppColors.card,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStatItem({
    required String label,
    required int amount,
    required IconData icon,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: badgeColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatRupiah(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryAnalysisCard(FinancialSummary summary) {
    final rows = summary.breakdown
        .where((row) => _showIncomeTab
            ? _incomeTypes.contains(row.type)
            : !_incomeTypes.contains(row.type))
        .toList();

    final tabTotal = _showIncomeTab ? summary.income : summary.expense;
    final segments = rows.map((row) {
      final meta = _metaFor(row.type);
      return _ChartSegment(
        label: meta.label,
        amount: row.total,
        color: meta.color,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSegmentedToggle(),
          const SizedBox(height: 20),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _showIncomeTab
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 38,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _showIncomeTab
                          ? 'Belum ada pemasukan pada periode ini.'
                          : 'Belum ada pengeluaran pada periode ini.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _MultiSegmentDonutPainter(
                      segments: segments,
                      strokeWidth: 16,
                      emptyColor: AppColors.card,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showIncomeTab ? 'Masuk' : 'Keluar',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _compactRupiah(tabTotal),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: segments.map((seg) {
                      final pct =
                          tabTotal == 0 ? 0.0 : (seg.amount / tabTotal) * 100;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: seg.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                seg.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: seg.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.card),
            const SizedBox(height: 8),
            for (var i = 0; i < rows.length; i++) ...[
              _buildCategoryRow(rows[i], tabTotal),
              if (i < rows.length - 1)
                const Divider(height: 1, color: AppColors.card),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentedToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segmentTab(
              label: 'Pengeluaran',
              selected: !_showIncomeTab,
              onTap: () => setState(() => _showIncomeTab = false),
            ),
          ),
          Expanded(
            child: _segmentTab(
              label: 'Pemasukan',
              selected: _showIncomeTab,
              onTap: () => setState(() => _showIncomeTab = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(SummaryBreakdown row, int tabTotal) {
    final meta = _metaFor(row.type);
    final share = tabTotal == 0 ? 0.0 : (row.total / tabTotal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, size: 20, color: meta.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 5,
                    backgroundColor: AppColors.card,
                    valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(row.total),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(share * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparisonTile(FinancialSummary summary) {
    final months = summary.monthlyComparison;
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.table_chart_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          title: const Text(
            'Perbandingan per Bulan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          subtitle: const Text(
            'Rekap 6 bulan terakhir',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          children: [
            const Divider(height: 1, color: AppColors.card),
            if (months.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada data perbandingan bulanan.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 8,
                  columnSpacing: 18,
                  headingRowHeight: 38,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 44,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Bulan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        'Selisih',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                  rows: months.map((item) {
                    final isCurrentMonth =
                        item.year == now.year && item.month == now.month;
                    return DataRow(
                      color: WidgetStateProperty.all(
                        isCurrentMonth
                            ? AppColors.background
                            : Colors.transparent,
                      ),
                      cells: [
                        DataCell(
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isCurrentMonth
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isCurrentMonth
                                  ? AppColors.primary
                                  : AppColors.text,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatRupiah(item.income),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatRupiah(item.expense),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _calmError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatRupiah(item.difference),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: _calmError, size: 40),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _load,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime? from, DateTime? to) {
    if (from == null || to == null) {
      return 'Pilih Tanggal';
    }
    final f = from.toLocal();
    final t = to.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    if (f.year == t.year && f.month == t.month && f.day == t.day) {
      return '${f.day} ${months[f.month - 1]} ${f.year}';
    }
    if (f.year == t.year && f.month == t.month) {
      return '${f.day} – ${t.day} ${months[t.month - 1]} ${t.year}';
    }
    if (f.year == t.year) {
      return '${f.day} ${months[f.month - 1]} – ${t.day} ${months[t.month - 1]} ${t.year}';
    }
    return '${f.day} ${months[f.month - 1]} ${f.year} – ${t.day} ${months[t.month - 1]} ${t.year}';
  }

  String _compactRupiah(int amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (abs >= 1000000000) {
      return '${sign}Rp${(abs / 1000000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000000) {
      return '${sign}Rp${(abs / 1000000).toStringAsFixed(1)}jt';
    }
    if (abs >= 1000) {
      return '${sign}Rp${(abs / 1000).toStringAsFixed(0)}rb';
    }
    return formatRupiah(amount);
  }
}

class _MultiSegmentDonutPainter extends CustomPainter {
  final List<_ChartSegment> segments;
  final double strokeWidth;
  final Color emptyColor;

  const _MultiSegmentDonutPainter({
    required this.segments,
    required this.strokeWidth,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final active = segments.where((s) => s.amount > 0).toList();
    final total = active.fold<int>(0, (sum, s) => sum + s.amount);

    if (total <= 0) {
      canvas.drawCircle(center, radius, paint..color = emptyColor);
      return;
    }

    final gap = active.length > 1 ? 0.04 : 0.0;
    var startAngle = -math.pi / 2;

    for (final seg in active) {
      final rawSweep = (seg.amount / total) * 2 * math.pi;
      final sweep = math.max(0.0, rawSweep - gap);
      if (sweep > 0) {
        canvas.drawArc(
          rect,
          startAngle + gap / 2,
          sweep,
          false,
          paint..color = seg.color,
        );
      }
      startAngle += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MultiSegmentDonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
