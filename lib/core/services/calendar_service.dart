/// 📅 GIGMATCH Calendar Service
/// Handles calendar and availability operations for artists
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api.dart';

/// Calendar event types
enum CalendarEventType {
  availability,
  blocked,
  gig,
}

/// Availability slot type for API
enum AvailabilityType {
  available,
  blocked,
  booked,
}

/// Calendar event model
class CalendarEvent {
  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final CalendarEventType eventType;
  final String title;
  final String? notes;
  final String? venueName;
  final String? venueId;
  final String? gigId;
  final double? payment;

  CalendarEvent({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.eventType,
    required this.title,
    this.notes,
    this.venueName,
    this.venueId,
    this.gigId,
    this.payment,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      startTime: json['startTime'] ?? '19:00',
      endTime: json['endTime'] ?? '23:00',
      eventType: _parseEventType(json['eventType']),
      title: json['title'] ?? 'Event',
      notes: json['notes'],
      venueName: json['venueName'],
      venueId: json['venueId'],
      gigId: json['gigId'],
      payment: json['payment']?.toDouble(),
    );
  }

  static CalendarEventType _parseEventType(String? type) {
    switch (type) {
      case 'gig':
        return CalendarEventType.gig;
      case 'blocked':
        return CalendarEventType.blocked;
      case 'availability':
      default:
        return CalendarEventType.availability;
    }
  }

  /// Format time for display (24h to 12h)
  String get displayStartTime => _formatTime(startTime);
  String get displayEndTime => _formatTime(endTime);

  static String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1] : '00';
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return time24;
    }
  }

  bool get isGig => eventType == CalendarEventType.gig;
  bool get isAvailability => eventType == CalendarEventType.availability;
  bool get isBlocked => eventType == CalendarEventType.blocked;
}

/// Calendar response model
class CalendarResponse {
  final List<CalendarEvent> events;
  final int availableCount;
  final int bookedCount;
  final int blockedCount;

  CalendarResponse({
    required this.events,
    required this.availableCount,
    required this.bookedCount,
    required this.blockedCount,
  });

  factory CalendarResponse.fromJson(Map<String, dynamic> json) {
    final eventsList = (json['events'] as List? ?? [])
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return CalendarResponse(
      events: eventsList,
      availableCount: json['availableCount'] ?? 0,
      bookedCount: json['bookedCount'] ?? 0,
      blockedCount: json['blockedCount'] ?? 0,
    );
  }

  /// Group events by date for calendar display
  Map<DateTime, List<CalendarEvent>> get eventsByDate {
    final Map<DateTime, List<CalendarEvent>> grouped = {};
    for (final event in events) {
      final dateKey = DateTime(event.date.year, event.date.month, event.date.day);
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(event);
    }
    return grouped;
  }

  /// Get events for specific date
  List<CalendarEvent> getEventsForDate(DateTime date) {
    return events.where((e) => 
      e.date.year == date.year && 
      e.date.month == date.month && 
      e.date.day == date.day
    ).toList();
  }
}

/// Availability slot for adding/updating
class AvailabilitySlot {
  final DateTime date;
  final String startTime;
  final String endTime;
  final AvailabilityType type;
  final String? notes;
  final bool isRecurring;
  final bool isOvernight;
  final String? timezone; // User's timezone for backend reference

  AvailabilitySlot({
    required this.date,
    required this.startTime,
    required this.endTime,
    this.type = AvailabilityType.available,
    this.notes,
    this.isRecurring = false,
    this.isOvernight = false,
    this.timezone,
  });

  /// Create from GigTimeSlot (our robust time model)
  factory AvailabilitySlot.fromTimeSlot(GigTimeSlot timeSlot, {
    AvailabilityType type = AvailabilityType.available,
    String? notes,
  }) {
    return AvailabilitySlot(
      date: timeSlot.date,
      startTime: timeSlot.startTimeString,
      endTime: timeSlot.endTimeString,
      type: type,
      notes: notes,
      isOvernight: timeSlot.isOvernight,
      timezone: DateTime.now().timeZoneName, // Capture user's timezone
    );
  }

  Map<String, dynamic> toJson() => {
    'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'startTime': startTime,
    'endTime': endTime,
    'type': type.name,
    'notes': notes,
    'isRecurring': isRecurring,
    'isOvernight': isOvernight,
    if (timezone != null) 'timezone': timezone,
    // Also send UTC timestamps for unambiguous time handling
    'startDateTimeUtc': _getStartDateTimeUtc().toIso8601String(),
    'endDateTimeUtc': _getEndDateTimeUtc().toIso8601String(),
  };

  /// Get start DateTime in UTC
  DateTime _getStartDateTimeUtc() {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute).toUtc();
  }

  /// Get end DateTime in UTC (handles overnight)
  DateTime _getEndDateTimeUtc() {
    final parts = endTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final endDate = isOvernight ? date.add(const Duration(days: 1)) : date;
    return DateTime(endDate.year, endDate.month, endDate.day, hour, minute).toUtc();
  }
}

/// 🎯 Robust Time Slot Model - Handles all edge cases
class GigTimeSlot {
  final DateTime date;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isOvernight;

  /// Minimum notice period in minutes (default: 60 minutes)
  static const int minNoticePeriod = 60;
  
  /// Minimum duration in minutes
  static const int minDuration = 30;
  
  /// Maximum duration in hours
  static const int maxDuration = 16;

  const GigTimeSlot({
    required this.date,
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
    this.isOvernight = false,
  });

  /// Common presets
  static GigTimeSlot afternoon(DateTime date) => GigTimeSlot(
    date: date,
    startHour: 12,
    endHour: 17,
  );

  static GigTimeSlot evening(DateTime date) => GigTimeSlot(
    date: date,
    startHour: 18,
    endHour: 23,
  );

  static GigTimeSlot lateNight(DateTime date) => GigTimeSlot(
    date: date,
    startHour: 22,
    endHour: 2,
    isOvernight: true,
  );

  static GigTimeSlot allDay(DateTime date) => GigTimeSlot(
    date: date,
    startHour: 10,
    endHour: 23,
  );

  /// Create from time strings (e.g., "10:30 PM" format)
  factory GigTimeSlot.fromTimeStrings({
    required DateTime date,
    required String startTime,
    required String endTime,
  }) {
    int parseTime(String timeStr) {
      // Parse "10:30 PM" format
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      final isAM = parts.length > 1 && parts[1].toUpperCase() == 'AM';
      
      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      
      return hour * 60 + minute;
    }
    
    final startMins = parseTime(startTime);
    final endMins = parseTime(endTime);
    
    final startHour = startMins ~/ 60;
    final startMinute = startMins % 60;
    final endHour = endMins ~/ 60;
    final endMinute = endMins % 60;
    
    // Detect overnight (end time appears before start time)
    final isOvernight = endMins <= startMins;
    
    return GigTimeSlot(
      date: date,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      isOvernight: isOvernight,
    );
  }

  /// Calculate duration handling overnight
  Duration get duration {
    int startMins = startHour * 60 + startMinute;
    int endMins = endHour * 60 + endMinute;
    if (isOvernight) endMins += 24 * 60;
    return Duration(minutes: endMins - startMins);
  }

  /// Get total minutes (for slider calculations)
  int get startTotalMinutes => startHour * 60 + startMinute;
  int get endTotalMinutes {
    int mins = endHour * 60 + endMinute;
    if (isOvernight) mins += 24 * 60;
    return mins;
  }

  /// Start DateTime (local time)
  DateTime get startDateTime => DateTime(
    date.year, date.month, date.day,
    startHour, startMinute,
  );

  /// End DateTime (handles overnight, local time)
  DateTime get endDateTime {
    final baseDate = isOvernight
        ? date.add(const Duration(days: 1))
        : date;
    return DateTime(
      baseDate.year, baseDate.month, baseDate.day,
      endHour, endMinute,
    );
  }

  /// Start DateTime in UTC (for API calls)
  DateTime get startDateTimeUtc => startDateTime.toUtc();
  
  /// End DateTime in UTC (for API calls)
  DateTime get endDateTimeUtc => endDateTime.toUtc();

  /// Format for API (HH:mm)
  String get startTimeString => 
    '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  
  String get endTimeString => 
    '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  /// Display format (12h with AM/PM)
  String get displayStartTime => _formatDisplay(startHour, startMinute);
  String get displayEndTime => _formatDisplay(endHour, endMinute);

  String _formatDisplay(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  /// Duration display (e.g., "4h 30m")
  String get durationDisplay {
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// Full validation with all edge cases
  bool get isValid {
    final error = validationError;
    return error == null;
  }

  /// Get validation error (null if valid)
  String? get validationError {
    // 1. Duration must be at least 30 minutes
    if (duration.inMinutes < minDuration) {
      return 'Min $minDuration mins duration required';
    }
    
    // 2. Duration must be at most 16 hours
    if (duration.inHours > maxDuration) {
      return 'Max $maxDuration hours duration';
    }
    
    // 3. Date cannot be in the past (before today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final slotDate = DateTime(date.year, date.month, date.day);
    if (slotDate.isBefore(today)) {
      return 'Cannot add past dates';
    }
    
    // 4. If today, start time must be at least 1 hour in the future
    if (slotDate.isAtSameMomentAs(today)) {
      final minStartTime = now.add(Duration(minutes: minNoticePeriod));
      if (startDateTime.isBefore(minStartTime)) {
        return 'Must start 1hr+ from now';
      }
    }
    
    // 5. Start hour must be reasonable (6 AM - 11 PM for start)
    if (startHour < 6) {
      return 'Cannot start before 6 AM';
    }
    
    return null;
  }

  /// Check if time is in the past
  bool get isInPast {
    final now = DateTime.now();
    return startDateTime.isBefore(now);
  }

  /// Check if within minimum notice period
  bool get isTooSoon {
    final now = DateTime.now();
    final minStart = now.add(Duration(minutes: minNoticePeriod));
    return startDateTime.isBefore(minStart);
  }

  /// Check if this slot overlaps with another
  bool overlaps(GigTimeSlot other) {
    // Convert to minutes from midnight for comparison
    final thisStart = startTotalMinutes;
    final thisEnd = endTotalMinutes;
    final otherStart = other.startTotalMinutes;
    final otherEnd = other.endTotalMinutes;
    
    // Only check overlap if same date
    final thisDate = DateTime(date.year, date.month, date.day);
    final otherDate = DateTime(other.date.year, other.date.month, other.date.day);
    if (!thisDate.isAtSameMomentAs(otherDate)) {
      // Check if overnight slots spill into next day
      if (isOvernight && otherDate.isAtSameMomentAs(thisDate.add(const Duration(days: 1)))) {
        // This slot ends on otherDate
        final overlapEnd = endHour * 60 + endMinute;
        if (otherStart < overlapEnd) return true;
      }
      return false;
    }
    
    // Check overlap: two ranges overlap if start1 < end2 AND start2 < end1
    return thisStart < otherEnd && otherStart < thisEnd;
  }

  /// Check overlap with CalendarEvent
  bool overlapsEvent(CalendarEvent event) {
    // Parse event times
    final eventStartParts = event.startTime.split(':');
    final eventEndParts = event.endTime.split(':');
    final eventStartMins = int.parse(eventStartParts[0]) * 60 + int.parse(eventStartParts[1]);
    final eventEndMins = int.parse(eventEndParts[0]) * 60 + int.parse(eventEndParts[1]);
    
    // Only check same date
    final thisDate = DateTime(date.year, date.month, date.day);
    final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
    if (!thisDate.isAtSameMomentAs(eventDate)) return false;
    
    final thisStart = startTotalMinutes;
    final thisEnd = isOvernight ? endTotalMinutes : endHour * 60 + endMinute;
    
    return thisStart < eventEndMins && eventStartMins < thisEnd;
  }

  /// Create a copy with modifications
  GigTimeSlot copyWith({
    DateTime? date,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? isOvernight,
  }) {
    return GigTimeSlot(
      date: date ?? this.date,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      isOvernight: isOvernight ?? this.isOvernight,
    );
  }

  @override
  String toString() => '$displayStartTime → $displayEndTime${isOvernight ? ' (next day)' : ''}';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GigTimeSlot &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
        other.startHour == startHour &&
        other.startMinute == startMinute &&
        other.endHour == endHour &&
        other.endMinute == endMinute &&
        other.isOvernight == isOvernight;
  }

  @override
  int get hashCode => Object.hash(
    date.year, date.month, date.day,
    startHour, startMinute, endHour, endMinute, isOvernight,
  );
}

/// Calendar Service Exception
class CalendarServiceError implements Exception {
  final String message;
  final int? statusCode;

  CalendarServiceError(this.message, [this.statusCode]);

  @override
  String toString() => 'CalendarServiceError: $message';
}

/// 📅 Calendar Service
class CalendarService {
  final ApiClient _client = ApiClient();

  /// Get full calendar with availability and gigs
  Future<CalendarResponse> getCalendar({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('📅 [CalendarService] Fetching calendar...');

      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _client.get(
        Endpoints.artistsMyCalendar,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data == null) {
        throw CalendarServiceError('Empty response from server');
      }

      final calendar = CalendarResponse.fromJson(response.data);
      debugPrint('📅 [CalendarService] Loaded ${calendar.events.length} events');
      return calendar;

    } on DioException catch (e) {
      throw _handleDioError(e, 'get calendar');
    } catch (e) {
      throw CalendarServiceError('Failed to load calendar: $e');
    }
  }

  /// Get only availability slots
  Future<List<AvailabilitySlot>> getAvailability({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('📅 [CalendarService] Fetching availability...');

      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _client.get(
        Endpoints.artistsMyAvailability,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data == null) {
        return [];
      }

      final slots = (response.data['slots'] as List? ?? [])
          .map((e) => AvailabilitySlot(
                date: DateTime.parse(e['date']),
                startTime: e['startTime'] ?? '19:00',
                endTime: e['endTime'] ?? '23:00',
                type: e['isAvailable'] == true 
                    ? AvailabilityType.available 
                    : AvailabilityType.blocked,
              ))
          .toList();

      debugPrint('📅 [CalendarService] Loaded ${slots.length} availability slots');
      return slots;

    } on DioException catch (e) {
      throw _handleDioError(e, 'get availability');
    } catch (e) {
      throw CalendarServiceError('Failed to load availability: $e');
    }
  }

  /// Add a single availability slot
  Future<void> addAvailability(AvailabilitySlot slot) async {
    try {
      debugPrint('📅 [CalendarService] Adding availability for ${slot.date}...');

      await _client.post(
        Endpoints.artistsAddAvailability,
        data: slot.toJson(),
      );

      debugPrint('📅 [CalendarService] Availability added successfully');

    } on DioException catch (e) {
      throw _handleDioError(e, 'add availability');
    } catch (e) {
      throw CalendarServiceError('Failed to add availability: $e');
    }
  }

  /// Update all availability (replace)
  Future<void> updateAvailability(List<AvailabilitySlot> slots) async {
    try {
      debugPrint('📅 [CalendarService] Updating ${slots.length} availability slots...');

      await _client.put(
        Endpoints.artistsMyAvailability,
        data: {
          'slots': slots.map((s) => s.toJson()).toList(),
        },
      );

      debugPrint('📅 [CalendarService] Availability updated successfully');

    } on DioException catch (e) {
      throw _handleDioError(e, 'update availability');
    } catch (e) {
      throw CalendarServiceError('Failed to update availability: $e');
    }
  }

  /// Remove availability for a specific date
  Future<void> removeAvailability(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      debugPrint('📅 [CalendarService] Removing availability for $dateStr...');

      await _client.delete(
        Endpoints.artistsRemoveAvailability,
        data: {'date': dateStr},
      );

      debugPrint('📅 [CalendarService] Availability removed successfully');

    } on DioException catch (e) {
      throw _handleDioError(e, 'remove availability');
    } catch (e) {
      throw CalendarServiceError('Failed to remove availability: $e');
    }
  }

  /// Block a date (mark as unavailable)
  Future<void> blockDate(DateTime date, {String? notes}) async {
    return addAvailability(AvailabilitySlot(
      date: date,
      startTime: '00:00',
      endTime: '23:59',
      type: AvailabilityType.blocked,
      notes: notes,
    ));
  }

  /// Helper to handle Dio errors
  CalendarServiceError _handleDioError(DioException e, String operation) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] ?? e.message ?? 'Unknown error';

    if (statusCode == 401) {
      return CalendarServiceError('Authentication required', statusCode);
    } else if (statusCode == 404) {
      return CalendarServiceError('Calendar not found', statusCode);
    } else if (statusCode == 403) {
      return CalendarServiceError('Access denied', statusCode);
    }

    return CalendarServiceError('Failed to $operation: $message', statusCode);
  }
}
