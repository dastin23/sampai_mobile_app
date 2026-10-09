import 'package:flutter/material.dart';

import '../../core/format/date.dart';
import '../../core/format/rupiah.dart';
import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Profil — ringkasan rencana finansial dan reset pengaturan (tab ke-4).
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({
    super.key,
    required this.appState,
    required this.onRestartOnboarding,
  });

  final AppState appState;
  final VoidCallback onRestartOnboarding;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final plan = appState.plan;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.componentWide,
            AppSpacing.pageHorizontal,
            AppSpacing.section,
          ),
          children: [
            const Text('Profil', style: AppTypography.h1),
            const SizedBox(height: AppSpacing.component),
            Text(
              plan == null
                  ? 'Belum ada rencana finansial.'
                  : 'Ringkasan rencana finansialmu.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.section),
            if (plan != null) _PlanCard(plan: plan),
            const SizedBox(height: AppSpacing.section),
            _RestartCard(onRestart: onRestartOnboarding),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final bills = plan.activeBills;
    final paydayDate = plan.nextPayday;
    final rows = <(String, String)>[
      ('Gaji bersih per siklus', '${formatRupiah(plan.netIncome)} / siklus'),
      ('Tanggal gajian', 'Setiap tanggal ${plan.paydayDay}'),
      (
        'Siklus berjalan berakhir',
        paydayDate == null
            ? formatDayMonth(plan.cycleFor(DateTime.now()).end)
            : formatShortDate(paydayDate),
      ),
      ('Target tabungan', '${formatRupiah(plan.savingsTarget)} / siklus'),
      (
        'Tagihan tetap',
        '${bills.length} tagihan · ${formatRupiah(plan.activeBillsTotal)} / siklus',
      ),
    ];
    return Container(
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
          const Text('Rencana finansial', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.component),
          for (final (label, value) in rows) ...[
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(label, style: AppTypography.body),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: AppTypography.bodyStrong,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RestartCard extends StatelessWidget {
  const _RestartCard({required this.onRestart});

  final VoidCallback onRestart;

  Future<void> _confirm(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Mulai ulang pengaturan?'),
        content: const Text(
          'Semua data lokal (rencana, anggaran, dan transaksi) akan hilang '
          'dan kamu akan kembali ke onboarding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mulai ulang'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) onRestart();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text('Data lokal', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.component),
          const Text(
            'Data tersimpan hanya di perangkat ini. Mulai ulang untuk '
            'menghapusnya dan mengatur dari awal.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.section),
          OutlinedButton.icon(
            onPressed: () => _confirm(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.restart_alt, size: 20),
            label: const Text('Mulai ulang pengaturan'),
          ),
        ],
      ),
    );
  }
}