import 'package:flutter/foundation.dart';

import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';

enum ExpenseSaveStatus { idle, saving, success, error }

/// Penyimpanan transaksi Add Expense (PRD 6.5).
///
/// - Mencegah double submit berulang selama [save] berjalan.
/// - Idempotensi tambahan: [AppState.addTransaction] mengabaikan transaksi
///   dengan id yang sudah tersimpan.
class AddExpenseController extends ChangeNotifier {
  AddExpenseController(this._appState, {this.simulateFailure = false});

  final AppState _appState;
  final bool simulateFailure;

  ExpenseSaveStatus _status = ExpenseSaveStatus.idle;
  ExpenseSaveStatus get status => _status;
  bool get isSaving => _status == ExpenseSaveStatus.saving;

  /// Simpan transaksi. Return [null] bila gagal atau sedang sibuk menyimpan.
  Future<ExpenseTransaction?> save({
    required String note,
    required String category,
    required int amount,
    required DateTime date,
  }) async {
    if (isSaving) return null;
    _status = ExpenseSaveStatus.saving;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (simulateFailure) {
      _status = ExpenseSaveStatus.error;
      notifyListeners();
      return null;
    }

    final trimmedNote = note.trim();
    final transaction = ExpenseTransaction(
      id: 'expense-${DateTime.now().microsecondsSinceEpoch}-$amount',
      title: trimmedNote.isEmpty ? category : trimmedNote,
      category: category,
      amount: amount,
      date: date,
    );
    _appState.addTransaction(transaction);
    _status = ExpenseSaveStatus.success;
    notifyListeners();
    return transaction;
  }
}