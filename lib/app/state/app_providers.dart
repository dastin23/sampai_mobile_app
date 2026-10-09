import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_state.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/onboarding/onboarding_controller.dart';
import '../../features/sync/providers/app_data_providers.dart';

/// Estado aplikasi (rencana, transaksi, anggaran) — sumber kebenaran
/// Home/Budget/Add Expense/Profil.
final appStateProvider = Provider<AppState>((ref) {
  final state = AppState();
  ref.onDispose(state.dispose);
  return state;
});

/// Controller alur onboarding; data form dipertahankan selama app hidup.
final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  final controller = OnboardingController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// `true` setelah rencana tersedia (via onboarding selesai atau hydrate dari
/// Supabase saaat login kembali).
class OnboardedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  AppState get _state => ref.read(appStateProvider);

  bool get _authed => ref.read(authRepositoryProvider).isAuthenticated;

  /// Onboarding selesai: terapkan rencana ke [appStateProvider]; penyimpanan
  /// ke Supabase dilakukan oleh [appDataSyncProvider] secara otomatis.
  void complete() {
    final controller = ref.read(onboardingControllerProvider);
    _state.applyPlan(controller.buildPlan());
    state = true;
  }

  /// Muat rencana, anggaran, dan transaksi dari Supabase untuk mengisi
  /// Home saat pengguna kembali. Tidak menindih rencana lokal yang ada.
  Future<void> hydrate() async {
    if (!_authed) return;
    if (_state.plan != null) return;
    try {
      final snapshot = await ref.read(appDataRepositoryProvider).fetchAll();
      if (!_authed) return;
      if (snapshot.plan != null) {
        _state.applyPlan(snapshot.plan!);
        _state.replaceBudgets(snapshot.budgets);
        _state.replaceTransactions(snapshot.transactions);
        state = true;
      }
    } catch (error, stack) {
      debugPrint('OnboardedNotifier: gagal memuat rencana.\n$error\n$stack');
    }
  }

  /// Reset lokal + hapus data di Supabase (bila login), kembali ke onboarding.
  void reset() {
    if (_authed) {
      unawaited(_deleteRemote());
    }
    ref.read(onboardingControllerProvider).restart();
    _state.clear();
    state = false;
  }

  Future<void> _deleteRemote() async {
    try {
      await ref.read(appDataRepositoryProvider).deleteAll();
    } catch (error, stack) {
      debugPrint('OnboardedNotifier: gagal menghapus data remote.\n$error\n$stack');
    }
  }
}

final onboardedProvider = NotifierProvider<OnboardedNotifier, bool>(
  OnboardedNotifier.new,
);