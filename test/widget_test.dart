import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/core/calc/salary_cycle.dart';
import 'package:sampai_app/core/format/rupiah.dart';
import 'package:sampai_app/main.dart';

void main() {
  /// Frame referensi PRD: 390 × 844.
  void useDesignFrame(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }


  group('formatRupiah', () {
    test('formats with thousand separators', () {
      expect(formatRupiah(8000000), 'Rp8.000.000');
      expect(formatRupiah(0), 'Rp0');
      expect(formatRupiah(-150000), '-Rp150.000');
    });

    test('parses digits only', () {
      expect(parseRupiah('Rp8.000.000'), 8000000);
      expect(parseRupiah(''), 0);
    });
  });

  group('salary cycle', () {
    test('uses last day of month for day 31', () {
      expect(paydayInMonth(2026, 2, 31), DateTime(2026, 2, 28));
      expect(paydayInMonth(2026, 4, 31), DateTime(2026, 4, 30));
    });

    test('cycle runs from payday to day before next payday', () {
      final cycle =
          SalaryCycle.forToday(today: DateTime(2026, 10, 8), paydayDay: 25);
      expect(cycle.start, DateTime(2026, 9, 25));
      expect(cycle.end, DateTime(2026, 10, 24));
      expect(cycle.labelWithYear, '25 Sep 2026 – 24 Okt 2026');
      expect(cycle.totalDays, 30);
      expect(cycle.remainingDays(DateTime(2026, 10, 8)), 17);
    });

    test('handles payday today as cycle start', () {
      final cycle =
          SalaryCycle.forToday(today: DateTime(2026, 10, 25), paydayDay: 25);
      expect(cycle.start, DateTime(2026, 10, 25));
      expect(cycle.end, DateTime(2026, 11, 24));
    });

    test('no division by zero semantics for remaining days', () {
      final cycle =
          SalaryCycle.forToday(today: DateTime(2026, 10, 24), paydayDay: 25);
      expect(cycle.remainingDays(DateTime(2026, 10, 24)), 1);
      expect(cycle.remainingDays(DateTime(2026, 10, 25)), 0);
    });
  });

  testWidgets('onboarding flow reaches income screen', (tester) async {
    useDesignFrame(tester);
    await tester.pumpWidget(const SampeiApp());
    expect(find.text('Bikin gaji sampai.'), findsOneWidget);

    await tester.tap(find.text('Mulai atur gaji'));
    await tester.pumpAndSettle();

    expect(find.text('Berapa gaji bersihmu?'), findsOneWidget);
    expect(find.text('1 dari 4'), findsOneWidget);
    expect(find.text('Lanjutkan'), findsOneWidget);
  });

  testWidgets('income CTA disabled until amount is valid', (tester) async {
    useDesignFrame(tester);
    await tester.pumpWidget(const SampeiApp());
    await tester.tap(find.text('Mulai atur gaji'));
    await tester.pumpAndSettle();

    FilledButton cta() => tester.widget<FilledButton>(
        find.ancestor(of: find.text('Lanjutkan'), matching: find.byType(FilledButton)),
      );
    expect(cta().onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '8000000');
    await tester.pump();
    expect(find.text('Rp8.000.000'), findsOneWidget);
    expect(cta().onPressed, isNotNull);
  });

  testWidgets('completes full onboarding and lands on home', (tester) async {
    useDesignFrame(tester);
    await tester.pumpWidget(const SampeiApp());

    // Screen 1 → 2
    await tester.tap(find.text('Mulai atur gaji'));
    await tester.pumpAndSettle();

    // Screen 2 — Income
    await tester.enterText(find.byType(TextField).first, '8000000');
    await tester.pump();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Screen 3 — Payday
    expect(find.text('Kapan gajian?'), findsOneWidget);
    expect(find.text('2 dari 4'), findsOneWidget);
    expect(find.textContaining('25 Sep'), findsWidgets);
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    // Screen 4 — Fixed expenses
    expect(find.text('Belum ada tagihan tetap'), findsOneWidget);
    await tester.tap(find.text('Tambah tagihan'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), 'Kos');
    await tester.enterText(find.byType(TextField).at(1), '1500000');
    await tester.pump();
    expect(find.text('Rp1.500.000'), findsWidgets);
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    // Screen 5 — Savings & preview
    expect(find.text('Mau sisihkan berapa?'), findsOneWidget);
    expect(find.text('4 dari 4'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '1000000');
    await tester.pump();
    // 8.000.000 − 1.500.000 − 1.000.000 = 5.500.000
    expect(find.text('Rp5.500.000'), findsOneWidget);

    await tester.tap(find.text('Buat rencana saya'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    // Home memuat data (timer 500ms) setelah shell terpasang.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Home
    expect(find.text('Halo!'), findsOneWidget);
    expect(find.text('Rp5.500.000'), findsWidgets);
    if (find.text('Tagihan terdekat').evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text('Tagihan terdekat'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Kos'), findsOneWidget);
  });
}

