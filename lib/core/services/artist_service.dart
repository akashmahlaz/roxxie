/// 🎸 GIGMATCH Artist Service
/// Handles artist profile operations
library;

import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../models/models.dart';

class ArtistService {
  final ApiClient _client = ApiClient();

  /// 🔍 Search artists with filters
  Future<List<Artist>> searchArtists(ArtistSearchParams params) async {
    try {
      final response = await _client.get(
        Endpoints.artistsSearch,
        queryParameters: params.toQueryParams(),
      );

      final data = response.data['data'] ?? response.data['artists'] ?? [];
      return (data as List).map((e) => Artist.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Search artists error: $e');
      rethrow;
    }
  }

  /// 👤 Get my artist profile
  Future<Artist> getMyProfile() async {
    try {
      final response = await _client.get(Endpoints.artistsMe);
      return Artist.fromJson(response.data);
    } catch (e) {
      debugPrint('Get my artist profile error: $e');
      rethrow;
    }
  }

  /// ✏️ Update my artist profile
  Future<Artist> updateMyProfile(UpdateArtistRequest request) async {
    try {
      final response = await _client.patch(
        Endpoints.artistsMe,
        data: request.toJson(),
      );
      return Artist.fromJson(response.data);
    } catch (e) {
      debugPrint('Update artist profile error: $e');
      rethrow;
    }
  }

  /// ✅ Complete artist profile setup
  Future<Artist> completeSetup(UpdateArtistRequest request) async {
    try {
      final response = await _client.post(
        Endpoints.artistsCompleteSetup,
        data: request.toJson(),
      );
      return Artist.fromJson(response.data);
    } catch (e) {
      debugPrint('Complete artist setup error: $e');
      rethrow;
    }
  }

  /// 🚀 Boost artist profile
  Future<Artist> boostProfile() async {
    try {
      final response = await _client.post(Endpoints.artistsBoost);
      return Artist.fromJson(response.data);
    } catch (e) {
      debugPrint('Boost profile error: $e');
      rethrow;
    }
  }

  /// 🔍 Get artist by ID
  Future<Artist> getArtistById(String id) async {
    try {
      final response = await _client.get(Endpoints.artistById(id));
      return Artist.fromJson(response.data);
    } catch (e) {
      debugPrint('Get artist by ID error: $e');
      rethrow;
    }
  }
}
