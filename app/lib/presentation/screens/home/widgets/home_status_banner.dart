import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/cat_animation.dart';

class HomeStatusBanner extends StatelessWidget {
  final int catSpeed;
  final int activeCount;
  final int completedTodayCount;
  final int todayTotalCount;
  final int completionPercent;

  const HomeStatusBanner({
    super.key,
    required this.catSpeed,
    required this.activeCount,
    required this.completedTodayCount,
    required this.todayTotalCount,
    required this.completionPercent,
  });

  String _getSpeechText() {
    final hour = DateTime.now().hour;

    // Morning: 5:00 AM - 11:59 AM
    if (hour >= 5 && hour < 12) {
      if (activeCount > 0) {
        return 'Good morning!\n$activeCount ${activeCount == 1 ? 'task' : 'tasks'} waiting today.';
      }
      if (completedTodayCount > 0) {
        return 'Good morning!\nAll caught up for today.';
      }
      return 'Good morning!\nReady for today?';
    }

    // Afternoon: 12:00 PM - 4:59 PM
    if (hour >= 12 && hour < 17) {
      if (activeCount > 0) {
        return 'Good afternoon!\n$activeCount ${activeCount == 1 ? 'task' : 'tasks'} remaining.';
      }
      if (completedTodayCount > 0) {
        return 'Good afternoon!\nAll caught up for today.';
      }
      return 'Good afternoon!\nReady for today?';
    }

    // Evening: 5:00 PM - 9:59 PM
    if (hour >= 17 && hour < 22) {
      if (completedTodayCount > 0 && activeCount == 0) {
        return 'Good evening!\nYou crushed $completedTodayCount ${completedTodayCount == 1 ? 'task' : 'tasks'} today!\nCat is happy and asleep.';
      }
      if (activeCount > 0) {
        return 'Good evening!\n$activeCount ${activeCount == 1 ? 'task' : 'tasks'} remaining today.';
      }
      if (completedTodayCount > 0) {
        return 'Good evening!\nYou crushed $completedTodayCount ${completedTodayCount == 1 ? 'task' : 'tasks'} today!';
      }
      return 'Good evening!\nHave a peaceful rest.';
    }

    // Night: 10:00 PM - 4:59 AM
    if (completedTodayCount > 0) {
      return 'You crushed $completedTodayCount ${completedTodayCount == 1 ? 'task' : 'tasks'} today!\nCat is asleep.';
    }
    return 'Cat is asleep.\nRest well for tomorrow.';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final cardBg = palette.taskCardBg;
    final cardBorder = palette.cardBorder;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    final progress = (todayTotalCount == 0
            ? 0.0
            : (completedTodayCount / todayTotalCount))
        .clamp(0.0, 1.0);

    final speechText = _getSpeechText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: palette.softShadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Half: Big Cat (50% width)
          Expanded(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SpeechBubble(
                  text: speechText,
                  bg: cardBg,
                  border: cardBorder,
                  textColor: textPrimary,
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final catSize = (constraints.maxWidth * 0.90).clamp(120.0, 155.0);
                    return RepaintBoundary(
                      child: CatAnimation(
                        speedPercent: catSpeed,
                        size: catSize,
                        showContainer: false,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Right Half: Big Progress & Stats (50% width)
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$activeCount Active Tasks',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$completionPercent%',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 16,
                    backgroundColor: palette.progressTrack,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.progressFill),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$completedTodayCount done today · $activeCount remaining',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final Color bg;
  final Color border;
  final Color textColor;

  const _SpeechBubble({
    required this.text,
    required this.bg,
    required this.border,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0.2, 0),
          child: CustomPaint(
            size: const Size(10, 5),
            painter: _BubbleTailPainter(bg: bg, border: border),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color bg;
  final Color border;

  _BubbleTailPainter({required this.bg, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final fillPaint = Paint()
      ..color = bg
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawLine(Offset.zero, Offset(size.width / 2, size.height), strokePaint);
    canvas.drawLine(Offset(size.width / 2, size.height), Offset(size.width, 0), strokePaint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.bg != bg || oldDelegate.border != border;
}
