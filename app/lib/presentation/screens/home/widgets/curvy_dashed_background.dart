import 'dart:math' as math;
import 'package:flutter/material.dart';

class CurvyDashedBackground extends StatelessWidget {
  final ScrollController scrollController;
  final bool isDark;

  const CurvyDashedBackground({
    super.key,
    required this.scrollController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final offset =
            scrollController.hasClients ? scrollController.offset : 0.0;
        return RepaintBoundary(
          child: CustomPaint(
            painter: CurvyDashedBackgroundPainter(
              scrollOffset: offset,
              isDark: isDark,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class CurvyDashedBackgroundPainter extends CustomPainter {
  final double scrollOffset;
  final bool isDark;

  CurvyDashedBackgroundPainter({
    required this.scrollOffset,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Palette: White for dark theme, Black for white theme
    final lineColor = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? 0.24 : 0.15);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 5.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Subtle parallax response: shifts gently on scroll and overscroll
    final parallaxY = -scrollOffset * 0.18;

    canvas.save();
    canvas.translate(0, parallaxY);

    // One thick big line:
    // Starts top right -> curves into middle a little away from top -> curves right -> exits bottom
    final path = Path();
    path.moveTo(w * 0.88, -20);
    path.cubicTo(
      w * 0.86,
      h * 0.10,
      w * 0.52,
      h * 0.16,
      w * 0.42,
      h * 0.30,
    );
    path.cubicTo(
      w * 0.32,
      h * 0.44,
      w * 0.76,
      h * 0.54,
      w * 0.82,
      h * 0.68,
    );
    path.cubicTo(
      w * 0.88,
      h * 0.82,
      w * 0.72,
      h * 0.94,
      w * 0.65,
      h + 40,
    );

    // Draw thick, rounded, stylish dashes along the curve
    const double dashLength = 16.0;
    const double dashGap = 16.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + dashGap;
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CurvyDashedBackgroundPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.isDark != isDark;
  }
}
