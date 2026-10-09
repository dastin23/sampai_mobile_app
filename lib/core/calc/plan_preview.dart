/// Preview kalkulasi onboarding (PRD 4.6 / 8.2).
///
/// Satu sumber kebenaran: UI hanya menampilkan hasil kelas ini.
library;

class PlanPreview {
  const PlanPreview({
    required this.netIncome,
    required this.fixedBillsTotal,
    required this.savingsTarget,
  });

  final int netIncome;
  final int fixedBillsTotal;
  final int savingsTarget;

  /// Anggaran fleksibel awal; negatif ditandai via [isDeficit],
  /// tidak pernah dijadikan budget tersimpan sebagai nilai negatif.
  int get flexibleBudget => netIncome - fixedBillsTotal - savingsTarget;

  bool get isDeficit => flexibleBudget < 0;

  int get deficitAmount => isDeficit ? -flexibleBudget : 0;
}
