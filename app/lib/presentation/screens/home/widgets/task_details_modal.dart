import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../models/task.dart';
import '../../../widgets/app_outlined_icons.dart';

Future<void> showTaskDetailsModal(
  BuildContext context, {
  required Task task,
  String? currentUserId,
  required List<Task> Function() getTasks,
  required Future<void> Function(Task task) onToggle,
  required Future<void> Function(String taskId) onDelete,
  required Future<void> Function(
    Task task, {
    required String title,
    required String description,
    required DateTime? dueDate,
    required bool hasTime,
    required String recurrence,
    required String priority,
    required String category,
  }) onEdit,
}) {
  final palette = AppColors.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dialogBg = palette.surfaceElevated;
  final textPrimary = palette.textPrimary;
  final textSecondary = palette.textSecondary;
  final cardBg = palette.surface;
  final cardBorder = palette.cardBorder;

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
          final formattedDueDate = formatDueDate(currentTask.dueDate, hasTime: currentTask.hasTime);

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
                          if (currentTask.isRecurring) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat_rounded, size: 12, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentTask.recurrence[0].toUpperCase() + currentTask.recurrence.substring(1),
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
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
                        Builder(
                          builder: (context) {
                            final isChecked = currentTask.isShared
                                ? (currentUserId != null && currentTask.completedBy.contains(currentUserId))
                                : currentTask.completed;
                            return InkWell(
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
                                      color: isChecked
                                          ? (isDark ? Colors.white : const Color(0xFF4B5563))
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isChecked
                                            ? Colors.transparent
                                            : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8)),
                                        width: 2,
                                      ),
                                    ),
                                    child: isChecked
                                        ? Icon(
                                            Icons.check,
                                            size: 15,
                                            color: isDark ? Colors.black : Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    currentTask.completed
                                        ? 'Completed'
                                        : (currentTask.isShared && isChecked
                                            ? 'My part completed (Waiting for friends)'
                                            : (currentTask.isShared
                                                ? 'Mark my part complete'
                                                : 'Mark as completed')),
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

                        // Shared Friends & Dual Completion Row
                        if (currentTask.isShared) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: cardBorder, height: 1),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_alt_rounded,
                                        size: 16,
                                        color: textPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Participants',
                                        style: TextStyle(
                                          fontFamily: 'Sniglet',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      currentTask.dualProgressText,
                                      style: TextStyle(
                                        fontFamily: 'Sniglet',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...currentTask.allParticipants.map((person) {
                                final isDone = currentTask.completedBy.contains(person.id);
                                final isCreator = currentTask.creator != null && currentTask.creator!.id == person.id;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                                        backgroundImage: person.avatar != null && person.avatar!.isNotEmpty
                                            ? NetworkImage(person.avatar!)
                                            : null,
                                        child: person.avatar == null || person.avatar!.isEmpty
                                            ? Text(
                                                person.displayName.isNotEmpty ? person.displayName[0].toUpperCase() : '?',
                                                style: TextStyle(
                                                  fontFamily: 'Sniglet',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: textPrimary,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    person.displayName,
                                                    style: TextStyle(
                                                      fontFamily: 'Sniglet',
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: textPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (currentUserId != null && person.id == currentUserId) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'You',
                                                      style: TextStyle(
                                                        fontFamily: 'Sniglet',
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (isCreator) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Creator',
                                                      style: TextStyle(
                                                        fontFamily: 'Sniglet',
                                                        fontSize: 10,
                                                        color: textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (person.email.isNotEmpty)
                                              Text(
                                                person.email,
                                                style: TextStyle(
                                                  fontFamily: 'Sniglet',
                                                  fontSize: 11,
                                                  color: textSecondary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TaskStatusBadge(isDone: isDone),
                                    ],
                                  ),
                                );
                              }),
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
                      final taskId = currentTask.id;
                      Navigator.pop(ctx);
                      await onDelete(taskId);
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
    required DateTime? dueDate,
    required bool hasTime,
    required String recurrence,
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
    required DateTime? dueDate,
    required bool hasTime,
    required String recurrence,
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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late bool _hasTime;
  late String _selectedPriority;
  late String _selectedCategory;
  late String _selectedRecurrence;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _selectedDate = widget.task.dueDate;
    _hasTime = widget.task.hasTime;
    _selectedTime = widget.task.dueDate != null && widget.task.hasTime
        ? TimeOfDay.fromDateTime(widget.task.dueDate!)
        : null;
    _selectedPriority = widget.task.priority;
    _selectedCategory = widget.task.category.isNotEmpty ? widget.task.category : 'General';
    _selectedRecurrence = widget.task.recurrence.isNotEmpty ? widget.task.recurrence : 'none';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _recurrenceLabel(String val) {
    switch (val) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'none':
      default:
        return 'None';
    }
  }

  PopupMenuItem<String> _buildRecurrenceItem(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSel = _selectedRecurrence == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 13,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              color: isSel ? textPrimary : textSecondary,
            ),
          ),
          if (isSel) Icon(Icons.check, size: 16, color: textPrimary),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    try {
      final dueDate = _selectedDate == null
          ? null
          : (_hasTime && _selectedTime != null
              ? DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  _selectedTime!.hour,
                  _selectedTime!.minute,
                )
              : DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                ));

      await widget.onEdit(
        widget.task,
        title: title,
        description: _descController.text.trim(),
        dueDate: dueDate,
        hasTime: _hasTime,
        recurrence: _selectedRecurrence,
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

            // Due Date & Time
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
                      'Due',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                if (_selectedDate == null)
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+ Add date',
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white24 : const Color(0xFFD4D4D8),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate!,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 14,
                                    color: textPrimary,
                                  ),
                                  const SizedBox(width: 5),
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
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = null;
                                  _hasTime = false;
                                  _selectedTime = null;
                                });
                              },
                              child: Icon(Icons.close, size: 14, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () async {
                          final initial = _selectedTime ?? TimeOfDay.now();
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: initial,
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedTime = picked;
                              _hasTime = true;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(18),
                            border: _hasTime
                                ? Border.all(
                                    color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                                    width: 1.2,
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: _hasTime ? textPrimary : textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _hasTime && _selectedTime != null
                                    ? formatTime(DateTime(2026, 1, 1, _selectedTime!.hour, _selectedTime!.minute))
                                    : '+ Time',
                                style: TextStyle(
                                  fontFamily: 'Sniglet',
                                  fontSize: 12,
                                  fontWeight: _hasTime ? FontWeight.bold : FontWeight.w600,
                                  color: _hasTime ? textPrimary : textSecondary,
                                ),
                              ),
                              if (_hasTime) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _hasTime = false;
                                      _selectedTime = null;
                                    });
                                  },
                                  child: Icon(Icons.close, size: 13, color: textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Repeat / Recurring Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.repeat_rounded,
                        size: 16,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Repeat',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (val) => setState(() => _selectedRecurrence = val),
                  color: isDark ? const Color(0xFF222222) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  itemBuilder: (ctx) => [
                    _buildRecurrenceItem('None', 'none', textPrimary, textSecondary),
                    _buildRecurrenceItem('Daily', 'daily', textPrimary, textSecondary),
                    _buildRecurrenceItem('Weekly', 'weekly', textPrimary, textSecondary),
                    _buildRecurrenceItem('Monthly', 'monthly', textPrimary, textSecondary),
                    _buildRecurrenceItem('Yearly', 'yearly', textPrimary, textSecondary),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(18),
                      border: _selectedRecurrence != 'none'
                          ? Border.all(
                              color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                              width: 1.2,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _recurrenceLabel(_selectedRecurrence),
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 13,
                            fontWeight: _selectedRecurrence != 'none'
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: _selectedRecurrence != 'none'
                                ? textPrimary
                                : textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 18,
                          color: textSecondary,
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
                    PriorityChoicePill(
                      value: 'low',
                      current: _selectedPriority,
                      onTap: () => setState(() => _selectedPriority = 'low'),
                    ),
                    const SizedBox(width: 8),
                    PriorityChoicePill(
                      value: 'medium',
                      current: _selectedPriority,
                      onTap: () => setState(() => _selectedPriority = 'medium'),
                    ),
                    const SizedBox(width: 8),
                    PriorityChoicePill(
                      value: 'high',
                      current: _selectedPriority,
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
