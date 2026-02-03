import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 📊 MATERIAL 3 PROGRESS INDICATORS - 2026 Design Patterns
///
/// Centralized progress indicators with consistent styling.
/// Supports linear, circular, determinate and indeterminate modes.
///
/// Usage:
/// ```dart
/// AppProgress.linear(value: 0.5); // 50% progress
/// AppProgress.circular(); // Loading spinner
/// AppProgress.steps(current: 2, total: 5);
/// ```
class AppProgress {
  AppProgress._();

  /// 📏 Linear progress bar
  static Widget linear({
    double? value,
    Color? color,
    Color? backgroundColor,
    double height = 4,
    BorderRadius? borderRadius,
    String? label,
    bool showPercentage = false,
  }) {
    return _LinearProgress(
      value: value,
      color: color ?? AppColors.crimson,
      backgroundColor: backgroundColor ?? AppColors.slate,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      label: label,
      showPercentage: showPercentage,
    );
  }

  /// ⭕ Circular progress indicator
  static Widget circular({
    double? value,
    double size = 40,
    double strokeWidth = 3,
    Color? color,
    Color? backgroundColor,
    Widget? child,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (value != null) ...[
            // Background track
            CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              color: backgroundColor ?? AppColors.slate,
            ),
            // Progress
            CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              color: color ?? AppColors.crimson,
              strokeCap: StrokeCap.round,
            ),
          ] else
            CircularProgressIndicator(
              strokeWidth: strokeWidth,
              color: color ?? AppColors.crimson,
              strokeCap: StrokeCap.round,
            ),
          if (child case final c?) c,
        ],
      ),
    );
  }

  /// 🔢 Step progress indicator
  static Widget steps({
    required int current,
    required int total,
    Color? activeColor,
    Color? inactiveColor,
    Color? completedColor,
    double dotSize = 10,
    double spacing = 4,
    bool showLabels = false,
    List<String>? labels,
  }) {
    return _StepProgress(
      current: current,
      total: total,
      activeColor: activeColor ?? AppColors.crimson,
      inactiveColor: inactiveColor ?? AppColors.slate,
      completedColor: completedColor ?? AppColors.success,
      dotSize: dotSize,
      spacing: spacing,
      showLabels: showLabels,
      labels: labels,
    );
  }

  /// 📶 Segmented progress bar
  static Widget segmented({
    required int current,
    required int total,
    Color? activeColor,
    Color? inactiveColor,
    double height = 4,
    double gap = 4,
    BorderRadius? borderRadius,
  }) {
    return _SegmentedProgress(
      current: current,
      total: total,
      activeColor: activeColor ?? AppColors.crimson,
      inactiveColor: inactiveColor ?? AppColors.slate,
      height: height,
      gap: gap,
      borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
    );
  }

  /// 💯 Percentage progress with label
  static Widget percentage({
    required double value,
    Color? color,
    Color? backgroundColor,
    double size = 80,
    double strokeWidth = 6,
    TextStyle? textStyle,
  }) {
    final percentage = (value * 100).round();
    return _CircularPercentage(
      value: value,
      percentage: percentage,
      color: color ?? AppColors.crimson,
      backgroundColor: backgroundColor ?? AppColors.slate,
      size: size,
      strokeWidth: strokeWidth,
      textStyle: textStyle,
    );
  }
}

class _LinearProgress extends StatelessWidget {
  final double? value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius borderRadius;
  final String? label;
  final bool showPercentage;

  const _LinearProgress({
    this.value,
    required this.color,
    required this.backgroundColor,
    required this.height,
    required this.borderRadius,
    this.label,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = value != null ? (value! * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (showPercentage && value != null)
                  Text(
                    '$percentage%',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
            height: height,
            child: value != null
                ? LinearProgressIndicator(
                    value: value,
                    color: color,
                    backgroundColor: backgroundColor,
                    minHeight: height,
                  )
                : LinearProgressIndicator(
                    color: color,
                    backgroundColor: backgroundColor,
                    minHeight: height,
                  ),
          ),
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int current;
  final int total;
  final Color activeColor;
  final Color inactiveColor;
  final Color completedColor;
  final double dotSize;
  final double spacing;
  final bool showLabels;
  final List<String>? labels;

  const _StepProgress({
    required this.current,
    required this.total,
    required this.activeColor,
    required this.inactiveColor,
    required this.completedColor,
    required this.dotSize,
    required this.spacing,
    this.showLabels = false,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < current - 1;
          return Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.symmetric(horizontal: spacing),
              color: isCompleted ? completedColor : inactiveColor,
            ),
          );
        }

        // Dot
        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex < current - 1;
        final isActive = stepIndex == current - 1;

        Color dotColor;
        if (isCompleted) {
          dotColor = completedColor;
        } else if (isActive) {
          dotColor = activeColor;
        } else {
          dotColor = inactiveColor;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? dotSize * 1.2 : dotSize,
              height: isActive ? dotSize * 1.2 : dotSize,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      size: dotSize * 0.6,
                      color: AppColors.pureWhite,
                    )
                  : null,
            ),
            if (showLabels && labels != null && stepIndex < labels!.length) ...[
              const SizedBox(height: 4),
              Text(
                labels![stepIndex],
                style: AppTypography.labelSmall.copyWith(
                  color: isActive ? activeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  final int current;
  final int total;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final double gap;
  final BorderRadius borderRadius;

  const _SegmentedProgress({
    required this.current,
    required this.total,
    required this.activeColor,
    required this.inactiveColor,
    required this.height,
    required this.gap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final isActive = index < current;
        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : gap / 2,
              right: index == total - 1 ? 0 : gap / 2,
            ),
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: borderRadius,
            ),
          ),
        );
      }),
    );
  }
}

class _CircularPercentage extends StatelessWidget {
  final double value;
  final int percentage;
  final Color color;
  final Color backgroundColor;
  final double size;
  final double strokeWidth;
  final TextStyle? textStyle;

  const _CircularPercentage({
    required this.value,
    required this.percentage,
    required this.color,
    required this.backgroundColor,
    required this.size,
    required this.strokeWidth,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              color: backgroundColor,
            ),
          ),
          // Progress
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Percentage text
          Text(
            '$percentage%',
            style:
                textStyle ??
                AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
