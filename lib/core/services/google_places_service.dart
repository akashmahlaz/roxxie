import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api_config.dart';

class GooglePlacesService {
  static final GooglePlacesService _instance = GooglePlacesService._internal();
  factory GooglePlacesService() => _instance;
  GooglePlacesService._internal();

  final Dio _dio = Dio();
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Get autocomplete suggestions
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String input,
    String sessionToken,
  ) async {
    if (input.isEmpty) return [];

    try {
      final response = await _dio.get(
        '$_baseUrl/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': ApiConfig.googlePlacesApiKey,
          'sessiontoken': sessionToken,
          'types': '(cities)', // Restrict to cities for now as per SmartLocationPicker usage
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final predictions = data['predictions'] as List;
          return predictions.map((e) => PlaceSuggestion.fromJson(e)).toList();
        } else {
          debugPrint(
            'Google Places Error: ${data['status']} - ${data['error_message']}',
          );
          return [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
      return [];
    }
  }

  /// Get place details
  Future<PlaceDetails?> getPlaceDetails(
    String placeId,
    String sessionToken,
  ) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': ApiConfig.googlePlacesApiKey,
          'sessiontoken': sessionToken,
          'fields': 'name,geometry,address_components',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching place details: $e');
      return null;
    }
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final struct = json['structured_formatting'] ?? {};
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: struct['main_text'] ?? '',
      secondaryText: struct['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String name;
  final double lat;
  final double lng;
  final String city;
  final String country;

  PlaceDetails({
    required this.name,
    required this.lat,
    required this.lng,
    required this.city,
    required this.country,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    final addressComponents = json['address_components'] as List? ?? [];

    String city = '';
    String country = '';

    for (var component in addressComponents) {
      final types = (component['types'] as List).cast<String>();
      if (types.contains('locality')) {
        city = component['long_name'];
      } else if (types.contains('administrative_area_level_1') &&
          city.isEmpty) {
        // Fallback if locality is missing
        city = component['long_name'];
      }

      if (types.contains('country')) {
        country = component['long_name'];
      }
    }

    return PlaceDetails(
      name: json['name'] ?? '',
      lat: (location['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location['lng'] as num?)?.toDouble() ?? 0.0,
      city: city,
      country: country,
    );
  }
}
