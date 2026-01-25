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

            // Progress indicator
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: null,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.crimson,
                  ),
                  minHeight: 4,
                ),
              ),
            ),
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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
