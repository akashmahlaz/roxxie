import 'package:flutter/material.dart';

/// 📐 ROXXIE SPACING SYSTEM
///
/// Based on 4px base unit with harmonic scale
/// Creates consistent rhythm throughout the app
///
/// Philosophy: Generous white space = Premium feel

class AppSpacing {
  AppSpacing._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 📏 BASE SPACING SCALE
  // ═══════════════════════════════════════════════════════════════════════════

  /// 2px - Micro spacing
  static const double xxs = 2.0;

  /// 4px - Tiny spacing
  static const double xs = 4.0;

  /// 8px - Small spacing
  static const double sm = 8.0;

  /// 12px - Medium-small spacing
  static const double md = 12.0;

  /// 16px - Base spacing
  static const double base = 16.0;

  /// 20px - Medium spacing
  static const double lg = 20.0;

  /// 24px - Large spacing
  static const double xl = 24.0;

  /// 32px - Extra large spacing
  static const double xxl = 32.0;

  /// 40px - 2X large spacing
  static const double xxxl = 40.0;

  /// 48px - 3X large spacing
  static const double huge = 48.0;

  /// 64px - Massive spacing
  static const double massive = 64.0;

  /// 80px - Giant spacing
  static const double giant = 80.0;

  /// 96px - Colossal spacing
  static const double colossal = 96.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 SCREEN PADDING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard horizontal screen padding
  static const double screenPaddingH = 24.0;

  /// Standard vertical screen padding
  static const double screenPaddingV = 16.0;

  /// Screen edge insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );

  /// Screen horizontal only
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎴 CARD & CONTAINER PADDING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compact card padding
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);

  /// Standard card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  /// Large card padding
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24.0);

  /// Premium card padding (generous spacing)
  static const EdgeInsets cardPaddingPremium = EdgeInsets.all(32.0);

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔘 BUTTON PADDING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Small button padding
  static const EdgeInsets buttonPaddingSm = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );

  /// Medium button padding
  static const EdgeInsets buttonPaddingMd = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 12.0,
  );

  /// Large button padding
  static const EdgeInsets buttonPaddingLg = EdgeInsets.symmetric(
    horizontal: 32.0,
    vertical: 16.0,
  );

  /// Extra large button padding (CTA buttons)
  static const EdgeInsets buttonPaddingXl = EdgeInsets.symmetric(
    horizontal: 40.0,
    vertical: 20.0,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 📝 INPUT FIELD PADDING
  // ═══════════════════════════════════════════════════════════════════════════

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 18.0,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ⭕ BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tiny radius - chips, small elements
  static const double radiusXs = 4.0;

  /// Small radius - buttons, inputs
  static const double radiusSm = 8.0;

  /// Medium radius - cards
  static const double radiusMd = 12.0;

  /// Large radius - modals, large cards
  static const double radiusLg = 16.0;

  /// Extra large radius - bottom sheets
  static const double radiusXl = 24.0;

  /// 2XL radius - full rounded elements
  static const double radiusXxl = 32.0;

  /// Full circle
  static const double radiusFull = 999.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // 📦 BORDER RADIUS PRESETS
  // ═══════════════════════════════════════════════════════════════════════════

  static const BorderRadius borderRadiusXs = BorderRadius.all(
    Radius.circular(radiusXs),
  );
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadiusXxl = BorderRadius.all(
    Radius.circular(radiusXxl),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 📏 ICON SIZES
  // ═══════════════════════════════════════════════════════════════════════════

  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 28.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 40.0;
  static const double iconHuge = 48.0;
  static const double iconMassive = 64.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // 📸 AVATAR SIZES
  // ═══════════════════════════════════════════════════════════════════════════

  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 48.0;
  static const double avatarXl = 64.0;
  static const double avatarXxl = 80.0;
  static const double avatarHuge = 120.0;
  static const double avatarProfile = 160.0;
}
