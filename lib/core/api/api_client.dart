///  GIGMATCH API Client
/// Dio-based HTTP client with interceptors for auth, refresh, and error handling
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';
import 'endpoints.dart';
import '../models/auth_models.dart';
import '../services/error_handling_service.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔐 SECURE STORAGE CONFIGURATION
  // Uses flutter_secure_storage with proper settings for data persistence
  // This fixes the issue where tokens are lost on app restart/reinstall
  // ═══════════════════════════════════════════════════════════════════════════
  late final FlutterSecureStorage _storage;

  // Android options to persist tokens across app restarts
  // Note: encryptedSharedPreferences is deprecated in v10, using custom ciphers
  static AndroidOptions _getAndroidOptions() => const AndroidOptions(
    // Use strong encryption algorithms for token storage
    keyCipherAlgorithm:
        KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    // Reset storage on error to prevent corrupted state blocking the app
    resetOnError: true,
  );

  // iOS options for keychain persistence
  static IOSOptions _getIOSOptions() => const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    // Sync across devices disabled for security
    synchronizable: false,
  );

  // Singleton
  factory ApiClient() => _instance ??= ApiClient._internal();

  ApiClient._internal() {
    // Initialize secure storage with platform-specific options
    _storage = FlutterSecureStorage(
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      _RetryInterceptor(this),
      if (kDebugMode) _LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔑 TOKEN MANAGEMENT
  // All storage operations have try-catch to handle encryption key issues
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: ApiConfig.accessTokenKey);
    } catch (e) {
      debugPrint('⚠️ Error reading access token: $e');
      // If encryption fails, clear storage and return null
      await _handleStorageError();
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: ApiConfig.refreshTokenKey);
    } catch (e) {
      debugPrint('⚠️ Error reading refresh token: $e');
      await _handleStorageError();
      return null;
    }
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    try {
      await _storage.write(
        key: ApiConfig.accessTokenKey,
        value: tokens.accessToken,
      );
      await _storage.write(
        key: ApiConfig.refreshTokenKey,
        value: tokens.refreshToken,
      );
      debugPrint('✅ Tokens saved successfully');
    } catch (e) {
      debugPrint('⚠️ Error saving tokens: $e');
      await _handleStorageError();
      // Retry once after clearing
      try {
        await _storage.write(
          key: ApiConfig.accessTokenKey,
          value: tokens.accessToken,
        );
        await _storage.write(
          key: ApiConfig.refreshTokenKey,
          value: tokens.refreshToken,
        );
        debugPrint('✅ Tokens saved successfully after retry');
      } catch (e2) {
        debugPrint('❌ Failed to save tokens even after retry: $e2');
      }
    }
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: ApiConfig.accessTokenKey);
      await _storage.delete(key: ApiConfig.refreshTokenKey);
      await _storage.delete(key: ApiConfig.userKey);
      await _storage.delete(key: ApiConfig.onboardingSkippedKey);
    } catch (e) {
      debugPrint('⚠️ Error clearing tokens: $e');
      // Force clear all storage on error
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }

  Future<void> saveUser(String userData) async {
    try {
      await _storage.write(key: ApiConfig.userKey, value: userData);
    } catch (e) {
      debugPrint('⚠️ Error saving user: $e');
    }
  }

  Future<String?> getUser() async {
    try {
      return await _storage.read(key: ApiConfig.userKey);
    } catch (e) {
      debugPrint('⚠️ Error reading user: $e');
      return null;
    }
  }

  /// Handle storage errors by clearing corrupted data
  Future<void> _handleStorageError() async {
    try {
      debugPrint('🔄 Attempting to recover from storage error...');
      await _storage.deleteAll();
      debugPrint('✅ Storage cleared after error');
    } catch (e) {
      debugPrint('❌ Failed to clear storage: $e');
    }
  }

  // ✅ Onboarding skipped flag
  Future<void> saveOnboardingSkipped(bool value) async {
    try {
      await _storage.write(
        key: ApiConfig.onboardingSkippedKey,
        value: value ? 'true' : 'false',
      );
    } catch (e) {
      debugPrint('⚠️ Error saving onboarding skipped: $e');
    }
  }

  Future<bool> getOnboardingSkipped() async {
    try {
      final value = await _storage.read(key: ApiConfig.onboardingSkippedKey);
      return value == 'true';
    } catch (e) {
      debugPrint('⚠️ Error reading onboarding skipped: $e');
      return false;
    }
  }

  // ✅ Has seen onboarding (for non-logged in users)
  Future<void> saveHasSeenOnboarding(bool value) async {
    try {
      await _storage.write(
        key: ApiConfig.hasSeenOnboardingKey,
        value: value ? 'true' : 'false',
      );
    } catch (e) {
      debugPrint('⚠️ Error saving has seen onboarding: $e');
    }
  }

  Future<bool> getHasSeenOnboarding() async {
    try {
      final value = await _storage.read(key: ApiConfig.hasSeenOnboardingKey);
      return value == 'true';
    } catch (e) {
      debugPrint('⚠️ Error reading has seen onboarding: $e');
      return false;
    }
  }

  // 🔄 Token Refresh
  Future<bool> refreshTokens() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${ApiConfig.baseUrl}${Endpoints.authRefresh}',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final tokens = AuthTokens.fromJson(response.data);
        await saveTokens(tokens);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return false;
    }
  }

  // 📡 HTTP Methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// 🔐 Auth Interceptor - Adds token to requests, handles 401
class _AuthInterceptor extends Interceptor {
  final ApiClient _client;

  _AuthInterceptor(this._client);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    final publicEndpoints = [
      Endpoints.authRegister,
      Endpoints.authLogin,
      Endpoints.authRefresh,
      Endpoints.authForgotPassword,
      Endpoints.authResetPassword,
    ];

    if (!publicEndpoints.any((e) => options.path.contains(e))) {
      final token = await _client.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _client.refreshTokens();
      if (refreshed) {
        // Retry original request
        try {
          final token = await _client.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await _client.dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // Refresh failed, clear tokens
          await _client.clearTokens();
        }
      } else {
        await _client.clearTokens();
      }
    }
    handler.next(err);
  }
}

/// 📝 Logging Interceptor (Debug only)
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🌐 ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('📦 Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅ ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('❌ ${err.response?.statusCode} ${err.requestOptions.uri}');
    debugPrint('   ${err.message}');
    if (err.response?.data != null) {
      debugPrint('   Response: ${err.response?.data}');
    }

    // Log to error handling service
    ErrorHandlingService().logError(
      err,
      stackTrace: err.stackTrace,
      context: {
        'url': err.requestOptions.uri.toString(),
        'method': err.requestOptions.method,
        'statusCode': err.response?.statusCode,
      },
    );

    handler.next(err);
  }
}

/// 🔄 Retry Interceptor with Exponential Backoff
class _RetryInterceptor extends Interceptor {
  final ApiClient _client;
  final int _maxRetries = 3;
  final Duration _initialDelay = const Duration(milliseconds: 500);

  _RetryInterceptor(this._client);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldRetry = _shouldRetry(err);
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (shouldRetry && retryCount < _maxRetries) {
      // Calculate exponential backoff delay
      final delay = _initialDelay * (1 << retryCount); // 2^retryCount

      debugPrint(
        '⏳ Retrying request (${retryCount + 1}/$_maxRetries) after ${delay.inMilliseconds}ms',
      );

      await Future.delayed(delay);

      // Increment retry count
      err.requestOptions.extra['retryCount'] = retryCount + 1;

      try {
        final response = await _client.dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          return handler.next(e);
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on specific HTTP status codes
    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      // Retry on server errors (500-599) and rate limiting (429)
      return statusCode >= 500 || statusCode == 429;
    }

    return false;
  }
}
