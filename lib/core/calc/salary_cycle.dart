/// Aturan salary cycle (PRD 4.4 / 8.3).
///
/// Konvensi yang dipilih dan dipakai konsisten:
/// - Hari pertama siklus = tanggal gajian (inklusif).
/// - Akhir siklus = sehari sebelum tanggal gajian berikutnya (inklusif).
/// - Tanggal gajian 29/30/31 yang tidak ada di bulan tertentu -> hari
///   terakhir bulan tersebut.
/// - Semua tanggal lokal (tanpa jam), timezone device.
library;

const List<String> shortMonthsId = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Tanggal gajian pada bulan [month]/[year] dengan aturan
/// "gunakan hari terakhir bulan bila tanggal tidak ada".
DateTime paydayInMonth(int year, int month, int paydayDay) {
  assert(paydayDay >= 1 && paydayDay <= 31);
  final firstOfMonth = DateTime(year, month, 1);
  final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
  return DateTime(year, month, paydayDay > lastDay ? lastDay : paydayDay);
}

/// Tanggal gajian terakhir pada atau sebelum [today].
DateTime paydayOnOrBefore(DateTime today, int paydayDay) {
  var candidate = paydayInMonth(today.year, today.month, paydayDay);
  if (candidate.isAfter(DateTime(today.year, today.month, today.day))) {
    final prev = DateTime(today.year, today.month - 1, 1);
    candidate = paydayInMonth(prev.year, prev.month, paydayDay);
  }
  return candidate;
}

class SalaryCycle {
  const SalaryCycle({required this.start, required this.end});

  /// Tanggal mulai siklus (inklusif), hari pertama = tanggal gajian.
  final DateTime start;

  /// Tanggal akhir siklus (inklusif), sehari sebelum gajian berikutnya.
  final DateTime end;

  DateTime get nextStart => DateTime(
        end.year,
        end.month,
        end.day + 1,
      );

  int get totalDays => end.difference(start).inDays + 1;

  /// Hari yang sudah berjalan, inklusif hari ini. 0 bila sebelum siklus.
  int elapsedDays(DateTime today) {
    final t = DateTime(today.year, today.month, today.day);
    if (t.isBefore(start)) return 0;
    if (t.isAfter(end)) return totalDays;
    return t.difference(start).inDays + 1;
  }

  /// Sisa hari termasuk hari ini. 0 bila siklus sudah berakhir.
  int remainingDays(DateTime today) {
    final t = DateTime(today.year, today.month, today.day);
    if (t.isAfter(end)) return 0;
    if (t.isBefore(start)) return totalDays;
    return end.difference(t).inDays + 1;
  }

  static SalaryCycle forToday({required DateTime today, required int paydayDay}) {
    final start = paydayOnOrBefore(today, paydayDay);
    return between(
      start: start,
      nextStart: _nextPaydayAfter(start, paydayDay),
      paydayDay: paydayDay,
    );
  }

  /// Siklus dari tanggal mulai ke tanggal gajian berikutnya.
  /// [nextStart] dipakai bila tanggal gajian berikutnya diketahui
  /// (field opsional PRD 4.4).
  static SalaryCycle between({
    required DateTime start,
    required DateTime? nextStart,
    required int paydayDay,
  }) {
    final next = nextStart ?? _nextPaydayAfter(start, paydayDay);
    return SalaryCycle(start: start, end: next.subtract(const Duration(days: 1)));
  }

  static DateTime _nextPaydayAfter(DateTime start, int paydayDay) => paydayInMonth(
        start.month == 12 ? start.year + 1 : start.year,
        start.month == 12 ? 1 : start.month + 1,
        paydayDay,
      );

  String get label => '${formatCycleDate(start)} – ${formatCycleDate(end)}';

  String get labelWithYear =>
      '${formatCycleDate(start)} ${start.year} – ${formatCycleDate(end)} ${end.year}';
}

String formatCycleDate(DateTime date) =>
    '${date.day} ${shortMonthsId[date.month - 1]}';
