import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 🔔 MATERIAL 3 SNACKBAR HELPER - 2026 Design Patterns
///
/// Centralized SnackBar management with consistent styling.
/// Follows Material 3 guidelines for floating behavior and proper margins.
///
/// Usage:
/// ```dart
/// AppSnackBar.success(context, message: 'Profile saved!');
/// AppSnackBar.error(context, message: 'Something went wrong');
/// AppSnackBar.showRetry(context, message: 'Network error', onRetry: () {});
/// ```
class AppSnackBar {
  AppSnackBar._();

  /// Base show method with full customization
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    IconData? icon,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.pureWhite, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
        action: action,
      ),
    );
  }

  /// ✅ Success - Confirmation, saved, completed actions
  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
      duration: duration,
      action: action,
    );
  }

  /// ❌ Error - Failures, validation errors
  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_rounded,
      duration: duration,
      action: action,
    );
  }

  /// ⚠️ Warning - Pending actions, attention needed
  static void warning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_rounded,
      duration: duration,
      action: action,
    );
  }

  /// ℹ️ Info - Neutral information, tips
  static void info(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info_rounded,
      duration: duration,
      action: action,
    );
  }

  /// 🔄 Retry - Error with retry action
  static void showRetry(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
    Color? backgroundColor,
    String actionLabel = 'Retry',
  }) {
    show(
      context,
      message: message,
      backgroundColor: backgroundColor ?? AppColors.error,
      icon: Icons.error_outline_rounded,
      action: SnackBarAction(
        label: actionLabel,
        onPressed: onRetry,
        textColor: AppColors.pureWhite,
      ),
    );
  }

  /// 🔙 Undo - Actions that can be reversed
  static void showUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context,
      message: message,
      backgroundColor: AppColors.charcoal,
      duration: duration,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: onUndo,
        textColor: AppColors.crimson,
      ),
    );
  }

  /// Hide current SnackBar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
