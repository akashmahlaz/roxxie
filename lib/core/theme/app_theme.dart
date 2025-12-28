import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// 🎨 ROXXIE MASTER THEME
///
/// This combines all our design tokens into a cohesive Material theme
/// that feels ultra-premium and world-class.

class AppTheme {
  AppTheme._();

  /// The main dark theme for Roxxie
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ═══════════════════════════════════════════════════════════════════════
      // 🎨 COLOR SCHEME
      // ═══════════════════════════════════════════════════════════════════════
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricViolet,
        onPrimary: AppColors.textPrimary,
        primaryContainer: AppColors.deepViolet,
        onPrimaryContainer: AppColors.textPrimary,

        secondary: AppColors.neonMagenta,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: AppColors.neonMagenta,
        onSecondaryContainer: AppColors.textPrimary,

        tertiary: AppColors.electricCyan,
        onTertiary: AppColors.textInverse,

        error: AppColors.error,
        onError: AppColors.textPrimary,
        errorContainer: AppColors.errorDark,
        onErrorContainer: AppColors.textPrimary,

        surface: AppColors.charcoal,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.graphite,
        onSurfaceVariant: AppColors.textSecondary,

        outline: AppColors.slate,
        outlineVariant: AppColors.graphite,

        shadow: Colors.black,
        scrim: Colors.black,

        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.obsidian,
        inversePrimary: AppColors.deepViolet,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🖼️ SCAFFOLD
      // ═══════════════════════════════════════════════════════════════════════
      scaffoldBackgroundColor: AppColors.obsidian,

      // ═══════════════════════════════════════════════════════════════════════
      // 📝 TEXT THEME
      // ═══════════════════════════════════════════════════════════════════════
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🔘 BUTTON THEMES
      // ═══════════════════════════════════════════════════════════════════════

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricViolet,
          foregroundColor: AppColors.textPrimary,
          padding: AppSpacing.buttonPaddingLg,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          elevation: 0,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.electricViolet,
          foregroundColor: AppColors.textPrimary,
          padding: AppSpacing.buttonPaddingLg,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: AppSpacing.buttonPaddingLg,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          side: const BorderSide(color: AppColors.slate, width: 1.5),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.electricViolet,
          padding: AppSpacing.buttonPaddingMd,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.all(12),
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 📝 INPUT DECORATION
      // ═══════════════════════════════════════════════════════════════════════
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.graphite,
        contentPadding: AppSpacing.inputPadding,

        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.slate, width: 1),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.electricViolet,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),

        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),

        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),

        floatingLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.electricViolet,
        ),

        errorStyle: AppTypography.labelSmall.copyWith(color: AppColors.error),

        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🎴 CARD THEME
      // ═══════════════════════════════════════════════════════════════════════
      cardTheme: CardThemeData(
        color: AppColors.charcoal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(color: AppColors.glassBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 📍 APP BAR
      // ═══════════════════════════════════════════════════════════════════════
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleMedium,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconMd,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🧭 NAVIGATION BAR
      // ═══════════════════════════════════════════════════════════════════════
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.charcoal,
        indicatorColor: AppColors.electricViolet.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.electricViolet,
              size: 24,
            );
          }
          return const IconThemeData(color: AppColors.textTertiary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.electricViolet,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          );
        }),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 📜 BOTTOM SHEET
      // ═══════════════════════════════════════════════════════════════════════
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.charcoal,
        modalBackgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.slate,
        dragHandleSize: Size(40, 4),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 💬 DIALOG
      // ═══════════════════════════════════════════════════════════════════════
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.charcoal,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🏷️ CHIP
      // ═══════════════════════════════════════════════════════════════════════
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.graphite,
        selectedColor: AppColors.electricViolet.withValues(alpha: 0.2),
        disabledColor: AppColors.graphite,
        labelStyle: AppTypography.labelMedium,
        secondaryLabelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          side: const BorderSide(color: AppColors.slate),
        ),
        side: const BorderSide(color: AppColors.slate),
        showCheckmark: false,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🔀 DIVIDER
      // ═══════════════════════════════════════════════════════════════════════
      dividerTheme: const DividerThemeData(
        color: AppColors.slate,
        thickness: 1,
        space: 1,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 📊 PROGRESS INDICATOR
      // ═══════════════════════════════════════════════════════════════════════
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.electricViolet,
        linearTrackColor: AppColors.graphite,
        circularTrackColor: AppColors.graphite,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🎚️ SLIDER
      // ═══════════════════════════════════════════════════════════════════════
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.electricViolet,
        inactiveTrackColor: AppColors.graphite,
        thumbColor: AppColors.textPrimary,
        overlayColor: AppColors.electricViolet.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // ☑️ CHECKBOX
      // ═══════════════════════════════════════════════════════════════════════
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.electricViolet;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textPrimary),
        side: const BorderSide(color: AppColors.slate, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🔘 RADIO
      // ═══════════════════════════════════════════════════════════════════════
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.electricViolet;
          }
          return AppColors.slate;
        }),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🔄 SWITCH
      // ═══════════════════════════════════════════════════════════════════════
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textPrimary;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.electricViolet;
          }
          return AppColors.graphite;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🍞 SNACKBAR
      // ═══════════════════════════════════════════════════════════════════════
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.graphite,
        contentTextStyle: AppTypography.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 📑 TAB BAR
      // ═══════════════════════════════════════════════════════════════════════
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.electricViolet, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // ✨ SPLASH & HIGHLIGHT
      // ═══════════════════════════════════════════════════════════════════════
      splashColor: AppColors.electricViolet.withValues(alpha: 0.1),
      highlightColor: AppColors.electricViolet.withValues(alpha: 0.05),
      hoverColor: AppColors.electricViolet.withValues(alpha: 0.05),
      focusColor: AppColors.electricViolet.withValues(alpha: 0.1),

      // ═══════════════════════════════════════════════════════════════════════
      // 🎯 MISC
      // ═══════════════════════════════════════════════════════════════════════
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  /// System UI overlay style for immersive experience
  static const SystemUiOverlayStyle systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.obsidian,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
