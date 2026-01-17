import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/artist_models.dart';
import '../../../core/theme/theme.dart';

/// 🎸 ARTIST STEP 2: PERFORMANCE TYPE & BUDGET
/// 
/// Features:
/// - Performance type selection (Solo, Duo, Band, DJ, etc)
/// - Budget tier selection (similar to venue)
/// 
/// This step is SKIPPABLE - user can proceed without filling

class ArtistStep2BudgetType extends StatefulWidget {
  final ArtistProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const ArtistStep2BudgetType({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<ArtistStep2BudgetType> createState() => _ArtistStep2BudgetTypeState();
}

class _ArtistStep2BudgetTypeState extends State<ArtistStep2BudgetType> {
  String? _selectedPerformanceType;
  String? _selectedBudgetTier;

  // Performance types
  final List<Map<String, dynamic>> _performanceTypes = [
    {'name': 'Solo', 'icon': Icons.person_rounded, 'desc': 'Single performer'},
    {'name': 'Duo', 'icon': Icons.people_rounded, 'desc': '2 musicians'},
    {'name': 'Band', 'icon': Icons.groups_rounded, 'desc': '3+ members'},
    {'name': 'DJ', 'icon': Icons.album_rounded, 'desc': 'Electronic/mixing'},
    {'name': 'Orchestra', 'icon': Icons.piano_rounded, 'desc': 'Large ensemble'},
    {'name': 'Other', 'icon': Icons.music_note_rounded, 'desc': 'Other type'},
  ];

  // Budget tiers with min/max values
  final List<Map<String, dynamic>> _budgetTiers = [
    {'name': 'Starting', 'icon': Icons.local_cafe_rounded, 'min': 50.0, 'max': 150.0, 'range': '\$50–150'},
    {'name': 'Standard', 'icon': Icons.music_note_rounded, 'min': 150.0, 'max': 400.0, 'range': '\$150–400'},
    {'name': 'Premium', 'icon': Icons.star_rounded, 'min': 400.0, 'max': 800.0, 'range': '\$400–800'},
    {'name': 'Pro', 'icon': Icons.diamond_rounded, 'min': 800.0, 'max': 2000.0, 'range': '\$800+'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize from existing data
    _selectedPerformanceType = widget.profileData.bandSize != null
        ? _getPerformanceTypeFromBandSize(widget.profileData.bandSize!)
        : null;
    
    // Determine which tier is selected based on existing budget
    final existingMin = widget.profileData.minPrice;
    final existingMax = widget.profileData.maxPrice;
    if (existingMin > 0 && existingMax > 0) {
      for (var tier in _budgetTiers) {
        if (existingMin == tier['min'] && existingMax == tier['max']) {
          _selectedBudgetTier = tier['name'];
          break;
        }
      }
    }
  }

  String? _getPerformanceTypeFromBandSize(int size) {
    if (size == 1) return 'Solo';
    if (size == 2) return 'Duo';
    if (size >= 3 && size <= 8) return 'Band';
    if (size > 8) return 'Orchestra';
    return null;
  }

  int _getBandSizeFromType(String type) {
    switch (type) {
      case 'Solo': return 1;
      case 'Duo': return 2;
      case 'Band': return 4;
      case 'DJ': return 1;
      case 'Orchestra': return 10;
      default: return 1;
    }
  }

  void _selectPerformanceType(Map<String, dynamic> type) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPerformanceType = type['name'];
      widget.profileData.bandSize = _getBandSizeFromType(type['name']);
    });
    widget.onDataChanged();
  }

  void _selectBudgetTier(Map<String, dynamic> tier) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedBudgetTier = tier['name'];
      widget.profileData.minPrice = tier['min'];
      widget.profileData.maxPrice = tier['max'];
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
                Icons.music_note_rounded,
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
              'Tell venues about your act',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),

          // ═══════════════════════════════════════════════════════════════
          // PERFORMANCE TYPE SECTION
          // ═══════════════════════════════════════════════════════════════
          Row(
            children: [
              Icon(
                Icons.mic_rounded,
                color: AppColors.crimson,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'What type of act?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Performance Type Chips (Fully Rounded)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _performanceTypes.map((type) {
              final isSelected = _selectedPerformanceType == type['name'];
              return GestureDetector(
                onTap: () => _selectPerformanceType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                      Icon(
                        type['icon'] as IconData,
                        size: 18,
                        color: isSelected 
                            ? Colors.white 
                            : AppColors.crimson,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
              Icon(
                Icons.payments_rounded,
                color: AppColors.crimson,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your typical rate',
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
                        color: isSelected 
                            ? Colors.white 
                            : AppColors.crimson,
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
                    'You can adjust your rates anytime in your profile settings.',
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
