/// 🏢 GIGMATCH Venue Service
/// Handles venue profile operations

import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../models/models.dart';

class VenueService {
  final ApiClient _client = ApiClient();

  /// 🔍 Search venues with filters
  Future<List<Venue>> searchVenues(VenueSearchParams params) async {
    try {
      final response = await _client.get(
        Endpoints.venuesSearch,
        queryParameters: params.toQueryParams(),
      );

      final data = response.data['data'] ?? response.data['venues'] ?? [];
      return (data as List).map((e) => Venue.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Search venues error: $e');
      rethrow;
    }
  }

  /// 🏢 Get my venue profile
  Future<Venue> getMyProfile() async {
    try {
      final response = await _client.get(Endpoints.venuesMe);
      return Venue.fromJson(response.data);
    } catch (e) {
      debugPrint('Get my venue profile error: $e');
      rethrow;
    }
  }

  /// ✏️ Update my venue profile
  Future<Venue> updateMyProfile(UpdateVenueRequest request) async {
    try {
      final response = await _client.patch(
        Endpoints.venuesMe,
        data: request.toJson(),
      );
      return Venue.fromJson(response.data);
    } catch (e) {
      debugPrint('Update venue profile error: $e');
      rethrow;
    }
  }

  /// ✅ Complete venue profile setup
  Future<Venue> completeSetup(UpdateVenueRequest request) async {
    try {
      final response = await _client.post(
        Endpoints.venuesCompleteSetup,
        data: request.toJson(),
      );
      return Venue.fromJson(response.data);
    } catch (e) {
      debugPrint('Complete venue setup error: $e');
      rethrow;
    }
  }

  /// 🔍 Get venue by ID
  Future<Venue> getVenueById(String id) async {
    try {
      final response = await _client.get(Endpoints.venueById(id));
      return Venue.fromJson(response.data);
    } catch (e) {
      debugPrint('Get venue by ID error: $e');
      rethrow;
    }
  }
}
