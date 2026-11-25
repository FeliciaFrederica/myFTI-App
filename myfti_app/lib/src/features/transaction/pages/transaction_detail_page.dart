import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  static const Color _borderColor = Color(0xFFD1C4E9);
  static const Color _calmError = Color(0xFFD9534F);

  final TransactionService _transactionService = TransactionService();

  bool _loading = true;
  String? _error;
  TransactionModel? _transaction;

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
      final detail = await _transactionService.getTransactionDetail(
        widget.transactionId,
      );
      if (!mounted) return;
      setState(() {
        _transaction = detail;
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

  Future<void> _copyText(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Transaksi',
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
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: _calmError,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
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
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final tx = _transaction;
    if (tx == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeaderCard(tx),
        const SizedBox(height: 20),
        _buildDetailCard(tx),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Kembali',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeaderCard(TransactionModel tx) {
    final isFailed = tx.status == 'FAILED';
    final statusColor = isFailed ? _calmError : AppColors.success;
    final amountColor = isFailed
        ? Colors.grey
        : tx.isIncoming
            ? AppColors.success
            : _calmError;
    final sign = isFailed ? '' : (tx.isIncoming ? '+ ' : '- ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFailed ? Icons.cancel_rounded : Icons.check_circle_rounded,
              color: statusColor,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFailed ? 'GAGAL' : 'BERHASIL',
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _typeLabel(tx.type),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$sign${formatRupiah(tx.amount)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateTime(tx.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(TransactionModel tx) {
    final isFailed = tx.status == 'FAILED';
    final statusColor = isFailed ? _calmError : AppColors.success;
    final counterpartLabel = _counterpartLabel(tx.type);

    final rows = <Widget>[
      _buildCopyableRow(
        label: 'Kode Referensi',
        value: tx.reference,
      ),
      _buildCopyableRow(
        label: 'ID Transaksi',
        value: tx.id,
      ),
      _buildRow(
        label: 'Jenis Transaksi',
        value: _typeLabel(tx.type),
      ),
      _buildRow(
        label: 'Status',
        value: isFailed ? 'Gagal' : 'Berhasil',
        valueColor: statusColor,
      ),
      _buildRow(
        label: 'Tanggal & Waktu',
        value: _formatDateTime(tx.createdAt),
      ),
    ];

    if (counterpartLabel != null &&
        tx.counterpartName != null &&
        tx.counterpartName!.trim().isNotEmpty) {
      rows.add(
        _buildRow(
          label: counterpartLabel,
          value: tx.counterpartName!.trim(),
        ),
      );
    }

    if (tx.type == 'WITHDRAW') {
      if (tx.bankCode != null && tx.bankCode!.trim().isNotEmpty) {
        rows.add(
          _buildRow(
            label: 'Kode Bank',
            value: tx.bankCode!.trim(),
          ),
        );
      }
      if (tx.accountNumber != null && tx.accountNumber!.trim().isNotEmpty) {
        rows.add(
          _buildRow(
            label: 'Nomor Rekening',
            value: tx.accountNumber!.trim(),
          ),
        );
      }
    }

    if (tx.description != null && tx.description!.trim().isNotEmpty) {
      rows.add(
        _buildRow(
          label: 'Catatan',
          value: tx.description!.trim(),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.card),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(height: 1, color: AppColors.card),
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _copyText(label, value),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
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

  String? _counterpartLabel(String type) {
    switch (type) {
      case 'TRANSFER_OUT':
        return 'Penerima';
      case 'TRANSFER_IN':
        return 'Pengirim';
      case 'PAYMENT':
        return 'Merchant';
      case 'PAYMENT_IN':
        return 'Dari Mahasiswa';
      case 'WITHDRAW':
        return 'Bank Tujuan';
      default:
        return null;
    }
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
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
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} ${local.year} • $hour:$minute';
  }
}
