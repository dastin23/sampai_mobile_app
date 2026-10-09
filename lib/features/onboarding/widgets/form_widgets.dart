import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_theme.dart';

/// CTA utama 56 px dengan state loading dan anti double-submit.
class PrimaryCta extends StatelessWidget {
  const PrimaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel = 'Menyimpan…',
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: loading
          ? FilledButton.styleFrom(
              disabledBackgroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.surface,
            )
          : null,
      child: loading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(width: 10),
                Text(loadingLabel),
              ],
            )
          : Text(label),
    );
  }
}

class SecondaryCta extends StatelessWidget {
  const SecondaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        alignment: Alignment.center,
      ),
      label: Text(label),
    );
  }
}

/// Input currency besar dengan prefix Rp (PRD 4.3).
class RupiahField extends StatelessWidget {
  const RupiahField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.label),
          const SizedBox(height: AppSpacing.component),
        ],
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          style: AppTypography.display.copyWith(fontSize: 30, height: 36 / 30),
          decoration: InputDecoration(hintText: hint ?? 'Rp0'),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Field teks umum onboarding.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.component),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: suffix,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
