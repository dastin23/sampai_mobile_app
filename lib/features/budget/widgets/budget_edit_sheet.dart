import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_theme.dart';
import '../budget_controller.dart';

/// Bottom sheet "Ubah anggaran" (PRD 7.2.E).
///
/// Menampilkan input batas untuk tiap kategori pada [initialLimits].
/// Bila total seluruh kategori melampaui [flexibleBudget], pengguna harus
/// mengonfirmasi; nominal kategori lain tidak pernah diubah diam-diam.
Future<void> showBudgetEditSheet(
  BuildContext context, {
  required BudgetController controller,
  required String title,
  required Map<String, int> initialLimits,
  int? flexibleBudget,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          child: _BudgetEditSheet(
            controller: controller,
            title: title,
            initialLimits: initialLimits,
            flexibleBudget: flexibleBudget,
          ),
        ),
      ),
    ),
  );
}

class _BudgetEditSheet extends StatefulWidget {
  const _BudgetEditSheet({
    required this.controller,
    required this.title,
    required this.initialLimits,
    required this.flexibleBudget,
  });

  final BudgetController controller;
  final String title;
  final Map<String, int> initialLimits;
  final int? flexibleBudget;

  @override
  State<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends State<_BudgetEditSheet> {
  late final Map<String, TextEditingController> _fields = {
    for (final entry in widget.initialLimits.entries)
      entry.key: TextEditingController(text: '${entry.value}'),
  };

  final Map<String, String> _errors = {};
  bool _showWarning = false;
  int _pendingTotal = 0;

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _onChanged(String category) {
    if (_errors.containsKey(category) || _showWarning) {
      setState(() {
        _errors.remove(category);
        _showWarning = false;
      });
    }
  }

  void _submit() {
    final parsed = <String, int>{};
    final errors = <String, String>{};
    for (final entry in _fields.entries) {
      final value = int.tryParse(entry.value.text.trim());
      if (value == null || value < 0) {
        errors[entry.key] = 'Masukkan jumlah yang valid.';
      } else {
        parsed[entry.key] = value;
      }
    }
    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
        _showWarning = false;
      });
      return;
    }

    final all = <String, int>{...widget.controller.currentLimits}
      ..addAll(parsed);
    final total = all.values.fold(0, (sum, value) => sum + value);
    final flexible = widget.flexibleBudget;
    if (!_showWarning && flexible != null && total > flexible) {
      setState(() {
        _showWarning = true;
        _pendingTotal = total;
      });
      return;
    }

    widget.controller.saveLimits(parsed);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final flexible = widget.flexibleBudget;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.componentWide),
          Text(widget.title, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.component),
          const Text(
            'Perubahan memengaruhi total alokasi fleksibel. '
            'Kategori lain tidak ikut berubah.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.componentWide),
          for (final category in _fields.keys) ...[
            TextField(
              controller: _fields[category],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: category,
                prefixText: 'Rp ',
                errorText: _errors[category],
              ),
              onChanged: (_) => _onChanged(category),
            ),
            const SizedBox(height: 12),
          ],
          if (_showWarning && flexible != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total kategori ${formatRupiah(_pendingTotal)} melebihi '
                    'anggaran fleksibel ${formatRupiah(flexible)}.',
                    style: AppTypography.bodyStrong,
                  ),
                  const SizedBox(height: AppSpacing.component),
                  const Text(
                    'Konfirmasi bila tetap ingin menyimpan, atau sesuaikan '
                    'alokasi lain terlebih dahulu.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.componentWide),
          ],
          FilledButton(
            onPressed: _submit,
            child: Text(
              _showWarning ? 'Konfirmasi & simpan' : 'Simpan perubahan',
            ),
          ),
        ],
      ),
    );
  }
}
