/// Anggaran bulanan per kategori dari tabel `budgets`.
///
/// `categoryId` null berarti anggaran total bulanan; baris ber-`categoryId`
/// berarti anggaran satu kategori pengeluaran.
class Budget {
  final String id;
  final String userId;
  final String? categoryId;
  final DateTime month;
  final double amount;
  final String? categoryName;

  const Budget({
    required this.id,
    required this.userId,
    required this.month,
    required this.amount,
    this.categoryId,
    this.categoryName,
  });

  bool get isTotal => categoryId == null;

  factory Budget.fromMap(Map<String, dynamic> map) {
    final category = map['categories'];

    return Budget(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      categoryId: map['category_id']?.toString(),
      month: DateTime.parse(map['month'] as String),
      amount: (map['amount'] as num).toDouble(),
      categoryName: category is Map ? category['name'] as String? : null,
    );
  }
}
