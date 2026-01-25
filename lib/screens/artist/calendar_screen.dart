/// 📅 Artist Calendar Screen - PROFESSIONAL VERSION
///
/// Features:
/// - Real-time backend integration
/// - View availability slots & booked gigs
/// - Add/Edit/Delete availability
/// - Professional UI with loading states
/// - Pull to refresh
library;

import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/services/calendar_service.dart';
import '../../widgets/time_range_picker.dart';

class ArtistCalendarScreen extends StatefulWidget {
  const ArtistCalendarScreen({super.key});

  @override
  State<ArtistCalendarScreen> createState() => _ArtistCalendarScreenState();
}

class _ArtistCalendarScreenState extends State<ArtistCalendarScreen> {
  final CalendarService _calendarService = CalendarService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  CalendarResponse? _calendarData;
  bool _isLoading = true;
  String? _errorMessage;

  // Date formatters
  static const _weekdays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  static const _weekdaysShort = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _months = [
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

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load current month + buffer
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final data = await _calendarService.getCalendar(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _calendarData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatWeekday(DateTime date) => _weekdays[date.weekday % 7];
  String _formatMonthDay(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';
  String _formatMonthYear(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta);
    });
    _loadCalendar();
  }

  List<CalendarEvent> _getEventsForDay(DateTime date) {
    return _calendarData?.getEventsForDate(date) ?? [];
  }

  /// Get last week's availability for the same day
  GigTimeSlot? _getLastWeekSlot(DateTime date) {
    final lastWeekDate = date.subtract(const Duration(days: 7));
    final lastWeekEvents = _getEventsForDay(lastWeekDate);

    for (final event in lastWeekEvents) {
      if (event.eventType == CalendarEventType.availability) {
        // Convert to GigTimeSlot
        return GigTimeSlot.fromTimeStrings(
          date: date,
          startTime: event.displayStartTime,
          endTime: event.displayEndTime,
        );
      }
    }
    return null;
  }

  /// Get existing availability slots for the current date (for conflict detection)
  List<AvailabilitySlot> _getExistingSlotsForDay(DateTime date) {
    final events = _getEventsForDay(date);
    final slots = <AvailabilitySlot>[];

    for (final event in events) {
      if (event.eventType == CalendarEventType.availability) {
        slots.add(
          AvailabilitySlot(
            date: date,
            startTime: event.startTime,
            endTime: event.endTime,
            isOvernight: false, // Will be determined by time comparison
          ),
        );
      }
    }
    return slots;
  }

  /// Parse time string like "10:30 PM" to hour/minute
  // ignore: unused_element
  Map<String, int>? _parseTimeString(String timeStr) {
    try {
      final clean = timeStr.trim().replaceAll('(Next Day)', '').trim();
      final isPM = clean.toUpperCase().contains('PM');
      final parts = clean.replaceAll(RegExp(r'[APMapm]'), '').trim().split(':');

      int hour = int.parse(parts[0].trim());
      int minute = parts.length > 1 ? int.parse(parts[1].trim()) : 0;

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return {'hour': hour, 'minute': minute};
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.background(brightness),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Calendar',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          // Stats indicator
          if (_calendarData != null && !_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatDot(
                    color: AppColors.success,
                    count: _calendarData!.availableCount,
                  ),
                  const SizedBox(width: 8),
                  _StatDot(
                    color: AppColors.crimson,
                    count: _calendarData!.bookedCount,
                  ),
                  if (_calendarData!.blockedCount > 0) ...[
                    const SizedBox(width: 8),
                    _StatDot(
                      color: AppColors.textDisabled,
                      count: _calendarData!.blockedCount,
                    ),
                  ],
                ],
              ),
            ),
          IconButton(
            tooltip: 'Add availability',
            onPressed: () => _showAddAvailabilitySheet(context, brightness),
            icon: Icon(
              Icons.add_circle_rounded,
              color: AppColors.crimson,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCalendar,
        color: AppColors.crimson,
        child: Column(
          children: [
            // Month View
            _buildMonthView(brightness),

            const SizedBox(height: 16),

            // Selected Date Header
            _buildSelectedDateHeader(brightness),

            const SizedBox(height: 8),

            // Events List
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(brightness)
                  : _errorMessage != null
                  ? _buildErrorState(brightness)
                  : _buildEventList(brightness),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 CALENDAR WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMonthView(Brightness brightness) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(brightness)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Month Year + Nav)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.text(brightness),
                ),
                tooltip: 'Previous month',
              ),
              GestureDetector(
                onTap: () {
                  // Jump to today
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDate = DateTime.now();
                  });
                  _loadCalendar();
                },
                child: Text(
                  _formatMonthYear(_focusedDay),
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.text(brightness),
                ),
                tooltip: 'Next month',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdaysShort.map((day) {
              return SizedBox(
                width: 36,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textTert(brightness),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Days Grid
          _buildDaysGrid(brightness),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(Brightness brightness) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedDay.year,
      _focusedDay.month,
    );
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final weekdayOffset = firstDayOfMonth.weekday % 7;

    final totalCells = daysInMonth + weekdayOffset;
    final rowCount = (totalCells / 7).ceil();

    // For checking past dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - weekdayOffset + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 36, height: 36);
              }

              final currentDay = DateTime(
                _focusedDay.year,
                _focusedDay.month,
                dayNumber,
              );
              final isSelected = DateUtils.isSameDay(currentDay, _selectedDate);
              final isToday = DateUtils.isSameDay(currentDay, DateTime.now());
              final isPast = currentDay.isBefore(today);
              final events = _getEventsForDay(currentDay);
              final hasGig = events.any((e) => e.isGig);
              final hasAvailability = events.any((e) => e.isAvailability);
              final hasBlocked = events.any((e) => e.isBlocked);

              return GestureDetector(
                onTap: () => _onDaySelected(currentDay, _focusedDay),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.crimson
                        : isToday
                        ? AppColors.crimson.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.crimson, width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? AppColors.crimson
                              : isPast
                              ? AppColors.textDisabled
                              : AppColors.text(brightness),
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                      // Event indicators
                      if (events.isNotEmpty && !isSelected)
                        Positioned(
                          bottom: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasGig)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.crimson,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasAvailability)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasBlocked)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.textDisabled,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildSelectedDateHeader(Brightness brightness) {
    final events = _getEventsForDay(_selectedDate);
    final gigCount = events.where((e) => e.isGig).length;
    final availCount = events.where((e) => e.isAvailability).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isToday(_selectedDate)
                    ? 'Today'
                    : _formatWeekday(_selectedDate),
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatMonthDay(_selectedDate),
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (gigCount > 0)
                _EventBadge(
                  icon: Icons.music_note_rounded,
                  count: gigCount,
                  color: AppColors.crimson,
                  brightness: brightness,
                ),
              if (availCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _EventBadge(
                    icon: Icons.check_circle_rounded,
                    count: availCount,
                    color: AppColors.success,
                    brightness: brightness,
                  ),
                ),
              if (events.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface(brightness),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border(brightness)),
                  ),
                  child: Text(
                    'No events',
                    style: TextStyle(
                      color: AppColors.textTert(brightness),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 EVENT LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.crimson),
          const SizedBox(height: 16),
          Text(
            'Loading calendar...',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Brightness brightness) {
    // Parse short error message
    String shortError = 'Unable to connect';
    if (_errorMessage != null) {
      if (_errorMessage!.contains('404')) {
        shortError = 'Calendar service unavailable';
      } else if (_errorMessage!.contains('401')) {
        shortError = 'Please sign in again';
      } else if (_errorMessage!.contains('timeout') ||
          _errorMessage!.contains('connect')) {
        shortError = 'Check your internet connection';
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textTert(brightness),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              shortError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCalendar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(Brightness brightness) {
    final events = _getEventsForDay(_selectedDate);

    // Check if selected date is in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final isPastDate = selectedDay.isBefore(today);

    if (events.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPastDate
                      ? Icons.history_rounded
                      : Icons.event_available_rounded,
                  color: AppColors.textTert(brightness),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isPastDate ? 'Past date' : 'No events',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isPastDate) ...[
                const SizedBox(height: 4),
                Text(
                  'Tap + to add availability',
                  style: TextStyle(
                    color: AppColors.textTert(brightness),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(
          event: event,
          brightness: brightness,
          onDelete: event.isGig ? null : () => _deleteAvailability(event),
          onTap: () => _showEventDetails(context, event, brightness),
        );
      },
    );
  }

  /// Show event details bottom sheet
  void _showEventDetails(
    BuildContext context,
    CalendarEvent event,
    Brightness brightness,
  ) {
    final isGig = event.isGig;
    final isAvailability = event.eventType == CalendarEventType.availability;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sheetBackground(brightness),
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border(brightness),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Event Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isGig
                    ? AppColors.crimson.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGig
                        ? Icons.music_note_rounded
                        : Icons.event_available_rounded,
                    size: 16,
                    color: isGig ? AppColors.crimson : AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isGig ? 'Booked Gig' : 'Available',
                    style: TextStyle(
                      color: isGig ? AppColors.crimson : AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              event.title,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // Date & Time
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.textSec(brightness),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatMonthDay(event.date),
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.textSec(brightness),
                ),
                const SizedBox(width: 8),
                Text(
                  '${event.displayStartTime} - ${event.displayEndTime}',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Venue (for gigs)
            if (event.venueName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: AppColors.crimson,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.venueName!,
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // Payment (for gigs)
            if (event.payment != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.attach_money_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${event.payment!.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],

            // Notes
            if (event.notes != null && event.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.notes!,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            if (isGig) ...[
              // View Gig Details button for gigs
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // TODO: Navigate to gig details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('View gig details coming soon')),
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('View Gig Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else if (isAvailability) ...[
              // Edit and Delete for availability
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteAvailability(event);
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      label: Text(
                        'Remove',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Open edit sheet with existing values
                        _showEditAvailabilitySheet(context, event, brightness);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: MediaQuery.of(ctx).viewPadding.bottom + 8),
          ],
        ),
      ),
    );
  }

  /// Show edit availability sheet
  void _showEditAvailabilitySheet(
    BuildContext context,
    CalendarEvent event,
    Brightness brightness,
  ) {
    // Parse existing times
    final startParts = event.startTime.split(':');
    final endParts = event.endTime.split(':');
    final startHour = int.parse(startParts[0]);
    final startMin = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMin = int.parse(endParts[1]);

    // Determine if overnight (if end < start)
    final isOvernight =
        endHour < startHour || (endHour == startHour && endMin < startMin);

    GigTimeSlot timeSlot = GigTimeSlot(
      date: event.date,
      startHour: startHour,
      startMinute: startMin,
      endHour: endHour,
      endMinute: endMin,
      isOvernight: isOvernight,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sheetBackground(brightness),
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.border(brightness),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Availability',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.crimson,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatMonthDay(event.date),
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Time Range Picker
              TimeRangePicker(
                date: event.date,
                initialSlot: timeSlot,
                brightness: brightness,
                onChanged: (slot) {
                  setSheetState(() => timeSlot = slot);
                },
              ),

              const SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: timeSlot.isValid
                      ? () => _updateAvailability(ctx, event, timeSlot)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: timeSlot.isValid
                        ? AppColors.success
                        : AppColors.ash,
                    disabledBackgroundColor: AppColors.ash,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: timeSlot.isValid ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    timeSlot.isValid
                        ? 'Update Availability'
                        : 'Invalid Time Slot',
                    style: TextStyle(
                      color: timeSlot.isValid
                          ? Colors.white
                          : AppColors.textDisabled,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Update existing availability
  void _updateAvailability(
    BuildContext context,
    CalendarEvent existingEvent,
    GigTimeSlot timeSlot,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    try {
      // Delete old and add new (simple update approach)
      await _calendarService.removeAvailability(existingEvent.date);

      final slot = AvailabilitySlot.fromTimeSlot(timeSlot);
      await _calendarService.addAvailability(slot);

      _loadCalendar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Availability updated: ${timeSlot.displayStartTime} → ${timeSlot.displayEndTime}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update: ${e.toString().split(':').last.trim()}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚙️ ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _deleteAvailability(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Availability?'),
        content: Text(
          'Remove availability for ${_formatMonthDay(event.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _calendarService.removeAvailability(event.date);
        _loadCalendar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Availability removed'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // ignore: unused_element
  Future<void> _blockDate(Brightness brightness) async {
    try {
      await _calendarService.blockDate(_selectedDate);
      _loadCalendar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_formatMonthDay(_selectedDate)} blocked'),
            backgroundColor: AppColors.textDisabled,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddAvailabilitySheet(BuildContext context, Brightness brightness) {
    // Initialize with evening preset
    GigTimeSlot timeSlot = GigTimeSlot.evening(_selectedDate);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sheetBackground(brightness),
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => GestureDetector(
          // Prevent scroll from blocking sheet dismiss
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar - drag indicator
                    Center(
                      child: GestureDetector(
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! > 300) {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.border(brightness),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add Availability',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.crimson,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatMonthDay(_selectedDate),
                          style: TextStyle(
                            color: AppColors.crimson,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Slider-Based Time Picker with conflict detection
                    TimeRangePicker(
                      date: _selectedDate,
                      initialSlot: timeSlot,
                      brightness: brightness,
                      existingSlots: _getExistingSlotsForDay(_selectedDate),
                      lastWeekSlot: _getLastWeekSlot(_selectedDate),
                      onChanged: (slot) {
                        setSheetState(() => timeSlot = slot);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: timeSlot.isValid
                            ? () => _submitAvailability(context, timeSlot)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: timeSlot.isValid
                              ? AppColors.crimson
                              : AppColors.ash,
                          disabledBackgroundColor: AppColors.ash,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: timeSlot.isValid ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          timeSlot.isValid
                              ? 'Add Availability'
                              : 'Invalid Time Slot',
                          style: TextStyle(
                            color: timeSlot.isValid
                                ? Colors.white
                                : AppColors.textDisabled,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Submit availability with proper validation and conflict detection
  void _submitAvailability(BuildContext context, GigTimeSlot timeSlot) {
    // 1. Validate slot using built-in validation
    final validationError = timeSlot.validationError;
    if (validationError != null) {
      // Error already shown in UI, don't submit
      return;
    }

    // 2. Check minimum notice period (already handled in validation, but double-check)
    if (timeSlot.isTooSoon) {
      return;
    }

    // 3. Check for conflicts with existing events on the same day
    final eventsOnDate = _calendarData?.getEventsForDate(_selectedDate) ?? [];
    final conflictingEvents = eventsOnDate.where((event) {
      return timeSlot.overlapsEvent(event);
    }).toList();

    if (conflictingEvents.isNotEmpty) {
      // Show conflict warning dialog
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Time Conflict',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This time slot overlaps with:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ...conflictingEvents.map(
                (event) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.obsidian,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getEventColor(event).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        event.eventType == CalendarEventType.gig
                            ? Icons.music_note
                            : Icons.check_circle_outline,
                        color: _getEventColor(event),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${event.startTime} - ${event.endTime}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Would you like to add this availability anyway?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                _doAddAvailability(context, timeSlot); // Proceed anyway
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add Anyway',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // No conflicts - proceed to add
    _doAddAvailability(context, timeSlot);
  }

  /// Actually add the availability after all validation passes
  void _doAddAvailability(BuildContext context, GigTimeSlot timeSlot) {
    // Store scaffold messenger before popping
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // Close bottom sheet

    // Create slot using the robust model (includes timezone info)
    final slot = AvailabilitySlot.fromTimeSlot(timeSlot);

    _calendarService
        .addAvailability(slot)
        .then((_) {
          _loadCalendar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                'Availability added: ${timeSlot.displayStartTime} → ${timeSlot.displayEndTime}'
                '${timeSlot.isOvernight ? ' (overnight)' : ''}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        })
        .catchError((e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                'Failed to add: ${e.toString().split(':').last.trim()}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        });
  }

  /// Get color for calendar event type
  Color _getEventColor(CalendarEvent event) {
    switch (event.eventType) {
      case CalendarEventType.gig:
        return AppColors.crimson;
      case CalendarEventType.availability:
        return AppColors.success;
      case CalendarEventType.blocked:
        return AppColors.error;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🧩 HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _StatDot extends StatelessWidget {
  final Color color;
  final int count;

  const _StatDot({required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EventBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final Brightness brightness;

  const _EventBadge({
    required this.icon,
    required this.count,
    required this.color,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final Brightness brightness;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _EventCard({
    required this.event,
    required this.brightness,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGig = event.isGig;
    final isBlocked = event.isBlocked;
    final accentColor = isGig
        ? AppColors.crimson
        : isBlocked
        ? AppColors.textDisabled
        : AppColors.success;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Time Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.displayStartTime,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    event.displayEndTime,
                    style: TextStyle(
                      color: AppColors.textTert(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Vertical Accent
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (event.venueName != null)
                      Text(
                        '@ ${event.venueName}',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (event.payment != null)
                      Text(
                        '\$${event.payment!.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              // Action
              if (isGig)
                Icon(Icons.star_rounded, color: accentColor)
              else if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  tooltip: 'Remove',
                )
              else
                Icon(
                  isBlocked ? Icons.block_rounded : Icons.check_circle_rounded,
                  color: accentColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
