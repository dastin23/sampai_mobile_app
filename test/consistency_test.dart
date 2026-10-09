import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/core/calc/cycle_transactions.dart';
import 'package:sampai_app/core/calc/financial_summary.dart';
import 'package:sampai_app/core/calc/salary_cycle.dart';
import 'package:sampai_app/core/models/plan.dart';

/// Verifikasi acceptance "Konsistensi finansial" (PRD §12):
/// tagihan & transaksi tidak dihitung dua kali, tabungan terdana tidak
/// dihitung ulang, Money Velocity & Safe-to-Spend tidak membagi nol,
/// Safe-to-Spend tidak negatif, dan tanggal memakai aturan siklus lokal.
void main() {
  final cycle = SalaryCycle(
    start: DateTime(2026, 9, 25),
    end: DateTime(2026, 10, 24),
  );

  ExpenseTransaction tx(
    String id, {
    String category = 'Makan',
    int amount = 75000,
    bool flexible = true,
    DateTime? date,
  }) =>
      ExpenseTransaction(
        id: id,
        title: id,
        category: category,
        amount: amount,
        date: date ?? DateTime(2026, 10, 8),
        countsTowardFlexibleBudget: flexible,
      );

  test('tagihan dikurangi tepat satu kali dari anggaran fleksibel', () {
    // PRD 8.2: fleksibel = gaji − tagihan − tabungan − buffer.
    final summary = FinancialSummary.compute(
      netIncome: 8000000,
      fixedBillsUnpaid: 2800000,
      savingsTargetUnfunded: 1000000,
      safetyBuffer: 0,
      discretionarySpent: 0,
      cycle: cycle,
      today: cycle.start.add(const Duration(days: 1)),
    );
    expect(summary.discretionaryBudget, 4200000);

    // Tambah transaksi fleksibel → berkurang TEPAT sesuai jumlahnya.
    final after = FinancialSummary.compute(
      netIncome: 8000000,
      fixedBillsUnpaid: 2800000,
      savingsTargetUnfunded: 1000000,
      safetyBuffer: 0,
      discretionarySpent: 75000,
      cycle: cycle,
      today: cycle.start.add(const Duration(days: 1)),
    );
    expect(after.remainingFlexible, summary.discretionaryBudget - 75000);

    // Tagihan tidak memunculkan "sisa" tambahan maupun pengurangan ganda.
    expect(after.reservedUnpaidBills, 2800000);
  });

  test('transaksi non-fleksibel tidak ikut terpakai (PRD 8.5)', () {
    // Transfer antar-akun / di luar fleksibel tidak boleh mengurangi budget.
    final transactions = [
      tx('flex-1', amount: 50000),
      tx('transfer-1', amount: 1000000, flexible: false),
      tx(
        'transfer-2',
        amount: 250000,
        flexible: false,
        date: DateTime(2026, 10, 1),
      ),
    ];
    expect(discretionarySpent(transactions, cycle), 50000);
    expect(
      flexibleTransactionsIn(transactions, cycle).map((t) => t.id),
      ['flex-1'],
    );
  });

  test('tabungan yang sudah didanai tidak dihitung ulang', () {
    // Parameter calc memakai target yang BELUM didanai (PRD 8.5).
    final belumTerdana = FinancialSummary.compute(
      netIncome: 8000000,
      fixedBillsUnpaid: 2800000,
      savingsTargetUnfunded: 1000000,
      safetyBuffer: 0,
      discretionarySpent: 0,
      cycle: cycle,
      today: cycle.start.add(const Duration(days: 1)),
    );
    final sudahTerdana = FinancialSummary.compute(
      netIncome: 8000000,
      fixedBillsUnpaid: 2800000,
      savingsTargetUnfunded: 0,
      safetyBuffer: 0,
      discretionarySpent: 0,
      cycle: cycle,
      today: cycle.start.add(const Duration(days: 1)),
    );
    expect(belumTerdana.discretionaryBudget, 4200000);
    // Begitu terdana, dana boleh dipakai: budget menjadi 5.200.000.
    expect(sudahTerdana.discretionaryBudget, 5200000);
    expect(sudahTerdana.unfundedSavingsTarget, 0);
  });

  test('safe-to-spend tidak pernah negatif saat pengeluaran > anggaran', () {
    final summary = FinancialSummary.compute(
      netIncome: 8000000,
      fixedBillsUnpaid: 2800000,
      savingsTargetUnfunded: 1000000,
      safetyBuffer: 0,
      discretionarySpent: 5000000,
      cycle: cycle,
      today: DateTime(2026, 10, 8),
    );
    expect(summary.spendingProgress!, greaterThan(1));
    expect(summary.remainingFlexible, 0);
    expect(summary.safeToSpendPerDay, 0);
    expect(summary.isCritical, isTrue);
  });

  test('money velocity tidak membagi nol pada hari/siklus valid', () {
    // Sebelum siklus dimulai: waktu berlalu 0 → velocity null, bukan infinity.
    final beforeCycle = FinancialSummary.compute(
      netIncome: 8000000,
      fixedBillsUnpaid: 2800000,
      savingsTargetUnfunded: 1000000,
      safetyBuffer: 0,
      discretionarySpent: 0,
      cycle: cycle,
      today: DateTime(2026, 9, 20),
    );
    expect(beforeCycle.timeProgress, 0);
    expect(beforeCycle.moneyVelocity, isNull);
    expect(beforeCycle.safeToSpendPerDay, greaterThan(0));

    // Daya tampung siklus penuh: total > 0, velocity terdefinisi.
    final later = FinancialSummary.compute(
      netIncome: 8000000,
      fixedBillsUnpaid: 2800000,
      savingsTargetUnfunded: 1000000,
      safetyBuffer: 0,
      discretionarySpent: 4200000,
      cycle: cycle,
      today: DateTime(2026, 10, 24),
    );
    expect(later.totalDays, greaterThan(0));
    expect(later.moneyVelocity, isNotNull);
    expect(later.remainingFlexible, 0);
  });

  test('siklus memakai tanggal lokal dengan batas inklusif', () {
    // 25 Sep termasuk hari pertama; 24 Okt hari terakhir.
    expect(cycle.start, DateTime(2026, 9, 25));
    expect(cycle.end, DateTime(2026, 10, 24));
    expect(cycle.elapsedDays(DateTime(2026, 9, 25)), 1);
    expect(cycle.totalDays, 30); // 25 Sep–24 Okt = 30 hari.
    expect(cycle.remainingDays(DateTime(2026, 10, 24)), 1); // hari terakhir
    expect(cycle.remainingDays(DateTime(2026, 10, 25)), 0); // selesai

    // Tanggal di luar siklus dianggap tidak transaksi siklus (inklusif).
    final inCycle = DateTime(2026, 9, 25);
    final outCycle = DateTime(2026, 10, 25);
    final flexible = [
      tx('a', date: inCycle),
      tx('b', date: outCycle),
    ];
    expect(flexibleTransactionsIn(flexible, cycle).length, 1);
  });
}