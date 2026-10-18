import 'package:flutter/material.dart';
import 'cat_animation.dart';

class DraggableFloatingCat extends StatefulWidget {
  final int speedPercent;
  final String speedMessage;

  const DraggableFloatingCat({
    super.key,
    required this.speedPercent,
    required this.speedMessage,
  });

  @override
  State<DraggableFloatingCat> createState() => _DraggableFloatingCatState();
}

class _DraggableFloatingCatState extends State<DraggableFloatingCat> {
  Offset? _position;
  final double _catSize = 54.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Default to bottom-left corner above safe area
    final defaultPos = Offset(
      20,
      screenSize.height - padding.bottom - 110,
    );

    final pos = _position ?? defaultPos;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final minX = 10.0;
            final maxX = screenSize.width - _catSize - 10.0;
            final minY = padding.top + 60.0;
            final maxY = screenSize.height - padding.bottom - _catSize - 20.0;

            final newX = (pos.dx + details.delta.dx).clamp(minX, maxX);
            final newY = (pos.dy + details.delta.dy).clamp(minY, maxY);

            _position = Offset(newX, newY);
          });
        },
        onTap: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.pets, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.speedMessage,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1F1F1F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        child: Material(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          color: Colors.transparent,
          child: CatAnimation(
            speedPercent: widget.speedPercent,
            size: _catSize,
          ),
        ),
      ),
    );
  }
}
