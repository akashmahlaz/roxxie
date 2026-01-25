/// 🎭 ANIMATED MICRO-INTERACTIONS
///
/// 2026 Design Trend: Motion feedback that delights users
/// Implements subtle animations that provide immediate feedback
/// and create an engaging, responsive experience.
///
/// Features:
/// - Tap feedback with scale + haptic
/// - Success/Error state animations
/// - Skeleton loading with shimmer
/// - Pull-to-refresh with custom physics
/// - Optimistic state patterns
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🔘 ANIMATED TAP FEEDBACK
// ═══════════════════════════════════════════════════════════════════════════

/// Provides Material 3 compliant tap feedback with scale animation
/// Usage: Wrap any widget for instant tap feedback
class AnimatedTapFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDownTo;
  final Duration duration;
  final bool hapticFeedback;
  final bool enabled;

  const AnimatedTapFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDownTo = 0.96,
    this.duration = const Duration(milliseconds: 100),
    this.hapticFeedback = true,
    this.enabled = true,
  });

  @override
  State<AnimatedTapFeedback> createState() => _AnimatedTapFeedbackState();
}

class _AnimatedTapFeedbackState extends State<AnimatedTapFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDownTo,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled) return;

    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    await _controller.forward();
    await _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ✨ ANIMATED SUCCESS/ERROR INDICATOR
// ═══════════════════════════════════════════════════════════════════════════

/// Animated check mark for success states (like subscribe button pattern)
class AnimatedSuccessCheck extends StatefulWidget {
  final bool show;
  final double size;
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedSuccessCheck({
    super.key,
    this.show = true, // Default to true for simpler usage
    this.size = 24,
    this.color = AppColors.success,
    this.duration = const Duration(milliseconds: 400),
    this.onComplete,
  });

  @override
  State<AnimatedSuccessCheck> createState() => _AnimatedSuccessCheckState();
}

class _AnimatedSuccessCheckState extends State<AnimatedSuccessCheck>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;
  late Animation<double> _circleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedSuccessCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    } else if (!widget.show && oldWidget.show) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _SuccessCheckPainter(
              circleProgress: _circleAnimation.value,
              checkProgress: _checkAnimation.value,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _SuccessCheckPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  _SuccessCheckPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw circle
    if (circleProgress > 0) {
      final circlePaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * circleProgress, circlePaint);

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708, // Start from top
        6.2832 * circleProgress, // Full circle
        false,
        strokePaint,
      );
    }

    // Draw check mark
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      final startX = size.width * 0.25;
      final startY = size.height * 0.5;
      final midX = size.width * 0.45;
      final midY = size.height * 0.65;
      final endX = size.width * 0.75;
      final endY = size.height * 0.35;

      path.moveTo(startX, startY);
      if (checkProgress < 0.5) {
        final progress = checkProgress * 2;
        path.lineTo(
          startX + (midX - startX) * progress,
          startY + (midY - startY) * progress,
        );
      } else {
        path.lineTo(midX, midY);
        final progress = (checkProgress - 0.5) * 2;
        path.lineTo(
          midX + (endX - midX) * progress,
          midY + (endY - midY) * progress,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_SuccessCheckPainter oldDelegate) {
    return circleProgress != oldDelegate.circleProgress ||
        checkProgress != oldDelegate.checkProgress;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔄 SKELETON SHIMMER LOADING
// ═══════════════════════════════════════════════════════════════════════════

/// Premium shimmer loading effect for skeleton screens
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final brightness = Theme.of(context).brightness;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: brightness == Brightness.dark
                  ? [
                      AppColors.shimmerBase,
                      AppColors.shimmerHighlight,
                      AppColors.shimmerBase,
                    ]
                  : [
                      Colors.grey.shade200,
                      Colors.grey.shade100,
                      Colors.grey.shade200,
                    ],
              stops: [0.0, 0.5 + _animation.value * 0.25, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton placeholder shapes
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppColors.graphite
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppColors.graphite
            : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎯 OPTIMISTIC STATE BUTTON
// ═══════════════════════════════════════════════════════════════════════════

/// Implements the Optimistic State pattern from Flutter architecture guide
/// Shows immediate feedback while async operation runs in background
class OptimisticButton extends StatefulWidget {
  final String? text;
  final String? label; // Alias for text
  final String? successText;
  final IconData? icon;
  final IconData? successIcon;
  final Future<bool> Function()? onPressed;
  final VoidCallback? onTap; // Simple callback alternative
  final Color? color;
  final Color? successColor;
  final bool isLoading; // External loading state

  const OptimisticButton({
    super.key,
    this.text,
    this.label,
    this.successText,
    this.icon,
    this.successIcon,
    this.onPressed,
    this.onTap,
    this.color,
    this.successColor,
    this.isLoading = false,
  });

  String get displayText => text ?? label ?? 'Submit';
  String get displaySuccessText => successText ?? 'Success!';
  IconData get displayIcon => icon ?? Icons.send_rounded;
  IconData get displaySuccessIcon => successIcon ?? Icons.check_rounded;

  @override
  State<OptimisticButton> createState() => _OptimisticButtonState();
}

class _OptimisticButtonState extends State<OptimisticButton>
    with SingleTickerProviderStateMixin {
  bool _isSuccess = false;
  bool _isLoading = false;
  bool _hasError = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isSuccess || _isLoading || widget.isLoading) return;

    // Simple callback path
    if (widget.onTap != null) {
      HapticFeedback.mediumImpact();
      widget.onTap!();
      return;
    }

    // Optimistic callback path
    if (widget.onPressed == null) return;

    // Optimistic: Show success immediately
    HapticFeedback.mediumImpact();
    setState(() {
      _isSuccess = true;
      _isLoading = true;
    });
    _controller.forward().then((_) => _controller.reverse());

    try {
      final result = await widget.onPressed!();
      if (!result) {
        // Revert on failure
        HapticFeedback.heavyImpact();
        setState(() {
          _isSuccess = false;
          _hasError = true;
        });

        // Show error briefly
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _hasError = false);
        }
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSuccess = false;
        _hasError = true;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _hasError = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? AppColors.crimson;
    final successColor = widget.successColor ?? AppColors.success;
    final isCurrentlyLoading = widget.isLoading || _isLoading;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                color: _hasError
                    ? AppColors.error.withValues(alpha: 0.15)
                    : _isSuccess
                    ? successColor.withValues(alpha: 0.15)
                    : baseColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasError
                      ? AppColors.error
                      : _isSuccess
                      ? successColor
                      : baseColor,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: isCurrentlyLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _hasError
                                  ? Icons.error_outline_rounded
                                  : _isSuccess
                                  ? widget.displaySuccessIcon
                                  : widget.displayIcon,
                              key: ValueKey(_isSuccess),
                              color: _hasError
                                  ? AppColors.error
                                  : _isSuccess
                                  ? successColor
                                  : baseColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _hasError
                                  ? 'Failed'
                                  : _isSuccess
                                  ? widget.displaySuccessText
                                  : widget.displayText,
                              key: ValueKey(_isSuccess),
                              style: TextStyle(
                                color: _hasError
                                    ? AppColors.error
                                    : _isSuccess
                                    ? successColor
                                    : baseColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💫 ANIMATED COUNTER
// ═══════════════════════════════════════════════════════════════════════════

/// Smoothly animates number changes (stats, counts, etc.)
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '${prefix ?? ''}$animatedValue${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🌊 LIQUID GLASS EFFECT (iOS 26 / 2026 Trend)
// ═══════════════════════════════════════════════════════════════════════════

/// Enhanced glassmorphism with liquid glass effect
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? tintColor;
  final Color? glowColor; // Custom glow color
  final double tintOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool showBorder;
  final bool showGlow;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.tintColor,
    this.glowColor,
    this.tintOpacity = 0.05,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.showBorder = true,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final effectiveTint =
        tintColor ??
        (brightness == Brightness.dark ? Colors.white : Colors.black);
    final effectiveGlow = glowColor ?? AppColors.crimson;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: effectiveGlow.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Liquid glass gradient
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveTint.withValues(alpha: tintOpacity + 0.03),
                  effectiveTint.withValues(alpha: tintOpacity),
                  effectiveTint.withValues(alpha: tintOpacity + 0.02),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: effectiveTint.withValues(alpha: 0.12),
                      width: 1,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📱 CONTEXT-AWARE GREETING
// ═══════════════════════════════════════════════════════════════════════════

/// Returns context-aware greeting based on time of day
String getContextualGreeting() {
  final hour = DateTime.now().hour;

  if (hour < 5) return 'Night owl mode';
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  if (hour < 21) return 'Good evening';
  return 'Good night';
}

/// Returns emoji for time of day (for contextual UI)
IconData getTimeOfDayIcon() {
  final hour = DateTime.now().hour;

  if (hour < 6 || hour >= 20) return Icons.nightlight_rounded;
  if (hour < 12) return Icons.wb_sunny_rounded;
  if (hour < 17) return Icons.wb_cloudy_rounded;
  return Icons.wb_twilight_rounded;
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔲 SHIMMER BASE - Simple skeleton box with shimmer
// ═══════════════════════════════════════════════════════════════════════════

/// Simple shimmer placeholder box for skeleton loading
/// Used as `ShimmerBase(width: 100, height: 20)` in skeleton screens
class ShimmerBase extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  const ShimmerBase({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppColors.shimmerBase
            : const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}
