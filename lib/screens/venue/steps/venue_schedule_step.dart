import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 5: VENUE SCHEDULE
///
/// Collects:
/// - Weekly operating hours
/// - Typical event nights (chips selection)
/// - Booking lead time preference

class VenueScheduleStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;

  const VenueScheduleStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
  });

  @override
  State<VenueScheduleStep> createState() => _VenueScheduleStepState();
}

class _VenueScheduleStepState extends State<VenueScheduleStep> {
  // Days of the week data
  final List<_DaySchedule> _weekSchedule = [
    _DaySchedule(
      name: 'Monday',
      isOpen: true,
      openTime: '09:00 AM',
      closeTime: '11:00 PM',
    ),
    _DaySchedule(
      name: 'Tuesday',
      isOpen: true,
      openTime: '09:00 AM',
      closeTime: '11:00 PM',
    ),
    _DaySchedule(
      name: 'Wednesday',
      isOpen: true,
      openTime: '09:00 AM',
      closeTime: '11:00 PM',
    ),
    _DaySchedule(
      name: 'Thursday',
      isOpen: true,
      openTime: '09:00 AM',
      closeTime: '11:00 PM',
    ),
    _DaySchedule(
      name: 'Friday',
      isOpen: true,
      openTime: '09:00 AM',
      closeTime: '02:00 AM',
      note: 'Open Late',
    ),
    _DaySchedule(
      name: 'Saturday',
      isOpen: true,
      openTime: '09:00 AM',
      closeTime: '02:00 AM',
      note: 'Open Late',
    ),
    _DaySchedule(name: 'Sunday', isOpen: false),
  ];

  // Typical event nights
  final Set<String> _eventNights = {'Fri', 'Sat', 'Sun'};
  final List<String> _allDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Booking lead time
  String _bookingLeadTime = '2 weeks';
  final List<String> _leadTimeOptions = [
    '1 week',
    '2 weeks',
    '1 month',
    '2 months',
    'No preference',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    // Load existing operating hours if available
    if (widget.profileData.operatingHours.isNotEmpty) {
      for (
        int i = 0;
        i < widget.profileData.operatingHours.length && i < 7;
        i++
      ) {
        final hours = widget.profileData.operatingHours[i];
        _weekSchedule[i].isOpen = hours.isOpen;
        if (hours.openTime != null) {
          _weekSchedule[i].openTime = hours.openTime!;
        }
        if (hours.closeTime != null) {
          _weekSchedule[i].closeTime = hours.closeTime!;
        }
      }
    }

    // Load event nights from gigPreferences if available
    if (widget.profileData.gigPreferences.typicalEventNights.isNotEmpty) {
      _eventNights.clear();
      _eventNights.addAll(widget.profileData.gigPreferences.typicalEventNights);
    }

    // Load booking lead time
    final leadTime = widget.profileData.gigPreferences.bookingLeadTime;
    if (leadTime != null && _leadTimeOptions.contains(leadTime)) {
      _bookingLeadTime = leadTime;
    }
  }

  void _saveData() {
    // Save operating hours
    widget.profileData.operatingHours = _weekSchedule.map((day) {
      return OperatingHours(
        isOpen: day.isOpen,
        openTime: day.isOpen ? day.openTime : null,
        closeTime: day.isOpen ? day.closeTime : null,
      );
    }).toList();

    // Save event nights
    widget.profileData.gigPreferences.typicalEventNights = _eventNights
        .toList();

    // Save booking lead time
    widget.profileData.gigPreferences.bookingLeadTime = _bookingLeadTime;

    widget.onDataChanged();
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
                  'Your Schedule',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set your venue\'s availability and booking preferences.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : const Color(0xFF876464),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════════
          // WEEKLY OPERATING HOURS
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Weekly operating hours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text(brightness),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.graphite.withValues(alpha: 0.4)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
              ),
            ),
            child: Column(
              children: [
                // Only show 4 days for preview (Mon, Tue, Fri, Sun)
                _buildDayRow(_weekSchedule[0], isDark, isFirst: true), // Monday
                _buildDivider(isDark),
                _buildDayRow(_weekSchedule[1], isDark), // Tuesday
                _buildDivider(isDark),
                _buildDayRow(_weekSchedule[4], isDark), // Friday
                _buildDivider(isDark),
                _buildDayRow(_weekSchedule[6], isDark, isLast: true), // Sunday
              ],
            ),
          ),

          // Edit all days button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showEditHoursSheet(context);
              },
              child: Row(
                children: [
                  Icon(Icons.add_rounded, color: AppColors.crimson, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Edit all days',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.crimson,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════════
          // TYPICAL EVENT NIGHTS
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Typical event nights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When do you usually host live music?',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : const Color(0xFF876464),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allDays.map((day) {
                final isSelected = _eventNights.contains(day);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _eventNights.remove(day);
                      } else {
                        _eventNights.add(day);
                      }
                    });
                    _saveData();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.crimson
                          : (isDark
                                ? AppColors.graphite.withValues(alpha: 0.4)
                                : Colors.white),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.crimson
                            : (isDark
                                  ? AppColors.slate
                                  : const Color(0xFFE5DCDC)),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.text(brightness),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // BOOKING LEAD TIME
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking lead time preference',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How far in advance do you like to book gigs?',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : const Color(0xFF876464),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DropdownMenu<String>(
              initialSelection: _bookingLeadTime,
              expandedInsets: EdgeInsets.zero,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: isDark
                    ? AppColors.graphite.withValues(alpha: 0.4)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              menuStyle: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(
                  isDark ? AppColors.graphite : Colors.white,
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              textStyle: TextStyle(
                fontSize: 16,
                color: AppColors.text(brightness),
              ),
              trailingIcon: Icon(
                Icons.expand_more_rounded,
                color: isDark ? Colors.grey[400] : const Color(0xFF876464),
              ),
              selectedTrailingIcon: Icon(
                Icons.expand_less_rounded,
                color: isDark ? Colors.grey[400] : const Color(0xFF876464),
              ),
              dropdownMenuEntries: _leadTimeOptions.map((option) {
                return DropdownMenuEntry<String>(value: option, label: option);
              }).toList(),
              onSelected: (value) {
                if (value != null) {
                  HapticFeedback.selectionClick();
                  setState(() => _bookingLeadTime = value);
                  _saveData();
                }
              },
            ),
          ),

          // Bottom padding for safe area
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildDayRow(
    _DaySchedule day,
    bool isDark, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Opacity(
      opacity: day.isOpen ? 1.0 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => day.isOpen = !day.isOpen);
                _saveData();
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: day.isOpen ? AppColors.crimson : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: day.isOpen
                        ? AppColors.crimson
                        : (isDark ? AppColors.slate : const Color(0xFFE5DCDC)),
                    width: 2,
                  ),
                ),
                child: day.isOpen
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Day info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(
                        isDark ? Brightness.dark : Brightness.light,
                      ),
                    ),
                  ),
                  Text(
                    day.isOpen ? (day.note ?? 'Open') : 'Closed',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey[400]
                          : const Color(0xFF876464),
                    ),
                  ),
                ],
              ),
            ),
            // Time slots
            if (day.isOpen) ...[
              _buildTimeChip(day.openTime!, isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'to',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : const Color(0xFF876464),
                  ),
                ),
              ),
              _buildTimeChip(day.closeTime!, isDark),
            ] else
              Text(
                'No hours set',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey[500] : const Color(0xFF876464),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String time, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate : const Color(0xFFF8F6F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
        ),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.text(isDark ? Brightness.dark : Brightness.light),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = parts[1];

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  void _showEditHoursSheet(BuildContext context) {
    // Create a copy of the schedule for editing
    final tempSchedule = _weekSchedule.map((day) => day.copy()).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Operating Hours',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(
                              isDark ? Brightness.dark : Brightness.light,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
                  ),

                  // List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: tempSchedule.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.slate.withValues(alpha: 0.5)
                            : const Color(0xFFE5DCDC).withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        return _buildEditableDayRow(
                          tempSchedule[index],
                          isDark,
                          setSheetState,
                        );
                      },
                    ),
                  ),

                  // Save Button
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () {
                          // Save changes
                          setState(() {
                            for (int i = 0; i < _weekSchedule.length; i++) {
                              _weekSchedule[i] = tempSchedule[i];
                            }
                            _saveData();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.crimson,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditableDayRow(
    _DaySchedule day,
    bool isDark,
    StateSetter setSheetState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setSheetState(() => day.isOpen = !day.isOpen);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: day.isOpen ? AppColors.crimson : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: day.isOpen
                          ? AppColors.crimson
                          : (isDark
                                ? AppColors.slate
                                : const Color(0xFFE5DCDC)),
                      width: 2,
                    ),
                  ),
                  child: day.isOpen
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Day Name
              SizedBox(
                width: 100,
                child: Text(
                  day.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text(
                      isDark ? Brightness.dark : Brightness.light,
                    ),
                  ),
                ),
              ),

              // Status (Closed)
              if (!day.isOpen)
                Text(
                  'Closed',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[500] : const Color(0xFF876464),
                  ),
                ),
            ],
          ),

          // Time Pickers (only if open)
          if (day.isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 40), // Align with text
                _buildTimePickerChip(
                  context,
                  day.openTime ?? '09:00 AM',
                  isDark,
                  (newTime) => setSheetState(() => day.openTime = newTime),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'to',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.grey[400]
                          : const Color(0xFF876464),
                    ),
                  ),
                ),
                _buildTimePickerChip(
                  context,
                  day.closeTime ?? '11:00 PM',
                  isDark,
                  (newTime) => setSheetState(() => day.closeTime = newTime),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerChip(
    BuildContext context,
    String time,
    bool isDark,
    Function(String) onTimeChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final initialTime =
            _parseTimeOfDay(time) ?? const TimeOfDay(hour: 9, minute: 0);
        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            return Theme(
              data: isDark
                  ? ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.crimson,
                        surface: AppColors.charcoal,
                        onSurface: Colors.white,
                      ),
                    )
                  : ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.crimson,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          onTimeChanged(_formatTimeOfDay(picked));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.graphite : const Color(0xFFF8F6F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.text(
                  isDark ? Brightness.dark : Brightness.light,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.access_time_rounded,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal model for day schedule
class _DaySchedule {
  String name;
  bool isOpen;
  String? openTime;
  String? closeTime;
  String? note;

  _DaySchedule({
    required this.name,
    this.isOpen = true,
    this.openTime,
    this.closeTime,
    this.note,
  });

  _DaySchedule copy() {
    return _DaySchedule(
      name: name,
      isOpen: isOpen,
      openTime: openTime,
      closeTime: closeTime,
      note: note,
    );
  }
}
