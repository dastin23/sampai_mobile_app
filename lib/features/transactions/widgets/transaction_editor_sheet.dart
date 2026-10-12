import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/date.dart';
import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/category_icons.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_providers.dart';

/// Hasil sheet editor transaksi.
enum TransactionEditorResult { saved, deleted }

/// Buka sheet catat/ubah transaksi berbasis [TransactionRepository].
///
/// [type] harus 'income' atau 'expense'. Bila [editing] terisi, sheet menjadi
/// mode sunting (dengan tombol hapus).
Future<TransactionEditorResult?> showTransactionEditorSheet(
  BuildContext context, {
  required String type,
  FinanceTransaction? editing,
}) {
  return showModalBottomSheet<TransactionEditorResult>(
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
        child: _TransactionEditorSheet(type: type, editing: editing),
      ),
    ),
  );
}

class _EditorCopy {
  const _EditorCopy({
    required this.title,
    required this.editTitle,
    required this.descriptionLabel,
    required this.descriptionHint,
    required this.categoryError,
    required this.actionLabel,
    required this.editActionLabel,
  });

  final String title;
  final String editTitle;
  final String descriptionLabel;
  final String descriptionHint;
  final String categoryError;
  final String actionLabel;
  final String editActionLabel;
}

class _TransactionEditorSheet extends ConsumerStatefulWidget {
  const _TransactionEditorSheet({required this.type, this.editing});

  final String type;
  final FinanceTransaction? editing;

  @override
  ConsumerState<_TransactionEditorSheet> createState() =>
      _TransactionEditorSheetState();
}

class _TransactionEditorSheetState
    extends ConsumerState<_TransactionEditorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  String? _categoryId;
  late DateTime _date;
  String? _amountError;
  String? _categoryError;
  bool _saving = false;
  bool _failed = false;
  bool _saved = false;

  bool get _isIncome => widget.type == 'income';

  bool get _isEditing => widget.editing != null;

  _EditorCopy get _copy => _isIncome
      ? const _EditorCopy(
          title: 'Catat pemasukan',
          editTitle: 'Ubah pemasukan',
          descriptionLabel: 'Dari mana? (opsional)',
          descriptionHint: 'Contoh: gaji tambahan',
          categoryError: 'Pilih kategori pemasukan.',
          actionLabel: 'Simpan pemasukan',
          editActionLabel: 'Simpan perubahan',
        )
      : const _EditorCopy(
          title: 'Catat pengeluaran',
          editTitle: 'Ubah pengeluaran',
          descriptionLabel: 'Beli apa? (opsional)',
          descriptionHint: 'Contoh: makan siang',
          categoryError: 'Pilih kategori pengeluaran.',
          actionLabel: 'Simpan pengeluaran',
          editActionLabel: 'Simpan perubahan',
        );

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _amountController = TextEditingController(
      text: editing == null ? '' : formatRupiah(editing.amount.round()),
    );
    _descriptionController = TextEditingController(
      text: editing?.description ?? '',
    );
    _categoryId = editing?.categoryId;
    _date = editing == null
        ? _normalizedNow()
        : DateTime(
            editing.transactionDate.year,
            editing.transactionDate.month,
            editing.transactionDate.day,
          );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static DateTime _normalizedNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isDirty {
    final editing = widget.editing;
    if (editing != null) {
      return parseRupiah(_amountController.text) != editing.amount.round() ||
          _descriptionController.text.trim() != (editing.description ?? '') ||
          _categoryId != editing.categoryId ||
          !_date.isAtSameMomentAs(
            DateTime(
              editing.transactionDate.year,
              editing.transactionDate.month,
              editing.transactionDate.day,
            ),
          );
    }
    return _amountController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _categoryId != null ||
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
              : 'Buang ${_isIncome ? 'pemasukan' : 'pengeluaran'} ini?',
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
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 44),
            ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glassSheet,
        title: Text(
          'Hapus ${_isIncome ? 'pemasukan' : 'pengeluaran'} ini?',
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
              minimumSize: const Size(64, 44),
              backgroundColor: AppColors.criticalText,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(widget.editing!.id);
      ref.invalidate(transactionsProvider);
      if (mounted) {
        setState(() => _saved = true);
        Navigator.pop(context, TransactionEditorResult.deleted);
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
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
    if (_categoryId == null) {
      setState(() => _categoryError = _copy.categoryError);
      errors.add('category');
    }
    if (errors.isNotEmpty) return;

    setState(() {
      _amountError = null;
      _categoryError = null;
      _saving = true;
      _failed = false;
    });

    final repository = ref.read(transactionRepositoryProvider);
    final description = _descriptionController.text;
    try {
      final editing = widget.editing;
      if (editing != null) {
        await repository.updateTransaction(
          id: editing.id,
          type: widget.type,
          amount: amount.toDouble(),
          transactionDate: _date,
          categoryId: _categoryId,
          description: description,
        );
      } else {
        await repository.createTransaction(
          type: widget.type,
          amount: amount.toDouble(),
          transactionDate: _date,
          categoryId: _categoryId,
          description: description,
        );
      }
      ref.invalidate(transactionsProvider);
      if (mounted) {
        setState(() => _saved = true);
        Navigator.pop(context, TransactionEditorResult.saved);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(transactionCategoriesProvider);
    final categories = categoriesAsync.maybeWhen(
      data: (list) => list.where((c) => c.type == widget.type).toList(),
      orElse: () => const <TransactionCategory>[],
    );

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
                    onPressed: _saving ? null : _close,
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
              _CategoryGrid(
                categories: categories,
                loading: categoriesAsync.isLoading,
                selectedId: _categoryId,
                isIncome: _isIncome,
                onSelected: (id) {
                  setState(() {
                    _categoryId = id;
                    _categoryError = null;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.section),
              TextField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _copy.descriptionLabel,
                  hintText: _copy.descriptionHint,
                ),
              ),
              const SizedBox(height: AppSpacing.componentWide),
              _DateField(date: _date, onTap: _pickDate),
              if (_failed) ...[
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
                onPressed: _saving ? null : _submit,
                child: _saving
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
                  onPressed: _saving ? null : _confirmDelete,
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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.loading,
    required this.selectedId,
    required this.isIncome,
    required this.onSelected,
  });

  final List<TransactionCategory> categories;
  final bool loading;
  final String? selectedId;
  final bool isIncome;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (categories.isEmpty) {
      return Text(
        'Belum ada kategori. Tambahkan kategori dulu.',
        style: AppTypography.body,
      );
    }
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.componentWide,
      crossAxisSpacing: 12,
      mainAxisExtent: 90,
      children: [
        for (final category in categories)
          _CategoryTile(
            category: category.name,
            selected: selectedId == category.id,
            icon: isIncome
                ? incomeCategoryIcon(category.name)
                : categoryIcon(category.name),
            onTap: () => onSelected(category.id),
          ),
      ],
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

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.componentWide,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
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
                    formatShortDate(date),
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
    );
  }
}
