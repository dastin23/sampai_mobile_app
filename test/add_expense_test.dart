import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/core/state/app_state.dart';
import 'package:sampai_app/core/theme/app_theme.dart';
import 'package:sampai_app/features/add_expense/add_expense_controller.dart';
import 'package:sampai_app/features/add_expense/add_expense_sheet.dart';
import 'package:sampai_app/features/home/home_demo_data.dart';
import 'package:sampai_app/features/shell/app_shell.dart';

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
    await tester.tap(find.text('Catat pengeluaran'));
    await tester.pumpAndSettle();
  }

  Future<void> fillValid(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), '75000');
    await tester.pump();
    await tester.tap(find.text('Makan'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'Makan siang');
    await tester.pump();
  }

  testWidgets('membuka sheet dari CTA Home', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    expect(find.text('Simpan pengeluaran'), findsOneWidget);
    expect(find.text('Jumlah'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.byType(GridView), findsWidgets);
  });

  testWidgets('validasi jumlah dan kategori saat submit kosong', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await tester.tap(find.text('Simpan pengeluaran'));
    await tester.pump();

    expect(find.text('Masukkan jumlah lebih dari Rp0.'), findsOneWidget);
    expect(find.text('Pilih kategori pengeluaran.'), findsOneWidget);
  });

  testWidgets('kategori wajib dipilih walau jumlah valid', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await tester.enterText(find.byType(TextField).at(0), '75000');
    await tester.pump();
    await tester.tap(find.text('Simpan pengeluaran'));
    await tester.pump();

    expect(find.text('Pilih kategori pengeluaran.'), findsOneWidget);
    expect(find.text('Masukkan jumlah lebih dari Rp0.'), findsNothing);
  });

  testWidgets('simpan sukses menutup sheet dan memperbarui Home', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    // Belum ada transaksi → badge Estimasi.
    expect(find.text('Estimasi'), findsOneWidget);

    await fillValid(tester);
    await tester.tap(find.text('Simpan pengeluaran'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Menyimpan…'), findsOneWidget);
    expect(find.text('Simpan pengeluaran'), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Pengeluaran tersimpan'), findsOneWidget);
    // 4.200.000 − 75.000 = 4.125.000 (kartu utama, di atas halaman).
    expect(find.text('Rp4.125.000'), findsOneWidget);
    expect(find.text('Estimasi'), findsNothing);

    // Bagian "Transaksi terbaru" ada di bawah; gulir dulu.
    await tester.scrollUntilVisible(
      find.text('Makan siang'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Makan siang'), findsOneWidget);
    expect(find.text('−Rp75.000'), findsOneWidget);
  });

  testWidgets('submit berulang tidak membuat transaksi ganda', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await fillValid(tester);
    await tester.tap(find.text('Simpan pengeluaran'));
    await tester.pump(const Duration(milliseconds: 50));

    // CTA dalam keadaan loading/nonaktif → percobaan kedua tidak berefek.
    expect(find.text('Menyimpan…'), findsOneWidget);
    await tester.tap(find.text('Menyimpan…'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Pengeluaran tersimpan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('−Rp75.000'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('−Rp75.000'), findsOneWidget);
  });

  testWidgets('gagal simpan menahan sheet dan mempertahankan draft',
      (tester) async {
    useDesignFrame(tester);
    final failing = AddExpenseController(state, simulateFailure: true);
    addTearDown(failing.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAddExpenseSheet(
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
    await tester.tap(find.text('Simpan pengeluaran'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Belum berhasil menyimpan. Coba lagi.'), findsOneWidget);
    // Sheet tetap terbuka dan draft utuh.
    expect(find.text('Simpan pengeluaran'), findsOneWidget);
    expect(find.text('Rp75.000'), findsOneWidget);
  });

  testWidgets('menutup tanpa data tidak meminta konfirmasi', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Buang pengeluaran ini?'), findsNothing);
    expect(find.text('Simpan pengeluaran'), findsNothing);
  });

  testWidgets('menutup dengan data meminta konfirmasi', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await tester.enterText(find.byType(TextField).at(0), '75000');
    await tester.pump();

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Buang pengeluaran ini?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan pengeluaran'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Buang pengeluaran ini?'), findsOneWidget);

    await tester.tap(find.text('Buang'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan pengeluaran'), findsNothing);
  });

  testWidgets('tanggal bisa diganti lewat date picker', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await openSheet(tester);

    await tester.tap(find.text('Tanggal'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan pengeluaran'), findsOneWidget);
  });
}