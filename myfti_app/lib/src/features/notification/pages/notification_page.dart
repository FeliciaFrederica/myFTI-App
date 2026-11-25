import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotifVisual {
  final String badge;
  final IconData icon;
  final Color accent;
  final String sign;

  const _NotifVisual({
    required this.badge,
    required this.icon,
    required this.accent,
    required this.sign,
  });
}

class _NotificationPageState extends State<NotificationPage> {
  static const Color _borderColor = Color(0xFFD1C4E9);
  static const Color _calmError = Color(0xFFD9534F);
  static final RegExp _rupiahRegex = RegExp(r'Rp\s?[\d.]+');

  bool _loading = true;
  bool _markingAll = false;
  bool _onlyUnread = false;
  String? _error;
  List<AppNotification> _items = const [];

  int get _unreadCount => _items.where((n) => !n.isRead).length;

  List<AppNotification> get _visibleItems =>
      _onlyUnread ? _items.where((n) => !n.isRead).toList() : _items;

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
      final items = await NotificationService.list();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  _NotifVisual _visualFor(AppNotification item) {
    final lower = '${item.title} ${item.message}'.toLowerCase();

    if (lower.contains('top up')) {
      return const _NotifVisual(
        badge: 'TOP UP',
        icon: Icons.add_circle_outline_rounded,
        accent: AppColors.success,
        sign: '+',
      );
    }
    if (lower.contains('dana masuk') || lower.contains('pembayaran masuk')) {
      return const _NotifVisual(
        badge: 'DANA MASUK',
        icon: Icons.south_west_rounded,
        accent: AppColors.success,
        sign: '+',
      );
    }
    if (lower.contains('withdraw')) {
      return const _NotifVisual(
        badge: 'WITHDRAW',
        icon: Icons.account_balance_outlined,
        accent: _calmError,
        sign: '-',
      );
    }
    if (lower.contains('pembayaran') || lower.contains('payment')) {
      return const _NotifVisual(
        badge: 'PEMBAYARAN',
        icon: Icons.shopping_bag_outlined,
        accent: AppColors.primary,
        sign: '-',
      );
    }
    if (lower.contains('transfer')) {
      return const _NotifVisual(
        badge: 'TRANSFER',
        icon: Icons.send_rounded,
        accent: AppColors.primary,
        sign: '-',
      );
    }

    return const _NotifVisual(
      badge: 'INFO',
      icon: Icons.notifications_outlined,
      accent: AppColors.primary,
      sign: '',
    );
  }

  String? _extractAmount(String message) {
    final match = _rupiahRegex.firstMatch(message);
    return match?.group(0);
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final local = date.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  Future<void> _openNotification(AppNotification item) async {
    if (!item.isRead) {
      _markAsRead(item);
    }

    final visual = _visualFor(item);
    final amountText = _extractAmount(item.message);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: visual.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    visual.icon,
                    color: visual.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: visual.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    visual.badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: visual.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (amountText != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: visual.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: visual.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Nominal',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visual.sign.isEmpty
                              ? amountText
                              : '${visual.sign} $amountText',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: visual.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.card),
                  ),
                  child: Text(
                    item.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAsRead(AppNotification item) async {
    if (item.isRead) return;

    setState(() {
      _items = _items
          .map(
            (n) => n.id == item.id
                ? AppNotification(
                    id: n.id,
                    title: n.title,
                    message: n.message,
                    isRead: true,
                    createdAt: n.createdAt,
                  )
                : n,
          )
          .toList();
    });

    try {
      await NotificationService.markAsRead(item.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      _load();
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadItems = _items.where((n) => !n.isRead).toList();
    if (unreadItems.isEmpty || _markingAll) return;

    setState(() {
      _markingAll = true;
      _items = _items
          .map(
            (n) => AppNotification(
              id: n.id,
              title: n.title,
              message: n.message,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();
    });

    try {
      await Future.wait(
        unreadItems.map((n) => NotificationService.markAsRead(n.id)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      _load();
    } finally {
      if (mounted) {
        setState(() => _markingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notification',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          if (!_loading && _unreadCount > 0)
            TextButton(
              onPressed: _markingAll ? null : _markAllAsRead,
              child: const Text(
                'Tandai semua',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
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
                const Icon(Icons.error_outline, color: _calmError, size: 40),
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
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.notifications_none, size: 52, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum ada notifikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Aktivitas Top Up, Transfer, Payment, dan Withdraw kamu akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    final visible = _visibleItems;
    final todayItems = visible.where((n) => _isToday(n.createdAt)).toList();
    final earlierItems = visible.where((n) => !_isToday(n.createdAt)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _buildFilterBar(),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Column(
              children: [
                Icon(Icons.mark_email_read_outlined,
                    size: 46, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Semua notifikasi sudah dibaca.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else ...[
          if (todayItems.isNotEmpty) ...[
            _buildSectionHeader('Hari Ini'),
            const SizedBox(height: 10),
            for (var i = 0; i < todayItems.length; i++) ...[
              _buildItem(todayItems[i]),
              if (i < todayItems.length - 1) const SizedBox(height: 10),
            ],
            if (earlierItems.isNotEmpty) const SizedBox(height: 20),
          ],
          if (earlierItems.isNotEmpty) ...[
            _buildSectionHeader('Sebelumnya'),
            const SizedBox(height: 10),
            for (var i = 0; i < earlierItems.length; i++) ...[
              _buildItem(earlierItems[i]),
              if (i < earlierItems.length - 1) const SizedBox(height: 10),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        ChoiceChip(
          label: Text('Semua (${_items.length})'),
          selected: !_onlyUnread,
          onSelected: (_) => setState(() => _onlyUnread = false),
          selectedColor: AppColors.card,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: !_onlyUnread ? AppColors.primary : AppColors.text,
            fontWeight: !_onlyUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.5,
          ),
          side: BorderSide(
            color: !_onlyUnread ? AppColors.primary : _borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text('Belum Dibaca ($_unreadCount)'),
          selected: _onlyUnread,
          onSelected: (_) => setState(() => _onlyUnread = true),
          selectedColor: AppColors.card,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: _onlyUnread ? AppColors.primary : AppColors.text,
            fontWeight: _onlyUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.5,
          ),
          side: BorderSide(
            color: _onlyUnread ? AppColors.primary : _borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.secondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildItem(AppNotification item) {
    final unread = !item.isRead;
    final visual = _visualFor(item);
    final iconColor = unread ? visual.accent : Colors.grey;
    final iconBg = unread
        ? visual.accent.withValues(alpha: 0.12)
        : AppColors.background;

    return Material(
      color: unread ? Colors.white : Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openNotification(item),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread ? _borderColor : AppColors.card,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  visual.icon,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.bold : FontWeight.w600,
                              color: unread
                                  ? AppColors.text
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: unread ? AppColors.text : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: unread
                                ? visual.accent.withValues(alpha: 0.10)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            visual.badge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: unread ? visual.accent : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final local = date.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    if (sameDay) return 'Hari ini, $time';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${local.day} ${months[local.month - 1]} ${local.year}, $time';
  }
}
