import '../../core/calc/cycle_transactions.dart';
import '../../core/calc/financial_summary.dart';
import '../../core/calc/salary_cycle.dart';
import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';

class UpcomingBill {
  const UpcomingBill({
    required this.name,
    required this.amount,
    required this.dueDate,
  });

  final String name;
  final int amount;
  final DateTime dueDate;
}

/// ViewModel layar Home: seluruh nilai sudah dihitung oleh
/// [FinancialSummary] / helper di bawah — UI tidak menghitung sendiri.
class HomeData {
  const HomeData({
    required this.plan,
    required this.cycle,
    required this.summary,
    required this.budgetUsages,
    required this.recentTransactions,
    required this.upcomingBills,
    required this.offline,
    required this.updatedAt,
    this.isDemo = false,
  });

  factory HomeData.fromState({
    required AppState state,
    required DateTime today,
    required bool offline,
  }) {
    final plan = state.plan;
    if (plan == null) {
      throw StateError('HomeData.fromState butuh plan');
    }
    return HomeData.fromInputs(
      plan: plan,
      transactions: state.transactions,
      budgets: state.budgets,
      today: today,
      offline: offline,
      updatedAt: state.lastUpdatedAt,
    );
  }

  factory HomeData.fromInputs({
    required Plan plan,
    required List<ExpenseTransaction> transactions,
    required List<BudgetCategory> budgets,
    required DateTime today,
    required bool offline,
    required DateTime? updatedAt,
    bool isDemo = false,
  }) {
    final cycle = plan.cycleFor(today);
    final spent = discretionarySpent(transactions, cycle);
    final summary = FinancialSummary.compute(
      netIncome: plan.netIncome,
      fixedBillsUnpaid: plan.activeBillsTotal,
      savingsTargetUnfunded: plan.savingsTarget,
      safetyBuffer: plan.safetyBuffer,
      discretionarySpent: spent,
      cycle: cycle,
      today: today,
      // Data dianggap belum lengkap selama belum ada catatan pengeluaran
      // (PRD 5.2.B — label Estimasi).
      isEstimate: flexibleTransactionsIn(transactions, cycle).isEmpty,
    );

    final usages = <BudgetUsage>[
      for (final b in budgets)
        BudgetUsage(
          category: b.category,
          spent: spentInCategory(transactions, cycle, b.category),
          limit: b.limit,
        ),
    ];

    final recent = flexibleTransactionsIn(transactions, cycle)
      ..sort((a, b) => b.date.compareTo(a.date));

    final bills = <UpcomingBill>[];
    for (final bill in plan.activeBills) {
      final due = firstDueDateIn(cycle, bill.dueDay);
      if (due != null) {
        bills.add(
          UpcomingBill(name: bill.name, amount: bill.amount, dueDate: due),
        );
      }
    }
    bills.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return HomeData(
      plan: plan,
      cycle: cycle,
      summary: summary,
      budgetUsages: usages,
      recentTransactions: recent.take(5).toList(),
      upcomingBills: bills,
      offline: offline,
      updatedAt: updatedAt,
      isDemo: isDemo,
    );
  }

  final Plan plan;
  final SalaryCycle cycle;
  final FinancialSummary summary;
  final List<BudgetUsage> budgetUsages;
  final List<ExpenseTransaction> recentTransactions;
  final List<UpcomingBill> upcomingBills;
  final bool offline;
  final DateTime? updatedAt;
  final bool isDemo;

  String get cycleLabel =>
      '${formatCycleDate(cycle.start)} – ${formatCycleDate(cycle.end)}';

  int get remainingDays => summary.remainingDays;

  /// Maksimal tiga kategori di Home (PRD 5.2.D).
  List<BudgetUsage> get topBudgetUsages {
    final sorted = [...budgetUsages]
      ..sort((a, b) => (b.progress ?? 0).compareTo(a.progress ?? 0));
    return sorted.take(3).toList();
  }

  HomeData copyWith({bool? offline, DateTime? updatedAt}) => HomeData(
        plan: plan,
        cycle: cycle,
        summary: summary,
        budgetUsages: budgetUsages,
        recentTransactions: recentTransactions,
        upcomingBills: upcomingBills,
        offline: offline ?? this.offline,
        updatedAt: updatedAt ?? this.updatedAt,
        isDemo: isDemo,
      );
}

/// Tanggal jatuh tempo pertama dari [dueDay] yang jatuh di dalam siklus.
DateTime? firstDueDateIn(SalaryCycle cycle, int dueDay) {
  final candidates = [
    DateTime(cycle.start.year, cycle.start.month, 1),
    DateTime(cycle.start.year, cycle.start.month + 1, 1),
  ];
  for (final month in candidates) {
    final due = paydayInMonth(month.year, month.month, dueDay);
    if (!due.isBefore(cycle.start) && !due.isAfter(cycle.end)) return due;
  }
  return null;
}
