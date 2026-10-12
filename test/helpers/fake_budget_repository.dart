import 'package:sampai_app/features/budget/data/budget_repository.dart';
import 'package:sampai_app/features/budget/models/budget_model.dart';
import 'package:sampai_app/features/transactions/models/transaction_model.dart';

import 'fake_transaction_repository.dart';

/// Fake [BudgetRepository] in-memory untuk test (tanpa Supabase).
class FakeBudgetRepository implements BudgetRepository {
  FakeBudgetRepository({
    List<Budget>? budgets,
    List<TransactionCategory>? categories,
    this.failGet = false,
  })  : budgets = [...?budgets],
        categories = [...(categories ?? defaultTestCategories)];

  final List<Budget> budgets;
  final List<TransactionCategory> categories;

  /// Bila true, [getBudgets] melempar error (uji state error layar).
  bool failGet;

  int _sequence = 0;

  @override
  Future<List<Budget>> getBudgets(DateTime month) async {
    if (failGet) {
      throw StateError('gagal memuat (uji)');
    }
    final target = DateTime(month.year, month.month);
    final list = [
      for (final budget in budgets)
        if (budget.month.year == target.year &&
            budget.month.month == target.month)
          budget,
    ];
    return list..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Future<void> setBudget({
    required String categoryId,
    required DateTime month,
    required double amount,
  }) async {
    final target = DateTime(month.year, month.month);
    budgets.removeWhere(
      (budget) =>
          budget.categoryId == categoryId &&
          budget.month.year == target.year &&
          budget.month.month == target.month,
    );
    if (amount <= 0) return;
    _sequence++;
    budgets.add(
      Budget(
        id: 'budget-$_sequence',
        userId: 'test-user',
        categoryId: categoryId,
        month: target,
        amount: amount,
        categoryName: _categoryName(categoryId),
      ),
    );
  }

  String? _categoryName(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return null;
  }
}
