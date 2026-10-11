import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Jenis material Liquid Glass (DESIGN.md).
///
/// - [raised]: kartu standar — tint transparan, rim, bayangan lembut.
/// - [well]: well/ikon — tint muted, tanpa blur, cocok untuk isi padat.
/// - [chrome]: chrome navigasi — blur + rim lebih terang.
/// - [hero]: kartu hero utama — tint brand + blur + glow.
/// - [strong]: dialog/sheet — hampir solid, kontras lebih kuat.
enum GlassKind { raised, well, chrome, hero, strong }

/// Lapisan yang diubah pada [GlassSurface].
abstract final class GlassLayers {
  static const bool filter = true; // blur/refraction
  static const bool overlay = true; // tint translucen
  static const bool specular = true; // highlight dalam
}

/// Latar atmosferik yang memberi bahan yang dibiaskan kaca.
///
/// Gradasi lime lembut + glow radial; konten tetap di atasnya.
class AtmosphereBackground extends StatelessWidget {
  const AtmosphereBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.background,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brandSoft,
            AppColors.canvas,
            AppColors.canvas,
          ],
          stops: [0.0, 0.42, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(
              size: 300,
              color: AppColors.brand.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            top: 180,
            left: -110,
            child: _Glow(
              size: 260,
              color: AppColors.primaryStrong.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -40,
            child: _Glow(
              size: 320,
              color: AppColors.brand.withValues(alpha: 0.18),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Material kaca: blur + tint + rim + highlight dalam + bayangan/glow.
///
/// Blur dimatikan otomatis saat `disableAnimations` (fallback non-blur) —
/// tint, rim, dan bayangan tetap memberi batas yang terbaca.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.kind = GlassKind.raised,
    this.radius = AppSpacing.cardRadius,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.glowColor,
    this.elevation,
  });

  final Widget child;
  final GlassKind kind;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  /// Warna rim; override hanya untuk kasus khusus (mis. state error).
  final Color? borderColor;

  /// Warna glow tambahan (default: brand untuk hero, danger untuk kritikal).
  final Color? glowColor;

  /// Shadow z-height override (10 = default dengan bayangan).
  final int? elevation;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final blurEnabled = _usesBlur(kind) && !reduceMotion;

    final tint = color ?? _tintFor(kind);
    final rim = borderColor ?? _rimFor(kind);
    final shadowList = _shadowFor(context, kind, glowColor, elevation);

    final decorator = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: _specularFor(kind)),
            tint,
          ],
          stops: const [0.0, 0.45],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: rim, width: 1),
        boxShadow: shadowList,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    final content = blurEnabled
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius - 1),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _blurFor(kind), sigmaY: _blurFor(kind)),
              child: decorator,
            ),
          )
        : decorator;

    if (margin == null) return content;
    return Padding(padding: margin!, child: content);
  }

  static bool _usesBlur(GlassKind kind) =>
      kind == GlassKind.chrome || kind == GlassKind.hero || kind == GlassKind.strong;

  static double _blurFor(GlassKind kind) => switch (kind) {
        GlassKind.chrome => 22,
        GlassKind.hero => 18,
        GlassKind.strong => 14,
        GlassKind.raised || GlassKind.well => 0,
      };

  static double _specularFor(GlassKind kind) => switch (kind) {
        GlassKind.chrome => 0.35,
        GlassKind.hero => 0.28,
        GlassKind.strong => 0.18,
        GlassKind.raised => 0.22,
        GlassKind.well => 0.08,
      };

  static Color _tintFor(GlassKind kind) => switch (kind) {
        GlassKind.hero => AppColors.brandSoft.withValues(alpha: 0.82),
        GlassKind.chrome => AppColors.surface.withValues(alpha: 0.78),
        GlassKind.strong => AppColors.glassSheet.withValues(alpha: 0.96),
        GlassKind.well => AppColors.surfaceMuted.withValues(alpha: 0.30),
        GlassKind.raised => AppColors.surface.withValues(alpha: 0.72),
      };

  static Color _rimFor(GlassKind kind) => switch (kind) {
        GlassKind.hero => Colors.white.withValues(alpha: 0.80),
        GlassKind.chrome => Colors.white.withValues(alpha: 0.85),
        GlassKind.strong => Colors.white.withValues(alpha: 0.70),
        GlassKind.well => AppColors.border.withValues(alpha: 0.25),
        GlassKind.raised => Colors.white.withValues(alpha: 0.60),
      };

  List<BoxShadow> _shadowFor(
    BuildContext context,
    GlassKind kind,
    Color? glowColor,
    int? elevation,
  ) {
    final z = elevation ?? switch (kind) {
      GlassKind.hero => 6,
      GlassKind.chrome => 4,
      GlassKind.strong => 8,
      GlassKind.raised => 1,
      GlassKind.well => 0,
    };
    if (kind == GlassKind.well) return const [];
    return [
      if (kind == GlassKind.hero || glowColor != null)
        BoxShadow(
          color: (glowColor ?? AppColors.brand).withValues(alpha: 0.28),
          blurRadius: 26,
          offset: const Offset(0, 2),
        ),
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.10 + z * 0.015),
        blurRadius: 8 + z * 2.5,
        offset: Offset(0, (3 + z).toDouble()),
      ),
    ];
  }
}

/// Tombol pill kaca untuk aksi utama (refractive pill, DESIGN.md).
/// Paling terang di layar: tint brand + rim tegas + glow.
class GlassHeroPill extends StatelessWidget {
  const GlassHeroPill({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        Text(label, style: AppTypography.bodyStrong),
      ],
    );
    return Semantics(
      button: true,
      enabled: on,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: on == false
              ? AppColors.borderSoft
              : AppColors.brand,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.borderSoft,
          disabledForegroundColor: AppColors.primary.withValues(alpha: 0.45),
          elevation: 0,
          shape: const StadiumBorder(),
          side: BorderSide(
            color: on == false
                ? AppColors.borderSoft
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
        child: content,
      ),
    );
  }
}