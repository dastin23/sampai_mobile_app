import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'onboarding_controller.dart';

/// Screen 1 — Welcome (PRD 4.2).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('SAMPAI', style: AppTypography.h3),
              const Spacer(),
              const _WelcomeVisual(),
              const SizedBox(height: AppSpacing.section + 8),
              const Text('Bikin gaji sampai.', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.componentWide),
              const Text(
                'Atur pengeluaran, sisihkan kebutuhan penting, dan tahu '
                'berapa yang aman dibelanjakan.',
                style: AppTypography.body,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => controller.goTo(OnboardingStep.income),
                child: const Text('Mulai atur gaji'),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeVisual extends StatelessWidget {
  const _WelcomeVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 180,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            Positioned(
              top: 16,
              right: 24,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_outlined, color: AppColors.primary),
              ),
            ),
            Positioned(
              left: 32,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Rp140.000/hari',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
