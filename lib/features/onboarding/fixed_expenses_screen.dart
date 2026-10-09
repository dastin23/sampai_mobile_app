import 'package:flutter/material.dart';

import '../../core/format/rupiah.dart';
import '../../core/models/plan.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_controller.dart';
import 'onboarding_scaffold.dart';
import 'widgets/form_widgets.dart';

/// Screen 4 — Fixed expenses (PRD 4.5).
class FixedExpensesScreen extends StatelessWidget {
  const FixedExpensesScreen({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final bills = controller.bills;
    final total = controller.fixedBillsTotal;

    return OnboardingScaffold(
      stepNumber: 3,
      onBack: controller.goBack,
      heading: 'Apa yang harus dibayar tiap gajian?',
      helper: 'Masukkan tagihan tetap. Kamu bisa menambah atau mengubahnya nanti.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bills.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 32, color: AppColors.secondaryText),
                  SizedBox(height: AppSpacing.componentWide),
                  Text('Belum ada tagihan tetap', style: AppTypography.h3),
                  SizedBox(height: AppSpacing.component),
                  Text(
                    'Kamu bisa langsung lanjut, tagihan bisa ditambahkan kembali nanti.',
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            for (final bill in bills) ...[
              _BillRow(
                key: ValueKey(bill.id),
                bill: bill,
                controller: controller,
              ),
              const SizedBox(height: AppSpacing.componentWide),
            ],
          const SizedBox(height: AppSpacing.component),
          SecondaryCta(
            label: 'Tambah tagihan',
            icon: Icons.add,
            onPressed: controller.addBill,
          ),
        ],
      ),
      footer: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total tagihan per siklus',
                    style: AppTypography.body,
                  ),
                ),
                const SizedBox(width: AppSpacing.component),
                Text(formatRupiah(total), style: AppTypography.bodyStrong),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.componentWide),
          PrimaryCta(
            label: 'Lanjutkan',
            onPressed: () => controller.goTo(OnboardingStep.savings),
          ),
          TextButton(
            onPressed: () => controller.goTo(OnboardingStep.savings),
            child: const Text('Lewati dulu', style: AppTypography.body),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatefulWidget {
  const _BillRow({super.key, required this.bill, required this.controller});

  final FixedBill bill;
  final OnboardingController controller;

  @override
  State<_BillRow> createState() => _BillRowState();
}

class _BillRowState extends State<_BillRow> {
  late final TextEditingController _name =
      TextEditingController(text: widget.bill.name);
  late final TextEditingController _amount = TextEditingController(
    text: widget.bill.amount > 0 ? formatRupiah(widget.bill.amount) : '',
  );

  bool _touchedName = false;
  bool _touchedAmount = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  String? get _nameError {
    if (!_touchedName && _name.text.isEmpty) return null;
    return _name.text.trim().isEmpty ? 'Nama tagihan wajib diisi.' : null;
  }

  String? get _amountError {
    if (!_touchedAmount && _amount.text.isEmpty) return null;
    return parseRupiah(_amount.text) <= 0 ? 'Jumlah lebih dari Rp0.' : null;
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.componentWide),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  style: AppTypography.bodyStrong,
                  decoration: InputDecoration(
                    hintText: 'Nama tagihan',
                    errorText: _nameError,
                    errorMaxLines: 2,
                  ),
                  onChanged: (v) {
                    setState(() => _touchedName = true);
                    widget.controller.updateBill(bill.id, name: v);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.component),
              SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: IconButton(
                  tooltip: 'Hapus tagihan',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.secondaryText),
                  onPressed: () => widget.controller.removeBill(bill.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.componentWide),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  style: AppTypography.bodyStrong,
                  decoration: InputDecoration(
                    hintText: 'Rp0',
                    errorText: _amountError,
                    errorMaxLines: 2,
                  ),
                  onChanged: (v) {
                    setState(() => _touchedAmount = true);
                    widget.controller
                        .updateBill(bill.id, amount: parseRupiah(v));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.component),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: bill.dueDay,
                  isExpanded: true,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  ),
                  items: [
                    for (var d = 1; d <= 31; d++)
                      DropdownMenuItem(
                        value: d,
                        child: Text('Tgl $d', style: AppTypography.body),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    widget.controller.updateBill(bill.id, dueDay: v);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.component),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tanggal tetap · aktif disisihkan tiap siklus',
                  style: AppTypography.caption,
                ),
              ),
              Switch(
                value: bill.active,
                activeThumbColor: AppColors.surface,
                activeTrackColor: AppColors.primary,
                onChanged: (v) {
                  widget.controller.updateBill(bill.id, active: v);
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
