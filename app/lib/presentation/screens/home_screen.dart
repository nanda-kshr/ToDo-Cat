import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../models/analytics.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/fcm_service.dart';
import '../../services/floating_cat_service.dart';
import '../../services/task_sync_service.dart';
import '../../services/theme_service.dart';
import '../../services/widget_service.dart';
import 'home/widgets/cat_trail_background.dart';
import 'home/widgets/create_task_modal.dart';
import 'home/widgets/friends_view.dart';
import 'home/widgets/home_bottom_bar.dart';
import 'home/widgets/home_tasks_view.dart';
import 'home/widgets/profile_view.dart';
import 'home/widgets/settings_modal.dart';
import 'home/widgets/task_details_modal.dart';
import 'home/widgets/widget_choice_dialog.dart';
import '../widgets/app_toast.dart';
import '../widgets/in_app_notification_banner.dart';
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
  final ScrollController _statsScrollController = ScrollController();

  int _currentTab = 1; // 0 = Friends, 1 = Home, 2 = Profile
  String _filter = 'all'; // all, active, completed
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  TaskAnalytics? _analytics;
  bool _loadingAnalytics = false;
  String? _analyticsError;
  String _statsPeriod = '7d';

  bool _isFloatingOverlayRunning = false;
  StreamSubscription<Uri?>? _widgetClickSubscription;
  final GlobalKey<FriendsViewState> _friendsViewKey = GlobalKey<FriendsViewState>();

  StreamSubscription<InAppNotificationPayload>? _fcmNotificationSubscription;
  Timer? _friendRequestPollTimer;
  int _pendingFriendsCount = 0;
  int _lastKnownPendingRequestsCount = 0;
  InAppNotificationPayload? _activeInAppNotification;
  final Map<String, Timer> _pendingDeletions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    FloatingCatService.initialize();
    FloatingCatService.onTasksUpdated = _onExternalTasksUpdated;
    _setupInAppNotificationListener();
    _startFriendRequestPolling();
    _loadCachedTasks().then((_) {
      _checkAuthAndLoad();
    });
    _checkFloatingOverlayStatus();
    _initWidgetLaunchHandling();
  }

  void _setupInAppNotificationListener() {
    _fcmNotificationSubscription?.cancel();
    _fcmNotificationSubscription = FcmService().onInAppNotification.listen((payload) {
      if (!mounted) return;
      setState(() {
        _activeInAppNotification = payload;
        if (payload.type == 'friend_request') {
          _pendingFriendsCount++;
          _lastKnownPendingRequestsCount++;
        }
      });

      if (payload.type == 'friend_request' || payload.type == 'friend_accepted') {
        if (_currentTab == 0) {
          _friendsViewKey.currentState?.reload();
        }
      } else if (payload.type == 'task_shared') {
        _loadData();
      }
    });
  }

  void _startFriendRequestPolling() {
    _friendRequestPollTimer?.cancel();
    _friendRequestPollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted) {
        _checkPendingFriendRequests();
      }
    });
  }

  Future<void> _checkPendingFriendRequests() async {
    try {
      final isLoggedIn = await _apiService.isLoggedIn();
      if (!isLoggedIn) return;

      final data = await _apiService.fetchFriends(limit: 1);
      if (!mounted) return;

      final pending = data.pendingIncoming;
      final newCount = pending.length;

      if (newCount > _lastKnownPendingRequestsCount) {
        final latestReq = pending.isNotEmpty ? pending.first : null;
        final senderName = latestReq?.user.displayName ?? 'A user';
        setState(() {
          _pendingFriendsCount = newCount;
          _lastKnownPendingRequestsCount = newCount;
          _activeInAppNotification = InAppNotificationPayload(
            title: 'New Friend Request!',
            body: '$senderName sent you a friend request.',
            type: 'friend_request',
          );
        });
        if (_currentTab == 0) {
          _friendsViewKey.currentState?.reload();
        }
      } else {
        if (newCount != _pendingFriendsCount) {
          setState(() {
            _pendingFriendsCount = newCount;
            _lastKnownPendingRequestsCount = newCount;
          });
        }
      }
    } catch (e) {
      debugPrint('[HomeScreen] _checkPendingFriendRequests error: $e');
    }
  }

  @override
  void dispose() {
    for (final entry in _pendingDeletions.entries) {
      entry.value.cancel();
      _apiService.deleteTask(entry.key);
    }
    _pendingDeletions.clear();
    _fcmNotificationSubscription?.cancel();
    _friendRequestPollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _statsScrollController.dispose();
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
      _checkAuthAndLoad(showLoading: false);
      _checkFloatingOverlayStatus();
      _checkPendingFriendRequests();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      for (final entry in _pendingDeletions.entries) {
        entry.value.cancel();
        _apiService.deleteTask(entry.key);
      }
      _pendingDeletions.clear();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200 && !_isLoadingMore && _hasMore && !_loading) {
      _loadMoreTasks();
    }
  }

  void _onExternalTasksUpdated(String raw) async {
    if (!mounted) return;
    final loaded = await TaskSyncService.parseTasksJsonAsync(raw);
    if (loaded.isEmpty && _tasks.isNotEmpty) return;
    if (!mounted) return;

    setState(() {
      _tasks = TaskSyncService.mergeLocalTasks(loaded: loaded, current: _tasks);
      _loading = false;
    });

    TaskSyncService.syncOfflineTasksToServer(
      apiService: _apiService,
      currentTasks: _tasks,
    );
  }

  Future<void> _loadCachedTasks() async {
    final raw = await TaskSyncService.getCachedTasksJson();
    if (raw != null && raw.isNotEmpty && mounted) {
      _onExternalTasksUpdated(raw);
    }
  }

  void _syncWidget() {
    final counts = _counts;
    TaskSyncService.syncWidget(
      context,
      tasks: _tasks,
      activeCount: counts.active,
      todayTotalCount: counts.todayTotal,
      catSpeed: counts.catSpeed,
      isFloatingOverlayRunning: _isFloatingOverlayRunning,
    );
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

  Future<void> _checkFloatingOverlayStatus() async {
    final running = await FloatingCatService.isRunning();
    if (mounted && running != _isFloatingOverlayRunning) {
      setState(() => _isFloatingOverlayRunning = running);
    }
  }

  Future<void> _checkAuthAndLoad({bool showLoading = false}) async {
    final isLoggedIn = await _apiService.isLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, _, _) => const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
      return;
    }

    _loadData(showLoading: showLoading);
    _loadAnalytics();
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

      await TaskSyncService.syncOfflineTasksToServer(
        apiService: _apiService,
        currentTasks: _tasks,
        serverTasks: tasks,
      );

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
        FcmService().syncCurrentToken();
        _checkPendingFriendRequests();
        if (_currentTab == 2) {
          _loadAnalytics();
        }
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode == 401) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        }
        setState(() {
          if (_tasks.isEmpty) {
            _error = e.toString();
          }
          _loading = false;
        });
      }
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

  _TaskCounts? _cachedCounts;
  List<Task>? _lastCountTasks;

  _TaskCounts get _counts {
    if (_cachedCounts == null || !identical(_lastCountTasks, _tasks)) {
      _lastCountTasks = _tasks;
      _cachedCounts = _TaskCounts.fromTasks(_tasks);
    }
    return _cachedCounts!;
  }

  List<Task>? _cachedFiltered;
  List<Task>? _cachedTodayTasks;
  List<Task>? _cachedEarlierTasks;
  List<Task>? _lastFilteredSourceTasks;
  String? _lastFilter;
  String? _lastSearchQuery;

  void _ensureFilteredTasks() {
    if (_cachedFiltered != null &&
        identical(_lastFilteredSourceTasks, _tasks) &&
        _lastFilter == _filter &&
        _lastSearchQuery == _searchQuery) {
      return;
    }
    _lastFilteredSourceTasks = _tasks;
    _lastFilter = _filter;
    _lastSearchQuery = _searchQuery;

    final trimmedQ = _searchQuery.trim().toLowerCase();
    final hasSearch = trimmedQ.isNotEmpty;

    final filtered = <Task>[];
    final today = <Task>[];
    final earlier = <Task>[];

    for (final t in _tasks) {
      if (_filter == 'active' && t.completed) continue;
      if (_filter == 'completed' && !t.completed) continue;

      if (hasSearch) {
        final matchTitle = t.title.toLowerCase().contains(trimmedQ);
        final matchDesc = t.description.toLowerCase().contains(trimmedQ);
        final matchCat = t.category.toLowerCase().contains(trimmedQ);
        if (!matchTitle && !matchDesc && !matchCat) continue;
      }

      filtered.add(t);
      if (!t.completed || isToday(t.updatedAt ?? t.createdAt)) {
        today.add(t);
      } else {
        earlier.add(t);
      }
    }

    _cachedFiltered = filtered;
    _cachedTodayTasks = today;
    _cachedEarlierTasks = earlier;
  }

  Future<void> _toggleTask(Task task) async {
    final myId = _user?.id ?? '';
    final isMyPartCompleted = myId.isNotEmpty && task.completedBy.contains(myId);
    final willComplete = task.isShared ? !isMyPartCompleted : !task.completed;

    try {
      final updatedTask = await _apiService.updateTask(
        task.id,
        completed: willComplete,
      );
      if (mounted) {
        setState(() {
          _tasks = _tasks.map((t) => t.id == task.id ? updatedTask : t).toList();
          _cachedFiltered = null;
          _cachedTodayTasks = null;
          _cachedEarlierTasks = null;
        });
        _syncWidget();
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to update task', isError: true);
      }
    }
  }

  Future<void> _deleteTask(String id) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return;
    final deletedTask = _tasks[taskIndex];

    // Optimistically remove from state
    setState(() {
      _tasks = _tasks.where((t) => t.id != id).toList();
      _cachedFiltered = null;
      _cachedTodayTasks = null;
      _cachedEarlierTasks = null;
    });
    _syncWidget();

    // Cancel any previous timer for this ID
    _pendingDeletions[id]?.cancel();

    bool isUndone = false;

    // Start 5-second undo timer
    final timer = Timer(const Duration(seconds: 5), () async {
      _pendingDeletions.remove(id);
      if (!isUndone) {
        try {
          await _apiService.deleteTask(id);
        } catch (e) {
          debugPrint('[HomeScreen] deleteTask on server failed: $e');
        }
      }
    });
    _pendingDeletions[id] = timer;

    if (mounted) {
      AppToast.show(
        context,
        'Task deleted',
        duration: const Duration(seconds: 5),
        actionLabel: 'Undo',
        onAction: () {
          isUndone = true;
          _pendingDeletions[id]?.cancel();
          _pendingDeletions.remove(id);

          if (mounted) {
            setState(() {
              final newTasks = List<Task>.from(_tasks);
              final insertIndex = taskIndex <= newTasks.length ? taskIndex : newTasks.length;
              newTasks.insert(insertIndex, deletedTask);
              _tasks = newTasks;
              _cachedFiltered = null;
              _cachedTodayTasks = null;
              _cachedEarlierTasks = null;
            });
            _syncWidget();
            AppToast.show(context, 'Task restored');
          }
        },
      );
    }
  }

  Future<bool> _toggleFloatingCat() async {
    if (!FloatingCatService.isSupported) {
      if (mounted) {
        AppToast.show(context, 'Android only');
      }
      return false;
    }

    if (_isFloatingOverlayRunning) {
      setState(() => _isFloatingOverlayRunning = false);
      await FloatingCatService.stop();
      _syncWidget();
      if (mounted) {
        AppToast.show(context, 'Floating cat closed');
      }
      return false;
    }

    final hasPerm = await FloatingCatService.hasPermission();
    if (!hasPerm && mounted) {
      final isDark = ThemeService.instance.isDarkMode(context);
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
      return false;
    }

    if (!mounted) return false;
    setState(() => _isFloatingOverlayRunning = true);

    final isDark = ThemeService.instance.isDarkMode(context);
    final isWhite = ThemeService.instance.isCatWhite(context);
    final counts = _counts;
    final todayTasks = _tasks.where((t) => !t.completed || isToday(t.updatedAt ?? t.createdAt)).toList();
    final tasksJson = jsonEncode(todayTasks.map((t) => t.toJson()).toList());
    final speedMessage = counts.active == 0 ? 'All caught up' : '${counts.active} tasks pending';

    final started = await FloatingCatService.start(
      speedPercent: counts.catSpeed,
      speedMessage: speedMessage,
      tasksJson: tasksJson,
      isCatWhite: isWhite,
      isDark: isDark,
    );

    if (!started) {
      if (mounted) setState(() => _isFloatingOverlayRunning = false);
      return false;
    }

    _syncWidget();
    if (mounted) {
      AppToast.show(context, 'Floating cat active');
    }
    return true;
  }

  Future<void> _pinWidget({bool isCatWidget = false}) async {
    _syncWidget();
    final pinned = await WidgetService.requestPinWidget(isCatWidget: isCatWidget);
    if (!pinned && mounted) {
      AppToast.show(context, 'Long-press home screen for widget');
    }
  }

  void _showWidgetChoiceDialog() {
    showWidgetChoiceDialog(
      context,
      onSelectWidget: (isCatWidget) => _pinWidget(isCatWidget: isCatWidget),
    );
  }

  Future<void> _logout() async {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
    await _apiService.logout();
  }

  void _showSettingsModal() {
    showSettingsModal(
      context,
      user: _user,
      isFloatingOverlayRunning: _isFloatingOverlayRunning,
      onToggleFloatingCat: _toggleFloatingCat,
      onShowWidgetChoice: _showWidgetChoiceDialog,
      onLogout: _logout,
      onThemeChanged: () {
        setState(() {});
        _syncWidget();
      },
    );
  }

  void _showCreateTaskDialog() {
    showCreateTaskModal(
      context,
      onTaskCreated: (newTask) {
        if (mounted) {
          setState(() {
            _tasks = [newTask, ..._tasks];
          });
          _syncWidget();
        }
      },
    );
  }

  Future<void> _editTask(Task task, {
    required String title,
    required String description,
    required DateTime? dueDate,
    required bool hasTime,
    required String recurrence,
    required String priority,
    required String category,
  }) async {
    final updatedTask = await ApiService().updateTask(
      task.id,
      title: title,
      description: description,
      dueDate: dueDate,
      clearDueDate: dueDate == null,
      hasTime: hasTime,
      recurrence: recurrence,
      priority: priority,
      category: category,
    );
    if (mounted) {
      setState(() {
        _tasks = _tasks.map((t) => t.id == task.id ? updatedTask : t).toList();
      });
      _syncWidget();
    }
  }

  void _showTaskDetailsModal(Task task) {
    showTaskDetailsModal(
      context,
      task: task,
      currentUserId: _user?.id,
      getTasks: () => _tasks,
      onToggle: _toggleTask,
      onDelete: _deleteTask,
      onEdit: _editTask,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = palette.background;
    final cardBorder = palette.cardBorder;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    _ensureFilteredTasks();
    final filtered = _cachedFiltered!;
    final todayTasks = _cachedTodayTasks!;
    final earlierTasks = _cachedEarlierTasks!;
    final counts = _counts;
    final completionPercent = counts.todayTotal == 0
        ? 0
        : ((counts.completedToday / counts.todayTotal) * 100).round();

    return Scaffold(
      extendBody: true,
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        titleSpacing: 18,
        title: Text(
          'Todocat',
          style: TextStyle(
            fontFamily: 'Sniglet',
            color: palette.appTitle,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_user?.avatar != null && _user!.avatar!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _currentTab = 2),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBorder, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      _user!.avatar!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => CircleAvatar(
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
                        child: Text(
                          _user!.name?.isNotEmpty == true ? _user!.name![0].toUpperCase() : 'U',
                          style: TextStyle(fontFamily: 'Sniglet', fontSize: 13, color: textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
                color: palette.appTitle,
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
                          color: isDark ? Colors.white38 : palette.textMuted,
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
                            backgroundColor: palette.fabBg,
                            foregroundColor: palette.fabIcon,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CatTrailBackground(isDark: isDark),
                      ),
                    ),
                    IndexedStack(
                      index: _currentTab,
                      children: [
                        TickerMode(
                          enabled: _currentTab == 0,
                          child: FriendsView(
                            key: _friendsViewKey,
                            onFriendsUpdated: _checkPendingFriendRequests,
                          ),
                        ),
                        TickerMode(
                          enabled: _currentTab == 1,
                          child: HomeTasksView(
                            scrollController: _scrollController,
                            onRefresh: _loadData,
                            catSpeed: counts.catSpeed,
                            activeCount: counts.active,
                            completedCount: counts.completed,
                            completedTodayCount: counts.completedToday,
                            todayTotalCount: counts.todayTotal,
                            completionPercent: completionPercent,
                            totalCount: _tasks.length,
                            currentFilter: _filter,
                            onFilterChanged: (filter) => setState(() => _filter = filter),
                            searchController: _searchController,
                            searchQuery: _searchQuery,
                            onSearchChanged: (q) => setState(() => _searchQuery = q),
                            filteredTasks: filtered,
                            todayTasks: todayTasks,
                            earlierTasks: earlierTasks,
                            isLoadingMore: _isLoadingMore,
                            currentUserId: _user?.id,
                            onToggleTask: _toggleTask,
                            onTaskTap: _showTaskDetailsModal,
                            onDeleteTask: _deleteTask,
                          ),
                        ),
                        TickerMode(
                          enabled: _currentTab == 2,
                          child: ProfileView(
                            user: _user,
                            onUserUpdated: (updated) {
                              setState(() => _user = updated);
                            },
                            analytics: _analytics,
                            tasks: _tasks,
                            loadingAnalytics: _loadingAnalytics,
                            analyticsError: _analyticsError,
                            statsPeriod: _statsPeriod,
                            onPeriodChanged: (period) {
                              setState(() => _statsPeriod = period);
                              _loadAnalytics(period: period);
                            },
                            onRefresh: () => _loadAnalytics(),
                            scrollController: _statsScrollController,
                          ),
                        ),
                      ],
                    ),
                    if (_activeInAppNotification != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: InAppNotificationBanner(
                          key: ValueKey('${_activeInAppNotification!.title}_${_activeInAppNotification!.body}'),
                          title: _activeInAppNotification!.title,
                          body: _activeInAppNotification!.body,
                          type: _activeInAppNotification!.type,
                          onAction: () {
                            setState(() {
                              _activeInAppNotification = null;
                              _currentTab = 0;
                            });
                            _friendsViewKey.currentState?.reload();
                          },
                          onDismiss: () {
                            setState(() {
                              _activeInAppNotification = null;
                            });
                          },
                        ),
                      ),
                  ],
                ),
      floatingActionButton: _currentTab == 1
          ? FloatingActionButton(
              onPressed: _showCreateTaskDialog,
              backgroundColor: palette.fabBg,
              foregroundColor: palette.fabIcon,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            )
          : _currentTab == 0
              ? FloatingActionButton(
                  onPressed: () {
                    _friendsViewKey.currentState?.openAddFriendDialog();
                  },
                  backgroundColor: palette.fabBg,
                  foregroundColor: palette.fabIcon,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 28),
                )
              : null,
      bottomNavigationBar: HomeBottomBar(
        currentTab: _currentTab,
        pendingFriendsCount: _pendingFriendsCount,
        onTabSelected: (index) {
          setState(() => _currentTab = index);
          if (index == 0) {
            _checkPendingFriendRequests();
          } else if (index == 2) {
            _loadAnalytics();
          }
        },
      ),
    );
  }
}

class _TaskCounts {
  final int active;
  final int completed;
  final int completedToday;
  final int todayTotal;
  final int catSpeed;

  const _TaskCounts({
    required this.active,
    required this.completed,
    required this.completedToday,
    required this.todayTotal,
    required this.catSpeed,
  });

  factory _TaskCounts.fromTasks(List<Task> tasks) {
    int active = 0;
    int completed = 0;
    int completedToday = 0;

    for (final t in tasks) {
      if (t.completed) {
        completed++;
        if (isToday(t.updatedAt ?? t.createdAt)) {
          completedToday++;
        }
      } else {
        active++;
      }
    }

    final todayTotal = active + completedToday;
    int speed = 0;
    if (todayTotal > 0 && active > 0) {
      final totalRef = todayTotal < 5 ? 5.0 : todayTotal.toDouble();
      speed = ((active / totalRef) * 100).clamp(0, 100).round();
    }

    return _TaskCounts(
      active: active,
      completed: completed,
      completedToday: completedToday,
      todayTotal: todayTotal,
      catSpeed: speed,
    );
  }
}
