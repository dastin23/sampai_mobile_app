import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/core/state/app_state.dart';
import 'package:sampai_app/core/theme/app_theme.dart';
import 'package:sampai_app/features/auth/providers/auth_providers.dart';
import 'package:sampai_app/features/home/home_demo_data.dart';
import 'package:sampai_app/features/shell/app_shell.dart';

import 'helpers/fake_auth_repository.dart';

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

  Future<FakeAuthRepository> pumpShell(
    WidgetTester tester, {
    VoidCallback? onRestart,
  }) async {
    final repo = FakeAuthRepository(authenticated: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: AppShell(
            appState: state,
            onRestartOnboarding: onRestart ?? () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    return repo;
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
    await pumpShell(tester, onRestart: () => restarted = true);
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
    await pumpShell(tester, onRestart: () => restarted = true);
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

testWidgets('keluar dari akun meminta konfirmasi lalu memanggil signOut',
    (tester) async {
  useDesignFrame(tester);
  final repo = await pumpShell(tester);
  await goToProfil(tester);

  await tester.scrollUntilVisible(
    find.text('Keluar dari akun'),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Keluar dari akun'));
  await tester.pumpAndSettle();
  expect(find.text('Keluar akun?'), findsOneWidget);

  await tester.tap(find.text('Batal'));
  await tester.pumpAndSettle();
  expect(repo.authenticated, isTrue);

  await tester.tap(find.text('Keluar dari akun'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Keluar'));
  await tester.pumpAndSettle();

  expect(repo.authenticated, isFalse);
});
}