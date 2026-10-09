import 'salary_cycle.dart';

/// Satu-satunya sumber kebenaran kalkulasi finansial (PRD §8).
///
/// UI hanya menampilkan hasil kelas ini. Semua pembagian memiliki guard
/// nol dan semua nilai "aman dibelanjakan" tidak pernah negatif.
class FinancialSummary {
  const FinancialSummary({
    required this.availableForCycle,
    required this.reservedUnpaidBills,
    required this.unfundedSavingsTarget,
    required this.safetyBuffer,
    required this.discretionarySpent,
    required this.elapsedDays,
    required this.remainingDays,
    required this.totalDays,
    required this.isEstimate,
  });

  /// Metode dasar MVP: pendapatan bersih (PRD 8.2).
  factory FinancialSummary.compute({
    required int netIncome,
    required int fixedBillsUnpaid,
    required int savingsTargetUnfunded,
    required int safetyBuffer,
    required int discretionarySpent,
    required SalaryCycle cycle,
    required DateTime today,
    bool isEstimate = false,
  }) {
    final elapsed = cycle.elapsedDays(today);
    final total = cycle.totalDays;
    return FinancialSummary(
      availableForCycle: netIncome,
      reservedUnpaidBills: fixedBillsUnpaid,
      unfundedSavingsTarget: savingsTargetUnfunded,
      safetyBuffer: safetyBuffer,
      discretionarySpent: discretionarySpent,
      elapsedDays: elapsed,
      remainingDays: cycle.remainingDays(today),
      totalDays: total,
      isEstimate: isEstimate,
    );
  }

  final int availableForCycle;
  final int reservedUnpaidBills;
  final int unfundedSavingsTarget;
  final int safetyBuffer;
  final int discretionarySpent;
  final int elapsedDays;
  final int remainingDays;
  final int totalDays;
  final bool isEstimate;

  /// Anggaran fleksibel awal; boleh negatif untuk menandakan defisit
  /// rencana — jangan pernah dijadikan budget tersimpan (PRD 8.2).
  int get discretionaryBudget =>
      availableForCycle -
      reservedUnpaidBills -
      unfundedSavingsTarget -
      safetyBuffer;

  bool get hasPlanDeficit => discretionaryBudget < 0;

  /// Sisa uang fleksibel (PRD 8.3), tidak pernah negatif.
  int get remainingFlexible {
    final value = availableForCycle -
        reservedUnpaidBills -
        unfundedSavingsTarget -
        safetyBuffer -
        discretionarySpent;
    return value < 0 ? 0 : value;
  }

  /// Safe-to-Spend per hari. 0 bila siklus berakhir (hindari bagi nol).
  int get safeToSpendPerDay =>
      remainingDays <= 0 ? 0 : remainingFlexible ~/ remainingDays;

  bool get cycleEndsToday => remainingDays <= 0;

  /// Progres waktu siklus; null bila total hari 0.
  double? get timeProgress =>
      totalDays <= 0 ? null : elapsedDays / totalDays;

  /// Progres anggaran fleksibel terpakai; null bila anggaran <= 0.
  double? get spendingProgress => discretionaryBudget <= 0
      ? null
      : discretionarySpent / discretionaryBudget;

  /// Money Velocity = spendingProgress / timeProgress (PRD 8.4).
  double? get moneyVelocity {
    final time = timeProgress;
    final spend = spendingProgress;
    if (time == null || time == 0 || spend == null) return null;
    return spend / time;
  }

  bool get isSpendingTooFast =>
      moneyVelocity != null && moneyVelocity! > 1;

  bool get isCritical => remainingFlexible <= 0;

  /// Alasan Money Velocity tidak tersedia, sesuai PRD 8.4.
  String? get velocityUnavailableReason {
    final time = timeProgress;
    if (time == null || time == 0) {
      return 'Mulai dihitung setelah siklus berjalan.';
    }
    if (discretionaryBudget <= 0) {
      return 'Atur anggaran fleksibel untuk melihat Money Velocity.';
    }
    return null;
  }

  double get timeProgressPercent => (timeProgress ?? 0).clamp(0, 1);
  double get spendingProgressPercent => (spendingProgress ?? 0).clamp(0, 1);
}

/// Format rasio gaya Indonesia: 1.625 -> "1,63×".
String formatRatio(double value) =>
    '${value.toStringAsFixed(2).replaceAll('.', ',')}×';

/// Format persentase gaya Indonesia: 0.4 -> "40%".
String formatPercent(double ratio) => '${(ratio * 100).round()}%';
