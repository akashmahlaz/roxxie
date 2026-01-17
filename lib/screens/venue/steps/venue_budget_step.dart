import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 6: VENUE BUDGET & PAYMENTS
///
/// Collects:
/// - Budget range (min-max slider)
/// - Payment terms (per show, monthly, per hour)
/// - Artist perks (meals, drinks, stay, promo)

class VenueBudgetStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;

  const VenueBudgetStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
  });

  @override
  State<VenueBudgetStep> createState() => _VenueBudgetStepState();
}

class _VenueBudgetStepState extends State<VenueBudgetStep> {
  // Budget range
  late RangeValues _budgetRange;
  static const double _minBudget = 0;
  static const double _maxBudget = 2000;

  // Payment terms
  String _paymentTerm = 'per_show';
  final List<_PaymentOption> _paymentOptions = [
    _PaymentOption(
      id: 'per_show',
      title: 'Per show',
      icon: Icons.payments_rounded,
    ),
    _PaymentOption(
      id: 'monthly',
      title: 'Monthly contract',
      icon: Icons.calendar_today_rounded,
    ),
    _PaymentOption(
      id: 'per_hour',
      title: 'Per hour',
      icon: Icons.schedule_rounded,
    ),
  ];

  // Artist perks
  final Set<String> _selectedPerks = {'meals', 'drinks'};
  final List<_PerkOption> _perkOptions = [
    _PerkOption(id: 'meals', title: 'Meals', icon: Icons.restaurant_rounded),
    _PerkOption(id: 'drinks', title: 'Drinks', icon: Icons.local_bar_rounded),
    _PerkOption(id: 'accommodation', title: 'Stay', icon: Icons.hotel_rounded),
    _PerkOption(id: 'promotion', title: 'Promo', icon: Icons.campaign_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    // Load budget range
    final minBudget = widget.profileData.gigPreferences.minBudget;
    final maxBudget = widget.profileData.gigPreferences.maxBudget;
    _budgetRange = RangeValues(
      minBudget > 0 ? minBudget : 150,
      maxBudget > 0 ? maxBudget : 650,
    );

    // Load payment term
    final paymentTerm = widget.profileData.gigPreferences.paymentTerm;
    if (paymentTerm != null && _paymentOptions.any((o) => o.id == paymentTerm)) {
      _paymentTerm = paymentTerm;
    }

    // Load perks
    _selectedPerks.clear();
    if (widget.profileData.gigPreferences.providesMusicianMeals) {
      _selectedPerks.add('meals');
    }
    if (widget.profileData.gigPreferences.providesDrinks) {
      _selectedPerks.add('drinks');
    }
    if (widget.profileData.gigPreferences.providesAccommodation) {
      _selectedPerks.add('accommodation');
    }
    if (widget.profileData.gigPreferences.providesPromotion) {
      _selectedPerks.add('promotion');
    }
    
    // Default to meals and drinks if nothing selected
    if (_selectedPerks.isEmpty) {
      _selectedPerks.addAll({'meals', 'drinks'});
    }
  }

  void _saveData() {
    // Save budget
    widget.profileData.gigPreferences.minBudget = _budgetRange.start;
    widget.profileData.gigPreferences.maxBudget = _budgetRange.end;

    // Save payment term
    widget.profileData.gigPreferences.paymentTerm = _paymentTerm;

    // Save perks
    widget.profileData.gigPreferences.providesMusicianMeals = _selectedPerks.contains('meals');
    widget.profileData.gigPreferences.providesDrinks = _selectedPerks.contains('drinks');
    widget.profileData.gigPreferences.providesAccommodation = _selectedPerks.contains('accommodation');
    widget.profileData.gigPreferences.providesPromotion = _selectedPerks.contains('promotion');

    widget.onDataChanged();
  }

  String get _budgetDisplayText {
    final currency = widget.profileData.gigPreferences.currency;
    final symbol = currency == 'GBP' ? '£' : (currency == 'EUR' ? '€' : '\$');
    return '$symbol${_budgetRange.start.toInt()} - $symbol${_budgetRange.end.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gig Budget & Payments',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set your financial expectations to attract the right talent for your venue.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : AppColors.text(brightness).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // BUDGET RANGE SECTION
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Estimated Budget Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text(brightness),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Budget slider card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : const Color(0xFFF8F6F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Budget label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget per gig',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text(brightness),
                      ),
                    ),
                    Text(
                      _budgetDisplayText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.crimson,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Range slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.crimson,
                    inactiveTrackColor: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
                    thumbColor: Colors.white,
                    overlayColor: AppColors.crimson.withValues(alpha: 0.2),
                    trackHeight: 6,
                    thumbShape: _CustomThumbShape(),
                    rangeThumbShape: _CustomRangeThumbShape(),
                  ),
                  child: RangeSlider(
                    values: _budgetRange,
                    min: _minBudget,
                    max: _maxBudget,
                    divisions: 40,
                    onChanged: (values) {
                      HapticFeedback.selectionClick();
                      setState(() => _budgetRange = values);
                      _saveData();
                    },
                  ),
                ),

                // Min/Max labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${_budgetRange.start.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : AppColors.text(brightness).withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '\$${_budgetRange.end.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : AppColors.text(brightness).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // PAYMENT TERMS SECTION
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Payment Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text(brightness),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: _paymentOptions.map((option) {
                final isSelected = _paymentTerm == option.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _paymentTerm = option.id);
                      _saveData();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.crimson.withValues(alpha: 0.05)
                            : (isDark ? AppColors.graphite.withValues(alpha: 0.5) : const Color(0xFFF8F6F6)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.crimson : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option.icon,
                            color: isSelected
                                ? AppColors.crimson
                                : (isDark ? Colors.grey[400] : AppColors.text(brightness).withValues(alpha: 0.6)),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: AppColors.text(brightness),
                              ),
                            ),
                          ),
                          // Radio indicator
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.crimson : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.crimson
                                    : (isDark ? AppColors.slate : const Color(0xFFE5DCDC)),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // ARTIST PERKS SECTION
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Artist Perks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text(brightness),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: _perkOptions.map((perk) {
                final isSelected = _selectedPerks.contains(perk.id);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedPerks.remove(perk.id);
                      } else {
                        _selectedPerks.add(perk.id);
                      }
                    });
                    _saveData();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.crimson.withValues(alpha: 0.05)
                          : (isDark ? AppColors.graphite.withValues(alpha: 0.5) : const Color(0xFFF8F6F6)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.crimson : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          perk.icon,
                          color: isSelected
                              ? AppColors.crimson
                              : (isDark ? Colors.grey[400] : AppColors.text(brightness).withValues(alpha: 0.6)),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            perk.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text(brightness),
                            ),
                          ),
                        ),
                        // Checkbox indicator
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.crimson : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.crimson
                                  : (isDark ? AppColors.slate : const Color(0xFFE5DCDC)),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom padding for safe area
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

/// Custom thumb shape for the range slider
class _CustomThumbShape extends RoundSliderThumbShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(24, 24);
  }
}

class _CustomRangeThumbShape extends RoundRangeSliderThumbShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(24, 24);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;
    
    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 2), 12, shadowPaint);
    
    // Draw white circle with border
    final fillPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 12, fillPaint);
    
    // Draw crimson border
    final borderPaint = Paint()
      ..color = AppColors.crimson
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, 10, borderPaint);
  }
}

class _PaymentOption {
  final String id;
  final String title;
  final IconData icon;

  _PaymentOption({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class _PerkOption {
  final String id;
  final String title;
  final IconData icon;

  _PerkOption({
    required this.id,
    required this.title,
    required this.icon,
  });
}
