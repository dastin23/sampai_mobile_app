import 'package:flutter/material.dart';

/// Ikon kategori pengeluaran (PRD 6.2.C) + label Indonesia.
const Map<String, IconData> categoryIcons = {
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
