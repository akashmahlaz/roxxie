import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// 🎨 ROXXIE MASTER THEME - RED & WHITE
///
/// This combines all our design tokens into a cohesive Material theme
/// that feels ultra-premium with bold red accents and clean white typography.

class AppTheme {
  AppTheme._();

  /// The main dark theme for Roxxie
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ═══════════════════════════════════════════════════════════════════════
      // 🎨 COLOR SCHEME - RED & WHITE
      // ═══════════════════════════════════════════════════════════════════════
      colorScheme: const ColorScheme.dark(
        primary: AppColors.crimson,
        onPrimary: AppColors.pureWhite,
        primaryContainer: AppColors.crimsonDark,
        onPrimaryContainer: AppColors.pureWhite,

        secondary: AppColors.rose,
        onSecondary: AppColors.pureWhite,
        secondaryContainer: AppColors.roseDark,
        onSecondaryContainer: AppColors.pureWhite,

        tertiary: AppColors.cyan,
        onTertiary: AppColors.textInverse,

        error: AppColors.error,
        onError: AppColors.pureWhite,
        errorContainer: AppColors.errorDark,
        onErrorContainer: AppColors.pureWhite,

        surface: AppColors.charcoal,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.graphite,
        onSurfaceVariant: AppColors.textSecondary,

        outline: AppColors.slate,
        outlineVariant: AppColors.graphite,

        shadow: Colors.black,
        scrim: Colors.black,

        inverseSurface: AppColors.pureWhite,
        onInverseSurface: AppColors.obsidian,
        inversePrimary: AppColors.crimsonDark,
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
          backgroundColor: AppColors.crimson,
          foregroundColor: AppColors.pureWhite,
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
          backgroundColor: AppColors.crimson,
          foregroundColor: AppColors.pureWhite,
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
          foregroundColor: AppColors.crimson,
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
          borderSide: const BorderSide(color: AppColors.crimson, width: 2),
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
          color: AppColors.crimson,
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
      // 🧭 NAVIGATION BAR - RED THEMED
      // ═══════════════════════════════════════════════════════════════════════
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.charcoal,
        indicatorColor: AppColors.crimson.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.crimson, size: 24);
          }
          return const IconThemeData(color: AppColors.textTertiary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(color: AppColors.crimson);
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
      // 🏷️ CHIP - RED THEMED
      // ═══════════════════════════════════════════════════════════════════════
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.graphite,
        selectedColor: AppColors.crimson.withValues(alpha: 0.2),
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
      // 📊 PROGRESS INDICATOR - RED THEMED
      // ═══════════════════════════════════════════════════════════════════════
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.crimson,
        linearTrackColor: AppColors.graphite,
        circularTrackColor: AppColors.graphite,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🎚️ SLIDER - RED THEMED
      // ═══════════════════════════════════════════════════════════════════════
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.crimson,
        inactiveTrackColor: AppColors.graphite,
        thumbColor: AppColors.pureWhite,
        overlayColor: AppColors.crimson.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // ☑️ CHECKBOX - RED THEMED
      // ═══════════════════════════════════════════════════════════════════════
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.crimson;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.pureWhite),
        side: const BorderSide(color: AppColors.slate, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🔘 RADIO - RED THEMED
      // ═══════════════════════════════════════════════════════════════════════
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.crimson;
          }
          return AppColors.slate;
        }),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // 🔄 SWITCH - RED THEMED
      // ═══════════════════════════════════════════════════════════════════════
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.pureWhite;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.crimson;
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
      // 📑 TAB BAR - RED THEMED
      // ═══════════════════════════════════════════════════════════════════════
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.pureWhite,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.crimson, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // ✨ SPLASH & HIGHLIGHT - RED THEMED
      // ═══════════════════════════════════════════════════════════════════════
      splashColor: AppColors.crimson.withValues(alpha: 0.1),
      highlightColor: AppColors.crimson.withValues(alpha: 0.05),
      hoverColor: AppColors.crimson.withValues(alpha: 0.05),
      focusColor: AppColors.crimson.withValues(alpha: 0.1),

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
