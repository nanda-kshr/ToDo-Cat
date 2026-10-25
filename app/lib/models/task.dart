import '../core/utils/date_utils.dart' as date_utils;
import 'friend.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final DateTime? dueDate;
  final bool hasTime;
  final String recurrence;
  final String priority;
  final String category;
  final List<FriendUser> sharedWith;
  final List<String> completedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    this.dueDate,
    this.hasTime = false,
    this.recurrence = 'none',
    this.priority = 'medium',
    this.category = 'General',
    this.sharedWith = const [],
    this.completedBy = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val)?.toLocal();
      }
      return null;
    }

    final rawSharedWith = json['sharedWith'] as List? ?? [];
    final sharedWithList = rawSharedWith.map((e) {
      if (e is Map<String, dynamic>) {
        return FriendUser.fromJson(e);
      }
      return FriendUser(id: e.toString(), email: '');
    }).toList();

    final rawCompletedBy = json['completedBy'] as List? ?? [];
    final completedByList = rawCompletedBy.map((e) {
      if (e is Map<String, dynamic>) {
        return (e['_id'] ?? e['id'] ?? '').toString();
      }
      return e.toString();
    }).toList();

    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      completed: json['completed'] ?? false,
      dueDate: parseDate(json['dueDate']),
      hasTime: json['hasTime'] as bool? ?? false,
      recurrence: json['recurrence'] as String? ?? 'none',
      priority: json['priority'] ?? 'medium',
      category: json['category'] ?? 'General',
      sharedWith: sharedWithList,
      completedBy: completedByList,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'hasTime': hasTime,
      'recurrence': recurrence,
      'priority': priority,
      'category': category,
      if (sharedWith.isNotEmpty)
        'sharedWith': sharedWith.map((f) => f.id).toList(),
      if (completedBy.isNotEmpty) 'completedBy': completedBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? dueDate,
    bool? hasTime,
    String? recurrence,
    String? priority,
    String? category,
    List<FriendUser>? sharedWith,
    List<String>? completedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      hasTime: hasTime ?? this.hasTime,
      recurrence: recurrence ?? this.recurrence,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      sharedWith: sharedWith ?? this.sharedWith,
      completedBy: completedBy ?? this.completedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isShared => sharedWith.isNotEmpty;
  bool isCompletedBy(String userId) => completedBy.contains(userId);
  int get totalParticipants => 1 + sharedWith.length;
  int get completedParticipantsCount => completedBy.length;
  String get dualProgressText => '$completedParticipantsCount/$totalParticipants completed';

  bool get isRecurring => recurrence.isNotEmpty && recurrence != 'none';
  bool get isToday => date_utils.isToday(dueDate);

  bool get isOverdue {
    if (dueDate == null || completed) return false;
    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return dueDate!.isBefore(startOfToday);
  }

  bool get isUpcoming {
    if (dueDate == null || completed) return false;
    final endOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      23,
      59,
      59,
    );
    return dueDate!.isAfter(endOfToday);
  }
}
