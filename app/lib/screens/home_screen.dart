
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';
import '../services/floating_cat_service.dart';
import '../services/theme_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/cat_animation.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  User? _user;
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  String _filter = 'all'; // all, today, upcoming, completed
  String _priorityFilter = 'all'; // all, high, medium, low
  bool _isFloatingOverlayRunning = false;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _checkFloatingOverlayStatus();
    _initWidgetLaunchHandling();
  }

  void _initWidgetLaunchHandling() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunchUri);
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(_handleWidgetLaunchUri);
  }

  void _handleWidgetLaunchUri(Uri? uri) {
    if (uri == null) return;
    final uriStr = uri.toString().toLowerCase();
    if (uriStr.contains('create_task') || uri.host == 'create_task') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCreateTaskDialog();
        }
      });
    }
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
      _checkFloatingOverlayStatus();
    }
  }

  Future<void> _checkFloatingOverlayStatus() async {
    final running = await FloatingCatService.isRunning();
    if (mounted && running != _isFloatingOverlayRunning) {
      setState(() => _isFloatingOverlayRunning = running);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _apiService.getMe();
      final tasks = await _apiService.fetchTasks();

      // Sync any local offline tasks created via floating overlay
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('tasks_json');
        if (raw != null) {
          final List<dynamic> localList = jsonDecode(raw);
          final serverTitles = tasks.map((t) => t.title).toSet();
          for (final item in localList) {
            final title = item['title'] as String?;
            final id = item['id'] as String?;
            if (title != null && title.isNotEmpty && id != null && id.contains('-') && !serverTitles.contains(title)) {
              final created = await _apiService.createTask(title: title);
              tasks.insert(0, created);
              serverTitles.add(title);
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _user = user;
          _tasks = tasks;
          _loading = false;
        });
        _syncWidget();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _syncWidget() {
    final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    WidgetService.updateWidget(
      pendingCount: _activeCount,
      totalCount: _tasks.length,
      speedPercent: _catSpeed,
      speedMessage: _activeCount == 0 ? 'All caught up' : '$_activeCount tasks pending',
      tasks: _tasks,
    );
    if (_isFloatingOverlayRunning) {
      final isWhite = ThemeService.instance.isCatWhite(context);
      FloatingCatService.update(
        speedPercent: _catSpeed,
        speedMessage: _activeCount == 0 ? 'All caught up' : '$_activeCount tasks pending',
        tasksJson: tasksJson,
        isCatWhite: isWhite,
      );
    }
  }

  Future<void> _toggleFloatingCat() async {
    if (!FloatingCatService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Floating cat overlay is supported on Android devices')),
      );
      return;
    }

    if (_isFloatingOverlayRunning) {
      await FloatingCatService.stop();
      if (mounted) {
        setState(() => _isFloatingOverlayRunning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Floating Cat closed')),
        );
      }
      return;
    }

    final hasPerm = await FloatingCatService.hasPermission();
    if (!hasPerm && mounted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Enable Floating Cat',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
          ),
          content: Text(
            'To float the animated cat over your home screen and other apps, Android requires the "Display over other apps" permission.',
            style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4B5563)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF111827),
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (proceed == true) {
        await FloatingCatService.requestPermission();
      }
      return;
    }

    if (!mounted) return;
    final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    final isWhite = ThemeService.instance.isCatWhite(context);
    await FloatingCatService.start(
      speedPercent: _catSpeed,
      speedMessage: _activeCount == 0 ? 'All caught up' : '$_activeCount tasks pending',
      tasksJson: tasksJson,
      isCatWhite: isWhite,
    );
    if (mounted) {
      setState(() => _isFloatingOverlayRunning = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Floating Cat active! Tap to expand tasks, drag to bottom to remove.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pinWidget({bool isCatWidget = false}) async {
    _syncWidget();
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pinned = await WidgetService.requestPinWidget(isCatWidget: isCatWidget);
    if (!pinned && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'To add the widget, long-press home screen > Widgets > TodoCat.',
          ),
          backgroundColor: isDark ? const Color(0xFF171717) : const Color(0xFF111827),
        ),
      );
    }
  }

  Future<void> _showWidgetChoiceDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171717) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF737373) : const Color(0xFF6B7280);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Widget',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.checklist, color: textPrimary, size: 22),
                ),
                title: Text(
                  'TodoCat Tasks',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  'Scrollable tasks list with quick add button',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pinWidget(isCatWidget: false);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.pets, color: textPrimary, size: 22),
                ),
                title: Text(
                  'TodoCat Running Cat',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  'Square animated companion with velocity and counts',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pinWidget(isCatWidget: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _showSettingsSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171717) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF737373) : const Color(0xFF6B7280);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final themeMode = ThemeService.instance.themeMode.value;
            final catVariant = ThemeService.instance.catColorVariant.value;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: textSecondary, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Theme Mode Dropdown
                    Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ThemeMode>(
                          value: themeMode,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF262626) : Colors.white,
                          icon: Icon(Icons.keyboard_arrow_down, color: textSecondary),
                          items: [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System Default (Auto)', style: TextStyle(color: textPrimary, fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark Mode', style: TextStyle(color: textPrimary, fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light Mode', style: TextStyle(color: textPrimary, fontSize: 14)),
                            ),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              ThemeService.instance.setThemeMode(mode);
                              setSheetState(() {});
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Cat Color Variant
                    Text(
                      'Cat Appearance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: catVariant,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF262626) : Colors.white,
                          icon: Icon(Icons.keyboard_arrow_down, color: textSecondary),
                          items: [
                            DropdownMenuItem(
                              value: 'auto',
                              child: Text('Auto (Dark = White cat, Light = Black cat)', style: TextStyle(color: textPrimary, fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'white',
                              child: Text('White Cat', style: TextStyle(color: textPrimary, fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'black',
                              child: Text('Black Cat', style: TextStyle(color: textPrimary, fontSize: 14)),
                            ),
                          ],
                          onChanged: (variant) {
                            if (variant != null) {
                              ThemeService.instance.setCatColorVariant(variant);
                              setSheetState(() {});
                              setState(() {});
                              _syncWidget();
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Floating Cat Companion Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Floating Companion',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Float running cat over other apps',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isFloatingOverlayRunning,
                            activeThumbColor: isDark ? Colors.white : const Color(0xFF111827),
                            onChanged: (_) async {
                              await _toggleFloatingCat();
                              setSheetState(() {});
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 4. Home Screen Widgets Option
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showWidgetChoiceDialog();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.widgets_outlined, size: 20, color: textPrimary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Home Screen Widgets',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Add responsive TodoCat widget to home screen',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),

                    if (_user != null) ...[
                      const SizedBox(height: 16),
                      Divider(color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _user!.name ?? _user!.email.split('@').first,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                _user!.email,
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _logout();
                            },
                            icon: const Icon(Icons.logout, size: 16, color: Color(0xFFEF4444)),
                            label: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleTask(Task task) async {
    final nextCompleted = !task.completed;

    // Optimistic UI update
    setState(() {
      _tasks = _tasks.map((t) {
        return t.id == task.id ? t.copyWith(completed: nextCompleted) : t;
      }).toList();
    });
    _syncWidget();

    try {
      await _apiService.toggleTask(task);
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _tasks = _tasks.map((t) {
            return t.id == task.id ? t.copyWith(completed: task.completed) : t;
          }).toList();
        });
        _syncWidget();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(String id) async {
    final original = List<Task>.from(_tasks);
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
    _syncWidget();

    try {
      await _apiService.deleteTask(id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _tasks = original;
        });
        _syncWidget();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
    }
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final categoryController = TextEditingController(text: 'General');
    DateTime? selectedDate;
    String selectedPriority = 'medium';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF181818) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF252525) : const Color(0xFFF3F4F6);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF888888) : const Color(0xFF6B7280);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New Task',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Task Title',
                        hintStyle: TextStyle(color: textSecondary),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Description (optional)',
                        hintStyle: TextStyle(color: textSecondary),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Due Date & Category Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: fieldBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedDate != null
                                          ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'
                                          : 'Due Date',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: selectedDate != null ? textPrimary : textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: categoryController,
                            style: TextStyle(color: textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Category',
                              hintStyle: TextStyle(color: textSecondary),
                              filled: true,
                              fillColor: fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Priority Chips (Pill shape, smooth soft colors)
                    Row(
                      children: [
                        {'key': 'low', 'label': 'LOW', 'color': const Color(0xFF10B981)},
                        {'key': 'medium', 'label': 'MED', 'color': const Color(0xFFF59E0B)},
                        {'key': 'high', 'label': 'HIGH', 'color': const Color(0xFFEF4444)},
                      ].map((item) {
                        final key = item['key'] as String;
                        final label = item['label'] as String;
                        final color = item['color'] as Color;
                        final isSel = selectedPriority == key;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  selectedPriority = key;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? color.withValues(alpha: isDark ? 0.25 : 0.15) : fieldBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSel ? color : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? color : textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Create Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : const Color(0xFF111827),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        try {
                          final created = await _apiService.createTask(
                            title: title,
                            description: descController.text.trim(),
                            dueDate: selectedDate,
                            priority: selectedPriority,
                            category: categoryController.text.trim(),
                          );
                          setState(() {
                            _tasks.insert(0, created);
                          });
                          _syncWidget();
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error creating task: $e')),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Create Task',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  List<Task> get _filteredTasks {
    return _tasks.where((t) {
      if (_filter == 'today') {
        if (!t.isToday && !(t.isOverdue && !t.completed)) return false;
      } else if (_filter == 'upcoming') {
        if (!t.isUpcoming || t.completed) return false;
      } else if (_filter == 'completed') {
        if (!t.completed) return false;
      }

      if (_priorityFilter != 'all' && t.priority != _priorityFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  int get _activeCount => _tasks.where((t) => !t.completed).length;
  int get _completedCount => _tasks.where((t) => t.completed).length;

  int get _catSpeed {
    if (_tasks.isEmpty || _activeCount == 0) return 0;
    final totalRef = _tasks.length < 5 ? 5.0 : _tasks.length.toDouble();
    return ((_activeCount / totalRef) * 100).clamp(0, 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171717) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF737373) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const AppLogo(size: 32, borderRadius: 8),
            const SizedBox(width: 10),
            Text(
              'TodoCat',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              size: 22,
            ),
            tooltip: 'Settings',
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: isDark ? Colors.white : const Color(0xFF111827),
        backgroundColor: cardBg,
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 48,
                            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : const Color(0xFF111827),
                              foregroundColor: isDark ? Colors.black : Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Status Banner Card: Big Square Cat + Progress on Right
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Big Square Running Cat (No border, no background box)
                            CatAnimation(
                              speedPercent: _catSpeed,
                              size: 84,
                              showContainer: false,
                              idleRunWhenSleeping: false,
                            ),
                            const SizedBox(width: 16),
                            // Progress on the right side
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _activeCount == 0
                                              ? 'All caught up'
                                              : '$_activeCount ${_activeCount == 1 ? 'task' : 'tasks'} pending',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$_catSpeed%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: (_tasks.isEmpty ? 0.0 : (_completedCount / _tasks.length)).clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark ? Colors.white : const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_completedCount of ${_tasks.length} tasks completed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // View Filter Chips (All, Today, Upcoming, Completed)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('all', 'All Tasks (${_tasks.length})'),
                            const SizedBox(width: 6),
                            _filterChip('today', 'Today'),
                            const SizedBox(width: 6),
                            _filterChip('upcoming', 'Upcoming'),
                            const SizedBox(width: 6),
                            _filterChip('completed', 'Completed ($_completedCount)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Priority Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _priorityChip('all', 'All Priorities'),
                            const SizedBox(width: 6),
                            _priorityChip('high', 'High'),
                            const SizedBox(width: 6),
                            _priorityChip('medium', 'Medium'),
                            const SizedBox(width: 6),
                            _priorityChip('low', 'Low'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Task List
                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.checklist_rtl, size: 40, color: Colors.white24),
                              SizedBox(height: 8),
                              Text(
                                'No tasks in this view',
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filtered.map((task) => _taskTile(task)),
                    ],
                  ),
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? Colors.white : const Color(0xFF111827),
        foregroundColor: isDark ? Colors.black : Colors.white,
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSel = _filter == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          color: isSel
              ? (isDark ? Colors.white : const Color(0xFF111827))
              : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
        ),
      ),
      selected: isSel,
      selectedColor: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
      backgroundColor: isDark ? const Color(0xFF171717) : const Color(0xFFF3F4F6),
      side: BorderSide(
        color: isSel
            ? (isDark ? const Color(0xFF525252) : const Color(0xFFD1D5DB))
            : (isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
      ),
      onSelected: (_) {
        setState(() {
          _filter = id;
        });
      },
    );
  }

  Widget _priorityChip(String id, String label) {
    final isSel = _priorityFilter == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          color: isSel
              ? (isDark ? Colors.white : const Color(0xFF111827))
              : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
        ),
      ),
      selected: isSel,
      selectedColor: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
      backgroundColor: isDark ? const Color(0xFF171717) : const Color(0xFFF3F4F6),
      side: BorderSide(
        color: isSel
            ? (isDark ? const Color(0xFF525252) : const Color(0xFFD1D5DB))
            : (isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
      ),
      onSelected: (_) {
        setState(() {
          _priorityFilter = id;
        });
      },
    );
  }

  Widget _taskTile(Task task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: task.completed
            ? (isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FAFB))
            : (isDark ? const Color(0xFF171717) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.completed
              ? (isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF3F4F6))
              : (isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          InkWell(
            onTap: () => _toggleTask(task),
            child: Container(
              margin: const EdgeInsets.only(top: 2, right: 10),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: task.completed ? const Color(0xFF10B981) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: task.completed
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF525252) : const Color(0xFF9CA3AF)),
                ),
              ),
              child: task.completed
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: task.completed
                              ? (isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF))
                              : (isDark ? Colors.white : const Color(0xFF111827)),
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _priorityBadge(task.priority),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: task.completed
                          ? (isDark ? const Color(0xFF525252) : const Color(0xFF9CA3AF))
                          : (isDark ? const Color(0xFFA3A3A3) : const Color(0xFF4B5563)),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (task.category.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (task.dueDate != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 11,
                        color: task.isOverdue
                            ? const Color(0xFFF43F5E)
                            : task.isToday
                                ? const Color(0xFFF59E0B)
                                : Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.isOverdue
                            ? 'Overdue'
                            : task.isToday
                                ? 'Due Today'
                                : '${task.dueDate!.month}/${task.dueDate!.day}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: task.isOverdue
                              ? const Color(0xFFF43F5E)
                              : task.isToday
                                  ? const Color(0xFFF59E0B)
                                  : Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Delete icon
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
            onPressed: () => _deleteTask(task.id),
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    Color bg;
    Color fg;
    if (priority == 'high') {
      bg = const Color(0xFFF43F5E).withValues(alpha: 0.15);
      fg = const Color(0xFFFB7185);
    } else if (priority == 'medium') {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      fg = const Color(0xFFFBBF24);
    } else {
      bg = const Color(0xFF10B981).withValues(alpha: 0.15);
      fg = const Color(0xFF34D399);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
