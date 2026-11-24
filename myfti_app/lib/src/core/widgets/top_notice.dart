import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Notifikasi singkat yang muncul di bagian atas layar.
class TopNotice {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    bool success = true,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    // Hapus notifikasi sebelumnya kalau masih tampil
    _entry?.remove();
    _entry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopNoticeView(
        message: message,
        success: success,
        duration: duration,
        onDismissed: () {
          if (_entry == entry) {
            entry.remove();
            _entry = null;
          }
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _TopNoticeView extends StatefulWidget {
  final String message;
  final bool success;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopNoticeView({
    required this.message,
    required this.success,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopNoticeView> createState() => _TopNoticeViewState();
}

class _TopNoticeViewState extends State<_TopNoticeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.5),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(widget.duration, _close);
  }

  Future<void> _close() async {
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? AppColors.success : AppColors.error;
    final icon =
        widget.success ? Icons.check_circle_outline : Icons.error_outline;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _c,
              child: GestureDetector(
                onTap: _close,
                child: Material(
                  color: color,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}