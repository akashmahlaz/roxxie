import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// 🏷️ PREMIUM CHIP
///
/// Beautiful chip with glow effects for genre tags, filters etc
///
/// Usage:
/// ```dart
/// PremiumChip(
///   label: 'Rock',
///   isSelected: true,
///   onTap: () {},
/// )
/// ```

class PremiumChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;

  const PremiumChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.electricViolet;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.graphite,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected ? color : AppColors.slate,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🏷️ GENRE CHIP
///
/// Specialized chip for music genres with color coding

class GenreChip extends StatelessWidget {
  final String genre;
  final bool isSelected;
  final VoidCallback? onTap;

  const GenreChip({
    super.key,
    required this.genre,
    this.isSelected = false,
    this.onTap,
  });

  Color get _genreColor {
    switch (genre.toLowerCase()) {
      case 'rock':
        return const Color(0xFFEF4444);
      case 'jazz':
        return const Color(0xFFF59E0B);
      case 'pop':
        return const Color(0xFFEC4899);
      case 'hip-hop':
      case 'hip hop':
        return const Color(0xFF8B5CF6);
      case 'r&b':
        return const Color(0xFF06B6D4);
      case 'indie':
        return const Color(0xFF10B981);
      case 'electronic':
        return const Color(0xFF3B82F6);
      case 'classical':
        return const Color(0xFFA78BFA);
      case 'country':
        return const Color(0xFFF97316);
      case 'metal':
        return const Color(0xFF6B7280);
      case 'blues':
        return const Color(0xFF0EA5E9);
      case 'reggae':
        return const Color(0xFF22C55E);
      case 'folk':
        return const Color(0xFFD97706);
      default:
        return AppColors.electricViolet;
    }
  }

  IconData get _genreIcon {
    switch (genre.toLowerCase()) {
      case 'rock':
        return Icons.flash_on;
      case 'jazz':
        return Icons.music_note;
      case 'pop':
        return Icons.star;
      case 'hip-hop':
      case 'hip hop':
        return Icons.mic;
      case 'classical':
        return Icons.piano;
      case 'electronic':
        return Icons.graphic_eq;
      default:
        return Icons.music_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumChip(
      label: genre,
      isSelected: isSelected,
      onTap: onTap,
      icon: _genreIcon,
      selectedColor: _genreColor,
    );
  }
}

/// 🏷️ STATUS BADGE
///
/// For showing booking status, verification etc

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.info,
    this.small = false,
  });

  Color get _color {
    switch (type) {
      case StatusType.success:
        return AppColors.success;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.error:
        return AppColors.error;
      case StatusType.info:
        return AppColors.info;
      case StatusType.premium:
        return AppColors.sunsetOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: (small ? AppTypography.caption : AppTypography.labelSmall)
            .copyWith(color: _color),
      ),
    );
  }
}

enum StatusType { success, warning, error, info, premium }

/// ⭐ RATING BADGE
///
/// Compact rating display

class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool compact;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.slate),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: AppColors.warning,
            size: compact ? 14 : 18,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style:
                (compact ? AppTypography.labelSmall : AppTypography.labelMedium)
                    .copyWith(color: AppColors.textPrimary),
          ),
          if (reviewCount != null && !compact) ...[
            const SizedBox(width: 4),
            Text('($reviewCount)', style: AppTypography.caption),
          ],
        ],
      ),
    );
  }
}

/// 💰 PRICE BADGE
///
/// Display price range

class PriceBadge extends StatelessWidget {
  final double minPrice;
  final double? maxPrice;
  final String currency;

  const PriceBadge({
    super.key,
    required this.minPrice,
    this.maxPrice,
    this.currency = '\$',
  });

  @override
  Widget build(BuildContext context) {
    String priceText;
    if (maxPrice != null && maxPrice != minPrice) {
      priceText =
          '$currency${minPrice.toInt()} - $currency${maxPrice!.toInt()}';
    } else {
      priceText = '$currency${minPrice.toInt()}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emeraldGlow.withValues(alpha: 0.2),
            AppColors.electricCyan.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.emeraldGlow.withValues(alpha: 0.3)),
      ),
      child: Text(
        priceText,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.emeraldGlow,
          fontFamily: 'JetBrainsMono',
        ),
      ),
    );
  }
}
