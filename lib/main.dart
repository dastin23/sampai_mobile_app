import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load konfigurasi dari file .env
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabasePublishableKey == null ||
      supabasePublishableKey.isEmpty) {
    throw StateError('SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY wajib diisi.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  // Tes status autentikasi Supabase
  final session = supabase.auth.currentSession;

  debugPrint(
    session == null
        ? 'Supabase terinisialisasi, belum login'
        : 'Supabase terinisialisasi, user sudah login',
  );

  runApp(const ProviderScope(child: SampeiApp()));
}

final supabase = Supabase.instance.client;

class SampeiApp extends StatefulWidget {
  const SampeiApp({super.key});

  @override
  State<SampeiApp> createState() => _SampeiAppState();
}

class _SampeiAppState extends State<SampeiApp> {
  final OnboardingController _onboarding = OnboardingController();
  final AppState _appState = AppState();
  bool _onboarded = false;

  @override
  void dispose() {
    _onboarding.dispose();
    _appState.dispose();
    super.dispose();
  }

  void _completeOnboarding() {
    _appState.applyPlan(_onboarding.buildPlan());
    setState(() => _onboarded = true);
  }

  void _restartOnboarding() {
    _onboarding.restart();
    setState(() => _onboarded = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAMPAI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _onboarded
          ? AppShell(
              appState: _appState,
              onRestartOnboarding: _restartOnboarding,
            )
          : OnboardingFlow(
              controller: _onboarding,
              onCompleted: _completeOnboarding,
            ),
    );
  }
}
