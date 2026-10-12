import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state/app_providers.dart';
import '../../core/calc/salary_cycle.dart';
import '../../core/format/rupiah.dart';
import '../../core/models/plan.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/liquid_glass.dart';
import '../home/home_sections.dart';
import 'models/transaction_model.dart';
import 'providers/transaction_providers.dart';
import 'transactions_data.dart';
import 'widgets/transaction_editor_sheet.dart';
import 'widgets/transaction_tile.dart';

/// Layar daftar transaksi siklus & riwayat lengkap (tab Transaksi / "Lihat
/// semua", PRD 5.2.F). Sumber data: tabel `transactions` via
/// [TransactionRepository] (Supabase). Mendukung catat/ubah/hapus.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionScope _scope = TransactionScope.cycle;
  SalaryCycle? _period;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(appStateProvider).plan;
    final transactionsAsync = ref.watch(transactionsProvider);

    final source = transactionsAsync.value ?? const <FinanceTransaction>[];
    final byId = {for (final t in source) t.id: t};
    final mapped = source.map(_toExpenseTransaction).toList();

    final data = plan == null
        ? null
        : TransactionsData.fromInputs(
            plan: plan,
            transactions: mapped,
            today: DateTime.now(),
            scope: _scope,
            period: _period,
          );

    return Column(
      children: [
        _Header(cycleLabel: data?.cycleLabel),
        Expanded(
          child: switch (transactionsAsync) {
            AsyncValue(hasError: true) => HomeErrorView(
                onRetry: () => ref.invalidate(transactionsProvider),
              ),
            AsyncValue(isLoading: true) => const TransactionsSkeleton(),
            _ when plan == null => _NoPlanView(),
            _ => _TransactionsView(
                data: data!,
                today: DateTime.now(),
                onAddExpense: () => _openEditor('expense'),
                onEditTransaction: (transaction) =>
                    _openEditorFor(byId[transaction.id]),
                onSelectCurrent: _selectCurrent,
                onSelectCycle: (cycle) => setState(() {
                  _scope = TransactionScope.cycle;
                  _period = cycle;
                }),
                onSelectAll: () => setState(() {
                  _scope = TransactionScope.all;
                  _period = null;
                }),
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
                  onPressed: () => _openEditor('income'),
                  icon: const Icon(Icons.arrow_downward, size: 20),
                  label: const Text('Catat pemasukan'),
                ),
              ),
              const SizedBox(width: AppSpacing.component),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openEditor('expense'),
                  icon: const Icon(Icons.add, size: 22),
                  label: const Text('Catat pengeluaran'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectCurrent() {
    setState(() {
      _scope = TransactionScope.cycle;
      _period = null;
    });
  }

  Future<void> _openEditorFor(FinanceTransaction? editing) async {
    if (editing == null) return;
    await _openEditor(editing.isIncome ? 'income' : 'expense', editing: editing);
  }

  Future<void> _openEditor(String type, {FinanceTransaction? editing}) async {
    final result = await showTransactionEditorSheet(
      context,
      type: type,
      editing: editing,
    );
    if (result == null || !mounted) return;
    final noun = type == 'income' ? 'Pemasukan' : 'Pengeluaran';
    final message = switch (result) {
      TransactionEditorResult.deleted => '$noun dihapus',
      TransactionEditorResult.saved => editing == null
          ? '$noun tersimpan'
          : '$noun diperbarui',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Petakan transaksi dari backend ke model tampilan [ExpenseTransaction].
ExpenseTransaction _toExpenseTransaction(FinanceTransaction transaction) {
  final categoryName = transaction.categoryName?.trim();
  final category =
      categoryName == null || categoryName.isEmpty ? 'Lainnya' : categoryName;
  final description = transaction.description?.trim();
  final title = description == null || description.isEmpty
      ? category
      : description;
  final amount = transaction.amount.round();
  return transaction.isIncome
      ? ExpenseTransaction.income(
          id: transaction.id,
          title: title,
          category: category,
          amount: amount,
          date: transaction.transactionDate,
        )
      : ExpenseTransaction(
          id: transaction.id,
          title: title,
          category: category,
          amount: amount,
          date: transaction.transactionDate,
        );
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
    required this.onEditTransaction,
    required this.onSelectCurrent,
    required this.onSelectCycle,
    required this.onSelectAll,
  });

  final TransactionsData data;
  final DateTime today;
  final VoidCallback onAddExpense;
  final ValueChanged<ExpenseTransaction> onEditTransaction;
  final VoidCallback onSelectCurrent;
  final ValueChanged<SalaryCycle> onSelectCycle;
  final VoidCallback onSelectAll;

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
        _PeriodFilter(
          data: data,
          onSelectCurrent: onSelectCurrent,
          onSelectCycle: onSelectCycle,
          onSelectAll: onSelectAll,
        ),
        const SizedBox(height: AppSpacing.componentWide),
        if (data.isEmpty)
          _EmptyCard(data: data, onAddExpense: onAddExpense)
        else
          GlassSurface(
            kind: GlassKind.raised,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.componentWide,
              vertical: AppSpacing.component,
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
                      onTap: () => onEditTransaction(data.transactions[i]),
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

/// Pemilih periode daftar: siklus berjalan, siklus lain, atau seluruh riwayat
/// (filter transaksi berdasarkan periode, PRD 7.2).
class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({
    required this.data,
    required this.onSelectCurrent,
    required this.onSelectCycle,
    required this.onSelectAll,
  });

  final TransactionsData data;
  final VoidCallback onSelectCurrent;
  final ValueChanged<SalaryCycle> onSelectCycle;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final others = data.availablePeriods
        .where((cycle) => cycle.start != data.cycle.start)
        .toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PeriodChip(
            label: 'Siklus ini',
            selected: !data.isAllScope && data.isCurrentPeriod,
            onSelected: onSelectCurrent,
          ),
          const SizedBox(width: AppSpacing.component),
          _PeriodChip(
            label: 'Semua transaksi',
            selected: data.isAllScope,
            onSelected: onSelectAll,
          ),
          for (final cycle in others) ...[
            const SizedBox(width: AppSpacing.component),
            _PeriodChip(
              label: cycle.label,
              selected: !data.isAllScope && data.period?.start == cycle.start,
              onSelected: () => onSelectCycle(cycle),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      backgroundColor: AppColors.surface.withValues(alpha: 0.6),
      selectedColor: AppColors.brandSoft,
      side: const BorderSide(color: AppColors.borderSoft),
      labelStyle: AppTypography.bodyStrong.copyWith(
        color: selected ? AppColors.primaryStrong : AppColors.primary,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final TransactionsData data;

  @override
  Widget build(BuildContext context) {
    final scopeLabel = data.periodLabel;
    return GlassSurface(
      kind: GlassKind.hero,
      radius: AppSpacing.heroRadius,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo $scopeLabel', style: AppTypography.label),
          const SizedBox(height: AppSpacing.componentWide),
          Text(
            formatRupiah(data.balance),
            style: AppTypography.display.copyWith(
              color: data.balance < 0 ? AppColors.criticalText : null,
            ),
          ),
          const SizedBox(height: AppSpacing.componentWide),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Pemasukan',
                  value: '+${formatRupiah(data.totalIncome)}',
                  color: AppColors.successText,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Pengeluaran',
                  value: '−${formatRupiah(data.totalExpense)}',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.componentWide),
          Text(
            'Terpakai siklus ini ${formatRupiah(data.totalSpent)}',
            style: AppTypography.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.component),
          Text(
            'Sisa anggaran fleksibel '
            '${formatRupiah(data.remainingFlexible)}',
            style: AppTypography.bodyStrong,
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyStrong.copyWith(color: color),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.data, required this.onAddExpense});

  final TransactionsData data;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final label = data.isAllScope
        ? 'Belum ada transaksi tercatat'
        : 'Belum ada transaksi di ${data.periodLabel}';
    return GlassSurface(
      kind: GlassKind.raised,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.body,
          ),
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
