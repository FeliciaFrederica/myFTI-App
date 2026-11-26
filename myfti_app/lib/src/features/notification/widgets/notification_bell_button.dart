import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../pages/notification_page.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';

class NotificationBellButton extends StatefulWidget {
  final Color iconColor;

  const NotificationBellButton({
    super.key,
    this.iconColor = AppColors.primary,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton>
    with WidgetsBindingObserver {
  bool _hasUnread = false;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocalNotificationService.startPolling();
    _checkUnread();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkUnread(),
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    LocalNotificationService.stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocalNotificationService.checkNow();
      _checkUnread();
    }
  }

  Future<void> _checkUnread() async {
    try {
      final items = await NotificationService.list();
      if (!mounted) return;
      final unread = items.any((item) => !item.isRead);
      if (unread != _hasUnread) {
        setState(() => _hasUnread = unread);
      }
    } catch (_) {
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationPage(),
      ),
    );
    if (mounted) {
      _checkUnread();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _openNotifications,
      tooltip: 'Notifikasi',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none,
            color: widget.iconColor,
          ),
          if (_hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
