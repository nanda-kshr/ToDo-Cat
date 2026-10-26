import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

/// Raw SVG paths crafted with crisp 2.2px rounded outlines.
class AppOutlinedSvgStrings {
  AppOutlinedSvgStrings._();

  static const String completed = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="9"/>
  <path d="M8.5 12.5l2.5 2.5 5-5"/>
</svg>
''';

  static const String pending = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="9"/>
  <polyline points="12 7 12 12 15 15"/>
</svg>
''';

  static const String priorityHigh = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 2c.5 3.5 2.5 5 4.5 7 2 2 3 5 2 8-1 3-4 5-6.5 5S6 20 5 17c-1-3 0-6 2-8 0 2 1.5 3 3 3 0-3 1-6 2-10z"/>
</svg>
''';

  static const String priorityMedium = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M5 9.5h14"/>
  <path d="M5 14.5h14"/>
</svg>
''';

  static const String priorityLow = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M7 10l5 5 5-5"/>
</svg>
''';

  static const String shared = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="9" cy="7" r="4"/>
  <path d="M3 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/>
  <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
  <path d="M21 21v-2a4 4 0 0 0-3-3.85"/>
</svg>
''';

  static const String calendar = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="4" width="18" height="18" rx="3"/>
  <path d="M16 2v4M8 2v4M3 10h18"/>
</svg>
''';

  static const String recurrence = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M17 2l4 4-4 4"/>
  <path d="M3 11V9a4 4 0 0 1 4-4h14"/>
  <path d="M7 22l-4-4 4-4"/>
  <path d="M21 13v2a4 4 0 0 1-4 4H3"/>
</svg>
''';
}

/// Helper widget to render custom outlined SVGs with dynamic tint and sizing.
class AppOutlinedIcon extends StatelessWidget {
  final String svgString;
  final double size;
  final Color color;

  const AppOutlinedIcon({
    super.key,
    required this.svgString,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Outlined Status Badge without text.
class TaskStatusBadge extends StatelessWidget {
  final bool isDone;
  final double iconSize;

  const TaskStatusBadge({
    super.key,
    required this.isDone,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final iconColor = isDone ? palette.completed : palette.pending;
    final bgColor = isDone ? palette.completedBg : palette.pendingBg;
    final borderColor = isDone ? palette.completedBorder : palette.pendingBorder;

    return Tooltip(
      message: isDone ? 'Completed' : 'Pending',
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: AppOutlinedIcon(
          svgString: isDone
              ? AppOutlinedSvgStrings.completed
              : AppOutlinedSvgStrings.pending,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

/// Outlined Priority Badge without text.
class TaskPriorityBadge extends StatelessWidget {
  final String priority;
  final double iconSize;

  const TaskPriorityBadge({
    super.key,
    required this.priority,
    this.iconSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final norm = priority.toLowerCase().trim();

    Color iconColor;
    Color bgColor;
    Color borderColor;
    String svgString;
    String tooltip;

    if (norm == 'high') {
      iconColor = palette.priorityHigh;
      bgColor = palette.priorityHighBg;
      borderColor = palette.priorityHighBorder;
      svgString = AppOutlinedSvgStrings.priorityHigh;
      tooltip = 'High Priority';
    } else if (norm == 'low') {
      iconColor = palette.priorityLow;
      bgColor = palette.priorityLowBg;
      borderColor = palette.priorityLowBorder;
      svgString = AppOutlinedSvgStrings.priorityLow;
      tooltip = 'Low Priority';
    } else {
      iconColor = palette.priorityMedium;
      bgColor = palette.priorityMediumBg;
      borderColor = palette.priorityMediumBorder;
      svgString = AppOutlinedSvgStrings.priorityMedium;
      tooltip = 'Medium Priority';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: AppOutlinedIcon(
          svgString: svgString,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

/// Shared Priority Choice Pill for Create / Edit dialogs.
class PriorityChoicePill extends StatelessWidget {
  final String value;
  final String current;
  final VoidCallback onTap;

  const PriorityChoicePill({
    super.key,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isSel = current == value;
    final norm = value.toLowerCase().trim();

    Color iconColor;
    Color bgColor;
    String svgString;
    String tooltip;

    if (norm == 'high') {
      iconColor = palette.priorityHigh;
      bgColor = palette.priorityHighBg;
      svgString = AppOutlinedSvgStrings.priorityHigh;
      tooltip = 'High';
    } else if (norm == 'low') {
      iconColor = palette.priorityLow;
      bgColor = palette.priorityLowBg;
      svgString = AppOutlinedSvgStrings.priorityLow;
      tooltip = 'Low';
    } else {
      iconColor = palette.priorityMedium;
      bgColor = palette.priorityMediumBg;
      svgString = AppOutlinedSvgStrings.priorityMedium;
      tooltip = 'Medium';
    }

    return Tooltip(
      message: '$tooltip Priority',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSel ? bgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSel ? iconColor : palette.cardBorder,
              width: isSel ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppOutlinedIcon(
                svgString: svgString,
                size: 14,
                color: isSel ? iconColor : palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
