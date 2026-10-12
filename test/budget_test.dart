import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/app/state/app_providers.dart';
import 'package:sampai_app/core/state/app_state.dart';
import 'package:sampai_app/core/theme/app_theme.dart';
import 'package:sampai_app/features/budget/budget_adapters.dart';
import 'package:sampai_app/features/budget/budget_screen.dart';
import 'package:sampai_app/features/budget/models/budget_model.dart';
import 'package:sampai_app/features/budget/providers/budget_providers.dart';
import 'package:sampai_app/features/home/home_demo_data.dart';
import 'package:sampai_app/features/shell/app_shell.dart';
import 'package:sampai_app/features/transactions/models/transaction_model.dart';
import 'package:sampai_app/features/transactions/providers/transaction_providers.dart';

import 'helpers/demo_seed.dart';
import 'helpers/fake_budget_repository.dart';
import 'helpers/fake_transaction_repository.dart';

void main() {
  late AppState state;
  late FakeTransactionRepository repository;
  late FakeBudgetRepository budgetRepository;
  final today = DateTime.now();

  setUp(() {
    state = AppState()..applyPlan(demoPlan(today));
    repository = seededTransactionRepository(today);
    budgetRepository = seededBudgetRepository(today);
  });

  tearDown(() => state.dispose());

  void useDesignFrame(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget wrap(
    AppState appState,
    FakeTransactionRepository txRepo,
    FakeBudgetRepository budgetRepo,
  ) =>
      ProviderScope(
        overrides: [
          appStateProvider.overrideWithValue(appState),
          transactionRepositoryProvider.overrideWithValue(txRepo),
          budgetRepositoryProvider.overrideWithValue(budgetRepo),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: AppShell(appState: appState, onRestartOnboarding: () {}),
        ),
      );

  Future<void> openBudget(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(app);
    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  Future<void> pumpBudget(WidgetTester tester) => openBudget(
        tester,
        wrap(state, repository, budgetRepository),
      );

  testWidgets('state normal menampilkan total, sisa, dan progress', (tester) async {
    useDesignFrame(tester);
    await pumpBudget(tester);

    expect(find.text('Anggaran'), findsOneWidget);
    expect(find.textContaining('Siklus'), findsOneWidget);
    expect(find.text('Anggaran fleksibel'), findsOneWidget);
    // 8.000.000 − 2.800.000 − 1.000.000 = 4.200.000
    expect(find.text('Rp4.200.000'), findsOneWidget);
    expect(find.text('Terpakai Rp2.730.000'), findsOneWidget);
    expect(find.text('Sisa Rp1.470.000'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Edit anggaran'), findsOneWidget);
    expect(find.text('Makan'), findsOneWidget);
    expect(find.text('Rp900.000 dari Rp1.200.000'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('detail kategori menampilkan anggaran dan transaksi', (tester) async {
    useDesignFrame(tester);
    await pumpBudget(tester);

    final makan = find.text('Makan');
    await tester.ensureVisible(makan);
    await tester.pumpAndSettle();
    await tester.tap(makan);
    await tester.pumpAndSettle();

    expect(find.text('Anggaran periode'), findsOneWidget);
    expect(find.text('Rp1.200.000'), findsOneWidget);
    expect(find.text('Total terpakai'), findsOneWidget);
    expect(find.text('Rp900.000'), findsOneWidget);
    expect(find.text('Sisa'), findsOneWidget);
    expect(find.text('Rp300.000'), findsOneWidget);
    expect(find.text('−Rp250.000'), findsOneWidget);
    expect(find.text('Ubah anggaran'), findsOneWidget);
  });

  testWidgets('mengubah anggaran memberi warning lalu konfirmasi', (tester) async {
    useDesignFrame(tester);
    await pumpBudget(tester);

    final makan = find.text('Makan');
    await tester.ensureVisible(makan);
    await tester.pumpAndSettle();
    await tester.tap(makan);
    await tester.pumpAndSettle();
    final editButton = find.text('Ubah anggaran');
    await tester.ensureVisible(editButton);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '1500000');
    await tester.pump();
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    // Total kategori 4.500.000 > anggaran fleksibel 4.200.000 → warning.
    expect(find.textContaining('melebihi anggaran fleksibel'), findsOneWidget);
    expect(find.text('Konfirmasi & simpan'), findsOneWidget);

    await tester.tap(find.text('Konfirmasi & simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Rp900.000 dari Rp1.500.000'), findsOneWidget);
    expect(find.text('Rp350.000 dari Rp600.000'), findsOneWidget);
  });

  testWidgets('edit memakai "Edit anggaran" menyimpan tanpa warning', (tester) async {
    useDesignFrame(tester);
    await pumpBudget(tester);

    await tester.tap(find.text('Edit anggaran'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan perubahan'), findsOneWidget);

    // Transportasi 600.000 → 500.000 → total 4.100.000 ≤ 4.200.000.
    final transportasi = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == '600000',
    );
    await tester.enterText(transportasi, '500000');
    await tester.pump();
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Rp350.000 dari Rp500.000'), findsOneWidget);
    expect(find.text('Rp900.000 dari Rp1.200.000'), findsOneWidget);
  });

  testWidgets('validasi menolak nilai tidak valid dan menyimpan draft',
      (tester) async {
    useDesignFrame(tester);
    await pumpBudget(tester);

    await tester.tap(find.text('Edit anggaran'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pump();
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Masukkan jumlah yang valid.'), findsOneWidget);
    // Draft tetap dipertahankan (PRD 7.3 error).
    expect(find.text('Simpan perubahan'), findsOneWidget);
  });

  testWidgets('state mendekati batas menampilkan label', (tester) async {
    useDesignFrame(tester);
    final month = activeBudgetMonth(demoPlan(today), today);
    final budgetRepo = FakeBudgetRepository(
      categories: demoTestCategories,
      budgets: [
        Budget(
          id: 'b1',
          userId: 'test-user',
          categoryId: 'cat-makan',
          month: month,
          amount: 1200000,
          categoryName: 'Makan',
        ),
      ],
    );
    final txRepo = FakeTransactionRepository(
      categories: demoTestCategories,
      transactions: [
        FinanceTransaction(
          id: 't1',
          userId: 'test-user',
          type: 'expense',
          amount: 1000000,
          transactionDate: today,
          categoryId: 'cat-makan',
          categoryName: 'Makan',
        ),
      ],
    );
    await openBudget(tester, wrap(state, txRepo, budgetRepo));

    expect(find.text('Mendekati batas'), findsOneWidget);
    expect(find.text('Rp1.000.000 dari Rp1.200.000'), findsOneWidget);
    expect(find.text('Kategori mendekati batas: 1'), findsOneWidget);
  });

  testWidgets('state melebihi anggaran menampilkan jumlah kelebihan', (tester) async {
    useDesignFrame(tester);
    final month = activeBudgetMonth(demoPlan(today), today);
    final budgetRepo = FakeBudgetRepository(
      categories: demoTestCategories,
      budgets: [
        Budget(
          id: 'b1',
          userId: 'test-user',
          categoryId: 'cat-makan',
          month: month,
          amount: 1000000,
          categoryName: 'Makan',
        ),
      ],
    );
    final txRepo = FakeTransactionRepository(
      categories: demoTestCategories,
      transactions: [
        FinanceTransaction(
          id: 't1',
          userId: 'test-user',
          type: 'expense',
          amount: 1100000,
          transactionDate: today,
          categoryId: 'cat-makan',
          categoryName: 'Makan',
        ),
      ],
    );
    await openBudget(tester, wrap(state, txRepo, budgetRepo));

    expect(find.text('Melebihi anggaran Rp100.000'), findsOneWidget);
    expect(find.text('Kategori melewati anggaran: 1'), findsOneWidget);
  });

  testWidgets('state error menyediakan coba lagi', (tester) async {
    useDesignFrame(tester);
    budgetRepository.failGet = true;
    await openBudget(tester, wrap(state, repository, budgetRepository));

    expect(find.text('Data belum bisa dimuat.'), findsOneWidget);

    budgetRepository.failGet = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Anggaran fleksibel'), findsOneWidget);
  });

  testWidgets('skeleton tampil saat memuat', (tester) async {
    useDesignFrame(tester);
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const BudgetSkeleton()),
    );
    expect(find.byType(BudgetSkeleton), findsOneWidget);
    expect(find.text('Anggaran fleksibel'), findsNothing);
  });

  testWidgets('membuat alokasi pertama dari state kosong', (tester) async {
    useDesignFrame(tester);
    final emptyState = AppState()..applyPlan(demoPlan(today));
    addTearDown(emptyState.dispose);
    final emptyBudgets = FakeBudgetRepository(categories: demoTestCategories);
    final emptyTransactions =
        FakeTransactionRepository(categories: demoTestCategories);
    await openBudget(
      tester,
      wrap(emptyState, emptyTransactions, emptyBudgets),
    );

    expect(find.text('Belum ada anggaran kategori.'), findsOneWidget);

    await tester.tap(find.text('Atur anggaran'));
    await tester.pumpAndSettle();
    // Kategori default dari design system.
    expect(find.text('Makan'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '500000');
    await tester.pump();
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Rp0 dari Rp500.000'), findsOneWidget);
    expect(find.text('Belum ada anggaran kategori.'), findsNothing);
  });
}
