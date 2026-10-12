class FinanceTransaction {
  final String id;
  final String userId;
  final String? categoryId;
  final String type;
  final double amount;
  final String? description;
  final DateTime transactionDate;
  final String? categoryName;

  const FinanceTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.categoryId,
    this.description,
    this.categoryName,
  });

  bool get isIncome => type == 'income';

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    final category = map['categories'];

    return FinanceTransaction(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      categoryId: map['category_id']?.toString(),
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      categoryName: category is Map ? category['name'] as String? : null,
    );
  }
}

class TransactionCategory {
  final String id;
  final String name;
  final String type;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.type,
  });

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
      id: map['id'].toString(),
      name: map['name'] as String,
      type: map['type'] as String,
    );
  }
}
