/// 📍 GIGMATCH Location Service - BULLETPROOF VERSION
/// Handles location services with comprehensive error handling and edge cases
library;

import 'dart:io';
import 'dart:ui' show Locale;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../exceptions.dart';

enum LocationPermissionState {
  granted,
  serviceDisabled,
  denied,
  deniedForever,
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// 📍 Get current location with comprehensive error handling
  Future<Position> getCurrentLocation() async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('📍 [LocationService] Getting current location...');

      // Check permissions first
      await _checkLocationPermissions();

      // Check if location service is enabled
      await _checkLocationServiceEnabled();

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      debugPrint('📍 [LocationService] Location obtained in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📍 [LocationService] Coordinates: ${position.latitude}, ${position.longitude}');

      return position;

    } on PermissionDeniedException {
      throw PermissionException('Location permission denied. Please enable location access in settings.');
    } on LocationServiceDisabledException {
      throw ServiceDisabledException('Location service is disabled. Please enable location services.');
    } catch (e) {
      debugPrint('❌ [LocationService] Get location error: $e');
      throw LocationTimeoutException('Failed to get location: $e');
    } finally {
      stopwatch.stop();
    }
  }

  /// 📍 Get last known location (faster, may be outdated)
  Future<Position?> getLastKnownLocation() async {
    try {
      debugPrint('📍 [LocationService] Getting last known location...');

      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        debugPrint('📍 [LocationService] Last known location: ${position.latitude}, ${position.longitude}');
      } else {
        debugPrint('📍 [LocationService] No last known location available');
      }

      return position;

    } catch (e) {
      debugPrint('❌ [LocationService] Get last known location error: $e');
      return null;
    }
  }

  /// 🌍 Get address from coordinates with retry logic
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🌍 [LocationService] Getting address for: $latitude, $longitude');

      // Validate coordinates
      _validateCoordinates(latitude, longitude);

      // Retry logic for geocoding (can be flaky)
      String? address;
      Exception? lastError;

      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          debugPrint('🌍 [LocationService] Geocoding attempt $attempt/$_maxRetries');

          final placemarks = await placemarkFromCoordinates(
            latitude,
            longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            address = _formatAddress(placemark);
            debugPrint('🌍 [LocationService] Address found: $address');
            break;
          }

        } on SocketException {
          lastError = NetworkException('Network error during geocoding');
          if (attempt < _maxRetries) {
            final delay = _retryDelay * attempt;
            debugPrint('⚠️ [LocationService] Geocoding attempt $attempt failed, retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        } catch (e) {
          lastError = LocationTimeoutException('Geocoding error: $e');
          if (attempt < _maxRetries) {
            final delay = _retryDelay * attempt;
            debugPrint('⚠️ [LocationService] Geocoding attempt $attempt failed, retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        }
      }

      if (address == null) {
        throw lastError ?? LocationTimeoutException('Failed to get address after $_maxRetries attempts');
      }

      debugPrint('🌍 [LocationService] Address resolved in ${stopwatch.elapsedMilliseconds}ms');
      return address;

    } catch (e) {
      debugPrint('❌ [LocationService] Get address error: $e');
      throw LocationTimeoutException('Failed to get address: $e');
    } finally {
      stopwatch.stop();
    }
  }

  /// 📍 Get coordinates from address with retry logic
  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('📍 [LocationService] Getting coordinates for address: $address');

      // Validate address
      if (address.trim().isEmpty) {
        throw ValidationException('Address cannot be empty');
      }

      // Retry logic for geocoding
      List<Location>? locations;
      Exception? lastError;

      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          debugPrint('📍 [LocationService] Address geocoding attempt $attempt/$_maxRetries');

          locations = await locationFromAddress(
            address,
          );

          if (locations != null && locations.isNotEmpty) {
            debugPrint('📍 [LocationService] Found ${locations.length} locations');
            break;
          }

        } on SocketException {
          lastError = NetworkException('Network error during address geocoding');
          if (attempt < _maxRetries) {
            final delay = _retryDelay * attempt;
            debugPrint('⚠️ [LocationService] Address geocoding attempt $attempt failed, retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        } catch (e) {
          lastError = LocationTimeoutException('Address geocoding error: $e');
          if (attempt < _maxRetries) {
            final delay = _retryDelay * attempt;
            debugPrint('⚠️ [LocationService] Address geocoding attempt $attempt failed, retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        }
      }

      if (locations == null || locations.isEmpty) {
        throw lastError ?? LocationTimeoutException('Failed to find coordinates for address after $_maxRetries attempts');
      }

      debugPrint('📍 [LocationService] Address resolved in ${stopwatch.elapsedMilliseconds}ms');
      return locations;

    } catch (e) {
      debugPrint('❌ [LocationService] Get coordinates error: $e');
      throw LocationTimeoutException('Failed to get coordinates: $e');
    } finally {
      stopwatch.stop();
    }
  }

  /// 📏 Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    try {
      _validateCoordinates(lat1, lon1);
      _validateCoordinates(lat2, lon2);

      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    } catch (e) {
      debugPrint('❌ [LocationService] Calculate distance error: $e');
      return 0.0;
    }
  }

  /// 📏 Calculate distance in kilometers
  double calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    return calculateDistance(lat1, lon1, lat2, lon2) / 1000;
  }

  /// 📏 Calculate distance in miles
  double calculateDistanceInMiles(double lat1, double lon1, double lat2, double lon2) {
    return calculateDistance(lat1, lon1, lat2, lon2) / 1609.34;
  }

  /// 🔍 Check if location is within radius
  bool isWithinRadius(double centerLat, double centerLon, double pointLat, double pointLon, double radiusKm) {
    final distance = calculateDistanceInKm(centerLat, centerLon, pointLat, pointLon);
    return distance <= radiusKm;
  }

  /// 📍 Get location with address in one call
  Future<Map<String, dynamic>> getLocationWithAddress() async {
    try {
      debugPrint('📍 [LocationService] Getting location with address...');

      // Try to get current location first
      final position = await getCurrentLocation();

      // Get address for the coordinates
      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('❌ [LocationService] Get location with address error: $e');
      rethrow;
    }
  }

  /// 🔍 Search for locations by query
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🔍 [LocationService] Searching locations: $query');

      if (query.trim().isEmpty) {
        throw ValidationException('Search query cannot be empty');
      }

      final locations = await getCoordinatesFromAddress(query);

      final results = <Map<String, dynamic>>[];

      for (final location in locations) {
        try {
          final address = await getAddressFromCoordinates(
            location.latitude,
            location.longitude,
          );

          results.add({
            'latitude': location.latitude,
            'longitude': location.longitude,
            'address': address,
            'formattedAddress': address,
          });

        } catch (e) {
          debugPrint('⚠️ [LocationService] Failed to get address for location: $e');
          // Continue with basic coordinates if address fails
          results.add({
            'latitude': location.latitude,
            'longitude': location.longitude,
            'address': '${location.latitude}, ${location.longitude}',
            'formattedAddress': '${location.latitude}, ${location.longitude}',
          });
        }
      }

      debugPrint('🔍 [LocationService] Found ${results.length} locations in ${stopwatch.elapsedMilliseconds}ms');
      return results;

    } catch (e) {
      debugPrint('❌ [LocationService] Search locations error: $e');
      throw LocationTimeoutException('Failed to search locations: $e');
    } finally {
      stopwatch.stop();
    }
  }

  /// 🔐 Request location permissions
  Future<bool> requestLocationPermissions() async {
    try {
      debugPrint('🔐 [LocationService] Requesting location permissions...');

      final status = await Permission.location.request();

      switch (status) {
        case PermissionStatus.granted:
          debugPrint('✅ [LocationService] Location permission granted');
          return true;
        case PermissionStatus.denied:
          debugPrint('⚠️ [LocationService] Location permission denied');
          return false;
        case PermissionStatus.permanentlyDenied:
          debugPrint('❌ [LocationService] Location permission permanently denied');
          return false;
        case PermissionStatus.limited:
          debugPrint('⚠️ [LocationService] Location permission limited');
          return false;
        default:
          debugPrint('❌ [LocationService] Unknown permission status: $status');
          return false;
      }

    } catch (e) {
      debugPrint('❌ [LocationService] Request permissions error: $e');
      return false;
    }
  }

  /// 🔐 Check location permissions
  Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('❌ [LocationService] Check permissions error: $e');
      return false;
    }
  }

  /// 🔐 Open app settings
  Future<bool> openAppSettings() async {
    try {
      debugPrint('🔐 [LocationService] Opening app settings...');
      return await openAppSettings();
    } catch (e) {
      debugPrint('❌ [LocationService] Open app settings error: $e');
      return false;
    }
  }

  /// Get the current permission/service state (no prompts)
  Future<LocationPermissionState> getPermissionState() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionState.serviceDisabled;

    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionState.deniedForever;
    }

    if (permission == LocationPermission.denied) {
      return LocationPermissionState.denied;
    }

    return LocationPermissionState.granted;
  }

  /// Request location permission - ALWAYS requests if not granted
  Future<bool> requestPermission() async {
    // Check if service is enabled first
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    // Check current permission status
    var permission = await Geolocator.checkPermission();

    // If already granted, return true
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }

    // If permanently denied, can't request again
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return false;
    }

    // Request permission (will show dialog)
    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      debugPrint('Location permissions are denied');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  /// Get current position - tries last known first for speed, then current
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      // Try to get last known position first (instant)
      Position? position = await Geolocator.getLastKnownPosition();

      // If we have a recent position (less than 5 mins old), use it
      if (position != null &&
          DateTime.now().difference(position.timestamp).inMinutes < 5) {
        debugPrint('Using cached position: ${position.latitude}, ${position.longitude}');
        return position;
      }

      // Get fresh position with medium accuracy (faster than high)
      debugPrint('Fetching fresh GPS position...');
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );

      debugPrint('Got position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting position: $e');

      // Fallback: try with lower accuracy (faster)
      try {
        debugPrint('Trying low accuracy fallback...');
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (e2) {
        debugPrint('Fallback position also failed: $e2');

        // Last resort: try last known again
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          debugPrint('Using stale last known position as final fallback');
          return lastKnown;
        }

        return null;
      }
    }
  }

  /// Get current location as formatted address - RELIABLE VERSION
  Future<LocationResult?> getCurrentLocationWithAddress() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) {
        debugPrint('getCurrentLocationWithAddress: No position available');
        return null;
      }

      String? address;
      String? city;
      String? country;

      try {
        debugPrint('Geocoding position: ${position.latitude}, ${position.longitude}');
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => <Placemark>[],
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality?.isNotEmpty == true
              ? place.locality
              : place.subAdministrativeArea;
          country = place.country?.isNotEmpty == true ? place.country : null;

          final parts = <String>[];
          if (place.street?.isNotEmpty == true) parts.add(place.street!);
          if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
          if (place.administrativeArea?.isNotEmpty == true) {
            parts.add(place.administrativeArea!);
          }
          if (place.country?.isNotEmpty == true) parts.add(place.country!);
          address = parts.isNotEmpty ? parts.join(', ') : null;

          debugPrint('Geocoded: city=$city, country=$country');
        }
      } catch (e) {
        debugPrint('Geocoding failed: $e');
        // Continue with coordinates only
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        city: city,
        country: country,
      );
    } catch (e) {
      debugPrint('Error getting location with address: $e');
      return null;
    }
  }

  /// Open app settings for location permissions
  Future<bool> openLocationSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open device location settings
  Future<bool> openDeviceLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛡️ PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check location permissions
  Future<void> _checkLocationPermissions() async {
    final status = await Permission.location.status;

    if (status == PermissionStatus.denied) {
      // Try to request permission
      final requestStatus = await Permission.location.request();
      if (requestStatus != PermissionStatus.granted) {
        throw PermissionException('Location permission denied');
      }
    } else if (status == PermissionStatus.permanentlyDenied) {
      throw PermissionException('Location permission permanently denied. Please enable in app settings.');
    } else if (status == PermissionStatus.limited) {
      throw PermissionException('Location permission limited. Please enable full access.');
    }
  }

  /// Check if location service is enabled
  Future<void> _checkLocationServiceEnabled() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw ServiceDisabledException('Location service is disabled. Please enable location services.');
    }
  }

  /// Validate coordinates
  void _validateCoordinates(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) {
      throw ValidationException('Invalid latitude: $latitude (must be between -90 and 90)');
    }
    if (longitude < -180 || longitude > 180) {
      throw ValidationException('Invalid longitude: $longitude (must be between -180 and 180)');
    }
  }

  /// Format address from placemark
  String _formatAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.name != null && placemark.name!.isNotEmpty) {
      parts.add(placemark.name!);
    }
    if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
      parts.add(placemark.thoroughfare!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown address';
  }
}

/// Location result with coordinates and address
class LocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? country;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.country,
  });

  @override
  String toString() => 'LocationResult($address, $latitude, $longitude)';
}
