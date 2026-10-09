import 'package:flutter/material.dart';

import '../../../core/calc/financial_summary.dart';
import '../../../core/format/rupiah.dart';
import '../../../core/models/plan.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/category_icons.dart';
import '../../home/widgets/progress_bar.dart';

/// Baris kategori anggaran: ikon, nama, terpakai/batas, progress, status
/// (PRD 7.2.C) — dipakai Home (ringkasan) dan layar Budget.
class BudgetUsageRow extends StatelessWidget {
  const BudgetUsageRow({super.key, required this.usage, this.onTap});

  final BudgetUsage usage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final over = usage.isOver;
    final near = usage.isNearLimit;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categoryIcon(usage.category),
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usage.category, style: AppTypography.bodyStrong),
                  Text(
                    '${formatRupiah(usage.spent)} dari ${formatRupiah(usage.limit)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            if (usage.progress != null)
              Text(
                formatPercent(usage.progress!),
                style: AppTypography.bodyStrong,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.component),
        ProgressBar(
          value: usage.progressClamped,
          fill: over ? AppColors.criticalText : AppColors.primary,
        ),
        if (over || near) ...[
          const SizedBox(height: AppSpacing.component),
          Text(
            over
                ? 'Melebihi anggaran ${formatRupiah(usage.overAmount)}'
                : 'Mendekati batas',
            style: AppTypography.caption.copyWith(
              color: over ? AppColors.criticalText : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
