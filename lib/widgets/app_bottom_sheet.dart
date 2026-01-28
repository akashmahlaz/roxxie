import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 📋 MATERIAL 3 BOTTOM SHEET HELPER - 2026 Design Patterns
///
/// Modern BottomSheet with drag handle, proper styling and animations.
/// Supports modal and persistent sheets with scrollable content.
///
/// Usage:
/// ```dart
/// AppBottomSheet.show(context,
///   title: 'Select Option',
///   child: ListView(...),
/// );
/// ```
class AppBottomSheet {
  AppBottomSheet._();

  /// Standard modal bottom sheet
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool showDragHandle = true,
    bool isScrollControlled = true,
    bool enableDrag = true,
    double? height,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.95,
    bool useSnapSizes = false,
    List<double>? snapSizes,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      builder: (context) => _BottomSheetContent(
        title: title,
        showDragHandle: showDragHandle,
        height: height,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        useSnapSizes: useSnapSizes,
        snapSizes: snapSizes,
        child: child,
      ),
    );
  }

  /// Action sheet with list of options
  static Future<T?> showActions<T>(
    BuildContext context, {
    required List<AppBottomSheetAction<T>> actions,
    String? title,
    bool showCancel = true,
  }) {
    return show<T>(
      context,
      title: title,
      isScrollControlled: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...actions.map((action) => _ActionTile(action: action)),
          if (showCancel) ...[
            const SizedBox(height: 8),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.slate,
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Confirmation bottom sheet with action buttons
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String confirmText,
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return show<bool>(
      context,
      isScrollControlled: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDestructive ? AppColors.error : AppColors.crimson)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? AppColors.error : AppColors.crimson,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.slate,
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(cancelText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDestructive
                          ? AppColors.error
                          : AppColors.crimson,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
            const SafeArea(child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet content wrapper with proper styling
class _BottomSheetContent extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showDragHandle;
  final double? height;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool useSnapSizes;
  final List<double>? snapSizes;

  const _BottomSheetContent({
    required this.child,
    this.title,
    this.showDragHandle = true,
    this.height,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.95,
    this.useSnapSizes = false,
    this.snapSizes,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(brightness),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Text(
                    title!,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.text(brightness),
                    ),
                  ),
                ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: content);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: useSnapSizes,
      snapSizes: snapSizes,
      builder: (context, scrollController) =>
          SingleChildScrollView(controller: scrollController, child: content),
    );
  }
}

/// Action item for bottom sheet actions
class AppBottomSheetAction<T> {
  final String label;
  final IconData? icon;
  final T? value;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isSelected;

  const AppBottomSheetAction({
    required this.label,
    this.icon,
    this.value,
    this.onTap,
    this.isDestructive = false,
    this.isSelected = false,
  });
}

class _ActionTile<T> extends StatelessWidget {
  final AppBottomSheetAction<T> action;

  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive
        ? AppColors.error
        : action.isSelected
        ? AppColors.crimson
        : AppColors.textPrimary;

    return ListTile(
      leading: action.icon != null
          ? Icon(action.icon, color: color, size: 24)
          : null,
      title: Text(
        action.label,
        style: AppTypography.bodyLarge.copyWith(
          color: color,
          fontWeight: action.isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: action.isSelected
          ? Icon(Icons.check_rounded, color: AppColors.crimson, size: 24)
          : null,
      onTap: () {
        if (action.value != null) {
          Navigator.of(context).pop(action.value);
        } else {
          action.onTap?.call();
          Navigator.of(context).pop();
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
