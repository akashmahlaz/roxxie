import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 🌟 ROXXIE SHADOW & GLOW SYSTEM
///
/// Premium apps don't just have shadows - they have GLOWS
/// We use colored shadows to create depth and brand presence
///
/// RED & WHITE Theme:
/// 1. Subtle shadows - Depth without distraction
/// 2. Crimson glows - Brand-colored ambient light
/// 3. Neon glows - Electric, attention-grabbing

class AppShadows {
  AppShadows._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌑 SUBTLE SHADOWS (Depth & Elevation)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Subtle elevation - barely visible, just enough depth
  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Small shadow - cards, buttons
  static List<BoxShadow> small = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Medium shadow - modals, dropdowns
  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Large shadow - floating elements
  static List<BoxShadow> large = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ✨ CRIMSON GLOWS (Brand Presence - RED)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crimson glow - Primary brand elements
  static List<BoxShadow> crimsonGlow = [
    BoxShadow(
      color: AppColors.crimson.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: AppColors.crimson.withValues(alpha: 0.2),
      blurRadius: 40,
      spreadRadius: -4,
    ),
  ];

  /// Rose glow - Secondary accents
  static List<BoxShadow> roseGlow = [
    BoxShadow(
      color: AppColors.rose.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: AppColors.rose.withValues(alpha: 0.2),
      blurRadius: 40,
      spreadRadius: -4,
    ),
  ];

  /// Legacy aliases for backward compatibility
  static List<BoxShadow> get violetGlow => crimsonGlow;
  static List<BoxShadow> get magentaGlow => roseGlow;

  /// Cyan glow - Venue role, info elements
  static List<BoxShadow> cyanGlow = [
    BoxShadow(
      color: AppColors.cyan.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];

  /// Success glow - Confirmations, matches
  static List<BoxShadow> successGlow = [
    BoxShadow(
      color: AppColors.success.withValues(alpha: 0.4),
      blurRadius: 24,
      spreadRadius: -2,
    ),
  ];

  /// Error glow - Rejections
  static List<BoxShadow> errorGlow = [
    BoxShadow(
      color: AppColors.error.withValues(alpha: 0.4),
      blurRadius: 24,
      spreadRadius: -2,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚡ NEON GLOWS (Attention-Grabbing - RED THEMED)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Intense crimson neon - CTAs, important buttons
  static List<BoxShadow> neonCrimson = [
    BoxShadow(
      color: AppColors.crimson.withValues(alpha: 0.5),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.crimson.withValues(alpha: 0.3),
      blurRadius: 32,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.crimson.withValues(alpha: 0.1),
      blurRadius: 64,
      spreadRadius: 0,
    ),
  ];

  /// Intense rose neon
  static List<BoxShadow> neonRose = [
    BoxShadow(
      color: AppColors.rose.withValues(alpha: 0.5),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.rose.withValues(alpha: 0.3),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];

  /// Legacy aliases
  static List<BoxShadow> get neonViolet => neonCrimson;
  static List<BoxShadow> get neonMagenta => neonRose;

  /// Multi-color neon (gradient effect)
  static List<BoxShadow> neonMulti = [
    BoxShadow(
      color: AppColors.crimson.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(-8, 0),
    ),
    BoxShadow(
      color: AppColors.rose.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(8, 0),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎴 CARD SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default card shadow
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  /// Elevated card (hover state)
  static List<BoxShadow> cardElevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: AppColors.electricViolet.withValues(alpha: 0.1),
      blurRadius: 40,
      spreadRadius: -8,
    ),
  ];

  /// Swipe card shadow
  static List<BoxShadow> swipeCard = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔘 BUTTON SHADOWS - RED THEMED
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary button shadow
  static List<BoxShadow> buttonPrimary = [
    BoxShadow(
      color: AppColors.crimson.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Button pressed state
  static List<BoxShadow> buttonPressed = [
    BoxShadow(
      color: AppColors.crimson.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌈 INNER SHADOWS (Inset effects)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inner shadow for pressed states
  static List<BoxShadow> innerSubtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
      blurStyle: BlurStyle.inner,
    ),
  ];

  /// Inner glow effect
  static List<BoxShadow> innerGlow = [
    BoxShadow(
      color: AppColors.crimson.withValues(alpha: 0.2),
      blurRadius: 16,
      blurStyle: BlurStyle.inner,
    ),
  ];
}
