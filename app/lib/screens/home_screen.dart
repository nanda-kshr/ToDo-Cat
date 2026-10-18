import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';
import '../services/floating_cat_service.dart';
import '../services/theme_service.dart';
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

  int _currentTab = 0; // 0 = Home, 1 = Stats
  String _filter = 'all'; // all, active, completed
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isFloatingOverlayRunning = false;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedTasks().then((_) => _loadData());
    _checkFloatingOverlayStatus();
    _initWidgetLaunchHandling();
  }

  Future<void> _loadCachedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('tasks_json');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> localList = jsonDecode(raw);
        final loaded = localList
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted && loaded.isNotEmpty && _tasks.isEmpty) {
          setState(() {
            _tasks = loaded;
            _loading = false;
          });
        }
      }
    } catch (_) {}
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
    _searchController.dispose();
    _widgetClickSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCachedTasks();
      _loadData(showLoading: false);
      _checkFloatingOverlayStatus();
    }
  }

  Future<void> _checkFloatingOverlayStatus() async {
    final running = await FloatingCatService.isRunning();
    if (mounted && running != _isFloatingOverlayRunning) {
      setState(() => _isFloatingOverlayRunning = running);
    }
  }

  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading || _tasks.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final user = await _apiService.getMe();
      final tasks = await _apiService.fetchTasks();

      // Sync offline tasks created or updated via widget or floating cat
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('tasks_json');
        if (raw != null) {
          final List<dynamic> localList = jsonDecode(raw);
          final serverTaskMap = {for (var t in tasks) t.id: t};
          final serverTitles = tasks.map((t) => t.title).toSet();
          for (final item in localList) {
            final title = item['title'] as String?;
            final id = item['id'] as String?;
            final completed = item['completed'] as bool? ?? false;
            if (title != null &&
                title.isNotEmpty &&
                id != null &&
                id.contains('-') &&
                !serverTitles.contains(title)) {
              final created = await _apiService.createTask(title: title);
              tasks.insert(0, created);
              serverTitles.add(title);
            } else if (id != null && serverTaskMap.containsKey(id)) {
              final serverTask = serverTaskMap[id]!;
              if (serverTask.completed != completed) {
                await _apiService.updateTask(id, completed: completed);
                final idx = tasks.indexWhere((t) => t.id == id);
                if (idx != -1) {
                  tasks[idx] = tasks[idx].copyWith(
                    completed: completed,
                    updatedAt: DateTime.now(),
                  );
                }
              }
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _user = user;
          _tasks = tasks;
          _loading = false;
          _error = null;
        });
        _syncWidget();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_tasks.isEmpty) {
            _error = e.toString();
          }
          _loading = false;
        });
      }
    }
  }

  void _syncWidget() {
    final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    final isWhite = ThemeService.instance.isCatWhite(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    WidgetService.updateWidget(
      pendingCount: _activeCount,
      totalCount: _todayTotalCount,
      speedPercent: _catSpeed,
      speedMessage: _activeCount == 0 ? 'All caught up' : '$_activeCount tasks pending',
      isDark: isDark,
      isCatWhite: isWhite,
      tasks: _tasks,
    );
    if (_isFloatingOverlayRunning) {
      FloatingCatService.update(
        speedPercent: _catSpeed,
        speedMessage: _activeCount == 0 ? 'All caught up' : '$_activeCount tasks pending',
        tasksJson: tasksJson,
        isCatWhite: isWhite,
        isDark: isDark,
      );
    }
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  int get _activeCount => _tasks.where((t) => !t.completed).length;
  int get _completedCount => _tasks.where((t) => t.completed).length;
  int get _completedTodayCount => _tasks
      .where((t) => t.completed && _isToday(t.updatedAt ?? t.createdAt))
      .length;
  int get _todayTotalCount => _activeCount + _completedTodayCount;

  int get _catSpeed {
    if (_todayTotalCount == 0 || _activeCount == 0) return 0;
    final totalRef = _todayTotalCount < 5 ? 5.0 : _todayTotalCount.toDouble();
    return ((_activeCount / totalRef) * 100).clamp(0, 100).round();
  }

  List<Task> get _filteredTasks {
    return _tasks.where((t) {
      if (_filter == 'active' && t.completed) return false;
      if (_filter == 'completed' && !t.completed) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(q);
        final matchDesc = t.description.toLowerCase().contains(q);
        final matchCat = t.category.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchCat) return false;
      }
      return true;
    }).toList();
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    if (diffDays == -1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _toggleTask(Task task) async {
    final nextCompleted = !task.completed;
    final now = DateTime.now();
    setState(() {
      _tasks = _tasks.map((t) {
        return t.id == task.id
            ? t.copyWith(completed: nextCompleted, updatedAt: now)
            : t;
      }).toList();
    });
    _syncWidget();

    try {
      await _apiService.toggleTask(task);
    } catch (e) {
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
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF4B5563)),
          ),
          content: Text(
            'TodoCat needs permission to show the floating running cat overlay on your screen.',
            style: TextStyle(color: isDark ? const Color(0xFFA3A3A3) : const Color(0xFF4B5563)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF4B5563),
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              child: const Text('Grant Permission'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await FloatingCatService.start(
      speedPercent: _catSpeed,
      speedMessage: _activeCount == 0 ? 'All caught up' : '$_activeCount tasks pending',
      tasksJson: tasksJson,
      isCatWhite: isWhite,
      isDark: isDark,
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
          backgroundColor: isDark ? const Color(0xFF171717) : const Color(0xFF4B5563),
        ),
      );
    }
  }

  Future<void> _showWidgetChoiceDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171717) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
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

  // --- SETTINGS MODAL (Screenshot 2) ---
  void _showSettingsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF181818) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final cardBg = isDark ? const Color(0xFF222222) : const Color(0xFFF4F4F5);
    final cardBorder = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE4E4E7);
    final activeBorder = isDark ? Colors.white : const Color(0xFF4B5563);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: dialogBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentMode = ThemeService.instance.themeMode.value;
            final currentCatVariant = ThemeService.instance.catColorVariant.value;
            final isEffectiveDark = currentMode == ThemeMode.dark ||
                (currentMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness == Brightness.dark);

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 22, right: 22, top: 4, bottom: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Title + Circular Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontFamily: 'Sniglet',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
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
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: isDark ? Colors.white70 : const Color(0xFF52525B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Section 1: Theme Mode
                    Text(
                      'Theme Mode',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // System
                        _buildSettingOptionCard(
                          label: 'System',
                          iconWidget: Icon(
                            Icons.brightness_auto_outlined,
                            size: 26,
                            color: currentMode == ThemeMode.system
                                ? textPrimary
                                : textSecondary,
                          ),
                          isSelected: currentMode == ThemeMode.system,
                          onTap: () {
                            ThemeService.instance.setThemeMode(ThemeMode.system);
                            setDialogState(() {});
                            setState(() {});
                            _syncWidget();
                          },
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          activeBorder: activeBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        // Light
                        _buildSettingOptionCard(
                          label: 'Light',
                          iconWidget: Icon(
                            Icons.wb_sunny_outlined,
                            size: 26,
                            color: currentMode == ThemeMode.light
                                ? textPrimary
                                : textSecondary,
                          ),
                          isSelected: currentMode == ThemeMode.light,
                          onTap: () {
                            ThemeService.instance.setThemeMode(ThemeMode.light);
                            setDialogState(() {});
                            setState(() {});
                            _syncWidget();
                          },
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          activeBorder: activeBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        // Dark
                        _buildSettingOptionCard(
                          label: 'Dark',
                          iconWidget: Icon(
                            Icons.nightlight_round,
                            size: 26,
                            color: currentMode == ThemeMode.dark
                                ? textPrimary
                                : textSecondary,
                          ),
                          isSelected: currentMode == ThemeMode.dark,
                          onTap: () {
                            ThemeService.instance.setThemeMode(ThemeMode.dark);
                            setDialogState(() {});
                            setState(() {});
                            _syncWidget();
                          },
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          activeBorder: activeBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Section 2: Cat Color
                    Text(
                      'Cat Color',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Auto
                        _buildSettingOptionCard(
                          label: 'Auto',
                          iconWidget: Image.asset(
                            isEffectiveDark
                                ? 'assets/runners/cat_white/cat_0.png'
                                : 'assets/runners/cat/cat_0.png',
                            width: 32,
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 24),
                          ),
                          isSelected: currentCatVariant == 'auto',
                          onTap: () {
                            ThemeService.instance.setCatColorVariant('auto');
                            setDialogState(() {});
                            setState(() {});
                            _syncWidget();
                          },
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          activeBorder: activeBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        // Black
                        _buildSettingOptionCard(
                          label: 'Black',
                          iconWidget: Image.asset(
                            'assets/runners/cat/cat_0.png',
                            width: 32,
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 24),
                          ),
                          isSelected: currentCatVariant == 'black',
                          onTap: () {
                            ThemeService.instance.setCatColorVariant('black');
                            setDialogState(() {});
                            setState(() {});
                            _syncWidget();
                          },
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          activeBorder: activeBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        // White
                        _buildSettingOptionCard(
                          label: 'White',
                          iconWidget: Image.asset(
                            'assets/runners/cat_white/cat_0.png',
                            width: 32,
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 24),
                          ),
                          isSelected: currentCatVariant == 'white',
                          onTap: () {
                            ThemeService.instance.setCatColorVariant('white');
                            setDialogState(() {});
                            setState(() {});
                            _syncWidget();
                          },
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          activeBorder: activeBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Floating Cat Overlay Switch Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Floating Cat Overlay',
                                style: TextStyle(
                                  fontFamily: 'Sniglet',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Show a running cat on top of other apps',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isFloatingOverlayRunning,
                          activeTrackColor: isDark ? Colors.white : const Color(0xFF4B5563),
                          activeThumbColor: isDark ? Colors.black : Colors.white,
                          inactiveTrackColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE4E4E7),
                          onChanged: (_) async {
                            await _toggleFloatingCat();
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Extra field: Home Screen Widgets
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showWidgetChoiceDialog();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4E7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.widgets_outlined, size: 20, color: textPrimary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Home Screen Widgets',
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Setup quick tasks and running cat widgets',
                                    style: TextStyle(color: textSecondary, fontSize: 11),
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
                      Divider(color: cardBorder),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user!.name ?? _user!.email.split('@').first,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  _user!.email,
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _logout();
                            },
                            icon: const Icon(Icons.logout, size: 16, color: Color(0xFFEF4444)),
                            label: const Text(
                              'Sign Out',
                              style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                            ),
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

  Widget _buildSettingOptionCard({
    required String label,
    required Widget iconWidget,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardBg,
    required Color cardBorder,
    required Color activeBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? cardBg : cardBg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeBorder : cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? textPrimary : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CREATE TASK MODAL (Screenshot 3) ---
  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedPriority = 'medium';
    String selectedCategory = 'General';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF181818) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final inputBg = isDark ? const Color(0xFF222222) : const Color(0xFFF4F4F5);
    final badgeBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4E7);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          onTap: () => Navigator.pop(ctx),
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

                    // Task Title Input (Pill Shaped)
                    Container(
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      child: TextField(
                        controller: titleController,
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

                    // Due Date Row
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
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
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
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 15,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDueDate(selectedDate),
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
                            _buildPriorityPill(
                              label: 'Low',
                              value: 'low',
                              current: selectedPriority,
                              bgColor: isDark ? const Color(0xFF14291B) : const Color(0xFFE8F5E9),
                              textColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                              onTap: () => setModalState(() => selectedPriority = 'low'),
                            ),
                            const SizedBox(width: 6),
                            _buildPriorityPill(
                              label: 'Medium',
                              value: 'medium',
                              current: selectedPriority,
                              bgColor: isDark ? const Color(0xFF382C13) : const Color(0xFFFEF3C7),
                              textColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                              onTap: () => setModalState(() => selectedPriority = 'medium'),
                            ),
                            const SizedBox(width: 6),
                            _buildPriorityPill(
                              label: 'High',
                              value: 'high',
                              current: selectedPriority,
                              bgColor: isDark ? const Color(0xFF381A1A) : const Color(0xFFFEE2E2),
                              textColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                              onTap: () => setModalState(() => selectedPriority = 'high'),
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
                        controller: descController,
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
                          final isSel = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => setModalState(() => selectedCategory = cat),
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
                    const SizedBox(height: 22),

                    // Add Task Action Button (Grey + White monochrome)
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
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isNotEmpty) {
                          Navigator.pop(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final newTask = await _apiService.createTask(
                              title: title,
                              description: descController.text.trim(),
                              priority: selectedPriority,
                              dueDate: selectedDate,
                              category: selectedCategory,
                            );
                            if (mounted) {
                              setState(() {
                                _tasks.insert(0, newTask);
                              });
                              _syncWidget();
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed to create task: $e')),
                              );
                            }
                          }
                        }
                      },
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
          },
        );
      },
    );
  }

  Widget _buildPriorityPill({
    required String label,
    required String value,
    required String current,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    final isSel = current == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: isSel
              ? Border.all(color: textColor, width: 1.5)
              : null,
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

  // --- MAIN SCREEN BUILD (Screenshot 1) ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF242424) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    final filtered = _filteredTasks;
    final completionPercent = _todayTotalCount == 0
        ? 0
        : ((_completedTodayCount / _todayTotalCount) * 100).round();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        titleSpacing: 18,
        title: Text(
          'Todocat',
          style: TextStyle(
            fontFamily: 'Sniglet',
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _showSettingsModal,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF3F4F6),
                  border: Border.all(color: cardBorder),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF52525B),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.white : const Color(0xFF4B5563),
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
                            backgroundColor: isDark ? Colors.white : const Color(0xFF4B5563),
                            foregroundColor: isDark ? Colors.black : Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _currentTab == 1
                  ? _buildStatsView(isDark, cardBg, cardBorder, textPrimary, textSecondary)
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: isDark ? Colors.white : const Color(0xFF4B5563),
                      backgroundColor: cardBg,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          // Status Banner Card: Running Cat on Left + Progress & % on Right
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                // Left: Running Cat (Grey + White monochrome)
                                CatAnimation(
                                  speedPercent: _catSpeed,
                                  size: 88,
                                  showContainer: false,
                                ),
                                const SizedBox(width: 16),

                                // Right: Active Count, Percentage, Progress Bar, Done / Remaining
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_activeCount Active Tasks',
                                        style: TextStyle(
                                          fontFamily: 'Sniglet',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$completionPercent%',
                                        style: TextStyle(
                                          fontFamily: 'Sniglet',
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: (_todayTotalCount == 0
                                                  ? 0.0
                                                  : (_completedTodayCount / _todayTotalCount))
                                              .clamp(0.0, 1.0),
                                          minHeight: 8,
                                          backgroundColor: isDark
                                              ? const Color(0xFF282828)
                                              : const Color(0xFFE5E7EB),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isDark ? Colors.white : const Color(0xFF4B5563),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$_completedTodayCount done today · $_activeCount remaining',
                                        style: TextStyle(
                                          fontFamily: 'Sniglet',
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
                          const SizedBox(height: 16),

                          // Filter Tabs (All, Active, Completed Pills)
                          Row(
                            children: [
                              _buildFilterTab(
                                id: 'all',
                                label: 'All',
                                count: _tasks.length,
                                isDark: isDark,
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterTab(
                                id: 'active',
                                label: 'Active',
                                count: _activeCount,
                                isDark: isDark,
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterTab(
                                id: 'completed',
                                label: 'Completed',
                                count: _completedCount,
                                isDark: isDark,
                                cardBg: cardBg,
                                cardBorder: cardBorder,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Search Bar (Rounded Pill)
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: cardBorder),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Icon(Icons.search, size: 20, color: textSecondary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) => setState(() => _searchQuery = val),
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      color: textPrimary,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search tasks...',
                                      hintStyle: TextStyle(
                                        fontFamily: 'Sniglet',
                                        color: textSecondary,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: Icon(Icons.close, size: 18, color: textSecondary),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Task List
                          if (filtered.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.checklist_rtl,
                                    size: 42,
                                    color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No tasks found for "$_searchQuery"'
                                        : 'No tasks here yet',
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      color: textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...filtered.map((task) => _buildTaskCard(task, isDark, cardBg, cardBorder, textPrimary, textSecondary)),

                          // Grass illustration at the end of the task list
                          const SizedBox(height: 24),
                          SvgPicture.asset(
                            'assets/grass.svg',
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                          const SizedBox(height: 72),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        backgroundColor: isDark ? Colors.white : const Color(0xFF4B5563),
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      // Bottom Navigation Bar (Home, Stats)
      bottomNavigationBar: Container(
        height: 62,
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(
            top: BorderSide(color: cardBorder),
          ),
        ),
        child: Row(
          children: [
            _buildBottomNavItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: _currentTab == 0,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildBottomNavItem(
              index: 1,
              icon: Icons.bar_chart_rounded,
              label: 'Stats',
              isSelected: _currentTab == 1,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final activeColor = isDark ? Colors.white : const Color(0xFF4B5563);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FILTER TAB PILL ---
  Widget _buildFilterTab({
    required String id,
    required String label,
    required int count,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isSel = _filter == id;
    final activeBg = isDark ? Colors.white : const Color(0xFF4B5563);
    final activeText = isDark ? Colors.black : Colors.white;
    final activeBadgeBg = isDark ? const Color(0xFFE5E5E5) : const Color(0xFF374151);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? activeBg : cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSel ? activeBg : cardBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? activeText : textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSel
                      ? activeBadgeBg
                      : (isDark ? const Color(0xFF262626) : const Color(0xFFE4E4E7)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? activeText : textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TASK CARD TILE ---
  Widget _buildTaskCard(
    Task task,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final formattedDate = _formatDueDate(task.dueDate);

    return Dismissible(
      key: Key(task.id),
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
      onDismissed: (_) => _deleteTask(task.id),
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
              onTap: () => _toggleTask(task),
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
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
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
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Priority Pill Badge
            _buildTaskPriorityBadge(task.priority, isDark),
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
    );
  }

  Widget _buildTaskPriorityBadge(String priority, bool isDark) {
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

  // --- STATS VIEW (Stats tab) ---
  Widget _buildStatsView(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final completionRate = _tasks.isEmpty
        ? 0
        : ((_completedCount / _tasks.length) * 100).round();

    final highCount = _tasks.where((t) => t.priority == 'high' && !t.completed).length;
    final medCount = _tasks.where((t) => t.priority == 'medium' && !t.completed).length;
    final lowCount = _tasks.where((t) => t.priority == 'low' && !t.completed).length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Text(
          'Productivity Overview',
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // Big Metric Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completion Rate',
                style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '$completionRate%',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_tasks.isEmpty ? 0.0 : (_completedCount / _tasks.length)).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: isDark ? const Color(0xFF282828) : const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_completedCount completed',
                    style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 12),
                  ),
                  Text(
                    '$_activeCount pending',
                    style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3 Cards: Total, Completed, Pending
        Row(
          children: [
            _buildStatMetricCard('Total', '${_tasks.length}', isDark, cardBg, cardBorder, textPrimary, textSecondary),
            const SizedBox(width: 8),
            _buildStatMetricCard('Done', '$_completedCount', isDark, cardBg, cardBorder, textPrimary, textSecondary),
            const SizedBox(width: 8),
            _buildStatMetricCard('Active', '$_activeCount', isDark, cardBg, cardBorder, textPrimary, textSecondary),
          ],
        ),
        const SizedBox(height: 16),

        // Priority Breakdown
        Text(
          'Pending by Priority',
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              _buildPriorityStatRow('High Priority', '$highCount', isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626), textPrimary),
              Divider(color: cardBorder, height: 20),
              _buildPriorityStatRow('Medium Priority', '$medCount', isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), textPrimary),
              Divider(color: cardBorder, height: 20),
              _buildPriorityStatRow('Low Priority', '$lowCount', isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), textPrimary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatMetricCard(
    String label,
    String value,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityStatRow(String label, String count, Color dotColor, Color textPrimary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontFamily: 'Sniglet', fontSize: 14, color: textPrimary),
            ),
          ],
        ),
        Text(
          count,
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
