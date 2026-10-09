import 'package:flutter/material.dart';

import '../../core/calc/salary_cycle.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_controller.dart';
import 'onboarding_scaffold.dart';
import 'widgets/form_widgets.dart';

/// Screen 3 — Payday (PRD 4.4).
class PaydayScreen extends StatelessWidget {
  const PaydayScreen({super.key, required this.controller});

  final OnboardingController controller;

  Future<void> _pickNextPayday(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.nextPayday ?? DateTime(now.year, now.month, now.day + 7),
      firstDate: DateTime(now.year - 1, 1),
      lastDate: DateTime(now.year + 2, 12),
    );
    if (picked != null) {
      controller.setNextPayday(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycle = controller.cyclePreview;
    return OnboardingScaffold(
      stepNumber: 2,
      onBack: controller.goBack,
      heading: 'Kapan gajian?',
      helper:
          'Kami gunakan tanggal ini untuk menghitung sisa hari dalam siklus gajimu.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanggal gajian', style: AppTypography.label),
          const SizedBox(height: AppSpacing.componentWide),
          Wrap(
            spacing: AppSpacing.component,
            runSpacing: AppSpacing.component,
            children: [
              for (var day = 1; day <= 31; day++)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => controller.setPaydayDay(day),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: controller.paydayDay == day
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: controller.paydayDay == day
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '$day',
                          style: AppTypography.bodyStrong.copyWith(
                            color: controller.paydayDay == day
                                ? AppColors.surface
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.component),
          const Text(
            'Jika tanggal gajian tidak ada di suatu bulan, gunakan hari '
            'terakhir bulan tersebut.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.section),
          if (cycle != null)
            _CyclePreviewCard(
              start: cycle.start,
              end: cycle.end,
              startLabel: 'Siklus berjalan',
            ),
          const SizedBox(height: AppSpacing.section),
          Text('Tanggal gajian berikutnya (opsional)', style: AppTypography.label),
          const SizedBox(height: AppSpacing.component),
          OutlinedButton.icon(
            onPressed: () => _pickNextPayday(context),
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.fieldHeight),
              alignment: Alignment.centerLeft,
            ),
            label: Text(
              controller.nextPayday == null
                  ? 'Pilih tanggal'
                  : '${formatCycleDate(controller.nextPayday!)} '
                      '${controller.nextPayday!.year}',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.component),
          const Text(
            'Isi hanya bila tanggal gajianmu tidak tetap tiap bulan.',
            style: AppTypography.caption,
          ),
        ],
      ),
      footer: PrimaryCta(
        label: 'Lanjutkan',
        onPressed: () => controller.goTo(OnboardingStep.fixedExpenses),
      ),
    );
  }
}

class _CyclePreviewCard extends StatelessWidget {
  const _CyclePreviewCard({
    required this.start,
    required this.end,
    required this.startLabel,
  });

  final DateTime start;
  final DateTime end;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(startLabel.toUpperCase(), style: AppTypography.label),
          const SizedBox(height: AppSpacing.component),
          Text(
            '${formatCycleDate(start)} – ${formatCycleDate(end)} ${end.year}',
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.component),
          Text(
            '${end.difference(start).inDays + 1} hari · '
            'gajian berikutnya ${formatCycleDate(end)} ${end.year}',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
