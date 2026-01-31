import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../core/services/services.dart';

/// 📍 SMART LOCATION PICKER
///
/// Modern location UX with:
/// - Auto-detection on load (with permission)
/// - Single autocomplete field
/// - Visual confirmation
/// - Easy to change

class SmartLocationPicker extends StatefulWidget {
  final String? initialCity;
  final String? initialCountry;
  final Function(String city, String country, double? lat, double? lng)?
  onLocationSelected;
  final bool autoDetect;

  const SmartLocationPicker({
    super.key,
    this.initialCity,
    this.initialCountry,
    this.onLocationSelected,
    this.autoDetect = true,
  });

  @override
  State<SmartLocationPicker> createState() => _SmartLocationPickerState();
}

class _SmartLocationPickerState extends State<SmartLocationPicker> {
  final _locationService = LocationService();
  final _searchController = TextEditingController();

  String? _city;
  String? _country;
  double? _latitude;
  double? _longitude;
  bool _isDetecting = false;
  bool _isManualEntry = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _city = widget.initialCity;
    _country = widget.initialCountry;

    if (widget.autoDetect && _city == null) {
      _autoDetectLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _autoDetectLocation() async {
    setState(() {
      _isDetecting = true;
      _errorMessage = null;
    });

    try {
      final result = await _locationService.getCurrentLocationWithAddress();

      if (result != null && mounted) {
        setState(() {
          _city = result.city;
          _country = result.country;
          _latitude = result.latitude;
          _longitude = result.longitude;
          _isDetecting = false;
        });

        widget.onLocationSelected?.call(
          _city!,
          _country!,
          _latitude,
          _longitude,
        );
      } else {
        setState(() {
          _isDetecting = false;
          _errorMessage = 'Location not detected';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
          _errorMessage = 'Could not detect location';
        });
      }
    }
  }

  void _enterManually() {
    setState(() {
      _isManualEntry = true;
    });
  }

  void _cancelManualEntry() {
    setState(() {
      _isManualEntry = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (_isDetecting) {
      return _buildDetectingState(brightness);
    }

    if (_city != null && !_isManualEntry) {
      return _buildDetectedLocation(brightness);
    }

    return _buildManualEntry(brightness);
  }

  Widget _buildDetectingState(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.crimson),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detecting your location...',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This helps us find venues near you',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedLocation(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location detected',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_city, $_country',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _enterManually,
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your location',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: TextStyle(color: AppColors.text(brightness)),
          decoration: InputDecoration(
            hintText: 'City or Zip Code',
            hintStyle: TextStyle(color: AppColors.textSec(brightness)),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.crimson),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppColors.textTert(brightness),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                if (_city != null)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textTert(brightness),
                    ),
                    onPressed: _cancelManualEntry,
                  ),
              ],
            ),
            filled: true,
            fillColor: AppColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(brightness)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(brightness)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.crimson, width: 2),
            ),
          ),
          onChanged: (value) {
            setState(() {});
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              // For now, parse simple city input
              _handleManualLocation(value);
            }
          },
        ),

        const SizedBox(height: 12),

        // Auto-detect option
        TextButton.icon(
          onPressed: _autoDetectLocation,
          icon: Icon(Icons.my_location_rounded, size: 18),
          label: const Text('Auto-detect my location'),
          style: TextButton.styleFrom(foregroundColor: AppColors.crimson),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  void _handleManualLocation(String input) {
    // Simple parsing - in production, use Google Places API
    final parts = input.split(',').map((e) => e.trim()).toList();

    setState(() {
      if (parts.length >= 2) {
        _city = parts[0];
        _country = parts[1];
      } else {
        _city = input;
        _country = 'Unknown';
      }
      _isManualEntry = false;
    });

    widget.onLocationSelected?.call(_city!, _country!, null, null);
  }
}
