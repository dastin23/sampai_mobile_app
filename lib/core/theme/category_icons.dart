import 'package:flutter/material.dart';

/// Ikon kategori pengeluaran (PRD 6.2.C) + label Indonesia.
///
/// Kunci mengikuti nama kategori default global di tabel `categories`
/// (lihat supabase/migrations/supabase_database.sql).
const Map<String, IconData> categoryIcons = {
  'Makanan': Icons.restaurant_outlined,
  'Makan': Icons.restaurant_outlined,
  'Transportasi': Icons.directions_car_outlined,
  'Belanja': Icons.shopping_bag_outlined,
  'Tagihan': Icons.receipt_long_outlined,
  'Hiburan': Icons.movie_outlined,
  'Kesehatan': Icons.favorite_outline,
  'Keluarga': Icons.people_outline,
  'Lainnya': Icons.category_outlined,
};

IconData categoryIcon(String category) =>
    categoryIcons[category] ?? Icons.category_outlined;

/// Ikon kategori pemasukan (form Catat pemasukan).
///
/// Kunci mengikuti nama kategori default global di tabel `categories`.
const Map<String, IconData> incomeCategoryIcons = {
  'Gaji': Icons.payments_outlined,
  'Bonus': Icons.card_giftcard_outlined,
  'Investasi': Icons.trending_up_outlined,
  'Sampingan': Icons.work_outline,
  'Hadiah': Icons.redeem_outlined,
  'Lainnya': Icons.category_outlined,
};

IconData incomeCategoryIcon(String category) =>
    incomeCategoryIcons[category] ?? Icons.category_outlined;
