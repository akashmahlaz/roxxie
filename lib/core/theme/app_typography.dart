import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 🔤 ROXXIE ULTRA PREMIUM TYPOGRAPHY SYSTEM
///
/// Font Choices (World-Class Selection):
///
/// DISPLAY/HEADINGS: Space Grotesk
/// - Modern, geometric sans-serif
/// - Perfect for bold statements
/// - Used by: Stripe, Vercel, top tech brands
///
/// BODY/UI: Inter
/// - Best readability on screens
/// - Designed specifically for UI
/// - Used by: GitHub, Figma, Linear
///
/// ACCENT/SPECIAL: Playfair Display
/// - Elegant serif for luxury moments
/// - Premium feel for special text
/// - Used by: Fashion brands, luxury apps
///
/// MONO/NUMBERS: JetBrains Mono
/// - Clean monospace for stats/numbers
/// - Modern and readable

class AppTypography {
  AppTypography._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 📐 TYPE SCALE (Based on Golden Ratio 1.618)
  // ═══════════════════════════════════════════════════════════════════════════

  static const double _scaleXXS = 10.0;
  static const double _scaleXS = 12.0;
  static const double _scaleSM = 14.0;
  static const double _scaleMD = 16.0;
  static const double _scaleLG = 18.0;
  static const double _scaleXL = 20.0;
  static const double _scaleXXL = 24.0;
  static const double _scale2XL = 30.0;
  static const double _scale3XL = 36.0;
  static const double _scale4XL = 48.0;
  static const double _scale5XL = 60.0;
  static const double _scale6XL = 72.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 DISPLAY STYLES (Hero text, Splash, Major headings)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Massive display - Splash screen, major moments
  static TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: _scale6XL,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -2.0,
    height: 1.1,
  );

  /// Large display - Section headers
  static TextStyle displayMedium = GoogleFonts.spaceGrotesk(
    fontSize: _scale5XL,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
    height: 1.1,
  );

  /// Medium display
  static TextStyle displaySmall = GoogleFonts.spaceGrotesk(
    fontSize: _scale4XL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.2,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 📰 HEADLINE STYLES (Page titles, Card headers)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle headlineLarge = GoogleFonts.spaceGrotesk(
    fontSize: _scale3XL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle headlineMedium = GoogleFonts.spaceGrotesk(
    fontSize: _scale2XL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.25,
    height: 1.3,
  );

  static TextStyle headlineSmall = GoogleFonts.spaceGrotesk(
    fontSize: _scaleXXL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏷️ TITLE STYLES (List items, Cards, Dialogs)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: _scaleXXL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: _scaleXL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: _scaleLG,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 📝 BODY STYLES (Main content, Descriptions)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: _scaleLG,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: _scaleMD,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: _scaleSM,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏷️ LABEL STYLES (Buttons, Chips, Tags)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: _scaleMD,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: _scaleSM,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: _scaleXS,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ✨ SPECIAL STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Luxury accent text (for special moments)
  static TextStyle luxuryAccent = GoogleFonts.playfairDisplay(
    fontSize: _scale2XL,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontStyle: FontStyle.italic,
    height: 1.4,
  );

  /// Premium serif for quotes or special text
  static TextStyle premiumSerif = GoogleFonts.playfairDisplay(
    fontSize: _scaleXL,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Monospace for numbers, stats, prices
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: _scaleMD,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Large number display (for stats, prices)
  static TextStyle numberDisplay = GoogleFonts.jetBrainsMono(
    fontSize: _scale3XL,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Price tag style
  static TextStyle price = GoogleFonts.jetBrainsMono(
    fontSize: _scaleXXL,
    fontWeight: FontWeight.w600,
    color: AppColors.emeraldGlow,
    height: 1.2,
  );

  /// Caption style
  static TextStyle caption = GoogleFonts.inter(
    fontSize: _scaleXS,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  /// Overline text (small caps feel)
  static TextStyle overline = GoogleFonts.inter(
    fontSize: _scaleXXS,
    fontWeight: FontWeight.w700,
    color: AppColors.textTertiary,
    letterSpacing: 2.0,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 GRADIENT TEXT HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a gradient text shader
  static Shader gradientShader(Rect bounds) {
    return AppColors.primaryGradient.createShader(bounds);
  }
}

/// Extension for easy gradient text
extension GradientText on Text {
  Widget withGradient(Gradient gradient) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: this,
    );
  }
}
