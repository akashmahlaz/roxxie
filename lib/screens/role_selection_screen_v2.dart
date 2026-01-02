import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../core/theme/theme.dart';
import 'login_screen.dart';
import 'artist_signup_screen.dart';
import 'venue_signup_screen.dart';

/// 🎭 ROLE SELECTION SCREEN V2
///
/// Premium redesign with glassmorphic cards and particle effects
/// "Welcome to the stage" - Choose Artist or Venue

class RoleSelectionScreenV2 extends StatefulWidget {
  const RoleSelectionScreenV2({super.key});

  @override
  State<RoleSelectionScreenV2> createState() => _RoleSelectionScreenV2State();
}

class _RoleSelectionScreenV2State extends State<RoleSelectionScreenV2>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _navigateToArtistSignup() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ArtistSignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
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
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToVenueSignup() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const VenueSignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
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
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
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
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Stack(
        children: [
          // Particle background
          _ParticleBackground(isDark: isDark),

          // Red glow at top
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.5,
                      colors: [
                        AppColors.crimson.withOpacity(
                          _glowAnimation.value * 0.3,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Horizontal light streak
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.crimson.withOpacity(0.6),
                    Colors.white.withOpacity(0.8),
                    AppColors.crimson.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.equalizer_rounded,
                          color: AppColors.crimson,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'GigMatch',
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          fontStyle: FontStyle.italic,
                        ),
                        children: [
                          TextSpan(
                            text: 'Welcome ',
                            style: TextStyle(color: AppColors.crimson),
                          ),
                          TextSpan(
                            text: 'to the stage',
                            style: TextStyle(color: AppColors.text(brightness)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Select your role to get started.',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Artist Card
                    _buildRoleCard(
                      context: context,
                      icon: Icons.headphones_rounded,
                      title: 'Artist / Band',
                      subtitle: 'Find gigs & get booked',
                      isHighlighted: true,
                      onTap: _navigateToArtistSignup,
                    ),

                    const SizedBox(height: 16),

                    // Venue Card
                    _buildRoleCard(
                      context: context,
                      icon: Icons.storefront_rounded,
                      title: 'Venue / Host',
                      subtitle: 'Book talent for your stage',
                      isHighlighted: false,
                      onTap: _navigateToVenueSignup,
                    ),

                    const Spacer(),

                    // Login link
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?  ',
                            style: TextStyle(
                              color: AppColors.textSec(brightness),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToLogin,
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                color: AppColors.text(brightness),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.text(brightness),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(brightness),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHighlighted
                    ? AppColors.crimson.withOpacity(_glowAnimation.value + 0.3)
                    : AppColors.border(brightness),
                width: isHighlighted ? 1.5 : 1,
              ),
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withOpacity(
                          _glowAnimation.value * 0.3,
                        ),
                        blurRadius: 30,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.iconSecondary(
                      brightness,
                    ).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.icon(brightness),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isHighlighted
                              ? AppColors.crimson.withOpacity(0.8)
                              : AppColors.textSec(brightness),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.crimson
                        : AppColors.iconSecondary(brightness).withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: isHighlighted
                        ? [
                            BoxShadow(
                              color: AppColors.crimson.withOpacity(0.5),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: isHighlighted
                        ? Colors.white
                        : AppColors.icon(brightness),
                    size: 22,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Particle background with floating dots
class _ParticleBackground extends StatefulWidget {
  final bool isDark;

  const _ParticleBackground({required this.isDark});

  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate particles
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(
        _Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 3 + 1,
          speed: random.nextDouble() * 0.5 + 0.2,
          opacity: random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            isDark: widget.isDark,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final bool isDark;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final color = isDark ? Colors.white : Colors.black;
      final paint = Paint()
        ..color = color.withOpacity(particle.opacity * (isDark ? 1.0 : 0.3))
        ..style = PaintingStyle.fill;

      final y = (particle.y + progress * particle.speed) % 1.0;
      final x =
          particle.x +
          math.sin(progress * math.pi * 2 + particle.y * 10) * 0.02;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
