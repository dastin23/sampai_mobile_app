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

  Future<void> pumpBudget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AppShell(appState: state, onRestartOnboarding: () {}),
      ),
    );
    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.text('Makan'));
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

    await tester.tap(find.text('Makan'));
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
    await tester.enterText(find.byType(TextField).at(1), '500000');
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
    await pumpBudget(tester);
    await preview(tester, 'Mendekati batas (80%)');

    expect(find.text('Mendekati batas'), findsOneWidget);
    expect(find.text('Rp1.000.000 dari Rp1.200.000'), findsOneWidget);
  });

  testWidgets('state melebihi anggaran menampilkan jumlah kelebihan', (tester) async {
    useDesignFrame(tester);
    await pumpBudget(tester);
    await preview(tester, 'Melebihi anggaran');

    expect(find.text('Melebihi anggaran Rp100.000'), findsOneWidget);
  });

  testWidgets('state kosong menawarkan atur anggaran', (tester) async {
    useDesignFrame(tester);
    await pumpBudget(tester);
    await preview(tester, 'Kosong (belum ada anggaran)');

    expect(find.text('Belum ada anggaran kategori.'), findsOneWidget);
    expect(find.text('Atur anggaran'), findsOneWidget);
  });

  testWidgets('state error menyediakan coba lagi', (tester) async {
    useDesignFrame(tester);
    await pumpBudget(tester);
    await preview(tester, 'Error');

    expect(find.text('Data belum bisa dimuat.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Anggaran fleksibel'), findsOneWidget);
  });

  testWidgets('skeleton tampil saat memuat', (tester) async {
    useDesignFrame(tester);
    await pumpBudget(tester);
    await preview(tester, 'Memuat (skeleton)');

    expect(find.text('Anggaran fleksibel'), findsNothing);
    expect(find.text('Pratinjau: memuat'), findsOneWidget);
  });

  testWidgets('membuat alokasi pertama dari state kosong', (tester) async {
    useDesignFrame(tester);
    final emptyState = AppState()..applyPlan(demoPlan(today));
    addTearDown(emptyState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AppShell(appState: emptyState, onRestartOnboarding: () {}),
      ),
    );
    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

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