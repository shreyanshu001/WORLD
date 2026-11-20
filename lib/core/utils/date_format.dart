const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// A short day for lists: "today", "yesterday", "20 Nov" or "20 Nov 2025".
String formatDay(DateTime date, {DateTime? now}) {
  final local = date.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  final difference = todayDay.difference(day).inDays;
  if (difference == 0) return 'today';
  if (difference == 1) return 'yesterday';
  final short = '${local.day} ${_months[local.month - 1]}';
  return local.year == today.year ? short : '$short ${local.year}';
}
