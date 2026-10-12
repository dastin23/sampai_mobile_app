import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/transaction_repository.dart';
import '../models/transaction_model.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(Supabase.instance.client);
});

final transactionsProvider = FutureProvider<List<FinanceTransaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).getTransactions();
});

final transactionCategoriesProvider = FutureProvider<List<TransactionCategory>>(
  (ref) {
    return ref.watch(transactionRepositoryProvider).getCategories();
  },
);
