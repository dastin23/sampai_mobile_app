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
    state = AppState()..applyPlan(demoPlan(today));
  });

  tearDown(() => state.dispose());

  void useDesignFrame(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> goToProfil(WidgetTester tester) async {
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
  }

  Future<void> revealRestart(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Mulai ulang pengaturan'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tab Profil menampilkan ringkasan rencana', (tester) async {
    useDesignFrame(tester);
    var restarted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AppShell(
          appState: state,
          onRestartOnboarding: () => restarted = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await goToProfil(tester);

    expect(find.text('Rencana finansial'), findsOneWidget);
    expect(find.text('Gaji bersih per siklus'), findsOneWidget);
    expect(find.text('Rp8.000.000 / siklus'), findsOneWidget);
    expect(
      find.text('Setiap tanggal ${demoPlan(today).paydayDay}'),
      findsOneWidget,
    );
    await revealRestart(tester);
    expect(find.text('Mulai ulang pengaturan'), findsOneWidget);
    expect(restarted, isFalse);
  });

  testWidgets('mulai ulang meminta konfirmasi lalu memanggil callback',
      (tester) async {
    useDesignFrame(tester);
    var restarted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AppShell(
          appState: state,
          onRestartOnboarding: () => restarted = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await goToProfil(tester);

    await revealRestart(tester);
    await tester.tap(find.text('Mulai ulang pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai ulang pengaturan?'), findsOneWidget);
    expect(restarted, isFalse);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(restarted, isFalse);

    await tester.tap(find.text('Mulai ulang pengaturan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai ulang'));
    await tester.pumpAndSettle();
    expect(restarted, isTrue);
  });
}