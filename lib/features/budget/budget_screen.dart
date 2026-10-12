import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state/app_providers.dart';
import '../../core/calc/financial_summary.dart';
import '../../core/format/rupiah.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/liquid_glass.dart';
import '../home/home_sections.dart';
import '../home/widgets/progress_bar.dart';
import '../transactions/models/transaction_adapters.dart';
import '../transactions/models/transaction_model.dart';
import '../transactions/providers/transaction_providers.dart';
import 'budget_adapters.dart';
import 'budget_data.dart';
import 'providers/budget_providers.dart';
import 'widgets/budget_detail_sheet.dart';
import 'widgets/budget_edit_sheet.dart';
import 'widgets/budget_usage_row.dart';

enum _BudgetStatus { loading, ready, error }

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key, required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late final DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
  }

  Map<String, int> _limitsOf(BudgetOverview? overview) => {
        if (overview != null)
          for (final usage in overview.usages) usage.category: usage.limit,
      };

  void _retry() {
    final plan = ref.read(appStateProvider).plan;
    ref.invalidate(budgetsProvider(activeBudgetMonth(plan, _today)));
    ref.invalidate(transactionsProvider);
  }

  Future<void> _saveLimits(Map<String, int> limits, BudgetOverview? overview) async {
    final plan = ref.read(appStateProvider).plan;
    final month = activeBudgetMonth(plan, _today);
    final categories =
        ref.read(transactionCategoriesProvider).value ?? const [];
    final byName = {
      for (final category in categories)
        if (category.type == 'expense') category.name: category.id,
    };
    final repository = ref.read(budgetRepositoryProvider);
    final merged = <String, int>{..._limitsOf(overview)}..addAll(limits);

    for (final entry in merged.entries) {
      final categoryId = byName[entry.key];
      if (categoryId == null) continue;
      await repository.setBudget(
        categoryId: categoryId,
        month: month,
        amount: entry.value.toDouble(),
      );
    }
    if (mounted) ref.invalidate(budgetsProvider(month));
  }

  void _openEditAll(BudgetOverview? overview, List<TransactionCategory> categories) {
    final current = _limitsOf(overview);
    final initial = <String, int>{
      for (final category in categories)
        if (category.type == 'expense') category.name: current[category.name] ?? 0,
    };
    for (final entry in current.entries) {
      initial.putIfAbsent(entry.key, () => entry.value);
    }
    showBudgetEditSheet(
      context,
      title: current.isEmpty ? 'Atur anggaran' : 'Ubah anggaran',
      initialLimits: initial,
      currentLimits: current,
      onSave: (limits) => _saveLimits(limits, overview),
      flexibleBudget: overview?.flexibleBudget,
    );
  }

  void _openDetail(BudgetOverview overview, String category) {
    final usage = overview.usageFor(category);
    if (usage == null) return;
    showBudgetDetailSheet(
      context,
      overview: overview,
      usage: usage,
      currentLimits: _limitsOf(overview),
      onSave: (limits) => _saveLimits(limits, overview),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(appStateProvider).plan;
    final today = _today;
    final month = activeBudgetMonth(plan, today);

    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(budgetsProvider(month));
    final categories =
        ref.watch(transactionCategoriesProvider).value ?? const [];

    _BudgetStatus status = _BudgetStatus.ready;
    BudgetOverview? overview;
    var empty = false;

    if (plan == null) {
      empty = true;
    } else if (transactionsAsync.hasError || budgetsAsync.hasError) {
      status = _BudgetStatus.error;
    } else if (transactionsAsync.isLoading || budgetsAsync.isLoading) {
      status = _BudgetStatus.loading;
    } else {
      overview = BudgetOverview.fromInputs(
        plan: plan,
        transactions: (transactionsAsync.value ?? const [])
            .map(toExpenseTransaction)
            .toList(),
        budgets: toBudgetCategories(budgetsAsync.value ?? const []),
        today: today,
      );
      if (overview.isEmpty) empty = true;
    }

    return Column(
      children: [
        _Header(
          cycleLabel: overview?.cycleLabel,
          onOpenProfile: widget.onOpenProfile,
        ),
        Expanded(
          child: switch (status) {
            _BudgetStatus.loading => const BudgetSkeleton(),
            _BudgetStatus.error => HomeErrorView(onRetry: _retry),
            _BudgetStatus.ready => empty
                ? _EmptyView(
                    flexibleBudget: overview?.flexibleBudget,
                    onSetUp: () => _openEditAll(overview, categories),
                  )
                : _OverviewView(
                    overview: overview!,
                    onEditAll: () => _openEditAll(overview, categories),
                    onOpenCategory: _openDetail,
                  ),
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cycleLabel,
    required this.onOpenProfile,
  });

  final String? cycleLabel;
  final VoidCallback onOpenProfile;

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
                const Text('Anggaran', style: AppTypography.h1),
                Text(
                  cycleLabel == null
                      ? 'Siklus belum diatur'
                      : 'Siklus $cycleLabel',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          SizedBox(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            child: IconButton(
              onPressed: onOpenProfile,
              tooltip: 'Buka profil',
              padding: EdgeInsets.zero,
              icon: GlassSurface(
                kind: GlassKind.raised,
                radius: 999,
                color: AppColors.brandSoft.withValues(alpha: 0.75),
                borderColor: Colors.white.withValues(alpha: 0.8),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.person_outline,
                    size: 22,
                    color: AppColors.primaryStrong,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView({
    required this.overview,
    required this.onEditAll,
    required this.onOpenCategory,
  });

  final BudgetOverview overview;
  final VoidCallback onEditAll;
  final void Function(BudgetOverview overview, String category) onOpenCategory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.component,
        AppSpacing.pageHorizontal,
        AppSpacing.section,
      ),
      children: [
        _TotalBudgetCard(overview: overview),
        if (overview.overBudgetCount > 0 || overview.nearLimitCount > 0) ...[
          const SizedBox(height: AppSpacing.componentWide),
          _BudgetWarningBanner(overview: overview),
        ],
        const SizedBox(height: AppSpacing.section),
        SectionHeader(
          title: 'Kategori',
          actionLabel: 'Edit anggaran',
          onAction: onEditAll,
        ),
        const SizedBox(height: AppSpacing.component),
        GlassSurface(
          kind: GlassKind.raised,
          padding: const EdgeInsets.all(AppSpacing.componentWide),
          child: Column(
            children: [
              for (var i = 0; i < overview.usages.length; i++) ...[
                if (i > 0) const Divider(height: 20),
                BudgetUsageRow(
                  usage: overview.usages[i],
                  onTap: () =>
                      onOpenCategory(overview, overview.usages[i].category),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Kartu total anggaran fleksibel (PRD 7.2.B).
class _TotalBudgetCard extends StatelessWidget {
  const _TotalBudgetCard({required this.overview});

  final BudgetOverview overview;

  @override
  Widget build(BuildContext context) {
    final progress = overview.progress;
    return GlassSurface(
      kind: GlassKind.hero,
      radius: AppSpacing.heroRadius,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anggaran fleksibel',
            style: AppTypography.label,
          ),
          const SizedBox(height: AppSpacing.componentWide),
          Text(
            formatRupiah(overview.flexibleBudget),
            style: AppTypography.display,
          ),
          const SizedBox(height: AppSpacing.componentWide),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terpakai ${formatRupiah(overview.totalSpent)}',
                  style: AppTypography.body,
                ),
              ),
              Text(
                'Sisa ${formatRupiah(overview.remainingFlexible)}',
                style: AppTypography.bodyStrong,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.componentWide),
          ProgressBar(
            value: (progress ?? 0).clamp(0, 1),
            fill: AppColors.primaryStrong,
            track: AppColors.surface.withValues(alpha: 0.55),
          ),
          const SizedBox(height: AppSpacing.component),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              progress == null ? '—' : formatPercent(progress),
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner ringkasan peringatan anggaran: kategori yang mendekati atau
/// melewati batas (PRD 7.2.C).
class _BudgetWarningBanner extends StatelessWidget {
  const _BudgetWarningBanner({required this.overview});

  final BudgetOverview overview;

  @override
  Widget build(BuildContext context) {
    final over = overview.overBudgetCount;
    final near = overview.nearLimitCount;
    final isOver = over > 0;
    final message = isOver
        ? 'Kategori melewati anggaran: $over'
        : 'Kategori mendekati batas: $near';
    final color = isOver ? AppColors.criticalText : AppColors.warning;
    final icon = isOver ? Icons.error_outline : Icons.speed;
    return GlassSurface(
      kind: GlassKind.raised,
      padding: const EdgeInsets.all(AppSpacing.componentWide),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.component),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyStrong.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.flexibleBudget, required this.onSetUp});

  final int? flexibleBudget;
  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final flexible = flexibleBudget;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.component,
        AppSpacing.pageHorizontal,
        AppSpacing.section,
      ),
      children: [
        GlassSurface(
          kind: GlassKind.raised,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Belum ada anggaran kategori.',
                style: AppTypography.h3,
              ),
              const SizedBox(height: AppSpacing.component),
              Text(
                flexible == null
                    ? 'Atur siklus gajimu dulu, lalu alokasikan anggaran '
                        'fleksibel ke tiap kategori sesuai kebutuhanmu.'
                    : 'Alokasikan anggaran fleksibel '
                        '${formatRupiah(flexible)} ke tiap kategori sesuai '
                        'kebutuhanmu.',
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.section),
              FilledButton(
                onPressed: onSetUp,
                child: const Text('Atur anggaran'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton loading Budget (PRD 7.3).
class BudgetSkeleton extends StatelessWidget {
  const BudgetSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const box = _SkeletonBox();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.component,
        AppSpacing.pageHorizontal,
        AppSpacing.section,
      ),
      children: const [
        SizedBox(height: 8),
        Row(children: [SizedBox(width: 160, height: 24, child: box)]),
        SizedBox(height: AppSpacing.section),
        SizedBox(height: 180, child: box),
        SizedBox(height: AppSpacing.section),
        SizedBox(height: 220, child: box),
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
