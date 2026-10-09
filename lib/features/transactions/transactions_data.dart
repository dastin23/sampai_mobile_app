import '../../core/calc/cycle_transactions.dart';
import '../../core/calc/financial_summary.dart';
import '../../core/calc/salary_cycle.dart';
import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';

/// ViewModel layar Transaksi — seluruh nilai berasal dari
/// [FinancialSummary] dan perhitungan siklus; UI tidak menghitung sendiri.
class TransactionsData {
  const TransactionsData({
    required this.plan,
    required this.cycle,
    required this.summary,
    required this.transactions,
  });

  factory TransactionsData.fromState({
    required AppState state,
    required DateTime today,
  }) {
    final plan = state.plan;
    if (plan == null) {
      throw StateError('TransactionsData.fromState butuh plan');
    }
    return TransactionsData.fromInputs(
      plan: plan,
      transactions: state.transactions,
      today: today,
    );
  }

  factory TransactionsData.fromInputs({
    required Plan plan,
    required List<ExpenseTransaction> transactions,
    required DateTime today,
  }) {
    final cycle = plan.cycleFor(today);
    final cycleTx = flexibleTransactionsIn(transactions, cycle);
    final summary = FinancialSummary.compute(
      netIncome: plan.netIncome,
      fixedBillsUnpaid: plan.activeBillsTotal,
      savingsTargetUnfunded: plan.savingsTarget,
      safetyBuffer: plan.safetyBuffer,
      discretionarySpent: cycleTx.fold(0, (sum, t) => sum + t.amount),
      cycle: cycle,
      today: today,
      isEstimate: cycleTx.isEmpty,
    );

    final sorted = [...transactionsInCycle(transactions, cycle)]
      ..sort((a, b) => b.date.compareTo(a.date));

    return TransactionsData(
      plan: plan,
      cycle: cycle,
      summary: summary,
      transactions: sorted,
    );
  }

  final Plan plan;
  final SalaryCycle cycle;
  final FinancialSummary summary;

  /// Transaksi dalam siklus (pengeluaran + pemasukan), terbaru di atas.
  final List<ExpenseTransaction> transactions;

  bool get isEmpty => transactions.isEmpty;

  /// Total terpakai terhadap anggaran fleksibel siklus.
  int get totalSpent => summary.discretionarySpent;

  /// Total pemasukan tercatat dalam siklus.
  int get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  /// Sisa anggaran fleksibel; tidak pernah negatif.
  int get remainingFlexible => summary.remainingFlexible;

  String get cycleLabel => cycle.label;
}