import 'package:flutter/material.dart';

import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/shell/app_shell.dart';

void main() {
  runApp(const SampeiApp());
}

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
