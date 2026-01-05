import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// ✨ GRADIENT BUTTON
///
/// Premium call-to-action button with gradient background
/// Includes hover animations and glow effects
///
/// Usage:
/// ```dart
/// GradientButton(
///   text: 'Get Started',
///   onPressed: () {},
/// )
/// ```

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final double? width;
  final double height;
  final bool isLoading;
  final bool enabled;
  final IconData? icon;
  final bool iconAfter;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.width,
    this.height = 56,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    this.iconAfter = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !widget.enabled || widget.isLoading;
    final Gradient effectiveGradient =
        widget.gradient ?? AppColors.primaryGradient;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: isDisabled
                    ? LinearGradient(
                        colors: [
                          AppColors.slate.withValues(alpha: 0.5),
                          AppColors.graphite.withValues(alpha: 0.5),
                        ],
                      )
                    : effectiveGradient,
                borderRadius: AppSpacing.borderRadiusMd,
                boxShadow: isDisabled
                    ? null
                    : _isPressed
                    ? AppShadows.buttonPressed
                    : AppShadows.buttonPrimary,
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null && !widget.iconAfter) ...[
                            Icon(
                              widget.icon,
                              color: isDisabled
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: AppTypography.labelLarge.copyWith(
                              color: isDisabled
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (widget.icon != null && widget.iconAfter) ...[
                            const SizedBox(width: 8),
                            Icon(
                              widget.icon,
                              color: isDisabled
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 🌟 NEON BUTTON
///
/// Button with neon glow effect for special actions

class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color glowColor;
  final double? width;
  final double height;
  final IconData? icon;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.glowColor = AppColors.electricViolet,
    this.width,
    this.height = 56,
    this.icon,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: widget.glowColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: 0.3 * _glowAnimation.value,
                ),
                blurRadius: 16 * _glowAnimation.value,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: 0.2 * _glowAnimation.value,
                ),
                blurRadius: 32 * _glowAnimation.value,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: AppSpacing.borderRadiusMd,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.glowColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: AppTypography.labelLarge.copyWith(
                        color: widget.glowColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 🔘 OUTLINE BUTTON
///
/// Subtle outline button for secondary actions

class RoxxieOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double height;

  const RoxxieOutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.slate, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
