import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class CatAnimation extends StatefulWidget {
  final int speedPercent;
  final double size;
  final bool idleRunWhenSleeping;
  final bool? isWhite;
  final bool showContainer;

  const CatAnimation({
    super.key,
    required this.speedPercent,
    this.size = 44,
    this.idleRunWhenSleeping = false,
    this.isWhite,
    this.showContainer = false,
  });

  @override
  State<CatAnimation> createState() => _CatAnimationState();
}

class _CatAnimationState extends State<CatAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int get _effectiveSpeed {
    if (widget.speedPercent <= 0 && widget.idleRunWhenSleeping) {
      return 15;
    }
    return widget.speedPercent;
  }

  Duration _getDuration() {
    final speed = _effectiveSpeed;
    if (speed <= 0) {
      return const Duration(milliseconds: 1600);
    }
    final clamped = speed.clamp(1, 100);
    // At clamped = 100 (100% speed, task 5): 0.25s (35ms/frame, max sprint)
    // At clamped = 50 (50% speed): 1.15s (164ms/frame, steady run)
    // At clamped = 20 (task 1 min speed): 2.00s (285ms/frame, slow leisurely walk/trot)
    // At clamped = 1: 2.35s (335ms/frame, ultra slow)
    final sec = (2.40 - (clamped / 100.0) * 2.15).clamp(0.25, 2.40);
    return Duration(milliseconds: (sec * 1000).round());
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _getDuration(),
    );

    if (_effectiveSpeed > 0) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CatAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldEffective = oldWidget.speedPercent <= 0 && oldWidget.idleRunWhenSleeping ? 15 : oldWidget.speedPercent;
    final newEffective = _effectiveSpeed;
    if (oldEffective != newEffective) {
      if (newEffective > 0) {
        _controller.duration = _getDuration();
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSleeping = _effectiveSpeed <= 0;
    final radius = (widget.size * 0.22).clamp(6.0, 12.0);
    final pad = (widget.size * 0.08).clamp(2.0, 5.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final useWhite = widget.isWhite ?? ThemeService.instance.isCatWhite(context);
    final assetDir = useWhite ? 'assets/runners/cat_white' : 'assets/runners/cat';
    final catImage = Center(
      child: isSleeping
          ? Image.asset(
              '$assetDir/cat_0.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            )
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final frame = (_controller.value * 7).floor().clamp(0, 6);
                return Image.asset(
                  '$assetDir/cat_$frame.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                );
              },
            ),
    );

    if (!widget.showContainer) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: catImage,
      );
    }

    final boxColor = isDark ? const Color(0xFF262626) : Colors.white;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(pad),
      child: catImage,
    );
  }
}
