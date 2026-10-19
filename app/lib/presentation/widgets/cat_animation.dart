import 'package:flutter/material.dart';
import '../../services/theme_service.dart';

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;

  bool get _isSleeping => widget.speedPercent <= 0 && !widget.idleRunWhenSleeping;

  Duration _getDuration() {
    if (_isSleeping) {
      return const Duration(milliseconds: 1800);
    }
    final speed = widget.speedPercent <= 0 ? 15 : widget.speedPercent;
    final clamped = speed.clamp(1, 100);
    final sec = (2.40 - (clamped / 100.0) * 2.15).clamp(0.25, 2.40);
    return Duration(milliseconds: (sec * 1000).round());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: _getDuration(),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void didUpdateWidget(covariant CatAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speedPercent != widget.speedPercent ||
        oldWidget.idleRunWhenSleeping != widget.idleRunWhenSleeping) {
      final wasSleeping = oldWidget.speedPercent <= 0 && !oldWidget.idleRunWhenSleeping;
      final nowSleeping = _isSleeping;
      _controller.duration = _getDuration();
      if (wasSleeping != nowSleeping) {
        _controller.reset();
      }
      _controller.repeat();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSleeping = _isSleeping;
    final radius = (widget.size * 0.22).clamp(6.0, 12.0);
    final pad = (widget.size * 0.08).clamp(2.0, 5.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final useWhite = widget.isWhite ?? ThemeService.instance.isCatWhite(context);
    final assetDir = useWhite ? 'assets/runners/cat_white' : 'assets/runners/cat';
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final targetCachePx = (widget.size * pixelRatio).round().clamp(32, 256);

    final catImage = Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (isSleeping) {
            final frame = (_controller.value * 6).floor().clamp(0, 5);
            return Image.asset(
              '$assetDir/cat_sleep_$frame.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              cacheWidth: targetCachePx,
              cacheHeight: targetCachePx,
            );
          } else {
            final frame = (_controller.value * 7).floor().clamp(0, 6);
            return Image.asset(
              '$assetDir/cat_$frame.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              cacheWidth: targetCachePx,
              cacheHeight: targetCachePx,
            );
          }
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
