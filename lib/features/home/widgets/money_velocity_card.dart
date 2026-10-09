import 'package:flutter/material.dart';

import '../../../core/calc/financial_summary.dart';
import '../../../core/theme/app_theme.dart';
import 'progress_bar.dart';

/// Kartu Money Velocity (PRD 5.2.C).
class MoneyVelocityCard extends StatelessWidget {
  const MoneyVelocityCard({super.key, required this.summary});

  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    final velocity = summary.moneyVelocity;
    final reason = summary.velocityUnavailableReason;
    final tooFast = summary.isSpendingTooFast;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.componentWide),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Money Velocity', style: AppTypography.h3)),
              _RatioChip(
                label: velocity == null ? '—' : formatRatio(velocity),
                warning: tooFast,
                neutral: velocity == null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.component),
          Text(
            reason ??
                (tooFast
                    ? 'Pengeluaran sedikit lebih cepat dari rencana'
                    : 'Pengeluaran berjalan sesuai rencana'),
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          if (reason != null) ...[
            const SizedBox(height: AppSpacing.componentWide),
            Text(reason, style: AppTypography.caption),
          ] else ...[
            const SizedBox(height: AppSpacing.componentWide),
            _MetricRow(
              label: 'Siklus berlalu',
              percent: summary.timeProgressPercent,
              caption: formatPercent(summary.timeProgressPercent),
            ),
            const SizedBox(height: AppSpacing.componentWide),
            _MetricRow(
              label: 'Anggaran terpakai',
              percent: summary.spendingProgressPercent,
              caption: formatPercent(summary.spendingProgressPercent),
            ),
            const SizedBox(height: AppSpacing.componentWide),
            Text(
              tooFast
                  ? 'Kamu menggunakan anggaran lebih cepat dibanding waktu yang sudah berjalan.'
                  : 'Pengeluaran berjalan sebanding dengan waktu siklus.',
              style: AppTypography.caption,
            ),
            if (summary.isEstimate) ...[
              const SizedBox(height: AppSpacing.component),
              const Text(
                'Estimasi — catatan pengeluaran belum lengkap.',
                style: AppTypography.caption,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RatioChip extends StatelessWidget {
  const _RatioChip({required this.label, required this.warning, required this.neutral});

  final String label;
  final bool warning;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final background = neutral
        ? AppColors.canvas
        : warning
            ? AppColors.warning
            : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warning) ...[
            const Icon(Icons.warning_amber_rounded,
                size: 14, color: AppColors.criticalText),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTypography.bodyStrong),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.percent,
    required this.caption,
  });

  final String label;
  final double percent;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: AppTypography.label)),
            Text(caption, style: AppTypography.bodyStrong),
          ],
        ),
        const SizedBox(height: AppSpacing.component),
        ProgressBar(value: percent),
      ],
    );
  }
}
