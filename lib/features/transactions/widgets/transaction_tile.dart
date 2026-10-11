import 'package:flutter/material.dart';

import '../../../core/format/date.dart';
import '../../../core/format/rupiah.dart';
import '../../../core/models/plan.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/category_icons.dart';

/// Satu baris transaksi: ikon kategori, judul, kategori, jumlah, dan hari relatif.
/// Dipakai Home ("Transaksi terbaru") dan layar Transaksi.
/// Pemasukan ditampilkan dengan tanda "+" dan warna [AppColors.successText].
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.today,
    this.onTap,
  });

  final ExpenseTransaction transaction;
  final DateTime today;

  /// Dipanggil saat baris diketuk (mis. membuka suntingan).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandSoft.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderSoft.withValues(alpha: 0.6),
                ),
              ),
              child: Icon(
                isIncome
                    ? incomeCategoryIcon(transaction.category)
                    : categoryIcon(transaction.category),
                size: 20,
                color: isIncome ? AppColors.successText : AppColors.primaryStrong,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: AppTypography.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    transaction.category,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isIncome
                      ? '+${formatRupiah(transaction.amount)}'
                      : '−${formatRupiah(transaction.amount)}',
                  style: AppTypography.bodyStrong.copyWith(
                    color: isIncome ? AppColors.successText : null,
                  ),
                ),
                Text(
                  formatRelativeDay(transaction.date, today),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
