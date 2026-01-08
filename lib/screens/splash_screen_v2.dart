import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import 'onboarding_screen_v2.dart';
import 'home_screen.dart';
import 'artist/artist_profile_setup_screen.dart';
import 'venue/venue_profile_setup_screen.dart';

/// 🌟 GIGMATCH PREMIUM SPLASH SCREEN V2
///
/// Cinematic first impression with:
/// - Custom guitar pick logo with pulse animation
/// - Refined animation choreography
/// - Premium glow effects
/// - Animated loading dots
/// - Professional typography treatment

class SplashScreenV2 extends StatefulWidget {
  const SplashScreenV2({super.key});

  @override
  State<SplashScreenV2> createState() => _SplashScreenV2State();
}

class _SplashScreenV2State extends State<SplashScreenV2>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late AnimationController _loadingController;

  // Track delayed navigation so tests don't fail with pending timers on dispose
  bool _disposed = false;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowIntensity;
  late Animation<double> _textOpacity;
  late Animation<double> _textScale;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Background fade in
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Logo entrance with bounce
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.95,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_logoController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Continuous pulse effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowIntensity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Text entrance
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _textScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Tagline entrance
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _taglineController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Loading dots
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _startAnimationSequence() async {
    // Phase 1: Background fades in
    _backgroundController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (_disposed) return;

    // Phase 2: Logo appears with bounce
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (_disposed) return;

    // Phase 3: Start pulse loop
    _pulseController.repeat(reverse: true);

    // Phase 4: Brand name appears
    await Future.delayed(const Duration(milliseconds: 300));
    if (_disposed) return;
    _textController.forward();

    // Phase 5: Tagline slides in
    await Future.delayed(const Duration(milliseconds: 400));
    if (_disposed) return;
    _taglineController.forward();

    // Phase 6: Loading starts
    await Future.delayed(const Duration(milliseconds: 200));
    if (_disposed) return;
    _loadingController.repeat();

    // Wait for auth check and navigate based on state
    await Future.delayed(const Duration(milliseconds: 2200));
    if (_disposed) return;
    if (mounted) {
      _navigateBasedOnAuthState();
    }
  }

  void _navigateBasedOnAuthState() {
    final authProvider = context.read<AuthProvider>();

    Widget destination;

    switch (authProvider.status) {
      case AuthStatus.authenticated:
        // User is logged in and profile is complete
        destination = const HomeScreen();
        break;
      case AuthStatus.profileIncomplete:
        // User is logged in but needs to complete profile
        if (authProvider.isArtist) {
          destination = const ArtistProfileSetupScreen();
        } else {
          destination = const VenueProfileSetupScreen();
        }
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.initial:
      case AuthStatus.loading:
      case AuthStatus.error:
        // Not logged in, show onboarding
        destination = const OnboardingScreenV2();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _backgroundController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Stack(
        children: [
          // Premium animated background
          _buildBackground(brightness),

          // Radial glow behind logo
          _buildRadialGlow(),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Logo
                  _buildAnimatedLogo(),

                  const SizedBox(height: 40),

                  // Brand name
                  _buildBrandName(brightness),

                  const SizedBox(height: 12),

                  // Tagline
                  _buildTagline(brightness),

                  const Spacer(flex: 3),

                  // Loading indicator
                  _buildLoadingDots(),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Brightness brightness) {
    final bgColor = AppColors.background(brightness);
    final accentColor = brightness == Brightness.dark
        ? AppColors.wine.withValues(alpha: 0.3)
        : AppColors.crimson.withValues(alpha: 0.1);

    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Opacity(
          opacity: _backgroundController.value,
          child: Stack(
            children: [
              // Base gradient
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 1.5,
                    colors: [accentColor, bgColor],
                  ),
                ),
              ),

              // Noise texture overlay (simulated with pattern)
              CustomPaint(
                painter: _NoisePainter(
                  opacity: brightness == Brightness.dark ? 0.03 : 0.02,
                ),
                size: Size.infinite,
              ),

              // Subtle vignette
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      bgColor.withValues(alpha: 0.8),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadialGlow() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        final intensity = _logoOpacity.value * _glowIntensity.value;
        return Center(
          child: Transform.translate(
            offset: const Offset(0, -60),
            child: Container(
              width: 300 * _pulseAnimation.value,
              height: 300 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.crimson.withValues(alpha: 0.4 * intensity),
                    AppColors.rose.withValues(alpha: 0.2 * intensity),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value * _pulseAnimation.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Opacity(
              opacity: _logoOpacity.value,
              child: _buildLogoWidget(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoWidget() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.crimson, AppColors.rose],
            ),
            boxShadow: [
              // Outer glow
              BoxShadow(
                color: AppColors.crimson.withValues(
                  alpha: 0.6 * _glowIntensity.value,
                ),
                blurRadius: 40,
                spreadRadius: 5,
              ),
              // Inner shadow for depth
              BoxShadow(
                color: AppColors.wine.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inner gradient overlay
              Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(37),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // "G" Monogram
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
                ).createShader(bounds),
                child: const Text(
                  'G',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),

              // Music note accent
              Positioned(
                right: 22,
                bottom: 28,
                child: Icon(
                  Icons.music_note_rounded,
                  size: 28,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandName(Brightness brightness) {
    final textColor = AppColors.text(brightness);
    final textColorSecondary = brightness == Brightness.dark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF374151);

    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Transform.scale(
          scale: _textScale.value,
          child: Opacity(
            opacity: _textOpacity.value,
            child: Column(
              children: [
                // Main brand name
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [textColor, textColorSecondary],
                  ).createShader(bounds),
                  child: Text(
                    'GIGMATCH',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: textColor,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Accent line
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Container(
                      width: 60 * _textController.value,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [AppColors.crimson, AppColors.rose],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline(Brightness brightness) {
    return AnimatedBuilder(
      animation: _taglineController,
      builder: (context, child) {
        return SlideTransition(
          position: _taglineSlide,
          child: Opacity(
            opacity: _taglineOpacity.value,
            child: Text(
              'Where Artists Meet Stages',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
                color: AppColors.textSec(brightness).withValues(alpha: 0.8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _taglineController,
      builder: (context, child) {
        return Opacity(
          opacity: _taglineOpacity.value,
          child: SizedBox(
            height: 24,
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final animValue =
                        ((_loadingController.value + delay) % 1.0);
                    final scale = 0.5 + 0.5 * math.sin(animValue * math.pi);
                    final opacity = 0.3 + 0.7 * scale;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.crimson.withValues(alpha: opacity),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.crimson.withValues(
                                  alpha: 0.3 * opacity,
                                ),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Noise texture painter for premium feel
class _NoisePainter extends CustomPainter {
  final double opacity;
  final math.Random _random = math.Random(42);

  _NoisePainter({this.opacity = 0.05});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw sparse noise dots
    for (int i = 0; i < 800; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final alpha = _random.nextDouble() * opacity;

      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
