import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 💬 MATERIAL 3 DIALOG HELPER - 2026 Design Patterns
///
/// Modern AlertDialog with proper Material 3 styling.
/// Supports destructive actions, custom content, and animations.
///
/// Usage:
/// ```dart
/// AppDialog.confirm(context,
///   title: 'Delete Account?',
///   content: 'This action cannot be undone.',
///   confirmText: 'Delete',
///   isDestructive: true,
///   onConfirm: () => deleteAccount(),
/// );
/// ```
class AppDialog {
  AppDialog._();

  /// 🔔 Standard confirmation dialog
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    String? content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: content != null
            ? Text(
                content,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              onCancel?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive ? AppColors.error : AppColors.crimson,
              foregroundColor: AppColors.pureWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  /// ⚠️ Destructive action dialog with emphasis
  static Future<bool?> destructive(
    BuildContext context, {
    required String title,
    String? content,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
  }) {
    return confirm(
      context,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: true,
      onConfirm: onConfirm,
    );
  }

  /// ℹ️ Info dialog with single action
  static Future<void> info(
    BuildContext context, {
    required String title,
    String? content,
    String buttonText = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_rounded,
            color: AppColors.info,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: content != null
            ? Text(
                content,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              )
            : null,
        actions: [
          Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  /// 🎉 Success dialog with icon
  static Future<void> success(
    BuildContext context, {
    required String title,
    String? content,
    String buttonText = 'Done',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: content != null
            ? Text(
                content,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              )
            : null,
        actions: [
          Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  /// 📝 Custom content dialog
  static Future<T?> custom<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool barrierDismissible = true,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.all(24),
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: title != null
            ? Text(
                title,
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              )
            : null,
        content: child,
        contentPadding: contentPadding,
      ),
    );
  }

  /// ⏳ Loading dialog
  static void showLoading(
    BuildContext context, {
    String message = 'Please wait...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.charcoal,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.crimson,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          contentPadding: const EdgeInsets.all(32),
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}
