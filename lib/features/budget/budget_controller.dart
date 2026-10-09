import 'package:flutter/foundation.dart';

import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';
import 'budget_data.dart';
import 'budget_demo_data.dart';

enum BudgetStatus { loading, ready, error }

/// Mengelola pemuatan data Budget, penyimpanan edit anggaran, dan
/// pratinjau state (mode desain) untuk pengujian acceptance criteria PRD 7.3.
class BudgetController extends ChangeNotifier {
  BudgetController(this._appState) {
    _appState.addListener(_onAppStateChanged);
  }

  final AppState _appState;

  BudgetStatus _status = BudgetStatus.loading;
  BudgetOverview? _overview;
  String? _previewNote;

  BudgetStatus get status => _status;
  BudgetOverview? get overview => _overview;

  /// Non-null bila layar menampilkan data contoh / state buatan.
  String? get previewNote => _previewNote;

  /// Belum ada plan (plan == null) atau belum ada kategori teralokasi.
  bool get isEmpty => _overview == null || _overview!.usages.isEmpty;

  /// Batas kategori saat ini (persisted) — dasar alokasi lain saat edit.
  Map<String, int> get currentLimits => {
        for (final b in _appState.budgets) b.category: b.limit,
      };

  /// Muat data live; menampilkan skeleton selama proses.
  Future<void> load() async {
    _status = BudgetStatus.loading;
    _previewNote = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    resolveLive();
  }

  void resolveLive() {
    final plan = _appState.plan;
    _overview = plan == null
        ? null
        : BudgetOverview.fromState(state: _appState, today: DateTime.now());
    _status = BudgetStatus.ready;
    _previewNote = null;
    notifyListeners();
  }

  /// Simpan batas kategori. Hanya kategori yang disebut [limits] yang
  /// berubah; alokasi lain tidak diubah diam-diam (PRD 7.2.E).
  void saveLimits(Map<String, int> limits) {
    final merged = <String, int>{
      for (final b in _appState.budgets) b.category: b.limit,
    }..addAll(limits);
    _appState.replaceBudgets([
      for (final entry in merged.entries)
        BudgetCategory(category: entry.key, limit: entry.value),
    ]);
  }

  // ----------------------------------------------------- pratinjau state --

  void previewLoading() {
    _status = BudgetStatus.loading;
    _previewNote = 'Pratinjau: memuat';
    notifyListeners();
  }

  void previewNormal() => resolveLive();

  void previewEmpty() {
    _overview = null;
    _status = BudgetStatus.ready;
    _previewNote = 'Pratinjau: kosong';
    notifyListeners();
  }

  void previewNearLimit() {
    _overview = demoNearLimitOverview(DateTime.now());
    _status = BudgetStatus.ready;
    _previewNote = 'Pratinjau: mendekati batas';
    notifyListeners();
  }

  void previewOverBudget() {
    _overview = demoOverBudgetOverview(DateTime.now());
    _status = BudgetStatus.ready;
    _previewNote = 'Pratinjau: melebihi anggaran';
    notifyListeners();
  }

  void previewError() {
    _status = BudgetStatus.error;
    _previewNote = 'Pratinjau: error';
    notifyListeners();
  }

  void _onAppStateChanged() {
    if (_status == BudgetStatus.ready && _previewNote == null) {
      resolveLive();
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }
}
