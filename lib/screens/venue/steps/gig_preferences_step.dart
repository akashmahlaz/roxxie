
import 'package:flutter/material.dart';

import '../../../core/constants/music_genres.dart';
import '../../../core/models/venue_models.dart';
import '../../../core/theme/theme.dart';



/// 🎵 STEP 4: GIG PREFERENCES
///
/// Collects:
/// - Preferred genres
/// - Budget range
/// - Typical performance slots
/// - Set length preferences
/// - What venue provides (accommodation, meals, equipment)

class GigPreferencesStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const GigPreferencesStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<GigPreferencesStep> createState() => _GigPreferencesStepState();
}

class _GigPreferencesStepState extends State<GigPreferencesStep> {
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'INR'];
  final List<int> _setLengths = [30, 45, 60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preferred Genres
          _buildSectionTitle(
            'Preferred Genres',
            'What kind of music fits your venue?',
            brightness,
          ),
          const SizedBox(height: 14),
          _buildGenreSelector(brightness),

          const SizedBox(height: 32),

          // Budget Range
          _buildSectionTitle(
            'Budget Range',
            'What\'s your typical payment for artists?',
            brightness,
          ),
          const SizedBox(height: 14),
          _buildBudgetSection(brightness),

          const SizedBox(height: 32),

          // Performance Slots
          _buildSectionTitle(
            'Typical Performance Slots',
            'When do artists usually perform?',
            brightness,
          ),
          const SizedBox(height: 14),
          _buildSlotSelector(brightness),

          const SizedBox(height: 32),

          // Set Length
          _buildSectionTitle(
            'Typical Set Length',
            'How long should performances be?',
            brightness,
          ),
          const SizedBox(height: 14),
          _buildSetLengthSelector(brightness),

          const SizedBox(height: 32),

          // What Venue Provides
          _buildSectionTitle(
            'What You Provide',
            'Extra perks for artists',
            brightness,
          ),
          const SizedBox(height: 14),
          _buildPerksSection(brightness),

          const SizedBox(height: 40),

          // Navigation Buttons
          _buildNavigationButtons(brightness),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    String subtitle,
    Brightness brightness,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildGenreSelector(Brightness brightness) {
    return Column(
      children: [
        // Selected count
        if (widget.profileData.preferredGenres.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.crimson,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.profileData.preferredGenres.length} genres selected',
                  style: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: MusicGenres.genres.map((genre) {
            final isSelected = widget.profileData.preferredGenres.contains(
              genre,
            );
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    widget.profileData.preferredGenres.remove(genre);
                  } else {
                    widget.profileData.preferredGenres.add(genre);
                  }
                });
                widget.onDataChanged();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.crimson.withValues(alpha: 0.15)
                      : AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.border(brightness),
                  ),
                ),
                child: Text(
                  genre,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.text(brightness),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBudgetSection(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        children: [
          // Currency Selector
          Row(
            children: [
              Text(
                'Currency',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background(brightness),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.profileData.currency,
                    dropdownColor: AppColors.surface(brightness),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSec(brightness),
                    ),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(
                          currency,
                          style: TextStyle(color: AppColors.text(brightness)),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        widget.profileData.currency = value ?? 'USD';
                      });
                      widget.onDataChanged();
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Budget Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetLabel(
                'Min',
                widget.profileData.minBudget,
                brightness,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_getCurrencySymbol()}${widget.profileData.minBudget.toInt()} - ${_getCurrencySymbol()}${widget.profileData.maxBudget.toInt()}',
                  style: const TextStyle(
                    color: AppColors.crimson,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildBudgetLabel(
                'Max',
                widget.profileData.maxBudget,
                brightness,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Range Slider
          RangeSlider(
            values: RangeValues(
              widget.profileData.minBudget,
              widget.profileData.maxBudget,
            ),
            min: 0,
            max: 10000,
            divisions: 100,
            activeColor: AppColors.crimson,
            inactiveColor: AppColors.border(brightness),
            onChanged: (values) {
              setState(() {
                widget.profileData.minBudget = values.start;
                widget.profileData.maxBudget = values.end;
              });
              widget.onDataChanged();
            },
          ),

          // Budget Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getCurrencySymbol()}0',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              Text(
                '${_getCurrencySymbol()}10,000+',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetLabel(String label, double value, Brightness brightness) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 12),
        ),
        Text(
          '${_getCurrencySymbol()}${value.toInt()}',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getCurrencySymbol() {
    switch (widget.profileData.currency) {
      case 'USD':
      case 'CAD':
      case 'AUD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      default:
        return '\$';
    }
  }

  Widget _buildSlotSelector(Brightness brightness) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: PerformanceSlots.slots.map((slot) {
        final isSelected = widget.profileData.typicalSlots.contains(slot);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                widget.profileData.typicalSlots.remove(slot);
              } else {
                widget.profileData.typicalSlots.add(slot);
              }
            });
            widget.onDataChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimson.withValues(alpha: 0.15)
                  : AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.border(brightness),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.access_time_rounded,
                  size: 16,
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.textSec(brightness),
                ),
                const SizedBox(width: 6),
                Text(
                  slot,
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
    );
  }

  Widget _buildSetLengthSelector(Brightness brightness) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _setLengths.map((length) {
        final isSelected = widget.profileData.typicalSetLength == length;
        final label = length < 60
            ? '$length min'
            : '${length ~/ 60}${length % 60 > 0 ? '.5' : ''} hr${length >= 120 ? 's' : ''}';

        return GestureDetector(
          onTap: () {
            setState(() {
              widget.profileData.typicalSetLength = length;
            });
            widget.onDataChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimson.withValues(alpha: 0.15)
                  : AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.border(brightness),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.text(brightness),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPerksSection(Brightness brightness) {
    return Column(
      children: [
        _buildPerkToggle(
          'Accommodation',
          'Provide lodging for artists',
          Icons.hotel_rounded,
          widget.profileData.providesAccommodation,
          (value) {
            setState(() {
              widget.profileData.providesAccommodation = value;
            });
            widget.onDataChanged();
          },
          brightness,
        ),
        const SizedBox(height: 12),
        _buildPerkToggle(
          'Meals',
          'Provide food for artists',
          Icons.restaurant_rounded,
          widget.profileData.providesMeals,
          (value) {
            setState(() {
              widget.profileData.providesMeals = value;
            });
            widget.onDataChanged();
          },
          brightness,
        ),
        const SizedBox(height: 12),
        _buildPerkToggle(
          'Equipment',
          'Provide backline/equipment',
          Icons.speaker_rounded,
          widget.profileData.providesEquipment,
          (value) {
            setState(() {
              widget.profileData.providesEquipment = value;
            });
            widget.onDataChanged();
          },
          brightness,
        ),
      ],
    );
  }

  Widget _buildPerkToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Brightness brightness,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value
              ? AppColors.crimson.withValues(alpha: 0.08)
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppColors.crimson : AppColors.border(brightness),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.crimson.withValues(alpha: 0.15)
                    : AppColors.background(brightness),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: value
                    ? AppColors.crimson
                    : AppColors.textSec(brightness),
                size: 22,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.crimson : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value
                      ? AppColors.crimson
                      : AppColors.border(brightness),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(Brightness brightness) {
    return Row(
      children: [
        // Back Button
        Expanded(
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.text(brightness),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Continue Button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: widget.onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
