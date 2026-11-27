import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../authentication/models/user_model.dart';
import '../../authentication/services/auth_service.dart';
import '../../authentication/widgets/user_avatar.dart';
import '../../merchant/services/merchant_dashboard_service.dart';
import '../../notification/widgets/notification_bell_button.dart';
import '../../transaction/models/transaction_model.dart';
import '../../wallet/services/wallet_service.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key, this.onProfileTap, this.onHistoryTap});

  final VoidCallback? onProfileTap;
  final ValueChanged<String?>? onHistoryTap;

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  final WalletService _walletService = WalletService();
  final MerchantDashboardService _dashboardService = MerchantDashboardService();

  late Future<Map<String, dynamic>> _walletFuture;
  late Future<UserModel> _userFuture;
  late Future<MerchantDashboardData> _dashboardFuture;

  bool _balanceVisible = false;
  String _period = 'daily';
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadData();
    _userFuture = AuthService.getProfile();
  }

  void _loadData() {
    _walletFuture = _walletService.getWallet();
    _dashboardFuture = _dashboardService.getDashboard(
      period: _period,
      from: _customRange?.start,
      to: _customRange?.end,
    );
  }

  void _openHistory([String? subcategory]) {
    widget.onHistoryTap?.call(subcategory);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
      _userFuture = AuthService.getProfile();
    });

    try {
      await Future.wait([_walletFuture, _userFuture, _dashboardFuture]);
    } catch (_) {
      // Error ditampilkan di bagian yang datanya gagal dimuat.
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

  String _periodLabel() {
    switch (_period) {
      case 'weekly':
        return 'Minggu ini';
      case 'monthly':
        return 'Bulan ini';
      case 'yearly':
        return 'Tahun ini';
      case 'custom':
        final range = _customRange;
        if (range == null) return 'Pilih tanggal';
        return '${range.start.day}/${range.start.month}–'
            '${range.end.day}/${range.end.month}';
      default:
        return 'Hari ini';
    }
  }

  String _periodCaption() {
    switch (_period) {
      case 'weekly':
        return 'minggu ini';
      case 'monthly':
        return 'bulan ini';
      case 'yearly':
        return 'tahun ini';
      case 'custom':
        return 'periode terpilih';
      default:
        return 'hari ini';
    }
  }

  Future<void> _selectPeriod(String? value) async {
    if (value == null) return;

    if (value == 'custom') {
      await _pickCustomRange();
      return;
    }

    setState(() {
      _period = value;
      _customRange = null;
      _loadData();
    });
  }

  Future<DateTime?> _pickDate({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String helpText,
  }) {
    var safeDate = initialDate;
    if (safeDate.isBefore(firstDate)) safeDate = firstDate;
    if (safeDate.isAfter(lastDate)) safeDate = lastDate;

    return showDatePicker(
      context: context,
      initialDate: safeDate,
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

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliestDate = DateTime(2024, 1, 1);

    var start = _customRange?.start ?? DateTime(now.year, now.month, 1);
    var end = _customRange?.end ?? today;

    if (end.isAfter(today)) end = today;
    if (start.isAfter(end)) start = end;

    final selectedRange = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Tentukan tanggal mulai dan akhir pemasukan.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 18),
                    _dateField(
                      label: 'Tanggal Mulai',
                      date: start,
                      onTap: () async {
                        final picked = await _pickDate(
                          initialDate: start,
                          firstDate: earliestDate,
                          lastDate: today,
                          helpText: 'Pilih Tanggal Mulai',
                        );
                        if (picked == null) return;

                        setSheetState(() {
                          start = picked;
                          if (end.isBefore(start)) end = start;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _dateField(
                      label: 'Tanggal Akhir',
                      date: end,
                      onTap: () async {
                        final picked = await _pickDate(
                          initialDate: end,
                          firstDate: start,
                          lastDate: today,
                          helpText: 'Pilih Tanggal Akhir',
                        );
                        if (picked != null) {
                          setSheetState(() => end = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text,
                              side: const BorderSide(color: Color(0xFFD1C4E9)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(
                              sheetContext,
                              DateTimeRange(start: start, end: end),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
      _loadData();
    });
  }

  Widget _dateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
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
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${date.day} ${months[date.month - 1]} ${date.year}',
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
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFF3EEFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
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

    if (ok != true) return;

    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                _buildBalanceCard(),
                const SizedBox(height: 24),
                _buildPeriodPicker(),
                const SizedBox(height: 22),
                _buildSummarySections(),
                const SizedBox(height: 8),
                _buildRecentPayments(),
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
                    ? 'Merchant!'
                    : user == null
                    ? 'Memuat profil...'
                    : '${user.name}!';

                return Row(
                  children: [
                    if (user != null)
                      UserAvatar(
                        initials: user.initials,
                        avatar: user.avatar,
                        radius: 20,
                      )
                    else
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFEDE7F6),
                        child: Icon(Icons.storefront, color: AppColors.primary),
                      ),
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
                              color: AppColors.text,
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
          icon: const Icon(Icons.logout, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _walletFuture,
      builder: (context, snapshot) {
        String balanceText;

        if (snapshot.hasData) {
          final rawBalance = snapshot.data?['balance'];
          final balance = rawBalance is num ? rawBalance.toInt() : 0;
          balanceText = _balanceVisible
              ? _formatRupiah(balance)
              : 'Rp ••••••••';
        } else if (snapshot.hasError) {
          balanceText = 'Gagal memuat saldo';
        } else {
          balanceText = 'Memuat saldo...';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Dekorasi Mega Mendung
              Positioned.fill(
                child: IgnorePointer(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.white,
                          Colors.white54,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.42, 0.72],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Opacity(
                      opacity: 0.16,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildCloudItem(
                            right: -25,
                            top: -20,
                            width: 170,
                            angle: -0.15,
                          ),
                          _buildCloudItem(
                            right: -15,
                            bottom: -25,
                            width: 150,
                            angle: 0.2,
                            flipX: true,
                          ),
                          _buildCloudItem(
                            right: 110,
                            top: 10,
                            width: 105,
                            angle: 0.25,
                            flipX: true,
                          ),
                          _buildCloudItem(
                            right: 95,
                            bottom: 5,
                            width: 120,
                            angle: -0.2,
                          ),
                          _buildCloudItem(
                            right: 185,
                            top: 45,
                            width: 85,
                            angle: -0.35,
                            flipX: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 30,
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
                            setState(() => _balanceVisible = !_balanceVisible);
                          },
                          icon: Icon(
                            _balanceVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white,
                          ),
                        ),
                      if (snapshot.hasError)
                        IconButton(
                          onPressed: _refresh,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodPicker() {
    final isCustom = _period == 'custom';
    final range = _customRange;

    return Row(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isCustom ? const Color(0xFFD1C4E9) : AppColors.primary,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _period,
              isDense: true,
              borderRadius: BorderRadius.circular(16),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              items: [
                const DropdownMenuItem(value: 'daily', child: Text('Hari ini')),
                const DropdownMenuItem(
                  value: 'weekly',
                  child: Text('Minggu ini'),
                ),
                const DropdownMenuItem(
                  value: 'monthly',
                  child: Text('Bulan ini'),
                ),
                const DropdownMenuItem(
                  value: 'yearly',
                  child: Text('Tahun ini'),
                ),
                if (isCustom)
                  const DropdownMenuItem(
                    value: 'custom',
                    child: Text('Custom'),
                  ),
                if (!isCustom)
                  const DropdownMenuItem(
                    value: 'custom',
                    child: Text('Pilih tanggal'),
                  ),
              ],
              onChanged: _selectPeriod,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: isCustom ? const Color(0xFFF3EEFC) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: _pickCustomRange,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isCustom
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
                        isCustom && range != null
                            ? '${range.start.day}/${range.start.month}/${range.start.year}'
                                  ' – ${range.end.day}/${range.end.month}/${range.end.year}'
                            : 'Pilih tanggal',
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
        ),
      ],
    );
  }

  Widget _buildOverallSummary() {
    return FutureBuilder<MerchantDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Row(
            children: [
              Expanded(child: _MetricCard.loading()),
              SizedBox(width: 12),
              Expanded(child: _MetricCard.loading()),
            ],
          );
        }

        if (snapshot.hasError) {
          return _errorCard(
            'Ringkasan pemasukan belum tersedia.',
            onRetry: _refresh,
          );
        }

        final categories = snapshot.data?.categories ?? [];
        final count = categories.fold<int>(0, (sum, item) => sum + item.count);
        final amount = categories.fold<int>(
          0,
          (sum, item) => sum + item.amount,
        );

        return Row(
          children: [
            Expanded(
              child: _MetricCard(
                value: '$count transaksi',
                caption: _periodCaption(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                value: _formatRupiah(amount),
                caption: 'total pemasukan',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummarySections() {
    return FutureBuilder<MerchantDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final hasOneCategory =
            snapshot.hasData && snapshot.data!.categories.length == 1;

        if (hasOneCategory) {
          return _buildCategories();
        }

        return Column(
          children: [
            _buildOverallSummary(),
            const SizedBox(height: 22),
            _buildCategories(),
          ],
        );
      },
    );
  }

  Widget _buildCategories() {
    return FutureBuilder<MerchantDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final categories = snapshot.data!.categories;
        if (categories.isEmpty) return const SizedBox.shrink();

        return Column(
          children: categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openHistory(category.subcategory),
                        child: const Text(
                          'Riwayat',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          value: '${category.count} transaksi',
                          caption: _periodCaption(),
                          onTap: () => _openHistory(category.subcategory),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          value: _formatRupiah(category.amount),
                          caption: 'pemasukan ${category.name}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentPayments() {
    return FutureBuilder<MerchantDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final payments =
            snapshot.data?.recentPayments ?? const <TransactionModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pembayaran Terbaru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _openHistory(),
                  child: const Text(
                    'Riwayat',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            if (snapshot.hasError)
              _errorCard('Gagal memuat pembayaran masuk.', onRetry: _refresh)
            else if (!snapshot.hasData)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (payments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Belum ada pembayaran pada periode ini.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...payments
                  .take(5)
                  .map(
                    (payment) => Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEDE7F6),
                          child: Icon(
                            Icons.south_west_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          payment.counterpartName ?? 'Pembayaran pelanggan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(payment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Text(
                          '+ ${_formatRupiah(payment.amount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _errorCard(String message, {required VoidCallback onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.text)),
          ),
          IconButton(
            onPressed: onRetry,
            tooltip: 'Coba lagi',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudItem({
    double? top,
    double? bottom,
    double? right,
    double? left,
    required double width,
    double angle = 0,
    bool flipX = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      right: right,
      left: left,
      child: Transform.rotate(
        angle: angle,
        child: Transform.flip(
          flipX: flipX,
          child: Image.asset(
            'assets/images/mega_mendung.png',
            width: width,
            fit: BoxFit.contain,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.caption, this.onTap})
    : _loading = false;

  const _MetricCard.loading()
    : value = '',
      caption = '',
      onTap = null,
      _loading = true;

  final String value;
  final String caption;
  final VoidCallback? onTap;
  final bool _loading;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3EF)),
      ),
      child: _loading
          ? const Center(
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1B46),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: card,
    );
  }
}
