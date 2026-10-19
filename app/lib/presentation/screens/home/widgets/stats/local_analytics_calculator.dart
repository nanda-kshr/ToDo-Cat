import '../../../../../models/analytics.dart';
import '../../../../../models/task.dart';

TaskAnalytics buildLocalAnalytics(List<Task> tasks, String period) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

  DateTime? startDate;
  DateTime? endDate;

  if (period == 'today') {
    startDate = startOfToday;
    endDate = endOfToday;
  } else if (period == '7d') {
    startDate = startOfToday.subtract(const Duration(days: 6));
    endDate = endOfToday;
  } else if (period == '30d') {
    startDate = startOfToday.subtract(const Duration(days: 29));
    endDate = endOfToday;
  } else if (period == 'this_month') {
    startDate = DateTime(now.year, now.month, 1);
    endDate = endOfToday;
  }

  final filtered = tasks.where((t) {
    if (startDate != null || endDate != null) {
      final d = t.createdAt ?? t.updatedAt ?? now;
      if (startDate != null && d.isBefore(startDate)) return false;
      if (endDate != null && d.isAfter(endDate)) return false;
    }
    return true;
  }).toList();

  final total = filtered.length;
  final completed = filtered.where((t) => t.completed).length;
  final pending = total - completed;
  final completionRate = total == 0 ? 0 : ((completed / total) * 100).round();

  final byPriority = <String, PriorityStats>{
    'high': PriorityStats(total: 0, completed: 0, pending: 0),
    'medium': PriorityStats(total: 0, completed: 0, pending: 0),
    'low': PriorityStats(total: 0, completed: 0, pending: 0),
  };
  for (final t in filtered) {
    final p = t.priority.toLowerCase();
    final key = byPriority.containsKey(p) ? p : 'medium';
    final cur = byPriority[key]!;
    byPriority[key] = PriorityStats(
      total: cur.total + 1,
      completed: cur.completed + (t.completed ? 1 : 0),
      pending: cur.pending + (t.completed ? 0 : 1),
    );
  }

  final catMap = <String, CategoryStats>{};
  for (final t in filtered) {
    final cat = t.category.trim().isEmpty ? 'General' : t.category.trim();
    final cur = catMap[cat] ?? CategoryStats(category: cat, total: 0, completed: 0, pending: 0);
    catMap[cat] = CategoryStats(
      category: cat,
      total: cur.total + 1,
      completed: cur.completed + (t.completed ? 1 : 0),
      pending: cur.pending + (t.completed ? 0 : 1),
    );
  }

  int overdue = 0;
  int dueToday = 0;
  int upcoming = 0;
  int noDueDate = 0;

  for (final t in filtered) {
    if (t.dueDate == null) {
      noDueDate++;
    } else {
      final due = t.dueDate!;
      if (due.isBefore(startOfToday)) {
        if (!t.completed) overdue++;
      } else if (due.isBefore(endOfToday)) {
        if (!t.completed) dueToday++;
      } else {
        if (!t.completed) upcoming++;
      }
    }
  }

  final dateKeys = <String>[];
  for (int i = 6; i >= 0; i--) {
    final day = startOfToday.subtract(Duration(days: i));
    dateKeys.add(
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
    );
  }
  final keySet = dateKeys.toSet();

  final dayCreatedMap = <String, int>{};
  final dayCompletedMap = <String, int>{};

  for (final t in tasks) {
    if (t.createdAt != null) {
      final d = t.createdAt!;
      final k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (keySet.contains(k)) {
        dayCreatedMap[k] = (dayCreatedMap[k] ?? 0) + 1;
      }
    }
    if (t.completed) {
      final up = t.updatedAt ?? t.createdAt;
      if (up != null) {
        final k = '${up.year}-${up.month.toString().padLeft(2, '0')}-${up.day.toString().padLeft(2, '0')}';
        if (keySet.contains(k)) {
          dayCompletedMap[k] = (dayCompletedMap[k] ?? 0) + 1;
        }
      }
    }
  }

  final trendPoints = dateKeys
      .map(
        (key) => CompletionTrendPoint(
          date: key,
          completed: dayCompletedMap[key] ?? 0,
          created: dayCreatedMap[key] ?? 0,
        ),
      )
      .toList();

  return TaskAnalytics(
    summary: AnalyticsSummary(
      total: total,
      completed: completed,
      pending: pending,
      completionRate: completionRate,
    ),
    byPriority: byPriority,
    byCategory: catMap.values.toList(),
    dueStatus: DueStatus(
      overdue: overdue,
      dueToday: dueToday,
      upcoming: upcoming,
      noDueDate: noDueDate,
    ),
    completionTrend: trendPoints,
    period: period,
  );
}
