import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 🃏 MATERIAL 3 CARD VARIANTS - 2026 Design Patterns
///
/// Modern Card styles following Material 3 specifications:
/// - Elevated (default): Raised with shadow
/// - Filled: Solid color background
/// - Outlined: Border-only styling
///
/// Usage:
/// ```dart
/// AppCard.elevated(child: MyContent());
/// AppCard.filled(child: MyContent());
/// AppCard.outlined(child: MyContent());
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool animate;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.animate = true,
  });

  /// 📦 Elevated card with shadow (default style)
  factory AppCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double elevation = 2,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor ?? AppColors.charcoal,
      elevation: elevation,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }

  /// 🎨 Filled card with solid background
  factory AppCard.filled({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor ?? AppColors.graphite,
      elevation: 0,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }

  /// 🔲 Outlined card with border
  factory AppCard.outlined({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 1,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor ?? Colors.transparent,
      borderColor: borderColor ?? AppColors.slate,
      borderWidth: borderWidth,
      elevation: 0,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }

  /// ✨ Interactive card with hover/press states
  factory AppCard.interactive({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    required VoidCallback onTap,
    BorderRadius? borderRadius,
    bool selected = false,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      backgroundColor:
          selected ? AppColors.crimson.withValues(alpha: 0.15) : AppColors.charcoal,
      borderColor: selected ? AppColors.crimson : AppColors.slate,
      borderWidth: 1,
      elevation: 0,
      borderRadius: borderRadius,
      onTap: onTap,
      animate: true,
      child: child,
    );
  }

  /// 🌟 Premium card with gradient border
  static Widget premium({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return _PremiumCard(
      key: key,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(16);

    final decoration = BoxDecoration(
      color: backgroundColor ?? AppColors.charcoal,
      borderRadius: effectiveBorderRadius,
      border: borderColor != null
          ? Border.all(color: borderColor!, width: borderWidth ?? 1)
          : null,
      boxShadow: (elevation ?? 0) > 0
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: (elevation ?? 2) * 2,
                offset: Offset(0, (elevation ?? 2)),
              ),
            ]
          : null,
    );

    Widget card = AnimatedContainer(
      duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
      decoration: decoration,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          splashColor: AppColors.crimson.withValues(alpha: 0.1),
          highlightColor: AppColors.crimson.withValues(alpha: 0.05),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Premium card with gradient border effect
class _PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const _PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    required this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldDark, AppColors.gold],
          stops: [0, 0.5, 1],
        ),
        borderRadius: borderRadius,
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: borderRadius,
        ),
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// 📊 Stats card for displaying metrics
class AppStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const AppStatsCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.filled(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.crimson).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.crimson,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
