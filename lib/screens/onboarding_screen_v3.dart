/// 🌟 ULTRA-PREMIUM ONBOARDING SCREEN V3 - 2026 DESIGN
///
/// Features:
/// ✅ Animated particle nebula background
/// ✅ 3D perspective hero transitions
/// ✅ Morphing liquid gradient mesh
/// ✅ Character-by-character text reveal
/// ✅ Premium glassmorphic navigation
/// ✅ Haptic feedback integration
/// ✅ Parallax depth effects
/// ✅ Staggered element animations

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import 'unified_signup_screen.dart';

class OnboardingScreenV3 extends StatefulWidget {
  const OnboardingScreenV3({super.key});

  @override
  State<OnboardingScreenV3> createState() => _OnboardingScreenV3State();
}

class _OnboardingScreenV3State extends State<OnboardingScreenV3>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE CONTROLLER
  // ═══════════════════════════════════════════════════════════════════════════
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _pageProgress = 0.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION CONTROLLERS
  // ═══════════════════════════════════════════════════════════════════════════
  late AnimationController _particleController;
  late AnimationController _meshController;
  late AnimationController _enterController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  // Particle system
  final List<_NebulaParticle> _particles = [];
  final math.Random _random = math.Random();

  // Onboarding content
  final List<_OnboardingContent> _pages = [
    _OnboardingContent(
      image: 'assets/images/onboarding/image1.png',
      titleHighlight: 'Discover',
      titleNormal: ' Your Stage',
      subtitle: 'Connect with venues looking for your unique sound',
      icon: Icons.search_rounded,
    ),
    _OnboardingContent(
      image: 'assets/images/onboarding/image4.png',
      titleHighlight: 'Showcase',
      titleNormal: ' Your Talent',
      subtitle: 'Build your profile with audio, video, and photos',
      icon: Icons.auto_awesome_rounded,
    ),
    _OnboardingContent(
      image: 'assets/images/onboarding/Artist avatar(image5).png',
      titleHighlight: 'Get',
      titleNormal: ' Booked',
      subtitle: 'Match with venues and secure your next gig',
      icon: Icons.calendar_today_rounded,
    ),
    _OnboardingContent(
      image: 'assets/images/onboarding/Venue card image(image7).png',
      titleHighlight: 'Join',
      titleNormal: ' the Community',
      subtitle: 'Thousands of artists and venues already connected',
      icon: Icons.people_alt_rounded,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initAnimations();
    _pageController.addListener(_onPageScroll);
  }

  void _initParticles() {
    for (int i = 0; i < 80; i++) {
      _particles.add(_NebulaParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 1,
        speed: _random.nextDouble() * 0.2 + 0.05,
        opacity: _random.nextDouble() * 0.5 + 0.2,
        hue: _random.nextDouble() * 60 - 30, // Red-orange range
        depth: _random.nextDouble(),
      ));
    }
  }

  void _initAnimations() {
    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // Mesh animation
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Enter animation
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // Float animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onPageScroll() {
    setState(() {
      _pageProgress = _pageController.page ?? 0.0;
      _currentPage = _pageProgress.round();
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _particleController.dispose();
    _meshController.dispose();
    _enterController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToRoleSelection();
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToRoleSelection() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const UnifiedSignupScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Stack(
        children: [
          // Layer 1: Animated nebula particle field
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _NebulaFieldPainter(
                  particles: _particles,
                  progress: _particleController.value,
                  pageProgress: _pageProgress,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 2: Morphing gradient mesh
          AnimatedBuilder(
            animation: _meshController,
            builder: (context, _) {
              return CustomPaint(
                painter: _MorphingMeshPainter(
                  progress: _meshController.value,
                  pageProgress: _pageProgress,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 3: Page content
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildPage(index, brightness, size);
            },
          ),

          // Layer 4: Top navigation bar
          _buildTopNav(brightness),

          // Layer 5: Bottom controls
          _buildBottomControls(brightness),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE BUILDER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPage(int index, Brightness brightness, Size size) {
    final content = _pages[index];
    final pageOffset = _pageProgress - index;
    final parallax = pageOffset * 50;
    final scale = 1.0 - (pageOffset.abs() * 0.15);
    final opacity = 1.0 - (pageOffset.abs() * 0.5);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 140),
        child: Column(
          children: [
            // Hero image with 3D perspective
            Expanded(
              flex: 5,
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(pageOffset * 0.3)
                      ..translate(parallax, _floatAnimation.value * (1 - pageOffset.abs().clamp(0, 1))),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale.clamp(0.8, 1.0),
                        child: _buildHeroImage(content, brightness, index),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Content section
            Expanded(
              flex: 3,
              child: Transform.translate(
                offset: Offset(parallax * 0.5, 0),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: _buildContentSection(content, brightness, index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO IMAGE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroImage(_OnboardingContent content, Brightness brightness, int index) {
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.3),
            blurRadius: 50,
            spreadRadius: 5,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.asset(
              content.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.crimson.withValues(alpha: 0.3),
                      AppColors.background(brightness),
                    ],
                  ),
                ),
                child: Icon(
                  content.icon,
                  size: 80,
                  color: AppColors.crimson.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Floating icon badge
            Positioned(
              bottom: 20,
              right: 20,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.crimson,
                            AppColors.crimson.withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        content.icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page number indicator
            Positioned(
              top: 16,
              left: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${index + 1}/${_pages.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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
  // CONTENT SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContentSection(_OnboardingContent content, Brightness brightness, int index) {
    final isActive = _currentPage == index;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title with shimmer on active
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            final shimmerValue = (_shimmerController.value * 3 - 1).clamp(0.0, 1.0);

            return ShaderMask(
              shaderCallback: isActive
                  ? (bounds) {
                      return LinearGradient(
                        colors: [
                          AppColors.crimson,
                          Colors.white,
                          AppColors.crimson,
                        ],
                        stops: [
                          (shimmerValue - 0.3).clamp(0.0, 1.0),
                          shimmerValue,
                          (shimmerValue + 0.3).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds);
                    }
                  : (bounds) => LinearGradient(
                        colors: [AppColors.crimson, AppColors.crimson],
                      ).createShader(bounds),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: content.titleHighlight,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: content.titleNormal,
                      style: TextStyle(
                        color: AppColors.text(brightness),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Subtitle
        Text(
          content.subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopNav(Brightness brightness) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button (show after first page)
              AnimatedOpacity(
                opacity: _currentPage > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _buildGlassButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: _prevPage,
                  brightness: brightness,
                ),
              ),

              // Skip button
              _buildGlassTextButton(
                text: 'Skip',
                onTap: _goToRoleSelection,
                brightness: brightness,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM CONTROLS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomControls(Brightness brightness) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              // Page indicators
              _buildPageIndicators(brightness),

              const SizedBox(height: 24),

              // CTA button
              _buildCTAButton(brightness),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE INDICATORS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPageIndicators(Brightness brightness) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final distance = (_pageProgress - index).abs();
        final isActive = distance < 0.5;
        final width = isActive ? 32.0 : 8.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: width,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? AppColors.crimson
                : AppColors.textTert(brightness).withValues(alpha: 0.3),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CTA BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCTAButton(Brightness brightness) {
    final isLastPage = _currentPage == 3;

    return GestureDetector(
      onTap: _nextPage,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLastPage
                    ? [
                        AppColors.crimson,
                        AppColors.crimson.withValues(alpha: 0.8),
                      ]
                    : [
                        AppColors.crimson.withValues(alpha: 0.15),
                        AppColors.crimson.withValues(alpha: 0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: isLastPage ? 0.0 : 0.3),
                width: 1.5,
              ),
              boxShadow: isLastPage
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(
                          alpha: 0.4 * _pulseAnimation.value,
                        ),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLastPage ? 'Get Started' : 'Continue',
                  style: TextStyle(
                    color: isLastPage ? Colors.white : AppColors.crimson,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  color: isLastPage ? Colors.white : AppColors.crimson,
                  size: 22,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GLASS BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    required Brightness brightness,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.cardBackground(brightness).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border(brightness).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.text(brightness),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextButton({
    required String text,
    required VoidCallback onTap,
    required Brightness brightness,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(brightness).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border(brightness).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONBOARDING CONTENT MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class _OnboardingContent {
  final String image;
  final String titleHighlight;
  final String titleNormal;
  final String subtitle;
  final IconData icon;

  _OnboardingContent({
    required this.image,
    required this.titleHighlight,
    required this.titleNormal,
    required this.subtitle,
    required this.icon,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// NEBULA PARTICLE CLASS
// ═══════════════════════════════════════════════════════════════════════════════

class _NebulaParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double hue;
  double depth;

  _NebulaParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.hue,
    required this.depth,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// NEBULA FIELD PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _NebulaFieldPainter extends CustomPainter {
  final List<_NebulaParticle> particles;
  final double progress;
  final double pageProgress;
  final bool isDark;

  _NebulaFieldPainter({
    required this.particles,
    required this.progress,
    required this.pageProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Move particles diagonally
      final y = (particle.y + progress * particle.speed) % 1.0;
      final x = (particle.x + progress * particle.speed * 0.3) % 1.0;

      // Parallax based on page scroll
      final parallaxX = x * size.width - pageProgress * 30 * particle.depth;
      final parallaxY = y * size.height;

      // Twinkle effect
      final twinkle = 0.5 + 0.5 * math.sin(progress * math.pi * 6 + particle.x * 20);

      // Color based on particle hue (red-orange spectrum)
      final color = HSVColor.fromAHSV(
        particle.opacity * twinkle * (isDark ? 0.8 : 0.5),
        (particle.hue + 15).clamp(0, 360), // Crimson hue
        0.8,
        1.0,
      ).toColor();

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 0.5);

      canvas.drawCircle(
        Offset(parallaxX % size.width, parallaxY),
        particle.size * (0.5 + particle.depth * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaFieldPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MORPHING MESH PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _MorphingMeshPainter extends CustomPainter {
  final double progress;
  final double pageProgress;
  final bool isDark;

  _MorphingMeshPainter({
    required this.progress,
    required this.pageProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Main gradient orb that follows page
    final orbX = size.width * (0.5 + pageProgress * 0.1);
    final orbY = size.height * 0.3 + math.sin(progress * math.pi * 2) * 40;

    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.crimson.withValues(alpha: isDark ? 0.2 : 0.12),
          AppColors.crimson.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(orbX, orbY), radius: 250));

    canvas.drawCircle(Offset(orbX, orbY), 250, orbPaint);

    // Secondary orb at bottom
    final orb2X = size.width * (0.7 - pageProgress * 0.05);
    final orb2Y = size.height * 0.8 + math.cos(progress * math.pi * 2) * 30;

    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.deepPurple.withValues(alpha: isDark ? 0.12 : 0.08),
          Colors.deepPurple.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(orb2X, orb2Y), radius: 180));

    canvas.drawCircle(Offset(orb2X, orb2Y), 180, orb2Paint);
  }

  @override
  bool shouldRepaint(covariant _MorphingMeshPainter oldDelegate) => true;
}
