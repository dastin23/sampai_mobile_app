import 'package:flutter/material.dart';

import '../../core/format/rupiah.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_controller.dart';
import 'onboarding_scaffold.dart';
import 'widgets/form_widgets.dart';

/// Screen 5 — Savings & budget preview (PRD 4.6).
class SavingsPreviewScreen extends StatefulWidget {
  const SavingsPreviewScreen({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  final OnboardingController controller;
  final VoidCallback onCompleted;

  @override
  State<SavingsPreviewScreen> createState() => _SavingsPreviewScreenState();
}

class _SavingsPreviewScreenState extends State<SavingsPreviewScreen> {
  late final TextEditingController _target = TextEditingController(
    text: widget.controller.savingsTarget > 0
        ? formatRupiah(widget.controller.savingsTarget)
        : '',
  );

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ok = await widget.controller.submitPlan();
    if (!mounted) return;
    if (ok) {
      widget.onCompleted();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final preview = c.preview;

    return OnboardingScaffold(
      stepNumber: 4,
      onBack: c.goBack,
      heading: 'Mau sisihkan berapa?',
      helper: 'Tabungan dipisahkan dari uang belanja agar tidak terhitung dua kali.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RupiahField(
            controller: _target,
            label: 'Target tabungan per siklus',
            hint: 'Rp0',
            onChanged: (v) {
              c.savingsTarget = parseRupiah(v);
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.section),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _PreviewRow(label: 'Gaji bersih', value: preview.netIncome),
                const SizedBox(height: AppSpacing.componentWide),
                _PreviewRow(
                  label: 'Tagihan tetap',
                  value: -preview.fixedBillsTotal,
                ),
                const SizedBox(height: AppSpacing.componentWide),
                _PreviewRow(label: 'Target tabungan', value: -preview.savingsTarget),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Sisa untuk pengeluaran fleksibel',
                        style: AppTypography.bodyStrong,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        formatRupiah(preview.flexibleBudget),
                        textAlign: TextAlign.right,
                        style: AppTypography.h2.copyWith(
                          color: preview.isDeficit
                              ? AppColors.criticalText
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (preview.isDeficit) ...[
                  const SizedBox(height: AppSpacing.componentWide),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.criticalBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rencana defisit ${formatRupiah(preview.deficitAmount)}',
                          style: AppTypography.bodyStrong
                              .copyWith(color: AppColors.criticalText),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Turunkan target tabungan atau tinjau tagihan tetap '
                          'agar alokasi fleksibel tidak negatif.',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (c.submitError != null) ...[
            const SizedBox(height: AppSpacing.componentWide),
            Text(
              c.submitError!,
              style: AppTypography.caption.copyWith(color: AppColors.criticalText),
            ),
          ],
        ],
      ),
      footer: PrimaryCta(
        label: 'Buat rencana saya',
        loading: c.isSubmitting,
        loadingLabel: 'Membuat rencana…',
        onPressed: !c.isSubmitting && !preview.isDeficit ? _submit : null,
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final negative = value < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: AppTypography.body)),
        Text(
          negative ? '−${formatRupiah(-value)}' : formatRupiah(value),
          style: AppTypography.bodyStrong,
        ),
      ],
    );
  }
}
