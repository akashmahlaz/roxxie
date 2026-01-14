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

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../core/services/services.dart';
import 'login_screen_v2.dart';
import 'venue/venue_profile_setup_screen.dart';

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
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  // Form & Validation
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _acceptTerms = false;

  // Location state
  double? _latitude;
  double? _longitude;
  String? _detectedCity;
  String? _detectedCountry;

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
    _cityController.dispose();
    _countryController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _enterController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _getCurrentLocation() async {
    if (_isGettingLocation) return;
    HapticFeedback.lightImpact();

    setState(() => _isGettingLocation = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final locationResult = await _locationService.getCurrentLocationWithAddress();

      if (locationResult != null) {
        if (mounted) {
          setState(() {
            _cityController.text = locationResult.city ?? '';
            _countryController.text = locationResult.country ?? '';
            _latitude = locationResult.latitude;
            _longitude = locationResult.longitude;
            _detectedCity = locationResult.city;
            _detectedCountry = locationResult.country;
          });
        }
        HapticFeedback.mediumImpact();
        messenger.showSnackBar(_buildPremiumSnackBar(
          '📍 Location detected: ${locationResult.city}, ${locationResult.country}',
          Colors.green,
        ));
      }
    } catch (e) {
      messenger.showSnackBar(_buildPremiumSnackBar(
        '📍 Enable location or enter manually',
        _venueAccent,
      ));
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
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
      final city = _cityController.text.trim();
      final country = _countryController.text.trim();

      if (city.isEmpty && country.isEmpty) {
        throw _ValidationException('Please enter your city or enable location');
      }

      final success = await authProvider.register(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        name: _venueNameController.text.trim(),
        role: UserRole.venue,
        city: city.isNotEmpty ? city : null,
        country: country.isNotEmpty ? country : null,
        latitude: _latitude,
        longitude: _longitude,
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

                      // Glassmorphic form card
                      _buildFormCard(brightness),

                      const SizedBox(height: 24),

                      // Terms checkbox
                      _buildTermsCheckbox(brightness),

                      const SizedBox(height: 24),

                      // Submit button
                      _buildSubmitButton(),

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

        // Logo badge (blue for venue)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_venueAccent, _venueAccent.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _venueAccent.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'GigMatch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        const SizedBox(width: 48),
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
  // GLASSMORPHIC FORM CARD
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Venue name field
              _buildPremiumTextField(
                key: 'name',
                controller: _venueNameController,
                label: 'Venue Name',
                hint: 'Club / Bar / Event Space',
                icon: Icons.storefront_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 2) return 'Min 2 characters';
                  return null;
                },
                brightness: brightness,
              ),

              const SizedBox(height: 20),

              // Location fields
              _buildLocationFields(brightness),

              const SizedBox(height: 20),

              // Email field
              _buildPremiumTextField(
                key: 'email',
                controller: _emailController,
                label: 'Email Address',
                hint: 'venue@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v)) return 'Invalid email';
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
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textTert(brightness),
                    size: 22,
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
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  '8+ chars: A-Z, a-z, 0-9, @\$!%*?&',
                  style: TextStyle(
                    color: AppColors.textTert(brightness),
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Confirm password
              _buildPremiumTextField(
                key: 'confirmPassword',
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: '••••••••',
                icon: Icons.lock_reset_outlined,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textTert(brightness),
                    size: 22,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: _venueAccent.withValues(alpha: 0.2),
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
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.textTert(brightness),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  icon,
                  color: isFocused ? _venueAccent : AppColors.textTert(brightness),
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
                  borderSide: BorderSide(color: _venueAccent, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLocationFields(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City field
            Expanded(
              child: TextFormField(
                controller: _cityController,
                style: TextStyle(color: AppColors.text(brightness), fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'City',
                  hintStyle: TextStyle(color: AppColors.textTert(brightness)),
                  prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.textTert(brightness), size: 22),
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
                    borderSide: BorderSide(color: _venueAccent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // GPS button
            GestureDetector(
              onTap: _isGettingLocation ? null : _getCurrentLocation,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _venueAccent.withValues(alpha: 0.2),
                          _venueAccent.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _venueAccent.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _venueAccent.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isGettingLocation
                        ? Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: _venueAccent,
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.my_location_rounded, color: _venueAccent, size: 22),
                              Text(
                                'GPS',
                                style: TextStyle(
                                  color: _venueAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Country field
        TextFormField(
          controller: _countryController,
          style: TextStyle(color: AppColors.text(brightness), fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Country',
            hintStyle: TextStyle(color: AppColors.textTert(brightness)),
            prefixIcon: Icon(Icons.public_outlined, color: AppColors.textTert(brightness), size: 22),
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
              borderSide: BorderSide(color: _venueAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),

        // Location detected indicator
        if (_detectedCity != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                'GPS: $_detectedCity, $_detectedCountry',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          ),
        ],
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
                  ? LinearGradient(colors: [_venueAccent, _venueAccent.withValues(alpha: 0.8)])
                  : null,
              color: _acceptTerms ? null : Colors.transparent,
              border: Border.all(
                color: _acceptTerms ? _venueAccent : AppColors.border(brightness),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: _acceptTerms
                  ? [
                      BoxShadow(
                        color: _venueAccent.withValues(alpha: 0.3),
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
                    style: TextStyle(color: AppColors.textSec(brightness), fontSize: 14),
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(color: _venueAccent, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: TextStyle(color: AppColors.textSec(brightness), fontSize: 14),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: _venueAccent, fontSize: 14, fontWeight: FontWeight.w600),
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
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _venueAccent,
                  _venueAccent.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _venueAccent.withValues(alpha: _isLoading ? 0.2 : 0.4 * _pulseAnimation.value),
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Creating Profile...',
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
                        Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Create Venue Profile',
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
                pageBuilder: (_, __, ___) => const LoginScreenV2(),
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
