import 'package:flutter/material.dart';

/// 🎨 ROXXIE DESIGN SYSTEM - RED & WHITE PALETTE
///
/// Brand Identity: Passion meets Premium
/// Philosophy: Dark elegance with bold red accents and clean white typography
///
/// Inspired by: Stage lights, Concert energy, Music passion
/// Color Psychology: Red = Energy, Passion, Excitement | White = Clarity, Premium

class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌑 DARK SURFACES - The Premium Canvas
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pure black - AMOLED black, use for true depth
  static const Color pureBlack = Color(0xFF000000);

  /// Primary background - Rich dark with subtle warmth
  static const Color obsidian = Color(0xFF0A0A0C);

  /// Elevated surface - Cards, modals, bottom sheets
  static const Color charcoal = Color(0xFF121215);

  /// Secondary surface - Input fields, containers
  static const Color graphite = Color(0xFF1A1A1F);

  /// Tertiary surface - Borders, dividers, hover states
  static const Color slate = Color(0xFF252530);

  /// Subtle surface - Very light dark mode elements
  static const Color ash = Color(0xFF2F2F3A);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔴 SIGNATURE REDS - The Heart of Roxxie
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary brand color - Crimson (Bold, energetic)
  static const Color crimson = Color(0xFFDC2626);

  /// Primary hover/pressed - Darker crimson
  static const Color crimsonDark = Color(0xFFB91C1C);

  /// Primary light variant - Softer red for subtle accents
  static const Color crimsonLight = Color(0xFFEF4444);

  /// Rose accent - Warmer red for secondary elements
  static const Color rose = Color(0xFFE11D48);

  /// Rose dark - Pressed state for rose
  static const Color roseDark = Color(0xFFBE123C);

  /// Deep wine - Luxurious dark red for premium elements
  static const Color wine = Color(0xFF881337);

  /// Red tinted surface - Subtle red-tinted dark background
  static const Color redSurface = Color(0xFF1A0A0A);

  /// Light red surface - For cards with red accent
  static const Color redSurfaceLight = Color(0xFF2A1515);

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚪ WHITE SPECTRUM - Clarity & Typography
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pure white - Headlines, CTAs, maximum contrast
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// Off white - Primary body text
  static const Color offWhite = Color(0xFFFAFAFA);

  /// Snow white - Subtle white, secondary emphasis
  static const Color snow = Color(0xFFF4F4F5);

  /// Light gray - Tertiary text, placeholders
  static const Color lightGray = Color(0xFFE4E4E7);

  /// Medium gray - Disabled elements
  static const Color mediumGray = Color(0xFFA1A1AA);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 SUPPORTING COLORS - Functional Accents
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cyan accent - For venue role, info elements
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanDark = Color(0xFF0891B2);
  static const Color cyanLight = Color(0xFF22D3EE);

  /// Gold - Premium badges, special features
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF4E5C2);
  static const Color goldDark = Color(0xFFB8960C);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌈 SIGNATURE GRADIENTS - Brand Identity
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary brand gradient - Crimson to Rose (Main CTAs)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [crimson, rose],
  );

  /// Dark gradient - Crimson fading to dark (Cards, overlays)
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [crimsonDark, wine],
  );

  /// Hero gradient - Bold splash screens
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFE11D48), Color(0xFF881337)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Cosmic gradient - Deep background effect
  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0C), Color(0xFF1A0A0A), Color(0xFF0A0A0C)],
  );

  /// Gold Premium gradient - Subscription, premium features
  static const LinearGradient goldPremiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFF4E5C2), Color(0xFFD4AF37)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Venue gradient - Cyan for venue role
  static const LinearGradient venueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, cyanDark],
  );

  /// Mesh gradient colors for animated backgrounds
  static const List<Color> meshGradientColors = [
    Color(0xFFDC2626),
    Color(0xFFE11D48),
    Color(0xFF881337),
    Color(0xFF0A0A0C),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔄 LEGACY ALIASES (For backward compatibility during migration)
  // ═══════════════════════════════════════════════════════════════════════════

  /// @deprecated Use crimson instead
  static const Color electricViolet = crimson;

  /// @deprecated Use crimsonDark instead
  static const Color deepViolet = crimsonDark;

  /// @deprecated Use rose instead
  static const Color neonMagenta = rose;

  /// @deprecated Use cyan instead
  static const Color electricCyan = cyan;

  /// @deprecated Use gold instead
  static const Color sunsetOrange = gold;

  /// @deprecated Use success instead
  static const Color emeraldGlow = Color(0xFF10B981);

  /// Aurora gradient alias
  static const LinearGradient auroraGradient = heroGradient;

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

  /// Glow colors for shadows - RED THEMED
  static Color crimsonGlow = crimson.withValues(alpha: 0.4);
  static Color roseGlow = rose.withValues(alpha: 0.4);
  static Color cyanGlow = cyan.withValues(alpha: 0.4);

  /// Legacy glow aliases
  static Color violetGlow = crimsonGlow;
  static Color magentaGlow = roseGlow;

  /// Shimmer effect colors
  static const Color shimmerBase = Color(0xFF1A1A1F);
  static const Color shimmerHighlight = Color(0xFF252530);

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

  // ═══════════════════════════════════════════════════════════════════════════
  // ☀️ LIGHT MODE SURFACES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light mode background
  static const Color lightBackground = Color(0xFFF9F9F9);

  /// Light mode surface (cards, containers)
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light mode secondary surface
  static const Color lightSurfaceSecondary = Color(0xFFF3F4F6);

  /// Light mode border color
  static const Color lightBorder = Color(0xFFE5E7EB);

  /// Light mode divider
  static const Color lightDivider = Color(0xFFE5E7EB);

  // ═══════════════════════════════════════════════════════════════════════════
  // 📝 LIGHT MODE TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light mode primary text
  static const Color lightTextPrimary = Color(0xFF111827);

  /// Light mode secondary text
  static const Color lightTextSecondary = Color(0xFF6B7280);

  /// Light mode tertiary text
  static const Color lightTextTertiary = Color(0xFF9CA3AF);

  /// Light mode disabled text
  static const Color lightTextDisabled = Color(0xFFD1D5DB);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 ADAPTIVE COLOR HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get background color based on brightness
  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? obsidian : lightBackground;

  /// Get surface color based on brightness
  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? charcoal : lightSurface;

  /// Get secondary surface based on brightness
  static Color surfaceSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? graphite : lightSurfaceSecondary;

  /// Get card background color (warmer dark tone)
  static Color cardBackground(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF2A1A1A) : lightSurface;

  /// Get primary text color based on brightness
  static Color text(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimary : lightTextPrimary;

  /// Get secondary text color based on brightness
  static Color textSec(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondary : lightTextSecondary;

  /// Get tertiary text color based on brightness
  static Color textTert(Brightness brightness) =>
      brightness == Brightness.dark ? textTertiary : lightTextTertiary;

  /// Get border color based on brightness
  static Color border(Brightness brightness) => brightness == Brightness.dark
      ? Colors.white.withOpacity(0.1)
      : lightBorder;

  /// Get divider color based on brightness
  static Color divider(Brightness brightness) => brightness == Brightness.dark
      ? Colors.white.withOpacity(0.1)
      : lightDivider;

  /// Get icon color based on brightness
  static Color icon(Brightness brightness) => brightness == Brightness.dark
      ? Colors.white.withOpacity(0.7)
      : const Color(0xFF6B7280);

  /// Get icon secondary color based on brightness
  static Color iconSecondary(Brightness brightness) =>
      brightness == Brightness.dark
      ? Colors.white.withOpacity(0.5)
      : const Color(0xFF9CA3AF);

  /// Get input fill color based on brightness
  static Color inputFill(Brightness brightness) => brightness == Brightness.dark
      ? Colors.white.withOpacity(0.08)
      : lightSurface;

  /// Get sheet/modal background based on brightness
  static Color sheetBackground(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF211111) : lightSurface;
}
