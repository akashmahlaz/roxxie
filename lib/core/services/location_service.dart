/// 📍 GIGMATCH Location Service
/// Handles GPS location and geocoding - RELIABLE FIRST-TIME FETCH
library;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Build address string
        final parts = <String>[];

        if (place.locality?.isNotEmpty == true) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea?.isNotEmpty == true) {
          parts.add(place.administrativeArea!);
        }
        if (place.country?.isNotEmpty == true && parts.isEmpty) {
          parts.add(place.country!);
        }

        return parts.isNotEmpty ? parts.join(', ') : null;
      }
      return null;
    } catch (e) {
      debugPrint('Error geocoding: $e');
      return null;
    }
  }

  /// Get coordinates from address
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
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
