import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../artist_profile_setup_screen.dart';

/// Step 4: Availability & Pricing
/// - Availability Calendar (select available dates/times)
/// - Price Range (min-max per gig)
/// - Currency selection

class AvailabilityPricingStep extends StatefulWidget {
  final ArtistProfileData profileData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AvailabilityPricingStep({
    super.key,
    required this.profileData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<AvailabilityPricingStep> createState() =>
      _AvailabilityPricingStepState();
}

class _AvailabilityPricingStepState extends State<AvailabilityPricingStep> {
  late DateTime _selectedMonth;
  final Set<DateTime> _selectedDates = {};
  TimeOfDay _defaultStartTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _defaultEndTime = const TimeOfDay(hour: 23, minute: 0);

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'INR'];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();

    // Pre-populate selected dates from existing availability
    for (var slot in widget.profileData.availability) {
      _selectedDates.add(
        DateTime(slot.date.year, slot.date.month, slot.date.day),
      );
    }
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (_selectedDates.contains(normalizedDate)) {
        _selectedDates.remove(normalizedDate);
        widget.profileData.availability.removeWhere(
          (slot) =>
              slot.date.year == date.year &&
              slot.date.month == date.month &&
              slot.date.day == date.day,
        );
      } else {
        _selectedDates.add(normalizedDate);
        widget.profileData.availability.add(
          AvailabilitySlot(
            date: normalizedDate,
            startTime: _defaultStartTime,
            endTime: _defaultEndTime,
          ),
        );
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  Future<void> _selectDefaultTimes() async {
    final brightness = Theme.of(context).brightness;

    final startTime = await showTimePicker(
      context: context,
      initialTime: _defaultStartTime,
      helpText: 'Default Start Time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.crimson,
              surface: AppColors.cardBackground(brightness),
            ),
          ),
          child: child!,
        );
      },
    );

    if (startTime != null && mounted) {
      final endTime = await showTimePicker(
        context: context,
        initialTime: _defaultEndTime,
        helpText: 'Default End Time',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.crimson,
                surface: AppColors.cardBackground(brightness),
              ),
            ),
            child: child!,
          );
        },
      );

      if (endTime != null) {
        setState(() {
          _defaultStartTime = startTime;
          _defaultEndTime = endTime;

          // Update all existing slots with new default times
          for (var slot in widget.profileData.availability) {
            slot = AvailabilitySlot(
              date: slot.date,
              startTime: startTime,
              endTime: endTime,
              isBooked: slot.isBooked,
            );
          }
        });
      }
    }
  }

  void _validateAndContinue() {
    // Availability is optional, but pricing is needed
    if (widget.profileData.minPrice > widget.profileData.maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Minimum price cannot exceed maximum price'),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Availability Calendar Section
          _buildSectionTitle(
            'Availability',
            brightness,
            icon: Icons.calendar_month_rounded,
            subtitle: 'Select dates when you\'re available for gigs',
          ),

          const SizedBox(height: 16),

          // Default time slot
          _buildDefaultTimeSlot(brightness),

          const SizedBox(height: 16),

          // Calendar
          _buildCalendar(brightness),

          const SizedBox(height: 8),

          // Selected dates count
          _buildSelectedDatesInfo(brightness),

          const SizedBox(height: 28),

          // Pricing Section
          _buildSectionTitle(
            'Pricing',
            brightness,
            icon: Icons.attach_money_rounded,
            subtitle: 'Set your price range per gig',
          ),

          const SizedBox(height: 16),

          // Currency selector
          _buildCurrencySelector(brightness),

          const SizedBox(height: 16),

          // Price range slider
          _buildPriceRangeSlider(brightness),

          const SizedBox(height: 16),

          // Price inputs
          _buildPriceInputs(brightness),

          const SizedBox(height: 32),

          // Navigation Buttons
          _buildNavigationButtons(brightness),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    Brightness brightness, {
    IconData? icon,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.crimson, size: 20),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
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
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultTimeSlot(Brightness brightness) {
    return GestureDetector(
      onTap: _selectDefaultTimes,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: AppColors.crimson,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Time Slot',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatTime(_defaultStartTime)} - ${_formatTime(_defaultEndTime)}',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_rounded,
              color: AppColors.textTert(brightness),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.text(brightness),
                ),
              ),
              Text(
                _formatMonth(_selectedMonth),
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.text(brightness),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (day) => SizedBox(
                    width: 36,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textTert(brightness),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 8),

          // Calendar grid
          _buildCalendarGrid(brightness),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(Brightness brightness) {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Add empty cells for days before the first day of month
    for (int i = 0; i < firstWeekday; i++) {
      currentRow.add(const SizedBox(width: 36, height: 36));
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isSelected = _selectedDates.contains(date);
      final isPast = date.isBefore(todayNormalized);
      final isToday = date.isAtSameMomentAs(todayNormalized);

      currentRow.add(
        GestureDetector(
          onTap: isPast ? null : () => _toggleDate(date),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimson
                  : isToday
                  ? AppColors.crimson.withValues(alpha: 0.15)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isPast
                      ? AppColors.textTert(brightness).withValues(alpha: 0.5)
                      : isSelected
                      ? Colors.white
                      : AppColors.text(brightness),
                  fontSize: 14,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      );

      if (currentRow.length == 7) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: currentRow,
            ),
          ),
        );
        currentRow = [];
      }
    }

    // Add remaining cells
    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const SizedBox(width: 36, height: 36));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: currentRow,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildSelectedDatesInfo(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.crimson.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.crimson,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            '${_selectedDates.length} date${_selectedDates.length == 1 ? '' : 's'} selected',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_selectedDates.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDates.clear();
                  widget.profileData.availability.clear();
                });
              },
              child: Text(
                'Clear all',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Row(
        children: _currencies.map((currency) {
          final isSelected = widget.profileData.currency == currency;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  widget.profileData.currency = currency;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.crimson : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currency,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSec(brightness),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceRangeSlider(Brightness brightness) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.crimson,
            inactiveTrackColor: AppColors.border(brightness),
            thumbColor: AppColors.crimson,
            overlayColor: AppColors.crimson.withValues(alpha: 0.2),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            trackHeight: 6,
          ),
          child: RangeSlider(
            values: RangeValues(
              widget.profileData.minPrice,
              widget.profileData.maxPrice,
            ),
            min: 0,
            max: 2000,
            divisions: 40,
            onChanged: (values) {
              setState(() {
                widget.profileData.minPrice = values.start;
                widget.profileData.maxPrice = values.end;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_getCurrencySymbol()}0',
              style: TextStyle(
                color: AppColors.textTert(brightness),
                fontSize: 11,
              ),
            ),
            Text(
              '${_getCurrencySymbol()}2000+',
              style: TextStyle(
                color: AppColors.textTert(brightness),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceInputs(Brightness brightness) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minimum',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputFill(brightness),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: Row(
                  children: [
                    Text(
                      _getCurrencySymbol(),
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.profileData.minPrice.toInt().toString(),
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '—',
            style: TextStyle(
              color: AppColors.textTert(brightness),
              fontSize: 20,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Maximum',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputFill(brightness),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: Row(
                  children: [
                    Text(
                      _getCurrencySymbol(),
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.profileData.maxPrice.toInt().toString(),
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(Brightness brightness) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Center(
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _validateAndContinue,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.crimson,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                      fontWeight: FontWeight.w700,
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
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
}
