import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 2: BUDGET
/// 
/// Minimal step collecting budget range for matching:
/// - Min-Max budget slider → For price-based matching
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
  late double _minBudget;
  late double _maxBudget;

  @override
  void initState() {
    super.initState();
    // Initialize with existing values or defaults
    _minBudget = widget.profileData.gigPreferences.minBudget > 0 
        ? widget.profileData.gigPreferences.minBudget 
        : 100;
    _maxBudget = widget.profileData.gigPreferences.maxBudget > 0 
        ? widget.profileData.gigPreferences.maxBudget 
        : 500;
    
    // Ensure values are set in model
    widget.profileData.gigPreferences.minBudget = _minBudget;
    widget.profileData.gigPreferences.maxBudget = _maxBudget;
  }

  String _formatBudget(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}k';
    }
    return '\$${value.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════════════
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.crimson,
                    AppColors.crimson.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: Text(
              "What's your budget?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text(brightness),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Set your typical range per performance',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),

          // ═══════════════════════════════════════════════════════════════
          // BUDGET DISPLAY
          // ═══════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.graphite : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? AppColors.slate : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Min & Max Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBudgetDisplay('Min', _minBudget, brightness, isDark),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.charcoal : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'to',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _buildBudgetDisplay('Max', _maxBudget, brightness, isDark),
                  ],
                ),
                const SizedBox(height: 40),

                // Range Slider
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.crimson,
                    inactiveTrackColor: isDark 
                        ? AppColors.slate.withValues(alpha: 0.5) 
                        : Colors.grey[200],
                    thumbColor: AppColors.crimson,
                    overlayColor: AppColors.crimson.withValues(alpha: 0.15),
                    trackHeight: 10,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 16,
                      elevation: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: 16,
                      elevation: 6,
                    ),
                    rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                  ),
                  child: RangeSlider(
                    values: RangeValues(_minBudget, _maxBudget),
                    min: 50,
                    max: 2000,
                    divisions: 39,
                    onChanged: (values) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _minBudget = values.start;
                        _maxBudget = values.end;
                        widget.profileData.gigPreferences.minBudget = _minBudget;
                        widget.profileData.gigPreferences.maxBudget = _maxBudget;
                      });
                      widget.onDataChanged();
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Range Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$50',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$2,000',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // INFO CARD
          // ═══════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.crimson,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pro tip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.crimson,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A wider range helps you match with more artists. You can always negotiate the final price.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // COMPLETION MESSAGE
          // ═══════════════════════════════════════════════════════════════
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green[400],
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  "You're all set!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(brightness),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your profile to start matching\nwith musicians in your area.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Bottom spacing for button
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildBudgetDisplay(String label, double value, Brightness brightness, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.crimson,
                AppColors.crimson.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _formatBudget(value),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
