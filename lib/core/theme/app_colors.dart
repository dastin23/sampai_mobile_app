import 'package:flutter/material.dart';

/// Token warna Liquid Glass — sumber nilai dari DESIGN.md.
///
/// Gunakan nama token di widget, bukan hex tersebar. Feedback state
/// (success/warning/danger) selalu dipasangkan label/ikon, tidak mengandalkan
/// warna saja.
abstract final class AppColors {
  // Permukaan atmosferik (Liquid Glass base).
  static const Color canvas = Color(0xFFF7FEE7); // surface #f7fee7
  static const Color surface = Color(0xFFFBFEF1); // near-white glass fill
  static const Color surfaceMuted = Color(0xFFD9F99D); // muted #d9f99d

  // Tinta & batas.
  static const Color primary = Color(0xFF1A2E05); // text #1a2e05
  static const Color primaryStrong = Color(0xFF365314); // strong #365314
  static const Color secondaryText = Color(0xFF55611F); // kontras ≥ 4.5:1
  static const Color border = Color(0xFF3F6212); // border #3f6212
  static const Color borderSoft = Color(0xFFDCE7B8); // hairline lembut

  // Brand / aksi utama (direction Lime).
  static const Color brand = Color(0xFF84CC16); // primary #84cc16
  static const Color brandSoft = Color(0xFFD9F99D); // soft #d9f99d
  static const Color accent = Color(0xFFD9F99D); // alias brandSoft

  // Umpan balik semantik (selalu disertai label/ikon).
  static const Color success = Color(0xFFE2F2DA);
  static const Color successText = Color(0xFF157A3B);
  static const Color warning = Color(0xFFFFF2D4);
  static const Color warningText = Color(0xFF92400E);
  static const Color danger = Color(0xFFDC2626);
  static const Color criticalBackground = Color(0xFFFDEBEA);
  static const Color criticalText = Color(0xFFA32925);

  static const Color disabled = Color(0xFFC9D7A8);

  // Material Liquid Glass tambahan.
  static const Color glassRim = Color(0x8CFFFFFF); // rim highlight tipis
  static const Color glassShadow = Color(0x1F1A2E05); // bayangan lembut
  static const Color glassSheet = Color(0xF7FBFEF1); // sheet hampir solid
}