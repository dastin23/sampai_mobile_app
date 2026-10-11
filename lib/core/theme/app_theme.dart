import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart';

/// Spacing grid dasar 8 px (PRD 3.1, scale 4/8/12/16/24/32/48).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 48;

  static const double pageHorizontal = 24;
  static const double component = 8;
  static const double componentWide = 16;
  static const double cardPadding = 20;
  static const double cardRadius = 20;
  static const double heroRadius = 24;
  static const double sheetRadius = 28;
  static const double dockRadius = 28;
  static const double buttonHeight = 56;
  static const double buttonRadius = 16;
  static const double fieldHeight = 56;
  static const double fieldRadius = 14;
  static const double minTouchTarget = 44;
}

/// Motion (DESIGN.md): 120–260ms, hati-hati dengan reduced-motion.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 260);
}

/// Tipografi (DESIGN.md): system sans, bobot 300/400/500/600, default UI 600.
abstract final class AppTypography {
  static const String? fontFamily = null;

  static const TextStyle display = TextStyle(
    fontSize: 36,
    height: 42 / 36,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w600,
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

/// Palet Material terikat token Lime (DESIGN.md).
const ColorScheme _sampaiScheme = ColorScheme.light(
  primary: AppColors.brand,
  onPrimary: AppColors.primary,
  primaryContainer: AppColors.brandSoft,
  onPrimaryContainer: AppColors.primary,
  secondary: AppColors.primaryStrong,
  onSecondary: AppColors.surface,
  secondaryContainer: AppColors.brandSoft,
  onSecondaryContainer: AppColors.primary,
  surface: AppColors.surface,
  onSurface: AppColors.primary,
  onSurfaceVariant: AppColors.secondaryText,
  outline: AppColors.border,
  outlineVariant: AppColors.borderSoft,
  error: AppColors.danger,
  onError: AppColors.surface,
  errorContainer: AppColors.criticalBackground,
  onErrorContainer: AppColors.criticalText,
);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: _sampaiScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: AppTypography.fontFamily,
    dividerColor: AppColors.borderSoft,
    splashFactory: InkSparkle.splashFactory,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: AppColors.brandSoft.withValues(alpha: 0.85),
      cursorColor: AppColors.primaryStrong,
      selectionHandleColor: AppColors.primaryStrong,
    ),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: AppColors.primary,
      displayColor: AppColors.primary,
      fontFamily: AppTypography.fontFamily,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.borderSoft,
        disabledForegroundColor: AppColors.primary.withValues(alpha: 0.45),
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.bodyStrong,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSpacing.minTouchTarget, 48),
        backgroundColor: AppColors.surface.withValues(alpha: 0.7),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.bodyStrong,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryStrong,
        textStyle: AppTypography.bodyStrong,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surface.withValues(alpha: 0.6),
        foregroundColor: AppColors.primary,
        selectedBackgroundColor: AppColors.brandSoft,
        selectedForegroundColor: AppColors.primaryStrong,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: AppTypography.bodyStrong,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppColors.brandSoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryStrong
              : AppColors.secondaryText,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTypography.caption.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryStrong
              : AppColors.secondaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface.withValues(alpha: 0.85),
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
        borderSide: const BorderSide(
          color: AppColors.primaryStrong,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(color: AppColors.criticalText),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        borderSide: const BorderSide(
          color: AppColors.criticalText,
          width: 1.5,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.glassSheet,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sheetRadius),
      ),
      titleTextStyle: AppTypography.h2,
      contentTextStyle: AppTypography.body,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.glassSheet,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.glassSheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brand,
      linearTrackColor: AppColors.borderSoft,
      circularTrackColor: AppColors.borderSoft,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.surface
            : AppColors.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.brand
            : AppColors.borderSoft,
      ),
    ),
  );
}