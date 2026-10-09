import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/core/state/app_state.dart';
import 'package:sampai_app/core/theme/app_theme.dart';
import 'package:sampai_app/features/home/home_demo_data.dart';
import 'package:sampai_app/features/shell/app_shell.dart';

void main() {
  late AppState state;

  setUp(() {
    state = AppState()
      ..applyPlan(demoPlan(DateTime.now()))
      ..replaceBudgets(demoBudgets());
  });

  tearDown(() => state.dispose());

  void useDesignFrame(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AppShell(appState: state, onRestartOnboarding: () {}),
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
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('daftar transaksi menampilkan ringkasan dan baris siklus',
      (tester) async {
    useDesignFrame(tester);
    state.addTransaction(demoTransactions(DateTime.now())[0]);
    await pumpApp(tester);
    await goToTransactions(tester);

    expect(find.text('Terpakai siklus ini'), findsOneWidget);
    expect(find.text('Rp250.000'), findsOneWidget);
    expect(find.text('Sisa anggaran fleksibel Rp3.950.000'), findsOneWidget);
    expect(find.text('Warung makan'), findsOneWidget);
    expect(find.text('−Rp250.000'), findsOneWidget);
    expect(find.text('Semua transaksi'), findsOneWidget);
  });

  testWidgets('daftar kosong menampilkan empty state dan CTA', (tester) async {
    useDesignFrame(tester);
    await pumpApp(tester);
    await goToTransactions(tester);

    expect(find.text('Belum ada pengeluaran tercatat'), findsOneWidget);
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
      category: 'Makan',
      note: 'Jajan kopi',
    );

    expect(find.text('Pengeluaran tersimpan'), findsOneWidget);
    expect(find.text('Rp75.000'), findsOneWidget);
    expect(find.text('Sisa anggaran fleksibel Rp4.125.000'), findsOneWidget);
    expect(find.text('Jajan kopi'), findsOneWidget);
    expect(find.text('−Rp75.000'), findsOneWidget);
  });

  testWidgets('pengeluaran dari Home juga muncul di daftar Transaksi',
      (tester) async {
    useDesignFrame(tester);
    await pumpApp(tester);

    await saveExpense(
      tester,
      amount: '15000',
      category: 'Transportasi',
      note: 'Teh tarik',
    );

    await goToTransactions(tester);

    expect(find.text('Teh tarik'), findsOneWidget);
    expect(find.text('−Rp15.000'), findsOneWidget);
    expect(find.text('Sisa anggaran fleksibel Rp4.185.000'), findsOneWidget);
  });
}