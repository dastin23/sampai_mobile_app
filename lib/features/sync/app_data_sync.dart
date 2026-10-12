import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';
import '../auth/data/auth_repository.dart';
import 'data/app_data_repository.dart';

/// Sinkronisasi rencana finansial (plans + plan_bills) ke Supabase
/// (write-through).
///
/// `AppState` tetap sumber kebenaran runtime untuk rencana. Setiap kali
/// rencana berubah dan user sudah login, snapshot rencana disimpan ke backend.
/// Anggaran & transaksi disimpan langsung oleh repository fiturnya masing-masing.
/// Penyimpanan dilakukan di belakang layar dan kegagalan tidak pernah
/// mengganggu UI (offline-first).
class AppDataSync {
  AppDataSync(this._state, this._repository, this._auth) {
    _state.addListener(_onStateChanged);
  }

  final AppState _state;
  final AppDataRepository _repository;
  final AuthRepository _auth;

  String? _lastSignature;
  bool _persisting = false;

  void _onStateChanged() {
    if (!_auth.isAuthenticated) return;
    if (_state.plan == null) return;
    unawaited(_persist());
  }

  Future<void> _persist() async {
    if (_persisting) return;
    final plan = _state.plan;
    if (plan == null) return;
    final nextSignature = signature(plan);
    if (nextSignature == _lastSignature) return;

    _persisting = true;
    _lastSignature = nextSignature;
    try {
      await _repository.savePlan(plan);
    } catch (error, stack) {
      debugPrint('AppDataSync: gagal menyimpan ke Supabase.\n$error\n$stack');
    } finally {
      _persisting = false;
    }
  }

  @visibleForTesting
  static String signature(Plan plan) {
    final buf = StringBuffer()
      ..write(plan.netIncome)
      ..write('|')
      ..write(plan.paydayDay)
      ..write('|')
      ..write(plan.nextPayday)
      ..write('|')
      ..write(plan.savingsTarget)
      ..write('|')
      ..write(plan.safetyBuffer);
    for (final bill in plan.bills) {
      buf
        ..write('|[')
        ..write(bill.id)
        ..write(' ')
        ..write(bill.name)
        ..write(' ')
        ..write(bill.amount)
        ..write(' ')
        ..write(bill.dueDay)
        ..write(' ')
        ..write(bill.active)
        ..write(']');
    }
    return buf.toString();
  }

  void dispose() {
    _state.removeListener(_onStateChanged);
  }
}
