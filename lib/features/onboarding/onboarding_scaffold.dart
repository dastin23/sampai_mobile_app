import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Top bar onboarding: tombol Kembali (langkah 2–5) + indikator progres
/// `n dari 4` (PRD 4.1).
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.stepNumber,
    required this.heading,
    required this.content,
    required this.footer,
    this.helper,
    this.onBack,
  });

  final int stepNumber;
  final String heading;
  final String? helper;
  final Widget content;
  final Widget footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 24, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: AppSpacing.minTouchTarget,
                    height: AppSpacing.minTouchTarget,
                    child: onBack == null
                        ? null
                        : IconButton(
                            onPressed: onBack,
                            tooltip: 'Kembali',
                            icon: const Icon(Icons.arrow_back),
                            color: AppColors.primary,
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                          ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: _ProgressSegments(current: stepNumber)),
                  const SizedBox(width: 12),
                  Text('$stepNumber dari 4', style: AppTypography.caption),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.section,
                  AppSpacing.pageHorizontal,
                  AppSpacing.section,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(heading, style: AppTypography.h1),
                    if (helper != null) ...[
                      const SizedBox(height: AppSpacing.component),
                      Text(helper!, style: AppTypography.body.copyWith(color: AppColors.secondaryText)),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    content,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.componentWide,
                AppSpacing.pageHorizontal,
                MediaQuery.paddingOf(context).bottom + AppSpacing.componentWide,
              ),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({required this.current});

  /// Nilai 1–4.
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final filled = i < current;
        return Expanded(
          child: Container(
            height: 6,
            margin: i == 0 ? EdgeInsets.zero : const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
