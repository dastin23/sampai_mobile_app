import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/app/state/app_providers.dart';
import 'package:sampai_app/core/state/app_state.dart';
import 'package:sampai_app/core/theme/app_theme.dart';
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

  Widget wrap(Widget child, {AppState? appState}) => ProviderScope(
        overrides: [
          appStateProvider.overrideWithValue(appState ?? state),
          transactionRepositoryProvider.overrideWithValue(repository),
          budgetRepositoryProvider.overrideWithValue(budgetRepository),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: child),
      );

  Future<void> pumpHome(WidgetTester tester, {AppState? appState}) async {
    final target = appState ?? state;
    await tester.pumpWidget(
      wrap(AppShell(appState: target, onRestartOnboarding: () {}),
          appState: target),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  Future<void> scrollHomeTo(WidgetTester tester, String text) async {
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(text),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }
    if (find.text(text).evaluate().isNotEmpty) {
      await tester.ensureVisible(find.text(text));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('state normal menampilkan Safe-to-Spend, velocity, tagihan',
      (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);

    expect(find.text('Halo!'), findsOneWidget);
    expect(find.text('AMAN DIBELANJAKAN'), findsOneWidget);
    expect(find.textContaining('/hari'), findsOneWidget);
    expect(find.text('Money Velocity'), findsOneWidget);
    expect(find.text('Siklus berlalu'), findsOneWidget);
    expect(find.text('Anggaran terpakai'), findsOneWidget);
    expect(find.text('Catat pengeluaran'), findsOneWidget);
    // Data contoh sudah punya transaksi → tidak perlu label estimasi.
    expect(find.text('Estimasi'), findsNothing);

    await scrollHomeTo(tester, 'Ringkasan siklus ini');
    expect(find.text('Ringkasan siklus ini'), findsOneWidget);
    expect(find.text('Saldo siklus ini'), findsOneWidget);
    await scrollHomeTo(tester, 'Anggaran siklus ini');
    expect(find.text('Anggaran siklus ini'), findsOneWidget);
    await scrollHomeTo(tester, 'Tagihan terdekat');
    expect(find.text('Tagihan terdekat'), findsOneWidget);
    await scrollHomeTo(tester, 'Transaksi terbaru');
    expect(find.text('Transaksi terbaru'), findsOneWidget);
  });

  testWidgets('tombol avatar membuka tab Profil', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Buka profil'));
    await tester.pumpAndSettle();

    expect(find.text('Rencana finansial'), findsOneWidget);
  });

  testWidgets('state kosong mengarahkan ke pengaturan siklus', (tester) async {
    useDesignFrame(tester);
    final emptyState = AppState();
    addTearDown(emptyState.dispose);
    await pumpHome(tester, appState: emptyState);

    expect(
      find.text('Atur siklus gajimu untuk mulai menghitung.'),
      findsOneWidget,
    );
    expect(find.text('Selesaikan pengaturan'), findsOneWidget);
  });

  testWidgets('state error menyediakan coba lagi', (tester) async {
    useDesignFrame(tester);
    repository.failGet = true;
    await pumpHome(tester);

    expect(find.text('Data belum bisa dimuat.'), findsOneWidget);

    repository.failGet = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('AMAN DIBELANJAKAN'), findsOneWidget);
  });

  testWidgets('skeleton tampil saat memuat', (tester) async {
    useDesignFrame(tester);
    // Sebelum data async selesai → skeleton, bukan angka nol.
    await tester.pumpWidget(
      wrap(AppShell(appState: state, onRestartOnboarding: () {})),
    );
    expect(find.text('AMAN DIBELANJAKAN'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('AMAN DIBELANJAKAN'), findsOneWidget);
  });

  testWidgets('bottom navigation berpindah tab', (tester) async {
    useDesignFrame(tester);
    repository.transactions.add(
      FinanceTransaction(
        id: 'tx-1',
        userId: 'test-user',
        type: 'expense',
        amount: 250000,
        transactionDate: today,
        categoryId: 'cat-makan',
        categoryName: 'Makan',
        description: 'Kopi pagi',
      ),
    );
    await pumpHome(tester);

    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(find.text('Anggaran'), findsOneWidget);
    expect(find.text('Anggaran fleksibel'), findsOneWidget);

    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Transaksi'), findsWidgets);
    expect(find.textContaining('Terpakai siklus ini'), findsWidgets);
    expect(find.text('Kopi pagi'), findsOneWidget);
  });
}
