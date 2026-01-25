import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 2: VENUE TYPE & BUDGET
///
/// Collecting:
/// - Venue Type (required for matching)
/// - Min-Max budget slider (for price-based matching)
///
/// This step is SKIPPABLE - user can proceed without filling

class Step2Budget extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const Step2Budget({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<Step2Budget> createState() => _Step2BudgetState();
}

class _Step2BudgetState extends State<Step2Budget> {
  String? _selectedVenueType;
  String? _selectedBudgetTier;

  // Budget tiers with min/max values
  final List<Map<String, dynamic>> _budgetTiers = [
    {
      'name': 'Casual',
      'icon': Icons.local_cafe_rounded,
      'min': 50.0,
      'max': 150.0,
      'range': '\$50–150',
    },
    {
      'name': 'Standard',
      'icon': Icons.music_note_rounded,
      'min': 150.0,
      'max': 400.0,
      'range': '\$150–400',
    },
    {
      'name': 'Premium',
      'icon': Icons.star_rounded,
      'min': 400.0,
      'max': 800.0,
      'range': '\$400–800',
    },
    {
      'name': 'VIP',
      'icon': Icons.diamond_rounded,
      'min': 800.0,
      'max': 2000.0,
      'range': '\$800+',
    },
  ];

  // Popular venue types shown first
  final List<VenueType> _venueTypes = [
    VenueType.bar,
    VenueType.restaurant,
    VenueType.club,
    VenueType.lounge,
    VenueType.cafe,
    VenueType.concertHall,
    VenueType.jazzClub,
    VenueType.hotel,
    VenueType.brewery,
    VenueType.winery,
    VenueType.theater,
    VenueType.outdoorVenue,
    VenueType.weddingVenue,
    VenueType.privateEventSpace,
    VenueType.other,
  ];

  @override
  void initState() {
    super.initState();

    // Initialize venue type if already set
    _selectedVenueType = widget.profileData.venueType;

    // Determine which tier is selected based on existing budget
    final existingMin = widget.profileData.gigPreferences.minBudget;
    final existingMax = widget.profileData.gigPreferences.maxBudget;
    if (existingMin > 0 && existingMax > 0) {
      for (var tier in _budgetTiers) {
        if (existingMin == tier['min'] && existingMax == tier['max']) {
          _selectedBudgetTier = tier['name'];
          break;
        }
      }
    }
  }

  void _selectVenueType(VenueType type) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedVenueType = type.displayName;
      widget.profileData.venueType = type.displayName;
    });
    widget.onDataChanged();
  }

  void _selectBudgetTier(Map<String, dynamic> tier) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedBudgetTier = tier['name'];
      widget.profileData.gigPreferences.minBudget = tier['min'];
      widget.profileData.gigPreferences.maxBudget = tier['max'];
    });
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════════════
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.crimson,
                    AppColors.crimson.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              'Almost there!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.text(brightness),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Tell us about your venue',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),

          // ═══════════════════════════════════════════════════════════════
          // VENUE TYPE SECTION
          // ═══════════════════════════════════════════════════════════════
          Row(
            children: [
              Icon(Icons.category_rounded, color: AppColors.crimson, size: 20),
              const SizedBox(width: 8),
              Text(
                'What type of venue?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Venue Type Chips (Fully Rounded)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _venueTypes.map((type) {
              final isSelected = _selectedVenueType == type.displayName;
              return GestureDetector(
                onTap: () => _selectVenueType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.crimson,
                              AppColors.crimson.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? AppColors.graphite : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(50), // Fully rounded
                    border: Border.all(
                      color: isSelected
                          ? AppColors.crimson
                          : (isDark ? AppColors.slate : Colors.grey[300]!),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.crimson.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.text(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // ═══════════════════════════════════════════════════════════════
          // BUDGET TIER SECTION
          // ═══════════════════════════════════════════════════════════════
          Row(
            children: [
              Icon(Icons.payments_rounded, color: AppColors.crimson, size: 20),
              const SizedBox(width: 8),
              Text(
                'Budget per gig',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Budget Tier Cards - 2x2 Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: _budgetTiers.map((tier) {
              final isSelected = _selectedBudgetTier == tier['name'];
              return GestureDetector(
                onTap: () => _selectBudgetTier(tier),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.crimson,
                              AppColors.crimson.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? AppColors.graphite : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.crimson
                          : (isDark ? AppColors.slate : Colors.grey[300]!),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.crimson.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tier['icon'] as IconData,
                        size: 28,
                        color: isSelected ? Colors.white : AppColors.crimson,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tier['name'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.text(brightness),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tier['range'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════════════════════
          // PRO TIP
          // ═══════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.crimson,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose a tier that fits your typical gig budget.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom spacing for button
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
