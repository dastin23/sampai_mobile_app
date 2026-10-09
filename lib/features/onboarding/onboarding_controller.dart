import 'package:flutter/foundation.dart';

import '../../core/calc/plan_preview.dart';
import '../../core/calc/salary_cycle.dart';
import '../../core/models/plan.dart';

enum PayFrequency { bulanan, mingguan, duaMingguan }

extension PayFrequencyLabel on PayFrequency {
  String get label => switch (this) {
        PayFrequency.bulanan => 'Bulanan',
        PayFrequency.mingguan => 'Mingguan',
        PayFrequency.duaMingguan => 'Dua mingguan',
      };

  /// MVP hanya mendukung siklus bulanan (PRD 4.3).
  bool get supported => this == PayFrequency.bulanan;
}

enum OnboardingStep { welcome, income, payday, fixedExpenses, savings }

/// State tunggal seluruh flow onboarding. Data form tidak pernah dihapus
/// saat penyimpanan gagal (PRD 12.Onboarding).
class OnboardingController extends ChangeNotifier {
  OnboardingStep step = OnboardingStep.welcome;

  // Screen 2 — Income
  int netIncome = 0;
  PayFrequency frequency = PayFrequency.bulanan;

  // Screen 3 — Payday
  int paydayDay = 25;
  DateTime? nextPayday; // opsional, bila tanggal gajian tidak tetap

  // Screen 4 — Fixed expenses
  final List<FixedBill> bills = <FixedBill>[];

  // Screen 5 — Savings
  int savingsTarget = 0;

  bool isSubmitting = false;
  String? submitError;

  int _billSeq = 0;

  PlanPreview get preview => PlanPreview(
        netIncome: netIncome,
        fixedBillsTotal: fixedBillsTotal,
        savingsTarget: savingsTarget,
      );

  int get fixedBillsTotal =>
      bills.where((b) => b.active).fold(0, (sum, b) => sum + b.amount);

  SalaryCycle? get cyclePreview {
    if (step == OnboardingStep.welcome) return null;
    final today = DateTime.now();
    final start = paydayOnOrBefore(today, paydayDay);
    DateTime? next;
    final chosen = nextPayday;
    if (chosen != null) {
      final normalized = DateTime(chosen.year, chosen.month, chosen.day);
      if (normalized.isAfter(start)) next = normalized;
    }
    return SalaryCycle.between(
      start: start,
      nextStart: next,
      paydayDay: paydayDay,
    );
  }

  // ---------------------------------------------------------------- flow --

  void goTo(OnboardingStep next) {
    step = next;
    notifyListeners();
  }

  void goBack() {
    final values = OnboardingStep.values;
    final i = values.indexOf(step);
    if (i > 0) {
      step = values[i - 1];
      notifyListeners();
    }
  }

  /// Ulangi onboarding dari awal; data yang sudah terisi dipertahankan
  /// sehingga pengguna bisa meninjau, bukan mengisi ulang.
  void restart() {
    step = OnboardingStep.welcome;
    submitError = null;
    isSubmitting = false;
    notifyListeners();
  }

  void setPaydayDay(int day) {
    if (day < 1 || day > 31) return;
    paydayDay = day;
    notifyListeners();
  }

  void setNextPayday(DateTime? date) {
    nextPayday = date;
    notifyListeners();
  }

  // --------------------------------------------------------------- bills --

  void addBill() {
    bills.add(FixedBill(id: 'bill-${++_billSeq}'));
    notifyListeners();
  }

  void updateBill(String id, {String? name, int? amount, int? dueDay, bool? active}) {
    final i = bills.indexWhere((b) => b.id == id);
    if (i == -1) return;
    bills[i] = bills[i].copyWith(
      name: name,
      amount: amount,
      dueDay: dueDay,
      active: active,
    );
    notifyListeners();
  }

  void removeBill(String id) {
    bills.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  // ------------------------------------------------------------- submit ---

  /// Konfigurasi onboarding dalam bentuk domain [Plan].
  Plan buildPlan() => Plan(
        netIncome: netIncome,
        paydayDay: paydayDay,
        nextPayday: nextPayday,
        bills: List.unmodifiable(bills),
        savingsTarget: savingsTarget,
      );

  /// Simulasi penyimpanan konfigurasi onboarding + pembuatan salary cycle.
  /// Bila gagal, seluruh input form dipertahankan.
  Future<bool> submitPlan() async {
    if (isSubmitting) return false;
    isSubmitting = true;
    submitError = null;
    notifyListeners();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return true;
    } catch (_) {
      submitError = 'Belum berhasil menyimpan. Coba lagi.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
