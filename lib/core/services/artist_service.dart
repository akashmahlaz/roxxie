/// 🎸 GIGMATCH Artist Service - BULLETPROOF VERSION
/// Handles artist profile operations with comprehensive error handling
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api.dart';
import '../models/models.dart';

/// Custom exception classes for better error handling
class ArtistServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const ArtistServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'ArtistServiceException: $message';
}

class NetworkException extends ArtistServiceException {
  const NetworkException(String message, {dynamic originalError})
      : super(message, code: 'NETWORK_ERROR', originalError: originalError);
}

class ValidationException extends ArtistServiceException {
  const ValidationException(String message, {dynamic originalError})
      : super(message, code: 'VALIDATION_ERROR', originalError: originalError);
}

class AuthenticationException extends ArtistServiceException {
  const AuthenticationException(String message, {dynamic originalError})
      : super(message, code: 'AUTH_ERROR', originalError: originalError);
}

class ArtistService {
  final ApiClient _client = ApiClient();
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  /// 🔍 Search artists with filters - BULLETPROOF VERSION
  Future<List<Artist>> searchArtists(ArtistSearchParams params) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🎸 [ArtistService] Searching artists with params: ${params.toQueryParams()}');

      // Validate input parameters
      _validateSearchParams(params);

      // Check network connectivity
      await _checkConnectivity();

      final response = await _client.get(
        Endpoints.artistsSearch,
        queryParameters: params.toQueryParams(),
      );

      debugPrint('🎸 [ArtistService] Search completed in ${stopwatch.elapsedMilliseconds}ms');

      // Validate response structure
      if (response.data == null) {
        throw ValidationException('Empty response from server');
      }

      final data = response.data['data'] ?? response.data['artists'] ?? [];

      if (data is! List) {
        throw ValidationException('Invalid response format: expected array');
      }

      final artists = data.map((e) {
        try {
          return Artist.fromJson(e as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ [ArtistService] Failed to parse artist: $e');
          return null;
        }
      }).where((artist) => artist != null).cast<Artist>().toList();

      debugPrint('🎸 [ArtistService] Found ${artists.length} artists');
      return artists;

    } on DioException catch (e) {
      final error = _handleDioError(e, 'search artists');
      debugPrint('❌ [ArtistService] Search failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = ArtistServiceException('Unexpected error during search: $e');
      debugPrint('❌ [ArtistService] Search failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// 👤 Get my artist profile - BULLETPROOF VERSION
  Future<Artist> getMyProfile() async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🎸 [ArtistService] Fetching my artist profile');

      // Check authentication
      await _checkAuthentication();

      final response = await _client.get(Endpoints.artistsMe);

      debugPrint('🎸 [ArtistService] Profile fetched in ${stopwatch.elapsedMilliseconds}ms');

      // Validate response
      if (response.data == null) {
        throw ValidationException('Empty profile response');
      }

      final artist = Artist.fromJson(response.data);

      debugPrint('🎸 [ArtistService] Profile loaded: ${artist.displayName} (${artist.id})');
      return artist;

    } on DioException catch (e) {
      final error = _handleDioError(e, 'get my profile');
      debugPrint('❌ [ArtistService] Get profile failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = ArtistServiceException('Unexpected error getting profile: $e');
      debugPrint('❌ [ArtistService] Get profile failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// ✏️ Update my artist profile - BULLETPROOF VERSION
  Future<Artist> updateMyProfile(UpdateArtistRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🎸 [ArtistService] Updating artist profile');

      // Validate request
      _validateUpdateRequest(request);

      // Check authentication
      await _checkAuthentication();

      // Check network connectivity
      await _checkConnectivity();

      final requestData = request.toJson();
      debugPrint('🎸 [ArtistService] Update data keys: ${requestData.keys.toList()}');

      final response = await _client.patch(
        Endpoints.artistsMe,
        data: requestData,
      );

      debugPrint('🎸 [ArtistService] Profile updated in ${stopwatch.elapsedMilliseconds}ms');

      // Validate response
      if (response.data == null) {
        throw ValidationException('Empty update response');
      }

      final artist = Artist.fromJson(response.data);

      debugPrint('🎸 [ArtistService] Profile updated successfully: ${artist.displayName}');
      return artist;

    } on DioException catch (e) {
      final error = _handleDioError(e, 'update profile');
      debugPrint('❌ [ArtistService] Update failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = ArtistServiceException('Unexpected error updating profile: $e');
      debugPrint('❌ [ArtistService] Update failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// ✅ Complete artist profile setup - BULLETPROOF VERSION
  Future<Artist> completeSetup(UpdateArtistRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🎸 [ArtistService] Completing artist profile setup');

      // Validate request
      _validateCompleteSetupRequest(request);

      // Check authentication
      await _checkAuthentication();

      // Check network connectivity
      await _checkConnectivity();

      final requestData = request.toJson();
      debugPrint('🎸 [ArtistService] Setup data keys: ${requestData.keys.toList()}');

      // Retry logic for setup completion (critical operation)
      Artist? result;
      Exception? lastError;

      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          debugPrint('🎸 [ArtistService] Setup attempt $attempt/$_maxRetries');

          final response = await _client.post(
            Endpoints.artistsCompleteSetup,
            data: requestData,
          );

          debugPrint('🎸 [ArtistService] Setup completed in ${stopwatch.elapsedMilliseconds}ms (attempt $attempt)');

          // Validate response
          if (response.data == null) {
            throw ValidationException('Empty setup response');
          }

          result = Artist.fromJson(response.data);
          break; // Success, exit retry loop

        } on DioException catch (e) {
          lastError = e;
          if (attempt < _maxRetries) {
            final delay = _retryDelay * attempt;
            debugPrint('⚠️ [ArtistService] Setup attempt $attempt failed, retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        }
      }

      if (result == null) {
        throw lastError != null
            ? _handleDioError(lastError as DioException, 'complete setup')
            : ArtistServiceException('Setup failed after $_maxRetries attempts');
      }

      debugPrint('🎸 [ArtistService] Setup completed successfully: ${result.displayName}');
      return result;

    } catch (e) {
      final error = e is ArtistServiceException
          ? e
          : ArtistServiceException('Unexpected error during setup: $e');
      debugPrint('❌ [ArtistService] Setup failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// ✅ Complete artist profile setup with raw data - BULLETPROOF VERSION
  Future<Artist> completeSetupWithData(Map<String, dynamic> data) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🎸 [ArtistService] Completing setup with raw data');

      // Validate data
      _validateSetupData(data);

      // Check authentication
      await _checkAuthentication();

      // Check network connectivity
      await _checkConnectivity();

      debugPrint('🎸 [ArtistService] Raw data keys: ${data.keys.toList()}');

      // Retry logic for setup completion (critical operation)
      Artist? result;
      Exception? lastError;

      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          debugPrint('🎸 [ArtistService] Raw setup attempt $attempt/$_maxRetries');

          final response = await _client.post(
            Endpoints.artistsCompleteSetup,
            data: data,
          );

          debugPrint('🎸 [ArtistService] Raw setup completed in ${stopwatch.elapsedMilliseconds}ms (attempt $attempt)');

          // Validate response
          if (response.data == null) {
            throw ValidationException('Empty setup response');
          }

          result = Artist.fromJson(response.data);
          break; // Success, exit retry loop

        } on DioException catch (e) {
          lastError = e;
          if (attempt < _maxRetries) {
            final delay = _retryDelay * attempt;
            debugPrint('⚠️ [ArtistService] Raw setup attempt $attempt failed, retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        }
      }

      if (result == null) {
        throw lastError != null
            ? _handleDioError(lastError as DioException, 'complete setup with data')
            : ArtistServiceException('Raw setup failed after $_maxRetries attempts');
      }

      debugPrint('🎸 [ArtistService] Raw setup completed successfully: ${result.displayName}');
      return result;

    } catch (e) {
      final error = e is ArtistServiceException
          ? e
          : ArtistServiceException('Unexpected error during raw setup: $e');
      debugPrint('❌ [ArtistService] Raw setup failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// 🚀 Boost artist profile - BULLETPROOF VERSION
  Future<Artist> boostProfile() async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🎸 [ArtistService] Boosting artist profile');

      // Check authentication
      await _checkAuthentication();

      // Check network connectivity
      await _checkConnectivity();

      final response = await _client.post(Endpoints.artistsBoost);

      debugPrint('🎸 [ArtistService] Profile boosted in ${stopwatch.elapsedMilliseconds}ms');

      // Validate response
      if (response.data == null) {
        throw ValidationException('Empty boost response');
      }

      final artist = Artist.fromJson(response.data);

      debugPrint('🎸 [ArtistService] Profile boosted successfully: ${artist.displayName}');
      return artist;

    } on DioException catch (e) {
      final error = _handleDioError(e, 'boost profile');
      debugPrint('❌ [ArtistService] Boost failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = ArtistServiceException('Unexpected error boosting profile: $e');
      debugPrint('❌ [ArtistService] Boost failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// 🔍 Get artist by ID - BULLETPROOF VERSION
  Future<Artist> getArtistById(String id) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🎸 [ArtistService] Fetching artist by ID: $id');

      // Validate ID
      if (id.isEmpty) {
        throw ValidationException('Artist ID cannot be empty');
      }

      final response = await _client.get(Endpoints.artistById(id));

      debugPrint('🎸 [ArtistService] Artist fetched in ${stopwatch.elapsedMilliseconds}ms');

      // Validate response
      if (response.data == null) {
        throw ValidationException('Empty artist response for ID: $id');
      }

      final artist = Artist.fromJson(response.data);

      debugPrint('🎸 [ArtistService] Artist loaded: ${artist.displayName} (${artist.id})');
      return artist;

    } on DioException catch (e) {
      final error = _handleDioError(e, 'get artist by ID');
      debugPrint('❌ [ArtistService] Get artist failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = ArtistServiceException('Unexpected error getting artist: $e');
      debugPrint('❌ [ArtistService] Get artist failed: ${error.message}');
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
  ArtistServiceException _handleDioError(DioException e, String operation) {
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
  void _validateSearchParams(ArtistSearchParams params) {
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
    if (params.maxDistance != null && params.maxDistance! <= 0) {
      throw ValidationException('Max distance must be greater than 0');
    }
  }

  /// Validate update request
  void _validateUpdateRequest(UpdateArtistRequest request) {
    if (request.stageName != null && request.stageName!.length > 100) {
      throw ValidationException('Stage name must be less than 100 characters');
    }
    if (request.bio != null && request.bio!.length > 1000) {
      throw ValidationException('Bio must be less than 1000 characters');
    }
    if (request.genres != null && request.genres!.length > 5) {
      throw ValidationException('Maximum 5 genres allowed');
    }
    if (request.minPrice != null && request.minPrice! < 0) {
      throw ValidationException('Minimum price cannot be negative');
    }
    if (request.maxPrice != null && request.maxPrice! < 0) {
      throw ValidationException('Maximum price cannot be negative');
    }
    if (request.minPrice != null && request.maxPrice != null && request.minPrice! > request.maxPrice!) {
      throw ValidationException('Minimum price cannot be greater than maximum price');
    }
  }

  /// Validate complete setup request
  void _validateCompleteSetupRequest(UpdateArtistRequest request) {
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
  }

  /// Validate setup data
  void _validateSetupData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      throw ValidationException('Setup data cannot be empty');
    }

    // Check for required fields
    if (data['displayName'] == null || (data['displayName'] as String).isEmpty) {
      throw ValidationException('Display name is required to complete setup');
    }

    if (data['genres'] == null || (data['genres'] as List).isEmpty) {
      throw ValidationException('At least one genre is required to complete setup');
    }

    // Check location
    final location = data['location'];
    if (location == null || location is! Map) {
      throw ValidationException('Location is required to complete setup');
    }

    if (location['city'] == null || (location['city'] as String).isEmpty) {
      throw ValidationException('City is required to complete setup');
    }

    if (location['country'] == null || (location['country'] as String).isEmpty) {
      throw ValidationException('Country is required to complete setup');
    }

    if (location['coordinates'] == null || (location['coordinates'] as List).length != 2) {
      throw ValidationException('Valid coordinates [longitude, latitude] are required to complete setup');
    }
  }
}
