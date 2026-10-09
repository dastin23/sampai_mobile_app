import '../models/plan.dart';
import 'salary_cycle.dart';

/// Transaksi yang dihitung terhadap anggaran fleksibel (PRD 8.5)
/// dan jatuh dalam [cycle] (inklusif).
List<ExpenseTransaction> flexibleTransactionsIn(
  List<ExpenseTransaction> transactions,
  SalaryCycle cycle,
) {
  final result = <ExpenseTransaction>[];
  for (final t in transactions) {
    if (!t.countsTowardFlexibleBudget) continue;
    final date = DateTime(t.date.year, t.date.month, t.date.day);
    if (date.isBefore(cycle.start) || date.isAfter(cycle.end)) continue;
    result.add(t);
  }
  return result;
}

/// Total pengeluaran fleksibel dalam siklus.
int discretionarySpent(
  List<ExpenseTransaction> transactions,
  SalaryCycle cycle,
) =>
    flexibleTransactionsIn(transactions, cycle)
        .fold(0, (sum, t) => sum + t.amount);

/// Total pengeluaran fleksibel satu kategori dalam siklus.
int spentInCategory(
  List<ExpenseTransaction> transactions,
  SalaryCycle cycle,
  String category,
) =>
    flexibleTransactionsIn(transactions, cycle)
        .where((t) => t.category == category)
        .fold(0, (sum, t) => sum + t.amount);
