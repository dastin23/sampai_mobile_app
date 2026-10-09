import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart';

/// Spacing grid dasar 8 px (PRD 3.1).
abstract final class AppSpacing {
  static const double pageHorizontal = 24;
  static const double section = 24;
  static const double component = 8;
  static const double componentWide = 16;
  static const double cardPadding = 20;
  static const double cardRadius = 20;
  static const double buttonHeight = 56;
  static const double buttonRadius = 16;
  static const double fieldHeight = 56;
  static const double fieldRadius = 14;
  static const double minTouchTarget = 44;
}

/// Tipografi (PRD 3.3). Font sans-serif sistem; Inter bila tersedia di device.
abstract final class AppTypography {
  static const String? fontFamily = null;

  static const TextStyle display = TextStyle(
    fontSize: 36,
    height: 42 / 36,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: AppTypography.fontFamily,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.primary,
      displayColor: AppColors.primary,
    ),
    dividerColor: AppColors.border,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.bodyStrong,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSpacing.minTouchTarget, 48),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.bodyStrong,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      hintStyle: AppTypography.body.copyWith(color: AppColors.secondaryText),
      labelStyle: AppTypography.label,
      errorStyle: AppTypography.caption.copyWith(color: AppColors.criticalText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.criticalText),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.criticalText, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: AppTypography.body.copyWith(color: AppColors.surface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
    ),
  );
}
