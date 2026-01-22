/// 🏛️ ULTRA-PREMIUM VENUE SIGNUP SCREEN V2 - 2026 DESIGN
///
/// Features:
/// ✅ Animated particle background
/// ✅ Glassmorphic form cards
/// ✅ Premium animated step indicator
/// ✅ 3D floating hero icon
/// ✅ Shimmer loading states
/// ✅ Micro-interaction feedback
/// ✅ Haptic feedback integration
/// ✅ Animated form field focus
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import 'login_screen.dart';
import 'venue/venue_profile_setup_screen.dart';
import 'role_selection_screen_v3.dart';

class VenueSignupScreenV2 extends StatefulWidget {
  const VenueSignupScreenV2({super.key});

  @override
  State<VenueSignupScreenV2> createState() => _VenueSignupScreenV2State();
}

class _VenueSignupScreenV2State extends State<VenueSignupScreenV2>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM CONTROLLERS
  // ═══════════════════════════════════════════════════════════════════════════
  final _venueNameController = TextEditingController();
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
  final List<_VenueParticle> _particles = [];
  final math.Random _random = math.Random();

  // Venue accent color (blue instead of crimson)
  static const Color _venueAccent = Color(0xFF3B82F6); // Blue

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
    for (int i = 0; i < 40; i++) {
      _particles.add(_VenueParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.15 + 0.05,
        opacity: _random.nextDouble() * 0.4 + 0.1,
      ));
    }
  }

  void _initAnimations() {
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _enterAnimation = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutExpo,
    );
    _enterController.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _venueNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _enterController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  SnackBar _buildPremiumSnackBar(String message, Color color) {
    return SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      elevation: 8,
    );
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
      ScaffoldMessenger.of(context).showSnackBar(_buildPremiumSnackBar(
        'Please accept the Terms & Conditions',
        _venueAccent,
      ));
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.register(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        name: _venueNameController.text.trim(),
        role: UserRole.venue,
      );

      if (!mounted) return;

      if (success) {
        HapticFeedback.heavyImpact();
        messenger.showSnackBar(_buildPremiumSnackBar(
          '✅ Account created! Complete your venue profile',
          Colors.green,
        ));

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const VenueProfileSetupScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
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
      messenger.showSnackBar(_buildPremiumSnackBar('⚠️ ${e.message}', _venueAccent));
    } catch (e) {
      HapticFeedback.heavyImpact();
      messenger.showSnackBar(_buildPremiumSnackBar(
        '❌ ${e.toString().replaceAll('Exception: ', '')}',
        Colors.red.shade400,
      ));
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
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Stack(
        children: [
          // Layer 1: Particle background
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _VenueParticleFieldPainter(
                  particles: _particles,
                  progress: _particleController.value,
                  color: isDark ? Colors.white : _venueAccent,
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

                      const SizedBox(height: 32),

                      // Floating hero icon
                      _buildHeroIcon(),

                      const SizedBox(height: 24),

                      // Title section
                      _buildTitleSection(brightness),

                      const SizedBox(height: 32),

                      // Form fields (no card wrapper)
                      _buildFormFields(brightness),

                      const SizedBox(height: 28),

                      // Terms checkbox
                      _buildTermsCheckbox(brightness),

                      const SizedBox(height: 24),

                      // Submit button
                      _buildSubmitButton(),

                      const SizedBox(height: 24),

                      // Or divider
                      _buildOrDivider(brightness),

                      const SizedBox(height: 24),

                      // Social sign-up buttons
                      _buildSocialButtons(brightness),

                      const SizedBox(height: 24),

                      // Login link
                      _buildLoginLink(brightness),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
          painter: _VenueGradientOrbPainter(
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
            Navigator.pop(context);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground(brightness).withValues(alpha: 0.5),
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
  // FLOATING HERO ICON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _pulseAnimation]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _venueAccent,
                      _venueAccent.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _venueAccent.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TITLE SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTitleSection(Brightness brightness) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            final shimmerValue = (_shimmerController.value * 3 - 1).clamp(0.0, 1.0);
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    AppColors.text(brightness),
                    _venueAccent,
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
                'Create Venue Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Find talented artists for your stage',
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
  // FORM FIELDS - NO CARD WRAPPER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFormFields(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Venue name field
        _buildPremiumTextField(
          key: 'name',
          controller: _venueNameController,
          label: 'Venue Name',
          hint: 'Your venue or business name',
          icon: Icons.storefront_rounded,
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
                    _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: AppColors.textTert(brightness),
                    size: 24,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                padding: const EdgeInsets.only(top: 10, left: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.textTert(brightness),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '8+ chars with A-Z, a-z, 0-9, @\$!%*?&',
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
                    _obscureConfirmPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: AppColors.textTert(brightness),
                    size: 24,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
            color: isFocused ? _venueAccent : AppColors.textSec(brightness),
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
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  color: isFocused ? _venueAccent : AppColors.textTert(brightness),
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
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.slate.withValues(alpha: 0.5) : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _venueAccent, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: _acceptTerms
                  ? LinearGradient(colors: [_venueAccent, _venueAccent.withValues(alpha: 0.8)])
                  : null,
              color: _acceptTerms ? null : Colors.transparent,
              border: Border.all(
                color: _acceptTerms ? _venueAccent : AppColors.border(brightness),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _acceptTerms
                  ? [
                      BoxShadow(
                        color: _venueAccent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: _acceptTerms
                ? Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(color: AppColors.textSec(brightness), fontSize: 15),
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(color: _venueAccent, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: TextStyle(color: AppColors.textSec(brightness), fontSize: 15),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: _venueAccent, fontSize: 15, fontWeight: FontWeight.w600),
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
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _venueAccent,
                  _venueAccent.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _venueAccent.withValues(alpha: _isLoading ? 0.2 : 0.4 * _pulseAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Creating Profile...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Create Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          );
        },
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
                pageBuilder: (_, __, ___) => const LoginScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: _venueAccent,
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
        Expanded(child: Divider(color: AppColors.border(brightness), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or sign up with',
            style: TextStyle(color: AppColors.textTert(brightness), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border(brightness), thickness: 1)),
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
            onTap: _handleGoogleSignUp,
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
                onTap: isAvailable ? _handleAppleSignUp : null,
                brightness: brightness,
                disabled: !isAvailable,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignUp() async {
    HapticFeedback.lightImpact();
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      // Pass venue role for social signup
      final success = await authProvider.signInWithGoogle(role: UserRole.venue);
      
      if (!mounted) return;
      
      if (success) {
        HapticFeedback.heavyImpact();
        _navigateAfterSocialLogin(authProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Google sign-up failed'),
            backgroundColor: _venueAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignUp() async {
    HapticFeedback.lightImpact();
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      // Pass venue role for social signup
      final success = await authProvider.signInWithApple(role: UserRole.venue);
      
      if (!mounted) return;
      
      if (success) {
        HapticFeedback.heavyImpact();
        _navigateAfterSocialLogin(authProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Apple sign-up failed'),
            backgroundColor: _venueAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      // Go to venue profile setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VenueProfileSetupScreen()),
      );
    } else if (authProvider.status == AuthStatus.authenticated) {
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
    final isDark = brightness == Brightness.dark;
    return GestureDetector(
      onTap: disabled || _isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.graphite.withValues(alpha: 0.6)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.slate : Colors.grey[300]!,
              width: 1.5,
            ),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARTICLE CLASS
// ═══════════════════════════════════════════════════════════════════════════════

class _VenueParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _VenueParticle({
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

class _VenueParticleFieldPainter extends CustomPainter {
  final List<_VenueParticle> particles;
  final double progress;
  final Color color;

  _VenueParticleFieldPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y - progress * particle.speed) % 1.0;
      final x = particle.x + math.sin(progress * math.pi * 2 + particle.x * 10) * 0.02;

      final twinkle = 0.5 + 0.5 * math.sin(progress * math.pi * 4 + particle.x * 15);

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
  bool shouldRepaint(covariant _VenueParticleFieldPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRADIENT ORB PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _VenueGradientOrbPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  static const Color _venueAccent = Color(0xFF3B82F6);

  _VenueGradientOrbPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Top-right blue orb
    final orb1X = size.width * 0.85 + math.cos(progress * math.pi * 2) * 30;
    final orb1Y = size.height * 0.15 + math.sin(progress * math.pi * 2) * 20;

    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _venueAccent.withValues(alpha: isDark ? 0.2 : 0.12),
          _venueAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(orb1X, orb1Y), radius: 150));

    canvas.drawCircle(Offset(orb1X, orb1Y), 150, orb1Paint);

    // Bottom-left cyan orb
    final orb2X = size.width * 0.1 + math.sin(progress * math.pi * 2) * 25;
    final orb2Y = size.height * 0.85 + math.cos(progress * math.pi * 2) * 30;

    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.cyan.withValues(alpha: isDark ? 0.1 : 0.06),
          Colors.cyan.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(orb2X, orb2Y), radius: 120));

    canvas.drawCircle(Offset(orb2X, orb2Y), 120, orb2Paint);
  }

  @override
  bool shouldRepaint(covariant _VenueGradientOrbPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// VALIDATION EXCEPTION
// ═══════════════════════════════════════════════════════════════════════════════

class _ValidationException implements Exception {
  final String message;
  const _ValidationException(this.message);
}
