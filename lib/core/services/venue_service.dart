/// 🏢 GIGMATCH Venue Service - BULLETPROOF VERSION
///
/// Handles venue profile operations with comprehensive error handling
/// Syncs with NestJS backend DTOs and schemas
///
/// Features:
/// - Comprehensive error handling with user-friendly messages
/// - Retry logic for critical operations
/// - Network connectivity checks
/// - Validation at each step
/// - Full sync with backend venue schema (877 lines)
/// - GeoJSON coordinate format [lng, lat] validation

library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api.dart';
import '../models/models.dart';
import '../exceptions.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// VENUE SERVICE
/// ═══════════════════════════════════════════════════════════════════════

class VenueService {
  final ApiClient _client = ApiClient();
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  /// ═══════════════════════════════════════════════════════════════════════
  /// SEARCH & DISCOVERY
  /// ═══════════════════════════════════════════════════════════════════════

  /// 🔍 Search venues with filters
  Future<List<Venue>> searchVenues(VenueSearchParams params) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🏢 [VenueService] Searching venues with params');

      // Validate input parameters
      _validateSearchParams(params);

      // Check network connectivity
      await _checkConnectivity();

      final response = await _client.get(
        Endpoints.venuesSearch,
        queryParameters: params.toQueryParams(),
      );

      debugPrint(
        '🏢 [VenueService] Search completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Validate response structure
      if (response.data == null) {
        throw ValidationException('Empty response from server');
      }

      final data = response.data['data'] ?? response.data['venues'] ?? [];

      if (data is! List) {
        throw ValidationException('Invalid response format: expected array');
      }

      final venues = data.map((e) {
        try {
          return Venue.fromJson(e as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ [VenueService] Failed to parse venue: $e');
          return null;
        }
      }).where((venue) => venue != null).cast<Venue>().toList();

      debugPrint('🏢 [VenueService] Found ${venues.length} venues');
      return venues;
    } on DioException catch (e) {
      final error = _handleDioError(e, 'search venues');
      debugPrint('❌ [VenueService] Search failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceError(
        'Unexpected error during search: $e',
      );
      debugPrint('❌ [VenueService] Search failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// 🏢 Get venue by ID
  Future<Venue> getVenueById(String venueId) async {
    try {
      debugPrint('🏢 [VenueService] Fetching venue: $venueId');

      final response = await _client.get(
        Endpoints.venueById(venueId),
      );

      if (response.data == null) {
        throw NotFoundException('Venue not found');
      }

      final venue = Venue.fromJson(response.data);
      debugPrint('🏢 [VenueService] Venue loaded: ${venue.venueName}');
      return venue;
    } on DioException catch (e) {
      final error = _handleDioError(e, 'get venue');
      debugPrint('❌ [VenueService] Get venue failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceError(
        'Unexpected error getting venue: $e',
      );
      debugPrint('❌ [VenueService] Get venue failed: ${error.message}');
      throw error;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PROFILE OPERATIONS
  /// ═══════════════════════════════════════════════════════════════════════

  /// 🏢 Get my venue profile
  Future<Venue> getMyProfile() async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🏢 [VenueService] Fetching my venue profile');

      // Check authentication
      await _checkAuthentication();

      final response = await _client.get(Endpoints.venuesMe);

      debugPrint(
        '🏢 [VenueService] Profile fetched in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Validate response
      if (response.data == null) {
        throw ValidationException('Empty profile response');
      }

      final venue = Venue.fromJson(response.data);

      debugPrint(
        '🏢 [VenueService] Profile loaded: ${venue.venueName} (${venue.id})',
      );
      return venue;
    } on DioException catch (e) {
      final error = _handleDioError(e, 'get my profile');
      debugPrint('❌ [VenueService] Get profile failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceError(
        'Unexpected error getting profile: $e',
      );
      debugPrint('❌ [VenueService] Get profile failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// ✏️ Update my venue profile
  Future<Venue> updateMyProfile(UpdateVenueRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🏢 [VenueService] Updating venue profile');

      // Validate request
      _validateUpdateRequest(request);

      // Check authentication
      await _checkAuthentication();

      // Check network connectivity
      await _checkConnectivity();

      final requestData = request.toJson();
      debugPrint('🏢 [VenueService] Update data keys: ${requestData.keys.toList()}');

      final response = await _client.patch(
        Endpoints.venuesMe,
        data: requestData,
      );

      debugPrint(
        '🏢 [VenueService] Profile updated in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Validate response
      if (response.data == null) {
        throw ValidationException('Empty update response');
      }

      final venue = Venue.fromJson(response.data);

      debugPrint(
        '🏢 [VenueService] Profile updated successfully: ${venue.venueName}',
      );
      return venue;
    } on DioException catch (e) {
      final error = _handleDioError(e, 'update profile');
      debugPrint('❌ [VenueService] Update failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceError(
        'Unexpected error updating profile: $e',
      );
      debugPrint('❌ [VenueService] Update failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// ✅ Complete venue profile setup
  Future<Venue> completeSetup(VenueProfileData profileData) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🏢 [VenueService] Completing venue profile setup');

      // Validate profile data
      final errors = profileData.validate();
      if (errors.isNotEmpty) {
        throw ValidationException('Validation failed: ${errors.join(", ")}');
      }

      // Check authentication
      await _checkAuthentication();

      // Check network connectivity
      await _checkConnectivity();

      // Convert to backend DTO format
      final requestData = profileData.toBackendDto();
      debugPrint(
        '🏢 [VenueService] Setup data keys: ${requestData.keys.toList()}',
      );

      // Retry logic for setup completion (critical operation)
      Venue? result;
      Exception? lastError;

      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          debugPrint('🏢 [VenueService] Setup attempt $attempt/$_maxRetries');

          final response = await _client.post(
            Endpoints.venuesCompleteSetup,
            data: requestData,
          );

          debugPrint(
            '🏢 [VenueService] Setup completed in ${stopwatch.elapsedMilliseconds}ms (attempt $attempt)',
          );

          // Validate response
          if (response.data == null) {
            throw ValidationException('Empty setup response');
          }

          result = Venue.fromJson(response.data);
          break; // Success, exit retry loop
        } on DioException catch (e) {
          lastError = e;
          if (attempt < _maxRetries) {
            final delay = _retryDelay * attempt;
            debugPrint(
              '⚠️ [VenueService] Setup attempt $attempt failed, retrying in ${delay.inSeconds}s...',
            );
            await Future.delayed(delay);
          }
        }
      }

      if (result == null) {
        throw lastError != null
            ? _handleDioError(lastError as DioException, 'complete setup')
            : VenueServiceError(
                'Setup failed after $_maxRetries attempts',
              );
      }

      debugPrint(
        '🏢 [VenueService] Setup completed successfully: ${result.venueName}',
      );
      return result;
    } catch (e) {
      final error = e is VenueServiceError
          ? e
          : VenueServiceError(
              'Unexpected error during setup: $e',
            );
      debugPrint('❌ [VenueService] Setup failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// 💰 Boost venue visibility
  Future<Venue> boostVisibility({int days = 7}) async {
    try {
      debugPrint('🏢 [VenueService] Boosting visibility for $days days');

      await _checkAuthentication();

      final response = await _client.post(
        '${Endpoints.venuesMe}/boost',
        data: {'days': days},
      );

      if (response.data == null) {
        throw ValidationException('Empty boost response');
      }

      return Venue.fromJson(response.data);
    } on DioException catch (e) {
      final error = _handleDioError(e, 'boost visibility');
      debugPrint('❌ [VenueService] Boost failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceError(
        'Unexpected error boosting visibility: $e',
      );
      debugPrint('❌ [VenueService] Boost failed: ${error.message}');
      throw error;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// GIGS MANAGEMENT
  /// ═══════════════════════════════════════════════════════════════════════

  /// 📝 Create a new gig
  Future<dynamic> createGig(CreateGigRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🏢 [VenueService] Creating new gig');

      await _checkAuthentication();
      await _checkConnectivity();

      final response = await _client.post(
        Endpoints.gigsCreate,
        data: request.toJson(),
      );

      debugPrint(
        '🏢 [VenueService] Gig created in ${stopwatch.elapsedMilliseconds}ms',
      );

      if (response.data == null) {
        throw ValidationException('Empty create gig response');
      }

      return response.data;
    } on DioException catch (e) {
      final error = _handleDioError(e, 'create gig');
      debugPrint('❌ [VenueService] Create gig failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceError(
        'Unexpected error creating gig: $e',
      );
      debugPrint('❌ [VenueService] Create gig failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// 📋 Get my gigs
  Future<List<dynamic>> getMyGigs() async {
    try {
      debugPrint('🏢 [VenueService] Fetching my gigs');

      await _checkAuthentication();

      final response = await _client.get(Endpoints.gigsMine);

      if (response.data == null) {
        return [];
      }

      final gigs = response.data['data'] ?? response.data['gigs'] ?? [];
      return List<dynamic>.from(gigs);
    } on DioException catch (e) {
      final error = _handleDioError(e, 'get my gigs');
      debugPrint('❌ [VenueService] Get gigs failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceError(
        'Unexpected error getting gigs: $e',
      );
      debugPrint('❌ [VenueService] Get gigs failed: ${error.message}');
      throw error;
    }
  }

  /// 📊 Discover gigs (for artists to find)
  Future<List<dynamic>> discoverGigs(DiscoverGigsQuery query) async {
    try {
      debugPrint('🏢 [VenueService] Discovering gigs');

      await _checkAuthentication();
      await _checkConnectivity();

      final response = await _client.get(
        Endpoints.gigsDiscover,
        queryParameters: query.toQueryParams(),
      );

      if (response.data == null) {
        return [];
      }

      final gigs = response.data['data'] ?? response.data['gigs'] ?? [];
      return List<dynamic>.from(gigs);
    } on DioException catch (e) {
      final error = _handleDioError(e, 'discover gigs');
      debugPrint('❌ [VenueService] Discover gigs failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceError(
        'Unexpected error discovering gigs: $e',
      );
      debugPrint('❌ [VenueService] Discover gigs failed: ${error.message}');
      throw error;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PRIVATE HELPER METHODS
  /// ═══════════════════════════════════════════════════════════════════════

  void _validateSearchParams(VenueSearchParams params) {
    if (params.latitude != null &&
        (params.latitude! < -90 || params.latitude! > 90)) {
      throw ValidationException('Latitude must be between -90 and 90');
    }
    if (params.longitude != null &&
        (params.longitude! < -180 || params.longitude! > 180)) {
      throw ValidationException('Longitude must be between -180 and 180');
    }
    if (params.radiusMiles != null && params.radiusMiles! <= 0) {
      throw ValidationException('Radius must be greater than 0');
    }
    if (params.page < 1) {
      throw ValidationException('Page must be 1 or greater');
    }
    if ((params.limit < 1 || params.limit > 100)) {
      throw ValidationException('Limit must be between 1 and 100');
    }
  }

  void _validateUpdateRequest(UpdateVenueRequest request) {
    // Validate location coordinates if provided
    if (request.location != null) {
      final coords = request.location!.coordinates;
      if (coords.length >= 2) {
        final lng = coords[0];
        final lat = coords[1];
        if (lng < -180 || lng > 180) {
          throw ValidationException('Longitude must be between -180 and 180');
        }
        if (lat < -90 || lat > 90) {
          throw ValidationException('Latitude must be between -90 and 90');
        }
        // Reject [0,0] coordinates
        if (lng == 0.0 && lat == 0.0) {
          throw ValidationException('Invalid coordinates [0,0]');
        }
      }
    }

    // Validate budget
    if (request.minBudget != null && request.minBudget! < 0) {
      throw ValidationException('Minimum budget cannot be negative');
    }
    if (request.maxBudget != null && request.maxBudget! < 0) {
      throw ValidationException('Maximum budget cannot be negative');
    }
    if (request.minBudget != null &&
        request.maxBudget != null &&
        request.minBudget! > request.maxBudget!) {
      throw ValidationException(
        'Minimum budget cannot be greater than maximum budget',
      );
    }
  }

  Future<void> _checkAuthentication() async {
    final isLoggedIn = await ApiClient().getAccessToken();
    if (isLoggedIn == null || isLoggedIn.isEmpty) {
      throw AuthenticationException('Please log in to continue');
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw NetworkException('No internet connection');
      }
    } on SocketException {
      throw NetworkException('No internet connection. Please check your network.');
    }
  }

  VenueServiceError _handleDioError(DioException e, String context) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return VenueServiceError(
          'Connection timed out. Please try again.',
          originalError: e,
        );
      case DioExceptionType.sendTimeout:
        return VenueServiceError(
          'Request timed out. Please try again.',
          originalError: e,
        );
      case DioExceptionType.receiveTimeout:
        return VenueServiceError(
          'Response timed out. Please try again.',
          originalError: e,
        );
      case DioExceptionType.badCertificate:
        return VenueServiceError(
          'Security error. Please contact support.',
          originalError: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (statusCode == 400) {
          final message = data?['message'] ?? 'Invalid request data';
          return VenueServiceError(message, originalError: e);
        }
        if (statusCode == 401) {
          return VenueServiceError(
            'Session expired. Please log in again.',
            originalError: e,
          );
        }
        if (statusCode == 403) {
          return VenueServiceError(
            'You do not have permission to perform this action.',
            originalError: e,
          );
        }
        if (statusCode == 404) {
          return VenueServiceError(
            'The requested resource was not found.',
            originalError: e,
          );
        }
        if (statusCode == 422) {
          final message = data?['message'] ?? 'Validation error';
          return VenueServiceError(message, originalError: e);
        }
        if (statusCode == 429) {
          return VenueServiceError(
            'Too many requests. Please wait before trying again.',
            originalError: e,
          );
        }
        if (statusCode != null && statusCode >= 500) {
          return VenueServiceError(
            'Server error. Please try again later.',
            code: 'SERVER_ERROR',
            originalError: e,
          );
        }
        return VenueServiceError(
          'Request failed: ${e.message}',
          originalError: e,
        );

      case DioExceptionType.cancel:
        return VenueServiceError(
          'Request was cancelled',
          originalError: e,
        );

      case DioExceptionType.connectionError:
        if (e.message?.contains('SocketException') ?? false) {
          return VenueServiceError(
            'No internet connection. Please check your network.',
            originalError: e,
          );
        }
        return VenueServiceError(
          'An unexpected error occurred. Please try again.',
          originalError: e,
        );

      case DioExceptionType.unknown:
        return VenueServiceError(
          'Unknown error during $context: ${e.message}',
          originalError: e,
        );
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════
/// REQUEST/RESPONSE CLASSES
/// ═══════════════════════════════════════════════════════════════════════

/// Venue Search Parameters (matches backend VenueSearchQueryDto)
class VenueSearchParams {
  final String? venueType;
  final List<String>? genres;
  final double? latitude;
  final double? longitude;
  final int? radiusMiles;
  final int? minCapacity;
  final int? maxCapacity;
  final double? maxBudget;
  final bool? hasSoundSystem;
  final bool? hasStage;
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  VenueSearchParams({
    this.venueType,
    this.genres,
    this.latitude,
    this.longitude,
    this.radiusMiles,
    this.minCapacity,
    this.maxCapacity,
    this.maxBudget,
    this.hasSoundSystem,
    this.hasStage,
    this.page = 1,
    this.limit = 20,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (venueType != null) params['venueType'] = venueType;
    if (genres != null && genres!.isNotEmpty) {
      params['genres'] = genres!.join(',');
    }
    if (latitude != null) params['latitude'] = latitude.toString();
    if (longitude != null) params['longitude'] = longitude.toString();
    if (radiusMiles != null) params['radiusMiles'] = radiusMiles.toString();
    if (minCapacity != null) params['minCapacity'] = minCapacity.toString();
    if (maxCapacity != null) params['maxCapacity'] = maxCapacity.toString();
    if (maxBudget != null) params['maxBudget'] = maxBudget.toString();
    if (hasSoundSystem != null) {
      params['hasSoundSystem'] = hasSoundSystem.toString();
    }
    if (hasStage != null) params['hasStage'] = hasStage.toString();
    params['page'] = page.toString();
    params['limit'] = limit.toString();
    params['sortBy'] = sortBy;
    params['sortOrder'] = sortOrder;

    return params;
  }
}

/// Update Venue Request (matches backend UpdateVenueDto)
class UpdateVenueRequest {
  final String? venueName;
  final String? description;
  final String? venueType;
  final VenueLocation? location;
  final List<String>? preferredGenres;
  final String? phone;
  final bool? showPhoneOnProfile;
  final String? bookingEmail;
  final int? capacity;
  final double? minBudget;
  final double? maxBudget;
  final String? currency;
  final VenueEquipment? equipment;
  final VenueSocialLinks? socialLinks;
  final GigPreferences? gigPreferences;
  final bool? isActive;
  final bool? isVisible;

  UpdateVenueRequest({
    this.venueName,
    this.description,
    this.venueType,
    this.location,
    this.preferredGenres,
    this.phone,
    this.showPhoneOnProfile,
    this.bookingEmail,
    this.capacity,
    this.minBudget,
    this.maxBudget,
    this.currency,
    this.equipment,
    this.socialLinks,
    this.gigPreferences,
    this.isActive,
    this.isVisible,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    // Basic info
    if (venueName != null) json['venueName'] = venueName;
    if (description != null) json['description'] = description;
    if (venueType != null) json['venueType'] = venueType;

    // Location: only send if valid and not [0,0]
    if (location != null &&
        location!.coordinates.length >= 2 &&
        location!.longitude != 0.0 &&
        location!.latitude != 0.0) {
      json['location'] = location!.toJson();
    }

    // Preferences
    if (preferredGenres != null) json['preferredGenres'] = preferredGenres;
    if (gigPreferences != null) json['gigPreferences'] = gigPreferences!.toJson();

    // Contact
    if (phone != null) json['phone'] = phone;
    if (showPhoneOnProfile != null) {
      json['showPhoneOnProfile'] = showPhoneOnProfile;
    }
    if (bookingEmail != null) json['bookingEmail'] = bookingEmail;

    // Details
    if (capacity != null) json['capacity'] = capacity;

    // Budget
    if (minBudget != null) json['minBudget'] = minBudget;
    if (maxBudget != null) json['maxBudget'] = maxBudget;
    if (currency != null) json['currency'] = currency;

    // Equipment
    if (equipment != null) json['equipment'] = equipment!.toJson();

    // Social
    if (socialLinks != null) {
      final socialJson = socialLinks!.toJson();
      if (socialJson.isNotEmpty) json['socialLinks'] = socialJson;
    }

    // Status
    if (isActive != null) json['isActive'] = isActive;
    if (isVisible != null) json['isVisible'] = isVisible;

    return json;
  }
}

/// Create Gig Request
class CreateGigRequest {
  final String title;
  final String? description;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final List<String> genres;
  final String? paymentType;
  final double? budgetMin;
  final double? budgetMax;
  final String currency;
  final int setDurationMinutes;
  final List<String> equipmentProvided;
  final List<String> equipmentNeeded;
  final int slotsAvailable;

  CreateGigRequest({
    required this.title,
    this.description,
    required this.date,
    this.startTime,
    this.endTime,
    this.genres = const [],
    this.paymentType,
    this.budgetMin,
    this.budgetMax,
    this.currency = 'USD',
    this.setDurationMinutes = 60,
    this.equipmentProvided = const [],
    this.equipmentNeeded = const [],
    this.slotsAvailable = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'date': date.toIso8601String().split('T')[0],
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'genres': genres,
      if (paymentType != null) 'paymentType': paymentType,
      if (budgetMin != null) 'budgetMin': budgetMin,
      if (budgetMax != null) 'budgetMax': budgetMax,
      'currency': currency,
      'setDurationMinutes': setDurationMinutes,
      'equipmentProvided': equipmentProvided,
      'equipmentNeeded': equipmentNeeded,
      'slotsAvailable': slotsAvailable,
    };
  }
}

/// Discover Gigs Query
class DiscoverGigsQuery {
  final List<String>? genres;
  final double? latitude;
  final double? longitude;
  final int? radiusMiles;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? maxBudget;
  final int page;
  final int limit;

  DiscoverGigsQuery({
    this.genres,
    this.latitude,
    this.longitude,
    this.radiusMiles,
    this.dateFrom,
    this.dateTo,
    this.maxBudget,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (genres != null && genres!.isNotEmpty) {
      params['genres'] = genres!.join(',');
    }
    if (latitude != null) params['latitude'] = latitude.toString();
    if (longitude != null) params['longitude'] = longitude.toString();
    if (radiusMiles != null) params['radiusMiles'] = radiusMiles.toString();
    if (dateFrom != null) {
      params['dateFrom'] = dateFrom!.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      params['dateTo'] = dateTo!.toIso8601String().split('T')[0];
    }
    if (maxBudget != null) params['maxBudget'] = maxBudget.toString();
    params['page'] = page.toString();
    params['limit'] = limit.toString();

    return params;
  }
}
