import 'package:flutter/material.dart';

import '../../core/format/date.dart';
import '../../core/format/rupiah.dart';
import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import 'add_expense_controller.dart';

/// Bottom sheet "Catat pengeluaran" (PRD 6).
///
/// Return transaksi tersimpan, atau [null] bila ditutup tanpa menyimpan.
Future<ExpenseTransaction?> showAddExpenseSheet(
  BuildContext context, {
  required AppState appState,
  AddExpenseController? controller,
}) {
  return showModalBottomSheet<ExpenseTransaction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: _AddExpenseSheet(
          appState: appState,
          controller: controller,
        ),
      ),
    ),
  );
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({required this.appState, this.controller});

  final AppState appState;
  final AddExpenseController? controller;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  late final AddExpenseController _controller;
  late final bool _ownsController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _category;
  late DateTime _date;
  String? _amountError;
  String? _categoryError;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AddExpenseController(widget.appState);
    _controller.addListener(_onControllerChanged);
    _date = _normalizedNow();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static DateTime _normalizedNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  bool get _isDirty =>
      _amountController.text.isNotEmpty ||
      _noteController.text.isNotEmpty ||
      _category != null ||
      !_date.isAtSameMomentAs(_normalizedNow());

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Buang pengeluaran ini?'),
        content: const Text(
          'Jumlah dan catatan yang belum disimpan akan hilang.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(0)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _close() async {
    if (!_isDirty || _saved) {
      Navigator.pop(context);
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _submit() async {
    final amount = parseRupiah(_amountController.text);
    final errors = <String>[];
    if (amount <= 0) {
      setState(() => _amountError = 'Masukkan jumlah lebih dari Rp0.');
      errors.add('amount');
    }
    if (_category == null) {
      setState(() => _categoryError = 'Pilih kategori pengeluaran.');
      errors.add('category');
    }
    if (errors.isNotEmpty) return;

    setState(() {
      _amountError = null;
      _categoryError = null;
    });

    final saved = await _controller.save(
      note: _noteController.text,
      category: _category!,
      amount: amount,
      date: _date,
    );
    if (saved != null && mounted) {
      setState(() => _saved = true);
      Navigator.pop(context, saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty || _saved,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && mounted) Navigator.of(this.context).pop();
      },
      child: SingleChildScrollView(
        child: Padding(
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
              const SizedBox(height: AppSpacing.component),
              Row(
                children: [
                  const Expanded(
                    child: Text('Catat pengeluaran', style: AppTypography.h2),
                  ),
                  IconButton(
                    onPressed: _close,
                    tooltip: 'Tutup',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    icon: const Icon(Icons.close, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.componentWide),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                style: const TextStyle(
                  fontSize: 32,
                  height: 38 / 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  prefixText: 'Rp ',
                  errorText: _amountError,
                ),
                onChanged: (_) {
                  if (_amountError != null) {
                    setState(() => _amountError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.section),
              const Text('Kategori', style: AppTypography.h3),
              if (_categoryError != null) ...[
                const SizedBox(height: AppSpacing.component),
                Text(
                  _categoryError!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.criticalText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.componentWide),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.componentWide,
                crossAxisSpacing: 12,
                mainAxisExtent: 90,
                children: [
                  for (final category in categoryIcons.keys)
                    _CategoryTile(
                      category: category,
                      selected: _category == category,
                      onTap: () {
                        setState(() {
                          _category = category;
                          _categoryError = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              TextField(
                controller: _noteController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Beli apa? (opsional)',
                  hintText: 'Contoh: makan siang',
                ),
              ),
              const SizedBox(height: AppSpacing.componentWide),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.componentWide,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.fieldRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal', style: AppTypography.label),
                            Text(
                              formatShortDate(_date),
                              style: AppTypography.bodyStrong,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
              if (_controller.status == ExpenseSaveStatus.error) ...[
                const SizedBox(height: AppSpacing.componentWide),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.criticalBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Belum berhasil menyimpan. Coba lagi.',
                    style: AppTypography.bodyStrong,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              FilledButton(
                onPressed: _controller.isSaving ? null : _submit,
                child: _controller.isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Menyimpan…'),
                        ],
                      )
                    : const Text('Simpan pengeluaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final String category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.canvas,
              borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              categoryIcon(category),
              size: 26,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category,
            style: AppTypography.caption.copyWith(
              color: selected ? AppColors.primary : AppColors.secondaryText,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}