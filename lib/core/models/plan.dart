import '../calc/salary_cycle.dart';

/// Tagihan tetap per siklus (dipakai onboarding dan Home).
class FixedBill {
  FixedBill({
    required this.id,
    this.name = '',
    this.amount = 0,
    this.dueDay = 1,
    this.active = true,
  });

  final String id;
  String name;
  int amount;
  int dueDay;
  bool active;

  FixedBill copyWith({String? name, int? amount, int? dueDay, bool? active}) =>
      FixedBill(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        dueDay: dueDay ?? this.dueDay,
        active: active ?? this.active,
      );
}

/// Konfigurasi finansial hasil onboarding.
class Plan {
  const Plan({
    required this.netIncome,
    required this.paydayDay,
    required this.nextPayday,
    required this.bills,
    required this.savingsTarget,
    this.safetyBuffer = 0,
  });

  final int netIncome;
  final int paydayDay;
  final DateTime? nextPayday;
  final List<FixedBill> bills;
  final int savingsTarget;
  final int safetyBuffer;

  List<FixedBill> get activeBills =>
      bills.where((b) => b.active && b.amount > 0).toList();

  int get activeBillsTotal =>
      activeBills.fold(0, (sum, b) => sum + b.amount);

  SalaryCycle cycleFor(DateTime today) {
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
}

class ExpenseTransaction {
  const ExpenseTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.countsTowardFlexibleBudget = true,
    this.isIncome = false,
  });

  /// Transaksi pemasukan: tidak pernah dihitung ke anggaran fleksibel
  /// maupun pemakaian kategori.
  const ExpenseTransaction.income({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  })  : countsTowardFlexibleBudget = false,
        isIncome = true;

  final String id;
  final String title;
  final String category;
  final int amount;
  final DateTime date;

  /// Pengeluaran yang dikecualikan dari anggaran fleksibel
  /// (mis. transfer) harus bernilai false — PRD 8.5.
  final bool countsTowardFlexibleBudget;

  /// True untuk transaksi pemasukan (gaji tambahan, bonus, dll).
  final bool isIncome;
}

/// Alokasi batas kategori (diubah lewat layar Budget).
class BudgetCategory {
  const BudgetCategory({required this.category, required this.limit});

  final String category;
  final int limit;
}

/// Pemakaian kategori hasil hitung dari transaksi — PRD 7.2.
class BudgetUsage {
  const BudgetUsage({
    required this.category,
    required this.spent,
    required this.limit,
  });

  /// Ambang "mendekati batas" (PRD 7.3) — default 80%, dapat dikonfigurasi.
  static double nearLimitThreshold = 0.8;

  final String category;
  final int spent;
  final int limit;

  /// null bila anggaran kategori 0; UI wajib menangani nol sendiri.
  double? get progress => limit <= 0 ? null : spent / limit;

  int get remaining => limit - spent;

  bool get isOver => spent > limit;

  int get overAmount => isOver ? spent - limit : 0;

  bool get isNearLimit =>
      !isOver && limit > 0 && spent / limit >= nearLimitThreshold;

  double get progressClamped => (progress ?? 0).clamp(0, 1).toDouble();
}
