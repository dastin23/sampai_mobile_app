import 'package:flutter/material.dart';

import '../../core/format/date.dart';
import '../../core/format/rupiah.dart';
import '../../core/models/plan.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/category_icons.dart';
import 'add_expense_controller.dart';

/// Jenis transaksi yang dicatat lewat sheet.
enum TransactionKind { expense, income }

/// Hasil sheet sunting: transaksi diperbarui atau dihapus.
enum TransactionSheetAction { saved, deleted }

class TransactionSheetResult {
  const TransactionSheetResult.saved(ExpenseTransaction this.transaction)
      : action = TransactionSheetAction.saved,
        transactionId = null;

  const TransactionSheetResult.deleted(String this.transactionId)
      : action = TransactionSheetAction.deleted,
        transaction = null;

  final TransactionSheetAction action;
  final ExpenseTransaction? transaction;
  final String? transactionId;
}

/// Label dan pilihan kategori yang bergantung pada jenis transaksi.
class _SheetCopy {
  const _SheetCopy({
    required this.title,
    required this.editTitle,
    required this.noteLabel,
    required this.noteHint,
    required this.categoryError,
    required this.actionLabel,
    required this.editActionLabel,
    required this.categories,
  });

  final String title;
  final String editTitle;
  final String noteLabel;
  final String noteHint;
  final String categoryError;
  final String actionLabel;
  final String editActionLabel;
  final Map<String, IconData> categories;
}

_SheetCopy _sheetCopy(TransactionKind kind) => switch (kind) {
      TransactionKind.expense => const _SheetCopy(
        title: 'Catat pengeluaran',
        editTitle: 'Ubah pengeluaran',
        noteLabel: 'Beli apa? (opsional)',
        noteHint: 'Contoh: makan siang',
        categoryError: 'Pilih kategori pengeluaran.',
        actionLabel: 'Simpan pengeluaran',
        editActionLabel: 'Simpan perubahan',
        categories: categoryIcons,
      ),
      TransactionKind.income => const _SheetCopy(
        title: 'Catat pemasukan',
        editTitle: 'Ubah pemasukan',
        noteLabel: 'Dari mana? (opsional)',
        noteHint: 'Contoh: gaji tambahan',
        categoryError: 'Pilih kategori pemasukan.',
        actionLabel: 'Simpan pemasukan',
        editActionLabel: 'Simpan perubahan',
        categories: incomeCategoryIcons,
      ),
    };

/// Buka sheet "Catat pengeluaran" (PRD 6).
///
/// Return transaksi tersimpan, atau [null] bila ditutup tanpa menyimpan.
Future<ExpenseTransaction?> showAddExpenseSheet(
  BuildContext context, {
  required AppState appState,
  AddExpenseController? controller,
}) async {
  final result = await _showTransactionSheet<TransactionSheetResult>(
    context,
    kind: TransactionKind.expense,
    appState: appState,
    controller: controller,
  );
  return result?.transaction;
}

/// Buka sheet "Catat pemasukan".
Future<ExpenseTransaction?> showAddIncomeSheet(
  BuildContext context, {
  required AppState appState,
  AddIncomeController? controller,
}) async {
  final result = await _showTransactionSheet<TransactionSheetResult>(
    context,
    kind: TransactionKind.income,
    appState: appState,
    controller: controller,
  );
  return result?.transaction;
}

/// Buka sheet "Ubah transaksi" untuk menyunting atau menghapus [transaction].
///
/// Return [TransactionSheetResult] berisi aksi & data, atau [null] bila
/// ditutup tanpa perubahan.
Future<TransactionSheetResult?> showEditTransactionSheet(
  BuildContext context, {
  required AppState appState,
  required ExpenseTransaction transaction,
  AddExpenseController? controller,
}) {
  return _showTransactionSheet<TransactionSheetResult>(
    context,
    kind: transaction.isIncome
        ? TransactionKind.income
        : TransactionKind.expense,
    appState: appState,
    controller: controller,
    editing: transaction,
  );
}

Future<T?> _showTransactionSheet<T>(
  BuildContext context, {
  required TransactionKind kind,
  required AppState appState,
  AddExpenseController? controller,
  ExpenseTransaction? editing,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.glassSheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: _AddTransactionSheet(
          kind: kind,
          appState: appState,
          controller: controller,
          editing: editing,
        ),
      ),
    ),
  );
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet({
    required this.kind,
    required this.appState,
    this.controller,
    this.editing,
  });

  final TransactionKind kind;
  final AppState appState;
  final AddExpenseController? controller;
  final ExpenseTransaction? editing;

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  late final AddExpenseController _controller;
  late final bool _ownsController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  String? _category;
  late DateTime _date;
  String? _amountError;
  String? _categoryError;
  bool _saved = false;

  TransactionKind get _kind => widget.kind;

  ExpenseTransaction? get _editing => widget.editing;

  bool get _isEditing => _editing != null;

  _SheetCopy get _copy => _sheetCopy(_kind);

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    final editing = _editing;
    _controller = widget.controller ??
        (_kind == TransactionKind.income
            ? AddIncomeController(widget.appState, editing: editing)
            : AddExpenseController(widget.appState, editing: editing));
    _controller.addListener(_onControllerChanged);

    _amountController = TextEditingController(
      text: editing == null ? '' : formatRupiah(editing.amount),
    );
    _noteController = TextEditingController(
      text: editing == null || editing.title == editing.category
          ? ''
          : editing.title,
    );
    _category = editing?.category;
    _date = editing == null
        ? _normalizedNow()
        : DateTime(editing.date.year, editing.date.month, editing.date.day);
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

  bool get _isDirty {
    final editing = _editing;
    if (editing != null) {
      return parseRupiah(_amountController.text) != editing.amount ||
          _noteController.text.trim() !=
              (editing.title == editing.category ? '' : editing.title) ||
          _category != editing.category ||
          !_date.isAtSameMomentAs(
            DateTime(editing.date.year, editing.date.month, editing.date.day),
          );
    }
    return _amountController.text.isNotEmpty ||
        _noteController.text.isNotEmpty ||
        _category != null ||
        !_date.isAtSameMomentAs(_normalizedNow());
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glassSheet,
        title: Text(
          _isEditing
              ? 'Buang perubahan ini?'
              : 'Buang ${_kind == TransactionKind.income ? 'pemasukan' : 'pengeluaran'} ini?',
        ),
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

  Future<void> _confirmDelete() async {
    final isIncome = _editing?.isIncome ?? false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glassSheet,
        title: Text(
          'Hapus ${isIncome ? 'pemasukan' : 'pengeluaran'} ini?',
        ),
        content: const Text(
          'Transaksi akan dihapus dari riwayat.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(0),
              backgroundColor: AppColors.criticalText,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final id = _editing?.id;
    _controller.deleteEditing();
    _saved = true;
    Navigator.pop(
      context,
      TransactionSheetResult.deleted(id ?? ''),
    );
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
      setState(() => _categoryError = _copy.categoryError);
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
      Navigator.pop(context, TransactionSheetResult.saved(saved));
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
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.component),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? _copy.editTitle : _copy.title,
                      style: AppTypography.h2,
                    ),
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
                  for (final category in _copy.categories.keys)
                    _CategoryTile(
                      category: category,
                      selected: _category == category,
                      icon: _copy.categories[category]!,
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
                decoration: InputDecoration(
                  labelText: _copy.noteLabel,
                  hintText: _copy.noteHint,
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
                    color: AppColors.surface.withValues(alpha: 0.85),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.fieldRadius),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
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
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Menyimpan…'),
                        ],
                      )
                    : Text(
                        _isEditing ? _copy.editActionLabel : _copy.actionLabel,
                      ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.componentWide),
                TextButton.icon(
                  onPressed: _controller.isSaving ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Hapus transaksi'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.criticalText,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
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
    required this.icon,
    required this.onTap,
  });

  final String category;
  final bool selected;
  final IconData icon;
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
            duration: AppMotion.fast,
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.brandSoft.withValues(alpha: 0.9)
                  : AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
              border: Border.all(
                color: selected ? AppColors.primaryStrong : AppColors.borderSoft,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: 26,
              color: selected ? AppColors.primaryStrong : AppColors.primary,
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