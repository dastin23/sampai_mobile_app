import 'package:flutter/foundation.dart';

import '../../core/calc/salary_cycle.dart';
import '../../core/state/app_state.dart';
import 'transactions_data.dart';

enum TransactionsStatus { loading, ready, error }

/// Mengelola pemuatan daftar transaksi siklus (PRD 5.2.F "Lihat semua").
class TransactionsController extends ChangeNotifier {
  TransactionsController(this._appState) {
    _appState.addListener(_onAppStateChanged);
  }

  final AppState _appState;

  TransactionsStatus _status = TransactionsStatus.loading;
  TransactionsData? _data;
  TransactionScope _scope = TransactionScope.cycle;
  SalaryCycle? _period;

  TransactionsStatus get status => _status;
  TransactionsData? get data => _data;

  /// Cakupan daftar: siklus berjalan (default) atau seluruh riwayat.
  TransactionScope get scope => _scope;

  /// Periode siklus terpilih saat [scope] == cycle; null = siklus berjalan.
  SalaryCycle? get period => _period;

  /// Periode yang bisa dipilih (dari data), terbaru lebih dulu.
  List<SalaryCycle> get availablePeriods => _data?.availablePeriods ?? const [];

  /// Belum ada siklus teratur (plan == null).
  bool get noPlan => _appState.plan == null;

  /// Muat data live; menampilkan skeleton selama proses.
  Future<void> load() async {
    _status = TransactionsStatus.loading;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    resolveLive();
  }

  /// Ganti cakupan daftar (siklus ini ↔ riwayat semua) dan hitung ulang.
  void setScope(TransactionScope scope) {
    switch (scope) {
      case TransactionScope.all:
        selectAll();
      case TransactionScope.cycle:
        selectCurrentCycle();
    }
  }

  /// Pilih periode siklus tertentu; [cycle] null = siklus berjalan.
  void selectCycle(SalaryCycle? cycle) {
    _scope = TransactionScope.cycle;
    _period = cycle;
    resolveLive();
  }

  /// Tampilkan seluruh riwayat.
  void selectAll() {
    _scope = TransactionScope.all;
    _period = null;
    resolveLive();
  }

  /// Tampilkan siklus berjalan.
  void selectCurrentCycle() => selectCycle(null);

  void resolveLive() {
    final plan = _appState.plan;
    _data = plan == null
        ? null
        : TransactionsData.fromState(
            state: _appState,
            today: DateTime.now(),
            scope: _scope,
            period: _period,
          );
    _status = TransactionsStatus.ready;
    notifyListeners();
  }

  void previewError() {
    _status = TransactionsStatus.error;
    notifyListeners();
  }

  void _onAppStateChanged() {
    if (_status == TransactionsStatus.ready) {
      resolveLive();
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }
}