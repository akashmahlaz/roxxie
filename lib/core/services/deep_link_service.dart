/// 🔗 GIGMATCH Deep Link Service
///
/// Handles incoming deep links and notification navigation
/// Features:
/// - App Links (Android) / Universal Links (iOS)
/// - Custom scheme (gigmatch://)
/// - Notification deep link handling
/// - Share URL generation
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

/// Deep link patterns for the app
class DeepLinkPatterns {
  static const String host = 'gigmatch.app';
  static const String scheme = 'gigmatch';

  // Profile patterns
  static String artistProfile(String artistId) => '/artist/$artistId';
  static String venueProfile(String venueId) => '/venue/$venueId';
  static String userProfile(String userId) => '/profile/$userId';

  // Gig patterns
  static String gigDetails(String gigId) => '/gig/$gigId';

  // Booking patterns
  static String bookingDetails(String bookingId) => '/booking/$bookingId';
  static String contractDetails(String contractId) => '/contract/$contractId';

  // Chat patterns
  static String chat(String matchId) => '/chat/$matchId';

  // Generate shareable URLs (point to OG-tag server for rich previews)
  static String shareableArtistUrl(String artistId) =>
      'https://$host/share/artist/$artistId';
  static String shareableGigUrl(String gigId) =>
      'https://$host/share/gig/$gigId';
  static String shareableVenueUrl(String venueId) =>
      'https://$host/share/venue/$venueId';
  static String shareablePostUrl(String postId) =>
      'https://$host/share/post/$postId';
  static String shareableStoryUrl(String storyId) =>
      'https://$host/share/story/$storyId';
  static String shareableProfileUrl(String id, {required bool isArtist}) =>
      isArtist ? shareableArtistUrl(id) : shareableVenueUrl(id);
}

/// Deep Link Service for handling incoming links
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();

  // Stream controller for deep links
  final _deepLinkController = StreamController<String>.broadcast();
  Stream<String> get deepLinkStream => _deepLinkController.stream;

  // Store pending deep link for when router is ready
  String? _pendingDeepLink;
  String? get pendingDeepLink => _pendingDeepLink;

  void clearPendingDeepLink() {
    _pendingDeepLink = null;
  }

  /// Initialize deep link handling
  Future<void> initialize() async {
    debugPrint('🔗 [DeepLinkService] Initializing...');

    try {
      // Handle initial link (app opened via deep link)
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 [DeepLinkService] Initial link: $initialLink');
        _handleDeepLink(initialLink);
      }

      // Listen for incoming links while app is running
      _appLinks.uriLinkStream.listen(
        (Uri uri) {
          debugPrint('🔗 [DeepLinkService] Incoming link: $uri');
          _handleDeepLink(uri);
        },
        onError: (error) {
          debugPrint('❌ [DeepLinkService] Link stream error: $error');
        },
      );

      debugPrint('✅ [DeepLinkService] Initialized');
    } catch (e) {
      debugPrint('❌ [DeepLinkService] Initialization error: $e');
    }
  }

  /// Handle incoming deep link URI
  void _handleDeepLink(Uri uri) {
    final path = _extractPath(uri);
    debugPrint('🔗 [DeepLinkService] Extracted path: $path');

    if (path.isNotEmpty) {
      _pendingDeepLink = path;
      _deepLinkController.add(path);
    }
  }

  /// Extract navigation path from URI
  String _extractPath(Uri uri) {
    // Handle custom scheme: gigmatch://chat/123
    if (uri.scheme == DeepLinkPatterns.scheme) {
      return '/${uri.host}${uri.path}';
    }

    // Handle https links: https://gigmatch.app/chat/123
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      if (uri.host == DeepLinkPatterns.host ||
          uri.host == 'www.${DeepLinkPatterns.host}') {
        return uri.path;
      }
    }

    // Fallback - return path as is
    return uri.path;
  }

  /// Handle deep link from notification payload
  void handleNotificationDeepLink(Map<String, dynamic> data) {
    final deepLink = data['deepLink'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('🔗 [DeepLinkService] Notification deep link: $deepLink');
      _pendingDeepLink = deepLink;
      _deepLinkController.add(deepLink);
    }
  }

  /// Parse a deep link path into route parameters
  DeepLinkRoute? parseRoute(String path) {
    // Remove leading slash
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final segments = cleanPath.split('/');

    if (segments.isEmpty) return null;

    final routeType = segments[0];
    final id = segments.length > 1 ? segments[1] : null;

    return DeepLinkRoute(
      type: routeType,
      id: id,
      fullPath: path,
    );
  }

  void dispose() {
    _deepLinkController.close();
  }
}

/// Parsed deep link route
class DeepLinkRoute {
  final String type;
  final String? id;
  final String fullPath;

  DeepLinkRoute({
    required this.type,
    this.id,
    required this.fullPath,
  });

  @override
  String toString() => 'DeepLinkRoute(type: $type, id: $id, path: $fullPath)';
}
