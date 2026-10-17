import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Blue
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(23.49, 12.28)
      ..cubicTo(23.49, 11.58, 23.43, 10.88, 23.31, 10.24)
      ..lineTo(12.0, 10.24)
      ..lineTo(12.0, 14.75)
      ..lineTo(18.47, 14.75)
      ..cubicTo(18.18, 16.27, 17.33, 17.55, 16.07, 18.43)
      ..lineTo(19.95, 21.48)
      ..cubicTo(22.22, 19.39, 23.49, 16.31, 23.49, 12.28)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.95, 22.92, 19.93, 21.09)
      ..lineTo(16.05, 18.04)
      ..cubicTo(14.97, 18.76, 13.6, 19.2, 12.0, 19.2)
      ..cubicTo(8.88, 19.2, 6.23, 17.1, 5.28, 14.27)
      ..lineTo(1.25, 17.42)
      ..cubicTo(3.26, 21.36, 7.33, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(5.28, 14.28)
      ..cubicTo(5.03, 13.56, 4.9, 12.79, 4.9, 12.0)
      ..cubicTo(4.9, 11.21, 5.03, 10.44, 5.28, 9.72)
      ..lineTo(1.25, 6.57)
      ..cubicTo(0.45, 8.16, 0.0, 9.97, 0.0, 12.0)
      ..cubicTo(0.0, 14.03, 0.45, 15.84, 1.25, 17.43)
      ..lineTo(5.28, 14.28)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(12.0, 4.75)
      ..cubicTo(13.77, 4.75, 15.35, 5.36, 16.6, 6.55)
      ..lineTo(20.02, 3.13)
      ..cubicTo(17.95, 1.19, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.33, 0.0, 3.26, 2.64, 1.25, 6.57)
      ..lineTo(5.28, 9.72)
      ..cubicTo(6.23, 6.89, 8.88, 4.75, 12.0, 4.75)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
