import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/budget_repository.dart';
import '../models/budget_model.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(Supabase.instance.client);
});

/// Anggaran kategori untuk [month] (tanggal 1). Di-key per bulan karena
/// skema menyimpan anggaran secara bulanan.
final budgetsProvider = FutureProvider.family<List<Budget>, DateTime>(
  (ref, month) => ref.watch(budgetRepositoryProvider).getBudgets(month),
);
