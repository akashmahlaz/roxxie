/// 🚨 GIGMATCH Shared Exceptions
/// Central exception classes used across all services
library;

import 'package:dio/dio.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// BASE EXCEPTION CLASSES
/// ═══════════════════════════════════════════════════════════════════════

/// Base exception class for all service errors
abstract class GigMatchException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const GigMatchException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'GigMatchException: $message';
}

/// Base exception for service-specific errors
abstract class ServiceException extends GigMatchException {
  const ServiceException(super.message, {super.code, super.originalError});
}

/// ═══════════════════════════════════════════════════════════════════════
/// AUTHENTICATION EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Exception thrown when authentication fails
class AuthenticationException extends ServiceException {
  const AuthenticationException(
    super.message, {
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// Exception thrown when authorization fails
class AuthorizationException extends ServiceException {
  const AuthorizationException(
    super.message, {
    super.code = 'AUTHORIZATION_ERROR',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// VALIDATION EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Exception thrown when data validation fails
class ValidationException extends ServiceException {
  const ValidationException(
    super.message, {
    super.code = 'VALIDATION_ERROR',
    super.originalError,
  });
}

/// Exception thrown when required data is missing
class MissingDataException extends ServiceException {
  const MissingDataException(
    super.message, {
    super.code = 'MISSING_DATA',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// NETWORK EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Exception thrown when network operations fail
class NetworkException extends ServiceException {
  const NetworkException(
    super.message, {
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });

  /// Create NetworkException from DioException
  factory NetworkException.fromDioException(DioException e, String context) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          'Connection timed out during $context. Please try again.',
          originalError: e,
        );
      case DioExceptionType.sendTimeout:
        return NetworkException(
          'Request timed out during $context. Please try again.',
          originalError: e,
        );
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Response timed out during $context. Please try again.',
          originalError: e,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          'Connection error during $context. Please check your internet connection.',
          originalError: e,
        );
      case DioExceptionType.cancel:
        return NetworkException(
          'Request cancelled during $context.',
          originalError: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return NetworkException(
            'Session expired. Please log in again.',
            code: 'SESSION_EXPIRED',
            originalError: e,
          );
        }
        if (statusCode == 429) {
          return NetworkException(
            'Too many requests. Please wait before trying again.',
            code: 'RATE_LIMIT_EXCEEDED',
            originalError: e,
          );
        }
        if (statusCode != null && statusCode >= 500) {
          return NetworkException(
            'Server error during $context. Please try again later.',
            code: 'SERVER_ERROR',
            originalError: e,
          );
        }
        return NetworkException(
          'HTTP error ${statusCode ?? 'unknown'} during $context.',
          code: 'HTTP_ERROR',
          originalError: e,
        );
      case DioExceptionType.unknown:
      default:
        return NetworkException(
          'Unknown network error during $context: ${e.message}',
          code: 'UNKNOWN_NETWORK_ERROR',
          originalError: e,
        );
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════
/// RESOURCE EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Exception thrown when a resource is not found
class NotFoundException extends ServiceException {
  const NotFoundException(
    super.message, {
    super.code = 'NOT_FOUND',
    super.originalError,
  });
}

/// Exception thrown when a resource already exists
class AlreadyExistsException extends ServiceException {
  const AlreadyExistsException(
    super.message, {
    super.code = 'ALREADY_EXISTS',
    super.originalError,
  });
}

/// Exception thrown when access to a resource is forbidden
class ForbiddenException extends ServiceException {
  const ForbiddenException(
    super.message, {
    super.code = 'FORBIDDEN',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// BUSINESS LOGIC EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Exception thrown when an operation is not allowed
class NotAllowedException extends ServiceException {
  const NotAllowedException(
    super.message, {
    super.code = 'NOT_ALLOWED',
    super.originalError,
  });
}

/// Exception thrown when a service is unavailable
class ServiceUnavailableException extends ServiceException {
  const ServiceUnavailableException(
    super.message, {
    super.code = 'SERVICE_UNAVAILABLE',
    super.originalError,
  });
}

/// Exception thrown when a rate limit is exceeded
class RateLimitExceededException extends ServiceException {
  const RateLimitExceededException(
    super.message, {
    super.code = 'RATE_LIMIT_EXCEEDED',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// UPLOAD EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Exception thrown when upload operations fail
class UploadException extends ServiceException {
  const UploadException(
    super.message, {
    super.code = 'UPLOAD_ERROR',
    super.originalError,
  });
}

/// Exception thrown when file size exceeds limits
class FileTooLargeException extends UploadException {
  const FileTooLargeException(
    super.message, {
    super.code = 'FILE_TOO_LARGE',
    super.originalError,
  });
}

/// Exception thrown when file type is not supported
class UnsupportedFileTypeException extends UploadException {
  const UnsupportedFileTypeException(
    super.message, {
    super.code = 'UNSUPPORTED_FILE_TYPE',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// LOCATION EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Base exception for location service errors
abstract class LocationServiceException extends ServiceException {
  const LocationServiceException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Exception thrown when location permission is denied
class PermissionException extends LocationServiceException {
  const PermissionException(
    super.message, {
    super.code = 'PERMISSION_DENIED',
    super.originalError,
  });
}

/// Exception thrown when location service is disabled
class ServiceDisabledException extends LocationServiceException {
  const ServiceDisabledException(
    super.message, {
    super.code = 'SERVICE_DISABLED',
    super.originalError,
  });
}

/// Exception thrown when location timeout occurs
class LocationTimeoutException extends LocationServiceException {
  const LocationTimeoutException(
    super.message, {
    super.code = 'LOCATION_TIMEOUT',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// ARTIST SERVICE EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Base exception for artist service errors
abstract class ArtistServiceException extends ServiceException {
  const ArtistServiceException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Exception thrown in artist service operations
class ArtistServiceError extends ArtistServiceException {
  const ArtistServiceError(
    super.message, {
    super.code = 'ARTIST_SERVICE_ERROR',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// VENUE SERVICE EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Base exception for venue service errors
abstract class VenueServiceException extends ServiceException {
  const VenueServiceException(super.message, {super.code, super.originalError});
}

/// Exception thrown in venue service operations
class VenueServiceError extends VenueServiceException {
  const VenueServiceError(
    super.message, {
    super.code = 'VENUE_SERVICE_ERROR',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// CHAT SERVICE EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Base exception for chat service errors
abstract class ChatServiceException extends ServiceException {
  const ChatServiceException(super.message, {super.code, super.originalError});
}

/// Exception thrown in chat service operations
class ChatServiceError extends ChatServiceException {
  const ChatServiceError(
    super.message, {
    super.code = 'CHAT_SERVICE_ERROR',
    super.originalError,
  });
}

/// Exception thrown when message operations fail
class MessageException extends ChatServiceException {
  const MessageException(
    super.message, {
    super.code = 'MESSAGE_ERROR',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// DISCOVERY SERVICE EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Base exception for discovery service errors
abstract class DiscoveryServiceException extends ServiceException {
  const DiscoveryServiceException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Exception thrown in discovery service operations
class DiscoveryServiceError extends DiscoveryServiceException {
  const DiscoveryServiceError(
    super.message, {
    super.code = 'DISCOVERY_SERVICE_ERROR',
    super.originalError,
  });
}

/// Exception thrown when swipe operations fail
class SwipeException extends DiscoveryServiceException {
  const SwipeException(
    super.message, {
    super.code = 'SWIPE_ERROR',
    super.originalError,
  });
}

/// Exception thrown when match operations fail
class MatchException extends DiscoveryServiceException {
  const MatchException(
    super.message, {
    super.code = 'MATCH_ERROR',
    super.originalError,
  });
}

/// ═══════════════════════════════════════════════════════════════════════
/// SUBSCRIPTION EXCEPTIONS
/// ═══════════════════════════════════════════════════════════════════════

/// Base exception for subscription service errors
abstract class SubscriptionServiceException extends ServiceException {
  const SubscriptionServiceException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Exception thrown when subscription operations fail
class SubscriptionException extends SubscriptionServiceException {
  const SubscriptionException(
    super.message, {
    super.code = 'SUBSCRIPTION_ERROR',
    super.originalError,
  });
}

/// Exception thrown when payment operations fail
class PaymentException extends SubscriptionServiceException {
  const PaymentException(
    super.message, {
    super.code = 'PAYMENT_ERROR',
    super.originalError,
  });
}

/// Exception thrown when API operations fail
class ApiException extends ServiceException {
  final int statusCode;

  const ApiException(
    super.message,
    this.statusCode, {
    super.code = 'API_ERROR',
    super.originalError,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
