import 'package:flutter/material.dart';

import 'fixed_expenses_screen.dart';
import 'income_screen.dart';
import 'onboarding_controller.dart';
import 'payday_screen.dart';
import 'savings_preview_screen.dart';
import 'welcome_screen.dart';

/// Flow onboarding: Welcome → Income → Payday → Fixed expenses → Savings.
///
/// [controller] dimiliki oleh aplikasi agar data rencana tetap tersedia
/// di Home setelah onboarding selesai.
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  final OnboardingController controller;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return switch (controller.step) {
          OnboardingStep.welcome => WelcomeScreen(controller: controller),
          OnboardingStep.income => IncomeScreen(controller: controller),
          OnboardingStep.payday => PaydayScreen(controller: controller),
          OnboardingStep.fixedExpenses =>
            FixedExpensesScreen(controller: controller),
          OnboardingStep.savings => SavingsPreviewScreen(
              controller: controller,
              onCompleted: onCompleted,
            ),
        };
      },
    );
  }
}
