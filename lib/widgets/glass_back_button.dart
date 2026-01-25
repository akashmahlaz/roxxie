import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../core/theme/theme.dart';

/// 🔙 GLASS BACK BUTTON
///
/// Premium glassmorphic back button with haptic feedback
/// Consistent styling across all app screens
///
/// Usage:
/// ```dart
/// AppBar(
///   leading: GlassBackButton(),
/// )
/// ```

class GlassBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final double iconSize;

  const GlassBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 40,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onPressed != null) {
            onPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.cardBackground(
                  brightness,
                ).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border(brightness).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: color ?? AppColors.text(brightness),
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
