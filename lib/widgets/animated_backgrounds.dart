import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 🌈 ANIMATED GRADIENT BACKGROUND
///
/// Creates a beautiful animated mesh gradient background
/// that subtly shifts and moves - signature of premium apps
///
/// RED & WHITE Theme: Uses crimson and rose gradients
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     const AnimatedGradientBackground(),
///     // Your content here
///   ],
/// )
/// ```

class AnimatedGradientBackground extends StatefulWidget {
  final List<Color>? colors;
  final Duration duration;
  final double opacity;

  const AnimatedGradientBackground({
    super.key,
    this.colors,
    this.duration = const Duration(seconds: 8),
    this.opacity = 0.6,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topRight, end: Alignment.centerRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.centerRight, end: Alignment.topLeft),
        weight: 1,
      ),
    ]).animate(_controller);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomLeft, end: Alignment.centerLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.centerLeft, end: Alignment.bottomRight),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RED & WHITE theme colors
    final colors =
        widget.colors ?? [AppColors.crimson, AppColors.rose, AppColors.wine];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _topAlignmentAnimation.value,
              end: _bottomAlignmentAnimation.value,
              colors: [
                colors[0].withValues(alpha: widget.opacity),
                AppColors.obsidian,
                colors[1].withValues(alpha: widget.opacity * 0.7),
                AppColors.obsidian,
                colors[2].withValues(alpha: widget.opacity * 0.5),
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 🌟 AURORA BACKGROUND
///
/// Creates a beautiful aurora effect with RED theme

class AuroraBackground extends StatefulWidget {
  final Widget? child;

  const AuroraBackground({super.key, this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.obsidian,
      child: Stack(
        children: [
          // First blob - CRIMSON
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Positioned(
                top: -100 + (50 * _controller1.value),
                left: -50 + (100 * _controller1.value),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.crimson.withValues(alpha: 0.4),
                        AppColors.crimson.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Second blob - ROSE
          AnimatedBuilder(
            animation: _controller2,
            builder: (context, child) {
              return Positioned(
                top: 200 + (80 * _controller2.value),
                right: -100 + (120 * _controller2.value),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.rose.withValues(alpha: 0.35),
                        AppColors.rose.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Third blob - WINE (subtle)
          AnimatedBuilder(
            animation: _controller3,
            builder: (context, child) {
              return Positioned(
                bottom: -100 + (60 * _controller3.value),
                left: 100 - (80 * _controller3.value),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.wine.withValues(alpha: 0.3),
                        AppColors.wine.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Content
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

/// 🎆 PARTICLES BACKGROUND
///
/// Floating particles effect for special screens - RED themed

class ParticlesBackground extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double maxParticleSize;
  final Widget? child;

  const ParticlesBackground({
    super.key,
    this.particleCount = 50,
    this.particleColor = AppColors.crimson,
    this.maxParticleSize = 4,
    this.child,
  });

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (index) => _Particle.random(widget.maxParticleSize),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.obsidian,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlesPainter(
                  particles: _particles,
                  animation: _controller.value,
                  color: widget.particleColor,
                ),
                size: Size.infinite,
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
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

  factory _Particle.random(double maxSize) {
    return _Particle(
      x: _random(),
      y: _random(),
      size: 1 + _random() * maxSize,
      speed: 0.2 + _random() * 0.8,
      opacity: 0.2 + _random() * 0.6,
    );
  }

  static double _random() {
    return (DateTime.now().microsecondsSinceEpoch % 1000) / 1000.0;
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animation;
  final Color color;

  _ParticlesPainter({
    required this.particles,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final y = (particle.y + animation * particle.speed) % 1.0 * size.height;
      final x =
          particle.x * size.width + (10 * (i % 2 == 0 ? 1 : -1) * animation);

      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x % size.width, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
