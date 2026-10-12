import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/budget_model.dart';

/// Akses tabel `budgets` (skema baru): anggaran per kategori per bulan.
///
/// Setiap baris mewakili anggaran satu kategori pengeluaran untuk bulan
/// tertentu (`month` selalu tanggal 1). Menyetel anggaran 0 menghapus baris.
class BudgetRepository {
  BudgetRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Silakan login terlebih dahulu.');
    }

    return user.id;
  }

  Future<List<Budget>> getBudgets(DateTime month) async {
    final rows = await _client
        .from('budgets')
        .select('*, categories(name, type)')
        .eq('user_id', _userId)
        .eq('month', _monthOnly(month))
        .order('created_at');

    return rows
        .map((row) => Budget.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Setel anggaran [categoryId] untuk [month]. [amount] <= 0 menghapus baris.
  Future<void> setBudget({
    required String categoryId,
    required DateTime month,
    required double amount,
  }) async {
    await _client
        .from('budgets')
        .delete()
        .eq('user_id', _userId)
        .eq('category_id', categoryId)
        .eq('month', _monthOnly(month));

    if (amount <= 0) return;

    await _client.from('budgets').insert({
      'user_id': _userId,
      'category_id': categoryId,
      'month': _monthOnly(month),
      'amount': amount,
    });
  }

  String _monthOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$year-$month-01';
  }
}
