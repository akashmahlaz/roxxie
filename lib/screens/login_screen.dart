/// 🔐 ULTRA-PREMIUM LOGIN SCREEN V2 - 2026 DESIGN
///
/// Features:
/// ✅ Animated particle background
/// ✅ Glassmorphic form card
/// ✅ 3D floating logo with pulse
/// ✅ Shimmer text effects
/// ✅ Premium field animations
/// ✅ Haptic feedback integration
/// ✅ Biometric login option
/// ✅ Social login buttons
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/app_snackbar.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROLLERS
  // ═══════════════════════════════════════════════════════════════════════════
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  final Map<String, bool> _fieldFocus = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION CONTROLLERS
  // ═══════════════════════════════════════════════════════════════════════════
  late AnimationController _particleController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _enterController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _enterAnimation;

  // Particles
  final List<_LoginParticle> _particles = [];
  final math.Random _random = math.Random();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initAnimations();
  }

  void _initParticles() {
    for (int i = 0; i < 35; i++) {
      _particles.add(
        _LoginParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1,
          speed: _random.nextDouble() * 0.15 + 0.05,
          opacity: _random.nextDouble() * 0.4 + 0.1,
        ),
      );
    }
  }

  void _initAnimations() {
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _enterAnimation = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutExpo,
    );
    _enterController.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _enterController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIN HANDLER
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        HapticFeedback.heavyImpact();
        // Use hasCompletedOnboarding (profile exists) instead of isProfileComplete
        if (authProvider.hasCompletedOnboarding) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          if (authProvider.isArtist) {
            Navigator.pushReplacementNamed(context, '/artist-setup');
          } else {
            Navigator.pushReplacementNamed(context, '/venue-setup');
          }
        }
      } else {
        _showErrorSnackBar(authProvider.errorMessage ?? 'Login failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    HapticFeedback.heavyImpact();
    AppSnackBar.show(
      context,
      message: message,
      backgroundColor: AppColors.error,
    );
  }

  void _showForgotPasswordDialog() {
    HapticFeedback.lightImpact();
    final emailController = TextEditingController();
    final brightness = Theme.of(context).brightness;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppColors.surface(brightness),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.crimson,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Reset Password',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your email and we\'ll send you a reset link.',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    hintStyle: TextStyle(color: AppColors.textTert(brightness)),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.textTert(brightness),
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill(brightness),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: AppColors.text(brightness)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSec(brightness)),
                ),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        final email = emailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please enter a valid email'),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSending = true);
                        HapticFeedback.mediumImpact();

                        try {
                          final authProvider = context.read<AuthProvider>();
                          final success = await authProvider.forgotPassword(
                            email,
                          );

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '✅ Reset link sent to $email'
                                    : '❌ Failed to send reset link',
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSending = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send Link',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Navigate to role selection instead of allowing back with empty stack
        Navigator.of(context).pushReplacementNamed('/role-selection');
      },
      child: Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: Stack(
          children: [
            // Layer 1: Particle background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticleFieldPainter(
                    particles: _particles,
                    progress: _particleController.value,
                    color: isDark ? Colors.white : AppColors.crimson,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Layer 2: Gradient orbs
            _buildGradientOrbs(isDark),

            // Layer 3: Main content
            SafeArea(
              child: FadeTransition(
                opacity: _enterAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),

                        // Header
                        _buildHeader(brightness),

                        const SizedBox(height: 40),

                        // Floating logo
                        _buildFloatingLogo(),

                        const SizedBox(height: 32),

                        // Title
                        _buildTitle(brightness),

                        const SizedBox(height: 40),

                        // Form card
                        _buildFormCard(brightness),

                        const SizedBox(height: 24),

                        // Login button
                        _buildLoginButton(),

                        const SizedBox(height: 20),

                        // Or divider
                        _buildOrDivider(brightness),

                        const SizedBox(height: 20),

                        // Social login buttons
                        _buildSocialButtons(brightness),

                        const SizedBox(height: 32),

                        // Sign up link
                        _buildSignUpLink(brightness),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENT ORBS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGradientOrbs(bool isDark) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        return CustomPaint(
          painter: _GradientOrbPainter(
            progress: _floatController.value,
            isDark: isDark,
          ),
          size: Size.infinite,
        );
      },
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
            Navigator.of(context).pushReplacementNamed('/role-selection');
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground(
                    brightness,
                  ).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border(brightness).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.text(brightness),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING LOGO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFloatingLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _pulseAnimation]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.crimson,
                      AppColors.crimson.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.5),
                      blurRadius: 50,
                      spreadRadius: 10,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.equalizer_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TITLE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTitle(Brightness brightness) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            final shimmerValue = (_shimmerController.value * 3 - 1).clamp(
              0.0,
              1.0,
            );
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    AppColors.text(brightness),
                    AppColors.crimson,
                    AppColors.text(brightness),
                  ],
                  stops: [
                    (shimmerValue - 0.3).clamp(0.0, 1.0),
                    shimmerValue,
                    (shimmerValue + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to GigMatch',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 15),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFormCard(Brightness brightness) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(brightness).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.border(brightness).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email field
              _buildPremiumTextField(
                key: 'email',
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
                brightness: brightness,
              ),

              const SizedBox(height: 20),

              // Password field
              _buildPremiumTextField(
                key: 'password',
                controller: _passwordController,
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textTert(brightness),
                    size: 22,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  return null;
                },
                brightness: brightness,
              ),

              const SizedBox(height: 16),

              // Remember me & Forgot password
              Row(
                children: [
                  // Remember me
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _rememberMe = !_rememberMe);
                    },
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: _rememberMe
                                ? LinearGradient(
                                    colors: [
                                      AppColors.crimson,
                                      AppColors.crimson.withValues(alpha: 0.8),
                                    ],
                                  )
                                : null,
                            color: _rememberMe ? null : Colors.transparent,
                            border: Border.all(
                              color: _rememberMe
                                  ? AppColors.crimson
                                  : AppColors.border(brightness),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _rememberMe
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            color: AppColors.textSec(brightness),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Forgot password
                  GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.crimson,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: TextStyle(color: AppColors.text(brightness), fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.textTert(brightness),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  icon,
                  color: isFocused
                      ? AppColors.crimson
                      : AppColors.textTert(brightness),
                  size: 22,
                ),
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: AppColors.inputFill(brightness),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border(brightness)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border(brightness)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.crimson, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIN BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          return AnimatedContainer(
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withValues(
                    alpha: _isLoading ? 0.2 : 0.4 * _pulseAnimation.value,
                  ),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
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
                          'Signing In...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
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
            'or continue with',
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

  Widget _buildSocialButtons(Brightness brightness) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: Icons.g_mobiledata_rounded,
            label: 'Google',
            onTap: _handleGoogleSignIn,
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<bool>(
            future: context.read<AuthProvider>().isAppleSignInAvailable(),
            builder: (context, snapshot) {
              final isAvailable = snapshot.data ?? false;
              return _buildSocialButton(
                icon: Icons.apple_rounded,
                label: 'Apple',
                onTap: isAvailable ? _handleAppleSignIn : null,
                brightness: brightness,
                disabled: !isAvailable,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signInWithGoogle();

      if (!mounted) return;

      if (success) {
        HapticFeedback.heavyImpact();
        _navigateAfterSocialLogin(authProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Google sign-in failed'),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    HapticFeedback.lightImpact();
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signInWithApple();

      if (!mounted) return;

      if (success) {
        HapticFeedback.heavyImpact();
        _navigateAfterSocialLogin(authProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Apple sign-in failed'),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAfterSocialLogin(AuthProvider authProvider) {
    if (authProvider.status == AuthStatus.needsRoleSelection) {
      // User needs to select artist or venue role
      Navigator.pushReplacementNamed(context, '/role-selection');
    } else if (authProvider.status == AuthStatus.profileIncomplete) {
      // User has role but needs to complete profile
      Navigator.pushNamedAndRemoveUntil(
        context,
        authProvider.isArtist ? '/artist-setup' : '/venue-setup',
        (route) => false,
      );
    } else if (authProvider.status == AuthStatus.authenticated) {
      // User is fully set up
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Brightness brightness,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled || _isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.cardBackground(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.text(brightness), size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGN UP LINK
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSignUpLink(Brightness brightness) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 15),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacementNamed(context, '/role-selection');
          },
          child: Text(
            'Sign Up',
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARTICLE CLASS
// ═══════════════════════════════════════════════════════════════════════════════

class _LoginParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _LoginParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARTICLE PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _ParticleFieldPainter extends CustomPainter {
  final List<_LoginParticle> particles;
  final double progress;
  final Color color;

  _ParticleFieldPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y - progress * particle.speed) % 1.0;
      final x =
          particle.x +
          math.sin(progress * math.pi * 2 + particle.x * 10) * 0.02;
      final twinkle =
          0.5 + 0.5 * math.sin(progress * math.pi * 4 + particle.x * 15);

      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity * twinkle * 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRADIENT ORB PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _GradientOrbPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _GradientOrbPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final orb1X = size.width * 0.8 + math.cos(progress * math.pi * 2) * 30;
    final orb1Y = size.height * 0.2 + math.sin(progress * math.pi * 2) * 20;

    final orb1Paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.crimson.withValues(alpha: isDark ? 0.2 : 0.12),
              AppColors.crimson.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(orb1X, orb1Y), radius: 150),
          );

    canvas.drawCircle(Offset(orb1X, orb1Y), 150, orb1Paint);

    final orb2X = size.width * 0.15 + math.sin(progress * math.pi * 2) * 25;
    final orb2Y = size.height * 0.75 + math.cos(progress * math.pi * 2) * 30;

    final orb2Paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.purple.withValues(alpha: isDark ? 0.1 : 0.06),
              Colors.purple.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(orb2X, orb2Y), radius: 120),
          );

    canvas.drawCircle(Offset(orb2X, orb2Y), 120, orb2Paint);
  }

  @override
  bool shouldRepaint(covariant _GradientOrbPainter oldDelegate) => true;
}
