import 'package:flutter/material.dart';

import '../../core/format/date.dart';
import '../../core/format/rupiah.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../budget/widgets/budget_usage_row.dart';
import 'home_data.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.h3)),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(
                AppSpacing.minTouchTarget,
                AppSpacing.minTouchTarget,
              ),
            ),
            child: Text(actionLabel!, style: AppTypography.bodyStrong),
          ),
      ],
    );
  }
}

/// Ringkasan anggaran di Home — maksimal 3 kategori (PRD 5.2.D).
class BudgetSummarySection extends StatelessWidget {
  const BudgetSummarySection({
    super.key,
    required this.data,
    required this.onSeeAll,
    required this.onSetUpBudget,
  });

  final HomeData data;
  final VoidCallback onSeeAll;
  final VoidCallback onSetUpBudget;

  @override
  Widget build(BuildContext context) {
    final usages = data.topBudgetUsages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Anggaran siklus ini',
          actionLabel: 'Lihat semua',
          onAction: onSeeAll,
        ),
        if (usages.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Belum ada anggaran kategori.', style: AppTypography.body),
                const SizedBox(height: AppSpacing.componentWide),
                OutlinedButton(
                  onPressed: onSetUpBudget,
                  child: const Text('Atur anggaran'),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.componentWide),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < usages.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  BudgetUsageRow(usage: usages[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}


/// Tagihan yang jatuh tempo dalam siklus berjalan (PRD 5.2.E).
class UpcomingBillsSection extends StatelessWidget {
  const UpcomingBillsSection({super.key, required this.data, required this.today});

  final HomeData data;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final bills = data.upcomingBills;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Tagihan terdekat'),
        if (bills.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Tidak ada tagihan terdekat.',
              style: AppTypography.body,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.componentWide,
              vertical: AppSpacing.component,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < bills.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bills[i].name, style: AppTypography.bodyStrong),
                              Text(
                                'Jatuh tempo ${formatDayMonth(bills[i].dueDate)}',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(bills[i].amount),
                          style: AppTypography.bodyStrong,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Transaksi terbaru dalam siklus (PRD 5.2.F).
class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({
    super.key,
    required this.data,
    required this.today,
    required this.onSeeAll,
    required this.onAddExpense,
  });

  final HomeData data;
  final DateTime today;
  final VoidCallback onSeeAll;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final transactions = data.recentTransactions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Transaksi terbaru',
          actionLabel: 'Lihat semua',
          onAction: onSeeAll,
        ),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Belum ada pengeluaran tercatat', style: AppTypography.body),
                const SizedBox(height: AppSpacing.componentWide),
                OutlinedButton.icon(
                  onPressed: onAddExpense,
                  icon: const Icon(Icons.add, size: 20),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  label: const Text('Catat pengeluaran pertama'),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.componentWide,
              vertical: AppSpacing.component,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            categoryIcon(transactions[i].category),
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                transactions[i].category,
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '−${formatRupiah(transactions[i].amount)}',
                              style: AppTypography.bodyStrong,
                            ),
                            Text(
                              formatRelativeDay(transactions[i].date, today),
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Skeleton loading Home (PRD 5.4).
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const box = _SkeletonBox();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: const [
        SizedBox(height: 8),
        Row(children: [SizedBox(width: 120, height: 24, child: box)]),
        SizedBox(height: AppSpacing.section),
        SizedBox(height: 230, child: box),
        SizedBox(height: AppSpacing.section),
        SizedBox(height: 170, child: box),
        SizedBox(height: AppSpacing.section),
        SizedBox(height: 120, child: box),
        SizedBox(height: AppSpacing.section),
        SizedBox(height: 140, child: box),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
    );
  }
}

/// Banner offline (PRD 5.4).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.updatedAt});

  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              updatedAt == null
                  ? 'Data terakhir belum pernah diperbarui.'
                  : 'Data terakhir diperbarui ${formatDateTime(updatedAt!)}.',
              style: AppTypography.caption.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// State error Home (PRD 5.4).
class HomeErrorView extends StatelessWidget {
  const HomeErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.secondaryText),
            const SizedBox(height: AppSpacing.componentWide),
            const Text('Data belum bisa dimuat.', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.component),
            const Text(
              'Kami pertahankan data terakhir di perangkat bila tersedia.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.section),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
