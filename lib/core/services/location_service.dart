/// 📍 GIGMATCH Location Service
/// Handles GPS location and geocoding
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

enum LocationPermissionState {
  granted,
  serviceDisabled,
  denied,
  deniedPreviously,
  deniedForever,
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String _permissionRequestedKey = 'location_permission_requested';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> _hasRequestedPermissionBefore() async {
    final v = await _storage.read(key: _permissionRequestedKey);
    return v == 'true';
  }

  Future<void> _markPermissionRequested() async {
    await _storage.write(key: _permissionRequestedKey, value: 'true');
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
      final requestedBefore = await _hasRequestedPermissionBefore();
      return requestedBefore
          ? LocationPermissionState.deniedPreviously
          : LocationPermissionState.denied;
    }

    return LocationPermissionState.granted;
  }

  /// Check if location services are enabled and permissions granted
  Future<bool> checkPermissions() async {
    final state = await getPermissionState();

    if (state == LocationPermissionState.serviceDisabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    if (state == LocationPermissionState.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      await _markPermissionRequested();
      return false;
    }

    if (state == LocationPermissionState.deniedPreviously) {
      debugPrint('Location permission was previously denied; not requesting again');
      return false;
    }

    if (state == LocationPermissionState.denied) {
      final permission = await Geolocator.requestPermission();
      await _markPermissionRequested();

      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return false;
      }
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
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

  /// Get current location as formatted address
  Future<LocationResult?> getCurrentLocationWithAddress() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      String? address;
      String? city;
      String? country;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality?.isNotEmpty == true ? place.locality : null;
          country = place.country?.isNotEmpty == true ? place.country : null;

          final parts = <String>[];
          if (place.street?.isNotEmpty == true) parts.add(place.street!);
          if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
          if (place.administrativeArea?.isNotEmpty == true) {
            parts.add(place.administrativeArea!);
          }
          if (place.country?.isNotEmpty == true) parts.add(place.country!);
          address = parts.isNotEmpty ? parts.join(', ') : null;
        }
      } catch (e) {
        // Fallback to simpler formatter
        address = await getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address ?? 'Unknown location',
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
