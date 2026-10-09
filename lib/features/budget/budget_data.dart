import '../../core/calc/cycle_transactions.dart';
import '../../core/calc/financial_summary.dart';
import '../../core/calc/salary_cycle.dart';
import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';

/// ViewModel layar Budget (PRD 7.2) — seluruh nilai berasal dari
/// [FinancialSummary] dan perhitungan siklus; UI tidak menghitung sendiri.
class BudgetOverview {
  const BudgetOverview({
    required this.plan,
    required this.cycle,
    required this.summary,
    required this.usages,
    required this.cycleTransactions,
  });

  factory BudgetOverview.fromState({
    required AppState state,
    required DateTime today,
  }) {
    final plan = state.plan;
    if (plan == null) {
      throw StateError('BudgetOverview.fromState butuh plan');
    }
    return BudgetOverview.fromInputs(
      plan: plan,
      transactions: state.transactions,
      budgets: state.budgets,
      today: today,
    );
  }

  factory BudgetOverview.fromInputs({
    required Plan plan,
    required List<ExpenseTransaction> transactions,
    required List<BudgetCategory> budgets,
    required DateTime today,
  }) {
    final cycle = plan.cycleFor(today);
    final cycleTx = flexibleTransactionsIn(transactions, cycle);
    final spent = cycleTx.fold(0, (sum, t) => sum + t.amount);
    final summary = FinancialSummary.compute(
      netIncome: plan.netIncome,
      fixedBillsUnpaid: plan.activeBillsTotal,
      savingsTargetUnfunded: plan.savingsTarget,
      safetyBuffer: plan.safetyBuffer,
      discretionarySpent: spent,
      cycle: cycle,
      today: today,
      isEstimate: cycleTx.isEmpty,
    );

    final usages = <BudgetUsage>[
      for (final b in budgets)
        BudgetUsage(
          category: b.category,
          spent: cycleTx
              .where((t) => t.category == b.category)
              .fold(0, (sum, t) => sum + t.amount),
          limit: b.limit,
        ),
    ];

    final sorted = [...cycleTx]
      ..sort((a, b) => b.date.compareTo(a.date));

    return BudgetOverview(
      plan: plan,
      cycle: cycle,
      summary: summary,
      usages: usages,
      cycleTransactions: sorted,
    );
  }

  final Plan plan;
  final SalaryCycle cycle;
  final FinancialSummary summary;

  /// Pemakaian per kategori yang punya alokasi (PRD 7.2.C).
  final List<BudgetUsage> usages;

  /// Transaksi fleksibel dalam siklus, terbaru di atas (untuk detail, 7.2.D).
  final List<ExpenseTransaction> cycleTransactions;

  bool get isEmpty => usages.isEmpty;

  /// Total alokasi seluruh kategori.
  int get totalAllocated => usages.fold(0, (sum, u) => sum + u.limit);

  /// Total terpakai pada kategori yang dialokasikan.
  int get totalSpentInCategories =>
      usages.fold(0, (sum, u) => sum + u.spent);

  /// Anggaran fleksibel siklus (PRD 8.2) — pembanding edit anggaran.
  int get flexibleBudget => summary.discretionaryBudget;

  /// Terpakai terhadap anggaran fleksibel (kartu total, PRD 7.2.B).
  int get totalSpent => summary.discretionarySpent;

  /// Sisa anggaran fleksibel; tidak pernah negatif.
  int get remainingFlexible => summary.remainingFlexible;

  double? get progress => summary.spendingProgress;

  String get cycleLabel => cycle.label;

  BudgetUsage? usageFor(String category) {
    for (final u in usages) {
      if (u.category == category) return u;
    }
    return null;
  }

  List<ExpenseTransaction> transactionsIn(String category) => [
        for (final t in cycleTransactions)
          if (t.category == category) t,
      ];
}
