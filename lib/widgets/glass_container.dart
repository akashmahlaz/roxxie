import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/theme.dart';

/// 🪟 GLASSMORPHIC CONTAINER
///
/// Creates a beautiful frosted glass effect that's signature to premium apps
/// Think: iOS Control Center, macOS widgets, Spotify overlays
///
/// Usage:
/// ```dart
/// GlassContainer(
///   child: Text('Hello'),
///   borderRadius: 16,
///   blur: 10,
/// )
/// ```

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 10,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.glassWhite,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 🪟 GLASS CARD
///
/// Pre-styled glass container for cards

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding ?? AppSpacing.cardPaddingLarge,
      borderRadius: AppSpacing.radiusLg,
      blur: 20,
      boxShadow: elevated ? AppShadows.cardElevated : AppShadows.card,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: AppSpacing.borderRadiusLg,
              child: child,
            )
          : child,
    );
  }
}
