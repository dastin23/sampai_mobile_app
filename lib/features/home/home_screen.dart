import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'home_controller.dart';
import 'home_data.dart';
import 'home_sections.dart';
import 'widgets/money_velocity_card.dart';
import 'widgets/safe_to_spend_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onAddExpense,
    required this.onSeeAllBudgets,
    required this.onSeeAllTransactions,
    required this.onRestartOnboarding,
  });

  final HomeController controller;
  final VoidCallback onAddExpense;
  final VoidCallback onSeeAllBudgets;
  final VoidCallback onSeeAllTransactions;
  final VoidCallback onRestartOnboarding;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _today = _normalize(DateTime.now());
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _showPreviewSheet() async {
    final controller = widget.controller;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Text('Pratinjau state (mode desain)', style: AppTypography.h3),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Hanya untuk pengujian; data contoh dihitung dengan formula produksi.',
                style: AppTypography.caption,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Memuat (skeleton)'),
              onTap: () {
                Navigator.pop(context);
                controller.previewLoading();
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Normal (data pengguna)'),
              onTap: () {
                Navigator.pop(context);
                controller.previewNormal();
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Peringatan (velocity > 1)'),
              onTap: () {
                Navigator.pop(context);
                controller.previewWarning();
              },
            ),
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Kritis (Safe-to-Spend 0)'),
              onTap: () {
                Navigator.pop(context);
                controller.previewCritical();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Offline'),
              onTap: () {
                Navigator.pop(context);
                controller.previewOffline();
              },
            ),
            ListTile(
              leading: const Icon(Icons.rocket_launch_outlined),
              title: const Text('First-use / kosong'),
              onTap: () {
                Navigator.pop(context);
                controller.previewFirstUse();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Error'),
              onTap: () {
                Navigator.pop(context);
                controller.previewError();
              },
            ),
            const SizedBox(height: 8),
          ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final status = controller.status;
        return Column(
          children: [
            _Header(
              cycleLabel: controller.data?.cycleLabel,
              previewNote: controller.previewNote,
              onPreview: _showPreviewSheet,
            ),
            Expanded(
              child: switch (status) {
                HomeStatus.loading => const HomeSkeleton(),
                HomeStatus.error => HomeErrorView(onRetry: controller.load),
                HomeStatus.ready => controller.firstUse
                    ? _FirstUseView(onStart: widget.onRestartOnboarding)
                    : _ReadyView(
                        data: controller.data!,
                        today: _today,
                        onAddExpense: widget.onAddExpense,
                        onSeeAllBudgets: widget.onSeeAllBudgets,
                        onSeeAllTransactions: widget.onSeeAllTransactions,
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
              child: FilledButton.icon(
                onPressed: widget.onAddExpense,
                icon: const Icon(Icons.add, size: 22),
                label: const Text('Catat pengeluaran'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cycleLabel,
    required this.previewNote,
    required this.onPreview,
  });

  final String? cycleLabel;
  final String? previewNote;
  final VoidCallback onPreview;

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
                const Text('Halo!', style: AppTypography.h2),
                Text(
                  cycleLabel == null ? 'Siklus belum diatur' : 'Siklus $cycleLabel',
                  style: AppTypography.caption,
                ),
                if (previewNote != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(previewNote!, style: AppTypography.caption),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            child: IconButton(
              onPressed: onPreview,
              tooltip: 'Pratinjau state',
              padding: EdgeInsets.zero,
              icon: const CircleAvatar(
                backgroundColor: AppColors.accent,
                child: Icon(Icons.person_outline, color: AppColors.primary),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
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
