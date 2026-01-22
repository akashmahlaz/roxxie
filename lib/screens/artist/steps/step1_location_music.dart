import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/artist_models.dart';
import '../../../core/theme/theme.dart';

/// 🎸 ARTIST STEP 1: LOCATION & MUSIC PREFERENCES
/// 
/// Features:
/// - GPS auto-detect location (city + country)
/// - Interactive OpenStreetMap preview
/// - Preferred genres selection (what you play)
/// 
/// This step is SKIPPABLE - user can proceed without filling

class ArtistStep1LocationMusic extends StatefulWidget {
  final ArtistProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const ArtistStep1LocationMusic({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<ArtistStep1LocationMusic> createState() => _ArtistStep1LocationMusicState();
}

class _ArtistStep1LocationMusicState extends State<ArtistStep1LocationMusic> {
  final MapController _mapController = MapController();
  
  // Location state
  bool _isDetectingLocation = false;
  bool _locationDetected = false;
  String? _detectedCity;
  String? _detectedCountry;
  LatLng _currentPosition = const LatLng(40.7128, -74.0060); // Default: NYC
  
  // Available genres for selection
  final List<String> _allGenres = [
    'Rock', 'Jazz', 'Pop', 'Hip-Hop', 'R&B', 'Country',
    'Electronic', 'Classical', 'Folk', 'Indie', 'Metal',
    'Blues', 'Reggae', 'Soul', 'Funk', 'Latin', 'Punk', 'Alternative',
  ];

  @override
  void initState() {
    super.initState();
    // Check if location already exists in profile
    if (widget.profileData.latitude != null && widget.profileData.longitude != null) {
      _currentPosition = LatLng(
        widget.profileData.latitude!,
        widget.profileData.longitude!,
      );
      _detectedCity = widget.profileData.city;
      _detectedCountry = widget.profileData.country;
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
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permission denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permission permanently denied. Enable in settings.');
        return;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      // Reverse geocode to get city & country
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _detectedCity = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
          _detectedCountry = place.country ?? 'Unknown';
          _locationDetected = true;
          
          // Update profile data
          widget.profileData.city = _detectedCity;
          widget.profileData.country = _detectedCountry;
          widget.profileData.latitude = position.latitude;
          widget.profileData.longitude = position.longitude;
        });
        
        // Move map to detected location
        _mapController.move(_currentPosition, 14);
        
        widget.onDataChanged();
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showLocationError('Could not detect location. Try again.');
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }
  
  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    setState(() => _isDetectingLocation = false);
  }

  void _toggleGenre(String genre) {
    HapticFeedback.selectionClick();
    setState(() {
      final genres = widget.profileData.genres;
      if (genres.contains(genre)) {
        genres.remove(genre);
      } else {
        if (genres.length < 5) { // Max 5 genres for artists
          genres.add(genre);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Maximum 5 genres allowed'),
              backgroundColor: AppColors.crimson,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    });
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final selectedGenres = widget.profileData.genres;

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
              "Where do you perform?",
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
              'Help venues find you nearby',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),

          // ═══════════════════════════════════════════════════════════════
          // MAP WITH GPS
          // ═══════════════════════════════════════════════════════════════
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.slate : Colors.grey[300]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // OpenStreetMap
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 12,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none, // Disable user interaction
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.gigmatch.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.crimson,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.crimson.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: Colors.white,
                                size: 24,
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
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: AppColors.crimson,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Detecting location...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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

          // Location status card
          if (_locationDetected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location detected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          '$_detectedCity, $_detectedCountry',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _detectLocation,
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Colors.green[700],
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

          // ═══════════════════════════════════════════════════════════════
          // MUSIC GENRES
          // ═══════════════════════════════════════════════════════════════
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
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
                      "What genres do you play?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(brightness),
                      ),
                    ),
                    Text(
                      'Select up to 5 genres',
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
          
          // Selected count
          if (selectedGenres.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${selectedGenres.length}/5 genres selected',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          
          // Bottom spacing for button
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
