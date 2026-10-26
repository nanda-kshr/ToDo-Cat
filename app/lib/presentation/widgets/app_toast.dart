import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/theme_service.dart';

/// Centralized top-floating toast notification utility for TodoCat.
/// Replaces bottom snackbars with short, sleek top pills.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext? context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(milliseconds: 2200),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    dismiss();

    OverlayState? overlay;
    if (context != null && context.mounted) {
      overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    }
    overlay ??= TodoCatApp.navigatorKey.currentState?.overlay;

    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastOverlay(
        message: message,
        isError: isError,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (_currentEntry == entry) {
            dismiss();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      if (_currentEntry!.mounted) {
        _currentEntry!.remove();
      }
      _currentEntry = null;
    }
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _ToastOverlay({
    required this.message,
    required this.isError,
    required this.duration,
    this.actionLabel,
    this.onAction,
    required this.onDismissed,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    _autoDismissTimer = Timer(widget.duration, () {
      _dismissWithAnimation();
    });
  }

  void _dismissWithAnimation() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDismissed();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _dismissWithAnimation,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                      _dismissWithAnimation();
                    }
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222222) : const Color(0xFF3A2F28),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF353535) : const Color(0xFF4D3F36),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.2),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isError) ...[
                            const Icon(Icons.info_outline, size: 15, color: Colors.redAccent),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (widget.actionLabel != null && widget.onAction != null) ...[
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                widget.onAction?.call();
                                _dismissWithAnimation();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF333333) : const Color(0xFF4D3F36),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF444444) : const Color(0xFF5D4F46),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.actionLabel!,
                                  style: const TextStyle(
                                    fontFamily: 'Sniglet',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4E7DC),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
