import 'package:flutter/foundation.dart';

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

  TransactionsStatus get status => _status;
  TransactionsData? get data => _data;

  /// Belum ada siklus teratur (plan == null).
  bool get noPlan => _appState.plan == null;

  /// Muat data live; menampilkan skeleton selama proses.
  Future<void> load() async {
    _status = TransactionsStatus.loading;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    resolveLive();
  }

  void resolveLive() {
    final plan = _appState.plan;
    _data = plan == null
        ? null
        : TransactionsData.fromState(
            state: _appState,
            today: DateTime.now(),
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