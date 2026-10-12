import 'package:sampai_app/features/transactions/data/transaction_repository.dart';
import 'package:sampai_app/features/transactions/models/transaction_model.dart';

/// Kategori default global — meniru seed di supabase_database.sql.
const List<TransactionCategory> defaultTestCategories = [
  TransactionCategory(id: 'cat-makanan', name: 'Makanan', type: 'expense'),
  TransactionCategory(
    id: 'cat-transportasi',
    name: 'Transportasi',
    type: 'expense',
  ),
  TransactionCategory(id: 'cat-belanja', name: 'Belanja', type: 'expense'),
  TransactionCategory(id: 'cat-tagihan', name: 'Tagihan', type: 'expense'),
  TransactionCategory(id: 'cat-hiburan', name: 'Hiburan', type: 'expense'),
  TransactionCategory(id: 'cat-kesehatan', name: 'Kesehatan', type: 'expense'),
  TransactionCategory(id: 'cat-lainnya', name: 'Lainnya', type: 'expense'),
  TransactionCategory(id: 'cat-gaji', name: 'Gaji', type: 'income'),
  TransactionCategory(id: 'cat-bonus', name: 'Bonus', type: 'income'),
  TransactionCategory(id: 'cat-investasi', name: 'Investasi', type: 'income'),
];

/// Fake [TransactionRepository] in-memory untuk test (tanpa Supabase).
class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository({
    List<FinanceTransaction>? transactions,
    List<TransactionCategory>? categories,
    this.failCreate = false,
    this.failGet = false,
  })  : transactions = [...?transactions],
        categories = [...(categories ?? defaultTestCategories)];

  final List<FinanceTransaction> transactions;
  final List<TransactionCategory> categories;

  /// Bila true, [createTransaction] melempar error (uji kegagalan simpan).
  bool failCreate;

  /// Bila true, [getTransactions] melempar error (uji state error layar).
  bool failGet;

  int _sequence = 0;

  @override
  Future<List<FinanceTransaction>> getTransactions() async {
    if (failGet) {
      throw StateError('gagal memuat (uji)');
    }
    final list = [...transactions]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return list;
  }

  @override
  Future<List<TransactionCategory>> getCategories() async =>
      [...categories]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<void> createTransaction({
    required String type,
    required double amount,
    required DateTime transactionDate,
    String? categoryId,
    String? description,
  }) async {
    if (failCreate) {
      throw StateError('gagal menyimpan (uji)');
    }
    _sequence++;
    transactions.add(
      FinanceTransaction(
        id: 'gen-$_sequence',
        userId: 'test-user',
        type: type,
        amount: amount,
        transactionDate: transactionDate,
        categoryId: categoryId,
        description: description,
        categoryName: _categoryName(categoryId),
      ),
    );
  }

  @override
  Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required DateTime transactionDate,
    String? categoryId,
    String? description,
  }) async {
    final index = transactions.indexWhere((t) => t.id == id);
    if (index < 0) return;
    transactions[index] = FinanceTransaction(
      id: id,
      userId: transactions[index].userId,
      type: type,
      amount: amount,
      transactionDate: transactionDate,
      categoryId: categoryId,
      description: description,
      categoryName: _categoryName(categoryId),
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
  }

  String? _categoryName(String? categoryId) {
    if (categoryId == null) return null;
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return null;
  }
}
