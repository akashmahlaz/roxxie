/// 🗄️ GIGMATCH API Cache Interceptor
/// In-memory GET response cache for Dio to reduce redundant network calls
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Cached response entry
class _CacheEntry {
  final Response response;
  final DateTime timestamp;

  _CacheEntry(this.response) : timestamp = DateTime.now();

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }
}

/// Dio interceptor that caches GET responses in memory
///
/// Usage:
/// ```dart
/// dio.interceptors.add(CacheInterceptor());
/// ```
///
/// To skip cache for a specific request:
/// ```dart
/// dio.get('/endpoint', options: Options(extra: {'skipCache': true}));
/// ```
///
/// To force refresh (bypass cache, but update it):
/// ```dart
/// dio.get('/endpoint', options: Options(extra: {'forceRefresh': true}));
/// ```
class CacheInterceptor extends Interceptor {
  final Map<String, _CacheEntry> _cache = {};
  final Duration defaultMaxAge;
  final int maxEntries;

  /// Per-path cache durations (path prefix → max age)
  final Map<String, Duration> _pathDurations = {};

  CacheInterceptor({
    this.defaultMaxAge = const Duration(minutes: 3),
    this.maxEntries = 100,
  }) {
    // Configure per-endpoint cache durations
    _pathDurations.addAll({
      '/artists/me': const Duration(minutes: 5),
      '/venues/me': const Duration(minutes: 5),
      '/matches': const Duration(minutes: 2),
      '/discovery': const Duration(minutes: 1),
      '/feed': const Duration(minutes: 3),
      '/reviews': const Duration(minutes: 10),
      '/gigs': const Duration(minutes: 3),
    });
  }

  /// Get the cache duration for a given path
  Duration _getDuration(String path) {
    for (final entry in _pathDurations.entries) {
      if (path.contains(entry.key)) {
        return entry.value;
      }
    }
    return defaultMaxAge;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();

    // Auto-invalidate related GET cache on mutations
    if (method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE') {
      _cache.removeWhere((key, _) => key.contains(options.path.split('/').take(3).join('/')));
      debugPrint('📦 [Cache] AUTO-INVALIDATE on $method: ${options.path}');
      handler.next(options);
      return;
    }

    // Only cache GET requests
    if (method != 'GET') {
      handler.next(options);
      return;
    }

    // Check skip/force flags
    final skipCache = options.extra['skipCache'] == true;
    final forceRefresh = options.extra['forceRefresh'] == true;

    if (skipCache || forceRefresh) {
      handler.next(options);
      return;
    }

    // Build cache key
    final cacheKey = _buildCacheKey(options);
    final entry = _cache[cacheKey];
    final maxAge = _getDuration(options.path);

    if (entry != null && !entry.isExpired(maxAge)) {
      debugPrint('📦 [Cache] HIT: ${options.path}');
      // Return cached response without flowing through onResponse
      handler.resolve(
        Response(
          requestOptions: options,
          data: entry.response.data,
          statusCode: entry.response.statusCode,
          headers: entry.response.headers,
          extra: {'fromCache': true},
        ),
      );
      return;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Only cache successful GET responses (skip if already from cache)
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300 &&
        response.extra['fromCache'] != true) {
      final skipCache = response.requestOptions.extra['skipCache'] == true;

      if (!skipCache) {
        final cacheKey = _buildCacheKey(response.requestOptions);
        _cache[cacheKey] = _CacheEntry(response);

        // Evict oldest entries if cache is full
        if (_cache.length > maxEntries) {
          _evictOldest();
        }

        debugPrint('📦 [Cache] STORE: ${response.requestOptions.path}');
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // On network error, try to return stale cache
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      final cacheKey = _buildCacheKey(err.requestOptions);
      final entry = _cache[cacheKey];

      if (entry != null) {
        debugPrint('📦 [Cache] STALE (offline): ${err.requestOptions.path}');
        handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: entry.response.data,
            statusCode: entry.response.statusCode,
            headers: entry.response.headers,
            extra: {'fromCache': true, 'stale': true},
          ),
        );
        return;
      }
    }

    handler.next(err);
  }

  /// Build a unique cache key from request options
  String _buildCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    return uri;
  }

  /// Evict the oldest 20% of cache entries
  void _evictOldest() {
    final entries = _cache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    final removeCount = (_cache.length * 0.2).ceil();
    for (int i = 0; i < removeCount && i < entries.length; i++) {
      _cache.remove(entries[i].key);
    }
  }

  /// Invalidate cache for a specific path (call after mutations)
  void invalidate(String pathContains) {
    _cache.removeWhere((key, _) => key.contains(pathContains));
    debugPrint('📦 [Cache] INVALIDATED: $pathContains');
  }

  /// Clear entire cache
  void clearAll() {
    _cache.clear();
    debugPrint('📦 [Cache] CLEARED');
  }
}
