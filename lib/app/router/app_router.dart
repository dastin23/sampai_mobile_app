import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/onboarding/onboarding_flow.dart';
import '../../features/shell/app_shell.dart';
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
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';

      if (!loggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // Sudah login — jangan tampilkan halaman login/register.
      if (isAuthRoute) {
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
      GoRoute(path: '/onboarding', builder: (context, state) => const _OnboardingPage()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _ShellPage(),
      ),
    ],
  );

  ref.onDispose(() {
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