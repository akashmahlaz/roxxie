/// 📅 Artist Calendar — Red & White Professional Design
///
/// Full-month calendar with crimson date text, white today badge,
/// and super-rounded bento availability cards.
///
/// Flow: Full calendar visible → Tap "Add Availability" →
///       Date picker → Time picker → Saved.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/services/calendar_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ArtistCalendarScreen extends StatefulWidget {
  const ArtistCalendarScreen({super.key});

  @override
  State<ArtistCalendarScreen> createState() => _ArtistCalendarScreenState();
}

class _ArtistCalendarScreenState extends State<ArtistCalendarScreen> {
  final CalendarService _calService = CalendarService();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  late DateTime _focusedMonth;
  CalendarResponse? _data;
  Map<DateTime, List<CalendarEvent>> _eventsByDate = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _loadCalendar();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DATA
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _loadCalendar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final start = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      final end = DateTime(_focusedMonth.year, _focusedMonth.month + 2, 0);
      debugPrint('📅 [Calendar] Loading $start → $end');

      final data = await _calService.getCalendar(
        startDate: start,
        endDate: end,
      );
      if (!mounted) return;

      setState(() {
        _data = data;
        _eventsByDate = data.eventsByDate;
        _loading = false;
      });
      debugPrint('📅 [Calendar] ${data.events.length} events');
    } catch (e) {
      debugPrint('❌ [Calendar] $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<CalendarEvent> _eventsFor(DateTime d) =>
      _eventsByDate[DateTime(d.year, d.month, d.day)] ?? [];

  // ═════════════════════════════════════════════════════════════════════════
  // ADD AVAILABILITY — Full flow
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _addAvailability() async {
    if (_saving) return;
    HapticFeedback.mediumImpact();
    final br = Theme.of(context).brightness;

    // ── Step 1: Pick date ─────────────────────────────────────────────────
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'SELECT DATE',
      builder: (ctx, child) => Theme(
        data: _datePickerTheme(ctx, br),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    debugPrint('📅 [Calendar] Date picked: $pickedDate');

    // ── Step 2: Pick start time ───────────────────────────────────────────
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      helpText: 'START TIME',
      builder: (ctx, child) => Theme(
        data: _timePickerTheme(ctx, br),
        child: child!,
      ),
    );
    if (startTime == null || !mounted) return;

    debugPrint('📅 [Calendar] Start: ${startTime.format(context)}');

    // ── Step 3: Pick end time ─────────────────────────────────────────────
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startTime.hour + 4) % 24,
        minute: startTime.minute,
      ),
      helpText: 'END TIME',
      builder: (ctx, child) => Theme(
        data: _timePickerTheme(ctx, br),
        child: child!,
      ),
    );
    if (endTime == null || !mounted) return;

    debugPrint('📅 [Calendar] End: ${endTime.format(context)}');

    // ── Save ──────────────────────────────────────────────────────────────
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    try {
      final isOvernight = endTime.hour < startTime.hour;
      final slot = AvailabilitySlot(
        date: pickedDate,
        startTime:
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        endTime:
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        isOvernight: isOvernight,
        timezone: DateTime.now().timeZoneName,
      );

      debugPrint('📅 [Calendar] Saving: ${slot.toJson()}');
      await _calService.addAvailability(slot);

      if (!mounted) return;
      HapticFeedback.heavyImpact();

      messenger.showSnackBar(
        SnackBar(
          content: Text('Availability added — ${_shortDate(pickedDate)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

      // Jump to that month if needed
      if (pickedDate.month != _focusedMonth.month ||
          pickedDate.year != _focusedMonth.year) {
        _focusedMonth = DateTime(pickedDate.year, pickedDate.month);
      }
      await _loadCalendar();
    } catch (e) {
      debugPrint('❌ [Calendar] Save failed: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  /// Delete availability with confirmation
  Future<void> _deleteEvent(CalendarEvent event) async {
    final br = Theme.of(context).brightness;
    HapticFeedback.lightImpact();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(br),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Remove Availability?',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: AppColors.text(br),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          '${event.displayStartTime} – ${event.displayEndTime}\n${_shortDate(event.date)}',
          style: TextStyle(
            color: AppColors.textSec(br),
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSec(br)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.crimson.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Remove',
              style: TextStyle(
                color: AppColors.crimson,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    try {
      final slotId = event.id.startsWith('avail-')
          ? event.id.substring(6)
          : event.id;
      debugPrint('📅 [Calendar] Delete: $slotId');
      await _calService.removeAvailability(event.date, slotId: slotId);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Availability removed'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      await _loadCalendar();
    } catch (e) {
      debugPrint('❌ [Calendar] Delete failed: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PICKER THEMES — Red & White
  // ═════════════════════════════════════════════════════════════════════════

  ThemeData _datePickerTheme(BuildContext ctx, Brightness br) {
    final isDark = br == Brightness.dark;
    return Theme.of(ctx).copyWith(
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: AppColors.crimson,
              onPrimary: Colors.white,
              surface: AppColors.charcoal,
              onSurface: AppColors.pureWhite,
            )
          : ColorScheme.light(
              primary: AppColors.crimson,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.lightTextPrimary,
            ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.crimson),
      ),
    );
  }

  ThemeData _timePickerTheme(BuildContext ctx, Brightness br) {
    final isDark = br == Brightness.dark;
    return Theme.of(ctx).copyWith(
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: AppColors.crimson,
              onPrimary: Colors.white,
              surface: AppColors.charcoal,
              onSurface: AppColors.pureWhite,
              tertiary: AppColors.crimson,
            )
          : ColorScheme.light(
              primary: AppColors.crimson,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.lightTextPrimary,
              tertiary: AppColors.crimson,
            ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.crimson),
      ),
      timePickerTheme: TimePickerThemeData(
        dialHandColor: AppColors.crimson,
        hourMinuteColor: AppColors.crimson.withValues(alpha: 0.12),
        hourMinuteTextColor: AppColors.crimson,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final br = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(br),
      body: SafeArea(
        child: _error != null
            ? _buildError(br)
            : RefreshIndicator(
                onRefresh: _loadCalendar,
                color: AppColors.crimson,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Header ────────────────────────────────────
                    SliverToBoxAdapter(child: _buildHeader(br)),

                    // ── Calendar Card ────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: _buildCalendarCard(br),
                      ),
                    ),

                    // ── Add Button ───────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _buildAddButton(br),
                      ),
                    ),

                    // ── Stats Row ────────────────────────────────
                    if (_data != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _buildStatsRow(br),
                        ),
                      ),

                    // ── Upcoming / Availability cards ────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _buildEventsSection(br),
                      ),
                    ),

                    // Bottom space
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(Brightness br) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Calendar',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text(br),
                    letterSpacing: -1.0,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your availability',
                  style: TextStyle(
                    color: AppColors.textSec(br),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_loading || _saving)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.crimson,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Full Calendar Card ─────────────────────────────────────────────────

  Widget _buildCalendarCard(Brightness br) {
    final isDark = br == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 0 .. Sunday = 6
    final startPad = firstOfMonth.weekday - 1;
    final totalCells = startPad + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFEEEEEE),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // ── Month nav ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _focusedMonth = DateTime(year, month - 1);
                  });
                  _loadCalendar();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.text(br),
                    size: 22,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Return to current month
                  HapticFeedback.lightImpact();
                  final n = DateTime.now();
                  setState(() {
                    _focusedMonth = DateTime(n.year, n.month);
                  });
                  _loadCalendar();
                },
                child: Text(
                  _monthYear(year, month),
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.crimson,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _focusedMonth = DateTime(year, month + 1);
                  });
                  _loadCalendar();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.text(br),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Weekday headers ──
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: AppColors.textSec(br),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 12),

          // ── Day cells ──
          ...List.generate(rows, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: List.generate(7, (col) {
                  final idx = row * 7 + col;
                  final day = idx - startPad + 1;

                  if (day < 1 || day > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }

                  final date = DateTime(year, month, day);
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final isPast = date.isBefore(today);
                  final events = _eventsFor(date);
                  final hasGig = events.any((e) => e.isGig);
                  final hasAvail = events.any((e) => e.isAvailability);

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isPast
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                            },
                      child: SizedBox(
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Today: white circle bg with crimson text
                            if (isToday)
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.crimson,
                                  shape: BoxShape.circle,
                                ),
                              ),

                            // Day number
                            Text(
                              '$day',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 15,
                                fontWeight: isToday
                                    ? FontWeight.w900
                                    : hasAvail || hasGig
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                color: isToday
                                    ? (isDark
                                        ? AppColors.crimson
                                        : Colors.white)
                                    : isPast
                                        ? AppColors.textSec(br)
                                            .withValues(alpha: 0.35)
                                        : AppColors.crimson,
                              ),
                            ),

                            // Event dots below date
                            Positioned(
                              bottom: 2,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasGig)
                                    _eventDot(AppColors.crimson),
                                  if (hasAvail)
                                    _eventDot(AppColors.success),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _eventDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ─── Add Availability Button ────────────────────────────────────────────

  Widget _buildAddButton(Brightness br) {
    final isDark = br == Brightness.dark;

    return GestureDetector(
      onTap: _saving ? null : _addAvailability,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : AppColors.crimson,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.crimson.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: isDark ? AppColors.crimson : Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Add Availability',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: isDark ? AppColors.crimson : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats Row — Bento cards ────────────────────────────────────────────

  Widget _buildStatsRow(Brightness br) {
    final isDark = br == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _statBento(
            label: 'Available',
            count: _data!.availableCount,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            br: br,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBento(
            label: 'Booked',
            count: _data!.bookedCount,
            icon: Icons.music_note_rounded,
            color: AppColors.crimson,
            br: br,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBento(
            label: 'Blocked',
            count: _data!.blockedCount,
            icon: Icons.block_rounded,
            color: AppColors.textSec(br),
            br: br,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _statBento({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Brightness br,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSec(br),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Events Section ─────────────────────────────────────────────────────

  Widget _buildEventsSection(Brightness br) {
    final isDark = br == Brightness.dark;

    // Get upcoming events (today + future), sorted by date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = (_data?.events ?? [])
        .where((e) => !e.date.isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (upcoming.isEmpty && !_loading) {
      return _buildEmptyState(br, isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Upcoming',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text(br),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),

        // Event cards
        ...upcoming.take(20).map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _eventCard(event, br, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Brightness br, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF0F0F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            color: AppColors.crimson.withValues(alpha: 0.3),
            size: 52,
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming events',
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: AppColors.text(br),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your availability so venues\ncan discover and book you',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSec(br),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(CalendarEvent event, Brightness br, bool isDark) {
    final isGig = event.isGig;
    final isAvail = event.isAvailability;

    final Color accent = isGig
        ? AppColors.crimson
        : isAvail
            ? AppColors.success
            : AppColors.textSec(br);

    final IconData icon = isGig
        ? Icons.music_note_rounded
        : isAvail
            ? Icons.check_circle_rounded
            : Icons.block_rounded;

    final String typeLabel = isGig
        ? 'GIG'
        : isAvail
            ? 'AVAILABLE'
            : 'BLOCKED';

    return Dismissible(
      key: ValueKey(event.id),
      direction: isAvail
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        if (isAvail) {
          await _deleteEvent(event);
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.crimson.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.delete_rounded, color: AppColors.crimson),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? accent.withValues(alpha: 0.12)
                : accent.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(
                            alpha: isDark ? 0.2 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _shortDate(event.date),
                        style: TextStyle(
                          color: AppColors.textSec(br),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Time
                  Text(
                    '${event.displayStartTime} – ${event.displayEndTime}',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: AppColors.text(br),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),

                  // Venue name
                  if (event.venueName != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      event.venueName!,
                      style: TextStyle(
                        color: AppColors.textSec(br),
                        fontSize: 13,
                      ),
                    ),
                  ],

                  // Payment
                  if (event.payment != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '\$${event.payment!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: AppColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action
            if (isGig && event.gigId != null)
              GestureDetector(
                onTap: () => context.push('/gig/${event.gigId}'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.crimson,
                    size: 18,
                  ),
                ),
              ),
            if (isAvail)
              GestureDetector(
                onTap: () => _deleteEvent(event),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.crimson.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ────────────────────────────────────────────────────────

  Widget _buildError(Brightness br) {
    final isDark = br == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.crimson,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: AppColors.text(br),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSec(br),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _loadCalendar,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : AppColors.crimson,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: isDark ? AppColors.crimson : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  String _monthYear(int year, int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month - 1]} $year';
  }
}
