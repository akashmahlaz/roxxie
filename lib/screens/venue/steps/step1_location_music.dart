import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 1: LOCATION & MUSIC PREFERENCES
///
/// Features:
/// - GPS auto-detect location (city + country)
/// - Interactive OpenStreetMap preview
/// - Preferred genres selection
///
/// This step is SKIPPABLE - user can proceed without filling

class Step1LocationMusic extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const Step1LocationMusic({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<Step1LocationMusic> createState() => _Step1LocationMusicState();
}

class _Step1LocationMusicState extends State<Step1LocationMusic> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  // Location state
  bool _isDetectingLocation = false;
  bool _locationDetected = false;
  String? _detectedCity;
  String? _detectedCountry;
  LatLng _currentPosition = const LatLng(40.7128, -74.0060); // Default: NYC

  // Available genres for selection
  final List<String> _allGenres = [
    'Jazz',
    'Rock',
    'Pop',
    'EDM',
    'Hip Hop',
    'R&B',
    'Country',
    'Blues',
    'Classical',
    'Indie',
    'Folk',
    'Reggae',
    'Metal',
    'Soul',
    'Funk',
    'Latin',
  ];

  @override
  void initState() {
    super.initState();
    // Check if location already exists in profile
    if (widget.profileData.location.hasValidCoordinates) {
      _currentPosition = LatLng(
        widget.profileData.location.latitude,
        widget.profileData.location.longitude,
      );
      _detectedCity = widget.profileData.location.city;
      _detectedCountry = widget.profileData.location.country;
      _locationDetected = _detectedCity != null && _detectedCountry != null;
    } else {
      // Auto-detect on load
      _detectLocation();
    }
  }

  Future<void> _detectLocation() async {
    if (_isDetectingLocation) return;

    setState(() => _isDetectingLocation = true);
    HapticFeedback.lightImpact();

    try {
      final result = await _locationService.getCurrentLocationWithAddress();
      if (!mounted) return;

      if (result == null) {
        final state = await _locationService.getPermissionState();
        if (!mounted) return;

        if (state == LocationPermissionState.serviceDisabled) {
          _showLocationError(
            'Location services are disabled. Please enable GPS.',
            actionLabel: 'Settings',
            onAction: _locationService.openDeviceLocationSettings,
          );
          return;
        }

        if (state == LocationPermissionState.deniedForever) {
          _showLocationError(
            'Location permission denied. Enable it in Settings.',
            actionLabel: 'Settings',
            onAction: _locationService.openLocationSettings,
          );
          return;
        }

        _showLocationError('Could not detect location. Try again.');
        return;
      }

      _applyLocationResult(result, quick: false);
    } catch (e) {
      _showLocationError('Could not detect location. Try again.');
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _applyLocationResult(LocationResult result, {required bool quick}) {
    setState(() {
      _currentPosition = LatLng(result.latitude, result.longitude);
      _detectedCity = result.city ?? _detectedCity ?? 'Unknown';
      _detectedCountry = result.country ?? _detectedCountry ?? 'Unknown';
      _locationDetected = true;

      // Update profile data
      widget.profileData.location.city = _detectedCity;
      widget.profileData.location.country = _detectedCountry;
      widget.profileData.location.coordinates = [
        result.longitude,
        result.latitude,
      ];
      widget.profileData.location.formattedAddress = result.address;
    });

    _mapController.move(_currentPosition, quick ? 12 : 14);
    widget.onDataChanged();
    if (!quick) HapticFeedback.mediumImpact();
  }

  void _showLocationError(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
    setState(() => _isDetectingLocation = false);
  }

  void _toggleGenre(String genre) {
    HapticFeedback.selectionClick();
    setState(() {
      final genres = widget.profileData.gigPreferences.preferredGenres;
      if (genres.contains(genre)) {
        genres.remove(genre);
      } else {
        genres.add(genre);
      }
    });
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final selectedGenres = widget.profileData.gigPreferences.preferredGenres;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════════════
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.crimson,
                    AppColors.crimson.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              'Where are you located?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.text(brightness),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Help musicians find gigs near them',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════
          // MAP PREVIEW (Interactive OpenStreetMap)
          // ═══════════════════════════════════════════════════════════════
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _locationDetected
                    ? AppColors.crimson.withValues(alpha: 0.5)
                    : (isDark ? AppColors.slate : Colors.grey[300]!),
                width: _locationDetected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // OpenStreetMap
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 13,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none, // Disable interaction
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.gigmatch.roxxie',
                      ),
                      // Location marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            width: 60,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.crimson,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.crimson.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Loading overlay
                  if (_isDetectingLocation)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Detecting location...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
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
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════════════════
          // DETECTED LOCATION DISPLAY
          // ═══════════════════════════════════════════════════════════════
          if (_locationDetected) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location detected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_detectedCity, $_detectedCountry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: _isDetectingLocation ? null : _detectLocation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.green[600],
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Detect Location Button
            GestureDetector(
              onTap: _isDetectingLocation ? null : _detectLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.crimson.withValues(alpha: 0.15),
                      AppColors.crimson.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      color: AppColors.crimson,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Detect My Location',
                      style: TextStyle(
                        color: AppColors.crimson,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // MUSIC PREFERENCES
          // ═══════════════════════════════════════════════════════════════
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: AppColors.crimson,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's your vibe?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(brightness),
                      ),
                    ),
                    Text(
                      'Select genres you prefer',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Genre Chips (More rounded)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allGenres.map((genre) {
              final isSelected = selectedGenres.contains(genre);
              return GestureDetector(
                onTap: () => _toggleGenre(genre),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.crimson,
                              AppColors.crimson.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? AppColors.graphite : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(50), // Fully rounded
                    border: Border.all(
                      color: isSelected
                          ? AppColors.crimson
                          : (isDark ? AppColors.slate : Colors.grey[300]!),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.crimson.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        genre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.text(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Bottom spacing for button
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
