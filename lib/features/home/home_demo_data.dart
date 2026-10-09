import '../../core/models/plan.dart';
import 'home_data.dart';

/// Dataset contoh mode desain (PRD 5.3 — hanya untuk pratinjau state,
/// bukan data produksi). Semua angka dihitung ulang oleh formula yang sama.
Plan demoPlan(DateTime today) {
  final anchor = DateTime(today.year, today.month, today.day - 12);
  return Plan(
    netIncome: 8000000,
    paydayDay: anchor.day,
    nextPayday: null,
    savingsTarget: 1000000,
    bills: [
      FixedBill(id: 'demo-1', name: 'Kos', amount: 1500000, dueDay: 1),
      FixedBill(id: 'demo-2', name: 'Transportasi', amount: 500000, dueDay: 25),
      FixedBill(id: 'demo-3', name: 'Internet & pulsa', amount: 300000, dueDay: 10),
      FixedBill(id: 'demo-4', name: 'Langganan', amount: 100000, dueDay: 12),
      FixedBill(id: 'demo-5', name: 'Lainnya', amount: 400000, dueDay: 15),
    ],
  );
}

List<BudgetCategory> demoBudgets() => const [
      BudgetCategory(category: 'Makan', limit: 1200000),
      BudgetCategory(category: 'Transportasi', limit: 600000),
      BudgetCategory(category: 'Hiburan', limit: 400000),
      BudgetCategory(category: 'Belanja', limit: 700000),
      BudgetCategory(category: 'Lainnya', limit: 1300000),
    ];

ExpenseTransaction _tx(
  DateTime today,
  int offsetDays,
  String title,
  String category,
  int amount,
) =>
    ExpenseTransaction(
      id: 'demo-tx-$offsetDays-$title',
      title: title,
      category: category,
      amount: amount,
      date: DateTime(today.year, today.month, today.day - offsetDays),
    );

/// Total Rp2.730.000 — per kategori sama dengan budget contoh (PRD 7.2).
List<ExpenseTransaction> demoTransactions(DateTime today) => [
      _tx(today, 0, 'Warung makan', 'Makan', 250000),
      _tx(today, 1, 'Makan siang kantor', 'Makan', 180000),
      _tx(today, 2, 'Belanja bahan makanan', 'Makan', 300000),
      _tx(today, 4, 'Gorengan sore', 'Makan', 65000),
      _tx(today, 6, 'Bakso malam', 'Makan', 105000),
      _tx(today, 2, 'Bensin', 'Transportasi', 150000),
      _tx(today, 5, 'Ojek online', 'Transportasi', 75000),
      _tx(today, 8, 'Parkir & tol', 'Transportasi', 125000),
      _tx(today, 7, 'Nonton bioskop', 'Hiburan', 150000),
      _tx(today, 10, 'Langganan musik', 'Hiburan', 100000),
      _tx(today, 9, 'Baju kerja', 'Belanja', 300000),
      _tx(today, 11, 'Peralatan rumah', 'Belanja', 200000),
      _tx(today, 10, 'Hadiah ulang tahun', 'Lainnya', 400000),
      _tx(today, 11, 'Keperluan pribadi', 'Lainnya', 330000),
    ];

/// HomeData contoh: pengeluaran lebih cepat dari waktu siklus (velocity > 1).
HomeData demoWarningHome({required DateTime today, required bool offline}) =>
    HomeData.fromInputs(
      plan: demoPlan(today),
      transactions: demoTransactions(today),
      budgets: demoBudgets(),
      today: today,
      offline: offline,
      updatedAt: today,
      isDemo: true,
    );

/// HomeData contoh: seluruh anggaran fleksibel terpakai → Safe-to-Spend 0.
HomeData demoCriticalHome({required DateTime today}) {
  final transactions = [
    ...demoTransactions(today),
    _tx(today, 3, 'Pengeluaran besar', 'Lainnya', 1470000),
  ];
  return HomeData.fromInputs(
    plan: demoPlan(today),
    transactions: transactions,
    budgets: demoBudgets(),
    today: today,
    offline: false,
    updatedAt: today,
    isDemo: true,
  );
}
