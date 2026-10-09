import '../../core/models/plan.dart';
import '../home/home_demo_data.dart';
import 'budget_data.dart';

/// Dataset contoh mode desain Budget (PRD 7.3 — hanya untuk pratinjau state).
/// Semua angka dihitung oleh formula produksi yang sama dengan Home.

ExpenseTransaction _tx(
  DateTime today,
  int offsetDays,
  String title,
  String category,
  int amount,
) =>
    ExpenseTransaction(
      id: 'demo-budget-$offsetDays-$title',
      title: title,
      category: category,
      amount: amount,
      date: DateTime(today.year, today.month, today.day - offsetDays),
    );

/// Total Rp2.730.000 tetap; Makan Rp1.000.000/1.200.000 = 83%
/// → label "Mendekati batas" (PRD 7.3 near limit, ambang 80%).
List<ExpenseTransaction> demoNearLimitTransactions(DateTime today) => [
      ...demoTransactions(today).where(
        (t) => t.id != 'demo-tx-11-Keperluan pribadi',
      ),
      _tx(today, 3, 'Pesta kantor', 'Makan', 100000),
      _tx(today, 11, 'Keperluan pribadi', 'Lainnya', 230000),
    ];

/// Makan Rp1.300.000 > Rp1.200.000 → "Melebihi anggaran Rp100.000".
List<ExpenseTransaction> demoOverBudgetTransactions(DateTime today) => [
      ...demoTransactions(today),
      _tx(today, 3, 'Pesta kantor', 'Makan', 400000),
    ];

BudgetOverview demoNearLimitOverview(DateTime today) =>
    BudgetOverview.fromInputs(
      plan: demoPlan(today),
      transactions: demoNearLimitTransactions(today),
      budgets: demoBudgets(),
      today: today,
    );

BudgetOverview demoOverBudgetOverview(DateTime today) =>
    BudgetOverview.fromInputs(
      plan: demoPlan(today),
      transactions: demoOverBudgetTransactions(today),
      budgets: demoBudgets(),
      today: today,
    );
