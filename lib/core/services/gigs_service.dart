/// 🎤 Gigs Service
/// Calls gig-related endpoints for:
/// - Venue: create/manage gigs
/// - Artist: discover gigs feed (geo radius + genres defaults handled by backend)
///
/// This service is designed to stay in sync with the NestJS backend:
/// - POST   /api/v1/gigs
/// - GET    /api/v1/gigs/mine
/// - GET    /api/v1/gigs/discover
library;

import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/gig_models.dart';

class GigsService {
  final ApiClient _client;

  GigsService({ApiClient? client}) : _client = client ?? ApiClient();

  /// ✅ Get gig by ID
  ///
  /// Fetch full details of a specific gig
  Future<Gig> getGigById(String gigId) async {
    try {
      final response = await _client.get(Endpoints.gigById(gigId));
      return Gig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Get gig by ID error: $e');
      rethrow;
    }
  }

  /// ✅ Accept a gig offer (Artist)
  Future<Gig> acceptGig(String gigId) async {
    try {
      final response = await _client.post(Endpoints.gigAccept(gigId));
      return Gig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Accept gig error: $e');
      rethrow;
    }
  }

  /// ✅ Decline a gig offer (Artist)
  Future<void> declineGig(String gigId, {String? reason}) async {
    try {
      await _client.post(
        '/gigs/$gigId/decline',
        data: reason != null ? {'reason': reason} : null,
      );
    } catch (e) {
      debugPrint('Decline gig error: $e');
      rethrow;
    }
  }

  /// ✅ Apply to a gig (Artist)
  Future<Gig> applyToGig(
    String gigId, {
    String? coverMessage,
    int? proposedRate,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (coverMessage != null) data['message'] = coverMessage;
      if (proposedRate != null) data['proposedRate'] = proposedRate;

      final response = await _client.post(
        '/gigs/$gigId/apply',
        data: data.isNotEmpty ? data : null,
      );
      return Gig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Apply to gig error: $e');
      rethrow;
    }
  }

  /// ✅ Create gig (Venue only)
  ///
  /// Backend enforces:
  /// - caller owns venueId
  /// - geoCoordinates are valid [lng, lat]
  /// - publishing/open gigs requires venue setup completion
  Future<Gig> createGig(CreateGigRequest request) async {
    try {
      final response = await _client.post(
        Endpoints.gigsCreate,
        data: request.toJson(),
      );

      // Backend returns the created gig document
      return Gig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Create gig error: $e');
      rethrow;
    }
  }

  /// ✅ Update gig (Venue only)
  Future<Gig> updateGig(String gigId, UpdateGigRequest request) async {
    try {
      final response = await _client.patch(
        '/gigs/$gigId',
        data: request.toJson(),
      );

      return Gig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Update gig error: $e');
      rethrow;
    }
  }

  /// ✅ Get my gigs (Venue)
  ///
  /// Use [status] to filter (draft/open/in_progress/filled/completed/cancelled)
  Future<PaginatedGigsResponse> getMyGigs({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final qp = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null && status.trim().isNotEmpty) {
        qp['status'] = status.trim();
      }

      final response = await _client.get(
        Endpoints.gigsMine,
        queryParameters: qp,
      );

      return PaginatedGigsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Get my gigs error: $e');
      rethrow;
    }
  }

  /// ✅ Discover gigs (Artist)
  ///
  /// Enterprise UX:
  /// - If you pass no query params, backend will default to:
  ///   - artist genres (if present)
  ///   - artist location coordinates (if present)
  ///   - artist travelRadius (or backend default)
  ///
  /// You can override with [query] for "Filters" UI.
  Future<PaginatedGigsResponse> discoverGigs({DiscoverGigsQuery? query}) async {
    try {
      final response = await _client.get(
        Endpoints.gigsDiscover,
        queryParameters: query?.toQueryParams(),
      );

      return PaginatedGigsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Discover gigs error: $e');
      rethrow;
    }
  }
}
