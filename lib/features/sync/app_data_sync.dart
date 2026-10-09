import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/state/app_state.dart';
import '../auth/data/auth_repository.dart';
import 'data/app_data_repository.dart';

/// Sinkronisasi data Home ke Supabase (write-through).
///
/// `AppState` tetap sumber kebenaran runtime. Setiap kali `AppState` berubah
/// (rencana, anggaran, transaksi) dan user sudah login serta rencana sudah
/// ada, seluruh snapshot disimpan ke backend. Penyimpanan dilakukan di
/// belakang layar dan kegagalan tidak pernah mengganggu UI (offline-first).
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
    final signature = _signature(
      snapshot: AppDataSnapshot(
        plan: _state.plan,
        budgets: _state.budgets,
        transactions: _state.transactions,
      ),
    );
    if (signature == _lastSignature) return;

    _persisting = true;
    _lastSignature = signature;
    try {
      await _repository.saveAll(
        AppDataSnapshot(
          plan: _state.plan,
          budgets: _state.budgets,
          transactions: _state.transactions,
        ),
      );
    } catch (error, stack) {
      debugPrint('AppDataSync: gagal menyimpan ke Supabase.\n$error\n$stack');
    } finally {
      _persisting = false;
    }
  }

  @visibleForTesting
  static String signature(AppDataSnapshot snapshot) {
    final buf = StringBuffer();
    final plan = snapshot.plan;
    if (plan != null) {
      buf
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
    }
    buf.write('|b:');
    final budgets = [...snapshot.budgets]
      ..sort((a, b) => a.category.compareTo(b.category));
    for (final b in budgets) {
      buf..write(b.category)..write(':')..write(b.limit)..write(';');
    }
    buf.write('|t:');
    final txs = [...snapshot.transactions]
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final t in txs) {
      buf
        ..write(t.id)
        ..write(':')
        ..write(t.amount)
        ..write(':')
        ..write(t.date)
        ..write(':')
        ..write(t.countsTowardFlexibleBudget)
        ..write(':')
        ..write(t.isIncome)
        ..write(';');
    }
    return buf.toString();
  }

  String _signature({required AppDataSnapshot snapshot}) =>
      signature(snapshot);

  void dispose() {
    _state.removeListener(_onStateChanged);
  }
}