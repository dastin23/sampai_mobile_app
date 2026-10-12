import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/liquid_glass.dart';
import '../budget/budget_adapters.dart';
import '../budget/providers/budget_providers.dart';
import '../transactions/models/transaction_adapters.dart';
import '../transactions/providers/transaction_providers.dart';
import 'home_data.dart';
import 'home_sections.dart';
import 'widgets/money_velocity_card.dart';
import 'widgets/safe_to_spend_card.dart';

enum _HomeStatus { loading, ready, error }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onSeeAllBudgets,
    required this.onSeeAllTransactions,
    required this.onOpenProfile,
    required this.onRestartOnboarding,
    this.userName,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onSeeAllBudgets;
  final VoidCallback onSeeAllTransactions;
  final VoidCallback onOpenProfile;
  final VoidCallback onRestartOnboarding;
  final String? userName;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = _normalize(DateTime.now());
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _retry() {
    ref.invalidate(transactionsProvider);
    final month = activeBudgetMonth(
      ref.read(appStateProvider).plan,
      _today,
    );
    ref.invalidate(budgetsProvider(month));
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(appStateProvider).plan;
    final today = _today;
    final month = activeBudgetMonth(plan, today);

    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(budgetsProvider(month));

    _HomeStatus status = _HomeStatus.ready;
    HomeData? data;
    var firstUse = false;

    if (plan == null) {
      firstUse = true;
    } else if (transactionsAsync.hasError || budgetsAsync.hasError) {
      status = _HomeStatus.error;
    } else if (transactionsAsync.isLoading || budgetsAsync.isLoading) {
      status = _HomeStatus.loading;
    } else {
      data = HomeData.fromInputs(
        plan: plan,
        transactions: (transactionsAsync.value ?? const [])
            .map(toExpenseTransaction)
            .toList(),
        budgets: toBudgetCategories(budgetsAsync.value ?? const []),
        today: today,
        offline: false,
        updatedAt: null,
      );
    }

    return Column(
      children: [
        _Header(
          cycleLabel: data?.cycleLabel,
          userName: widget.userName,
          onOpenProfile: widget.onOpenProfile,
        ),
        Expanded(
          child: switch (status) {
            _HomeStatus.loading => const HomeSkeleton(),
            _HomeStatus.error => HomeErrorView(onRetry: _retry),
            _HomeStatus.ready => firstUse
                ? _FirstUseView(onStart: widget.onRestartOnboarding)
                : _ReadyView(
                    data: data!,
                    today: today,
                    onAddExpense: widget.onAddExpense,
                    onSeeAllBudgets: widget.onSeeAllBudgets,
                    onSeeAllTransactions: widget.onSeeAllTransactions,
                  ),
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
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
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cycleLabel,
    required this.userName,
    required this.onOpenProfile,
  });

  final String? cycleLabel;
  final String? userName;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final name = userName?.trim();
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
                Text(
                  name == null || name.isEmpty ? 'Halo!' : 'Halo, $name!',
                  style: AppTypography.h2,
                ),
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

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    required this.data,
    required this.today,
    required this.onAddExpense,
    required this.onSeeAllBudgets,
    required this.onSeeAllTransactions,
  });

  final HomeData data;
  final DateTime today;
  final VoidCallback onAddExpense;
  final VoidCallback onSeeAllBudgets;
  final VoidCallback onSeeAllTransactions;

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
        if (data.offline) ...[
          OfflineBanner(updatedAt: data.updatedAt),
          const SizedBox(height: AppSpacing.componentWide),
        ],
        SafeToSpendCard(
          summary: data.summary,
          onShowCalc: () =>
              showCalculationSheet(context, summary: data.summary),
        ),
        const SizedBox(height: AppSpacing.section),
        MoneyVelocityCard(summary: data.summary),
        const SizedBox(height: AppSpacing.section),
        CycleSummarySection(data: data),
        const SizedBox(height: AppSpacing.section),
        BudgetSummarySection(
          data: data,
          onSeeAll: onSeeAllBudgets,
          onSetUpBudget: onSeeAllBudgets,
        ),
        const SizedBox(height: AppSpacing.section),
        UpcomingBillsSection(data: data, today: today),
        const SizedBox(height: AppSpacing.section),
        RecentTransactionsSection(
          data: data,
          today: today,
          onSeeAll: onSeeAllTransactions,
          onAddExpense: onAddExpense,
        ),
      ],
    );
  }
}

class _FirstUseView extends StatelessWidget {
  const _FirstUseView({required this.onStart});

  final VoidCallback onStart;

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
        GlassSurface(
          kind: GlassKind.hero,
          radius: AppSpacing.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AMAN DIBELANJAKAN', style: AppTypography.label),
              const SizedBox(height: AppSpacing.componentWide),
              const Text(
                'Atur siklus gajimu untuk mulai menghitung.',
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.component),
              const Text(
                'Lengkapi gaji bersih, tanggal gajian, tagihan tetap, dan '
                'target tabungan lewat onboarding.',
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.section),
              FilledButton(
                onPressed: onStart,
                child: const Text('Selesaikan pengaturan'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
