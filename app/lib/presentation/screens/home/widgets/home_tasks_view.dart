import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/task.dart';
import 'home_search_filter_bar.dart';
import 'home_status_banner.dart';
import 'task_card_tile.dart';

class HomeTasksView extends StatefulWidget {
  final ScrollController scrollController;
  final RefreshCallback onRefresh;
  final int catSpeed;
  final int activeCount;
  final int completedCount;
  final int completedTodayCount;
  final int todayTotalCount;
  final int completionPercent;
  final int totalCount;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<Task> filteredTasks;
  final List<Task> todayTasks;
  final List<Task> earlierTasks;
  final bool isLoadingMore;
  final String? currentUserId;
  final ValueChanged<Task> onToggleTask;
  final ValueChanged<Task> onTaskTap;
  final ValueChanged<String> onDeleteTask;

  const HomeTasksView({
    super.key,
    required this.scrollController,
    required this.onRefresh,
    required this.catSpeed,
    required this.activeCount,
    required this.completedCount,
    required this.completedTodayCount,
    required this.todayTotalCount,
    required this.completionPercent,
    required this.totalCount,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.filteredTasks,
    required this.todayTasks,
    required this.earlierTasks,
    required this.isLoadingMore,
    this.currentUserId,
    required this.onToggleTask,
    required this.onTaskTap,
    required this.onDeleteTask,
  });

  @override
  State<HomeTasksView> createState() => _HomeTasksViewState();
}

class _HomeTasksViewState extends State<HomeTasksView> {
  bool _isEarlierExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scrollController = widget.scrollController;
    final onRefresh = widget.onRefresh;
    final catSpeed = widget.catSpeed;
    final activeCount = widget.activeCount;
    final completedCount = widget.completedCount;
    final completedTodayCount = widget.completedTodayCount;
    final todayTotalCount = widget.todayTotalCount;
    final completionPercent = widget.completionPercent;
    final totalCount = widget.totalCount;
    final currentFilter = widget.currentFilter;
    final onFilterChanged = widget.onFilterChanged;
    final searchController = widget.searchController;
    final searchQuery = widget.searchQuery;
    final onSearchChanged = widget.onSearchChanged;
    final filteredTasks = widget.filteredTasks;
    final todayTasks = widget.todayTasks;
    final earlierTasks = widget.earlierTasks;
    final isLoadingMore = widget.isLoadingMore;
    final onToggleTask = widget.onToggleTask;
    final onTaskTap = widget.onTaskTap;
    final onDeleteTask = widget.onDeleteTask;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.of(context);
    final cardBg = palette.surface;
    final cardBorder = palette.cardBorder;
    final textSecondary = palette.textSecondary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: palette.iconPrimary,
      backgroundColor: cardBg,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header Controls (Status Banner, Filter Tabs, Search Bar)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeStatusBanner(
                    catSpeed: catSpeed,
                    activeCount: activeCount,
                    completedTodayCount: completedTodayCount,
                    todayTotalCount: todayTotalCount,
                    completionPercent: completionPercent,
                  ),
                  const SizedBox(height: 16),
                  HomeSearchFilterBar(
                    currentFilter: currentFilter,
                    totalCount: totalCount,
                    activeCount: activeCount,
                    completedCount: completedCount,
                    onFilterChanged: onFilterChanged,
                    searchController: searchController,
                    searchQuery: searchQuery,
                    onSearchChanged: onSearchChanged,
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // Task List or Empty State
          if (filteredTasks.isEmpty)
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
                        searchQuery.isNotEmpty
                            ? 'No tasks found for "$searchQuery"'
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFF3F4F6),
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

            // 1. Today's Tasks List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: todayTasks.length,
                itemBuilder: (context, index) {
                  final task = todayTasks[index];
                  return TaskCardTile(
                    task: task,
                    currentUserId: widget.currentUserId,
                    onToggle: () => onToggleTask(task),
                    onTap: () => onTaskTap(task),
                    onDismissed: () => onDeleteTask(task.id),
                  );
                },
              ),
            ),

            // 2. Completed Till Yesterday Section Header (Expandable Button)
            if (earlierTasks.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: InkWell(
                    onTap: () => setState(() => _isEarlierExpanded = !_isEarlierExpanded),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 16,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Completed Earlier',
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF262626)
                                  : const Color(0xFFE4E4E7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${earlierTasks.length}',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _isEarlierExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Completed Till Yesterday Tasks List (Visible when expanded)
              if (_isEarlierExpanded)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: earlierTasks.length,
                    itemBuilder: (context, index) {
                      final task = earlierTasks[index];
                      return TaskCardTile(
                        task: task,
                        currentUserId: widget.currentUserId,
                        onToggle: () => onToggleTask(task),
                        onTap: () => onTaskTap(task),
                        onDismissed: () => onDeleteTask(task.id),
                      );
                    },
                  ),
                ),
            ],
          ],

          // Footer with loading indicator and bottom clearance
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 110),
              child: isLoadingMore
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
