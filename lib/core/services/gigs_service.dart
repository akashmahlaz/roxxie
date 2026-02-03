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

  /// ✅ Delete gig (Venue only)
  ///
  /// Permanently deletes a gig. Use [cancelGig] for soft deletion.
  Future<void> deleteGig(String gigId) async {
    try {
      await _client.delete('/gigs/$gigId');
    } catch (e) {
      debugPrint('Delete gig error: $e');
      rethrow;
    }
  }

  /// ✅ Cancel gig (Venue only)
  ///
  /// Soft deletes a gig by setting status to 'cancelled'.
  Future<Gig> cancelGig(String gigId, {String? reason}) async {
    try {
      final data = reason != null ? {'reason': reason} : null;
      final response = await _client.post(
        '/gigs/$gigId/cancel',
        data: data,
      );
      return Gig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Cancel gig error: $e');
      rethrow;
    }
  }

  /// ✅ Publish draft gig (Venue only)
  ///
  /// Updates a draft gig to 'open' status so artists can apply.
  Future<Gig> publishDraft(String gigId) async {
    try {
      final response = await _client.patch(
        '/gigs/$gigId',
        data: {'status': 'open'},
      );
      return Gig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Publish draft error: $e');
      rethrow;
    }
  }

  /// ✅ Duplicate a gig (Venue only)
  ///
  /// Creates a copy of an existing gig as a draft with today's date.
  Future<Gig> duplicateGig(Gig originalGig) async {
    try {
      final request = CreateGigRequest(
        venueId: originalGig.venue?.id ?? '',
        title: '${originalGig.title} (Copy)',
        description: originalGig.description,
        // Use today's date for duplicate (user can edit if needed)
        date: DateTime.now().toIso8601String(),
        startTime: originalGig.startTime,
        endTime: originalGig.endTime,
        durationMinutes: originalGig.durationMinutes,
        numberOfSets: originalGig.numberOfSets,
        requiredGenres: originalGig.requiredGenres,
        specificRequirements: originalGig.specificRequirements,
        artistsNeeded: originalGig.artistsNeeded,
        budget: originalGig.budget,
        currency: originalGig.currency,
        paymentType: originalGig.paymentType,
        location: CreateGigLocationRequest(
          city: originalGig.location.city,
          country: originalGig.location.country,
          venueAddress: originalGig.location.venueAddress,
          geoCoordinates:
              originalGig.location.geo?.coordinates ?? [0.0, 0.0],
        ),
        status: GigStatus.draft,
        perks: originalGig.perks,
        isPublic: originalGig.isPublic,
        acceptingApplications: originalGig.isPublic,
      );

      final response = await _client.post(
        Endpoints.gigsCreate,
        data: request.toJson(),
      );
      return Gig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Duplicate gig error: $e');
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

  // ═══════════════════════════════════════════════════════════════════════
  // APPLICATION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// ✅ Get applications for a gig (venue only)
  Future<List<VenueGigApplication>> getGigApplications(String gigId) async {
    try {
      final response = await _client.get('/gigs/$gigId/applications');
      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['applications'] ?? [];
      return data.map((json) => VenueGigApplication.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Get gig applications error: $e');
      rethrow;
    }
  }

  /// ✅ Get pending application count
  Future<int> getApplicationCount(String gigId) async {
    try {
      final response = await _client.get('/gigs/$gigId/application-count');
      return response.data['pendingApplications'] ?? 0;
    } catch (e) {
      debugPrint('Get application count error: $e');
      rethrow;
    }
  }

  /// ✅ Get my applications (artist only) - with pagination
  Future<PaginatedApplicationsResponse> getMyApplications({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _client.get(
        '/gigs/my-applications',
        queryParameters: queryParams,
      );

      return PaginatedApplicationsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Get my applications error: $e');
      rethrow;
    }
  }

  /// ✅ Accept application and create booking (venue only)
  Future<AcceptApplicationResult> acceptApplicationAndCreateBooking({
    required String gigId,
    required String artistId,
    required double agreedAmount,
    required String startTime,
    String? endTime,
    String? specialRequests,
  }) async {
    try {
      final response = await _client.post(
        '/gigs/$gigId/create-booking-from-application',
        data: {
          'artistId': artistId,
          'agreedAmount': agreedAmount,
          'startTime': startTime,
          if (endTime != null) 'endTime': endTime,
          if (specialRequests != null) 'specialRequests': specialRequests,
        },
      );
      return AcceptApplicationResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Accept application error: $e');
      rethrow;
    }
  }

  /// ✅ Decline an application (venue only)
  Future<Gig> declineApplication({
    required String gigId,
    required String artistId,
    String? reason,
  }) async {
    try {
      final response = await _client.post(
        '/gigs/$gigId/decline-application',
        data: {
          'artistId': artistId,
          if (reason != null) 'reason': reason,
        },
      );
      return Gig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Decline application error: $e');
      rethrow;
    }
  }
}
