import 'package:flutter/material.dart';

import '../../../core/calc/financial_summary.dart';
import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_theme.dart';

/// Kartu Safe-to-Spend (PRD 5.2.B).
class SafeToSpendCard extends StatelessWidget {
  const SafeToSpendCard({super.key, required this.summary, this.onShowCalc});

  final FinancialSummary summary;
  final VoidCallback? onShowCalc;

  @override
  Widget build(BuildContext context) {
    final critical = summary.isCritical;
    final endsToday = summary.cycleEndsToday;
    final background =
        critical ? AppColors.criticalBackground : AppColors.accent;
    final valueColor =
        critical ? AppColors.criticalText : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'AMAN DIBELANJAKAN',
                  style: AppTypography.label.copyWith(
                    color: valueColor,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (summary.isEstimate)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('Estimasi', style: AppTypography.caption),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.componentWide),
          Text(
            critical
                ? formatRupiah(0)
                : endsToday
                    ? formatRupiah(summary.remainingFlexible)
                    : '${formatRupiah(summary.safeToSpendPerDay)}/hari',
            style: AppTypography.display.copyWith(color: valueColor),
          ),
          const SizedBox(height: AppSpacing.component),
          Text(
            critical
                ? 'Anggaran harian sudah terpakai.'
                : endsToday
                    ? 'Siklus berakhir hari ini — ini sisa anggaran fleksibel periode ini.'
                    : 'Rata-rata per hari sampai gajian',
            style: AppTypography.body.copyWith(
              color: critical ? AppColors.criticalText : AppColors.secondaryText,
            ),
          ),
          if (summary.isEstimate && !critical) ...[
            const SizedBox(height: AppSpacing.component),
            const Text(
              'Lengkapi saldo atau catatan pengeluaran agar hasil lebih akurat.',
              style: AppTypography.caption,
            ),
          ],
          const SizedBox(height: AppSpacing.componentWide),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.componentWide),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Sisa uang fleksibel', style: AppTypography.body),
              ),
              Text(
                formatRupiah(summary.remainingFlexible),
                style: AppTypography.bodyStrong,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.component),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Hari tersisa', style: AppTypography.body),
              ),
              Text(
                summary.cycleEndsToday
                    ? 'Siklus berakhir hari ini'
                    : '${summary.remainingDays} hari tersisa',
                style: AppTypography.bodyStrong,
              ),
            ],
          ),
          if (onShowCalc != null) ...[
            const SizedBox(height: AppSpacing.component),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onShowCalc,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(
                    AppSpacing.minTouchTarget,
                    AppSpacing.minTouchTarget,
                  ),
                  alignment: Alignment.centerLeft,
                ),
                child: const Text(
                  'Cara hitungnya',
                  style: AppTypography.bodyStrong,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet penjelasan komponen kalkulasi (PRD 5.2.B).
Future<void> showCalculationSheet(
  BuildContext context, {
  required FinancialSummary summary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Cara hitungnya', style: AppTypography.h2),
            const SizedBox(height: 8),
            const Text(
              'Angka harian adalah estimasi, bukan saldo rekening.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 16),
            _CalcRow(
              label: 'Gaji bersih',
              value: formatRupiah(summary.availableForCycle),
            ),
            _CalcRow(
              label: 'Dikurangi tagihan belum dibayar',
              value: '-${formatRupiah(summary.reservedUnpaidBills)}',
            ),
            _CalcRow(
              label: 'Dikurangi target tabungan belum didanai',
              value: '-${formatRupiah(summary.unfundedSavingsTarget)}',
            ),
            _CalcRow(
              label: 'Dikurangi safety buffer',
              value: '-${formatRupiah(summary.safetyBuffer)}',
            ),
            _CalcRow(
              label: 'Dikurangi pengeluaran fleksibel tercatat',
              value: '-${formatRupiah(summary.discretionarySpent)}',
            ),
            const Divider(height: 24),
            _CalcRow(
              label: 'Sisa anggaran fleksibel',
              value: formatRupiah(summary.remainingFlexible),
              strong: true,
            ),
            _CalcRow(
              label: 'Dibagi ${summary.remainingDays} hari tersisa',
              value:
                  summary.cycleEndsToday ? '—' : formatRupiah(summary.safeToSpendPerDay),
              strong: true,
            ),
            if (summary.isEstimate) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Hasil masih estimasi karena catatan pengeluaran belum lengkap.',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: strong ? AppTypography.bodyStrong : AppTypography.body,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: strong ? AppTypography.bodyStrong : AppTypography.body,
          ),
        ],
      ),
    );
  }
}
