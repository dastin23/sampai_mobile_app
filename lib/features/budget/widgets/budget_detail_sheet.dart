import 'package:flutter/material.dart';

import '../../../core/calc/financial_summary.dart';
import '../../../core/format/date.dart';
import '../../../core/format/rupiah.dart';
import '../../../core/models/plan.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/category_icons.dart';
import '../budget_controller.dart';
import '../budget_data.dart';
import 'budget_edit_sheet.dart';

/// Detail kategori (PRD 7.2.D): anggaran, terpakai, sisa, progress,
/// daftar transaksi, dan aksi "Ubah anggaran".
Future<void> showBudgetDetailSheet(
  BuildContext context, {
  required BudgetController controller,
  required BudgetOverview overview,
  required BudgetUsage usage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: AppSpacing.componentWide),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon(usage.category),
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usage.category, style: AppTypography.h3),
                        Text('Anggaran kategori', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.componentWide),
              _DetailRow(
                label: 'Anggaran periode',
                value: formatRupiah(usage.limit),
              ),
              _DetailRow(
                label: 'Total terpakai',
                value: formatRupiah(usage.spent),
              ),
              _DetailRow(
                label: 'Sisa',
                value: usage.isOver
                    ? 'Melebihi ${formatRupiah(usage.overAmount)}'
                    : formatRupiah(usage.remaining),
                strong: true,
              ),
              const SizedBox(height: AppSpacing.componentWide),
              if (usage.progress != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.component),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${formatPercent(usage.progress!)} terpakai',
                      style: AppTypography.caption,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.section),
              const Text('Transaksi', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.component),
              _TransactionList(transactions: overview.transactionsIn(usage.category)),
              const SizedBox(height: AppSpacing.section),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  showBudgetEditSheet(
                    context,
                    controller: controller,
                    title: 'Ubah anggaran',
                    initialLimits: {usage.category: usage.limit},
                    flexibleBudget: overview.flexibleBudget,
                  );
                },
                child: const Text('Ubah anggaran'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.body)),
          Text(
            value,
            style: strong ? AppTypography.bodyStrong : AppTypography.body,
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});

  final List<ExpenseTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Text(
        'Belum ada transaksi di kategori ini.',
        style: AppTypography.caption,
      );
    }
    return Column(
      children: [
        for (var i = 0; i < transactions.length; i++) ...[
          if (i > 0) const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transactions[i].title,
                      style: AppTypography.bodyStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatDayMonth(transactions[i].date),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '−${formatRupiah(transactions[i].amount)}',
                style: AppTypography.bodyStrong,
              ),
            ],
          ),
        ],
      ],
    );
  }
}