import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/core/models/plan.dart';
import 'package:sampai_app/core/state/app_state.dart';
import 'package:sampai_app/core/theme/app_theme.dart';
import 'package:sampai_app/features/add_expense/add_expense_controller.dart';
import 'package:sampai_app/features/add_expense/add_expense_sheet.dart';
import 'package:sampai_app/features/home/home_demo_data.dart';
import 'package:sampai_app/features/shell/app_shell.dart';
import 'package:sampai_app/features/transactions/transactions_data.dart';

void main() {
  late AppState state;
  final today = DateTime.now();

  setUp(() {
    state = AppState()..applyPlan(demoPlan(today));
  });

  tearDown(() => state.dispose());

  void useDesignFrame(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AppShell(appState: state, onRestartOnboarding: () {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Catat pemasukan'));
    await tester.pumpAndSettle();
  }

  Future<void> fillValid(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), '2000000');
    await tester.pump();
    await tester.tap(find.text('Gaji'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'Gaji tambahan');
    await tester.pump();
  }

  testWidgets('membuka sheet dari CTA Home', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    expect(find.text('Simpan pemasukan'), findsOneWidget);
    expect(find.text('Jumlah'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Gaji'), findsOneWidget);
    expect(find.text('Bonus'), findsOneWidget);
  });

  testWidgets('validasi jumlah dan kategori saat submit kosong', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await tester.tap(find.text('Simpan pemasukan'));
    await tester.pump();

    expect(find.text('Masukkan jumlah lebih dari Rp0.'), findsOneWidget);
    expect(find.text('Pilih kategori pemasukan.'), findsOneWidget);
  });

  testWidgets('kategori wajib dipilih walau jumlah valid', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await tester.enterText(find.byType(TextField).at(0), '2000000');
    await tester.pump();
    await tester.tap(find.text('Simpan pemasukan'));
    await tester.pump();

    expect(find.text('Pilih kategori pemasukan.'), findsOneWidget);
    expect(find.text('Masukkan jumlah lebih dari Rp0.'), findsNothing);
  });

  testWidgets('simpan sukses menutup sheet, tampil di Home, tidak mengubah terpakai',
      (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    expect(find.text('Estimasi'), findsOneWidget);

    await fillValid(tester);
    await tester.tap(find.text('Simpan pemasukan'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Menyimpan…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Pemasukan tersimpan'), findsOneWidget);
    // Pemasukan tidak masuk biaya fleksibel → belum ada pengeluaran.
    expect(find.text('Estimasi'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Gaji tambahan'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Gaji tambahan'), findsOneWidget);
    expect(find.text('+Rp2.000.000'), findsOneWidget);
  });

  testWidgets('submit berulang tidak membuat transaksi ganda', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await fillValid(tester);
    await tester.tap(find.text('Simpan pemasukan'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Menyimpan…'), findsOneWidget);
    await tester.tap(find.text('Menyimpan…'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Pemasukan tersimpan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('+Rp2.000.000'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('+Rp2.000.000'), findsOneWidget);
  });

  testWidgets('pemasukan dari Home muncul di daftar Transaksi dengan total',
      (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await fillValid(tester);
    await tester.tap(find.text('Simpan pemasukan'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('Gaji tambahan'), findsOneWidget);
    expect(find.text('+Rp2.000.000'), findsOneWidget);
    expect(find.text('Pemasukan tercatat Rp2.000.000'), findsOneWidget);
  });

  testWidgets('gagal simpan menahan sheet dan mempertahankan draft',
      (tester) async {
    useDesignFrame(tester);
    final failing = AddIncomeController(state, simulateFailure: true);
    addTearDown(failing.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAddIncomeSheet(
                  context,
                  appState: state,
                  controller: failing,
                ),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    await fillValid(tester);
    await tester.tap(find.text('Simpan pemasukan'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Belum berhasil menyimpan. Coba lagi.'), findsOneWidget);
    expect(find.text('Simpan pemasukan'), findsOneWidget);
    expect(find.text('Rp2.000.000'), findsOneWidget);
  });

  testWidgets('menutup tanpa data tidak meminta konfirmasi', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Buang pemasukan ini?'), findsNothing);
    expect(find.text('Simpan pemasukan'), findsNothing);
  });

  testWidgets('menutup dengan data meminta konfirmasi', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await tester.enterText(find.byType(TextField).at(0), '2000000');
    await tester.pump();

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Buang pemasukan ini?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan pemasukan'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Buang pemasukan ini?'), findsOneWidget);

    await tester.tap(find.text('Buang'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan pemasukan'), findsNothing);
  });

  group('kalkulasi', () {
    test('pemasukan tidak dihitung ke anggaran fleksibel', () {
      final income = ExpenseTransaction.income(
        id: 'inc-1',
        title: 'Bonus',
        category: 'Bonus',
        amount: 2000000,
        date: today,
      );
      final data = TransactionsData.fromInputs(
        plan: demoPlan(today),
        transactions: [income],
        today: today,
      );

      expect(income.isIncome, isTrue);
      expect(income.countsTowardFlexibleBudget, isFalse);
      expect(data.totalSpent, 0);
      expect(data.totalIncome, 2000000);
      expect(data.transactions, hasLength(1));
    });
  });
}