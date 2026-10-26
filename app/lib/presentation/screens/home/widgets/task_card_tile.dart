import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../models/task.dart';
import '../../../widgets/app_outlined_icons.dart';

class TaskCardTile extends StatelessWidget {
  final Task task;
  final String? currentUserId;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const TaskCardTile({
    super.key,
    required this.task,
    this.currentUserId,
    required this.onToggle,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isChecked = task.isShared
        ? (currentUserId != null && task.completedBy.contains(currentUserId))
        : task.completed;

    final formattedDate = formatDueDate(task.dueDate, hasTime: task.hasTime);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFE8E2D8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Icons.delete_outline, color: palette.textPrimary, size: 24),
      ),
      onDismissed: (_) => onDismissed(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.cardBorder),
            boxShadow: [
              BoxShadow(
                color: palette.softShadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Squircle Checkbox
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isChecked
                        ? palette.checkboxCheckedBg
                        : Colors.transparent,
                    border: Border.all(
                      color: isChecked
                          ? Colors.transparent
                          : palette.checkboxBorder,
                      width: 2,
                    ),
                  ),
                  child: isChecked
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: palette.checkboxCheckedIcon,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Title + Due Date Row
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: task.completed
                            ? palette.textMuted
                            : palette.textPrimary,
                        decoration:
                            task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (formattedDate.isNotEmpty ||
                        task.isRecurring ||
                        task.isShared) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (formattedDate.isNotEmpty) ...[
                            AppOutlinedIcon(
                              svgString: AppOutlinedSvgStrings.calendar,
                              size: 12,
                              color: palette.calendarIcon,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: palette.calendarText,
                              ),
                            ),
                          ],
                          if (task.isRecurring) ...[
                            if (formattedDate.isNotEmpty)
                              const SizedBox(width: 8),
                            AppOutlinedIcon(
                              svgString: AppOutlinedSvgStrings.recurrence,
                              size: 12,
                              color: palette.recurrenceIcon,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              task.recurrence[0].toUpperCase() +
                                  task.recurrence.substring(1),
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 11,
                                color: palette.recurrenceText,
                              ),
                            ),
                          ],
                          if (task.isShared) ...[
                            if (formattedDate.isNotEmpty || task.isRecurring)
                              const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: palette.sharedBadgeBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: palette.sharedBadgeBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppOutlinedIcon(
                                    svgString: AppOutlinedSvgStrings.shared,
                                    size: 11,
                                    color: palette.sharedBadgeText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.dualProgressText,
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: palette.sharedBadgeText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Priority Pill Badge (SVG Outlined Art, No text)
              TaskPriorityBadge(priority: task.priority),
              const SizedBox(width: 6),

              // Chevron Right
              Icon(
                Icons.chevron_right,
                size: 18,
                color: palette.iconMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
