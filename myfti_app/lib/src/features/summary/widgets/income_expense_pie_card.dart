import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../pages/financial_summary_page.dart';
import '../services/summary_service.dart';

class IncomeExpensePieChart extends StatelessWidget {
  final int income;
  final int expense;
  final double size;
  final double strokeWidth;

  const IncomeExpensePieChart({
    super.key,
    required this.income,
    required this.expense,
    this.size = 120,
    this.strokeWidth = 18,
  });

  static const Color calmError = Color(0xFFD9534F);

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final expensePercent = total == 0 ? 0.0 : (expense / total) * 100;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          income: income,
          expense: expense,
          strokeWidth: strokeWidth,
          incomeColor: AppColors.success,
          expenseColor: calmError,
          emptyColor: AppColors.card,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                total == 0 ? '0%' : '${expensePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Text(
                'Keluar',
                style: TextStyle(
                  fontSize: size * 0.10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int income;
  final int expense;
  final double strokeWidth;
  final Color incomeColor;
  final Color expenseColor;
  final Color emptyColor;

  const _DonutPainter({
    required this.income,
    required this.expense,
    required this.strokeWidth,
    required this.incomeColor,
    required this.expenseColor,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final total = income + expense;
    if (total <= 0) {
      canvas.drawCircle(center, radius, basePaint..color = emptyColor);
      return;
    }

    const startAngle = -math.pi / 2;
    final incomeSweep = (income / total) * 2 * math.pi;
    final expenseSweep = (expense / total) * 2 * math.pi;

    if (income > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        incomeSweep,
        false,
        basePaint..color = incomeColor,
      );
    }

    if (expense > 0) {
      canvas.drawArc(
        rect,
        startAngle + incomeSweep,
        expenseSweep,
        false,
        basePaint..color = expenseColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.income != income ||
        oldDelegate.expense != expense ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class IncomeExpensePieCard extends StatefulWidget {
  final String period;

  const IncomeExpensePieCard({
    super.key,
    this.period = 'monthly',
  });

  @override
  State<IncomeExpensePieCard> createState() => _IncomeExpensePieCardState();
}

class _IncomeExpensePieCardState extends State<IncomeExpensePieCard> {
  static const Color _borderColor = Color(0xFFD1C4E9);
  static const Color _calmError = Color(0xFFD9534F);

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
      final summary = await SummaryService.getSummary(period: widget.period);
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

  Future<void> _openSummary() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FinancialSummaryPage(),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openSummary,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Keuangan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pemasukan & pengeluaran bulan ini',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (_error != null)
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: _calmError,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Muat Ulang'),
                    ),
                  ],
                )
              else if (_summary != null)
                Row(
                  children: [
                    IncomeExpensePieChart(
                      income: _summary!.income,
                      expense: _summary!.expense,
                      size: 92,
                      strokeWidth: 14,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem(
                            label: 'Pemasukan',
                            amount: _summary!.income,
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 12),
                          _legendItem(
                            label: 'Pengeluaran',
                            amount: _summary!.expense,
                            color: _calmError,
                          ),
                        ],
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

  Widget _legendItem({
    required String label,
    required int amount,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                formatRupiah(amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
