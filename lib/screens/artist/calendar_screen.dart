/// 📅 Artist Calendar Screen — Simple 2-Click Availability
///
/// Flow: Tap a date → pick time range → done.
/// Shows booked gigs (read-only) and availability slots (editable).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/services/calendar_service.dart';
import '../../widgets/time_range_picker.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CALENDAR SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ArtistCalendarScreen extends StatefulWidget {
  const ArtistCalendarScreen({super.key});

  @override
  State<ArtistCalendarScreen> createState() => _ArtistCalendarScreenState();
}

class _ArtistCalendarScreenState extends State<ArtistCalendarScreen> {
  final CalendarService _calendarService = CalendarService();

  // --- State ---
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  CalendarResponse? _calendarData;

  // Events grouped by normalised date key
  Map<DateTime, List<CalendarEvent>> _eventsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadCalendar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final startDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month - 1,
        1,
      );
      final endDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 2,
        0,
      );

      debugPrint('📅 [CalendarScreen] Loading ${startDate.toIso8601String()} → ${endDate.toIso8601String()}');

      final data = await _calendarService.getCalendar(
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      setState(() {
        _calendarData = data;
        _eventsByDate = data.eventsByDate;
        _isLoading = false;
      });

      debugPrint('📅 [CalendarScreen] Loaded ${data.events.length} events');
    } catch (e) {
      debugPrint('❌ [CalendarScreen] Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  List<CalendarEvent> _eventsForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _eventsByDate[key] ?? [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS — Add Availability (click 2: pick time)
  // ═══════════════════════════════════════════════════════════════════════════

  void _onDateSelected(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = date);
  }

  /// Opens the time-range picker sheet then saves to backend.
  Future<void> _addAvailability(DateTime date) async {
    final brightness = Theme.of(context).brightness;
    GigTimeSlot? pickedSlot;

    // Gather existing availability for conflict detection
    final existingSlots = _eventsForDate(date)
        .where((e) => e.isAvailability)
        .map(
          (e) => AvailabilitySlot(
            date: e.date,
            startTime: e.startTime,
            endTime: e.endTime,
          ),
        )
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheetBackground(brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(brightness),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Set Availability — ${_shortDate(date)}',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Time Range Picker (reuse existing widget)
              TimeRangePicker(
                date: date,
                onChanged: (slot) => pickedSlot = slot,
                brightness: brightness,
                existingSlots: existingSlots,
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Default evening if user didn't move sliders
                    pickedSlot ??= GigTimeSlot.evening(date);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Availability',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // After sheet closes — save if a slot was selected
    if (pickedSlot == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);

    try {
      final slot = AvailabilitySlot.fromTimeSlot(pickedSlot!);
      debugPrint('📅 [CalendarScreen] Saving availability: $slot');

      await _calendarService.addAvailability(slot);

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Availability added for ${_shortDate(date)}',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      await _loadCalendar();
    } catch (e) {
      debugPrint('❌ [CalendarScreen] Save failed: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE AVAILABILITY
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _deleteAvailability(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(Theme.of(ctx).brightness),
        title: Text(
          'Remove Availability?',
          style: TextStyle(color: AppColors.text(Theme.of(ctx).brightness)),
        ),
        content: Text(
          '${event.displayStartTime} – ${event.displayEndTime} on ${_shortDate(event.date)}',
          style: TextStyle(color: AppColors.textSec(Theme.of(ctx).brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);

    try {
      // Extract slotId from event.id (format: "avail-<mongoId>")
      final slotId = event.id.startsWith('avail-')
          ? event.id.substring(6)
          : event.id;

      await _calendarService.removeAvailability(event.date, slotId: slotId);

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Availability removed'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      await _loadCalendar();
    } catch (e) {
      debugPrint('❌ [CalendarScreen] Delete failed: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.background(brightness),
        title: Text(
          'My Calendar',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_isLoading || _isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.crimson,
                ),
              ),
            ),
        ],
      ),
      body: _error != null
          ? _buildError(brightness)
          : RefreshIndicator(
              onRefresh: _loadCalendar,
              color: AppColors.crimson,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // ── Quick Stats ─────────────────────────────
                  if (_calendarData != null) _buildStats(brightness),

                  // ── Month Grid ──────────────────────────────
                  _buildMonthView(brightness),

                  const SizedBox(height: 8),

                  // ── Selected Day Events ─────────────────────
                  if (_selectedDate != null) _buildDayEvents(brightness),

                  const SizedBox(height: 100), // fab clearance
                ],
              ),
            ),

      // FAB: Add availability for the selected date
      floatingActionButton: _selectedDate != null
          ? FloatingActionButton.extended(
              heroTag: 'addAvail',
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              onPressed: _isSaving ? null : () => _addAvailability(_selectedDate!),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Availability',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────

  Widget _buildError(Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load calendar',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
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

  // ── Stats Bar ──────────────────────────────────────────────────────────

  Widget _buildStats(Brightness brightness) {
    final data = _calendarData!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statChip(
            Icons.check_circle_rounded,
            '${data.availableCount}',
            'Available',
            AppColors.success,
            brightness,
          ),
          _statChip(
            Icons.music_note_rounded,
            '${data.bookedCount}',
            'Booked',
            AppColors.crimson,
            brightness,
          ),
          _statChip(
            Icons.block_rounded,
            '${data.blockedCount}',
            'Blocked',
            AppColors.textSec(brightness),
            brightness,
          ),
        ],
      ),
    );
  }

  Widget _statChip(
    IconData icon,
    String count,
    String label,
    Color color,
    Brightness brightness,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MONTH VIEW (custom grid — no third-party calendar package)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMonthView(Brightness brightness) {
    final now = DateTime.now();
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday % 7; // Sun = 0

    return Column(
      children: [
        // ── Month nav ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(year, month - 1);
                  });
                  _loadCalendar();
                },
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.text(brightness),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Reset to current month
                  setState(() {
                    _focusedMonth = DateTime(now.year, now.month);
                    _selectedDate = DateTime(now.year, now.month, now.day);
                  });
                  _loadCalendar();
                },
                child: Text(
                  _monthYearLabel(year, month),
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(year, month + 1);
                  });
                  _loadCalendar();
                },
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.text(brightness),
                ),
              ),
            ],
          ),
        ),

        // ── Weekday headers ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // ── Day cells ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildDayGrid(
            startWeekday,
            daysInMonth,
            year,
            month,
            now,
            brightness,
          ),
        ),
      ],
    );
  }

  Widget _buildDayGrid(
    int startWeekday,
    int daysInMonth,
    int year,
    int month,
    DateTime now,
    Brightness brightness,
  ) {
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final index = row * 7 + col;
            final day = index - startWeekday + 1;

            if (day < 1 || day > daysInMonth) {
              return const Expanded(child: SizedBox(height: 48));
            }

            final date = DateTime(year, month, day);
            final isToday =
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isSelected =
                _selectedDate != null &&
                date.year == _selectedDate!.year &&
                date.month == _selectedDate!.month &&
                date.day == _selectedDate!.day;
            final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

            final events = _eventsForDate(date);
            final hasGig = events.any((e) => e.isGig);
            final hasAvailability = events.any((e) => e.isAvailability);
            final hasBlocked = events.any((e) => e.isBlocked);

            return Expanded(
              child: GestureDetector(
                onTap: isPast ? null : () => _onDateSelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.crimson
                        : isToday
                            ? AppColors.crimson.withValues(alpha: 0.15)
                            : null,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.crimson, width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isPast
                              ? AppColors.textSec(brightness).withValues(alpha: 0.4)
                              : isSelected
                                  ? Colors.white
                                  : AppColors.text(brightness),
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      // Dot indicators
                      Positioned(
                        bottom: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasGig)
                              _dot(AppColors.crimson, isSelected),
                            if (hasAvailability)
                              _dot(AppColors.success, isSelected),
                            if (hasBlocked)
                              _dot(AppColors.textSec(brightness), isSelected),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _dot(Color color, bool isSelected) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : color,
        shape: BoxShape.circle,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SELECTED DAY EVENTS LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDayEvents(Brightness brightness) {
    final events = _eventsForDate(_selectedDate!);

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: AppColors.textSec(brightness).withValues(alpha: 0.4),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'No events on ${_shortDate(_selectedDate!)}',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the button below to add availability',
              style: TextStyle(
                color: AppColors.textSec(brightness).withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              _shortDate(_selectedDate!),
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...events.map((event) => _buildEventTile(event, brightness)),
        ],
      ),
    );
  }

  Widget _buildEventTile(CalendarEvent event, Brightness brightness) {
    final isGig = event.isGig;
    final isAvailability = event.isAvailability;

    final Color accent = isGig
        ? AppColors.crimson
        : isAvailability
            ? AppColors.success
            : AppColors.textSec(brightness);

    final IconData icon = isGig
        ? Icons.music_note_rounded
        : isAvailability
            ? Icons.check_circle_outline_rounded
            : Icons.block_rounded;

    return Dismissible(
      key: ValueKey(event.id),
      direction: isAvailability
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        if (isAvailability) {
          await _deleteAvailability(event);
        }
        return false; // we handle removal via reload
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Accent bar
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Icon
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.displayStartTime} – ${event.displayEndTime}',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                  if (event.venueName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.venueName!,
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (event.payment != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\$${event.payment!.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            if (isGig && event.gigId != null)
              IconButton(
                onPressed: () => context.push('/gig/${event.gigId}'),
                icon: Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.textSec(brightness),
                  size: 20,
                ),
                tooltip: 'View Gig Details',
              ),
            if (isAvailability)
              IconButton(
                onPressed: () => _deleteAvailability(event),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.error.withValues(alpha: 0.7),
                  size: 20,
                ),
                tooltip: 'Remove',
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _monthYearLabel(int year, int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month - 1]} $year';
  }
}

