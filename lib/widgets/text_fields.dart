import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 📝 PREMIUM TEXT FIELD
///
/// Beautiful input field with animations and premium styling
///
/// Usage:
/// ```dart
/// PremiumTextField(
///   label: 'Email',
///   hint: 'Enter your email',
///   prefixIcon: Icons.email,
/// )
/// ```

class PremiumTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool showLabel;

  const PremiumTextField({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.showLabel = true,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _borderAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _borderAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && widget.showLabel) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium.copyWith(
              color: _isFocused
                  ? AppColors.electricViolet
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AnimatedBuilder(
          animation: _borderAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: AppSpacing.borderRadiusMd,
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.electricViolet.withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                enabled: widget.enabled,
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines,
                validator: widget.validator,
                onChanged: widget.onChanged,
                textInputAction: widget.textInputAction,
                onFieldSubmitted: widget.onSubmitted,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: _isFocused
                              ? AppColors.electricViolet
                              : AppColors.textTertiary,
                          size: 22,
                        )
                      : null,
                  suffixIcon: widget.suffixIcon != null
                      ? IconButton(
                          icon: Icon(
                            widget.suffixIcon,
                            color: AppColors.textTertiary,
                            size: 22,
                          ),
                          onPressed: widget.onSuffixTap,
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                    borderSide: BorderSide(
                      color: AppColors.slate,
                      width: _borderAnimation.value,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                    borderSide: BorderSide(
                      color: AppColors.electricViolet,
                      width: _borderAnimation.value,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// � GLASS TEXT FIELD (Alias for PremiumTextField with legacy parameter names)
///
/// Glass-morphism styled input field
///
/// Usage:
/// ```dart
/// GlassTextField(
///   labelText: 'Email',
///   hintText: 'Enter your email',
///   prefixIcon: Icons.email,
/// )
/// ```

class GlassTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const GlassTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumTextField(
      label: labelText,
      hint: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onSuffixTap: onSuffixTap,
      obscureText: obscureText,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }
}

/// �🔍 SEARCH FIELD
///
/// Premium search input with animations

class PremiumSearchField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;

  const PremiumSearchField({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.slate),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textTertiary),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
