import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../models/task.dart';
import '../../../../models/friend.dart';
import '../../../../services/api_service.dart';
import '../../../widgets/app_outlined_icons.dart';

Future<void> showCreateTaskModal(
  BuildContext context, {
  required Function(Task newTask) onTaskCreated,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => CreateTaskDialog(onTaskCreated: onTaskCreated),
  );
}

class CreateTaskDialog extends StatefulWidget {
  final Function(Task newTask) onTaskCreated;

  const CreateTaskDialog({
    super.key,
    required this.onTaskCreated,
  });

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  DateTime? _selectedDate; // Default is no deadline
  TimeOfDay? _selectedTime;
  bool _hasTime = false;
  String _selectedPriority = 'medium';
  String _selectedCategory = 'General';
  String _selectedRecurrence = 'none';
  List<FriendItem> _availableFriends = [];
  final List<FriendUser> _selectedFriends = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _loadAvailableFriends();
  }

  Future<void> _loadAvailableFriends() async {
    try {
      final data = await ApiService().fetchFriends();
      if (mounted) {
        setState(() {
          _availableFriends = data.friends;
        });
      }
    } catch (_) {}
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

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

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

    try {
      final newTask = await ApiService().createTask(
        title: title,
        description: _descController.text.trim(),
        priority: _selectedPriority,
        dueDate: dueDate,
        hasTime: _hasTime,
        recurrence: _selectedRecurrence,
        category: _selectedCategory,
        sharedWith: _selectedFriends.map((f) => f.id).toList(),
      );
      widget.onTaskCreated(newTask);
    } catch (_) {
      // Offline fallback: save locally and notify user
      final offlineTask = Task(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: _descController.text.trim(),
        priority: _selectedPriority,
        dueDate: dueDate,
        hasTime: _hasTime,
        recurrence: _selectedRecurrence,
        category: _selectedCategory,
        sharedWith: _selectedFriends,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      widget.onTaskCreated(offlineTask);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Saved offline. Will sync when back online.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = palette.surfaceElevated;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;
    final inputBg = palette.inputBg;
    final badgeBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4E7);

    return Dialog(
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Create Task Title + Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Task',
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeBg,
                    ),
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

            // Task Title Input
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: TextField(
                controller: _titleController,
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  color: textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Task title...',
                  hintStyle: TextStyle(
                    fontFamily: 'Sniglet',
                    color: textSecondary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Due Date & Time Row
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
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: textPrimary,
                      ),
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

            // Priority Row
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
                        Icons.flag_outlined,
                        size: 16,
                        color: textPrimary,
                      ),
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

            // Extra Field: Description
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: TextField(
                controller: _descController,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  color: textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Description (optional)...',
                  hintStyle: TextStyle(
                    fontFamily: 'Sniglet',
                    color: textSecondary,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Extra Field: Category Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'General',
                  'Work',
                  'Personal',
                  'Study',
                  'Health',
                  'Shopping'
                ].map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? (isDark ? Colors.white : const Color(0xFF4B5563))
                              : inputBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel
                                ? (isDark ? Colors.black : Colors.white)
                                : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Share with Friends Row
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
                        Icons.group_add_outlined,
                        size: 16,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Share',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                if (_availableFriends.isEmpty)
                  Text(
                    'No friends yet',
                    style: TextStyle(
                      fontFamily: 'Sniglet',
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  )
                else
                  PopupMenuButton<FriendUser>(
                    onSelected: (friend) {
                      setState(() {
                        if (_selectedFriends.any((f) => f.id == friend.id)) {
                          _selectedFriends.removeWhere((f) => f.id == friend.id);
                        } else {
                          _selectedFriends.add(friend);
                        }
                      });
                    },
                    color: isDark ? const Color(0xFF222222) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    itemBuilder: (ctx) => _availableFriends.map((f) {
                      final isSel = _selectedFriends.any((sf) => sf.id == f.user.id);
                      return PopupMenuItem<FriendUser>(
                        value: f.user,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              f.user.displayName,
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? textPrimary : textSecondary,
                              ),
                            ),
                            if (isSel) const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(18),
                        border: _selectedFriends.isNotEmpty
                            ? Border.all(color: const Color(0xFF10B981), width: 1.2)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 14,
                            color: _selectedFriends.isNotEmpty ? const Color(0xFF10B981) : textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _selectedFriends.isEmpty
                                ? '+ Friend'
                                : '${_selectedFriends.length} shared',
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 12,
                              fontWeight: _selectedFriends.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                              color: _selectedFriends.isNotEmpty ? const Color(0xFF10B981) : textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down_rounded, size: 18, color: textSecondary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (_selectedFriends.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedFriends.map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          f.displayName,
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _selectedFriends.removeWhere((sf) => sf.id == f.id)),
                          child: Icon(Icons.close, size: 13, color: textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 22),

            // Add Task Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF4B5563),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _submit,
              child: const Text(
                'Add Task',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
