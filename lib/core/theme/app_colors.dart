import 'package:flutter/material.dart';

/// 🎨 ROXXIE ULTRA PREMIUM COLOR SYSTEM
/// Inspired by: Luxury brands (Rolls Royce, Vertu), Music (Concert lights, Vinyl)
/// Philosophy: Dark elegance with electric accents
/// 
/// This is NOT a typical app color scheme - it's designed to feel
/// like a $10,000 experience in your pocket.

class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌑 DEEP BLACKS - The Canvas of Luxury
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Pure black - use sparingly for true AMOLED black
  static const Color pureBlack = Color(0xFF000000);
  
  /// Rich black with subtle blue undertone - main background
  static const Color obsidian = Color(0xFF0A0A0F);
  
  /// Elevated surface - cards, modals
  static const Color charcoal = Color(0xFF141419);
  
  /// Secondary surface - input fields, containers
  static const Color graphite = Color(0xFF1E1E26);
  
  /// Tertiary surface - hover states, borders
  static const Color slate = Color(0xFF2A2A35);

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚡ ELECTRIC ACCENTS - The Soul of Music
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary brand color - Electric Violet (Concert spotlight)
  static const Color electricViolet = Color(0xFF8B5CF6);
  
  /// Primary variant - Deep Violet
  static const Color deepViolet = Color(0xFF7C3AED);
  
  /// Secondary accent - Neon Magenta (Stage lights)
  static const Color neonMagenta = Color(0xFFEC4899);
  
  /// Tertiary accent - Electric Cyan (Cool tone balance)
  static const Color electricCyan = Color(0xFF06B6D4);
  
  /// Warm accent - Sunset Orange (Energy, passion)
  static const Color sunsetOrange = Color(0xFFF97316);
  
  /// Success accent - Emerald Glow
  static const Color emeraldGlow = Color(0xFF10B981);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌈 PREMIUM GRADIENTS - The Signature Look
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Main brand gradient - Violet to Magenta (Premium CTA buttons)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricViolet, neonMagenta],
  );
  
  /// Aurora gradient - The hero gradient (Splash, special moments)
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667eea),
      Color(0xFF764ba2),
      Color(0xFFf093fb),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Cosmic gradient - Deep space feel (Backgrounds)
  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F0F1A),
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
    ],
  );
  
  /// Gold Premium gradient - For premium badges
  static const LinearGradient goldPremiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4AF37),
      Color(0xFFF4E5C2),
      Color(0xFFD4AF37),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Mesh gradient colors for animated backgrounds
  static const List<Color> meshGradientColors = [
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF0A0A0F),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 📝 TEXT COLORS - Hierarchy & Readability
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary text - Maximum contrast
  static const Color textPrimary = Color(0xFFFAFAFA);
  
  /// Secondary text - Descriptions, subtitles
  static const Color textSecondary = Color(0xFFA1A1AA);
  
  /// Tertiary text - Hints, placeholders
  static const Color textTertiary = Color(0xFF71717A);
  
  /// Disabled text
  static const Color textDisabled = Color(0xFF52525B);
  
  /// Inverse text (on light backgrounds)
  static const Color textInverse = Color(0xFF0A0A0F);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚦 SEMANTIC COLORS - Clear Communication
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Success - Bookings confirmed, matches
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  
  /// Warning - Pending actions
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  
  /// Error - Rejections, errors
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  
  /// Info - Notifications, tips
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // ═══════════════════════════════════════════════════════════════════════════
  // ✨ SPECIAL EFFECTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Glass effect overlay
  static Color glassWhite = Colors.white.withValues(alpha: 0.08);
  static Color glassBorder = Colors.white.withValues(alpha: 0.12);
  
  /// Glow colors for shadows
  static Color violetGlow = electricViolet.withValues(alpha: 0.4);
  static Color magentaGlow = neonMagenta.withValues(alpha: 0.4);
  static Color cyanGlow = electricCyan.withValues(alpha: 0.4);
  
  /// Shimmer effect colors
  static const Color shimmerBase = Color(0xFF1E1E26);
  static const Color shimmerHighlight = Color(0xFF2A2A35);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎭 SWIPE COLORS (Core Feature)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Swipe right - Like/Match
  static const Color swipeLike = Color(0xFF10B981);
  static const Color swipeLikeGlow = Color(0x6610B981);
  
  /// Swipe left - Skip
  static const Color swipeSkip = Color(0xFFEF4444);
  static const Color swipeSkipGlow = Color(0x66EF4444);
  
  /// Super like - Star
  static const Color superLike = Color(0xFFF59E0B);
  static const Color superLikeGlow = Color(0x66F59E0B);
}
