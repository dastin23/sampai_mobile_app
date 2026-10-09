import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Progress bar standar: tinggi 8 px, radius 999, track Border (PRD 3.4).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.fill = AppColors.primary,
    this.track = AppColors.border,
  });

  /// 0–1; nilai di luar rentang dipotong ke track penuh.
  final double value;
  final Color fill;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Container(color: track),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1).toDouble(),
              child: Container(color: fill),
            ),
          ],
        ),
      ),
    );
  }
}
