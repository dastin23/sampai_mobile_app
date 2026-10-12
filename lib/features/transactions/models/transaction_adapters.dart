import '../../../core/models/plan.dart';
import 'transaction_model.dart';

/// Petakan transaksi backend ([FinanceTransaction]) ke model tampilan
/// kalkulasi ([ExpenseTransaction]) yang dipakai Home/Budget/Transaksi.
ExpenseTransaction toExpenseTransaction(FinanceTransaction transaction) {
  final categoryName = transaction.categoryName?.trim();
  final category =
      categoryName == null || categoryName.isEmpty ? 'Lainnya' : categoryName;
  final description = transaction.description?.trim();
  final title = description == null || description.isEmpty
      ? category
      : description;
  final amount = transaction.amount.round();

  return transaction.isIncome
      ? ExpenseTransaction.income(
          id: transaction.id,
          title: title,
          category: category,
          amount: amount,
          date: transaction.transactionDate,
        )
      : ExpenseTransaction(
          id: transaction.id,
          title: title,
          category: category,
          amount: amount,
          date: transaction.transactionDate,
        );
}
