import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/core/calc/financial_summary.dart';
import 'package:sampai_app/core/calc/salary_cycle.dart';

void main() {
  SalaryCycle cycle(int startDay) => SalaryCycle(
        start: DateTime(2026, 9, startDay),
        end: DateTime(2026, 10, 24),
      );

  FinancialSummary summary({
    int netIncome = 8000000,
    int bills = 2800000,
    int savings = 1000000,
    int buffer = 0,
    int spent = 0,
    int income = 0,
    DateTime? today,
    int startDay = 25,
    bool estimate = false,
  }) =>
      FinancialSummary.compute(
        netIncome: netIncome,
        fixedBillsUnpaid: bills,
        savingsTargetUnfunded: savings,
        safetyBuffer: buffer,
        discretionarySpent: spent,
        cycle: cycle(startDay),
        today: today ?? DateTime(2026, 10, 8),
        recordedIncome: income,
        isEstimate: estimate,
      );

  test('budget fleksibel mengikuti PRD 8.2', () {
    final s = summary();
    expect(s.discretionaryBudget, 4200000);
    expect(s.hasPlanDeficit, isFalse);
  });

  test('defisit rencana tidak menjadi budget negatif', () {
    final s = summary(bills: 7000000, savings: 2000000);
    expect(s.discretionaryBudget, -1000000);
    expect(s.hasPlanDeficit, isTrue);
    expect(s.remainingFlexible, 0);
    expect(s.safeToSpendPerDay, 0);
  });

  test('safe-to-spend memakai rumus PRD 8.6', () {
    final s = summary(spent: 2730000);
    expect(s.remainingFlexible, 1470000);
    expect(s.remainingDays, 17); // 8 Okt → 24 Okt inklusif
    expect(s.safeToSpendPerDay, 1470000 ~/ 17);
  });

  test('remainingDays 0 tidak membagi nol', () {
    final s = summary(today: DateTime(2026, 10, 25), spent: 4200000);
    expect(s.cycleEndsToday, isTrue);
    expect(s.safeToSpendPerDay, 0);
    expect(s.remainingFlexible, 0);
    expect(s.isCritical, isTrue);
  });

  test('money velocity mengikuti PRD 8.4', () {
    final s = summary(spent: 2730000);
    expect(s.timeProgress!, closeTo(0.4667, 0.001));
    expect(s.spendingProgress!, closeTo(0.65, 0.001));
    expect(s.moneyVelocity!, closeTo(1.39, 0.01));
    expect(s.isSpendingTooFast, isTrue);
  });

  test('money velocity tidak membagi nol', () {
    final early = summary(today: DateTime(2026, 9, 20));
    expect(early.timeProgress, 0);
    expect(early.moneyVelocity, isNull);
    expect(
      early.velocityUnavailableReason,
      'Mulai dihitung setelah siklus berjalan.',
    );

    final zeroBudget = summary(bills: 7000000, savings: 1000000);
    expect(zeroBudget.discretionaryBudget, 0);
    expect(zeroBudget.moneyVelocity, isNull);
    expect(
      zeroBudget.velocityUnavailableReason,
      'Atur anggaran fleksibel untuk melihat Money Velocity.',
    );
  });

  test('pemasukan menambah sisa uang, bukan anggaran fleksibel', () {
    final base = summary(spent: 2730000);
    final withIncome = summary(spent: 2730000, income: 2000000);

    // Uang aman dibelanjakan bertambah tepat sebesar pemasukan.
    expect(withIncome.remainingSpendable, base.remainingSpendable + 2000000);
    expect(withIncome.safeToSpendPerDay, withIncome.remainingSpendable ~/ 17);

    // Anggaran fleksibel & Money Velocity tidak terpengaruh pemasukan.
    expect(withIncome.discretionaryBudget, base.discretionaryBudget);
    expect(withIncome.remainingFlexible, base.remainingFlexible);
    expect(withIncome.moneyVelocity, base.moneyVelocity);
  });

  test('pemasukan mengangkat status kritis tanpa mengubah anggaran', () {
    final spentOut = summary(spent: 4200000);
    expect(spentOut.isCritical, isTrue);
    expect(spentOut.remainingFlexible, 0);

    final withIncome = summary(spent: 4200000, income: 500000);
    expect(withIncome.remainingFlexible, 0);
    expect(withIncome.remainingSpendable, 500000);
    expect(withIncome.isCritical, isFalse);
  });

  test('pemasukan tidak menutupi lebih dari pengeluaran berlebih', () {
    // 4.2jt budget, 5jt terpakai (−0.8jt), pemasukan 2jt → sisa uang 1.2jt.
    final s = summary(spent: 5000000, income: 2000000);
    expect(s.remainingSpendable, 1200000);
  });

  test('format gaya Indonesia', () {
    expect(formatRatio(1.625), '1,63×');
    expect(formatPercent(0.4), '40%');
  });
}
