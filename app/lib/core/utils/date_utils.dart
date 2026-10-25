String formatTime(DateTime? date) {
  if (date == null) return '';
  final hour = date.hour;
  final minute = date.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final displayMinute = minute.toString().padLeft(2, '0');
  return '$displayHour:$displayMinute $period';
}

String formatDueDate(DateTime? date, {bool hasTime = false}) {
  if (date == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diffDays = target.difference(today).inDays;
  String datePart;
  if (diffDays == 0) {
    datePart = 'Today';
  } else if (diffDays == 1) {
    datePart = 'Tomorrow';
  } else if (diffDays == -1) {
    datePart = 'Yesterday';
  } else {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    datePart = '${months[date.month - 1]} ${date.day}';
  }

  if (hasTime) {
    return '$datePart, ${formatTime(date)}';
  }
  return datePart;
}

bool isToday(DateTime? date) {
  if (date == null) return false;
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
