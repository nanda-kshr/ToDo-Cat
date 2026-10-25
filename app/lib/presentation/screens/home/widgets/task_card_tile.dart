import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../models/task.dart';

class TaskCardTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const TaskCardTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171717) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA3A3A3) : const Color(0xFF9CA3AF);

    final formattedDate = formatDueDate(task.dueDate, hasTime: task.hasTime);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDismissed(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
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
                    color: task.completed
                        ? (isDark ? Colors.white : const Color(0xFF4B5563))
                        : Colors.transparent,
                    border: Border.all(
                      color: task.completed
                          ? Colors.transparent
                          : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8)),
                      width: 2,
                    ),
                  ),
                  child: task.completed
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: isDark ? Colors.black : Colors.white,
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
                        color: task.completed ? textSecondary : textPrimary,
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (formattedDate.isNotEmpty || task.isRecurring) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (formattedDate.isNotEmpty) ...[
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                          if (task.isRecurring) ...[
                            if (formattedDate.isNotEmpty) const SizedBox(width: 8),
                            Icon(
                              Icons.repeat_rounded,
                              size: 12,
                              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              task.recurrence[0].toUpperCase() + task.recurrence.substring(1),
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 11,
                                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                              ),
                            ),
                          ],
                          if (task.isShared) ...[
                            if (formattedDate.isNotEmpty || task.isRecurring) const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: task.completed
                                    ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                                    : (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_alt_rounded,
                                    size: 11,
                                    color: task.completed
                                        ? const Color(0xFF16A34A)
                                        : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.dualProgressText,
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: task.completed
                                          ? const Color(0xFF16A34A)
                                          : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
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

              // Priority Pill Badge
              TaskPriorityBadge(priority: task.priority),
              const SizedBox(width: 6),

              // Chevron Right
              Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskPriorityBadge extends StatelessWidget {
  final String priority;

  const TaskPriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    String text;

    switch (priority.toLowerCase()) {
      case 'high':
        bg = isDark ? const Color(0xFF381A1A) : const Color(0xFFFEE2E2);
        fg = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        text = 'High';
        break;
      case 'low':
        bg = isDark ? const Color(0xFF14291B) : const Color(0xFFE8F5E9);
        fg = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
        text = 'Low';
        break;
      case 'medium':
      default:
        bg = isDark ? const Color(0xFF382C13) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
        text = 'Medium';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Sniglet',
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: fg,
        ),
      ),
    );
  }
}
