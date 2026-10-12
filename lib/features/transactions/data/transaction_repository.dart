import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Silakan login terlebih dahulu.');
    }

    return user.id;
  }

  Future<List<FinanceTransaction>> getTransactions() async {
    final rows = await _client
        .from('transactions')
        .select('*, categories(id, name, type)')
        .eq('user_id', _userId)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => FinanceTransaction.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<TransactionCategory>> getCategories() async {
    final rows = await _client
        .from('categories')
        .select('id, name, type')
        .order('name');

    return rows
        .map(
          (row) => TransactionCategory.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> createTransaction({
    required String type,
    required double amount,
    required DateTime transactionDate,
    String? categoryId,
    String? description,
  }) async {
    await _client.from('transactions').insert({
      'user_id': _userId,
      'type': type,
      'amount': amount,
      'transaction_date': _dateOnly(transactionDate),
      'category_id': categoryId,
      'description': _cleanDescription(description),
    });
  }

  Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required DateTime transactionDate,
    String? categoryId,
    String? description,
  }) async {
    await _client
        .from('transactions')
        .update({
          'type': type,
          'amount': amount,
          'transaction_date': _dateOnly(transactionDate),
          'category_id': categoryId,
          'description': _cleanDescription(description),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteTransaction(String id) async {
    await _client
        .from('transactions')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String? _cleanDescription(String? value) {
    final cleaned = value?.trim();

    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}
