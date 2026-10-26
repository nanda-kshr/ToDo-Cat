import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final VoidCallback onAction;
  final VoidCallback onDismiss;
  final Duration autoDismissDuration;

  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.type,
    required this.onAction,
    required this.onDismiss,
    this.autoDismissDuration = const Duration(seconds: 5),
  });

  @override
  State<InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _offsetAnim;
  late final Animation<double> _fadeAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _animController.forward();
    _dismissTimer = Timer(widget.autoDismissDuration, _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (mounted) {
      _animController.reverse().then((_) {
        if (mounted) {
          widget.onDismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isFriendReq = widget.type == 'friend_request';
    final isFriendAccepted = widget.type == 'friend_accepted';

    final IconData icon = isFriendReq
        ? Icons.person_add_alt_1_rounded
        : isFriendAccepted
            ? Icons.how_to_reg_rounded
            : Icons.notifications_active_outlined;

    return SlideTransition(
      position: _offsetAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) < -100) {
                    _dismiss();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFFFFDFB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE8E2D8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      // Accent Icon Container
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: palette.subtleGreenBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.subtleGreenBorder, width: 1),
                        ),
                        child: Icon(
                          icon,
                          size: 19,
                          color: palette.subtleGreen,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text Content
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 11.5,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Action Button
                      InkWell(
                        onTap: () {
                          _dismissTimer?.cancel();
                          widget.onAction();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: palette.subtleGreenBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: palette.subtleGreenBorder),
                          ),
                          child: Text(
                            'View',
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: palette.subtleGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Dismiss Button
                      IconButton(
                        onPressed: _dismiss,
                        icon: const Icon(Icons.close, size: 16),
                        color: palette.textMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Dismiss',
                      ),
                    ],
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
