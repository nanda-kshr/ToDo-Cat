import 'package:flutter/material.dart';
import '../../../../models/analytics.dart';
import '../../../../models/task.dart';
import 'stats/local_analytics_calculator.dart';
import 'stats/stats_category_card.dart';
import 'stats/stats_completion_card.dart';
import 'stats/stats_due_status_card.dart';
import 'stats/stats_period_selector.dart';
import 'stats/stats_priority_card.dart';
import 'stats/stats_trend_card.dart';

class StatsView extends StatefulWidget {
  final TaskAnalytics? analytics;
  final List<Task> tasks;
  final bool loadingAnalytics;
  final String? analyticsError;
  final String statsPeriod;
  final Function(String period) onPeriodChanged;
  final VoidCallback onRefresh;
  final ScrollController scrollController;

  const StatsView({
    super.key,
    required this.analytics,
    required this.tasks,
    required this.loadingAnalytics,
    required this.analyticsError,
    required this.statsPeriod,
    required this.onPeriodChanged,
    required this.onRefresh,
    required this.scrollController,
  });

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  TaskAnalytics? _cachedLocalAnalytics;
  List<Task>? _lastTasks;
  String? _lastPeriod;

  TaskAnalytics _getEffectiveAnalytics() {
    if (widget.analytics != null) return widget.analytics!;
    if (_cachedLocalAnalytics == null ||
        !identical(_lastTasks, widget.tasks) ||
        _lastPeriod != widget.statsPeriod) {
      _lastTasks = widget.tasks;
      _lastPeriod = widget.statsPeriod;
      _cachedLocalAnalytics = buildLocalAnalytics(widget.tasks, widget.statsPeriod);
    }
    return _cachedLocalAnalytics!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA3A3A3) : const Color(0xFF9CA3AF);

    if (widget.loadingAnalytics && widget.analytics == null && widget.tasks.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white : const Color(0xFF4B5563),
        ),
      );
    }

    if (widget.analyticsError != null && widget.analytics == null && widget.tasks.isEmpty) {
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
                widget.analyticsError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  color: textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onRefresh,
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

    final data = _getEffectiveAnalytics();

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.loadingAnalytics)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: widget.onRefresh,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Period Filters Row
          StatsPeriodSelector(
            selectedPeriod: widget.statsPeriod,
            onPeriodChanged: widget.onPeriodChanged,
          ),
          const SizedBox(height: 14),

          // Hero Metric Card & 3 Metric Cards
          StatsCompletionCard(summary: data.summary),
          const SizedBox(height: 16),

          // Due Status Breakdown
          StatsDueStatusCard(due: data.dueStatus),
          const SizedBox(height: 16),

          // Priority Breakdown
          StatsPriorityCard(byPriority: data.byPriority),

          // Category Breakdown
          if (data.byCategory.isNotEmpty) ...[
            const SizedBox(height: 16),
            StatsCategoryCard(categories: data.byCategory),
          ],

          // Completion Trend
          if (data.completionTrend.isNotEmpty) ...[
            const SizedBox(height: 16),
            StatsTrendCard(trends: data.completionTrend),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
