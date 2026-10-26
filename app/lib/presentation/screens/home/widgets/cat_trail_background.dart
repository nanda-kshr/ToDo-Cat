import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/app_outlined_icons.dart';

class CatTrailBackground extends StatelessWidget {
  final bool isDark;

  const CatTrailBackground({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final palette = isDark ? AppColors.dark : AppColors.light;
    final pawColor = palette.pawAndTrail;
    const double pawSize = 68.0;
    const double halfPaw = pawSize / 2.0;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          if (w <= 0 || h <= 0) {
            return const SizedBox.shrink();
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Winding thick dashed line trail
              CustomPaint(
                painter: CatTrailLinePainter(isDark: isDark),
                size: Size(w, h),
              ),

              // 2. Paw 1: upper-left paw (angled slightly left ~ -18 deg)
              Positioned(
                left: (w * 0.58) - halfPaw,
                top: (h * 0.625) - halfPaw,
                child: Transform.rotate(
                  angle: -0.32,
                  child: SvgPicture.asset(
                    AppSvgAssets.paw,
                    width: pawSize,
                    height: pawSize,
                    colorFilter: ColorFilter.mode(pawColor, BlendMode.srcIn),
                  ),
                ),
              ),

              // 3. Paw 2: lower-right paw (angled forward-right ~ +12 deg)
              Positioned(
                left: (w * 0.72) - halfPaw,
                top: (h * 0.725) - halfPaw,
                child: Transform.rotate(
                  angle: 0.22,
                  child: SvgPicture.asset(
                    AppSvgAssets.paw,
                    width: pawSize,
                    height: pawSize,
                    colorFilter: ColorFilter.mode(pawColor, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CatTrailLinePainter extends CustomPainter {
  final bool isDark;

  CatTrailLinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    final palette = isDark ? AppColors.dark : AppColors.light;
    final trailColor = palette.pawAndTrail;

    // Thick rounded dashed line
    final linePaint = Paint()
      ..color = trailColor
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Recreate the winding dashed cat trail from the screenshot
    final path = Path();
    // Starts top-left
    path.moveTo(-10, h * 0.025);
    // Curves right and dips
    path.cubicTo(
      w * 0.18,
      h * 0.035,
      w * 0.36,
      h * 0.065,
      w * 0.48,
      h * 0.14,
    );
    // Meanders down vertically
    path.cubicTo(
      w * 0.55,
      h * 0.19,
      w * 0.52,
      h * 0.27,
      w * 0.38,
      h * 0.38,
    );
    // Curves left-center
    path.cubicTo(
      w * 0.31,
      h * 0.44,
      w * 0.33,
      h * 0.50,
      w * 0.46,
      h * 0.54,
    );
    // Sweeps out in wide loop to the right (framing the paws)
    path.cubicTo(
      w * 0.68,
      h * 0.56,
      w * 0.93,
      h * 0.58,
      w * 0.95,
      h * 0.67,
    );
    // Sweeps back left under the paws
    path.cubicTo(
      w * 0.97,
      h * 0.75,
      w * 0.74,
      h * 0.82,
      w * 0.46,
      h * 0.84,
    );
    // Loops back right at bottom
    path.cubicTo(
      w * 0.38,
      h * 0.85,
      w * 0.40,
      h * 0.91,
      w * 0.58,
      h * 0.93,
    );
    // Exits at bottom-right
    path.cubicTo(
      w * 0.78,
      h * 0.95,
      w * 0.92,
      h * 0.92,
      w * 0.96,
      h + 25,
    );

    // Draw the big, thick rounded dashed line
    const double dashLength = 16.0;
    const double dashGap = 15.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), linePaint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CatTrailLinePainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
