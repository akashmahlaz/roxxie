/// 🔍 GIGMATCH Filter Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass filter chips
/// - Range sliders with haptic feedback
/// - Animated selection states
/// - Real-time preview count
/// - Optimistic apply button
///
/// Advanced filtering for discovery
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

class FilterScreen extends StatefulWidget {
  final FilterOptions? initialFilters;
  final Function(FilterOptions)? onApply;
  
  const FilterScreen({
    super.key,
    this.initialFilters,
    this.onApply,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late FilterOptions _filters;
  int _matchCount = 47; // Mock count

  final List<String> _allGenres = [
    'Rock', 'Jazz', 'Blues', 'Pop', 'R&B', 'Soul',
    'Country', 'Electronic', 'Hip Hop', 'Classical',
    'Folk', 'Reggae', 'Metal', 'Indie', 'Alternative',
  ];

  final List<String> _venueTypes = [
    'Bar', 'Club', 'Restaurant', 'Lounge', 'Concert Hall',
    'Cafe', 'Hotel', 'Private Event', 'Festival', 'Corporate',
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? FilterOptions();
  }

  void _updateFilters(FilterOptions newFilters) {
    HapticFeedback.selectionClick();
    setState(() {
      _filters = newFilters;
      // Simulate recalculating match count
      _matchCount = (47 - (newFilters.selectedGenres.length * 3) + 
                   (newFilters.maxDistance / 10).toInt())
                   .clamp(5, 200);
    });
  }

  void _resetFilters() {
    HapticFeedback.mediumImpact();
    setState(() {
      _filters = FilterOptions();
      _matchCount = 47;
    });
  }

  void _applyFilters() {
    HapticFeedback.mediumImpact();
    widget.onApply?.call(_filters);
    Navigator.pop(context, _filters);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.text(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filters',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          AnimatedTapFeedback(
            onTap: _resetFilters,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distance Slider
            _buildSectionHeader('Distance', brightness),
            _buildDistanceSlider(brightness),

            const SizedBox(height: 24),

            // Payment Range
            _buildSectionHeader('Payment Range', brightness),
            _buildPaymentSlider(brightness),

            const SizedBox(height: 24),

            // Genres
            _buildSectionHeader('Genres', brightness),
            _buildGenreChips(brightness),

            const SizedBox(height: 24),

            // Venue Types
            _buildSectionHeader('Venue Type', brightness),
            _buildVenueTypeChips(brightness),

            const SizedBox(height: 24),

            // Date Range
            _buildSectionHeader('Availability', brightness),
            _buildAvailabilitySelector(brightness),

            const SizedBox(height: 24),

            // Additional Options
            _buildSectionHeader('More Options', brightness),
            _buildToggleOptions(brightness),

            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          border: Border(
            top: BorderSide(color: AppColors.border(brightness)),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Match count preview
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Showing',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        AnimatedCounter(
                          value: _matchCount,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'matches',
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Apply button
              Expanded(
                child: GradientButton(
                  text: 'Apply Filters',
                  onPressed: _applyFilters,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDistanceSlider(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filters.maxDistance.toInt()} miles',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: Text(
                  'Max Range',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.crimson,
              inactiveTrackColor: AppColors.border(brightness),
              thumbColor: AppColors.crimson,
              overlayColor: AppColors.crimson.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _filters.maxDistance,
              min: 5,
              max: 100,
              divisions: 19,
              onChanged: (value) {
                _updateFilters(_filters.copyWith(maxDistance: value));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSlider(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_filters.minPayment.toInt()}',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.crimson, Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${_filters.minPayment.toInt()} - \$${_filters.maxPayment.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$${_filters.maxPayment.toInt()}',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.crimson,
              inactiveTrackColor: AppColors.border(brightness),
              thumbColor: AppColors.crimson,
              overlayColor: AppColors.crimson.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: RangeSlider(
              values: RangeValues(_filters.minPayment, _filters.maxPayment),
              min: 0,
              max: 2000,
              divisions: 40,
              onChanged: (values) {
                _updateFilters(_filters.copyWith(
                  minPayment: values.start,
                  maxPayment: values.end,
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChips(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allGenres.map((genre) {
          final isSelected = _filters.selectedGenres.contains(genre);
          return AnimatedTapFeedback(
            onTap: () {
              final newGenres = List<String>.from(_filters.selectedGenres);
              if (isSelected) {
                newGenres.remove(genre);
              } else {
                newGenres.add(genre);
              }
              _updateFilters(_filters.copyWith(selectedGenres: newGenres));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.crimson, Color(0xFFFF6B6B)],
                      )
                    : null,
                color: isSelected ? null : AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.border(brightness),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.crimson.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text(brightness),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVenueTypeChips(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _venueTypes.map((type) {
          final isSelected = _filters.selectedVenueTypes.contains(type);
          return AnimatedTapFeedback(
            onTap: () {
              final newTypes = List<String>.from(_filters.selectedVenueTypes);
              if (isSelected) {
                newTypes.remove(type);
              } else {
                newTypes.add(type);
              }
              _updateFilters(_filters.copyWith(selectedVenueTypes: newTypes));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.crimson.withValues(alpha: 0.1)
                    : AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.border(brightness),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check_rounded,
                      color: AppColors.crimson,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.crimson
                          : AppColors.text(brightness),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvailabilitySelector(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _DatePickerCard(
              label: 'From',
              date: _filters.dateFrom,
              brightness: brightness,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filters.dateFrom ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  _updateFilters(_filters.copyWith(dateFrom: date));
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DatePickerCard(
              label: 'To',
              date: _filters.dateTo,
              brightness: brightness,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filters.dateTo ?? 
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: _filters.dateFrom ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  _updateFilters(_filters.copyWith(dateTo: date));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOptions(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _ToggleOption(
            title: 'Verified Venues Only',
            subtitle: 'Only show verified business accounts',
            icon: Icons.verified_rounded,
            value: _filters.verifiedOnly,
            onChanged: (value) {
              _updateFilters(_filters.copyWith(verifiedOnly: value));
            },
            brightness: brightness,
          ),
          const SizedBox(height: 12),
          _ToggleOption(
            title: 'Available for Booking',
            subtitle: 'Hide venues that are fully booked',
            icon: Icons.event_available_rounded,
            value: _filters.availableOnly,
            onChanged: (value) {
              _updateFilters(_filters.copyWith(availableOnly: value));
            },
            brightness: brightness,
          ),
          const SizedBox(height: 12),
          _ToggleOption(
            title: 'Include Private Events',
            subtitle: 'Show private event opportunities',
            icon: Icons.lock_rounded,
            value: _filters.includePrivate,
            onChanged: (value) {
              _updateFilters(_filters.copyWith(includePrivate: value));
            },
            brightness: brightness,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📦 SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Brightness brightness;
  final VoidCallback onTap;

  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: date != null
                      ? AppColors.crimson
                      : AppColors.textSec(brightness),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date!.month}/${date!.day}/${date!.year}'
                      : 'Select',
                  style: TextStyle(
                    color: date != null
                        ? AppColors.text(brightness)
                        : AppColors.textSec(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Brightness brightness;

  const _ToggleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value
              ? AppColors.crimson.withValues(alpha: 0.05)
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? AppColors.crimson.withValues(alpha: 0.3)
                : AppColors.border(brightness),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.crimson.withValues(alpha: 0.1)
                    : AppColors.background(brightness),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: value ? AppColors.crimson : AppColors.textSec(brightness),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.crimson,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📊 MODELS
// ═══════════════════════════════════════════════════════════════════════════

class FilterOptions {
  final double maxDistance;
  final double minPayment;
  final double maxPayment;
  final List<String> selectedGenres;
  final List<String> selectedVenueTypes;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool verifiedOnly;
  final bool availableOnly;
  final bool includePrivate;

  FilterOptions({
    this.maxDistance = 50,
    this.minPayment = 100,
    this.maxPayment = 1000,
    this.selectedGenres = const [],
    this.selectedVenueTypes = const [],
    this.dateFrom,
    this.dateTo,
    this.verifiedOnly = false,
    this.availableOnly = true,
    this.includePrivate = true,
  });

  FilterOptions copyWith({
    double? maxDistance,
    double? minPayment,
    double? maxPayment,
    List<String>? selectedGenres,
    List<String>? selectedVenueTypes,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? verifiedOnly,
    bool? availableOnly,
    bool? includePrivate,
  }) {
    return FilterOptions(
      maxDistance: maxDistance ?? this.maxDistance,
      minPayment: minPayment ?? this.minPayment,
      maxPayment: maxPayment ?? this.maxPayment,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      selectedVenueTypes: selectedVenueTypes ?? this.selectedVenueTypes,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      availableOnly: availableOnly ?? this.availableOnly,
      includePrivate: includePrivate ?? this.includePrivate,
    );
  }
}
