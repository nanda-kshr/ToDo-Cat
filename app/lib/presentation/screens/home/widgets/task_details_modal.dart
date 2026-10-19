import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../models/task.dart';
import 'task_card_tile.dart';

Future<void> showTaskDetailsModal(
  BuildContext context, {
  required Task task,
  required List<Task> tasks,
  required Future<void> Function(Task task) onToggle,
  required Future<void> Function(String taskId) onDelete,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dialogBg = isDark ? const Color(0xFF181818) : Colors.white;
  final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
  final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
  final cardBg = isDark ? const Color(0xFF222222) : const Color(0xFFF4F4F5);
  final cardBorder = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE4E4E7);
  final formattedDueDate = formatDueDate(task.dueDate);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: dialogBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final currentTask = tasks.firstWhere(
            (t) => t.id == task.id,
            orElse: () => task,
          );

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 22, right: 22, top: 4, bottom: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: Priority, Category & Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          TaskPriorityBadge(priority: currentTask.priority),
                          if (currentTask.category.isNotEmpty && currentTask.category != 'General') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Text(
                                currentTask.category,
                                style: TextStyle(
                                  fontFamily: 'Sniglet',
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4E7),
                          ),
                          child: Icon(Icons.close, size: 18, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    currentTask.title,
                    style: TextStyle(
                      fontFamily: 'Sniglet',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: currentTask.completed ? textSecondary : textPrimary,
                      decoration: currentTask.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),

                  // Description (if present)
                  if (currentTask.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Text(
                        currentTask.description,
                        style: TextStyle(
                          fontFamily: 'Sniglet',
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Status and Info Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        // Toggle Status Row
                        InkWell(
                          onTap: () async {
                            await onToggle(currentTask);
                            setModalState(() {});
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  color: currentTask.completed
                                      ? (isDark ? Colors.white : const Color(0xFF4B5563))
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: currentTask.completed
                                        ? Colors.transparent
                                        : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8)),
                                    width: 2,
                                  ),
                                ),
                                child: currentTask.completed
                                    ? Icon(
                                        Icons.check,
                                        size: 15,
                                        color: isDark ? Colors.black : Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                currentTask.completed ? 'Completed' : 'Mark as completed',
                                style: TextStyle(
                                  fontFamily: 'Sniglet',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Due Date row if present
                        if (formattedDueDate.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: cardBorder, height: 1),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Due $formattedDueDate',
                                style: TextStyle(
                                  fontFamily: 'Sniglet',
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delete Task Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await onDelete(currentTask.id);
                    },
                    icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Delete Task',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      backgroundColor: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
