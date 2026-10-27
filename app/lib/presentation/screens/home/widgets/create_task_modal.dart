import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../models/task.dart';
import '../../../../models/friend.dart';
import '../../../../models/category.dart';
import '../../../../services/api_service.dart';
import '../../../widgets/app_outlined_icons.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/friend_picker_sheet.dart';

Future<void> showCreateTaskModal(
  BuildContext context, {
  required Function(Task newTask) onTaskCreated,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
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
  List<CategoryItem> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _loadAvailableFriends();
    _loadAvailableCategories();
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

  Future<void> _loadAvailableCategories() async {
    try {
      final cats = await ApiService().fetchCategories();
      if (mounted) {
        setState(() {
          _availableCategories = cats;
        });
      }
    } catch (_) {}
  }

  List<CategoryItem> get _displayCategories {
    final list = <CategoryItem>[
      const CategoryItem(id: 'general', name: 'General', isDefault: true),
      const CategoryItem(id: 'work', name: 'Work', isDefault: true),
    ];
    for (final cat in _availableCategories) {
      if (cat.name.toLowerCase() != 'general' && cat.name.toLowerCase() != 'work') {
        if (!list.any((c) => c.name.toLowerCase() == cat.name.toLowerCase())) {
          list.add(cat);
        }
      }
    }
    if (_selectedCategory.isNotEmpty &&
        !list.any((c) => c.name.toLowerCase() == _selectedCategory.toLowerCase())) {
      list.add(CategoryItem(id: 'custom', name: _selectedCategory));
    }
    return list;
  }

  Future<void> _showAddCategoryModal() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.of(context);
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBg = isDark ? const Color(0xFF282828) : const Color(0xFFF8EEDF);

    final catController = TextEditingController();
    List<FriendUser> selectedCategoryFriends = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cardBg,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: palette.activeChip,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.folder_outlined, size: 18, color: palette.activeChipText),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Add Category',
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: palette.cardBorder, width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: TextField(
                        controller: catController,
                        autofocus: true,
                        style: TextStyle(
                          fontFamily: 'Sniglet',
                          color: textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Category Name (e.g. Trip to Japan)',
                          hintStyle: TextStyle(
                            fontFamily: 'Sniglet',
                            color: textSecondary.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Share section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.group_outlined, size: 16, color: textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Share with friends',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (_availableFriends.isNotEmpty)
                          InkWell(
                            onTap: () async {
                              final res = await showFriendPickerSheet(
                                context: ctx,
                                availableFriends: _availableFriends,
                                initialSelected: selectedCategoryFriends,
                                title: 'Share Category with Friends',
                              );
                              if (res != null) {
                                setSheetState(() {
                                  selectedCategoryFriends = List<FriendUser>.from(res);
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: selectedCategoryFriends.isNotEmpty
                                    ? palette.activeChip
                                    : inputBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: palette.cardBorder, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selectedCategoryFriends.isNotEmpty
                                        ? Icons.edit_outlined
                                        : Icons.person_add_alt_1_rounded,
                                    size: 13,
                                    color: selectedCategoryFriends.isNotEmpty
                                        ? palette.activeChipText
                                        : textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedCategoryFriends.isEmpty
                                        ? '+ Select Friends'
                                        : '${selectedCategoryFriends.length} selected',
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selectedCategoryFriends.isNotEmpty
                                          ? palette.activeChipText
                                          : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_availableFriends.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No friends added yet. You can invite friends in the Friends tab to share projects.',
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      )
                    else if (selectedCategoryFriends.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedCategoryFriends.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282828) : const Color(0xFFEDF3EE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.cardBorder, width: 1),
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
                                  onTap: () {
                                    setSheetState(() {
                                      selectedCategoryFriends.removeWhere((sf) => sf.id == f.id);
                                    });
                                  },
                                  child: Icon(Icons.close_rounded, size: 13, color: textSecondary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.fabBg,
                              foregroundColor: palette.fabIcon,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              final name = catController.text.trim();
                              if (name.isEmpty) return;
                              Navigator.of(sheetCtx).pop();

                              try {
                                final newCat = await ApiService().createCategory(
                                  name: name,
                                  sharedWith: selectedCategoryFriends.map((f) => f.id).toList(),
                                );
                                if (mounted) {
                                  setState(() {
                                    _availableCategories.removeWhere((c) =>
                                        c.name.toLowerCase() == newCat.name.toLowerCase());
                                    _availableCategories.add(newCat);
                                    _selectedCategory = newCat.name;
                                    for (final f in selectedCategoryFriends) {
                                      if (!_selectedFriends.any((sf) => sf.id == f.id)) {
                                        _selectedFriends.add(f);
                                      }
                                    }
                                  });
                                  AppToast.show(null, 'Category "$name" added');
                                }
                              } catch (_) {
                                if (mounted) {
                                  setState(() {
                                    _selectedCategory = name;
                                  });
                                }
                              }
                            },
                            child: const Text(
                              'Create Category',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
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
      AppToast.show(null, 'Created task');
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
      AppToast.show(null, 'Saved offline');
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
      child: Dialog(
        backgroundColor: dialogBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: RepaintBoundary(
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
                color: isDark ? inputBg : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF383838) : palette.cardBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.softShadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: TextField(
                controller: _titleController,
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  color: textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  icon: Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                  hintText: 'What needs to be done?...',
                  hintStyle: TextStyle(
                    fontFamily: 'Sniglet',
                    color: textSecondary.withValues(alpha: 0.7),
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
                        color: isDark ? inputBg : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.cardBorder, width: 1.2),
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
                          color: isDark ? inputBg : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: palette.cardBorder,
                            width: 1.5,
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
                            color: isDark ? inputBg : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: palette.cardBorder,
                              width: 1.2,
                            ),
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
                      color: isDark ? inputBg : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: palette.cardBorder,
                        width: 1.2,
                      ),
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
                color: isDark ? inputBg : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF383838) : palette.cardBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.softShadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _descController,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  color: textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  icon: Icon(Icons.notes_rounded, size: 18, color: textSecondary),
                  hintText: 'Description (optional)...',
                  hintStyle: TextStyle(
                    fontFamily: 'Sniglet',
                    color: textSecondary.withValues(alpha: 0.7),
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
                  ..._displayCategories.map((catItem) {
                    final isSel = _selectedCategory.toLowerCase() == catItem.name.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = catItem.name;
                            if (catItem.isShared) {
                              for (final friend in catItem.sharedWith) {
                                if (!_selectedFriends.any((f) => f.id == friend.id)) {
                                  _selectedFriends.add(friend);
                                }
                              }
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? palette.activeChip
                                : (isDark ? inputBg : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? Colors.transparent : palette.cardBorder,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (catItem.isShared) ...[
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 13,
                                  color: isSel ? palette.activeChipText : textSecondary,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                catItem.name,
                                style: TextStyle(
                                  fontFamily: 'Sniglet',
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel
                                      ? palette.activeChipText
                                      : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  // Add Category Button
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: _showAddCategoryModal,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? inputBg : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: palette.cardBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: palette.fabBg,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add Category',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
                  InkWell(
                    onTap: () async {
                      final res = await showFriendPickerSheet(
                        context: context,
                        availableFriends: _availableFriends,
                        initialSelected: _selectedFriends,
                        title: 'Share Task with Friends',
                      );
                      if (res != null) {
                        setState(() {
                          _selectedFriends.clear();
                          _selectedFriends.addAll(res);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(18),
                        border: _selectedFriends.isNotEmpty
                            ? Border.all(color: palette.subtleGreen, width: 1.2)
                            : Border.all(color: palette.cardBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 14,
                            color: _selectedFriends.isNotEmpty ? palette.subtleGreen : textSecondary,
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
                              color: _selectedFriends.isNotEmpty ? palette.subtleGreen : textSecondary,
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
                backgroundColor: palette.fabBg,
                foregroundColor: palette.fabIcon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 3,
                shadowColor: palette.softShadow,
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
    ),
    ),
  );
}
}
