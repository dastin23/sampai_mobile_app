import 'package:sampai_app/features/budget/budget_adapters.dart';
import 'package:sampai_app/features/budget/models/budget_model.dart';
import 'package:sampai_app/features/home/home_demo_data.dart';
import 'package:sampai_app/features/transactions/models/transaction_model.dart';

import 'fake_budget_repository.dart';
import 'fake_transaction_repository.dart';

/// Kategori test memakai nama dataset contoh Home/Budget ('Makan', dst.) agar
/// anggaran dan transaksi saling merujuk pada kategori yang sama.
const List<TransactionCategory> demoTestCategories = [
  TransactionCategory(id: 'cat-makan', name: 'Makan', type: 'expense'),
  TransactionCategory(
    id: 'cat-transportasi',
    name: 'Transportasi',
    type: 'expense',
  ),
  TransactionCategory(id: 'cat-hiburan', name: 'Hiburan', type: 'expense'),
  TransactionCategory(id: 'cat-belanja', name: 'Belanja', type: 'expense'),
  TransactionCategory(id: 'cat-lainnya', name: 'Lainnya', type: 'expense'),
  TransactionCategory(id: 'cat-gaji', name: 'Gaji', type: 'income'),
  TransactionCategory(id: 'cat-bonus', name: 'Bonus', type: 'income'),
];

Map<String, String> _idByName() => {
      for (final category in demoTestCategories) category.name: category.id,
    };

/// Repository transaksi terisi dataset contoh [demoTransactions].
FakeTransactionRepository seededTransactionRepository(DateTime today) {
  final repository =
      FakeTransactionRepository(categories: demoTestCategories);
  final ids = _idByName();
  for (final tx in demoTransactions(today)) {
    repository.transactions.add(
      FinanceTransaction(
        id: tx.id,
        userId: 'test-user',
        type: tx.isIncome ? 'income' : 'expense',
        amount: tx.amount.toDouble(),
        transactionDate: tx.date,
        categoryId: ids[tx.category],
        description: tx.title,
        categoryName: tx.category,
      ),
    );
  }
  return repository;
}

/// Repository anggaran terisi dataset contoh [demoBudgets] untuk bulan aktif.
FakeBudgetRepository seededBudgetRepository(DateTime today) {
  final plan = demoPlan(today);
  final month = activeBudgetMonth(plan, today);
  final repository = FakeBudgetRepository(categories: demoTestCategories);
  final ids = _idByName();
  for (final budget in demoBudgets()) {
    repository.budgets.add(
      Budget(
        id: 'seed-${budget.category}',
        userId: 'test-user',
        categoryId: ids[budget.category],
        month: month,
        amount: budget.limit.toDouble(),
        categoryName: budget.category,
      ),
    );
  }
  return repository;
}
