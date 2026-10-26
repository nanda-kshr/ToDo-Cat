import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/analytics.dart';
import '../../../../models/task.dart';
import '../../../../models/user.dart';
import '../../../../services/api_service.dart';
import '../../../widgets/app_toast.dart';
import 'stats/local_analytics_calculator.dart';
import 'stats/stats_category_card.dart';
import 'stats/stats_completion_card.dart';
import 'stats/stats_due_status_card.dart';
import 'stats/stats_period_selector.dart';
import 'stats/stats_priority_card.dart';
import 'stats/stats_trend_card.dart';

class ProfileView extends StatefulWidget {
  final User? user;
  final ValueChanged<User>? onUserUpdated;
  final TaskAnalytics? analytics;
  final List<Task> tasks;
  final bool loadingAnalytics;
  final String? analyticsError;
  final String statsPeriod;
  final Function(String period) onPeriodChanged;
  final VoidCallback onRefresh;
  final ScrollController scrollController;

  const ProfileView({
    super.key,
    required this.user,
    this.onUserUpdated,
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
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ApiService _apiService = ApiService();
  bool _isPublic = false;
  bool _updatingPrivacy = false;

  TaskAnalytics? _cachedLocalAnalytics;
  List<Task>? _lastTasks;
  String? _lastPeriod;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.user?.isProfilePublic ?? false;
  }

  @override
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_updatingPrivacy &&
        widget.user != null &&
        widget.user?.isProfilePublic != oldWidget.user?.isProfilePublic) {
      setState(() {
        _isPublic = widget.user!.isProfilePublic;
      });
    }
  }

  Future<void> _togglePrivacy(bool value) async {
    setState(() {
      _isPublic = value;
      _updatingPrivacy = true;
    });

    try {
      final updatedUser = await _apiService.updateProfile(isProfilePublic: value);
      widget.onUserUpdated?.call(updatedUser);
      if (mounted) {
        setState(() {
          _isPublic = updatedUser.isProfilePublic;
          _updatingPrivacy = false;
        });
        AppToast.show(
          context,
          value ? 'Stats are public' : 'Stats are private',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPublic = !value; // revert
          _updatingPrivacy = false;
        });
        AppToast.show(
          context,
          'Failed to update privacy',
          isError: true,
        );
      }
    }
  }

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
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = palette.surface;
    final cardBorder = palette.cardBorder;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    final user = widget.user;
    final displayName = (user?.name != null && user!.name!.trim().isNotEmpty)
        ? user.name!
        : (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'User');
    final email = user?.email ?? '';

    final data = _getEffectiveAnalytics();

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: palette.appTitle,
      backgroundColor: cardBg,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
                      backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                          ? NetworkImage(user.avatar!)
                          : null,
                      onBackgroundImageError: user?.avatar != null && user!.avatar!.isNotEmpty
                          ? (exception, stackTrace) {}
                          : null,
                      child: user?.avatar == null || user!.avatar!.isEmpty
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFF262626)),
                const SizedBox(height: 12),

                // Privacy Switch (Public / Private)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      _isPublic ? Icons.public : Icons.lock_outline,
                      size: 20,
                      color: _isPublic ? palette.subtleGreen : palette.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Stats Visibility',
                                style: TextStyle(
                                  fontFamily: 'Sniglet',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _isPublic
                                      ? palette.subtleGreenBg
                                      : (isDark ? const Color(0xFF262626) : const Color(0xFFF3EFE8)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isPublic
                                        ? palette.subtleGreenBorder
                                        : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E0D5)),
                                  ),
                                ),
                                child: Text(
                                  _isPublic ? 'Public' : 'Private',
                                  style: TextStyle(
                                    fontFamily: 'Sniglet',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _isPublic ? palette.subtleGreen : textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isPublic
                                ? 'Friends can view your stats in the friends tab.'
                                : 'Only you can see your stats (default).',
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_updatingPrivacy)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Switch.adaptive(
                        value: _isPublic,
                        activeThumbColor: palette.subtleGreen,
                        activeTrackColor: palette.subtleGreen.withValues(alpha: 0.35),
                        onChanged: _togglePrivacy,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Productivity Stats Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productivity Stats',
                style: TextStyle(
                  fontFamily: 'Sniglet',
                  fontSize: 18,
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
                          color: palette.appTitle,
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
          const SizedBox(height: 12),

          // Period Filters Row
          StatsPeriodSelector(
            selectedPeriod: widget.statsPeriod,
            onPeriodChanged: widget.onPeriodChanged,
          ),
          const SizedBox(height: 14),

          // Hero Metric Card
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
        ],
      ),
    ),
  );
}
}
