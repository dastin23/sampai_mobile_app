import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/set_new_password_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/providers/password_reset_provider.dart';
import '../../features/onboarding/onboarding_flow.dart';
import '../../features/shell/app_shell.dart';
import '../../features/sync/providers/app_data_providers.dart';
import '../state/app_providers.dart';

/// Menyalakan ulang GoRouter setiap kali stream autentikasi berubah sehingga
/// `redirect` dievaluasi ulang.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  void notify() => notifyListeners();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authRepositoryProvider);
  final refresh = GoRouterRefreshStream(auth.authStateChanges);

  // Aktifkan write-through data Home ke Supabase sepanjang sesi.
  ref.read(appDataSyncProvider);

  // Saat status autentikasi berubah: muat/hapus rencana dari backend.
  // Khusus `passwordRecovery`, jangan hydrate — kunci user di
  // `/set-new-password` lalu refresh explicit agar redirect dievaluasi.
  late final StreamSubscription<dynamic> authSub;
  authSub = auth.authStateChanges.listen((payload) {
    final notifier = ref.read(onboardedProvider.notifier);
    final pending = ref.read(pendingPasswordResetProvider.notifier);
    if (payload.event == AuthChangeEvent.passwordRecovery) {
      pending.markFromRecovery();
      refresh.notify();
    } else if (auth.isAuthenticated) {
      unawaited(notifier.hydrate());
    } else {
      pending.clear();
      notifier.reset();
    }
  });

  // Kembali login dengan sesi tersimpan tanpa event baru.
  if (auth.isAuthenticated) {
    unawaited(ref.read(onboardedProvider.notifier).hydrate());
  }

  // Saat status onboarding berubah, redirect ikut dievaluasi.
  ref.listen(onboardedProvider, (_, _) {
    refresh.notify();
  });

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final onboarded = ref.read(onboardedProvider);
      final pendingReset = ref.read(pendingPasswordResetProvider);
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      if (!loggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // Sesi dari link reset: kunci di layar setel kata sandi baru.
      if (pendingReset) {
        return location == '/set-new-password' ? null : '/set-new-password';
      }

      // Sudah login — jangan tampilkan halaman login/register/reset.
      if (isAuthRoute || location == '/set-new-password') {
        return onboarded ? '/home' : '/onboarding';
      }

      // Gate onboarding: wajib selesaikan rencana sebelum masuk shell.
      if (!onboarded && location != '/onboarding') return '/onboarding';
      if (onboarded && location == '/onboarding') return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/set-new-password',
        builder: (context, state) => const SetNewPasswordScreen(),
      ),
      GoRoute(path: '/onboarding', builder: (context, state) => const _OnboardingPage()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _ShellPage(),
      ),
    ],
  );

  ref.onDispose(() {
    authSub.cancel();
    router.dispose();
    refresh.dispose();
  });

  return router;
});

class _OnboardingPage extends ConsumerWidget {
  const _OnboardingPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider);
    return OnboardingFlow(
      controller: controller,
      onCompleted: () => ref.read(onboardedProvider.notifier).complete(),
    );
  }
}

class _ShellPage extends ConsumerWidget {
  const _ShellPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShell(
      appState: ref.read(appStateProvider),
      onRestartOnboarding: () => ref.read(onboardedProvider.notifier).reset(),
    );
  }
}