import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/core/state/app_state.dart';
import 'package:sampai_app/core/theme/app_theme.dart';
import 'package:sampai_app/features/home/home_demo_data.dart';
import 'package:sampai_app/features/shell/app_shell.dart';

void main() {
  late AppState state;
  final today = DateTime.now();

  setUp(() {
    state = AppState()
      ..applyPlan(demoPlan(today))
      ..replaceBudgets(demoBudgets());
    for (final tx in demoTransactions(today)) {
      state.addTransaction(tx);
    }
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

  Future<void> preview(WidgetTester tester, String option) async {
    await tester.tap(find.byTooltip('Pratinjau state'));
    await tester.pumpAndSettle();
    final target = find.text(option);
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
    }
    await tester.tap(target);
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

    await scrollHomeTo(tester, 'Anggaran siklus ini');
    expect(find.text('Anggaran siklus ini'), findsOneWidget);
    await scrollHomeTo(tester, 'Tagihan terdekat');
    expect(find.text('Tagihan terdekat'), findsOneWidget);
    await scrollHomeTo(tester, 'Transaksi terbaru');
    expect(find.text('Transaksi terbaru'), findsOneWidget);
  });

  testWidgets('state peringatan menampilkan velocity > 1', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await preview(tester, 'Peringatan (velocity > 1)');

    expect(find.text('Pratinjau: peringatan'), findsOneWidget);
    expect(find.textContaining('lebih cepat dari rencana'), findsOneWidget);
    expect(find.textContaining('×'), findsOneWidget);
  });

  testWidgets('state kritis menampilkan Safe-to-Spend 0', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await preview(tester, 'Kritis (Safe-to-Spend 0)');

    expect(find.text('Rp0'), findsWidgets);
    expect(find.text('Anggaran harian sudah terpakai.'), findsOneWidget);
    await scrollHomeTo(tester, 'Melebihi anggaran Rp900.000');
    expect(find.text('Melebihi anggaran Rp900.000'), findsOneWidget);
  });

  testWidgets('state offline menampilkan data terakhir diperbarui',
      (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await preview(tester, 'Offline');

    expect(find.textContaining('Data terakhir diperbarui'), findsOneWidget);
    expect(find.text('Pratinjau: offline'), findsOneWidget);
  });

  testWidgets('state kosong mengarahkan ke pengaturan siklus', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await preview(tester, 'First-use / kosong');

    expect(
      find.text('Atur siklus gajimu untuk mulai menghitung.'),
      findsOneWidget,
    );
    expect(find.text('Selesaikan pengaturan'), findsOneWidget);
  });

  testWidgets('state error menyediakan coba lagi', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);
    await preview(tester, 'Error');

    expect(find.text('Data belum bisa dimuat.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('AMAN DIBELANJAKAN'), findsOneWidget);
  });

  testWidgets('skeleton tampil saat memuat', (tester) async {
    useDesignFrame(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AppShell(appState: state, onRestartOnboarding: () {}),
      ),
    );
    // Sebelum timer load selesai → skeleton, bukan angka nol.
    expect(find.text('AMAN DIBELANJAKAN'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('AMAN DIBELANJAKAN'), findsOneWidget);
  });

  testWidgets('bottom navigation berpindah tab', (tester) async {
    useDesignFrame(tester);
    await pumpHome(tester);

    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(find.text('Anggaran'), findsOneWidget);
    expect(find.text('Anggaran fleksibel'), findsOneWidget);

    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Transaksi'), findsWidgets);
    expect(find.text('Terpakai siklus ini'), findsOneWidget);
    expect(find.text('Warung makan'), findsOneWidget);
  });
}
