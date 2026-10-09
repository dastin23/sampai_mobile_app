import 'package:flutter/material.dart';

import '../../../core/format/date.dart';
import '../../../core/format/rupiah.dart';
import '../../../core/models/plan.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/category_icons.dart';

/// Satu baris transaksi: ikon kategori, judul, kategori, jumlah, dan hari relatif.
/// Dipakai Home ("Transaksi terbaru") dan layar Transaksi.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.today,
  });

  final ExpenseTransaction transaction;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            categoryIcon(transaction.category),
            size: 20,
            color: AppColors.primary,
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
              '−${formatRupiah(transaction.amount)}',
              style: AppTypography.bodyStrong,
            ),
            Text(
              formatRelativeDay(transaction.date, today),
              style: AppTypography.caption,
            ),
          ],
        ),
      ],
    );
  }
}