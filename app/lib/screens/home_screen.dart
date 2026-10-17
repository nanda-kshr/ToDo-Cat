import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';
import '../services/floating_cat_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/cat_animation.dart';
import '../widgets/draggable_floating_cat.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  User? _user;
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  String _filter = 'all'; // all, today, upcoming, completed
  String _priorityFilter = 'all'; // all, high, medium, low
  bool _isFloatingOverlayRunning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkFloatingOverlayStatus();
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
    WidgetService.updateWidget(
      pendingCount: _activeCount,
      totalCount: _tasks.length,
      speedPercent: _catSpeed,
      speedMessage: _catSpeedMessage,
    );
    if (_isFloatingOverlayRunning) {
      FloatingCatService.update(
        speedPercent: _catSpeed,
        speedMessage: _catSpeedMessage,
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
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Enable Floating Cat', style: TextStyle(color: Colors.white)),
          content: const Text(
            'To float the animated cat over your home screen and other apps, Android requires the "Display over other apps" permission.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
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

    await FloatingCatService.start(
      speedPercent: _catSpeed,
      speedMessage: _catSpeedMessage,
    );
    if (mounted) {
      setState(() => _isFloatingOverlayRunning = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Floating Cat active! Drag it anywhere on screen.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pinWidget() async {
    _syncWidget();
    final messenger = ScaffoldMessenger.of(context);
    final pinned = await WidgetService.requestPinWidget();
    if (!pinned && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'To add the Cat widget, long-press on your phone home screen and tap Widgets > TodoCat.',
          ),
          backgroundColor: Color(0xFF171717),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Task Title (required)',
                        hintStyle: const TextStyle(color: Color(0xFF737373)),
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Description (optional)',
                        hintStyle: const TextStyle(color: Color(0xFF737373)),
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF262626)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedDate != null
                                        ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'
                                        : 'Due Date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: selectedDate != null ? Colors.white : const Color(0xFF737373),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: categoryController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Category',
                              hintStyle: const TextStyle(color: Color(0xFF737373)),
                              filled: true,
                              fillColor: const Color(0xFF0A0A0A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF262626)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Priority selector
                    Row(
                      children: ['low', 'medium', 'high'].map((p) {
                        final isSel = selectedPriority == p;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Center(
                                child: Text(
                                  p.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : Colors.white60,
                                  ),
                                ),
                              ),
                              selected: isSel,
                              selectedColor: p == 'high'
                                  ? const Color(0xFFF43F5E)
                                  : p == 'medium'
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981),
                              backgroundColor: const Color(0xFF0A0A0A),
                              onSelected: (_) {
                                setModalState(() {
                                  selectedPriority = p;
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Create Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0A0A0A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        style: TextStyle(fontWeight: FontWeight.bold),
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
    return ((_activeCount / 5.0) * 100).clamp(0, 100).round();
  }

  String get _catSpeedMessage {
    if (_tasks.isEmpty) return 'No tasks yet • Cat is resting';
    if (_activeCount == 0) return 'All tasks completed! Cat is sleeping';
    if (_catSpeed >= 100) return '$_activeCount tasks pending • Maximum speed!';
    if (_catSpeed >= 60) return '$_activeCount tasks pending • Cat is running';
    return '$_activeCount task pending • Cat is alert';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Row(
          children: [
            const AppLogo(size: 32, borderRadius: 8),
            const SizedBox(width: 10),
            const Text(
              'TodoCat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_catSpeedMessage),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF171717),
                  ),
                );
              },
              child: CatAnimation(
                speedPercent: _catSpeed,
                size: 32,
                idleRunWhenSleeping: true,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFloatingOverlayRunning
                  ? Icons.picture_in_picture
                  : Icons.picture_in_picture_alt,
              color: _isFloatingOverlayRunning
                  ? const Color(0xFF818CF8)
                  : Colors.white70,
              size: 20,
            ),
            tooltip: _isFloatingOverlayRunning
                ? 'Floating Cat is active (tap to close)'
                : 'Float Cat Over Apps (System Overlay)',
            onPressed: _toggleFloatingCat,
          ),
          IconButton(
            icon: const Icon(Icons.widgets_outlined, color: Colors.white70, size: 20),
            tooltip: 'Add Cat Widget to Home Screen',
            onPressed: _pinWidget,
          ),
          if (_user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  _user!.name ?? _user!.email.split('@').first,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            color: Colors.white,
            backgroundColor: const Color(0xFF171717),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: Colors.white38),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
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
                      // Cat Speed Banner Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CatAnimation(
                                  speedPercent: _catSpeed,
                                  size: 52,
                                  idleRunWhenSleeping: true,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                _catSpeed == 0 ? Icons.nightlight_round : Icons.flash_on,
                                                size: 16,
                                                color: _catSpeed == 0
                                                    ? const Color(0xFF818CF8)
                                                    : _catSpeed >= 100
                                                        ? const Color(0xFFF43F5E)
                                                        : const Color(0xFFF59E0B),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '$_catSpeed% Speed',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: _catSpeed == 0
                                                      ? const Color(0xFF818CF8)
                                                      : _catSpeed >= 100
                                                          ? const Color(0xFFF43F5E)
                                                          : const Color(0xFFF59E0B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '$_completedCount/${_tasks.length} done',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF737373),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _catSpeedMessage,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _catSpeed / 100.0,
                                minHeight: 6,
                                backgroundColor: const Color(0xFF262626),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _catSpeed == 0
                                      ? const Color(0xFF6366F1)
                                      : _catSpeed >= 100
                                          ? const Color(0xFFF43F5E)
                                          : const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: _toggleFloatingCat,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isFloatingOverlayRunning
                                          ? const Color(0xFF312E81)
                                          : const Color(0xFF262626),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _isFloatingOverlayRunning
                                            ? const Color(0xFF6366F1)
                                            : const Color(0xFF383838),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isFloatingOverlayRunning
                                              ? Icons.picture_in_picture
                                              : Icons.picture_in_picture_alt,
                                          size: 14,
                                          color: _isFloatingOverlayRunning
                                              ? const Color(0xFFA5B4FC)
                                              : Colors.white70,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isFloatingOverlayRunning
                                              ? 'Floating Cat (ON)'
                                              : 'Float Over Apps',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _isFloatingOverlayRunning
                                                ? const Color(0xFFA5B4FC)
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _pinWidget,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF262626),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF383838),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.widgets_outlined,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Home Widget',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
          if (!_loading && _error == null)
            DraggableFloatingCat(
              speedPercent: _catSpeed,
              speedMessage: _catSpeedMessage,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSel = _filter == id;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          color: isSel ? Colors.white : Colors.white60,
        ),
      ),
      selected: isSel,
      selectedColor: const Color(0xFF262626),
      backgroundColor: const Color(0xFF171717),
      side: BorderSide(
        color: isSel ? const Color(0xFF525252) : const Color(0xFF262626),
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
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          color: isSel ? Colors.white : Colors.white60,
        ),
      ),
      selected: isSel,
      selectedColor: const Color(0xFF262626),
      backgroundColor: const Color(0xFF171717),
      side: BorderSide(
        color: isSel ? const Color(0xFF525252) : const Color(0xFF262626),
      ),
      onSelected: (_) {
        setState(() {
          _priorityFilter = id;
        });
      },
    );
  }

  Widget _taskTile(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: task.completed ? const Color(0xFF0F0F0F) : const Color(0xFF171717),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.completed ? const Color(0xFF1C1C1C) : const Color(0xFF262626),
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
                  color: task.completed ? const Color(0xFF10B981) : const Color(0xFF525252),
                ),
              ),
              child: task.completed
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
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
                          color: task.completed ? const Color(0xFF737373) : Colors.white,
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
                      color: task.completed ? const Color(0xFF525252) : const Color(0xFFA3A3A3),
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
                          color: const Color(0xFF262626),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.category,
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
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
