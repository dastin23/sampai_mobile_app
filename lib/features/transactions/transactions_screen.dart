import 'package:flutter/material.dart';

import '../../core/format/rupiah.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_sections.dart';
import 'transactions_controller.dart';
import 'transactions_data.dart';
import 'widgets/transaction_tile.dart';

/// Layar daftar transaksi siklus (tab Transaksi / "Lihat semua", PRD 5.2.F).
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.controller,
    required this.onAddExpense,
    required this.onAddIncome,
  });

  final TransactionsController controller;
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            _Header(
              cycleLabel: controller.data?.cycleLabel,
            ),
            Expanded(
              child: switch (controller.status) {
                TransactionsStatus.loading => const TransactionsSkeleton(),
                TransactionsStatus.error =>
                  HomeErrorView(onRetry: controller.load),
                TransactionsStatus.ready => controller.noPlan ||
                        controller.data == null
                    ? _NoPlanView()
                    : _TransactionsView(
                        data: controller.data!,
                        today: DateTime.now(),
                        onAddExpense: widget.onAddExpense,
                      ),
              },
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.component,
                AppSpacing.pageHorizontal,
                AppSpacing.componentWide,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onAddIncome,
                      icon: const Icon(Icons.arrow_downward, size: 20),
                      label: const Text('Catat pemasukan'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.component),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onAddExpense,
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text('Catat pengeluaran'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cycleLabel});

  final String? cycleLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.componentWide,
        AppSpacing.pageHorizontal,
        AppSpacing.component,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transaksi', style: AppTypography.h1),
                Text(
                  cycleLabel == null
                      ? 'Siklus belum diatur'
                      : 'Siklus $cycleLabel',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView({
    required this.data,
    required this.today,
    required this.onAddExpense,
  });

  final TransactionsData data;
  final DateTime today;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        0,
        AppSpacing.pageHorizontal,
        AppSpacing.section,
      ),
      children: [
        _SummaryCard(data: data),
        const SizedBox(height: AppSpacing.section),
        const SectionHeader(title: 'Semua transaksi', actionLabel: null),
        const SizedBox(height: AppSpacing.component),
        if (data.isEmpty)
          _EmptyCard(onAddExpense: onAddExpense)
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
                for (var i = 0; i < data.transactions.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TransactionTile(
                      transaction: data.transactions[i],
                      today: today,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final TransactionsData data;

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
          const Text('Terpakai siklus ini', style: AppTypography.label),
          const SizedBox(height: AppSpacing.componentWide),
          Text(
            formatRupiah(data.totalSpent),
            style: AppTypography.display,
          ),
          const SizedBox(height: AppSpacing.componentWide),
          Text(
            'Sisa anggaran fleksibel '
            '${formatRupiah(data.remainingFlexible)}',
            style: AppTypography.bodyStrong,
          ),
          if (data.totalIncome > 0) ...[
            const SizedBox(height: AppSpacing.component),
            Text(
              'Pemasukan tercatat ${formatRupiah(data.totalIncome)}',
              style: AppTypography.bodyStrong.copyWith(
                color: AppColors.successText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onAddExpense});

  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _NoPlanView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.cardPadding),
        child: Text(
          'Atur siklus gajimu dulu untuk mulai mencatat pengeluaran.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Skeleton loading daftar transaksi.
class TransactionsSkeleton extends StatelessWidget {
  const TransactionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const box = _SkeletonBox();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        0,
        AppSpacing.pageHorizontal,
        AppSpacing.section,
      ),
      children: const [
        SizedBox(height: 8),
        Row(children: [SizedBox(width: 160, height: 24, child: box)]),
        SizedBox(height: AppSpacing.section),
        SizedBox(height: 160, child: box),
        SizedBox(height: AppSpacing.section),
        SizedBox(height: 240, child: box),
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