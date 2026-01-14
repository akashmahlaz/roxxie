import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme.dart';

/// 🎉 ULTRA-PREMIUM VENUE SETUP SUCCESS SCREEN - 2026 DESIGN
///
/// Features:
/// ✅ Animated confetti particles (50+ particles)
/// ✅ 3D animated checkmark with scale/rotation
/// ✅ Shimmer text effects
/// ✅ Glassmorphic stat cards
/// ✅ Floating gradient orbs
/// ✅ Haptic feedback
/// ✅ Smooth page transitions
/// ✅ Auto-dismiss with countdown

class VenueSetupSuccessScreen extends StatefulWidget {
  final String venueName;

  const VenueSetupSuccessScreen({super.key, required this.venueName});

  @override
  State<VenueSetupSuccessScreen> createState() => _VenueSetupSuccessScreenState();
}

class _VenueSetupSuccessScreenState extends State<VenueSetupSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _checkmarkController;
  late AnimationController _contentController;
  late AnimationController _shimmerController;
  late AnimationController _orbController;

  late Animation<double> _checkmarkScale;
  late Animation<double> _checkmarkRotation;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  final List<ConfettiParticle> _particles = [];
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    
    HapticFeedback.heavyImpact();

    // Initialize particles
    _initParticles();

    // Particle animation (continuous)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Checkmark animation
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _checkmarkScale = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    );

    _checkmarkRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: Curves.easeOutBack,
      ),
    );

    // Content animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Orb animation
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      _checkmarkController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _contentController.forward();
      HapticFeedback.mediumImpact();
    });

    // Countdown timer
    _startCountdown();
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < 60; i++) {
      _particles.add(
        ConfettiParticle(
          x: random.nextDouble(),
          y: -random.nextDouble() * 0.5,
          speed: 0.3 + random.nextDouble() * 0.7,
          size: 4 + random.nextDouble() * 8,
          color: _getConfettiColor(random),
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
        ),
      );
    }
  }

  Color _getConfettiColor(math.Random random) {
    final colors = [
      AppColors.crimson,
      const Color(0xFFFF4D6D),
      const Color(0xFFFFD700),
      const Color(0xFF00D4FF),
      const Color(0xFF9D4EDD),
      const Color(0xFFFF6B9D),
    ];
    return colors[random.nextInt(colors.length)];
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      } else {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _particleController.dispose();
    _checkmarkController.dispose();
    _contentController.dispose();
    _shimmerController.dispose();
    _orbController.dispose();
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
          // Animated gradient orbs
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _SuccessOrbPainter(
                  animation: _orbController.value,
                  brightness: brightness,
                ),
              );
            },
          ),

          // Confetti particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _ConfettiPainter(
                  particles: _particles,
                  animation: _particleController.value,
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Checkmark
                    AnimatedBuilder(
                      animation: _checkmarkController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _checkmarkScale.value,
                          child: Transform.rotate(
                            angle: _checkmarkRotation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.crimson.withValues(alpha: 0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Success message with shimmer
                    FadeTransition(
                      opacity: _contentFade,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: Column(
                          children: [
                            // Title with shimmer effect
                            AnimatedBuilder(
                              animation: _shimmerController,
                              builder: (context, child) {
                                return ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: const [
                                        Colors.white,
                                        Color(0xFFFF4D6D),
                                        Colors.white,
                                      ],
                                      stops: [
                                        _shimmerController.value - 0.3,
                                        _shimmerController.value,
                                        _shimmerController.value + 0.3,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    '🎉 Welcome to GigMatch!',
                                    style: TextStyle(
                                      color: AppColors.text(brightness),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Venue name
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.crimson.withValues(alpha: 0.2),
                                    const Color(0xFFFF4D6D).withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.crimson.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                widget.venueName,
                                style: TextStyle(
                                  color: AppColors.crimson,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Description
                            Text(
                              'Your venue profile is now live!\nStart discovering talented artists ready to perform.',
                              style: TextStyle(
                                color: AppColors.textSec(brightness),
                                fontSize: 16,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 40),

                            // Stats cards
                            _buildStatsCards(brightness),

                            const SizedBox(height: 40),

                            // Action buttons
                            _buildActionButtons(brightness),

                            const SizedBox(height: 24),

                            // Auto-dismiss countdown
                            Text(
                              'Redirecting in $_countdown seconds...',
                              style: TextStyle(
                                color: AppColors.textSec(brightness),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildStatsCards(Brightness brightness) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.music_note_rounded,
            label: 'Artists\nWaiting',
            value: '1,200+',
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            label: 'Average\nRating',
            value: '4.8',
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.groups_rounded,
            label: 'Active\nVenues',
            value: '5,000+',
            brightness: brightness,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Brightness brightness,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border(brightness).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppColors.crimson,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 11,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Brightness brightness) {
    return Column(
      children: [
        // Primary CTA
        SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.mediumImpact();
                _navigateToHome();
              },
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Start Discovering Artists',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary action
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushReplacementNamed(context, '/profile');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'View My Profile',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Confetti particle data
class ConfettiParticle {
  double x;
  double y;
  final double speed;
  final double size;
  final Color color;
  double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

// Confetti painter
class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animation;

  _ConfettiPainter({required this.particles, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Update particle position
      final currentY = particle.y + (animation * particle.speed);
      final wrappedY = currentY % 1.2;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        particle.x * size.width,
        wrappedY * size.height,
      );
      canvas.rotate(particle.rotation + animation * particle.rotationSpeed * 10);

      // Draw particle as rotated rectangle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          Radius.circular(particle.size * 0.2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

// Success orb painter
class _SuccessOrbPainter extends CustomPainter {
  final double animation;
  final Brightness brightness;

  _SuccessOrbPainter({required this.animation, required this.brightness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Orb 1
    final orb1Offset = Offset(
      size.width * 0.2 + math.sin(animation * math.pi * 2) * 30,
      size.height * 0.3 + math.cos(animation * math.pi * 2) * 40,
    );
    paint.color = AppColors.crimson.withValues(alpha: 0.15);
    canvas.drawCircle(orb1Offset, 80, paint);

    // Orb 2
    final orb2Offset = Offset(
      size.width * 0.8 + math.cos(animation * math.pi * 2 + 1) * 40,
      size.height * 0.7 + math.sin(animation * math.pi * 2 + 1) * 30,
    );
    paint.color = const Color(0xFFFF4D6D).withValues(alpha: 0.15);
    canvas.drawCircle(orb2Offset, 100, paint);

    // Orb 3
    final orb3Offset = Offset(
      size.width * 0.5 + math.sin(animation * math.pi * 2 + 2) * 50,
      size.height * 0.5 + math.cos(animation * math.pi * 2 + 2) * 50,
    );
    paint.color = const Color(0xFF9D4EDD).withValues(alpha: 0.1);
    canvas.drawCircle(orb3Offset, 70, paint);
  }

  @override
  bool shouldRepaint(_SuccessOrbPainter oldDelegate) => true;
}
