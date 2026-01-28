import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 🔘 MATERIAL 3 SEGMENTED BUTTON - 2026 Design Patterns
///
/// Toggle button group for selecting between options.
/// Ideal for media type selection, view modes, filters.
///
/// Usage:
/// ```dart
/// AppSegmentedButton<MediaType>(
///   segments: [
///     AppSegment(value: MediaType.photos, label: 'Photos', icon: Icons.photo),
///     AppSegment(value: MediaType.videos, label: 'Videos', icon: Icons.videocam),
///   ],
///   selected: selectedType,
///   onChanged: (value) => setState(() => selectedType = value),
/// );
/// ```
class AppSegmentedButton<T> extends StatelessWidget {
  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool multiSelect;
  final Set<T>? selectedSet;
  final ValueChanged<Set<T>>? onMultiChanged;
  final bool showSelectedIcon;
  final double? height;
  final bool expand;

  const AppSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.multiSelect = false,
    this.selectedSet,
    this.onMultiChanged,
    this.showSelectedIcon = true,
    this.height,
    this.expand = false,
  });

  /// Icon-only segmented button
  factory AppSegmentedButton.iconOnly({
    Key? key,
    required List<AppSegment<T>> segments,
    required T selected,
    required ValueChanged<T> onChanged,
    double? height = 48,
  }) {
    return AppSegmentedButton<T>(
      key: key,
      segments: segments,
      selected: selected,
      onChanged: onChanged,
      showSelectedIcon: false,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 48,
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate, width: 1),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: segments.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          final isSelected = multiSelect
              ? (selectedSet?.contains(segment.value) ?? false)
              : selected == segment.value;
          final isFirst = index == 0;
          final isLast = index == segments.length - 1;

          return expand
              ? Expanded(
                  child: _SegmentButton<T>(
                    segment: segment,
                    isSelected: isSelected,
                    isFirst: isFirst,
                    isLast: isLast,
                    showSelectedIcon: showSelectedIcon,
                    onTap: () {
                      if (multiSelect && onMultiChanged != null) {
                        final newSet = Set<T>.from(selectedSet ?? <T>{});
                        if (isSelected) {
                          newSet.remove(segment.value);
                        } else {
                          newSet.add(segment.value);
                        }
                        onMultiChanged!(newSet);
                      } else {
                        onChanged(segment.value);
                      }
                    },
                  ),
                )
              : _SegmentButton<T>(
                  segment: segment,
                  isSelected: isSelected,
                  isFirst: isFirst,
                  isLast: isLast,
                  showSelectedIcon: showSelectedIcon,
                  onTap: () {
                    if (multiSelect && onMultiChanged != null) {
                      final newSet = Set<T>.from(selectedSet ?? <T>{});
                      if (isSelected) {
                        newSet.remove(segment.value);
                      } else {
                        newSet.add(segment.value);
                      }
                      onMultiChanged!(newSet);
                    } else {
                      onChanged(segment.value);
                    }
                  },
                );
        }).toList(),
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  final AppSegment<T> segment;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final bool showSelectedIcon;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.segment,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.showSelectedIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(11) : Radius.zero,
      right: isLast ? const Radius.circular(11) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: AppColors.crimson.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.crimson.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: borderRadius,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: segment.label != null ? 16 : 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected && showSelectedIcon) ...[
                Icon(
                  Icons.check,
                  size: 18,
                  color: AppColors.crimson,
                ),
                const SizedBox(width: 8),
              ],
              if (segment.icon != null) ...[
                Icon(
                  segment.icon,
                  size: 20,
                  color: isSelected ? AppColors.crimson : AppColors.textSecondary,
                ),
                if (segment.label != null) const SizedBox(width: 8),
              ],
              if (segment.label != null)
                Text(
                  segment.label!,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.crimson : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segment data class
class AppSegment<T> {
  final T value;
  final String? label;
  final IconData? icon;
  final bool enabled;

  const AppSegment({
    required this.value,
    this.label,
    this.icon,
    this.enabled = true,
  });
}

/// 🎚️ Toggle switch group for binary choices
class AppToggleGroup<T> extends StatelessWidget {
  final T value1;
  final T value2;
  final String label1;
  final String label2;
  final T selected;
  final ValueChanged<T> onChanged;
  final IconData? icon1;
  final IconData? icon2;

  const AppToggleGroup({
    super.key,
    required this.value1,
    required this.value2,
    required this.label1,
    required this.label2,
    required this.selected,
    required this.onChanged,
    this.icon1,
    this.icon2,
  });

  @override
  Widget build(BuildContext context) {
    return AppSegmentedButton<T>(
      segments: [
        AppSegment(value: value1, label: label1, icon: icon1),
        AppSegment(value: value2, label: label2, icon: icon2),
      ],
      selected: selected,
      onChanged: onChanged,
      showSelectedIcon: false,
      expand: true,
    );
  }
}

/// 📷 Media type selector for edit profile
enum MediaType { photos, videos, audio }

class MediaTypeSelector extends StatelessWidget {
  final MediaType selected;
  final ValueChanged<MediaType> onChanged;

  const MediaTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppSegmentedButton<MediaType>(
      segments: const [
        AppSegment(value: MediaType.photos, label: 'Photos', icon: Icons.photo_library_rounded),
        AppSegment(value: MediaType.videos, label: 'Videos', icon: Icons.videocam_rounded),
        AppSegment(value: MediaType.audio, label: 'Audio', icon: Icons.music_note_rounded),
      ],
      selected: selected,
      onChanged: onChanged,
      expand: true,
    );
  }
}
