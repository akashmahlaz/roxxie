/// 🏢 GIGMATCH Venue Service - BULLETPROOF VERSION
/// Handles venue profile operations with comprehensive error handling
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api.dart';
import '../models/models.dart';

/// Custom exception classes for better error handling
class VenueServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const VenueServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'VenueServiceException: $message';
}

class NetworkException extends VenueServiceException {
  const NetworkException(String message, {dynamic originalError})
      : super(message, code: 'NETWORK_ERROR', originalError: originalError);
}

class ValidationException extends VenueServiceException {
  const ValidationException(String message, {dynamic originalError})
      : super(message, code: 'VALIDATION_ERROR', originalError: originalError);
}

class AuthenticationException extends VenueServiceException {
  const AuthenticationException(String message, {dynamic originalError})
      : super(message, code: 'AUTH_ERROR', originalError: originalError);
}

class VenueService {
  final ApiClient _client = ApiClient();
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  /// 🔍 Search venues with filters - BULLETPROOF VERSION
  Future<List<Venue>> searchVenues(VenueSearchParams params) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🏢 [VenueService] Searching venues with params: ${params.toQueryParams()}');

      // Validate input parameters
      _validateSearchParams(params);

      // Check network connectivity
      await _checkConnectivity();

      final response = await _client.get(
        Endpoints.venuesSearch,
        queryParameters: params.toQueryParams(),
      );

      debugPrint('🏢 [VenueService] Search completed in ${stopwatch.elapsedMilliseconds}ms');

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
      final error = VenueServiceException('Unexpected error during search: $e');
      debugPrint('❌ [VenueService] Search failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// 🏢 Get my venue profile - BULLETPROOF VERSION
  Future<Venue> getMyProfile() async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🏢 [VenueService] Fetching my venue profile');

      // Check authentication
      await _checkAuthentication();

      final response = await _client.get(Endpoints.venuesMe);

      debugPrint('🏢 [VenueService] Profile fetched in ${stopwatch.elapsedMilliseconds}ms');

      // Validate response
      if (response.data == null) {
        throw ValidationException('Empty profile response');
      }

      final venue = Venue.fromJson(response.data);

      debugPrint('🏢 [VenueService] Profile loaded: ${venue.venueName} (${venue.id})');
      return venue;

    } on DioException catch (e) {
      final error = _handleDioError(e, 'get my profile');
      debugPrint('❌ [VenueService] Get profile failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceException('Unexpected error getting profile: $e');
      debugPrint('❌ [VenueService] Get profile failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// ✏️ Update my venue profile - BULLETPROOF VERSION
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

      debugPrint('🏢 [VenueService] Profile updated in ${stopwatch.elapsedMilliseconds}ms');

      // Validate response
      if (response.data == null) {
        throw ValidationException('Empty update response');
      }

      final venue = Venue.fromJson(response.data);

      debugPrint('🏢 [VenueService] Profile updated successfully: ${venue.venueName}');
      return venue;

    } on DioException catch (e) {
      final error = _handleDioError(e, 'update profile');
      debugPrint('❌ [VenueService] Update failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceException('Unexpected error updating profile: $e');
      debugPrint('❌ [VenueService] Update failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// ✅ Complete venue profile setup - BULLETPROOF VERSION
  Future<Venue> completeSetup(UpdateVenueRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🏢 [VenueService] Completing venue profile setup');

      // Validate request
      _validateCompleteSetupRequest(request);

      // Check authentication
      await _checkAuthentication();

      // Check network connectivity
      await _checkConnectivity();

      final requestData = request.toJson();
      debugPrint('🏢 [VenueService] Setup data keys: ${requestData.keys.toList()}');

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

          debugPrint('🏢 [VenueService] Setup completed in ${stopwatch.elapsedMilliseconds}ms (attempt $attempt)');

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
            debugPrint('⚠️ [VenueService] Setup attempt $attempt failed, retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        }
      }

      if (result == null) {
        throw lastError != null
            ? _handleDioError(lastError as DioException, 'complete setup')
            : VenueServiceException('Setup failed after $_maxRetries attempts');
      }

      debugPrint('🏢 [VenueService] Setup completed successfully: ${result.venueName}');
      return result;

    } catch (e) {
      final error = e is VenueServiceException
          ? e
          : VenueServiceException('Unexpected error during setup: $e');
      debugPrint('❌ [VenueService] Setup failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// 🔍 Get venue by ID - BULLETPROOF VERSION
  Future<Venue> getVenueById(String id) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🏢 [VenueService] Fetching venue by ID: $id');

      // Validate ID
      if (id.isEmpty) {
        throw ValidationException('Venue ID cannot be empty');
      }

      final response = await _client.get(Endpoints.venueById(id));

      debugPrint('🏢 [VenueService] Venue fetched in ${stopwatch.elapsedMilliseconds}ms');

      // Validate response
      if (response.data == null) {
        throw ValidationException('Empty venue response for ID: $id');
      }

      final venue = Venue.fromJson(response.data);

      debugPrint('🏢 [VenueService] Venue loaded: ${venue.venueName} (${venue.id})');
      return venue;

    } on DioException catch (e) {
      final error = _handleDioError(e, 'get venue by ID');
      debugPrint('❌ [VenueService] Get venue failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = VenueServiceException('Unexpected error getting venue: $e');
      debugPrint('❌ [VenueService] Get venue failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛡️ PRIVATE HELPER METHODS - BULLETPROOF ERROR HANDLING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    try {
      if (!await _isConnected()) {
        throw NetworkException('No internet connection. Please check your network and try again.');
      }
    } catch (e) {
      throw NetworkException('Network connectivity check failed: $e');
    }
  }

  /// Check authentication status
  Future<void> _checkAuthentication() async {
    try {
      final token = await _client.getAccessToken();
      if (token == null || token.isEmpty) {
        throw AuthenticationException('Not authenticated. Please log in again.');
      }
    } catch (e) {
      throw AuthenticationException('Authentication check failed: $e');
    }
  }

  /// Check if device is connected to internet
  Future<bool> _isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Handle Dio errors with specific error types
  VenueServiceException _handleDioError(DioException e, String operation) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout during $operation. Please try again.', originalError: e);

      case DioExceptionType.connectionError:
        return NetworkException('Connection error during $operation. Please check your internet connection.', originalError: e);

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 401) {
          return AuthenticationException('Authentication failed during $operation. Please log in again.', originalError: e);
        } else if (statusCode == 403) {
          return AuthenticationException('Access denied during $operation.', originalError: e);
        } else if (statusCode == 404) {
          return ValidationException('Resource not found during $operation.', originalError: e);
        } else if (statusCode == 422) {
          final message = responseData is Map ? (responseData['message'] ?? 'Validation failed') : 'Validation failed';
          return ValidationException('$message during $operation.', originalError: e);
        } else if (statusCode == 429) {
          return NetworkException('Too many requests during $operation. Please wait and try again.', originalError: e);
        } else if (statusCode != null && statusCode >= 500) {
          return NetworkException('Server error during $operation. Please try again later.', originalError: e);
        } else {
          return NetworkException('HTTP error ${statusCode ?? 'unknown'} during $operation.', originalError: e);
        }

      case DioExceptionType.cancel:
        return NetworkException('Request cancelled during $operation.', originalError: e);

      default:
        return NetworkException('Unknown network error during $operation: ${e.message}', originalError: e);
    }
  }

  /// Validate search parameters
  void _validateSearchParams(VenueSearchParams params) {
    if (params.limit <= 0 || params.limit > 100) {
      throw ValidationException('Limit must be between 1 and 100');
    }
    if (params.page <= 0) {
      throw ValidationException('Page must be greater than 0');
    }
    if (params.latitude != null && (params.latitude! < -90 || params.latitude! > 90)) {
      throw ValidationException('Latitude must be between -90 and 90');
    }
    if (params.longitude != null && (params.longitude! < -180 || params.longitude! > 180)) {
      throw ValidationException('Longitude must be between -180 and 180');
    }
    if (params.radius != null && params.radius! <= 0) {
      throw ValidationException('Radius must be greater than 0');
    }
    if (params.minBudget != null && params.minBudget! < 0) {
      throw ValidationException('Minimum budget cannot be negative');
    }
    if (params.maxBudget != null && params.maxBudget! < 0) {
      throw ValidationException('Maximum budget cannot be negative');
    }
    if (params.minBudget != null && params.maxBudget != null && params.minBudget! > params.maxBudget!) {
      throw ValidationException('Minimum budget cannot be greater than maximum budget');
    }
  }

  /// Validate update request
  void _validateUpdateRequest(UpdateVenueRequest request) {
    if (request.venueName != null && request.venueName!.length > 100) {
      throw ValidationException('Venue name must be less than 100 characters');
    }
    if (request.description != null && request.description!.length > 1000) {
      throw ValidationException('Description must be less than 1000 characters');
    }
    if (request.preferredGenres != null && request.preferredGenres!.length > 10) {
      throw ValidationException('Maximum 10 preferred genres allowed');
    }
    if (request.capacity != null && request.capacity! <= 0) {
      throw ValidationException('Capacity must be greater than 0');
    }
    if (request.minBudget != null && request.minBudget! < 0) {
      throw ValidationException('Minimum budget cannot be negative');
    }
    if (request.maxBudget != null && request.maxBudget! < 0) {
      throw ValidationException('Maximum budget cannot be negative');
    }
    if (request.minBudget != null && request.maxBudget != null && request.minBudget! > request.maxBudget!) {
      throw ValidationException('Minimum budget cannot be greater than maximum budget');
    }
  }

  /// Validate complete setup request
  void _validateCompleteSetupRequest(UpdateVenueRequest request) {
    _validateUpdateRequest(request);

    // Location is required for setup completion
    if (request.location == null) {
      throw ValidationException('Location is required to complete setup');
    }

    if (request.location!.city == null || request.location!.city!.isEmpty) {
      throw ValidationException('City is required to complete setup');
    }

    if (request.location!.country == null || request.location!.country!.isEmpty) {
      throw ValidationException('Country is required to complete setup');
    }

    if (request.location!.coordinates == null || request.location!.coordinates!.length != 2) {
      throw ValidationException('Valid coordinates [longitude, latitude] are required to complete setup');
    }

    if (request.venueName == null || request.venueName!.isEmpty) {
      throw ValidationException('Venue name is required to complete setup');
    }
  }
}
