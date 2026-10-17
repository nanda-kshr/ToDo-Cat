import 'package:flutter/material.dart';

class CatAnimation extends StatefulWidget {
  final int speedPercent;
  final double size;

  const CatAnimation({
    super.key,
    required this.speedPercent,
    this.size = 44,
  });

  @override
  State<CatAnimation> createState() => _CatAnimationState();
}

class _CatAnimationState extends State<CatAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Duration _getDuration() {
    if (widget.speedPercent <= 0) {
      return const Duration(seconds: 1);
    }
    final clamped = widget.speedPercent.clamp(1, 100);
    final sec = (1.5 - (clamped / 100.0) * 1.05).clamp(0.45, 1.5);
    return Duration(milliseconds: (sec * 1000).round());
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _getDuration(),
    );

    if (widget.speedPercent > 0) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CatAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speedPercent != widget.speedPercent) {
      _controller.duration = _getDuration();
      if (widget.speedPercent > 0) {
        if (!_controller.isAnimating) {
          _controller.repeat();
        }
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSleeping = widget.speedPercent <= 0;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Center(
        child: isSleeping
            ? Image.asset(
                'assets/runners/cat/cat_0.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              )
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final frame = (_controller.value * 15).floor().clamp(0, 14);
                  return Image.asset(
                    'assets/runners/cat/cat_$frame.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  );
                },
              ),
      ),
    );
  }
}
