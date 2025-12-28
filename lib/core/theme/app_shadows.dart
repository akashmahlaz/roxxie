import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 🌟 ROXXIE SHADOW & GLOW SYSTEM
///
/// Premium apps don't just have shadows - they have GLOWS
/// We use colored shadows to create depth and brand presence
///
/// Three types:
/// 1. Subtle shadows - Depth without distraction
/// 2. Glow shadows - Brand-colored ambient light
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
  // ✨ GLOW SHADOWS (Brand Presence)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Violet glow - Primary brand elements
  static List<BoxShadow> violetGlow = [
    BoxShadow(
      color: AppColors.electricViolet.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: AppColors.electricViolet.withValues(alpha: 0.2),
      blurRadius: 40,
      spreadRadius: -4,
    ),
  ];

  /// Magenta glow - Secondary accents
  static List<BoxShadow> magentaGlow = [
    BoxShadow(
      color: AppColors.neonMagenta.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: AppColors.neonMagenta.withValues(alpha: 0.2),
      blurRadius: 40,
      spreadRadius: -4,
    ),
  ];

  /// Cyan glow - Info, secondary actions
  static List<BoxShadow> cyanGlow = [
    BoxShadow(
      color: AppColors.electricCyan.withValues(alpha: 0.3),
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
  // ⚡ NEON GLOWS (Attention-Grabbing)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Intense violet neon - CTAs, important buttons
  static List<BoxShadow> neonViolet = [
    BoxShadow(
      color: AppColors.electricViolet.withValues(alpha: 0.5),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.electricViolet.withValues(alpha: 0.3),
      blurRadius: 32,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.electricViolet.withValues(alpha: 0.1),
      blurRadius: 64,
      spreadRadius: 0,
    ),
  ];

  /// Intense magenta neon
  static List<BoxShadow> neonMagenta = [
    BoxShadow(
      color: AppColors.neonMagenta.withValues(alpha: 0.5),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.neonMagenta.withValues(alpha: 0.3),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];

  /// Multi-color neon (gradient effect)
  static List<BoxShadow> neonMulti = [
    BoxShadow(
      color: AppColors.electricViolet.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(-8, 0),
    ),
    BoxShadow(
      color: AppColors.neonMagenta.withValues(alpha: 0.4),
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
  // 🔘 BUTTON SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary button shadow
  static List<BoxShadow> buttonPrimary = [
    BoxShadow(
      color: AppColors.electricViolet.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Button pressed state
  static List<BoxShadow> buttonPressed = [
    BoxShadow(
      color: AppColors.electricViolet.withValues(alpha: 0.2),
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
      color: AppColors.electricViolet.withValues(alpha: 0.2),
      blurRadius: 16,
      blurStyle: BlurStyle.inner,
    ),
  ];
}
