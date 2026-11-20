import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../services/summary_service.dart';

class FinancialSummaryPage extends StatefulWidget {
  const FinancialSummaryPage({super.key});

  @override
  State<FinancialSummaryPage> createState() => _FinancialSummaryPageState();
}

class _FinancialSummaryPageState extends State<FinancialSummaryPage> {
  static const _periods = <String, String>{
    'weekly': 'Mingguan',
    'monthly': 'Bulanan',
    'yearly': 'Tahunan',
  };

  String _period = 'monthly';
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
      final summary = await SummaryService.getSummary(period: _period);
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

  void _changePeriod(String? value) {
    if (value == null || value == _period) return;
    setState(() => _period = value);
    _load();
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
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildError()
            else if (_summary != null) ...[
              _buildTotals(_summary!),
              const SizedBox(height: 20),
              _buildExpenseIndicator(_summary!),
              const SizedBox(height: 20),
              _buildBreakdown(_summary!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _period,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColors.primary),
          items: _periods.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text('Periode: ${entry.value}'),
                ),
              )
              .toList(),
          onChanged: _changePeriod,
        ),
      ),
    );
  }

  Widget _buildTotals(FinancialSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTotalCard(
                label: 'Pemasukan',
                amount: summary.income,
                color: AppColors.success,
                icon: Icons.south_west,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTotalCard(
                label: 'Pengeluaran',
                amount: summary.expense,
                color: AppColors.error,
                icon: Icons.north_east,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selisih',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                formatRupiah(summary.difference),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard({
    required String label,
    required int amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatRupiah(amount),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseIndicator(FinancialSummary summary) {
    final ratio = (summary.expensePercentage / 100).clamp(0.0, 1.0);

    final color = ratio < 0.5
        ? AppColors.success
        : ratio < 0.8
            ? const Color(0xFFF9A825)
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Persentase Pengeluaran',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${summary.expensePercentage.toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppColors.card,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(FinancialSummary summary) {
    if (summary.breakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Belum ada transaksi pada periode ini.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: const Text(
          'Rincian per Jenis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: summary.breakdown
            .map(
              (row) => ListTile(
                dense: true,
                title: Text(_typeLabel(row.type)),
                trailing: Text(
                  formatRupiah(row.total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _load,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'TOP_UP':
        return 'Top Up';
      case 'TRANSFER_IN':
        return 'Transfer Masuk';
      case 'TRANSFER_OUT':
        return 'Transfer Keluar';
      case 'PAYMENT':
        return 'Pembayaran';
      case 'PAYMENT_IN':
        return 'Pembayaran Masuk';
      case 'WITHDRAW':
        return 'Withdraw';
      default:
        return type;
    }
  }
}
