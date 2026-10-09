import 'package:flutter/material.dart';

import '../../core/calc/financial_summary.dart';
import '../../core/format/rupiah.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import '../home/home_sections.dart';
import '../home/widgets/progress_bar.dart';
import 'budget_controller.dart';
import 'budget_data.dart';
import 'widgets/budget_detail_sheet.dart';
import 'widgets/budget_edit_sheet.dart';
import 'widgets/budget_usage_row.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, required this.controller});

  final BudgetController controller;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
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
                child: Text('Pratinjau state (mode desain)',
                    style: AppTypography.h3),
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
                leading: const Icon(Icons.donut_small_outlined),
                title: const Text('Normal (data pengguna)'),
                onTap: () {
                  Navigator.pop(context);
                  controller.previewNormal();
                },
              ),
              ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: const Text('Kosong (belum ada anggaran)'),
                onTap: () {
                  Navigator.pop(context);
                  controller.previewEmpty();
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Mendekati batas (80%)'),
                onTap: () {
                  Navigator.pop(context);
                  controller.previewNearLimit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Melebihi anggaran'),
                onTap: () {
                  Navigator.pop(context);
                  controller.previewOverBudget();
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

  void _openEditAll() {
    final controller = widget.controller;
    final limits = controller.currentLimits;
    showBudgetEditSheet(
      context,
      controller: controller,
      title: limits.isEmpty ? 'Atur anggaran' : 'Ubah anggaran',
      initialLimits: limits.isEmpty
          ? {for (final category in categoryIcons.keys) category: 0}
          : limits,
      flexibleBudget: controller.overview?.flexibleBudget,
    );
  }

  void _openDetail(BudgetOverview overview, String category) {
    final usage = overview.usageFor(category);
    if (usage == null) return;
    showBudgetDetailSheet(
      context,
      controller: widget.controller,
      overview: overview,
      usage: usage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            _Header(
              cycleLabel: controller.overview?.cycleLabel,
              previewNote: controller.previewNote,
              onPreview: _showPreviewSheet,
            ),
            Expanded(
              child: switch (controller.status) {
                BudgetStatus.loading => const BudgetSkeleton(),
                BudgetStatus.error =>
                  HomeErrorView(onRetry: controller.load),
                BudgetStatus.ready => controller.isEmpty
                    ? _EmptyView(
                        flexibleBudget:
                            controller.overview?.flexibleBudget,
                        onSetUp: _openEditAll,
                      )
                    : _OverviewView(
                        overview: controller.overview!,
                        onEditAll: _openEditAll,
                        onOpenCategory: _openDetail,
                      ),
              },
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
                const Text('Anggaran', style: AppTypography.h1),
                Text(
                  cycleLabel == null
                      ? 'Siklus belum diatur'
                      : 'Siklus $cycleLabel',
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
              icon: const Icon(
                Icons.visibility_outlined,
                color: AppColors.primary,
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
        const SizedBox(height: AppSpacing.section),
        SectionHeader(
          title: 'Kategori',
          actionLabel: 'Edit anggaran',
          onAction: onEditAll,
        ),
        const SizedBox(height: AppSpacing.component),
        Container(
          padding: const EdgeInsets.all(AppSpacing.componentWide),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
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