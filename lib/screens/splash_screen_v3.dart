/// 🌟 GIGMATCH ULTRA-PREMIUM SPLASH SCREEN V3
///
/// 2026 Cutting-Edge Design Features:
/// - Particle starfield with parallax depth
/// - 3D Logo rotation with perspective
/// - Morphing gradient mesh background
/// - Character-by-character text reveal
/// - Liquid metal shimmer effects
/// - Haptic feedback integration
/// - Cinematic fade transitions
///
/// A truly immersive first impression
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import 'onboarding_screen_v3.dart';
import 'app_shell.dart';
import 'artist/artist_profile_setup_screen.dart';
import 'venue/venue_profile_setup_screen.dart';

class SplashScreenV3 extends StatefulWidget {
  const SplashScreenV3({super.key});

  @override
  State<SplashScreenV3> createState() => _SplashScreenV3State();
}

class _SplashScreenV3State extends State<SplashScreenV3>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _particleController;
  late AnimationController _logoController;
  late AnimationController _logo3DController;
  late AnimationController _textController;
  late AnimationController _shimmerController;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logo3DRotation;
  late Animation<double> _textReveal;
  late Animation<double> _shimmerPosition;

  // State
  bool _disposed = false;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initParticles() {
    // Create 60 particles with varying properties
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.3 + 0.1,
        opacity: _random.nextDouble() * 0.6 + 0.2,
        depth: _random.nextDouble(), // For parallax
      ));
    }
  }

  void _initAnimations() {
    // Particle floating animation (continuous)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Logo entrance with bounce
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
    ]).animate(_logoController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // 3D Logo rotation (subtle continuous)
    _logo3DController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _logo3DRotation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _logo3DController, curve: Curves.easeInOut),
    );

    // Text character reveal
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Shimmer effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shimmerPosition = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Pulse glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  void _startAnimationSequence() async {
    // Haptic on start
    HapticFeedback.lightImpact();

    // Phase 1: Logo appears
    await Future.delayed(const Duration(milliseconds: 300));
    if (_disposed) return;
    _logoController.forward();

    // Phase 2: Text reveals
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_disposed) return;
    HapticFeedback.selectionClick();
    _textController.forward();

    // Phase 3: Wait for auth and navigate
    await _waitForAuthAndNavigate();
  }

  Future<void> _waitForAuthAndNavigate() async {
    final authProvider = context.read<AuthProvider>();

    const minSplashDuration = Duration(milliseconds: 1000);
    final startTime = DateTime.now();

    // Wait for auth
    int attempts = 0;
    while (authProvider.status == AuthStatus.initial ||
        authProvider.status == AuthStatus.loading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_disposed) return;
      attempts++;
      if (attempts >= 100) break;
    }

    // Ensure minimum splash time
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (_disposed) return;
    if (mounted) {
      HapticFeedback.mediumImpact();
      _navigateBasedOnAuthState();
    }
  }

  void _navigateBasedOnAuthState() {
    final authProvider = context.read<AuthProvider>();
    Widget destination;

    switch (authProvider.status) {
      case AuthStatus.authenticated:
        destination = const AppShell();
        break;
      case AuthStatus.profileIncomplete:
        destination = authProvider.isArtist
            ? const ArtistProfileSetupScreen()
            : const VenueProfileSetupScreen();
        break;
      default:
        destination = const OnboardingScreenV3();
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
    _particleController.dispose();
    _logoController.dispose();
    _logo3DController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Stack(
        children: [
          // Layer 1: Morphing gradient mesh
          _buildGradientMesh(brightness, size),

          // Layer 2: Particle starfield
          _buildParticleField(brightness, size),

          // Layer 3: Central glow
          _buildCentralGlow(brightness),

          // Layer 4: Wave overlay
          _buildWaveOverlay(brightness, size),

          // Layer 5: Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // 3D Animated Logo
                  _build3DLogo(brightness),

                  const SizedBox(height: 48),

                  // Animated brand text
                  _buildAnimatedBrandText(brightness),

                  const SizedBox(height: 16),

                  // Tagline with shimmer
                  _buildShimmerTagline(brightness),

                  const Spacer(flex: 3),

                  // Premium loading indicator
                  _buildPremiumLoader(brightness),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientMesh(Brightness brightness, Size size) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientMeshPainter(
            brightness: brightness,
            animationValue: _waveController.value,
          ),
          size: size,
        );
      },
    );
  }

  Widget _buildParticleField(Brightness brightness, Size size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticleFieldPainter(
            particles: _particles,
            animationValue: _particleController.value,
            brightness: brightness,
          ),
          size: size,
        );
      },
    );
  }

  Widget _buildCentralGlow(Brightness brightness) {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        final intensity = _logoOpacity.value * (0.6 + 0.4 * _pulseController.value);
        return Center(
          child: Transform.translate(
            offset: const Offset(0, -40),
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.crimson.withValues(alpha: 0.4 * intensity),
                    AppColors.rose.withValues(alpha: 0.15 * intensity),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveOverlay(Brightness brightness, Size size) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: _WaveOverlayPainter(
            animationValue: _waveController.value,
            brightness: brightness,
          ),
          size: size,
        );
      },
    );
  }

  Widget _build3DLogo(Brightness brightness) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _logo3DController,
        _pulseController,
      ]),
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(_logo3DRotation.value)
            ..rotateX(_logo3DRotation.value * 0.5),
          child: Transform.scale(
            scale: _logoScale.value,
            child: Opacity(
              opacity: _logoOpacity.value,
              child: _buildLogoContent(brightness),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoContent(Brightness brightness) {
    final pulseValue = 0.95 + 0.05 * _pulseController.value;

    return Transform.scale(
      scale: pulseValue,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(44),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF3366),
              AppColors.crimson,
              Color(0xFFCC2952),
            ],
          ),
          boxShadow: [
            // Outer glow
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.5 * pulseValue),
              blurRadius: 50,
              spreadRadius: 10,
            ),
            // Bottom shadow for 3D effect
            BoxShadow(
              color: const Color(0xFF800020).withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glass highlight
            Positioned(
              top: 8,
              left: 12,
              right: 40,
              child: Container(
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Main "G" letter with gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFEEEEEE)],
              ).createShader(bounds),
              child: const Text(
                'G',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Color(0x40000000),
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

            // Music note with subtle animation
            Positioned(
              right: 20,
              bottom: 25,
              child: Icon(
                Icons.music_note_rounded,
                size: 32,
                color: Colors.white.withValues(alpha: 0.9),
                shadows: const [
                  Shadow(
                    color: Color(0x40000000),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBrandText(Brightness brightness) {
    const text = 'GIGMATCH';

    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(text.length, (index) {
            final charDelay = index / text.length;
            final charProgress = ((_textReveal.value - charDelay) * 2).clamp(0.0, 1.0);
            final yOffset = 30 * (1 - Curves.easeOutBack.transform(charProgress));
            final opacity = charProgress;

            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Opacity(
                opacity: opacity,
                child: Text(
                  text[index],
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                    color: AppColors.text(brightness),
                    shadows: [
                      Shadow(
                        color: AppColors.crimson.withValues(alpha: 0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildShimmerTagline(Brightness brightness) {
    return AnimatedBuilder(
      animation: Listenable.merge([_textController, _shimmerController]),
      builder: (context, child) {
        final showTagline = _textController.value > 0.6;
        if (!showTagline) return const SizedBox(height: 20);

        final taglineOpacity = ((_textController.value - 0.6) / 0.4).clamp(0.0, 1.0);

        return Opacity(
          opacity: taglineOpacity,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.textSec(brightness),
                  Colors.white,
                  AppColors.textSec(brightness),
                ],
                stops: [
                  (_shimmerPosition.value - 0.3).clamp(0.0, 1.0),
                  _shimmerPosition.value.clamp(0.0, 1.0),
                  (_shimmerPosition.value + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            child: Text(
              'Where Artists Meet Stages',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: AppColors.textSec(brightness),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumLoader(Brightness brightness) {
    return AnimatedBuilder(
      animation: Listenable.merge([_textController, _pulseController]),
      builder: (context, child) {
        final showLoader = _textController.value > 0.8;
        if (!showLoader) return const SizedBox(height: 24);

        return Opacity(
          opacity: ((_textController.value - 0.8) / 0.2).clamp(0.0, 1.0),
          child: SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: AppColors.surface(brightness),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.crimson.withValues(
                    alpha: 0.7 + 0.3 * _pulseController.value,
                  ),
                ),
                minHeight: 3,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _Particle {
  double x, y, size, speed, opacity, depth;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.depth,
  });
}

class _ParticleFieldPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final Brightness brightness;

  _ParticleFieldPainter({
    required this.particles,
    required this.animationValue,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final baseColor = brightness == Brightness.dark
        ? Colors.white
        : AppColors.crimson;

    for (final particle in particles) {
      // Parallax effect based on depth
      final parallaxOffset = animationValue * particle.speed * particle.depth;
      final x = (particle.x + parallaxOffset) % 1.0 * size.width;
      final y = (particle.y + animationValue * particle.speed) % 1.0 * size.height;

      // Twinkling effect
      final twinkle = 0.5 + 0.5 * math.sin(animationValue * math.pi * 4 + particle.x * 10);
      
      paint.color = baseColor.withValues(alpha: particle.opacity * twinkle * 0.6);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (0.8 + 0.4 * particle.depth),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

class _GradientMeshPainter extends CustomPainter {
  final Brightness brightness;
  final double animationValue;

  _GradientMeshPainter({
    required this.brightness,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgColor = AppColors.background(brightness);
    final accentColor = brightness == Brightness.dark
        ? AppColors.wine.withValues(alpha: 0.3)
        : AppColors.crimson.withValues(alpha: 0.08);

    // Animated gradient center
    final centerX = size.width * (0.4 + 0.2 * math.sin(animationValue * math.pi * 2));
    final centerY = size.height * (0.3 + 0.1 * math.cos(animationValue * math.pi * 2));

    final gradient = RadialGradient(
      center: Alignment(
        (centerX / size.width) * 2 - 1,
        (centerY / size.height) * 2 - 1,
      ),
      radius: 1.5,
      colors: [accentColor, bgColor],
    );

    final paint = Paint()..shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _GradientMeshPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

class _WaveOverlayPainter extends CustomPainter {
  final double animationValue;
  final Brightness brightness;

  _WaveOverlayPainter({
    required this.animationValue,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final waveColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.03)
        : AppColors.crimson.withValues(alpha: 0.03);

    // Draw subtle waves
    for (int i = 0; i < 3; i++) {
      paint.color = waveColor.withValues(alpha: waveColor.a * (1 - i * 0.3));
      
      final path = Path();
      final waveHeight = 30.0 + i * 20;
      final offset = animationValue * size.width + i * 100;

      path.moveTo(0, size.height * 0.7);
      
      for (double x = 0; x <= size.width; x += 10) {
        final y = size.height * 0.7 +
            math.sin((x + offset) / 100) * waveHeight +
            math.cos((x + offset) / 150) * waveHeight * 0.5;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveOverlayPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
