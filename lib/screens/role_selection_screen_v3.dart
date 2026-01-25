/// 🎭 ULTRA-PREMIUM ROLE SELECTION SCREEN V3 - 2026 DESIGN
///
/// Features:
/// ✅ Animated particle starfield background
/// ✅ 3D floating role cards with perspective tilt
/// ✅ Glassmorphism with noise texture
/// ✅ Shimmer text effects
/// ✅ Haptic feedback integration
/// ✅ Morphing gradient orbs
/// ✅ Character-by-character text reveal
/// ✅ Premium micro-interactions
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import 'artist_signup_screen_v2.dart';
import 'venue_signup_screen_v2.dart';
import 'login_screen.dart';

class RoleSelectionScreenV3 extends StatefulWidget {
  const RoleSelectionScreenV3({super.key});

  @override
  State<RoleSelectionScreenV3> createState() => _RoleSelectionScreenV3State();
}

class _RoleSelectionScreenV3State extends State<RoleSelectionScreenV3>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION CONTROLLERS
  // ═══════════════════════════════════════════════════════════════════════════
  late AnimationController _particleController;
  late AnimationController _fadeController;
  late AnimationController _orbController;
  late AnimationController _shimmerController;
  late AnimationController _cardFloatController;
  late AnimationController _textRevealController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _cardFloatAnimation;
  late Animation<double> _textRevealAnimation;

  // Particle system
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  // Card hover states
  bool _artistCardHovered = false;
  bool _venueCardHovered = false;

  // Card tilt values (reserved for 3D hover effects)
  // Uncomment when implementing mouse/gyro based tilt
  // double _artistTiltX = 0;
  // double _artistTiltY = 0;
  // double _venueTiltX = 0;
  // double _venueTiltY = 0;

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
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1,
          speed: _random.nextDouble() * 0.3 + 0.1,
          opacity: _random.nextDouble() * 0.6 + 0.2,
          depth: _random.nextDouble(),
        ),
      );
    }
  }

  void _initAnimations() {
    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutExpo,
    );

    // Gradient orbs
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Shimmer effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Card floating
    _cardFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _cardFloatAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _cardFloatController, curve: Curves.easeInOut),
    );

    // Text reveal
    _textRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _textRevealAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textRevealController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start entrance animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _textRevealController.forward();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _fadeController.dispose();
    _orbController.dispose();
    _shimmerController.dispose();
    _cardFloatController.dispose();
    _textRevealController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _navigateToArtistSignup() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const ArtistSignupScreenV2(),
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
  }

  void _navigateToVenueSignup() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const VenueSignupScreenV2(),
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
  }

  void _navigateToLogin() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // PopScope to handle back button - this is the entry point, show exit confirmation
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Show exit confirmation dialog
        _showExitConfirmation(context, brightness);
      },
      child: Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: Stack(
          children: [
            // Layer 1: Animated particle starfield
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

            // Layer 2: Morphing gradient orbs
            AnimatedBuilder(
              animation: _orbController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GradientOrbPainter(
                    progress: _orbController.value,
                    isDark: isDark,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Layer 3: Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // Premium Logo with shimmer
                      _buildShimmerLogo(brightness),

                      const SizedBox(height: 32),

                      // Character reveal title
                      _buildRevealTitle(brightness),

                      const SizedBox(height: 8),

                      // Subtitle with fade
                      _buildSubtitle(brightness),

                      const SizedBox(height: 24),

                      // Role Cards
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Artist Card
                            _buildRoleCard(
                              icon: Icons.music_note_rounded,
                              title: 'Artist / Band',
                              subtitle: 'Find gigs & get booked',
                              features: [
                                'Create your portfolio',
                                'Get discovered by venues',
                                'Accept bookings',
                              ],
                              accentColor: AppColors.crimson,
                              isHovered: _artistCardHovered,
                              onHover: (hovering) {
                                setState(() => _artistCardHovered = hovering);
                                if (hovering) HapticFeedback.selectionClick();
                              },
                              onTap: _navigateToArtistSignup,
                              brightness: brightness,
                            ),

                            const SizedBox(height: 12),

                            // Venue Card
                            _buildRoleCard(
                              icon: Icons.storefront_rounded,
                              title: 'Venue / Host',
                              subtitle: 'Book talent for your stage',
                              features: [
                                'Browse local talent',
                                'Send booking requests',
                                'Manage your events',
                              ],
                              accentColor: const Color(0xFF3B82F6),
                              isHovered: _venueCardHovered,
                              onHover: (hovering) {
                                setState(() => _venueCardHovered = hovering);
                                if (hovering) HapticFeedback.selectionClick();
                              },
                              onTap: _navigateToVenueSignup,
                              brightness: brightness,
                            ),
                          ],
                        ),
                      ),

                      // Login link with shimmer
                      _buildLoginLink(brightness),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context, Brightness brightness) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Exit App?',
          style: TextStyle(color: AppColors.text(brightness)),
        ),
        content: Text(
          'Are you sure you want to exit?',
          style: TextStyle(color: AppColors.textSec(brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Actually exit the app
              SystemNavigator.pop();
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: AppColors.crimson),
            ),
          ),
        ],
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════════════════════
  // SHIMMER LOGO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLogo(Brightness brightness) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.text(brightness),
                AppColors.crimson,
                AppColors.text(brightness),
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.equalizer_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Text(
                'GigMatch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHARACTER REVEAL TITLE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRevealTitle(Brightness brightness) {
    const title1 = 'Welcome ';
    const title2 = 'to the stage';

    return AnimatedBuilder(
      animation: _textRevealAnimation,
      builder: (context, _) {
        final totalChars = title1.length + title2.length;
        final visibleChars = (totalChars * _textRevealAnimation.value).floor();

        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1.15,
              fontStyle: FontStyle.italic,
            ),
            children: [
              // "Welcome " in crimson
              TextSpan(
                text: title1.substring(0, visibleChars.clamp(0, title1.length)),
                style: TextStyle(color: AppColors.crimson),
              ),
              // "to the stage" in text color
              if (visibleChars > title1.length)
                TextSpan(
                  text: title2.substring(
                    0,
                    (visibleChars - title1.length).clamp(0, title2.length),
                  ),
                  style: TextStyle(color: AppColors.text(brightness)),
                ),
              // Blinking cursor
              if (_textRevealAnimation.value < 1.0)
                TextSpan(
                  text: '|',
                  style: TextStyle(
                    color: AppColors.crimson.withValues(
                      alpha:
                          (math.sin(_particleController.value * math.pi * 4) +
                              1) /
                          2,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBTITLE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSubtitle(Brightness brightness) {
    return AnimatedBuilder(
      animation: _textRevealAnimation,
      builder: (context, _) {
        return Opacity(
          opacity: ((_textRevealAnimation.value - 0.5) * 2).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              0,
              (1 - _textRevealAnimation.value.clamp(0.5, 1.0)) * 20,
            ),
            child: Text(
              'Select your role to get started',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 17,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE CARD WITH FEATURES (Clean Design)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> features,
    required Color accentColor,
    required bool isHovered,
    required Function(bool) onHover,
    required VoidCallback onTap,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _cardFloatAnimation,
      builder: (context, _) {
        return GestureDetector(
          onTapDown: (_) => onHover(true),
          onTapUp: (_) => onHover(false),
          onTapCancel: () => onHover(false),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(
              0,
              isHovered ? -4 : _cardFloatAnimation.value * 0.5,
              0,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.graphite : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isHovered
                      ? accentColor
                      : isDark
                      ? AppColors.slate
                      : Colors.grey[300]!,
                  width: isHovered ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHovered
                        ? accentColor.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: isHovered ? 30 : 15,
                    spreadRadius: isHovered ? 2 : 0,
                    offset: Offset(0, isHovered ? 10 : 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),

                  const SizedBox(width: 14),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Subtitle
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.textSec(brightness),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Feature bullets
                        ...features.map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: accentColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      color: AppColors.textSec(brightness),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(
                      isHovered ? 4 : 0,
                      0,
                      0,
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isHovered
                            ? accentColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: isHovered
                            ? accentColor
                            : AppColors.textTert(brightness),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIN LINK
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoginLink(Brightness brightness) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, _) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: _navigateToLogin,
                child: AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, _) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            AppColors.text(brightness),
                            AppColors.crimson,
                            AppColors.text(brightness),
                          ],
                          stops: [
                            (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                            _shimmerAnimation.value.clamp(0.0, 1.0),
                            (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARTICLE CLASS
// ═══════════════════════════════════════════════════════════════════════════════

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double depth;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.depth,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARTICLE FIELD PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _ParticleFieldPainter extends CustomPainter {
  final List<_Particle> particles;
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
      // Move particles upward
      final y = (particle.y - progress * particle.speed) % 1.0;

      // Parallax effect based on depth
      final parallaxOffset =
          math.sin(progress * math.pi * 2) * 20 * particle.depth;
      final x = (particle.x * size.width + parallaxOffset) % size.width;

      // Twinkle effect
      final twinkle =
          0.5 + 0.5 * math.sin(progress * math.pi * 4 + particle.x * 10);

      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity * twinkle * 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y * size.height),
        particle.size * (0.5 + particle.depth * 0.5),
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
    // Crimson orb (top-right)
    final orb1X = size.width * 0.8 + math.cos(progress * math.pi * 2) * 50;
    final orb1Y = size.height * 0.2 + math.sin(progress * math.pi * 2) * 30;

    final orb1Paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.crimson.withValues(alpha: 0.25),
              AppColors.crimson.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(orb1X, orb1Y), radius: 180),
          );

    canvas.drawCircle(Offset(orb1X, orb1Y), 180, orb1Paint);

    // Blue orb (bottom-left)
    final orb2X = size.width * 0.2 + math.sin(progress * math.pi * 2) * 40;
    final orb2Y = size.height * 0.7 + math.cos(progress * math.pi * 2) * 50;

    final orb2Paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.blueAccent.withValues(alpha: 0.15),
              Colors.blueAccent.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(orb2X, orb2Y), radius: 150),
          );

    canvas.drawCircle(Offset(orb2X, orb2Y), 150, orb2Paint);

    // Purple orb (center, slower)
    final orb3X = size.width * 0.5 + math.cos(progress * math.pi) * 30;
    final orb3Y = size.height * 0.5 + math.sin(progress * math.pi) * 40;

    final orb3Paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.purple.withValues(alpha: 0.1),
              Colors.purple.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(orb3X, orb3Y), radius: 200),
          );

    canvas.drawCircle(Offset(orb3X, orb3Y), 200, orb3Paint);
  }

  @override
  bool shouldRepaint(covariant _GradientOrbPainter oldDelegate) => true;
}
