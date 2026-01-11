/// 🔍 GIGMATCH Discovery Service - BULLETPROOF VERSION
///
/// Handles swipe-based discovery and matching system for artists and venues
/// Features:
/// - Tinder-style swipe functionality
/// - Smart recommendations (rule-based scoring)
/// - Geo-spatial discovery
/// - Swipe persistence and undo
/// - Real-time match notifications
///
/// Matching Logic:
/// - Swipe Right: Save to favorites / Initiate contact
/// - Swipe Left: Skip (persisted, can undo within session)
/// - Mutual Right: Create match for messaging
///
/// Recommendation System (Phase 1 - Rule-based):
/// - Genre matching score (0-100)
/// - Distance calculation using 2dsphere index
/// - Budget compatibility
/// - Availability overlap
/// - Past booking history boost
/// - Reputation score boost
///
/// Future Phase 2:
/// - ML-based recommendations
/// - Collaborative filtering
/// - Deep learning models

library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api.dart';
import '../models/models.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// CUSTOM EXCEPTION CLASSES
/// ═══════════════════════════════════════════════════════════════════════

class DiscoveryServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const DiscoveryServiceException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'DiscoveryServiceException: $message';
}

class NetworkException extends DiscoveryServiceException {
  const NetworkException(
    String message, {
    dynamic originalError,
  }) : super(
          message,
          code: 'NETWORK_ERROR',
          originalError: originalError,
        );
}

class ValidationException extends DiscoveryServiceException {
  const ValidationException(
    String message, {
    dynamic originalError,
  }) : super(
          message,
          code: 'VALIDATION_ERROR',
          originalError: originalError,
        );
}

class AuthenticationException extends DiscoveryServiceException {
  const AuthenticationException(
    String message, {
    dynamic originalError,
  }) : super(
          message,
          code: 'AUTH_ERROR',
          originalError: originalError,
        );
}

class NotFoundException extends DiscoveryServiceException {
  const NotFoundException(
    String message, {
    dynamic originalError,
  }) : super(
          message,
          code: 'NOT_FOUND',
          originalError: originalError,
        );
}

/// ═══════════════════════════════════════════════════════════════════════
/// SWIPE DIRECTION ENUM
/// ═══════════════════════════════════════════════════════════════════════

enum SwipeDirection { left, right }

extension SwipeDirectionExtension on SwipeDirection {
  String get backendValue {
    switch (this) {
      case SwipeDirection.right:
        return 'right';
      case SwipeDirection.left:
        return 'left';
    }
  }

  static SwipeDirection fromBackendValue(String value) {
    switch (value.toLowerCase()) {
      case 'right':
        return SwipeDirection.right;
      case 'left':
        return SwipeDirection.left;
      default:
        return SwipeDirection.left;
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════
/// DISCOVERY ITEM (Unified for Artists/Venues/Gigs)
/// ═══════════════════════════════════════════════════════════════════════

/// Represents an item in the discovery feed
class DiscoveryItem {
  final String id;
  final String type; // 'artist', 'venue', 'gig'
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final String? city;
  final String? country;
  final List<String> genres;
  final double? priceMin;
  final double? priceMax;
  final String? currency;
  final double distanceMiles;
  final double recommendationScore;
  final bool isVerified;
  final bool isBoosted;
  final DateTime? date; // For gigs
  final Map<String, dynamic> rawData;

  DiscoveryItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    this.city,
    this.country,
    this.genres = const [],
    this.priceMin,
    this.priceMax,
    this.currency,
    this.distanceMiles = 0,
    this.recommendationScore = 0,
    this.isVerified = false,
    this.isBoosted = false,
    this.date,
    required this.rawData,
  });

  factory DiscoveryItem.fromArtist(Artist artist, {double? distance}) {
    return DiscoveryItem(
      id: artist.id,
      type: 'artist',
      title: artist.displayName,
      subtitle: artist.genres.isNotEmpty ? artist.genres.take(3).join(', ') : null,
      imageUrl: artist.profilePhotoUrl,
      rating: artist.reviewStats?.averageRating,
      reviewCount: artist.reviewStats?.totalReviews,
      city: artist.location?.city,
      country: artist.location?.country,
      genres: artist.genres,
      priceMin: artist.minPrice,
      priceMax: artist.maxPrice,
      currency: artist.currency,
      distanceMiles: distance ?? 0,
      recommendationScore: 0,
      isVerified: artist.isVerified,
      isBoosted: artist.isBoosted ?? false,
      rawData: artist.toJson(),
    );
  }

  factory DiscoveryItem.fromVenue(Venue venue, {double? distance}) {
    return DiscoveryItem(
      id: venue.id,
      type: 'venue',
      title: venue.venueName,
      subtitle: venue.preferredGenres.isNotEmpty
          ? venue.preferredGenres.take(3).join(', ')
          : null,
      imageUrl: venue.profilePhotoUrl,
      rating: venue.reviewStatsAverageRating,
      reviewCount: null,
      city: venue.location?.city,
      country: venue.location?.country,
      genres: venue.preferredGenres,
      priceMin: null,
      priceMax: null,
      currency: null,
      distanceMiles: distance ?? 0,
      recommendationScore: 0,
      isVerified: venue.isVerified,
      isBoosted: false,
      rawData: venue.toJson(),
    );
  }

  factory DiscoveryItem.fromGig(dynamic gig, {double? distance}) {
    return DiscoveryItem(
      id: gig['id'] ?? gig['_id'] ?? '',
      type: 'gig',
      title: gig['title'] ?? 'Gig Opportunity',
      subtitle: gig['genres'] != null && (gig['genres'] as List).isNotEmpty
          ? (gig['genres'] as List).take(3).join(', ')
          : null,
      imageUrl: null,
      rating: null,
      reviewCount: null,
      city: gig['venue']?['city'] ?? gig['location']?['city'],
      country: gig['venue']?['country'] ?? gig['location']?['country'],
      genres: List<String>.from(gig['genres'] ?? []),
      priceMin: gig['budgetMin']?.toDouble(),
      priceMax: gig['budgetMax']?.toDouble(),
      currency: gig['currency'] ?? 'USD',
      distanceMiles: distance ?? 0,
      recommendationScore: 0,
      isVerified: false,
      isBoosted: false,
      date: gig['date'] != null ? DateTime.tryParse(gig['date']) : null,
      rawData: gig,
    );
  }

  factory DiscoveryItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? json['itemType'] ?? 'unknown';
    final distance = (json['distanceMiles'] ?? json['distance'] ?? 0.0).toDouble();

    switch (type) {
      case 'artist':
        return DiscoveryItem(
          id: json['id'] ?? json['_id'] ?? '',
          type: type,
          title: json['displayName'] ?? json['title'] ?? '',
          subtitle: json['genres'] != null && (json['genres'] as List).isNotEmpty
              ? (json['genres'] as List).take(3).join(', ')
              : null,
          imageUrl: json['profilePhotoUrl'] ?? json['photo'],
          rating: (json['reviewStats']?['averageRating'] ?? json['rating'])?.toDouble(),
          reviewCount: json['reviewStats']?['totalReviews'] ?? json['reviewCount'],
          city: json['location']?['city'],
          country: json['location']?['country'],
          genres: List<String>.from(json['genres'] ?? []),
          priceMin: (json['minPrice'] ?? json['priceMin'])?.toDouble(),
          priceMax: (json['maxPrice'] ?? json['priceMax'])?.toDouble(),
          currency: json['currency'] ?? 'USD',
          distanceMiles: distance,
          recommendationScore: (json['recommendationScore'] ?? 0).toDouble(),
          isVerified: json['isVerified'] ?? false,
          isBoosted: json['isBoosted'] ?? false,
          rawData: json,
        );
      case 'venue':
        return DiscoveryItem(
          id: json['id'] ?? json['_id'] ?? '',
          type: type,
          title: json['venueName'] ?? json['title'] ?? '',
          subtitle: json['preferredGenres'] != null &&
                  (json['preferredGenres'] as List).isNotEmpty
              ? (json['preferredGenres'] as List).take(3).join(', ')
              : null,
          imageUrl: json['profilePhotoUrl'],
          rating: json['reviewStats']?['averageRating']?.toDouble(),
          reviewCount: json['reviewStats']?['totalReviews'],
          city: json['location']?['city'],
          country: json['location']?['country'],
          genres: List<String>.from(json['preferredGenres'] ?? json['genres'] ?? []),
          priceMin: null,
          priceMax: null,
          currency: null,
          distanceMiles: distance,
          recommendationScore: (json['recommendationScore'] ?? 0).toDouble(),
          isVerified: json['isVerified'] ?? false,
          isBoosted: false,
          rawData: json,
        );
      case 'gig':
        return DiscoveryItem(
          id: json['id'] ?? json['_id'] ?? '',
          type: type,
          title: json['title'] ?? 'Gig Opportunity',
          subtitle: json['genres'] != null && (json['genres'] as List).isNotEmpty
              ? (json['genres'] as List).take(3).join(', ')
              : null,
          imageUrl: null,
          rating: null,
          reviewCount: null,
          city: json['venue']?['city'] ?? json['location']?['city'],
          country: json['venue']?['country'] ?? json['location']?['country'],
          genres: List<String>.from(json['genres'] ?? []),
          priceMin: (json['budgetMin'] ?? json['priceMin'])?.toDouble(),
          priceMax: (json['budgetMax'] ?? json['priceMax'])?.toDouble(),
          currency: json['currency'] ?? 'USD',
          distanceMiles: distance,
          recommendationScore: (json['recommendationScore'] ?? 0).toDouble(),
          isVerified: false,
          isBoosted: false,
          date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
          rawData: json,
        );
      default:
        return DiscoveryItem(
          id: json['id'] ?? json['_id'] ?? '',
          type: type,
          title: json['title'] ?? json['name'] ?? '',
          subtitle: json['subtitle'],
          imageUrl: json['imageUrl'] ?? json['photo'],
          rating: json['rating']?.toDouble(),
          reviewCount: json['reviewCount'],
          city: json['city'],
          country: json['country'],
          genres: List<String>.from(json['genres'] ?? []),
          priceMin: json['priceMin']?.toDouble(),
          priceMax: json['priceMax']?.toDouble(),
          currency: json['currency'] ?? 'USD',
          distanceMiles: distance,
          recommendationScore: (json['recommendationScore'] ?? 0).toDouble(),
          isVerified: json['isVerified'] ?? false,
          isBoosted: json['isBoosted'] ?? false,
          rawData: json,
        );
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'rating': rating,
        'reviewCount': reviewCount,
        'city': city,
        'country': country,
        'genres': genres,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'currency': currency,
        'distanceMiles': distanceMiles,
        'recommendationScore': recommendationScore,
        'isVerified': isVerified,
        'isBoosted': isBoosted,
        if (date != null) 'date': date!.toIso8601String(),
      };
}

/// ═══════════════════════════════════════════════════════════════════════
/// SWIPE RECORD
/// ═══════════════════════════════════════════════════════════════════════

class SwipeRecord {
  final String id;
  final String itemId;
  final String itemType;
  final SwipeDirection direction;
  final DateTime createdAt;
  final bool createdMatch;
  final String? matchId;

  SwipeRecord({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.direction,
    required this.createdAt,
    this.createdMatch = false,
    this.matchId,
  });

  factory SwipeRecord.fromJson(Map<String, dynamic> json) {
    return SwipeRecord(
      id: json['id'] ?? json['_id'] ?? '',
      itemId: json['itemId'] ?? json['swipedItemId'] ?? '',
      itemType: json['itemType'] ?? json['swipedItemType'] ?? '',
      direction: SwipeDirectionExtension.fromBackendValue(
        json['direction'] ?? json['swipeDirection'] ?? 'left',
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      createdMatch: json['createdMatch'] ?? false,
      matchId: json['matchId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'itemType': itemType,
        'direction': direction.backendValue,
        'createdAt': createdAt.toIso8601String(),
        'createdMatch': createdMatch,
        if (matchId != null) 'matchId': matchId,
      };
}

/// ═══════════════════════════════════════════════════════════════════════
/// MATCH MODEL
/// ═══════════════════════════════════════════════════════════════════════

class Match {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantPhoto;
  final String participantType; // 'artist' or 'venue'
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  final bool isActive;

  Match({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantPhoto,
    required this.participantType,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
    this.isActive = true,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? json['_id'] ?? '',
      participantId: json['participantId'] ?? json['participant']?['id'] ?? '',
      participantName: json['participantName'] ??
          json['participant']?['displayName'] ??
          json['participant']?['venueName'] ??
          '',
      participantPhoto: json['participantPhoto'] ?? json['participant']?['profilePhotoUrl'],
      participantType: json['participantType'] ?? json['participant']?['type'] ?? 'artist',
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantId': participantId,
        'participantName': participantName,
        'participantPhoto': participantPhoto,
        'participantType': participantType,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'unreadCount': unreadCount,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };
}

/// ═══════════════════════════════════════════════════════════════════════
/// DISCOVERY FILTERS
/// ═══════════════════════════════════════════════════════════════════════

class DiscoveryFilters {
  // Location
  final double? latitude;
  final double? longitude;
  final int? radiusMiles;

  // Genre filters
  final List<String> genres;
  final bool matchAnyGenre;
  final bool matchAllGenres;

  // Price filters
  final double? minPrice;
  final double? maxPrice;
  final String? currency;

  // Availability filters
  final DateTime? availableFrom;
  final DateTime? availableTo;

  // Type filters
  final bool includeArtists;
  final bool includeVenues;
  final bool includeGigs;

  // Quality filters
  final double? minRating;
  final bool verifiedOnly;
  final bool boostedOnly;

  // Sorting
  final String sortBy; // 'distance', 'rating', 'recommendation', 'recent'
  final String sortOrder; // 'asc', 'desc'

  // Pagination
  final int page;
  final int limit;

  DiscoveryFilters({
    this.latitude,
    this.longitude,
    this.radiusMiles,
    this.genres = const [],
    this.matchAnyGenre = true,
    this.matchAllGenres = false,
    this.minPrice,
    this.maxPrice,
    this.currency,
    this.availableFrom,
    this.availableTo,
    this.includeArtists = true,
    this.includeVenues = true,
    this.includeGigs = true,
    this.minRating,
    this.verifiedOnly = false,
    this.boostedOnly = false,
    this.sortBy = 'recommendation',
    this.sortOrder = 'desc',
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    // Location
    if (latitude != null) params['latitude'] = latitude.toString();
    if (longitude != null) params['longitude'] = longitude.toString();
    if (radiusMiles != null) params['radiusMiles'] = radiusMiles.toString();

    // Genres
    if (genres.isNotEmpty) {
      params['genres'] = genres.join(',');
      params['matchAnyGenre'] = matchAnyGenre.toString();
      params['matchAllGenres'] = matchAllGenres.toString();
    }

    // Price
    if (minPrice != null) params['minPrice'] = minPrice.toString();
    if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
    if (currency != null) params['currency'] = currency;

    // Availability
    if (availableFrom != null) {
      params['availableFrom'] = availableFrom!.toIso8601String().split('T')[0];
    }
    if (availableTo != null) {
      params['availableTo'] = availableTo!.toIso8601String().split('T')[0];
    }

    // Types
    if (!includeArtists || !includeVenues || !includeGigs) {
      params['types'] = [
        if (includeArtists) 'artist',
        if (includeVenues) 'venue',
        if (includeGigs) 'gig',
      ].join(',');
    }

    // Quality
    if (minRating != null) params['minRating'] = minRating.toString();
    if (verifiedOnly) params['verifiedOnly'] = 'true';
    if (boostedOnly) params['boostedOnly'] = 'true';

    // Sorting
    params['sortBy'] = sortBy;
    params['sortOrder'] = sortOrder;

    // Pagination
    params['page'] = page.toString();
    params['limit'] = limit.toString();

    return params;
  }

  DiscoveryFilters copyWith({
    double? latitude,
    double? longitude,
    int? radiusMiles,
    List<String>? genres,
    bool? matchAnyGenre,
    bool? matchAllGenres,
    double? minPrice,
    double? maxPrice,
    String? currency,
    DateTime? availableFrom,
    DateTime? availableTo,
    bool? includeArtists,
    bool? includeVenues,
    bool? includeGigs,
    double? minRating,
    bool? verifiedOnly,
    bool? boostedOnly,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) {
    return DiscoveryFilters(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMiles: radiusMiles ?? this.radiusMiles,
      genres: genres ?? this.genres,
      matchAnyGenre: matchAnyGenre ?? this.matchAnyGenre,
      matchAllGenres: matchAllGenres ?? this.matchAllGenres,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      currency: currency ?? this.currency,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      includeArtists: includeArtists ?? this.includeArtists,
      includeVenues: includeVenues ?? this.includeVenues,
      includeGigs: includeGigs ?? this.includeGigs,
      minRating: minRating ?? this.minRating,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      boostedOnly: boostedOnly ?? this.boostedOnly,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════
/// DISCOVERY SERVICE
/// ═══════════════════════════════════════════════════════════════════════

class DiscoveryService {
  final ApiClient _client = ApiClient();
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  // Local cache for swipe queue (for undo functionality)
  final List<DiscoveryItem> _swipeQueue = [];
  final List<SwipeRecord> _recentSwipes = [];
  static const int _maxUndoHistory = 50;

  // ═══════════════════════════════════════════════════════════════════════
  // DISCOVERY FEED
  // ═══════════════════════════════════════════════════════════════════════

  /// 🔍 Get discovery feed with filters and recommendations
  Future<List<DiscoveryItem>> getDiscoveryFeed(DiscoveryFilters filters) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🔍 [DiscoveryService] Fetching discovery feed');

      // Validate filters
      _validateFilters(filters);

      // Check authentication and connectivity
      await _checkAuthentication();
      await _checkConnectivity();

      // Build query params
      final queryParams = filters.toQueryParams();
      debugPrint('🔍 [DiscoveryService] Query params: $queryParams');

      // Make API request
      final response = await _client.get(
        Endpoints.discover,
        queryParameters: queryParams,
      );

      debugPrint(
        '🔍 [DiscoveryService] Feed fetched in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Parse response
      if (response.data == null) {
        throw ValidationException('Empty discovery feed response');
      }

      final data = response.data['data'] ?? response.data['items'] ?? response.data ?? [];

      if (data is! List) {
        throw ValidationException('Invalid discovery feed format');
      }

      final items = data.map((item) {
        try {
          return DiscoveryItem.fromJson(item as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ [DiscoveryService] Failed to parse item: $e');
          return null;
        }
      }).where((item) => item != null).cast<DiscoveryItem>().toList();

      // Cache items for swipe functionality
      _swipeQueue.clear();
      _swipeQueue.addAll(items);

      debugPrint('🔍 [DiscoveryService] Found ${items.length} items in feed');
      return items;

    } on DioException catch (e) {
      final error = _handleDioError(e, 'get discovery feed');
      debugPrint('❌ [DiscoveryService] Feed fetch failed: ${error.message}');
      throw error;
    } catch (e) {
      final error = DiscoveryServiceException(
        'Unexpected error getting discovery feed: $e',
      );
      debugPrint('❌ [DiscoveryService] Feed fetch failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// 🔄 Refresh discovery feed (get new items)
  Future<List<DiscoveryItem>> refreshFeed(DiscoveryFilters filters) async {
    try {
      debugPrint('🔍 [DiscoveryService] Refreshing discovery feed');

      // Clear local cache
      _swipeQueue.clear();

      // Reset filters pagination
      final freshFilters = filters.copyWith(page: 1);

      return await getDiscoveryFeed(freshFilters);

    } catch (e) {
      debugPrint('❌ [DiscoveryService] Feed refresh failed: $e');
      rethrow;
    }
  }

  /// 📄 Load more items (pagination)
  Future<List<DiscoveryItem>> loadMore(DiscoveryFilters currentFilters) async {
    try {
      debugPrint('🔍 [DiscoveryService] Loading more items');

      final nextPage = currentFilters.page + 1;
      final nextFilters = currentFilters.copyWith(page: nextPage);

      // Check authentication and connectivity
      await _checkAuthentication();
      await _checkConnectivity();

      final response = await _client.get(
        Endpoints.discover,
        queryParameters: nextFilters.toQueryParams(),
      );

      final data = response.data['data'] ?? response.data['items'] ?? [];

      if (data is! List) {
        return [];
      }

      final items = data.map((item) {
        try {
          return DiscoveryItem.fromJson(item as Map<String, dynamic>);
        } catch (e) {
          return null;
        }
      }).where((item) => item != null).cast<DiscoveryItem>().toList();

      // Add to local cache
      _swipeQueue.addAll(items);

      debugPrint('🔍 [DiscoveryService] Loaded ${items.length} more items');
      return items;

    } catch (e) {
      debugPrint('❌ [DiscoveryService] Load more failed: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SWIPE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// 👆 Process a swipe action
  Future<SwipeResult> swipe(
    DiscoveryItem item,
    SwipeDirection direction, {
    bool persistToBackend = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint(
        '👆 [DiscoveryService] Swipe ${direction.backendValue} on ${item.type}:${item.id}',
      );

      // Validate swipe
      if (item.id.isEmpty) {
        throw ValidationException('Cannot swipe on item without ID');
      }

      // Remove from local queue
      _swipeQueue.removeWhere((i) => i.id == item.id);

      // Create swipe record
      final swipeRecord = SwipeRecord(
        id: '${DateTime.now().millisecondsSinceEpoch}_${item.id}',
        itemId: item.id,
        itemType: item.type,
        direction: direction,
        createdAt: DateTime.now(),
        createdMatch: false,
      );

      // Add to recent swipes (for undo)
      _recentSwipes.insert(0, swipeRecord);
      if (_recentSwipes.length > _maxUndoHistory) {
        _recentSwipes.removeLast();
      }

      // If swipe left, just persist and return
      if (direction == SwipeDirection.left) {
        if (persistToBackend) {
          await _persistSwipe(swipeRecord);
        }

        return SwipeResult(
          success: true,
          swipeRecord: swipeRecord,
          createdMatch: false,
          newItem: _swipeQueue.isNotEmpty ? _swipeQueue.first : null,
        );
      }

      // If swipe right, check for mutual match
      final matchResult = await _checkAndCreateMatch(item);

      if (matchResult.createdMatch) {
        swipeRecord.createdMatch = true;
        swipeRecord.matchId = matchResult.match?.id;

        return SwipeResult(
          success: true,
          swipeRecord: swipeRecord,
          createdMatch: true,
          match: matchResult.match,
          newItem: _swipeQueue.isNotEmpty ? _swipeQueue.first : null,
        );
      }

      // Right swipe saved but no match yet
      if (persistToBackend) {
        await _persistSwipe(swipeRecord);
      }

      return SwipeResult(
        success: true,
        swipeRecord: swipeRecord,
        createdMatch: false,
        newItem: _swipeQueue.isNotEmpty ? _swipeQueue.first : null,
      );

    } catch (e) {
      final error = DiscoveryServiceException(
        'Swipe failed: $e',
      );
      debugPrint('❌ [DiscoveryService] Swipe failed: ${error.message}');
      throw error;
    } finally {
      stopwatch.stop();
    }
  }

  /// ↩️ Undo last swipe
  Future<UndoResult> undoLastSwipe() async {
    try {
      debugPrint('↩️ [DiscoveryService] Undoing last swipe');

      if (_recentSwipes.isEmpty) {
        throw ValidationException('No swipes to undo');
      }

      final lastSwipe = _recentSwipes.first;

      // Don't allow undo if swipe created a match
      if (lastSwipe.createdMatch && lastSwipe.matchId != null) {
        throw ValidationException(
          'Cannot undo - already matched. Unmatch from matches screen instead.',
        );
      }

      // Remove from recent swipes
      _recentSwipes.removeAt(0);

      // Add item back to front of queue
      final itemId = lastSwipe.itemId;
      final itemType = lastSwipe.itemType;

      // Try to fetch the item details from backend
      final item = await _fetchItemById(itemId, itemType);

      if (item != null) {
        _swipeQueue.insert(0, item);
      }

      // Delete swipe from backend
      try {
        await _deleteSwipe(lastSwipe.id);
      } catch (e) {
        debugPrint('⚠️ [DiscoveryService] Failed to delete swipe from backend: $e');
        // Continue anyway - item is back in queue
      }

      return UndoResult(
        success: true,
        recoveredItem: item,
        message: item != null
            ? 'Swipe undone. Item restored to feed.'
            : 'Swipe undone but item details could not be recovered.',
      );

    } catch (e) {
      debugPrint('❌ [DiscoveryService] Undo failed: $e');
      rethrow;
    }
  }

  /// 📋 Get recent swipe history
  Future<List<SwipeRecord>> getSwipeHistory({int limit = 20}) async {
    try {
      debugPrint('📋 [DiscoveryService] Getting swipe history');

      await _checkAuthentication();

      final response = await _client.get(
        '${Endpoints.swipe}/history',
        queryParameters: {'limit': limit.toString()},
      );

      final data = response.data['data'] ?? response.data['swipes'] ?? [];

      if (data is! List) {
        return [];
      }

      return data.map((item) {
        return SwipeRecord.fromJson(item as Map<String, dynamic>);
      }).toList();

    } catch (e) {
      debugPrint('❌ [DiscoveryService] Failed to get swipe history: $e');
      // Return local history as fallback
      return _recentSwipes.take(limit).toList();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MATCHES
  // ═══════════════════════════════════════════════════════════════════════

  /// 💑 Get all matches
  Future<List<Match>> getMatches() async {
    try {
      debugPrint('💑 [DiscoveryService] Getting matches');

      await _checkAuthentication();

      final response = await _client.get(Endpoints.matchesList);

      final data = response.data['data'] ?? response.data['matches'] ?? [];

      if (data is! List) {
        return [];
      }

      return data.map((item) {
        return Match.fromJson(item as Map<String, dynamic>);
      }).toList();

    } catch (e) {
      debugPrint('❌ [DiscoveryService] Failed to get matches: $e');
      throw DiscoveryServiceException('Failed to get matches: $e');
    }
  }

  /// 💑 Get match by ID
  Future<Match> getMatchById(String matchId) async {
    try {
      debugPrint('💑 [DiscoveryService] Getting match: $matchId');

      await _checkAuthentication();

      final response = await _client.get(Endpoints.matchById(matchId));

      if (response.data == null) {
        throw NotFoundException('Match not found');
      }

      return Match.fromJson(response.data);

    } catch (e) {
      debugPrint('❌ [DiscoveryService] Failed to get match: $e');
      rethrow;
    }
  }

  /// 🔓 Unmatch with a participant
  Future<bool> unmatch(String matchId) async {
    try {
      debugPrint('🔓 [DiscoveryService] Unmatching: $matchId');

      await _checkAuthentication();

      await _client.delete(Endpoints.matchById(matchId));

      debugPrint('🔓 [DiscoveryService] Unmatched successfully');
      return true;

    } catch (e) {
      debugPrint('❌ [DiscoveryService] Unmatch failed: $e');
      throw DiscoveryServiceException('Failed to unmatch: $e');
    }
  }

  /// 📊 Get unread match count
  Future<int> getUnreadMatchCount() async {
    try {
      debugPrint('📊 [DiscoveryService] Getting unread match count');

      await _checkAuthentication();

      final response = await _client.get(Endpoints.matchesUnreadCount);

      return response.data['count'] ?? response.data['unreadCount'] ?? 0;

    } catch (e) {
      debugPrint('❌ [DiscoveryService] Failed to get unread count: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SMART RECOMMENDATIONS (Phase 1 - Rule-based)
  // ═══════════════════════════════════════════════════════════════════════

  /// 🧠 Calculate recommendation score for an item
  ///
  /// Scoring Algorithm (Phase 1):
  /// - Genre match: 0-40 points
  /// - Distance: 0-25 points (closer = higher)
  /// - Rating: 0-15 points
  /// - Boosted: +10 points
  /// - Verified: +5 points
  /// - Reputation: 0-5 points
  double calculateRecommendationScore({
    required DiscoveryItem item,
    required List<String> userGenres,
    double? userLatitude,
    double? userLongitude,
    double maxDistance = 100,
    double? userMinBudget,
    double? userMaxBudget,
  }) {
    double score = 0;

    // Genre Match Score (0-40 points)
    if (userGenres.isNotEmpty && item.genres.isNotEmpty) {
      final matchingGenres = userGenres.where((g) {
        final normalizedG = g.toLowerCase();
        return item.genres.any((ig) => ig.toLowerCase() == normalizedG);
      }).length;

      final genreMatchRatio = matchingGenres / userGenres.length;
      score += genreMatchRatio * 40;
    }

    // Distance Score (0-25 points)
    if (userLatitude != null && userLongitude != null && item.distanceMiles > 0) {
      if (item.distanceMiles <= maxDistance) {
        final distanceRatio = 1 - (item.distanceMiles / maxDistance);
        score += distanceRatio * 25;
      }
    } else if (item.distanceMiles == 0) {
      // Same location
      score += 25;
    }

    // Rating Score (0-15 points)
    if (item.rating != null && item.rating! > 0) {
      score += (item.rating! / 5.0) * 15;
    }

    // Boosted Bonus (+10 points)
    if (item.isBoosted) {
      score += 10;
    }

    // Verified Bonus (+5 points)
    if (item.isVerified) {
      score += 5;
    }

    // Budget Compatibility (0-10 points)
    if (userMinBudget != null && userMaxBudget != null) {
      if (item.priceMin != null && item.priceMax != null) {
        final itemAvgPrice = (item.priceMin! + item.priceMax!) / 2;
        if (userMinBudget <= itemAvgPrice && userMaxBudget >= itemAvgPrice) {
          score += 10;
        } else if (userMinBudget <= item.priceMax! && userMaxBudget >= item.priceMin!) {
          score += 5; // Partial overlap
        }
      }
    }

    // Cap score at 100
    return math.min(score, 100);
  }

  /// 🎯 Get recommended items sorted by score
  Future<List<DiscoveryItem>> getRecommendedItems({
    required DiscoveryFilters filters,
    required List<String> userGenres,
    double? userLatitude,
    double? userLongitude,
    double maxDistance = 100,
    double? userMinBudget,
    double? userMaxBudget,
  }) async {
    try {
      // Get discovery feed
      final items = await getDiscoveryFeed(filters);

      // Calculate and add recommendation scores
      final scoredItems = items.map((item) {
        final score = calculateRecommendationScore(
          item: item,
          userGenres: userGenres,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
          maxDistance: maxDistance,
          userMinBudget: userMinBudget,
          userMaxBudget: userMaxBudget,
        );

        return DiscoveryItem(
          id: item.id,
          type: item.type,
          title: item.title,
          subtitle: item.subtitle,
          imageUrl: item.imageUrl,
          rating: item.rating,
          reviewCount: item.reviewCount,
          city: item.city,
          country: item.country,
          genres: item.genres,
          priceMin: item.priceMin,
          priceMax: item.priceMax,
          currency: item.currency,
          distanceMiles: item.distanceMiles,
          recommendationScore: score,
          isVerified: item.isVerified,
          isBoosted: item.isBoosted,
          date: item.date,
          rawData: item.rawData,
        );
      }).toList();

      // Sort by recommendation score (descending)
      scoredItems.sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));

      return scoredItems;

    } catch (e) {
      debugPrint('❌ [DiscoveryService] Failed to get recommendations: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  void _validateFilters(DiscoveryFilters filters) {
    if (filters.latitude != null &&
        (filters.latitude! < -90 || filters.latitude! > 90)) {
      throw ValidationException('Latitude must be between -90 and 90');
    }
    if (filters.longitude != null &&
        (filters.longitude! < -180 || filters.longitude! > 180)) {
      throw ValidationException('Longitude must be between -180 and 180');
    }
    if (filters.radiusMiles != null && filters.radiusMiles! <= 0) {
      throw ValidationException('Radius must be greater than 0');
    }
    if (filters.minPrice != null && filters.minPrice! < 0) {
      throw ValidationException('Minimum price cannot be negative');
    }
    if (filters.maxPrice != null && filters.maxPrice! < 0) {
      throw ValidationException('Maximum price cannot be negative');
    }
    if (filters.minPrice != null &&
        filters.maxPrice != null &&
        filters.minPrice! > filters.maxPrice!) {
      throw ValidationException('Minimum price cannot exceed maximum price');
    }
    if (filters.page < 1) {
      throw ValidationException('Page must be 1 or greater');
    }
    if (filters.limit < 1 || filters.limit > 100) {
      throw ValidationException('Limit must be between 1 and 100');
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
      throw NetworkException(
        'No internet connection. Please check your network.',
      );
    }
  }

  Future<void> _persistSwipe(SwipeRecord record) async {
    try {
      await _client.post(
        Endpoints.swipe,
        data: record.toJson(),
      );
      debugPrint('👆 [DiscoveryService] Swipe persisted to backend');
    } catch (e) {
      debugPrint('⚠️ [DiscoveryService] Failed to persist swipe: $e');
      // Swipe is still in local history for undo
    }
  }

  Future<void> _deleteSwipe(String swipeId) async {
    try {
      await _client.delete('${Endpoints.swipe}/$swipeId');
      debugPrint('↩️ [DiscoveryService] Swipe deleted from backend');
    } catch (e) {
      debugPrint('⚠️ [DiscoveryService] Failed to delete swipe: $e');
      rethrow;
    }
  }

  Future<MatchCheckResult> _checkAndCreateMatch(DiscoveryItem item) async {
    try {
      // Check if the other party has already swiped right on us
      final response = await _client.post(
        '${Endpoints.swipe}/check-match',
        data: {
          'itemId': item.id,
          'itemType': item.type,
        },
      );

      if (response.data == null || response.data['isMatch'] != true) {
        return MatchCheckResult(createdMatch: false);
      }

      // Create match
      final matchResponse = await _client.post(
        Endpoints.matchesList,
        data: {
          'participantId': item.id,
          'participantType': item.type,
        },
      );

      if (matchResponse.data == null) {
        return MatchCheckResult(createdMatch: false);
      }

      final match = Match.fromJson(matchResponse.data);
      return MatchCheckResult(
        createdMatch: true,
        match: match,
      );

    } catch (e) {
      debugPrint('⚠️ [DiscoveryService] Match check failed: $e');
      return MatchCheckResult(createdMatch: false);
    }
  }

  Future<DiscoveryItem?> _fetchItemById(String itemId, String itemType) async {
    try {
      switch (itemType) {
        case 'artist':
          final response = await _client.get(Endpoints.artistById(itemId));
          if (response.data != null) {
            return DiscoveryItem.fromJson(response.data);
          }
          break;
        case 'venue':
          final response = await _client.get(Endpoints.venueById(itemId));
          if (response.data != null) {
            return DiscoveryItem.fromJson(response.data);
          }
          break;
        case 'gig':
          // Could add gig by ID endpoint
          break;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ [DiscoveryService] Failed to fetch item: $e');
      return null;
    }
  }

  DiscoveryServiceException _handleDioError(DioException e, String context) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          'Connection timed out. Please try again.',
          originalError: e,
        );
      case DioExceptionType.sendTimeout:
        return NetworkException(
          'Request timed out. Please try again.',
          originalError: e,
        );
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Response timed out. Please try again.',
          originalError: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (statusCode == 401) {
          return AuthenticationException(
            'Session expired. Please log in again.',
            originalError: e,
          );
        }
        if (statusCode == 404) {
          return NotFoundException(
            'Resource not found.',
            originalError: e,
          );
        }
        if (statusCode == 422) {
          final message = data?['message'] ?? 'Validation error';
          return ValidationException(message, originalError: e);
        }
        if (statusCode != null && statusCode >= 500) {
          return DiscoveryServiceException(
            'Server error. Please try again later.',
            code: 'SERVER_ERROR',
            originalError: e,
          );
        }
        return DiscoveryServiceException(
          'Request failed: ${e.message}',
          originalError: e,
        );

      case DioExceptionType.cancel:
        return DiscoveryServiceException(
          'Request was cancelled',
          originalError: e,
        );

      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') ?? false) {
          return NetworkException(
            'No internet connection. Please check your network.',
            originalError: e,
          );
        }
        return DiscoveryServiceException(
          'An unexpected error occurred. Please try again.',
          originalError: e,
        );
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════
/// RESULT CLASSES
/// ═══════════════════════════════════════════════════════════════════════

/// Result of a swipe action
class SwipeResult {
  final bool success;
  final SwipeRecord swipeRecord;
  final bool createdMatch;
  final Match? match;
  final DiscoveryItem? newItem;

  SwipeResult({
    required this.success,
    required this.swipeRecord,
    required this.createdMatch,
    this.match,
    this.newItem,
  });
}

/// Result of checking for a match
class MatchCheckResult {
  final bool createdMatch;
  final Match? match;

  MatchCheckResult({
    required this.createdMatch,
    this.match,
  });
}

/// Result of an undo action
class UndoResult {
  final bool success;
  final DiscoveryItem? recoveredItem;
  final String message;

  UndoResult({
    required this.success,
    this.recoveredItem,
    required this.message,
  });
}
