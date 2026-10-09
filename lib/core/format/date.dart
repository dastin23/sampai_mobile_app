import '../calc/salary_cycle.dart';

String formatShortDate(DateTime date) =>
    '${date.day} ${shortMonthsId[date.month - 1]} ${date.year}';

String formatDayMonth(DateTime date) =>
    '${date.day} ${shortMonthsId[date.month - 1]}';

/// "Hari ini" / "Kemarin" / "8 Okt 2026".
String formatRelativeDay(DateTime date, DateTime today) {
  final d = DateTime(date.year, date.month, date.day);
  final t = DateTime(today.year, today.month, today.day);
  final diff = t.difference(d).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  return formatShortDate(d);
}

/// "8 Okt 2026, 14:30".
String formatDateTime(DateTime date) {
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${formatShortDate(date)}, $hh:$mm';
}
