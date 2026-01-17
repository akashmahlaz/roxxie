import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 3: SCHEDULE, BUDGET & FINALIZE
///
/// Collects:
/// - Event schedule via calendar
/// - Budget range slider
/// - Venue description
/// - Contact person details
/// - Terms agreement

class VenueScheduleBudgetStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;

  const VenueScheduleBudgetStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
  });

  @override
  State<VenueScheduleBudgetStep> createState() => _VenueScheduleBudgetStepState();
}

class _VenueScheduleBudgetStepState extends State<VenueScheduleBudgetStep> {
  late TextEditingController _descriptionController;
  late TextEditingController _contactNameController;
  late TextEditingController _phoneController;
  
  bool _agreedToTerms = false;
  DateTime _selectedMonth = DateTime.now();
  Set<int> _selectedDays = {};

  // Day name mapping
  final List<String> _weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.profileData.description ?? '',
    );
    _contactNameController = TextEditingController(
      text: widget.profileData.contactPerson ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profileData.phone ?? '',
    );
    
    // Initialize budget if not set
    if (widget.profileData.gigPreferences.minBudget == 0) {
      widget.profileData.gigPreferences.minBudget = 150;
      widget.profileData.gigPreferences.maxBudget = 500;
    }
    
    // Initialize selected days from typical event nights
    _initSelectedDays();
  }

  void _initSelectedDays() {
    final typicalNights = widget.profileData.gigPreferences.typicalEventNights;
    // For demonstration - would normally map to actual calendar dates
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  void _toggleDay(int day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstWeekdayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final minBudget = widget.profileData.gigPreferences.minBudget > 0 
        ? widget.profileData.gigPreferences.minBudget 
        : 150.0;
    final maxBudget = widget.profileData.gigPreferences.maxBudget > 0 
        ? widget.profileData.gigPreferences.maxBudget 
        : 500.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // SCHEDULE SECTION
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your schedule',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the days you typically host live music.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Calendar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Month Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _previousMonth,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.charcoal 
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.text(brightness),
                            size: 24,
                          ),
                        ),
                      ),
                      Text(
                        '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(brightness),
                        ),
                      ),
                      GestureDetector(
                        onTap: _nextMonth,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.charcoal 
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.text(brightness),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Weekday Headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekDays.map((day) {
                      return SizedBox(
                        width: 36,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Calendar Grid
                  _buildCalendarGrid(brightness, isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: isDark ? AppColors.slate : Colors.grey[200],
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // BUDGET SECTION
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's your budget?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set your typical range for a live performance.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Budget Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBudgetLabel('Min', minBudget.round(), brightness, isDark),
                      Container(
                        width: 40,
                        height: 2,
                        color: isDark ? AppColors.slate : Colors.grey[300],
                      ),
                      _buildBudgetLabel('Max', maxBudget.round(), brightness, isDark),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Budget Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.crimson,
                      inactiveTrackColor: isDark ? AppColors.slate : Colors.grey[200],
                      thumbColor: AppColors.crimson,
                      overlayColor: AppColors.crimson.withValues(alpha: 0.2),
                      trackHeight: 8,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 14,
                        elevation: 4,
                      ),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                    ),
                    child: RangeSlider(
                      values: RangeValues(minBudget.toDouble(), maxBudget.toDouble()),
                      min: 50,
                      max: 2000,
                      divisions: 39,
                      onChanged: (values) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          widget.profileData.gigPreferences.minBudget = values.start;
                          widget.profileData.gigPreferences.maxBudget = values.end;
                        });
                        widget.onDataChanged();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$50',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                      Text(
                        '\$2000',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: isDark ? AppColors.slate : Colors.grey[200],
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // FINALIZE SECTION
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finalize your profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tell musicians a bit more about your venue.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Venue Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Venue Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.text(brightness),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Describe your venue, its atmosphere, typical crowd...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (value) {
                      widget.profileData.description = value;
                      widget.onDataChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Person
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Person',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _contactNameController,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.text(brightness),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Name of booking manager',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onChanged: (value) {
                            widget.profileData.contactPerson = value;
                            widget.onDataChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Phone Number
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Icon(
                          Icons.phone_outlined,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.text(brightness),
                          ),
                          decoration: InputDecoration(
                            hintText: '+1 (555) 123-4567',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onChanged: (value) {
                            widget.profileData.phone = value;
                            widget.onDataChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Terms Agreement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _agreedToTerms = !_agreedToTerms);
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _agreedToTerms 
                          ? AppColors.crimson 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _agreedToTerms 
                            ? AppColors.crimson 
                            : (isDark ? AppColors.slate : Colors.grey[300]!),
                        width: 2,
                      ),
                    ),
                    child: _agreedToTerms
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: AppColors.crimson,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.crimson,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom padding
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(Brightness brightness, bool isDark) {
    final daysInMonth = _getDaysInMonth(_selectedMonth);
    final firstWeekday = _getFirstWeekdayOfMonth(_selectedMonth);
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final day = cellIndex - firstWeekday + 1;
              
              if (day < 1 || day > daysInMonth) {
                return const SizedBox(width: 36, height: 36);
              }

              final isSelected = _selectedDays.contains(day);
              final isToday = DateTime.now().day == day && 
                             DateTime.now().month == _selectedMonth.month &&
                             DateTime.now().year == _selectedMonth.year;

              return GestureDetector(
                onTap: () => _toggleDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.crimson 
                        : (isToday 
                            ? (isDark ? AppColors.slate : Colors.grey[200])
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                        color: isSelected 
                            ? Colors.white 
                            : AppColors.text(brightness),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildBudgetLabel(String label, int value, Brightness brightness, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '\$$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.crimson,
            ),
          ),
        ),
      ],
    );
  }
}
