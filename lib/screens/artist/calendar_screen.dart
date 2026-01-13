/// 📅 Artist Calendar Screen
///
/// Purpose:
/// - Manage availability blocks
/// - View upcoming gigs (Bookings)
/// - Sync with external calendars (future)
///
/// Design:
/// - Clean, modern calendar view
/// - Agenda view below for selected day details
/// - Full dark/light mode support using AppColors
library;

import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class ArtistCalendarScreen extends StatefulWidget {
  const ArtistCalendarScreen({super.key});

  @override
  State<ArtistCalendarScreen> createState() => _ArtistCalendarScreenState();
}

class _ArtistCalendarScreenState extends State<ArtistCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  
  // Use a map for O(1) lookups: Date string -> List of events
  final Map<String, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    // Force rebuild on init to get provider data
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvents());
  }

  void _loadEvents() {
    // Calendar starts empty - availability is managed locally and synced later
    // Future: Load from backend availability endpoint when implemented
    _events.clear();
    setState(() {});
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  // Custom date formatters (no intl dependency)
  static const _weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  String _formatWeekday(DateTime date) => _weekdays[date.weekday % 7];
  String _formatMonthDay(DateTime date) => '${_months[date.month - 1]} ${date.day}, ${date.year}';
  String _formatMonthYear(DateTime date) => '${_months[date.month - 1]} ${date.year}';

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _focusedDay = focusedDay;
    });
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
          IconButton(
            tooltip: 'Add availability',
            onPressed: () => _showAddAvailabilitySheet(context, brightness),
            icon: Icon(
              Icons.add_circle_rounded,
              color: AppColors.crimson,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Month View
          _buildMonthView(brightness),

          const SizedBox(height: 16),

          // Selected Date Header
          Padding(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface(brightness),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border(brightness)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getEventsForDay(_selectedDate).isNotEmpty
                              ? AppColors.success
                              : AppColors.textDisabled,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_getEventsForDay(_selectedDate).length} Events',
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Agenda / Event List
          Expanded(
            child: _buildEventList(brightness),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 CUSTOM CALENDAR WIDGETS
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
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
                icon: Icon(Icons.chevron_left_rounded, color: AppColors.text(brightness)),
                tooltip: 'Previous month',
              ),
              Text(
                _formatMonthYear(_focusedDay),
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
                icon: Icon(Icons.chevron_right_rounded, color: AppColors.text(brightness)),
                tooltip: 'Next month',
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 32,
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
    final daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final weekdayOffset = firstDayOfMonth.weekday % 7; // Sunday is 7 in DateTime but 0 in our logic usually, adjusting...
    // DateTime.weekday: Mon=1, Sun=7.
    // If we want Sun to be first column (index 0), then offset = weekday % 7.
    
    final totalCells = daysInMonth + weekdayOffset;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - weekdayOffset + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 32, height: 32);
              }

              final currentDay = DateTime(_focusedDay.year, _focusedDay.month, dayNumber);
              final isSelected = DateUtils.isSameDay(currentDay, _selectedDate);
              final isToday = DateUtils.isSameDay(currentDay, DateTime.now());
              final hasEvents = _getEventsForDay(currentDay).isNotEmpty;

              return GestureDetector(
                onTap: () => _onDaySelected(currentDay, _focusedDay),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.crimson
                        : isToday
                            ? AppColors.crimson.withValues(alpha: 0.1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.crimson)
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
                                  : AppColors.text(brightness),
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                      if (hasEvents && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.crimson : AppColors.text(brightness),
                              shape: BoxShape.circle,
                            ),
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

  Widget _buildEventList(Brightness brightness) {
    final events = _getEventsForDay(_selectedDate);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                color: AppColors.textTert(brightness),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No events for this day',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add availability',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isGig = event['type'] == 'gig';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isGig 
                  ? AppColors.crimson.withValues(alpha: 0.3) 
                  : AppColors.border(brightness),
            ),
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
                    event['startTime'],
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    event['endTime'],
                    style: TextStyle(
                      color: AppColors.textTert(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Vertical Divider
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: isGig ? AppColors.crimson : AppColors.success,
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
                      event['title'],
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isGig && event['venue'] != null)
                      Text(
                        '@ ${event['venue']}',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              // Action Icon
              Icon(
                isGig ? Icons.star_rounded : Icons.check_circle_outline_rounded,
                color: isGig ? AppColors.crimson : AppColors.success,
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚙️ HELPERS & LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _getEventsForDay(DateTime date) {
    return _events[_formatDateKey(date)] ?? [];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showAddAvailabilitySheet(BuildContext context, Brightness brightness) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sheetBackground(brightness),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 
          20, 
          20, 
          MediaQuery.of(context).viewInsets.bottom + 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Availability',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For ${_formatMonthDay(_selectedDate)}',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            // Time Pickers (Placeholder)
            Row(
              children: [
                 Expanded(child: _buildTimeInput('Start Time', '09:00 AM', brightness)),
                 const SizedBox(width: 16),
                 Expanded(child: _buildTimeInput('End Time', '11:00 PM', brightness)),
              ],
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                   // Logic to add to state
                   final key = _formatDateKey(_selectedDate);
                   if (_events[key] == null) _events[key] = [];
                   setState(() {
                      _events[key]!.add({
                        'type': 'availability',
                        'title': 'Available',
                        'startTime': '09:00 AM',
                        'endTime': '11:00 PM',
                        'venue': null,
                      });
                   });
                   Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Add Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInput(String label, String value, Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            color: AppColors.textSec(brightness), 
            fontSize: 12, 
            fontWeight: FontWeight.w600
          )
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inputFill(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.access_time_rounded, color: AppColors.textTert(brightness), size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
