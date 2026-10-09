import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Kerangka halaman autentikasi: Kembali + brand SAMPAI, heading, konten
/// scroll, dan footer CTA (pola serupa OnboardingScaffold, PRD 4.2).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.heading,
    required this.content,
    required this.footer,
    this.helper,
    this.onBack,
  });

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
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
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
                  const Expanded(
                    child: Center(child: Text('SAMPAI', style: AppTypography.h3)),
                  ),
                  const SizedBox(width: AppSpacing.minTouchTarget),
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
                      Text(
                        helper!,
                        style: AppTypography.body
                            .copyWith(color: AppColors.secondaryText),
                      ),
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

/// Banner informasi (mis. akun perlu verifikasi email).
class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTypography.bodyStrong),
          ),
        ],
      ),
    );
  }
}

/// Banner error dari server/autentikasi.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.criticalBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 20,
            color: AppColors.criticalText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyStrong.copyWith(
                color: AppColors.criticalText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}