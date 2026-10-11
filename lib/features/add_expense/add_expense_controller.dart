import 'package:flutter/foundation.dart';

import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';

enum ExpenseSaveStatus { idle, saving, success, error }

/// Penyimpanan transaksi (PRD 6.5) untuk pengeluaran maupun pemasukan.
///
/// - Mencegah double submit berulang selama [save] berjalan.
/// - Idempotensi tambahan: [AppState.addTransaction] mengabaikan transaksi
///   dengan id yang sudah tersimpan.
/// - Mode sunting: bila [editing] terisi, [save] memperbarui transaksi
///   yang sudah ada (id, jenis income, dan flag fleksibel dipertahankan).
class AddExpenseController extends ChangeNotifier {
  AddExpenseController(
    this._appState, {
    this.simulateFailure = false,
    this.editing,
  });

  final AppState _appState;
  final bool simulateFailure;

  /// Transaksi yang disunting; null bila sedang menambah baru.
  final ExpenseTransaction? editing;

  bool get isEditing => editing != null;

  /// True bila transaksi pemasukan (dipakai [AddIncomeController]).
  /// Dalam mode sunting, jenis ini diikuti dari transaksi yang disunting.
  bool get isIncome => editing?.isIncome ?? false;

  String get _idPrefix => isIncome ? 'income-' : 'expense-';

  ExpenseSaveStatus _status = ExpenseSaveStatus.idle;
  ExpenseSaveStatus get status => _status;
  bool get isSaving => _status == ExpenseSaveStatus.saving;

  /// Simpan transaksi (baru atau hasil sunting).
  /// Return [null] bila gagal atau sedang sibuk menyimpan.
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
    final title = trimmedNote.isEmpty ? category : trimmedNote;
    final existing = editing;

    final ExpenseTransaction result;
    if (existing != null) {
      result = existing.copyWith(
        title: title,
        category: category,
        amount: amount,
        date: date,
      );
      _appState.updateTransaction(result);
    } else {
      result = isIncome
          ? ExpenseTransaction.income(
              id: '$_idPrefix${DateTime.now().microsecondsSinceEpoch}-$amount',
              title: title,
              category: category,
              amount: amount,
              date: date,
            )
          : ExpenseTransaction(
              id: '$_idPrefix${DateTime.now().microsecondsSinceEpoch}-$amount',
              title: title,
              category: category,
              amount: amount,
              date: date,
            );
      _appState.addTransaction(result);
    }
    _status = ExpenseSaveStatus.success;
    notifyListeners();
    return result;
  }

  /// Hapus transaksi yang disunting. Tidak melakukan apa-apa pada mode tambah.
  void deleteEditing() {
    final existing = editing;
    if (existing == null) return;
    _appState.deleteTransaction(existing.id);
  }
}

/// Penyimpanan transaksi pemasukan — sama dengan pengeluaran, hanya
/// menandai [ExpenseTransaction.isIncome].
class AddIncomeController extends AddExpenseController {
  AddIncomeController(
    super.appState, {
    super.simulateFailure,
    super.editing,
  });

  @override
  bool get isIncome => true;
}