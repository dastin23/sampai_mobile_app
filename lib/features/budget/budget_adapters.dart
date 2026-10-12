import '../../core/calc/salary_cycle.dart';
import '../../core/models/plan.dart';
import 'models/budget_model.dart';

/// Bulan kalender tempat anggaran aktif disimpan: bulan dari tanggal mulai
/// siklus berjalan (atau bulan ini bila rencana belum ada). Selalu tanggal 1.
DateTime activeBudgetMonth(Plan? plan, DateTime today) {
  if (plan == null) return DateTime(today.year, today.month);
  final SalaryCycle cycle = plan.cycleFor(today);
  return DateTime(cycle.start.year, cycle.start.month);
}

/// Anggaran kategori (baris `category_id` terisi) → model alokasi app.
/// Baris non-kategori (anggaran total bulanan) diabaikan.
List<BudgetCategory> toBudgetCategories(List<Budget> budgets) => [
      for (final budget in budgets)
        if (budget.categoryId != null)
          BudgetCategory(
            category: budget.categoryName ?? 'Lainnya',
            limit: budget.amount.round(),
          ),
    ];
