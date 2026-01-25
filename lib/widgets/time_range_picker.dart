/// 🎚️ Slider-Based Time Range Picker
/// A professional, bulletproof time selection widget for gig scheduling
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../core/services/calendar_service.dart';

/// Time Range Picker using dual sliders
class TimeRangePicker extends StatefulWidget {
  final DateTime date;
  final GigTimeSlot? initialSlot;
  final ValueChanged<GigTimeSlot> onChanged;
  final Brightness brightness;
  final List<AvailabilitySlot>? existingSlots; // For conflict detection
  final GigTimeSlot? lastWeekSlot; // For copy from last week

  const TimeRangePicker({
    super.key,
    required this.date,
    this.initialSlot,
    required this.onChanged,
    required this.brightness,
    this.existingSlots,
    this.lastWeekSlot,
  });

  @override
  State<TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> 
    with SingleTickerProviderStateMixin {
  // Slider range: 6 AM (360 mins) to 4 AM next day (1680 mins = 28 hours * 60)
  // This allows overnight selection
  static const double _minMinutes = 6 * 60; // 6 AM
  static const double _maxMinutes = 28 * 60; // 4 AM next day (as 28:00)
  
  late double _startValue;
  late double _endValue;
  late bool _isOvernight;
  
  // For duration pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _lastDuration = '';
  
  // Track last hour for haptic feedback
  int _lastStartHour = -1;
  int _lastEndHour = -1;

  // Extended presets with venue-specific options
  final List<_TimePreset> _presets = [
    _TimePreset('Afternoon', 12, 17, false, Icons.wb_sunny_outlined),
    _TimePreset('Evening', 18, 23, false, Icons.nights_stay_outlined),
    _TimePreset('Late Night', 22, 26, true, Icons.dark_mode_outlined),
    _TimePreset('Dinner', 18, 22, false, Icons.restaurant_outlined),
    _TimePreset('Club Night', 22, 28, true, Icons.music_note_outlined),
    _TimePreset('Happy Hour', 16, 19, false, Icons.local_bar_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromSlot();
    _setupPulseAnimation();
  }
  
  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutBack),
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      }
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeFromSlot() {
    final slot = widget.initialSlot;
    if (slot != null) {
      _startValue = (slot.startHour * 60 + slot.startMinute).toDouble();
      int endMins = slot.endHour * 60 + slot.endMinute;
      if (slot.isOvernight) endMins += 24 * 60;
      _endValue = endMins.toDouble();
      _isOvernight = slot.isOvernight;
    } else {
      // Default: Evening (6 PM - 11 PM)
      _startValue = 18 * 60; // 6 PM
      _endValue = 23 * 60; // 11 PM
      _isOvernight = false;
    }
    _lastStartHour = (_startValue / 60).floor();
    _lastEndHour = (_endValue / 60).floor();
  }

  GigTimeSlot _buildTimeSlot() {
    int startMins = _startValue.round();
    int endMins = _endValue.round();
    
    // Determine if overnight
    bool overnight = endMins >= 24 * 60;
    
    // Normalize end time if overnight
    int actualEndMins = overnight ? endMins - 24 * 60 : endMins;
    
    return GigTimeSlot(
      date: widget.date,
      startHour: startMins ~/ 60,
      startMinute: startMins % 60,
      endHour: actualEndMins ~/ 60,
      endMinute: actualEndMins % 60,
      isOvernight: overnight,
    );
  }
  
  /// Check if current slot conflicts with existing availability
  String? _getConflictWarning() {
    if (widget.existingSlots == null || widget.existingSlots!.isEmpty) {
      return null;
    }
    
    final currentStart = _startValue;
    final currentEnd = _endValue;
    
    for (final existing in widget.existingSlots!) {
      // Skip if different date
      if (existing.date.day != widget.date.day ||
          existing.date.month != widget.date.month ||
          existing.date.year != widget.date.year) {
        continue;
      }
      
      // Parse existing slot times (format: "HH:mm")
      final startParts = existing.startTime.split(':');
      final endParts = existing.endTime.split(':');
      
      final existingStartHour = int.tryParse(startParts[0]) ?? 0;
      final existingStartMinute = startParts.length > 1 ? int.tryParse(startParts[1]) ?? 0 : 0;
      final existingEndHour = int.tryParse(endParts[0]) ?? 0;
      final existingEndMinute = endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0;
      
      double existingStart = (existingStartHour * 60 + existingStartMinute).toDouble();
      double existingEnd = (existingEndHour * 60 + existingEndMinute).toDouble();
      if (existing.isOvernight) existingEnd += 24 * 60;
      
      // Check for overlap
      if (currentStart < existingEnd && currentEnd > existingStart) {
        final displayStart = _formatTimeForDisplay(existingStartHour, existingStartMinute);
        final displayEnd = _formatTimeForDisplay(existingEndHour, existingEndMinute);
        return 'Overlaps with $displayStart - $displayEnd';
      }
    }
    return null;
  }
  
  String _formatTimeForDisplay(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }
  
  /// Copy availability from last week
  void _copyFromLastWeek() {
    if (widget.lastWeekSlot != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _startValue = (widget.lastWeekSlot!.startHour * 60 + widget.lastWeekSlot!.startMinute).toDouble();
        int endMins = widget.lastWeekSlot!.endHour * 60 + widget.lastWeekSlot!.endMinute;
        if (widget.lastWeekSlot!.isOvernight) endMins += 24 * 60;
        _endValue = endMins.toDouble();
        _isOvernight = widget.lastWeekSlot!.isOvernight;
      });
      widget.onChanged(_buildTimeSlot());
      _triggerPulse();
    }
  }
  
  void _triggerPulse() {
    if (!_pulseController.isAnimating) {
      _pulseController.forward();
    }
  }

  void _onStartSliderChanged(double val) {
    final newHour = (val / 60).floor();
    
    // Haptic at hourly marks
    if (newHour != _lastStartHour) {
      HapticFeedback.lightImpact();
      _lastStartHour = newHour;
    }
    
    setState(() => _startValue = val);
    _checkDurationChanged();
    widget.onChanged(_buildTimeSlot());
  }
  
  void _onEndSliderChanged(double val) {
    final newHour = (val / 60).floor();
    
    // Haptic at hourly marks
    if (newHour != _lastEndHour) {
      HapticFeedback.lightImpact();
      _lastEndHour = newHour;
    }
    
    setState(() {
      _endValue = val;
      _isOvernight = val >= 24 * 60;
    });
    _checkDurationChanged();
    widget.onChanged(_buildTimeSlot());
  }
  
  void _checkDurationChanged() {
    final slot = _buildTimeSlot();
    final newDuration = slot.durationDisplay;
    if (newDuration != _lastDuration) {
      _lastDuration = newDuration;
      _triggerPulse();
    }
  }

  void _onSliderChanged() {
    HapticFeedback.selectionClick();
    final slot = _buildTimeSlot();
    setState(() {
      _isOvernight = slot.isOvernight;
    });
    widget.onChanged(slot);
  }

  void _applyPreset(_TimePreset preset) {
    HapticFeedback.mediumImpact();
    setState(() {
      _startValue = (preset.startHour * 60).toDouble();
      _endValue = (preset.endHour * 60).toDouble();
      _isOvernight = preset.isOvernight;
    });
    widget.onChanged(_buildTimeSlot());
    _triggerPulse();
  }

  String _formatMinutes(double minutes) {
    int mins = minutes.round();
    int hour = (mins ~/ 60) % 24;
    int minute = mins % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    if (minute == 0) {
      return '$displayHour $period';
    }
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final slot = _buildTimeSlot();
    final isValid = slot.isValid;
    final brightness = widget.brightness;
    final conflictWarning = _getConflictWarning();
    final hasConflict = conflictWarning != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Copy from last week button (if available)
        if (widget.lastWeekSlot != null) ...[
          GestureDetector(
            onTap: _copyFromLastWeek,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.crimson.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.crimson.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.content_copy_rounded,
                    size: 16,
                    color: AppColors.crimson,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Copy from last week (${widget.lastWeekSlot!.displayStartTime} - ${widget.lastWeekSlot!.displayEndTime})',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Quick Presets with icons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _presets.map((preset) {
              final startMatch = _startValue.round() == preset.startHour * 60;
              final endMatch = _endValue.round() == preset.endHour * 60;
              final isSelected = startMatch && endMatch;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PresetChip(
                  label: preset.name,
                  icon: preset.icon,
                  isSelected: isSelected,
                  brightness: brightness,
                  onTap: () => _applyPreset(preset),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Conflict Warning
        if (hasConflict) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conflictWarning,
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Time Display Card
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasConflict 
                  ? AppColors.warning 
                  : (isValid ? AppColors.border(brightness) : AppColors.error),
              width: (isValid && !hasConflict) ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isValid 
                    ? Colors.black.withOpacity(0.05)
                    : AppColors.error.withOpacity(0.15),
                blurRadius: isValid ? 8 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Start & End Times
              Row(
                children: [
                  Expanded(
                    child: _TimeDisplay(
                      label: 'START',
                      time: slot.displayStartTime,
                      brightness: brightness,
                      color: AppColors.success,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textSec(brightness),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: _TimeDisplay(
                      label: _isOvernight ? 'END (NEXT DAY)' : 'END',
                      time: slot.displayEndTime,
                      brightness: brightness,
                      color: AppColors.crimson,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Animated Duration Badge
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isValid 
                        ? AppColors.crimson.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isValid ? Icons.schedule_rounded : Icons.warning_rounded,
                        size: 16,
                        color: isValid ? AppColors.crimson : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isValid 
                              ? 'Duration: ${slot.durationDisplay}'
                              : slot.validationError ?? 'Invalid',
                          style: TextStyle(
                            color: isValid ? AppColors.crimson : AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Start Time Slider with tooltip and tick marks
        _EnhancedSliderSection(
          label: 'Start Time',
          value: _startValue,
          min: _minMinutes,
          max: _endValue - 30,
          onChanged: _onStartSliderChanged,
          formatValue: _formatMinutes,
          brightness: brightness,
          color: AppColors.success,
        ),
        const SizedBox(height: 12),

        // End Time Slider with tooltip and tick marks
        _EnhancedSliderSection(
          label: 'End Time',
          value: _endValue,
          min: _startValue + 30,
          max: _maxMinutes,
          onChanged: _onEndSliderChanged,
          formatValue: _formatMinutes,
          brightness: brightness,
          color: AppColors.crimson,
          showOvernightLabel: _isOvernight,
        ),
        const SizedBox(height: 12),

        // Interactive Time Bar (drag to select)
        _InteractiveTimeBar(
          startValue: _startValue,
          endValue: _endValue,
          minValue: _minMinutes,
          maxValue: _maxMinutes,
          brightness: brightness,
          isOvernight: _isOvernight,
          onStartChanged: _onStartSliderChanged,
          onEndChanged: _onEndSliderChanged,
        ),
      ],
    );
  }
}

/// Preset chip button with icon
class _PresetChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Brightness brightness;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.crimson, AppColors.crimsonDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? AppColors.crimson 
                : AppColors.border(brightness),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.crimson.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSec(brightness),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : AppColors.text(brightness),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Time display box
class _TimeDisplay extends StatelessWidget {
  final String label;
  final String time;
  final Brightness brightness;
  final Color color;

  const _TimeDisplay({
    required this.label,
    required this.time,
    required this.brightness,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

/// Enhanced Slider section with tooltip and hour tick marks
class _EnhancedSliderSection extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String Function(double) formatValue;
  final Brightness brightness;
  final Color color;
  final bool showOvernightLabel;

  const _EnhancedSliderSection({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.formatValue,
    required this.brightness,
    required this.color,
    this.showOvernightLabel = false,
  });

  @override
  State<_EnhancedSliderSection> createState() => _EnhancedSliderSectionState();
}

class _EnhancedSliderSectionState extends State<_EnhancedSliderSection> {
  bool _isDragging = false;
  
  @override
  Widget build(BuildContext context) {
    double snappedValue = (widget.value / 15).round() * 15.0;
    snappedValue = snappedValue.clamp(widget.min, widget.max);
    
    // Calculate thumb position percentage for tooltip
    final range = widget.max - widget.min;
    final thumbPercent = range > 0 ? (snappedValue - widget.min) / range : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: AppColors.textSec(widget.brightness),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (widget.showOvernightLabel)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Next Day',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Slider with tooltip overlay
        LayoutBuilder(
          builder: (context, constraints) {
            final sliderWidth = constraints.maxWidth;
            // Clamp tooltip position to stay within bounds (tooltip width ~70)
            final tooltipX = (sliderWidth * thumbPercent).clamp(35.0, sliderWidth - 35);
            
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Hour tick marks under slider
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildTickMarks(widget.min, widget.max, sliderWidth, widget.brightness),
                ),
                
                // Slider with padding to prevent thumb overflow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: widget.color,
                      inactiveTrackColor: widget.color.withOpacity(0.15),
                      thumbColor: Colors.white,
                      overlayColor: widget.color.withOpacity(0.2),
                      trackHeight: 8,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                        elevation: 3,
                        pressedElevation: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: Slider(
                      value: snappedValue.clamp(widget.min, widget.max),
                      min: widget.min,
                      max: widget.max,
                      divisions: ((widget.max - widget.min) / 15).round().clamp(1, 1000),
                      onChangeStart: (_) => setState(() => _isDragging = true),
                      onChangeEnd: (_) => setState(() => _isDragging = false),
                      onChanged: (val) {
                        double snapped = (val / 15).round() * 15.0;
                        widget.onChanged(snapped);
                      },
                    ),
                  ),
                ),
                
                // Floating tooltip (visible when dragging)
                if (_isDragging)
                  Positioned(
                    left: tooltipX - 35,
                    top: -35,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.formatValue(snappedValue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildTickMarks(double min, double max, double width, Brightness brightness) {
    final List<Widget> ticks = [];
    final range = max - min;
    
    // Add tick at each hour
    for (double mins = min; mins <= max; mins += 60) {
      final percent = (mins - min) / range;
      final left = width * percent;
      
      // Only show tick marks at full hours
      if (mins % 60 == 0) {
        ticks.add(
          Positioned(
            left: left - 0.5,
            top: 0,
            child: Container(
              width: 1,
              height: 4,
              color: AppColors.textSec(brightness).withOpacity(0.3),
            ),
          ),
        );
      }
    }
    
    return SizedBox(
      height: 4,
      child: Stack(children: ticks),
    );
  }
}

/// Interactive time bar with drag-to-select
class _InteractiveTimeBar extends StatefulWidget {
  final double startValue;
  final double endValue;
  final double minValue;
  final double maxValue;
  final Brightness brightness;
  final bool isOvernight;
  final ValueChanged<double> onStartChanged;
  final ValueChanged<double> onEndChanged;

  const _InteractiveTimeBar({
    required this.startValue,
    required this.endValue,
    required this.minValue,
    required this.maxValue,
    required this.brightness,
    required this.isOvernight,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  State<_InteractiveTimeBar> createState() => _InteractiveTimeBarState();
}

class _InteractiveTimeBarState extends State<_InteractiveTimeBar> {
  bool _draggingStart = false;
  bool _draggingEnd = false;

  @override
  Widget build(BuildContext context) {
    final range = widget.maxValue - widget.minValue;
    final startPercent = (widget.startValue - widget.minValue) / range;
    final endPercent = (widget.endValue - widget.minValue) / range;

    return Column(
      children: [
        // Time markers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('6 AM', style: _markerStyle(widget.brightness)),
            Text('12 PM', style: _markerStyle(widget.brightness)),
            Text('6 PM', style: _markerStyle(widget.brightness)),
            Text('12 AM', style: _markerStyle(widget.brightness)),
            Text('4 AM', style: _markerStyle(widget.brightness)),
          ],
        ),
        const SizedBox(height: 4),
        
        // Interactive Bar
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final startX = width * startPercent;
            final endX = width * endPercent;
            final selectionWidth = endX - startX;

            return GestureDetector(
              onHorizontalDragStart: (details) {
                final localX = details.localPosition.dx;
                // Determine which handle to drag
                if ((localX - startX).abs() < (localX - endX).abs()) {
                  _draggingStart = true;
                  _draggingEnd = false;
                } else {
                  _draggingStart = false;
                  _draggingEnd = true;
                }
              },
              onHorizontalDragUpdate: (details) {
                final localX = details.localPosition.dx.clamp(0.0, width);
                final percent = localX / width;
                final minutes = widget.minValue + (range * percent);
                final snapped = (minutes / 15).round() * 15.0;
                
                if (_draggingStart && snapped < widget.endValue - 30) {
                  HapticFeedback.selectionClick();
                  widget.onStartChanged(snapped.clamp(widget.minValue, widget.endValue - 30));
                } else if (_draggingEnd && snapped > widget.startValue + 30) {
                  HapticFeedback.selectionClick();
                  widget.onEndChanged(snapped.clamp(widget.startValue + 30, widget.maxValue));
                }
              },
              onHorizontalDragEnd: (_) {
                _draggingStart = false;
                _draggingEnd = false;
              },
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.inputFill(widget.brightness),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    // Midnight marker
                    Positioned(
                      left: width * ((24 * 60 - widget.minValue) / range),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: AppColors.textSec(widget.brightness).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    
                    // Selection with handles
                    Positioned(
                      left: startX,
                      top: 2,
                      bottom: 2,
                      child: Container(
                        width: selectionWidth.clamp(0, width - startX),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isOvernight
                                ? [AppColors.success, AppColors.warning, AppColors.crimson]
                                : [AppColors.success, AppColors.crimson],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Start handle
                            Container(
                              width: 12,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 3,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            // End handle
                            Container(
                              width: 12,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 3,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  TextStyle _markerStyle(Brightness brightness) => TextStyle(
    color: AppColors.textSec(brightness),
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}

/// Preset data class with icon
class _TimePreset {
  final String name;
  final int startHour;
  final int endHour;
  final bool isOvernight;
  final IconData? icon;

  const _TimePreset(this.name, this.startHour, this.endHour, this.isOvernight, [this.icon]);
}
