/// 🎸 MODERN ARTIST SIGNUP SCREEN - 2026 DESIGN
///
/// Features:
/// ✅ Clean, professional design
/// ✅ Optimized scrolling
/// ✅ Full-width Google authentication
/// ✅ Modern padding & rounded corners
/// ✅ Haptic feedback integration
/// ✅ Animated form field focus
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/app_snackbar.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import 'login_screen.dart';
import 'artist/artist_profile_setup_screen.dart';
import 'role_selection_screen_v3.dart';

class ArtistSignupScreenV2 extends StatefulWidget {
  const ArtistSignupScreenV2({super.key});

  @override
  State<ArtistSignupScreenV2> createState() => _ArtistSignupScreenV2State();
}

class _ArtistSignupScreenV2State extends State<ArtistSignupScreenV2>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM CONTROLLERS
  // ═══════════════════════════════════════════════════════════════════════════
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form & Validation
  final _formKey = GlobalKey<FormState>();

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // Field focus states for animations
  final Map<String, bool> _fieldFocus = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNUP HANDLER
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleSignup() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (!_acceptTerms) {
      AppSnackBar.show(
        context,
        message: 'Please accept the Terms & Conditions',
        backgroundColor: AppColors.crimson,
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final authProvider = context.read<AuthProvider>();

      // Location will be collected via GPS in setup wizard Step 1
      final success = await authProvider.register(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: UserRole.artist,
      );

      if (!mounted) return;

      if (success) {
        HapticFeedback.heavyImpact();
        AppSnackBar.show(
          context,
          message: '✅ Account created! Complete your profile',
          backgroundColor: AppColors.success,
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const ArtistProfileSetupScreen(),
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        throw Exception(authProvider.errorMessage ?? 'Registration failed');
      }
    } on _ValidationException catch (e) {
      AppSnackBar.show(
        context,
        message: '⚠️ ${e.message}',
        backgroundColor: AppColors.crimson,
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      AppSnackBar.show(
        context,
        message: '❌ ${e.toString().replaceAll('Exception: ', '')}',
        backgroundColor: AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(brightness),

                  const SizedBox(height: 40),

                  // Title section
                  _buildTitleSection(brightness),

                  const SizedBox(height: 32),

                  // Form fields
                  _buildFormFields(brightness),

                  const SizedBox(height: 20),

                  // Terms checkbox
                  _buildTermsCheckbox(brightness),

                  const SizedBox(height: 24),

                  // Submit button
                  _buildSubmitButton(),

                  const SizedBox(height: 20),

                  // Or divider
                  _buildOrDivider(brightness),

                  const SizedBox(height: 20),

                  // Google sign-up button
                  _buildGoogleButton(brightness),

                  const SizedBox(height: 24),

                  // Login link
                  _buildLoginLink(brightness),
                ],
              ),
            ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(Brightness brightness) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border(brightness),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.text(brightness),
              size: 22,
            ),
          ),
        ),

        const Spacer(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TITLE SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTitleSection(Brightness brightness) {
    return Column(
      children: [
        Text(
          'Create Artist Profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Get discovered by venues looking for your talent',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM FIELDS - NO CARD WRAPPER (matches venue style)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFormFields(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        _buildPremiumTextField(
          key: 'name',
          controller: _nameController,
          label: 'Display Name',
          hint: 'Your band or artist name',
          icon: Icons.person_rounded,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (v.trim().length < 2) return 'Min 2 characters';
            return null;
          },
          brightness: brightness,
        ),

        const SizedBox(height: 24),

        // Email field
        _buildPremiumTextField(
          key: 'email',
          controller: _emailController,
          label: 'Email Address',
          hint: 'yourname@example.com',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(v)) return 'Invalid email';
            return null;
          },
          brightness: brightness,
        ),

        const SizedBox(height: 24),

        // Password field
        _buildPremiumTextField(
          key: 'password',
          controller: _passwordController,
          label: 'Password',
          hint: 'Create a strong password',
          icon: Icons.lock_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: AppColors.textTert(brightness),
              size: 24,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 8) return 'Min 8 characters';
            if (!v.contains(RegExp(r'[A-Z]'))) return 'Need uppercase';
            if (!v.contains(RegExp(r'[a-z]'))) return 'Need lowercase';
            if (!v.contains(RegExp(r'[0-9]'))) return 'Need number';
            if (!v.contains(RegExp(r'[@$!%*?&]'))) return 'Need special char';
            return null;
          },
          brightness: brightness,
        ),

        // Password hint
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.textTert(brightness),
              ),
              const SizedBox(width: 6),
              Text(
                '8+ chars: A-Z, a-z, 0-9, @\$!%*?&',
                style: TextStyle(
                  color: AppColors.textTert(brightness),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Confirm password
        _buildPremiumTextField(
          key: 'confirmPassword',
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          icon: Icons.lock_reset_rounded,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: AppColors.textTert(brightness),
              size: 24,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v != _passwordController.text) return 'Passwords don\'t match';
            return null;
          },
          brightness: brightness,
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM TEXT FIELD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPremiumTextField({
    required String key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    required Brightness brightness,
  }) {
    final isFocused = _fieldFocus[key] ?? false;
    final isDark = brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isFocused
                ? AppColors.crimson
                : AppColors.textSec(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) {
            setState(() => _fieldFocus[key] = focused);
            if (focused) HapticFeedback.selectionClick();
          },
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textTert(brightness),
                fontSize: 15,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  icon,
                  color: isFocused
                      ? AppColors.crimson
                      : AppColors.textTert(brightness),
                  size: 20,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: isDark
                  ? AppColors.graphite.withValues(alpha: 0.5)
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.slate.withValues(alpha: 0.5)
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppColors.crimson, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TERMS CHECKBOX
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTermsCheckbox(Brightness brightness) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _acceptTerms = !_acceptTerms);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: _acceptTerms
                  ? LinearGradient(
                      colors: [
                        AppColors.crimson,
                        AppColors.crimson.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: _acceptTerms ? null : Colors.transparent,
              border: Border.all(
                color: _acceptTerms
                    ? AppColors.crimson
                    : AppColors.border(brightness),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: _acceptTerms
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: _acceptTerms
                ? Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBMIT BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSignup,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.crimson,
              AppColors.crimson.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Please wait...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIN LINK
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoginLink(Brightness brightness) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 15),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, _, _) => const LoginScreen(),
                transitionsBuilder: (_, animation, _, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: AppColors.crimson,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OR DIVIDER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOrDivider(Brightness brightness) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.border(brightness), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or sign up with',
            style: TextStyle(
              color: AppColors.textTert(brightness),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.border(brightness), thickness: 1),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOCIAL BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGoogleButton(Brightness brightness) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleGoogleSignUp,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border(brightness),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.g_mobiledata_rounded,
                  color: AppColors.text(brightness),
                  size: 28,
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignUp() async {
    HapticFeedback.lightImpact();
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      // Pass artist role for social signup
      final success = await authProvider.signInWithGoogle(
        role: UserRole.artist,
      );

      if (!mounted) return;

      if (success) {
        HapticFeedback.heavyImpact();
        _navigateAfterSocialLogin(authProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Google sign-up failed'),
            backgroundColor: AppColors.crimson,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAfterSocialLogin(AuthProvider authProvider) {
    if (authProvider.status == AuthStatus.needsRoleSelection) {
      // Shouldn't happen since we passed role, but handle it
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreenV3()),
      );
    } else if (authProvider.status == AuthStatus.profileIncomplete) {
      // Go to artist profile setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ArtistProfileSetupScreen()),
      );
    } else if (authProvider.status == AuthStatus.authenticated) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VALIDATION EXCEPTION
// ═══════════════════════════════════════════════════════════════════════════════

class _ValidationException implements Exception {
  final String message;
  const _ValidationException(this.message);
}
