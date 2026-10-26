import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

/// Central asset paths for all SVG icons stored as separate files in assets/svg/
class AppSvgAssets {
  AppSvgAssets._();

  static const String completed = 'assets/svg/completed.svg';
  static const String pending = 'assets/svg/pending.svg';
  static const String priorityHigh = 'assets/svg/priority_high.svg';
  static const String priorityMedium = 'assets/svg/priority_medium.svg';
  static const String priorityLow = 'assets/svg/priority_low.svg';
  static const String shared = 'assets/svg/shared.svg';
  static const String calendar = 'assets/svg/calendar.svg';
  static const String recurrence = 'assets/svg/recurrence.svg';
  static const String handwrittenTick = 'assets/svg/tick.svg';
  static const String handwrittenCross = 'assets/svg/cross.svg';
  static const String paw = 'assets/svg/paw.svg';

  // Navigation icons
  static const String homeActive = 'assets/svg/home_active.svg';
  static const String homeInactive = 'assets/svg/home_inactive.svg';
  static const String friendsActive = 'assets/svg/friends_active.svg';
  static const String friendsInactive = 'assets/svg/friends_inactive.svg';
  static const String profileActive = 'assets/svg/profile_active.svg';
  static const String profileInactive = 'assets/svg/profile_inactive.svg';
}

/// Backwards compatibility alias pointing to separate SVG asset files.
class AppOutlinedSvgStrings {
  AppOutlinedSvgStrings._();

  static const String completed = AppSvgAssets.completed;
  static const String pending = AppSvgAssets.pending;
  static const String priorityHigh = AppSvgAssets.priorityHigh;
  static const String priorityMedium = AppSvgAssets.priorityMedium;
  static const String priorityLow = AppSvgAssets.priorityLow;
  static const String shared = AppSvgAssets.shared;
  static const String calendar = AppSvgAssets.calendar;
  static const String recurrence = AppSvgAssets.recurrence;
  static const String handwrittenTick = AppSvgAssets.handwrittenTick;
  static const String handwrittenCross = AppSvgAssets.handwrittenCross;
  static const String paw = AppSvgAssets.paw;
}

/// Helper widget to render custom outlined SVGs from assets or strings with dynamic tint and sizing.
class AppOutlinedIcon extends StatelessWidget {
  final String? assetPath;
  final String? svgString;
  final double size;
  final Color color;

  const AppOutlinedIcon({
    super.key,
    this.assetPath,
    this.svgString,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pathOrContent = assetPath ?? svgString ?? '';
    if (pathOrContent.startsWith('assets/')) {
      return SvgPicture.asset(
        pathOrContent,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return SvgPicture.string(
      pathOrContent,
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
