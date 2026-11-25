import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _loading = true;
  String? _error;
  List<AppNotification> _items = const [];

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

  Future<void> _markAsRead(AppNotification item) async {
    if (item.isRead) return;

    // Optimistis: UI langsung berubah, kalau gagal dikembalikan
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
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: _load,
              child: const Text('Coba lagi'),
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
          Icon(Icons.notifications_none, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum ada notifikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildItem(item);
      },
    );
  }

  Widget _buildItem(AppNotification item) {
    // Belum dibaca: latar lebih terang + judul tebal + titik ungu
    final unread = !item.isRead;

    return Material(
      color: unread ? Colors.white : AppColors.card.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _markAsRead(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: unread ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  unread
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none,
                  color: unread ? AppColors.primary : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight:
                            unread ? FontWeight.bold : FontWeight.w500,
                        color: unread ? AppColors.text : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: unread ? AppColors.text : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(item.createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
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
