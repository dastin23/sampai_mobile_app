import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/app/state/app_providers.dart';
import 'package:sampai_app/core/models/plan.dart';
import 'package:sampai_app/core/state/app_state.dart';
import 'package:sampai_app/core/theme/app_theme.dart';
import 'package:sampai_app/features/home/home_demo_data.dart';
import 'package:sampai_app/features/shell/app_shell.dart';
import 'package:sampai_app/features/transactions/models/transaction_model.dart';
import 'package:sampai_app/features/transactions/providers/transaction_providers.dart';
import 'package:sampai_app/features/transactions/transactions_data.dart';

import 'helpers/fake_transaction_repository.dart';

void main() {
  late AppState state;
  late FakeTransactionRepository repository;

  setUp(() {
    state = AppState()
      ..applyPlan(demoPlan(DateTime.now()))
      ..replaceBudgets(demoBudgets());
    repository = FakeTransactionRepository();
  });

  tearDown(() => state.dispose());

  void useDesignFrame(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStateProvider.overrideWithValue(state),
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: AppShell(appState: state, onRestartOnboarding: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  Future<void> goToTransactions(WidgetTester tester) async {
    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
  }

  Future<void> saveExpense(
    WidgetTester tester, {
    required String amount,
    required String category,
    required String note,
  }) async {
    await tester.tap(find.text('Catat pengeluaran'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), amount);
    await tester.pump();
    await tester.tap(find.text(category));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), note);
    await tester.pump();
    await tester.tap(find.text('Simpan pengeluaran'));
    await tester.pumpAndSettle();
  }

  testWidgets('daftar transaksi menampilkan ringkasan dan baris siklus',
      (tester) async {
    useDesignFrame(tester);
    repository.transactions.add(
      financeTransaction(
        id: 'tx-1',
        type: 'expense',
        amount: 250000,
        date: DateTime.now(),
        categoryId: 'cat-makanan',
        categoryName: 'Makanan',
        description: 'Warung makan',
      ),
    );
    await pumpApp(tester);
    await goToTransactions(tester);

    expect(find.text('Saldo siklus ini'), findsOneWidget);
    expect(find.text('-Rp250.000'), findsOneWidget);
    expect(find.text('Terpakai siklus ini Rp250.000'), findsOneWidget);
    expect(find.text('Sisa anggaran fleksibel Rp3.950.000'), findsOneWidget);
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('+Rp0'), findsOneWidget);
    expect(find.text('Warung makan'), findsOneWidget);
    // Kartu ringkasan + baris transaksi.
    expect(find.text('−Rp250.000'), findsNWidgets(2));
    expect(find.text('Semua transaksi'), findsOneWidget);
    expect(find.text('Siklus ini'), findsOneWidget);
  });

  testWidgets('daftar kosong menampilkan empty state dan CTA', (tester) async {
    useDesignFrame(tester);
    await pumpApp(tester);
    await goToTransactions(tester);

    expect(find.text('Belum ada transaksi di siklus ini'), findsOneWidget);
    expect(find.text('Catat pengeluaran pertama'), findsOneWidget);
    expect(find.text('Semua transaksi'), findsOneWidget);
  });

  testWidgets('menambah pengeluaran dari tab Transaksi memperbarui daftar',
      (tester) async {
    useDesignFrame(tester);
    await pumpApp(tester);
    await goToTransactions(tester);

    await saveExpense(
      tester,
      amount: '75000',
      category: 'Makanan',
      note: 'Jajan kopi',
    );

    expect(find.text('Pengeluaran tersimpan'), findsOneWidget);
    expect(find.text('Sisa anggaran fleksibel Rp4.125.000'), findsOneWidget);
    expect(find.text('Terpakai siklus ini Rp75.000'), findsOneWidget);
    expect(find.text('Jajan kopi'), findsOneWidget);
    expect(find.text('−Rp75.000'), findsNWidgets(2));
    // Tersimpan di repository.
    expect(repository.transactions.single.amount, 75000);
    expect(repository.transactions.single.categoryId, 'cat-makanan');
  });

  testWidgets('saldo dihitung dari pemasukan dan pengeluaran di database',
      (tester) async {
    useDesignFrame(tester);
    repository.transactions.addAll([
      financeTransaction(
        id: 'in-1',
        type: 'income',
        amount: 2000000,
        date: DateTime.now(),
        categoryId: 'cat-gaji',
        categoryName: 'Gaji',
        description: 'Gaji tambahan',
      ),
      financeTransaction(
        id: 'out-1',
        type: 'expense',
        amount: 250000,
        date: DateTime.now(),
        categoryId: 'cat-makanan',
        categoryName: 'Makanan',
        description: 'Warung makan',
      ),
    ]);
    await pumpApp(tester);
    await goToTransactions(tester);

    expect(find.text('Gaji tambahan'), findsOneWidget);
    expect(find.text('+Rp2.000.000'), findsNWidgets(2));
    expect(find.text('Saldo siklus ini'), findsOneWidget);
    expect(find.text('Rp1.750.000'), findsOneWidget);
  });

  testWidgets('menyunting transaksi lewat tap baris', (tester) async {
    useDesignFrame(tester);
    repository.transactions.add(
      financeTransaction(
        id: 'tx-1',
        type: 'expense',
        amount: 250000,
        date: DateTime.now(),
        categoryId: 'cat-makanan',
        categoryName: 'Makanan',
        description: 'Warung makan',
      ),
    );
    await pumpApp(tester);
    await goToTransactions(tester);

    await tester.tap(find.text('Warung makan'));
    await tester.pumpAndSettle();

    expect(find.text('Ubah pengeluaran'), findsOneWidget);
    expect(find.text('Rp250.000'), findsOneWidget);
    expect(find.text('Simpan perubahan'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '300000');
    await tester.pump();
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Pengeluaran diperbarui'), findsOneWidget);
    expect(find.text('Warung makan'), findsOneWidget);
    expect(find.text('−Rp300.000'), findsNWidgets(2));
    expect(find.text('Terpakai siklus ini Rp300.000'), findsOneWidget);
  });

  testWidgets('menghapus transaksi lewat sheet sunting', (tester) async {
    useDesignFrame(tester);
    repository.transactions.add(
      financeTransaction(
        id: 'tx-1',
        type: 'expense',
        amount: 250000,
        date: DateTime.now(),
        categoryId: 'cat-makanan',
        categoryName: 'Makanan',
        description: 'Warung makan',
      ),
    );
    await pumpApp(tester);
    await goToTransactions(tester);

    await tester.tap(find.text('Warung makan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hapus transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus pengeluaran ini?'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Pengeluaran dihapus'), findsOneWidget);
    expect(find.text('Warung makan'), findsNothing);
    expect(find.text('Belum ada transaksi di siklus ini'), findsOneWidget);
  });

  testWidgets('toggle Semua transaksi menampilkan riwayat lintas siklus',
      (tester) async {
    useDesignFrame(tester);
    final now = DateTime.now();
    repository.transactions.addAll([
      financeTransaction(
        id: 'now-1',
        type: 'expense',
        amount: 250000,
        date: now,
        categoryId: 'cat-makanan',
        categoryName: 'Makanan',
        description: 'Warung makan',
      ),
      financeTransaction(
        id: 'old-1',
        type: 'expense',
        amount: 123000,
        date: DateTime(now.year, now.month, now.day - 40),
        categoryId: 'cat-belanja',
        categoryName: 'Belanja',
        description: 'Belanja lama',
      ),
    ]);
    await pumpApp(tester);
    await goToTransactions(tester);

    expect(find.text('Belanja lama'), findsNothing);
    expect(find.text('Warung makan'), findsOneWidget);

    await tester.tap(find.text('Semua transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('Belanja lama'), findsOneWidget);
    expect(find.text('Saldo semua waktu'), findsOneWidget);
  });

  testWidgets('filter periode menampilkan siklus lampau', (tester) async {
    useDesignFrame(tester);
    final now = DateTime.now();
    final plan = demoPlan(now);
    final pastDate = DateTime(now.year, now.month, now.day - 40);
    final pastCycle = plan.cycleFor(pastDate);
    repository.transactions.addAll([
      financeTransaction(
        id: 'now-1',
        type: 'expense',
        amount: 250000,
        date: now,
        categoryId: 'cat-makanan',
        categoryName: 'Makanan',
        description: 'Warung makan',
      ),
      financeTransaction(
        id: 'old-1',
        type: 'expense',
        amount: 123000,
        date: pastDate,
        categoryId: 'cat-belanja',
        categoryName: 'Belanja',
        description: 'Belanja lama',
      ),
    ]);
    await pumpApp(tester);
    await goToTransactions(tester);

    expect(find.text('Belanja lama'), findsNothing);

    final chip = find.text(pastCycle.label);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(find.text('Belanja lama'), findsOneWidget);
    expect(find.text('Warung makan'), findsNothing);
    expect(find.text('Saldo ${pastCycle.label}'), findsOneWidget);

    // Kembali ke siklus berjalan.
    await tester.ensureVisible(find.text('Siklus ini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siklus ini'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo siklus ini'), findsOneWidget);
    expect(find.text('Warung makan'), findsOneWidget);
  });

  test('TransactionsData menghitung saldo dari pemasukan dan pengeluaran', () {
    final now = DateTime.now();
    final data = TransactionsData.fromInputs(
      plan: demoPlan(now),
      transactions: [
        ExpenseTransaction.income(
          id: 'i',
          title: 'Bonus',
          category: 'Bonus',
          amount: 1000000,
          date: now,
        ),
        ExpenseTransaction(
          id: 'e',
          title: 'Makan',
          category: 'Makan',
          amount: 250000,
          date: now,
        ),
      ],
      today: now,
    );

    expect(data.totalIncome, 1000000);
    expect(data.totalExpense, 250000);
    expect(data.balance, 750000);
  });

  test('TransactionsData memfilter per periode siklus', () {
    final now = DateTime.now();
    final plan = demoPlan(now);
    final pastDate = DateTime(now.year, now.month, now.day - 40);
    final pastCycle = plan.cycleFor(pastDate);
    final transactions = [
      ExpenseTransaction(
        id: 'now-1',
        title: 'Kini',
        category: 'Makan',
        amount: 100000,
        date: now,
      ),
      ExpenseTransaction(
        id: 'past-1',
        title: 'Lampau',
        category: 'Belanja',
        amount: 200000,
        date: pastDate,
      ),
    ];

    final current = TransactionsData.fromInputs(
      plan: plan,
      transactions: transactions,
      today: now,
    );
    expect(current.isAllScope, isFalse);
    expect(current.isCurrentPeriod, isTrue);
    expect(current.periodLabel, 'siklus ini');
    expect(current.transactions.single.title, 'Kini');
    expect(current.availablePeriods.length, 2);

    final past = TransactionsData.fromInputs(
      plan: plan,
      transactions: transactions,
      today: now,
      period: pastCycle,
    );
    expect(past.isCurrentPeriod, isFalse);
    expect(past.periodLabel, pastCycle.label);
    expect(past.transactions.single.title, 'Lampau');
    expect(past.balance, -200000);

    final all = TransactionsData.fromInputs(
      plan: plan,
      transactions: transactions,
      today: now,
      scope: TransactionScope.all,
    );
    expect(all.isAllScope, isTrue);
    expect(all.periodLabel, 'semua waktu');
    expect(all.transactions.length, 2);
  });

  test('AppState memperbarui dan menghapus transaksi', () {
    final localState = AppState()..applyPlan(demoPlan(DateTime.now()));
    addTearDown(localState.dispose);
    final t = ExpenseTransaction(
      id: 't1',
      title: 'A',
      category: 'Makan',
      amount: 1000,
      date: DateTime.now(),
    );
    localState.addTransaction(t);
    localState.updateTransaction(t.copyWith(amount: 5000, title: 'B'));
    expect(localState.transactions.single.amount, 5000);
    expect(localState.transactions.single.title, 'B');
    localState.deleteTransaction('t1');
    expect(localState.transactions, isEmpty);
  });
}

FinanceTransaction financeTransaction({
  required String id,
  required String type,
  required double amount,
  required DateTime date,
  String? categoryId,
  String? categoryName,
  String? description,
}) =>
    FinanceTransaction(
      id: id,
      userId: 'test-user',
      type: type,
      amount: amount,
      transactionDate: date,
      categoryId: categoryId,
      categoryName: categoryName,
      description: description,
    );
