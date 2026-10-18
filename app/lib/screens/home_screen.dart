import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/analytics.dart';
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

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  int _currentTab = 0; // 0 = Home, 1 = Stats
  String _filter = 'all'; // all, active, completed
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  TaskAnalytics? _analytics;
  bool _loadingAnalytics = false;
  String? _analyticsError;
  String _statsPeriod = '7d'; // 'today', '7d', '30d', 'this_month'

  bool _isFloatingOverlayRunning = false;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  Future<void> _loadAnalytics({String? period}) async {
    final selectedPeriod = period ?? _statsPeriod;
    setState(() {
      _loadingAnalytics = true;
      _analyticsError = null;
      _statsPeriod = selectedPeriod;
    });

    try {
      final res = await _apiService.fetchAnalytics(period: selectedPeriod);
      if (mounted) {
        setState(() {
          _analytics = res;
          _loadingAnalytics = false;
          _analyticsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAnalytics = false;
          _analyticsError = e.toString();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    FloatingCatService.initialize();
    FloatingCatService.onTasksUpdated = _onExternalTasksUpdated;
    _loadCachedTasks().then((_) => _loadData());
    _checkFloatingOverlayStatus();
    _initWidgetLaunchHandling();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200 && !_isLoadingMore && _hasMore && !_loading) {
      _loadMoreTasks();
    }
  }

  Future<void> _loadMoreTasks() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final res = await _apiService.fetchTasks(page: nextPage, limit: 50);
      if (mounted) {
        final existingIds = _tasks.map((t) => t.id).toSet();
        final newTasks = res.tasks.where((t) => !existingIds.contains(t.id)).toList();
        setState(() {
          _currentPage = nextPage;
          _tasks = [..._tasks, ...newTasks];
          _hasMore = res.hasMore;
          _isLoadingMore = false;
        });
        _syncWidget();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onExternalTasksUpdated(String raw) {
    if (!mounted) return;
    _applyLocalTasksJson(raw);
  }

  Future<void> _applyLocalTasksJson(String raw) async {
    try {
      final List<dynamic> localList = jsonDecode(raw);
      final loaded = localList
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
      if (loaded.isEmpty && _tasks.isNotEmpty) return;

      if (_tasks.isEmpty) {
        if (mounted) {
          setState(() {
            _tasks = loaded;
            _loading = false;
          });
        }
      } else {
        final localMap = {for (var t in loaded) t.id: t};
        final existingIds = _tasks.map((t) => t.id).toSet();
        final newTasks = loaded.where((t) => !existingIds.contains(t.id)).toList();
        final merged = [
          ...newTasks,
          ..._tasks.map((t) {
            if (localMap.containsKey(t.id)) {
              final lt = localMap[t.id]!;
              return t.copyWith(
                completed: lt.completed,
                updatedAt: lt.updatedAt ?? t.updatedAt,
              );
            }
            return t;
          }),
        ];
        if (mounted) {
          setState(() {
            _tasks = merged;
          });
        }
      }

      _syncOfflineTasksToServer();
    } catch (_) {}
  }

  Future<void> _loadCachedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString('tasks_json');
      if (raw != null && raw.isNotEmpty) {
        await _applyLocalTasksJson(raw);
      }
    } catch (_) {}
  }

  Future<void> _syncOfflineTasksToServer([List<Task>? serverTasks]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString('tasks_json');
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> localList = jsonDecode(raw);
      final targetList = serverTasks ?? _tasks;
      final serverTaskMap = {for (var t in targetList) t.id: t};
      final serverTitles = targetList.map((t) => t.title).toSet();
      bool hasChanges = false;

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
          if (serverTasks != null) {
            serverTasks.insert(0, created);
          } else {
            final idx = _tasks.indexWhere((t) => t.id == id);
            if (idx != -1) {
              _tasks[idx] = created;
            } else {
              _tasks.insert(0, created);
            }
          }
          serverTitles.add(title);
          hasChanges = true;
        } else if (id != null && serverTaskMap.containsKey(id)) {
          final serverTask = serverTaskMap[id]!;
          if (serverTask.completed != completed) {
            await _apiService.updateTask(id, completed: completed);
            final idx = (serverTasks ?? _tasks).indexWhere((t) => t.id == id);
            if (idx != -1) {
              (serverTasks ?? _tasks)[idx] = (serverTasks ?? _tasks)[idx].copyWith(
                completed: completed,
                updatedAt: DateTime.now(),
              );
            }
            hasChanges = true;
          }
        }
      }

      if (hasChanges && serverTasks == null && mounted) {
        setState(() {});
        _syncWidget();
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    FloatingCatService.onTasksUpdated = null;
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
      final res = await _apiService.fetchTasks(page: 1, limit: 50);
      final tasks = res.tasks;

      // Sync offline tasks created or updated via widget or floating cat
      await _syncOfflineTasksToServer(tasks);

      if (mounted) {
        setState(() {
          _user = user;
          _tasks = tasks;
          _currentPage = 1;
          _hasMore = res.hasMore;
          _loading = false;
          _error = null;
        });
        _syncWidget();
        if (_currentTab == 1) {
          _loadAnalytics();
        }
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
    final todayTasks = filtered.where((t) => !t.completed || _isToday(t.updatedAt ?? t.createdAt)).toList();
    final earlierTasks = filtered.where((t) => t.completed && !_isToday(t.updatedAt ?? t.createdAt)).toList();
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
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          // Controls Header (Status Banner, Filter Tabs, Search Bar)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
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
                                        // Left: Running Cat (Grey + White monochrome) isolated in RepaintBoundary
                                        RepaintBoundary(
                                          child: CatAnimation(
                                            speedPercent: _catSpeed,
                                            size: 88,
                                            showContainer: false,
                                          ),
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
                                ],
                              ),
                            ),
                          ),

                          // Task List or Empty State
                          if (filtered.isEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverToBoxAdapter(
                                child: Container(
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
                                ),
                              ),
                            )
                          else ...[
                            // 1. Today's Tasks Section Header
                            if (earlierTasks.isNotEmpty && todayTasks.isNotEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                                sliver: SliverToBoxAdapter(
                                  child: Row(
                                    children: [
                                      Text(
                                        'Today',
                                        style: TextStyle(
                                          fontFamily: 'Sniglet',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: cardBorder),
                                        ),
                                        child: Text(
                                          '${todayTasks.length}',
                                          style: TextStyle(
                                            fontFamily: 'Sniglet',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // 1. Today's Tasks List (Lazy recycled items)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverList.builder(
                                itemCount: todayTasks.length,
                                itemBuilder: (context, index) => _buildTaskCard(
                                  todayTasks[index],
                                  isDark,
                                  cardBg,
                                  cardBorder,
                                  textPrimary,
                                  textSecondary,
                                ),
                              ),
                            ),

                            // 2. Completed Till Yesterday Section Header
                            if (earlierTasks.isNotEmpty) ...[
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                                sliver: SliverToBoxAdapter(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 15,
                                        color: textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Completed Earlier',
                                        style: TextStyle(
                                          fontFamily: 'Sniglet',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: cardBorder),
                                        ),
                                        child: Text(
                                          '${earlierTasks.length}',
                                          style: TextStyle(
                                            fontFamily: 'Sniglet',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 2. Completed Till Yesterday Tasks List (Lazy recycled items)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverList.builder(
                                  itemCount: earlierTasks.length,
                                  itemBuilder: (context, index) => _buildTaskCard(
                                    earlierTasks[index],
                                    isDark,
                                    cardBg,
                                    cardBorder,
                                    textPrimary,
                                    textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // Footer with loading indicator and grass illustration
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isLoadingMore)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: isDark ? Colors.white : const Color(0xFF4B5563),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                  RepaintBoundary(
                                    child: SvgPicture.asset(
                                      'assets/grass.svg',
                                      width: double.infinity,
                                      fit: BoxFit.fitWidth,
                                    ),
                                  ),
                                  const SizedBox(height: 72),
                                ],
                              ),
                            ),
                          ),
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
        onTap: () {
          setState(() => _currentTab = index);
          if (index == 1 && _analytics == null) {
            _loadAnalytics();
          }
        },
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

  // --- TASK DETAILS MODAL ---
  void _showTaskDetailsModal(Task task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF181818) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final cardBg = isDark ? const Color(0xFF222222) : const Color(0xFFF4F4F5);
    final cardBorder = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE4E4E7);
    final formattedDueDate = _formatDueDate(task.dueDate);

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
          builder: (context, setModalState) {
            final currentTask = _tasks.firstWhere(
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
                            _buildTaskPriorityBadge(currentTask.priority, isDark),
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
                              await _toggleTask(currentTask);
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
                        await _deleteTask(currentTask.id);
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
      child: InkWell(
        onTap: () => _showTaskDetailsModal(task),
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

  // --- STATS VIEW (Stats tab using GET /api/analytics) ---
  Widget _buildStatsView(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_loadingAnalytics && _analytics == null) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white : const Color(0xFF4B5563),
        ),
      );
    }

    if (_analyticsError != null && _analytics == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 12),
              Text(
                _analyticsError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadAnalytics(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : const Color(0xFF4B5563),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _analytics;
    if (data == null) {
      return const SizedBox();
    }

    final summary = data.summary;
    final byPriority = data.byPriority;
    final high = byPriority['high'] ?? PriorityStats(total: 0, completed: 0, pending: 0);
    final med = byPriority['medium'] ?? PriorityStats(total: 0, completed: 0, pending: 0);
    final low = byPriority['low'] ?? PriorityStats(total: 0, completed: 0, pending: 0);

    final due = data.dueStatus;
    final categories = data.byCategory;
    final trends = data.completionTrend;
    final maxTrend = trends.isEmpty
        ? 1
        : trends.map((t) => t.completed).reduce((a, b) => a > b ? a : b).clamp(1, 9999);

    return RefreshIndicator(
      onRefresh: () => _loadAnalytics(),
      color: isDark ? Colors.white : const Color(0xFF4B5563),
      backgroundColor: cardBg,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (_loadingAnalytics)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Period Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodFilterTab(
                  period: 'today',
                  label: 'Today',
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 8),
                _buildPeriodFilterTab(
                  period: '7d',
                  label: '7 Days',
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 8),
                _buildPeriodFilterTab(
                  period: '30d',
                  label: '30 Days',
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 8),
                _buildPeriodFilterTab(
                  period: 'this_month',
                  label: 'This Month',
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Hero Metric Card: Completion Rate
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
                  '${summary.completionRate}%',
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
                    value: (summary.total == 0 ? 0.0 : (summary.completed / summary.total)).clamp(0.0, 1.0),
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
                      '${summary.completed} completed',
                      style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 12),
                    ),
                    Text(
                      '${summary.pending} pending',
                      style: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Metric Cards: Total, Done, Active
          Row(
            children: [
              _buildStatMetricCard('Total', '${summary.total}', isDark, cardBg, cardBorder, textPrimary, textSecondary),
              const SizedBox(width: 8),
              _buildStatMetricCard('Done', '${summary.completed}', isDark, cardBg, cardBorder, textPrimary, textSecondary),
              const SizedBox(width: 8),
              _buildStatMetricCard('Active', '${summary.pending}', isDark, cardBg, cardBorder, textPrimary, textSecondary),
            ],
          ),
          const SizedBox(height: 16),

          // Due Status Breakdown
          Text(
            'Due Status',
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                _buildDueStatusItem('Overdue', due.overdue, isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626), textPrimary, textSecondary),
                _buildDueStatusItem('Due Today', due.dueToday, isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), textPrimary, textSecondary),
                _buildDueStatusItem('Upcoming', due.upcoming, isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), textPrimary, textSecondary),
                _buildDueStatusItem('No Due Date', due.noDueDate, textSecondary, textPrimary, textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Priority Breakdown
          Text(
            'Tasks by Priority',
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
                _buildPriorityStatRow('High Priority', '${high.total}', '${high.completed} done · ${high.pending} pending', isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626), textPrimary, textSecondary),
                Divider(color: cardBorder, height: 20),
                _buildPriorityStatRow('Medium Priority', '${med.total}', '${med.completed} done · ${med.pending} pending', isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), textPrimary, textSecondary),
                Divider(color: cardBorder, height: 20),
                _buildPriorityStatRow('Low Priority', '${low.total}', '${low.completed} done · ${low.pending} pending', isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), textPrimary, textSecondary),
              ],
            ),
          ),

          // Category Breakdown
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'By Category',
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
                children: categories.map((cat) => _buildCategoryRow(cat, isDark, cardBorder, textPrimary, textSecondary)).toList(),
              ),
            ),
          ],

          // Completion Trend
          if (trends.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Daily Completion Trend',
              style: TextStyle(
                fontFamily: 'Sniglet',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trends.map((t) => _buildTrendBar(t, maxTrend, isDark, textSecondary, textPrimary)).toList(),
              ),
            ),
          ],

          // Grass illustration at bottom of stats
          const SizedBox(height: 24),
          RepaintBoundary(
            child: SvgPicture.asset(
              'assets/grass.svg',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildPeriodFilterTab({
    required String period,
    required String label,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isSelected = _statsPeriod == period;
    return InkWell(
      onTap: () {
        if (_statsPeriod != period) {
          _loadAnalytics(period: period);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : const Color(0xFF4B5563))
              : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDueStatusItem(String label, int count, Color color, Color textPrimary, Color textSecondary) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: count > 0 ? color : textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 11,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(CategoryStats cat, bool isDark, Color cardBorder, Color textPrimary, Color textSecondary) {
    final rate = cat.total == 0 ? 0.0 : (cat.completed / cat.total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cat.category,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                '${cat.completed}/${cat.total} done',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF282828) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBar(CompletionTrendPoint point, int maxVal, bool isDark, Color textSecondary, Color textPrimary) {
    final parts = point.date.split('-');
    final label = parts.length >= 3 ? '${parts[1]}/${parts[2]}' : point.date;
    final compH = maxVal > 0 ? ((point.completed / maxVal) * 44).clamp(4.0, 44.0) : 4.0;
    final isDone = point.completed > 0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${point.completed}',
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 10,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone ? textPrimary : textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: compH,
            width: 14,
            decoration: BoxDecoration(
              color: isDone
                  ? (isDark ? Colors.white : const Color(0xFF4B5563))
                  : (isDark ? const Color(0xFF282828) : const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 10,
              color: textSecondary,
            ),
          ),
        ],
      ),
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

  Widget _buildPriorityStatRow(String label, String count, String subtext, Color dotColor, Color textPrimary, Color textSecondary) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontFamily: 'Sniglet', fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtext,
                  style: TextStyle(fontFamily: 'Sniglet', fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ],
        ),
        Text(
          count,
          style: TextStyle(
            fontFamily: 'Sniglet',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
