import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../models/task.dart';
import 'task_card_tile.dart';

Future<void> showTaskDetailsModal(
  BuildContext context, {
  required Task task,
  required List<Task> Function() getTasks,
  required Future<void> Function(Task task) onToggle,
  required Future<void> Function(String taskId) onDelete,
  required Future<void> Function(
    Task task, {
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required String category,
  }) onEdit,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dialogBg = isDark ? const Color(0xFF181818) : Colors.white;
  final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
  final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
  final cardBg = isDark ? const Color(0xFF222222) : const Color(0xFFF4F4F5);
  final cardBorder = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE4E4E7);

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
          final currentTask = getTasks().firstWhere(
            (t) => t.id == task.id,
            orElse: () => task,
          );
          final formattedDueDate = formatDueDate(currentTask.dueDate);

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 22, right: 22, top: 4, bottom: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: Priority, Category & Actions
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
                      Row(
                        children: [
                          // Edit pencil icon
                          InkWell(
                            onTap: () async {
                              Navigator.pop(ctx);
                              await _showEditTaskModal(
                                context,
                                task: currentTask,
                                onEdit: onEdit,
                                isDark: isDark,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4E7),
                              ),
                              child: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
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

Future<void> _showEditTaskModal(
  BuildContext context, {
  required Task task,
  required Future<void> Function(
    Task task, {
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required String category,
  }) onEdit,
  required bool isDark,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _EditTaskDialog(task: task, onEdit: onEdit),
  );
}

class _EditTaskDialog extends StatefulWidget {
  final Task task;
  final Future<void> Function(
    Task task, {
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required String category,
  }) onEdit;

  const _EditTaskDialog({required this.task, required this.onEdit});

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late DateTime _selectedDate;
  late String _selectedPriority;
  late String _selectedCategory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _selectedDate = widget.task.dueDate ?? DateTime.now();
    _selectedPriority = widget.task.priority;
    _selectedCategory = widget.task.category.isNotEmpty ? widget.task.category : 'General';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    try {
      await widget.onEdit(
        widget.task,
        title: title,
        description: _descController.text.trim(),
        dueDate: _selectedDate,
        priority: _selectedPriority,
        category: _selectedCategory,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF181818) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final inputBg = isDark ? const Color(0xFF222222) : const Color(0xFFF4F4F5);
    final badgeBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4E7);

    return Dialog(
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Task',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: badgeBg),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF52525B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Title
            Container(
              decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: TextField(
                controller: _titleController,
                autofocus: true,
                style: TextStyle(fontFamily: 'Sniglet', color: textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Task title...',
                  hintStyle: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 15),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Due Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.calendar_today_outlined, size: 16, color: textPrimary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Due date',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 15, color: textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          formatDueDate(_selectedDate),
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Priority
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.flag_outlined, size: 16, color: textPrimary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Priority',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _PriorityPill(
                      label: 'Low',
                      value: 'low',
                      current: _selectedPriority,
                      bgColor: isDark ? const Color(0xFF14291B) : const Color(0xFFE8F5E9),
                      textColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                      onTap: () => setState(() => _selectedPriority = 'low'),
                    ),
                    const SizedBox(width: 6),
                    _PriorityPill(
                      label: 'Med',
                      value: 'medium',
                      current: _selectedPriority,
                      bgColor: isDark ? const Color(0xFF382C13) : const Color(0xFFFEF3C7),
                      textColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                      onTap: () => setState(() => _selectedPriority = 'medium'),
                    ),
                    const SizedBox(width: 6),
                    _PriorityPill(
                      label: 'High',
                      value: 'high',
                      current: _selectedPriority,
                      bgColor: isDark ? const Color(0xFF381A1A) : const Color(0xFFFEE2E2),
                      textColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                      onTap: () => setState(() => _selectedPriority = 'high'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: TextField(
                controller: _descController,
                maxLines: 2,
                style: TextStyle(fontFamily: 'Sniglet', color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Description (optional)...',
                  hintStyle: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['General', 'Work', 'Personal', 'Study', 'Health', 'Shopping'].map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? (isDark ? Colors.white : const Color(0xFF4B5563)) : inputBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? (isDark ? Colors.black : Colors.white) : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),

            // Save Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF4B5563),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _saving ? null : _submit,
              child: const Text(
                'Save Changes',
                style: TextStyle(fontFamily: 'Sniglet', fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _PriorityPill({
    required this.label,
    required this.value,
    required this.current,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSel = current == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: isSel ? Border.all(color: textColor, width: 1.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 13,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
