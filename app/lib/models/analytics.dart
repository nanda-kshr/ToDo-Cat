class TaskAnalytics {
  final AnalyticsSummary summary;
  final Map<String, PriorityStats> byPriority;
  final List<CategoryStats> byCategory;
  final DueStatus dueStatus;
  final List<CompletionTrendPoint> completionTrend;
  final String? period;

  TaskAnalytics({
    required this.summary,
    required this.byPriority,
    required this.byCategory,
    required this.dueStatus,
    required this.completionTrend,
    this.period,
  });

  factory TaskAnalytics.fromJson(Map<String, dynamic> json) {
    final filters = json['filters'] as Map<String, dynamic>?;
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final priorityJson = json['byPriority'] as Map<String, dynamic>? ?? {};
    final categoryList = json['byCategory'] as List<dynamic>? ?? [];
    final dueJson = json['dueStatus'] as Map<String, dynamic>? ?? {};
    final trendList = json['completionTrend'] as List<dynamic>? ?? [];

    final priorities = <String, PriorityStats>{};
    for (final key in ['high', 'medium', 'low']) {
      if (priorityJson.containsKey(key)) {
        priorities[key] = PriorityStats.fromJson(
          priorityJson[key] as Map<String, dynamic>? ?? {},
        );
      } else {
        priorities[key] = PriorityStats(total: 0, completed: 0, pending: 0);
      }
    }

    return TaskAnalytics(
      summary: AnalyticsSummary.fromJson(summaryJson),
      byPriority: priorities,
      byCategory: categoryList
          .map((e) => CategoryStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      dueStatus: DueStatus.fromJson(dueJson),
      completionTrend: trendList
          .map((e) => CompletionTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      period: filters?['period'] as String?,
    );
  }
}

class AnalyticsSummary {
  final int total;
  final int completed;
  final int pending;
  final int completionRate;

  AnalyticsSummary({
    required this.total,
    required this.completed,
    required this.pending,
    required this.completionRate,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toInt() ?? 0,
    );
  }
}

class PriorityStats {
  final int total;
  final int completed;
  final int pending;

  PriorityStats({
    required this.total,
    required this.completed,
    required this.pending,
  });

  factory PriorityStats.fromJson(Map<String, dynamic> json) {
    return PriorityStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
    );
  }
}

class CategoryStats {
  final String category;
  final int total;
  final int completed;
  final int pending;

  CategoryStats({
    required this.category,
    required this.total,
    required this.completed,
    required this.pending,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      category: json['category'] as String? ?? 'General',
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
    );
  }
}

class DueStatus {
  final int overdue;
  final int dueToday;
  final int upcoming;
  final int noDueDate;

  DueStatus({
    required this.overdue,
    required this.dueToday,
    required this.upcoming,
    required this.noDueDate,
  });

  factory DueStatus.fromJson(Map<String, dynamic> json) {
    return DueStatus(
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      dueToday: (json['dueToday'] as num?)?.toInt() ?? 0,
      upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
      noDueDate: (json['noDueDate'] as num?)?.toInt() ?? 0,
    );
  }
}

class CompletionTrendPoint {
  final String date;
  final int completed;
  final int created;

  CompletionTrendPoint({
    required this.date,
    required this.completed,
    required this.created,
  });

  factory CompletionTrendPoint.fromJson(Map<String, dynamic> json) {
    return CompletionTrendPoint(
      date: json['date'] as String? ?? '',
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      created: (json['created'] as num?)?.toInt() ?? 0,
    );
  }
}
