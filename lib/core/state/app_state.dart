import 'package:flutter/foundation.dart';

import '../calc/salary_cycle.dart';
import '../models/plan.dart';

/// Penyimpanan data aplikasi (in-memory, MVP).
///
/// Menjadi satu sumber kebenaran untuk Home, dan kelak Add Expense/Budget.
class AppState extends ChangeNotifier {
  Plan? _plan;
  final List<ExpenseTransaction> _transactions = <ExpenseTransaction>[];
  final List<BudgetCategory> _budgets = <BudgetCategory>[];

  DateTime? _lastUpdatedAt;

  Plan? get plan => _plan;
  List<ExpenseTransaction> get transactions => List.unmodifiable(_transactions);
  List<BudgetCategory> get budgets => List.unmodifiable(_budgets);

  /// Waktu pembaruan data terakhir; null bila belum pernah ada data.
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  bool get hasPlan => _plan != null;

  /// Dipanggil setelah onboarding sukses: membuat salary cycle configuration.
  void applyPlan(Plan plan) {
    _plan = plan;
    _touch();
    notifyListeners();
  }

  /// Simpan transaksi. Mengabaikan duplikat id (idempotensi, PRD 6.5).
  void addTransaction(ExpenseTransaction transaction) {
    if (_transactions.any((t) => t.id == transaction.id)) return;
    _transactions.insert(0, transaction);
    _touch();
    notifyListeners();
  }

  void replaceBudgets(List<BudgetCategory> budgets) {
    _budgets
      ..clear()
      ..addAll(budgets);
    _touch();
    notifyListeners();
  }

  /// Tandai data diperbarui (mis. setelah sinkronisasi terkonfirmasi).
  void touch() {
    _touch();
    notifyListeners();
  }

  /// Hapus seluruh data lokal (dipakai saat mulai ulang pengaturan).
  void clear() {
    _plan = null;
    _transactions.clear();
    _budgets.clear();
    _lastUpdatedAt = null;
    notifyListeners();
  }

  void _touch() => _lastUpdatedAt = DateTime.now();

  /// Transaksi yang dihitung terhadap anggaran fleksibel pada siklus [cycle]
  /// (PRD 8.5 — transfer/di luar fleksibel tidak boleh ikut terpakai).
  int discretionarySpentIn(SalaryCycle cycle) {
    var total = 0;
    for (final t in _transactions) {
      if (!t.countsTowardFlexibleBudget) continue;
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      if (date.isBefore(cycle.start) || date.isAfter(cycle.end)) continue;
      total += t.amount;
    }
    return total;
  }
}
