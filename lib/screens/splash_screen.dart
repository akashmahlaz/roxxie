/// 🌟 GIGMATCH PROFESSIONAL SPLASH SCREEN
///
/// Clean, modern, and professional design featuring:
/// - Subtle gradient background
/// - Smooth logo reveal animation
/// - Clean typography
/// - Elegant loading indicator
/// - Fast and smooth transitions
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/api/api_client.dart';
import 'onboarding_screen.dart';
import 'role_selection_screen_v3.dart';
import 'app_shell.dart';
import 'artist/artist_profile_setup_screen.dart';
import 'venue/venue_profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _loadingController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    // Main entrance animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Subtle pulse for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Loading spinner
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Logo animations
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Brand text animations
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    // Tagline animation
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );
  }

  void _startSequence() async {
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 100));
    if (_disposed) return;

    _mainController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (_disposed) return;

    await _waitForAuthAndNavigate();
  }

  Future<void> _waitForAuthAndNavigate() async {
    final authProvider = context.read<AuthProvider>();

    const minSplashDuration = Duration(milliseconds: 1200);
    final startTime = DateTime.now();

    // Wait for auth to initialize
    int attempts = 0;
    while (authProvider.status == AuthStatus.initial ||
        authProvider.status == AuthStatus.loading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_disposed) return;
      attempts++;
      if (attempts >= 50) break; // 5 second timeout
    }

    // Ensure minimum splash display time
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

  void _navigateBasedOnAuthState() async {
    final authProvider = context.read<AuthProvider>();
    Widget destination;

    switch (authProvider.status) {
      case AuthStatus.authenticated:
        destination = const AppShell();
        break;
      case AuthStatus.profileIncomplete:
      case AuthStatus.needsRoleSelection:
        destination = authProvider.isArtist
            ? const ArtistProfileSetupScreen()
            : const VenueProfileSetupScreen();
        break;
      default:
        // Check if user has seen onboarding before
        final apiClient = ApiClient();
        final hasSeenOnboarding = await apiClient.getHasSeenOnboarding();
        destination = hasSeenOnboarding
            ? const RoleSelectionScreenV3()
            : const OnboardingScreen();
    }

    if (!mounted) return;
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
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _mainController.dispose();
    _pulseController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: Stack(
        children: [
          // Subtle gradient background
          _buildBackground(isDark, size),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Logo
                  _buildLogo(isDark),

                  const SizedBox(height: 32),

                  // Brand name
                  _buildBrandName(brightness),

                  const SizedBox(height: 12),

                  // Tagline
                  _buildTagline(brightness),

                  const Spacer(flex: 3),

                  // Loading indicator
                  _buildLoadingIndicator(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark, Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.2,
          colors: isDark
              ? [const Color(0xFF1A0A10), const Color(0xFF0A0A0A)]
              : [const Color(0xFFFFF5F7), Colors.white],
        ),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = 0.3 + 0.15 * _pulseController.value;
          return CustomPaint(
            painter: _SubtleGlowPainter(
              color: AppColors.crimson,
              opacity: pulseValue,
              isDark: isDark,
            ),
            size: size,
          );
        },
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _pulseController]),
      builder: (context, child) {
        final pulse = 1.0 + 0.02 * _pulseController.value;
        return Transform.scale(
          scale: _logoScale.value * pulse,
          child: Opacity(
            opacity: _logoOpacity.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF4466),
                    AppColors.crimson,
                    Color(0xFFCC2244),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(
                      alpha: isDark ? 0.5 : 0.35,
                    ),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.2),
                    blurRadius: 80,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glass highlight
                  Positioned(
                    top: 6,
                    left: 10,
                    right: 30,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // G Letter
                  const Text(
                    'G',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  // Music pin indicator
                  Positioned(
                    right: 16,
                    bottom: 18,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildBrandName(Brightness brightness) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlide,
          child: Opacity(
            opacity: _textOpacity.value,
            child: Text(
              'GigMatch',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.text(brightness),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline(Brightness brightness) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Opacity(
          opacity: _taglineOpacity.value,
          child: Text(
            'Where Artists Meet Stages',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSec(brightness),
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return SizedBox(
          width: 32,
          height: 32,
          child: CustomPaint(
            painter: _LoadingPainter(
              progress: _loadingController.value,
              color: AppColors.crimson,
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

class _SubtleGlowPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final bool isDark;

  _SubtleGlowPainter({
    required this.color,
    required this.opacity,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);
    final radius = size.width * 0.8;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity * (isDark ? 0.15 : 0.08)),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SubtleGlowPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

class _LoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _LoadingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Animated arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const sweepAngle = math.pi * 0.8;
    final startAngle = progress * math.pi * 2 - math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
