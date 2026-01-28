import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 🔴 MATERIAL 3 BADGE WIDGET - 2026 Design Patterns
///
/// Notification badge for navigation items, icons, and avatars.
/// Supports count display, dot-only mode, and custom styling.
///
/// Usage:
/// ```dart
/// AppBadge(
///   count: 5,
///   child: Icon(Icons.notifications),
/// );
/// AppBadge.dot(child: Icon(Icons.chat));
/// ```
class AppBadge extends StatelessWidget {
  final Widget child;
  final int? count;
  final bool showBadge;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? offset;
  final bool animate;

  const AppBadge({
    super.key,
    required this.child,
    this.count,
    this.showBadge = true,
    this.backgroundColor,
    this.textColor,
    this.size,
    this.alignment = Alignment.topRight,
    this.offset,
    this.animate = true,
  });

  /// 🔵 Dot badge (no count)
  factory AppBadge.dot({
    Key? key,
    required Widget child,
    bool show = true,
    Color? color,
    double size = 8,
    AlignmentGeometry alignment = Alignment.topRight,
  }) {
    return AppBadge(
      key: key,
      showBadge: show,
      backgroundColor: color ?? AppColors.error,
      size: size,
      alignment: alignment,
      child: child,
    );
  }

  /// 🔢 Count badge
  factory AppBadge.count({
    Key? key,
    required Widget child,
    required int count,
    int maxCount = 99,
    Color? backgroundColor,
    Color? textColor,
    AlignmentGeometry alignment = Alignment.topRight,
  }) {
    return AppBadge(
      key: key,
      count: count,
      showBadge: count > 0,
      backgroundColor: backgroundColor,
      textColor: textColor,
      alignment: alignment,
      child: child,
    );
  }

  /// ✨ Small indicator badge
  factory AppBadge.indicator({
    Key? key,
    required Widget child,
    bool show = true,
    Color? color,
  }) {
    return AppBadge(
      key: key,
      showBadge: show,
      backgroundColor: color ?? AppColors.success,
      size: 10,
      alignment: Alignment.bottomRight,
      offset: const EdgeInsets.only(right: 2, bottom: 2),
      child: child,
    );
  }

  String get _displayText {
    if (count == null) {
      return '';
    }
    if (count! > 99) {
      return '99+';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDot = count == null && showBadge;
    final double badgeSize = size ?? (isDot ? 8 : 18);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: alignment == Alignment.topRight || alignment == Alignment.topLeft
              ? -4
              : null,
          right:
              alignment == Alignment.topRight ||
                  alignment == Alignment.bottomRight
              ? -4
              : null,
          left:
              alignment == Alignment.topLeft ||
                  alignment == Alignment.bottomLeft
              ? -4
              : null,
          bottom:
              alignment == Alignment.bottomRight ||
                  alignment == Alignment.bottomLeft
              ? -4
              : null,
          child: AnimatedScale(
            scale: showBadge ? 1.0 : 0.0,
            duration: animate
                ? const Duration(milliseconds: 200)
                : Duration.zero,
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: showBadge ? 1.0 : 0.0,
              duration: animate
                  ? const Duration(milliseconds: 150)
                  : Duration.zero,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: badgeSize,
                  minHeight: badgeSize,
                ),
                padding: isDot
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.error,
                  borderRadius: BorderRadius.circular(badgeSize / 2),
                  border: Border.all(color: AppColors.obsidian, width: 1.5),
                ),
                child: isDot
                    ? null
                    : Center(
                        child: Text(
                          _displayText,
                          style: TextStyle(
                            color: textColor ?? AppColors.pureWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 🏷️ Status badge label
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool small;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.small = false,
  });

  /// ✅ Success status
  factory AppStatusBadge.success({
    Key? key,
    required String label,
    bool small = false,
  }) {
    return AppStatusBadge(
      key: key,
      label: label,
      backgroundColor: AppColors.success.withValues(alpha: 0.15),
      textColor: AppColors.success,
      icon: Icons.check_circle_rounded,
      small: small,
    );
  }

  /// ⚠️ Warning status
  factory AppStatusBadge.warning({
    Key? key,
    required String label,
    bool small = false,
  }) {
    return AppStatusBadge(
      key: key,
      label: label,
      backgroundColor: AppColors.warning.withValues(alpha: 0.15),
      textColor: AppColors.warning,
      icon: Icons.warning_rounded,
      small: small,
    );
  }

  /// ❌ Error status
  factory AppStatusBadge.error({
    Key? key,
    required String label,
    bool small = false,
  }) {
    return AppStatusBadge(
      key: key,
      label: label,
      backgroundColor: AppColors.error.withValues(alpha: 0.15),
      textColor: AppColors.error,
      icon: Icons.error_rounded,
      small: small,
    );
  }

  /// ℹ️ Info status
  factory AppStatusBadge.info({
    Key? key,
    required String label,
    bool small = false,
  }) {
    return AppStatusBadge(
      key: key,
      label: label,
      backgroundColor: AppColors.info.withValues(alpha: 0.15),
      textColor: AppColors.info,
      icon: Icons.info_rounded,
      small: small,
    );
  }

  /// ⏳ Pending status
  factory AppStatusBadge.pending({
    Key? key,
    required String label,
    bool small = false,
  }) {
    return AppStatusBadge(
      key: key,
      label: label,
      backgroundColor: AppColors.slate,
      textColor: AppColors.textSecondary,
      icon: Icons.schedule_rounded,
      small: small,
    );
  }

  /// ⭐ Premium status
  factory AppStatusBadge.premium({
    Key? key,
    required String label,
    bool small = false,
  }) {
    return AppStatusBadge(
      key: key,
      label: label,
      backgroundColor: AppColors.gold.withValues(alpha: 0.15),
      textColor: AppColors.gold,
      icon: Icons.star_rounded,
      small: small,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.slate,
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: small ? 12 : 14,
              color: textColor ?? AppColors.textPrimary,
            ),
            SizedBox(width: small ? 4 : 6),
          ],
          Text(
            label,
            style:
                (small ? AppTypography.labelSmall : AppTypography.labelMedium)
                    .copyWith(
                      color: textColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ],
      ),
    );
  }
}
