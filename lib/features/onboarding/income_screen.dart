import 'package:flutter/material.dart';

import '../../core/format/rupiah.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_controller.dart';
import 'onboarding_scaffold.dart';
import 'widgets/form_widgets.dart';

/// Screen 2 — Income (PRD 4.3).
class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  late final TextEditingController _amount =
      TextEditingController(text: widget.controller.netIncome > 0 ? formatRupiah(widget.controller.netIncome) : '');

  bool _saving = false;
  bool _touched = false;
  bool _showZeroError = false;

  int get _value => parseRupiah(_amount.text);
  bool get _isEmpty => _amount.text.trim().isEmpty;
  bool get _isValid => !_isEmpty && _value > 0;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    widget.controller.netIncome = _value;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _saving = false);
    widget.controller.goTo(OnboardingStep.payday);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return OnboardingScaffold(
      stepNumber: 1,
      onBack: c.goBack,
      heading: 'Berapa gaji bersihmu?',
      helper:
          'Masukkan jumlah yang benar-benar masuk ke rekening setelah potongan.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RupiahField(
            controller: _amount,
            label: 'Gaji bersih per periode',
            hint: 'Rp0',
            onChanged: (_) {
              if (!_touched) setState(() => _touched = true);
              setState(() => _showZeroError = _value == 0 && _amount.text.isNotEmpty);
            },
          ),
          const SizedBox(height: AppSpacing.component),
          if (_showZeroError)
            Text(
              'Jumlah harus lebih besar dari Rp0.',
              style: AppTypography.caption.copyWith(color: AppColors.criticalText),
            )
          else if (_isEmpty && _touched)
            const Text('Masukkan jumlah gaji bersih.', style: AppTypography.caption)
          else if (_isValid)
            Text(
              '${formatRupiah(_value)} per ${c.frequency.label.toLowerCase()}',
              style: AppTypography.caption,
            ),
          const SizedBox(height: AppSpacing.section),
          Text('Frekuensi gaji', style: AppTypography.label),
          const SizedBox(height: AppSpacing.component),
          Wrap(
            spacing: AppSpacing.component,
            runSpacing: AppSpacing.component,
            children: [
              for (final f in PayFrequency.values)
                ChoiceChip(
                  label: Text(f.label),
                  selected: c.frequency == f,
                  onSelected: f.supported
                      ? (_) {
                          c.frequency = f;
                          setState(() {});
                        }
                      : null,
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  labelStyle: AppTypography.bodyStrong.copyWith(
                    color: f.supported ? AppColors.primary : AppColors.disabled,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.component),
          const Text(
            'MVP saat ini mendukung siklus bulanan.',
            style: AppTypography.caption,
          ),
        ],
      ),
      footer: PrimaryCta(
        label: 'Lanjutkan',
        loading: _saving,
        loadingLabel: 'Menyimpan…',
        onPressed: _isValid && !_saving ? _continue : null,
      ),
    );
  }
}
