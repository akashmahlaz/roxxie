/// 🚨 GIGMATCH Error Handling Service
/// Enterprise-level error handling, logging, and crash reporting
library;

import 'package:flutter/foundation.dart';
import 'dart:async';

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  fatal,
}

/// Custom app exception with detailed context
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;
  final Map<String, dynamic>? context;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    this.severity = ErrorSeverity.error,
    this.context,
  });

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }

  /// User-friendly message for display
  String get userMessage {
    switch (code) {
      case 'network':
        return 'Network connection error. Please check your internet.';
      case 'timeout':
        return 'Request timed out. Please try again.';
      case 'unauthorized':
        return 'Session expired. Please log in again.';
      case 'not_found':
        return 'Resource not found.';
      case 'server':
        return 'Server error. Please try again later.';
      default:
        return message;
    }
  }
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.originalError,
    super.stackTrace,
    super.context,
  }) : super(code: 'network');
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.originalError,
    super.stackTrace,
    super.context,
  }) : super(code: 'unauthorized', severity: ErrorSeverity.warning);
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    this.fieldErrors,
    super.context,
  }) : super(code: 'validation', severity: ErrorSeverity.warning);
}

/// Enterprise Error Handling Service
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  // Error listeners for UI components
  final _errorStreamController = StreamController<AppException>.broadcast();
  Stream<AppException> get errorStream => _errorStreamController.stream;

  // Error statistics
  int _errorCount = 0;
  int get errorCount => _errorCount;

  /// Initialize error handling
  Future<void> initialize() async {
    // Setup Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      logError(
        details.exception,
        stackTrace: details.stack,
        severity: ErrorSeverity.error,
        context: {
          'library': details.library ?? 'unknown',
          'context': details.context?.toString() ?? 'none',
        },
      );
    };

    // Setup platform dispatcher error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      logError(
        error,
        stackTrace: stack,
        severity: ErrorSeverity.fatal,
      );
      return true;
    };

    debugPrint('✅ Error Handling Service initialized');
  }

  /// Log an error with context
  void logError(
    dynamic error, {
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
  }) {
    _errorCount++;

    // Convert to AppException if needed
    final appException = error is AppException
        ? error
        : AppException(
            message: error.toString(),
            originalError: error,
            stackTrace: stackTrace,
            severity: severity,
            context: context,
          );

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚨 ERROR [${severity.name.toUpperCase()}]');
      debugPrint('Message: ${appException.message}');
      if (appException.code != null) {
        debugPrint('Code: ${appException.code}');
      }
      if (context != null) {
        debugPrint('Context: $context');
      }
      if (stackTrace != null) {
        debugPrint('Stack Trace:');
        debugPrint(stackTrace.toString());
      }
      debugPrint('═══════════════════════════════════════');
    }

    // Send to crash reporting service (Sentry, Firebase Crashlytics, etc.)
    _sendToCrashReporting(appException);

    // Notify listeners
    _errorStreamController.add(appException);
  }

  /// Send to crash reporting service
  void _sendToCrashReporting(AppException exception) {
    // TODO: Integrate with Sentry or Firebase Crashlytics
    // Example:
    // Sentry.captureException(
    //   exception.originalError ?? exception,
    //   stackTrace: exception.stackTrace,
    //   hint: Hint.withMap({
    //     'severity': exception.severity.name,
    //     'code': exception.code,
    //     ...?exception.context,
    //   }),
    // );
  }

  /// Handle API errors
  AppException handleApiError(dynamic error, {StackTrace? stackTrace}) {
    if (error is AppException) return error;

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection')) {
      return NetworkException(
        message: 'Network connection failed',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Timeout errors
    if (error.toString().contains('TimeoutException')) {
      return AppException(
        message: 'Request timed out',
        code: 'timeout',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic server error
    return AppException(
      message: 'An unexpected error occurred',
      code: 'unknown',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Dispose resources
  void dispose() {
    _errorStreamController.close();
  }
}

/// Error handling utilities
extension ErrorHandlingX on Object {
  /// Convert any error to AppException
  AppException toAppException({
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    if (this is AppException) return this as AppException;

    return AppException(
      message: toString(),
      originalError: this,
      stackTrace: stackTrace,
      severity: severity,
    );
  }
}
