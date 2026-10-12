import '../../core/calc/cycle_transactions.dart';
import '../../core/calc/financial_summary.dart';
import '../../core/calc/salary_cycle.dart';
import '../../core/models/plan.dart';

/// Cakupan daftar transaksi di layar: siklus berjalan atau seluruh riwayat.
enum TransactionScope { cycle, all }

/// ViewModel layar Transaksi — seluruh nilai berasal dari
/// [FinancialSummary] dan perhitungan siklus; UI tidak menghitung sendiri.
class TransactionsData {
  const TransactionsData({
    required this.plan,
    required this.cycle,
    required this.summary,
    required this.transactions,
    this.scope = TransactionScope.cycle,
    this.period,
    this.availablePeriods = const [],
  });

  factory TransactionsData.fromInputs({
    required Plan plan,
    required List<ExpenseTransaction> transactions,
    required DateTime today,
    TransactionScope scope = TransactionScope.cycle,
    SalaryCycle? period,
  }) {
    final cycle = plan.cycleFor(today);
    final cycleTx = flexibleTransactionsIn(transactions, cycle);
    final summary = FinancialSummary.compute(
      netIncome: plan.netIncome,
      fixedBillsUnpaid: plan.activeBillsTotal,
      savingsTargetUnfunded: plan.savingsTarget,
      safetyBuffer: plan.safetyBuffer,
      discretionarySpent: cycleTx.fold(0, (sum, t) => sum + t.amount),
      cycle: cycle,
      today: today,
      isEstimate: cycleTx.isEmpty,
    );

    final availablePeriods = _availablePeriods(plan, transactions, today);
    final activeCycle = period ?? cycle;
    final visible = scope == TransactionScope.all
        ? transactions
        : transactionsInCycle(transactions, activeCycle);
    final sorted = [...visible]..sort((a, b) => b.date.compareTo(a.date));

    return TransactionsData(
      plan: plan,
      cycle: cycle,
      summary: summary,
      transactions: sorted,
      scope: scope,
      period: period,
      availablePeriods: availablePeriods,
    );
  }

  /// Siklus unik dari seluruh transaksi, ditambah siklus berjalan, diurutkan
  /// dari yang terbaru (filter periode, PRD 7.2).
  static List<SalaryCycle> _availablePeriods(
    Plan plan,
    List<ExpenseTransaction> transactions,
    DateTime today,
  ) {
    final starts = <DateTime>{plan.cycleFor(today).start};
    for (final t in transactions) {
      starts.add(plan.cycleFor(t.date).start);
    }
    final sorted = starts.toList()..sort((a, b) => b.compareTo(a));
    return [for (final start in sorted) plan.cycleFor(start)];
  }

  final Plan plan;
  final SalaryCycle cycle;
  final FinancialSummary summary;

  /// Cakupan yang ditampilkan; angka pada kartu mengikuti cakupan ini
  /// kecuali angka "siklus ini" (selalu siklus berjalan).
  final TransactionScope scope;

  /// Periode siklus terpilih saat [scope] == cycle; null = siklus berjalan.
  final SalaryCycle? period;

  /// Semua periode yang bisa dipilih di filter, terbaru lebih dulu.
  final List<SalaryCycle> availablePeriods;

  /// Transaksi pada cakupan terpilih (pengeluaran + pemasukan),
  /// terbaru di atas.
  final List<ExpenseTransaction> transactions;

  bool get isEmpty => transactions.isEmpty;

  /// Siklus yang sedang ditampilkan pada cakupan siklus.
  SalaryCycle get activeCycle => period ?? cycle;

  /// True bila [scope] menampilkan seluruh riwayat.
  bool get isAllScope => scope == TransactionScope.all;

  /// True bila periode terpilih adalah siklus berjalan.
  bool get isCurrentPeriod => period == null || period!.start == cycle.start;

  /// Label periode untuk judul kartu ringkasan.
  String get periodLabel {
    if (isAllScope) return 'semua waktu';
    if (isCurrentPeriod) return 'siklus ini';
    return activeCycle.label;
  }

  /// Total terpakai terhadap anggaran fleksibel siklus.
  int get totalSpent => summary.discretionarySpent;

  /// Total pemasukan tercatat pada cakupan terpilih.
  int get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  /// Total pengeluaran tercatat pada cakupan terpilih.
  int get totalExpense => transactions
      .where((t) => !t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  /// Saldo pada cakupan terpilih: pemasukan − pengeluaran.
  /// Bisa negatif bila pengeluaran melebihi pemasukan.
  int get balance => totalIncome - totalExpense;

  /// Sisa anggaran fleksibel; tidak pernah negatif.
  int get remainingFlexible => summary.remainingFlexible;

  String get cycleLabel => cycle.label;
}