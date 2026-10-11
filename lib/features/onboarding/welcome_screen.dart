import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/liquid_glass.dart';
import 'onboarding_controller.dart';

/// Screen 1 — Welcome (PRD 4.2).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AtmosphereBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
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
                const SizedBox(height: AppSpacing.component),
                OutlinedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text('Sudah punya akun? Masuk'),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
              ],
            ),
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
            GlassSurface(
              kind: GlassKind.hero,
              radius: AppSpacing.heroRadius,
              child: const SizedBox(width: 180, height: 140),
            ),
            Positioned(
              top: 16,
              right: 24,
              child: GlassSurface(
                kind: GlassKind.raised,
                radius: 999,
                color: AppColors.surface.withValues(alpha: 0.85),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.savings_outlined,
                    color: AppColors.primaryStrong,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 32,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Rp140.000/hari',
                  style: TextStyle(
                    color: AppColors.primary,
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
