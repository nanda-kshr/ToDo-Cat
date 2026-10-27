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
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentDelete;
  final bool isDeleted;

  const TaskCardTile({
    super.key,
    required this.task,
    this.currentUserId,
    required this.onToggle,
    required this.onTap,
    required this.onDismissed,
    this.onRestore,
    this.onPermanentDelete,
    this.isDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isChecked = task.isShared
        ? (currentUserId != null && task.completedBy.contains(currentUserId))
        : task.completed;

    final formattedDate = formatDueDate(task.dueDate, hasTime: task.hasTime);

    // View for deleted tasks (below Today section)
    if (isDeleted) {
      return Dismissible(
        key: ValueKey('del_${task.id}'),
        direction: DismissDirection.horizontal,
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.35,
          DismissDirection.endToStart: 0.35,
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(left: 20),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2E24) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                Icons.restore,
                color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Restore',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF331818) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete Forever',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.delete_forever,
                color: isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
                size: 22,
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onRestore?.call();
            return true;
          } else if (direction == DismissDirection.endToStart) {
            onPermanentDelete?.call();
            return true;
          }
          return false;
        },
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161616) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.cardBorder.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: palette.textMuted.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontFamily: 'Sniglet',
                      fontSize: 15,
                      color: palette.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                if (onRestore != null)
                  IconButton(
                    icon: const Icon(Icons.restore, size: 20),
                    tooltip: 'Restore task',
                    color: palette.iconPrimary,
                    onPressed: onRestore,
                  ),
                if (onPermanentDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_forever_outlined, size: 20),
                    tooltip: 'Delete permanently',
                    color: isDark ? const Color(0xFFE57373) : const Color(0xFFEF4444),
                    onPressed: onPermanentDelete,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Active / Completed normal card
    return Dismissible(
      key: ValueKey('task_${task.id}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2922) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              isChecked ? Icons.remove_done : Icons.check_circle_outline,
              color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isChecked ? 'Mark Active' : 'Mark Done',
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E1A1A) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.delete_outline,
              color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
              size: 24,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Slide right: optimistic toggle
          onToggle();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Slide left: mark as deleted
          onDismissed();
          return true;
        }
        return false;
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: palette.taskCardBg,
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
              // Squircle Checkbox with smooth animation
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
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
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
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
                      child: Text(task.title),
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
