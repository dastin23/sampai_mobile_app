import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_state.dart';
import '../../features/onboarding/onboarding_controller.dart';

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

/// `true` setelah onboarding selesai (rencana diterapkan ke [appStateProvider]).
class OnboardedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() {
    final controller = ref.read(onboardingControllerProvider);
    ref.read(appStateProvider).applyPlan(controller.buildPlan());
    state = true;
  }

  void reset() {
    ref.read(onboardingControllerProvider).restart();
    ref.read(appStateProvider).clear();
    state = false;
  }
}

final onboardedProvider = NotifierProvider<OnboardedNotifier, bool>(
  OnboardedNotifier.new,
);