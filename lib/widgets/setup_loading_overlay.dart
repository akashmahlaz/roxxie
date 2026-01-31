import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 🔄 Professional Setup Loading Overlay
///
/// A clean, modern loading overlay for profile setup screens.
/// Shows an animated icon, title, subtitle, and progress indicator.
class SetupLoadingOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Brightness brightness;

  const SetupLoadingOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.brightness,
  });

  /// Show as a dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final brightness = Theme.of(context).brightness;
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => PopScope(
        canPop: false,
        child: SetupLoadingOverlay(
          title: title,
          subtitle: subtitle,
          icon: icon,
          brightness: brightness,
        ),
      ),
    );
  }

  /// Dismiss the dialog
  static void dismiss(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with glow
            _AnimatedIcon(icon: icon, isDark: isDark),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 28),

            // M3 Expressive wavy progress indicator
            _WavyProgressIndicator(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

/// Animated icon with pulse effect
class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final bool isDark;

  const _AnimatedIcon({required this.icon, required this.isDark});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // M3 Expressive: Spring-like motion curve for more natural feel
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.crimson, Color(0xFFFF4D6D)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 36),
          ),
        );
      },
    );
  }
}

/// Minimal loading overlay (for skip/quick actions)
class MinimalLoadingOverlay extends StatelessWidget {
  final String message;
  final Brightness brightness;

  const MinimalLoadingOverlay({
    super.key,
    required this.message,
    required this.brightness,
  });

  /// Show as a dialog
  static Future<void> show(BuildContext context, {required String message}) {
    final brightness = Theme.of(context).brightness;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: MinimalLoadingOverlay(message: message, brightness: brightness),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.crimson,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🌊 M3 Expressive Wavy Progress Indicator
///
/// Material 3 Expressive style progress indicator with:
/// - Wavy animation on the active track
/// - Thick track (8dp as per M3 spec)
/// - Rounded end caps
/// - Spring-based motion for natural feel
class _WavyProgressIndicator extends StatefulWidget {
  final bool isDark;

  const _WavyProgressIndicator({required this.isDark});

  @override
  State<_WavyProgressIndicator> createState() => _WavyProgressIndicatorState();
}

class _WavyProgressIndicatorState extends State<_WavyProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 8, // M3 Expressive thick track
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WavyProgressPainter(
              progress: _controller.value,
              trackColor: widget.isDark ? Colors.grey[800]! : Colors.grey[200]!,
              activeColor: AppColors.crimson,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for wavy progress effect
class _WavyProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color activeColor;

  _WavyProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final radius = size.height / 2;

    // Draw track (full width with rounded ends)
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    canvas.drawRRect(trackRect, trackPaint);

    // Draw active indicator with wave effect
    // The active section travels across the track
    final activeWidth = size.width * 0.4; // 40% width indicator
    final startX = (size.width + activeWidth) * progress - activeWidth;

    // Create wavy path for active indicator
    final path = Path();
    final waveHeight = size.height * 0.15; // Subtle wave
    final waveCount = 3;

    // Clamp to visible area
    final clampedStartX = startX.clamp(0.0, size.width);
    final clampedEndX = (startX + activeWidth).clamp(0.0, size.width);

    if (clampedEndX > clampedStartX) {
      // Start with rounded left cap if at beginning
      if (startX <= 0) {
        path.moveTo(0, size.height / 2);
        path.arcToPoint(
          Offset(radius, 0),
          radius: Radius.circular(radius),
          clockwise: true,
        );
      } else {
        path.moveTo(clampedStartX + radius, 0);
        path.arcToPoint(
          Offset(clampedStartX, size.height / 2),
          radius: Radius.circular(radius),
          clockwise: false,
        );
        path.arcToPoint(
          Offset(clampedStartX + radius, size.height),
          radius: Radius.circular(radius),
          clockwise: false,
        );
      }

      // Create wavy top edge
      final activeLength = clampedEndX - clampedStartX;
      for (int i = 0; i < waveCount; i++) {
        final segmentWidth = activeLength / waveCount;
        final x1 = clampedStartX + radius + (i * segmentWidth);
        final x2 = x1 + segmentWidth;

        if (x2 <= size.width - radius) {
          // Wave on top
          final wavePhase = progress * 2 * math.pi + i;
          final waveOffset = math.sin(wavePhase) * waveHeight;

          path.lineTo(x1, 0);
          path.quadraticBezierTo((x1 + x2) / 2, -waveOffset, x2, 0);
        }
      }

      // Rounded right cap if not at end
      if (startX + activeWidth < size.width) {
        final endX = (clampedEndX - radius).clamp(0.0, size.width);
        path.lineTo(endX, 0);
        path.arcToPoint(
          Offset(clampedEndX.clamp(0.0, size.width), size.height / 2),
          radius: Radius.circular(radius),
          clockwise: true,
        );
        path.arcToPoint(
          Offset(endX, size.height),
          radius: Radius.circular(radius),
          clockwise: true,
        );
      } else {
        path.lineTo(size.width - radius, 0);
        path.arcToPoint(
          Offset(size.width, size.height / 2),
          radius: Radius.circular(radius),
          clockwise: true,
        );
        path.arcToPoint(
          Offset(size.width - radius, size.height),
          radius: Radius.circular(radius),
          clockwise: true,
        );
      }

      path.close();

      // Clip to track bounds and draw
      canvas.save();
      canvas.clipRRect(trackRect);
      canvas.drawPath(path, activePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WavyProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
