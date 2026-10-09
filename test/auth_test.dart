import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampai_app/app/router/app_router.dart';
import 'package:sampai_app/app/sampai_app.dart';
import 'package:sampai_app/app/state/app_providers.dart';
import 'package:sampai_app/core/theme/app_theme.dart';
import 'package:sampai_app/features/auth/data/auth_repository.dart';
import 'package:sampai_app/features/auth/presentation/login_screen.dart';
import 'package:sampai_app/features/auth/presentation/register_screen.dart';
import 'package:sampai_app/features/auth/providers/auth_providers.dart';
import 'package:sampai_app/features/onboarding/onboarding_flow.dart';
import 'package:sampai_app/features/shell/app_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository implements AuthRepository {
  bool authenticated = false;
  AuthOutcome signInResult = const AuthOutcome.success();
  AuthOutcome signUpResult = const AuthOutcome.success();

  final List<(String, String)> logins = [];
  final List<(String, String, String)> registrations = [];
  final StreamController<AuthState> _authController =
      StreamController<AuthState>.broadcast();

  @override
  Session? get currentSession => null;

  @override
  bool get isAuthenticated => authenticated;

  @override
  Stream<AuthState> get authStateChanges => _authController.stream;

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    logins.add((email, password));
    if (signInResult.isSuccess) authenticated = true;
    return signInResult;
  }

  @override
  Future<AuthOutcome> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registrations.add((fullName, email, password));
    if (signUpResult.isSuccess) authenticated = true;
    return signUpResult;
  }

  @override
  Future<void> signOut() async {
    authenticated = false;
  }
}

void main() {
  void useDesignFrame(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    FakeAuthRepository repo,
    Widget screen,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(theme: buildAppTheme(), home: screen),
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester, FakeAuthRepository repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const SampaiApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterAuthFields(
    WidgetTester tester, {
    required String email,
    required String password,
    String? confirm,
    String? name,
  }) async {
    if (name != null) {
      await tester.enterText(find.byType(TextField).at(0), name);
      await tester.enterText(find.byType(TextField).at(1), email);
      await tester.enterText(find.byType(TextField).at(2), password);
      if (confirm != null) {
        await tester.enterText(find.byType(TextField).at(3), confirm);
      }
    } else {
      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), password);
    }
    await tester.pump();
  }

  group('LoginScreen', () {
    testWidgets('validasi kosong menampilkan error tanpa memanggil repository',
        (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository();
      await pumpScreen(tester, repo, const LoginScreen());

      await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Masukkan email.'), findsOneWidget);
      expect(find.text('Masukkan kata sandi.'), findsOneWidget);
      expect(repo.logins, isEmpty);
    });

    testWidgets('email tidak valid ditolak', (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository();
      await pumpScreen(tester, repo, const LoginScreen());

      await enterAuthFields(
        tester,
        email: 'bukan-email',
        password: 'secret123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Masukkan email yang valid.'), findsOneWidget);
      expect(repo.logins, isEmpty);
    });

    testWidgets('error dari server ditampilkan pada banner', (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository()
        ..signInResult = const AuthOutcome.failure('Email atau kata sandi salah.');
      await pumpScreen(tester, repo, const LoginScreen());

      await enterAuthFields(tester, email: 'user@mail.com', password: 'salah123');
      await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
      expect(repo.logins.single.$1, 'user@mail.com');
      expect(repo.logins.single.$2, 'salah123');
    });

    testWidgets('berhasil masuk diarahkan ke onboarding (belum ada rencana)',
        (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository();
      await pumpApp(tester, repo);

      await enterAuthFields(tester, email: 'user@mail.com', password: 'secret123');
      await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingFlow), findsOneWidget);
      expect(repo.logins.single.$1, 'user@mail.com');
    });

    testWidgets('navigasi ke Daftar dan kembali', (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository();
      await pumpApp(tester, repo);

      await tester.tap(find.text('Belum punya akun? Daftar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Buat akun gratis'), findsOneWidget);

      await tester.tap(find.text('Sudah punya akun? Masuk'));
      await tester.pumpAndSettle();
      expect(
        find.text('Masuk untuk menyimpan pengaturanmu di akun SAMPAI.'),
        findsOneWidget,
      );
    });
  });

  group('RegisterScreen', () {
    testWidgets('nama lengkap kosong dan pendek ditolak', (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository();
      await pumpScreen(tester, repo, const RegisterScreen());

      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan nama lengkap.'), findsOneWidget);

      await enterAuthFields(
        tester,
        name: 'A',
        email: 'new@mail.com',
        password: 'secret123',
        confirm: 'secret123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();
      expect(find.text('Nama minimal 2 karakter.'), findsOneWidget);
      expect(repo.registrations, isEmpty);
    });

    testWidgets('kata sandi pendek dan tidak sama ditolak', (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository();
      await pumpScreen(tester, repo, const RegisterScreen());

      await enterAuthFields(
        tester,
        name: 'Budi Santoso',
        email: 'new@mail.com',
        password: '123',
        confirm: '456',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi minimal 6 karakter.'), findsOneWidget);
      expect(find.text('Kata sandi tidak sama.'), findsOneWidget);
      expect(repo.registrations, isEmpty);
    });

    testWidgets('error dari server ditampilkan pada banner', (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository()
        ..signUpResult = const AuthOutcome.failure('Email sudah terdaftar.');
      await pumpScreen(tester, repo, const RegisterScreen());

      await enterAuthFields(
        tester,
        name: 'Budi Santoso',
        email: 'new@mail.com',
        password: 'secret123',
        confirm: 'secret123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Email sudah terdaftar.'), findsOneWidget);
      expect(repo.registrations.single.$1, 'Budi Santoso');
      expect(repo.registrations.single.$2, 'new@mail.com');
    });

    testWidgets('verifikasi email ditampilkan tanpa keluar dari halaman',
        (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository()
        ..signUpResult = const AuthOutcome.requiresConfirmation();
      await pumpApp(tester, repo);

      await tester.tap(find.text('Belum punya akun? Daftar'));
      await tester.pumpAndSettle();
      await enterAuthFields(
        tester,
        name: 'Budi Santoso',
        email: 'new@mail.com',
        password: 'secret123',
        confirm: 'secret123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('verifikasi email'), findsOneWidget);
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('daftar berhasil diarahkan ke onboarding', (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository();
      await pumpApp(tester, repo);

      await tester.tap(find.text('Belum punya akun? Daftar'));
      await tester.pumpAndSettle();
      await enterAuthFields(
        tester,
        name: 'Budi Santoso',
        email: 'new@mail.com',
        password: 'secret123',
        confirm: 'secret123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingFlow), findsOneWidget);
      expect(repo.registrations.single.$1, 'Budi Santoso');
      expect(repo.registrations.single.$2, 'new@mail.com');
    });
  });

  group('router redirect', () {
    testWidgets('belum login diarahkan ke /login', (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository()..authenticated = false;
      await pumpApp(tester, repo);

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('login tanpa rencana diarahkan ke /onboarding',
        (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository()..authenticated = true;
      await pumpApp(tester, repo);

      expect(find.byType(OnboardingFlow), findsOneWidget);
    });

    testWidgets('login dengan rencana menuju shell /home', (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository()..authenticated = true;

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.read(onboardedProvider.notifier).complete();

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const SampaiApp()),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('router menyediakan /home dan /login yang valid',
        (tester) async {
      useDesignFrame(tester);
      final repo = FakeAuthRepository()..authenticated = true;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.read(onboardedProvider.notifier).complete();

      final router = container.read(appRouterProvider);
      expect(router, isNotNull);
    });
  });
}