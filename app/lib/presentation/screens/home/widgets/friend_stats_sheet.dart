import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/analytics.dart';
import '../../../../models/friend.dart';
import '../../../../services/api_service.dart';
import 'stats/stats_category_card.dart';
import 'stats/stats_completion_card.dart';
import 'stats/stats_due_status_card.dart';
import 'stats/stats_period_selector.dart';
import 'stats/stats_priority_card.dart';
import 'stats/stats_trend_card.dart';

void showFriendStatsSheet(BuildContext context, {required FriendUser friend}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FriendStatsSheet(friend: friend),
  );
}

class FriendStatsSheet extends StatefulWidget {
  final FriendUser friend;

  const FriendStatsSheet({super.key, required this.friend});

  @override
  State<FriendStatsSheet> createState() => _FriendStatsSheetState();
}

class _FriendStatsSheetState extends State<FriendStatsSheet> {
  final ApiService _apiService = ApiService();
  String _period = '7d';
  bool _loading = true;
  String? _error;
  TaskAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats({String? period}) async {
    final targetPeriod = period ?? _period;
    setState(() {
      _loading = true;
      _error = null;
      if (period != null) _period = period;
    });

    try {
      final data = await _apiService.fetchAnalytics(
        friendId: widget.friend.id,
        period: targetPeriod,
      );
      if (mounted) {
        setState(() {
          _analytics = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Unable to load stats. Please check your connection.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141414) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Grab handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                      backgroundImage: widget.friend.avatar != null && widget.friend.avatar!.isNotEmpty
                          ? NetworkImage(widget.friend.avatar!)
                          : null,
                      child: widget.friend.avatar == null || widget.friend.avatar!.isEmpty
                          ? Text(
                              widget.friend.displayName.isNotEmpty
                                  ? widget.friend.displayName[0].toUpperCase()
                                  : 'F',
                              style: TextStyle(
                                fontFamily: 'Sniglet',
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.friend.displayName,
                                  style: TextStyle(
                                    fontFamily: 'Sniglet',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.public, size: 14, color: palette.subtleGreen),
                            ],
                          ),
                          Text(
                            "Public Productivity Stats",
                            style: TextStyle(
                              fontFamily: 'Sniglet',
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF262626)),

              // Content
              Expanded(
                child: _loading
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
                                    Icons.lock_outline,
                                    size: 44,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Sniglet',
                                      fontSize: 13,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => _loadStats(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _analytics == null
                            ? const SizedBox.shrink()
                            : SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    StatsPeriodSelector(
                                      selectedPeriod: _period,
                                      onPeriodChanged: (p) => _loadStats(period: p),
                                    ),
                                    const SizedBox(height: 14),
                                    StatsCompletionCard(summary: _analytics!.summary),
                                    const SizedBox(height: 16),
                                    StatsDueStatusCard(due: _analytics!.dueStatus),
                                    const SizedBox(height: 16),
                                    StatsPriorityCard(byPriority: _analytics!.byPriority),
                                    if (_analytics!.byCategory.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      StatsCategoryCard(categories: _analytics!.byCategory),
                                    ],
                                    if (_analytics!.completionTrend.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      StatsTrendCard(trends: _analytics!.completionTrend),
                                    ],
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
