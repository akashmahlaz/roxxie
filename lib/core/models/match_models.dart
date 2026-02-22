/// 🎯 GIGMATCH Match & Swipe Models
/// Models for swiping, matching, and discovery
library;

import 'package:flutter/foundation.dart';
import 'artist_models.dart';
import 'gig_models.dart';
import 'venues_models.dart';

/// Swipe Action Type
enum SwipeAction {
  like('like'),
  pass('pass'),
  superLike('super_like');

  final String value;
  const SwipeAction(this.value);

  static SwipeAction fromString(String value) {
    return SwipeAction.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => SwipeAction.pass,
    );
  }
}

/// Match Status
enum MatchStatus {
  active('active'),
  archived('archived'),
  blocked('blocked');

  final String value;
  const MatchStatus(this.value);

  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => MatchStatus.active,
    );
  }
}

/// Swipe Request
class SwipeRequest {
  final String targetId; // Artist or Venue ID being swiped
  final String targetType; // 'artist' or 'venue'
  final SwipeAction action;

  SwipeRequest({
    required this.targetId,
    required this.targetType,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
    'targetId': targetId,
    'targetType': targetType,
    'action': action.value,
  };
}

/// Swipe Response
class SwipeResponse {
  final bool success;
  final bool isMatch;
  final Match? match;
  final String? message;
  final String? swipeId; // Track for undo functionality

  SwipeResponse({
    required this.success,
    this.isMatch = false,
    this.match,
    this.message,
    this.swipeId,
  });

  factory SwipeResponse.fromJson(Map<String, dynamic> json) {
    return SwipeResponse(
      success: json['success'] ?? true,
      isMatch: json['isMatch'] ?? json['action'] == 'match',
      match: json['match'] != null ? Match.fromJson(json['match']) : null,
      message: json['message'],
      swipeId: json['swipeId'],
    );
  }
}

/// Discovery Card - Unified model for artists/venues in discovery
class DiscoveryCard {
  final String id;
  final bool isArtist;
  final bool isGig;
  final String name;
  final String? bio;
  final String primaryPhotoUrl;
  final List<String> galleryUrls;
  final String? location;
  final double? distance; // in miles/km
  final List<String> genres;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isBoosted;

  // Artist-specific
  final Artist? artist;

  // Venue-specific
  final Venue? venue;

  // Gig-specific
  final Gig? gig;

  DiscoveryCard({
    required this.id,
    required this.isArtist,
    required this.isGig,
    required this.name,
    this.bio,
    required this.primaryPhotoUrl,
    this.galleryUrls = const [],
    this.location,
    this.distance,
    this.genres = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isBoosted = false,
    this.artist,
    this.venue,
    this.gig,
  });

  factory DiscoveryCard.fromArtist(Artist artist, {double? distance}) {
    return DiscoveryCard(
      id: artist.id,
      isArtist: true,
      isGig: false,
      name: artist.stageName,
      bio: artist.bio,
      primaryPhotoUrl: artist.primaryPhoto,
      galleryUrls: artist.galleryUrls,
      location: artist.displayLocation,
      distance: distance,
      genres: artist.genres,
      rating: artist.rating,
      reviewCount: artist.reviewCount,
      isVerified: artist.isVerified,
      isBoosted: artist.isBoosted,
      artist: artist,
    );
  }

  factory DiscoveryCard.fromVenue(Venue venue, {double? distance}) {
    return DiscoveryCard(
      id: venue.id,
      isArtist: false,
      isGig: false,
      name: venue.name,
      bio: venue.bio,
      primaryPhotoUrl: venue.primaryPhoto,
      galleryUrls: venue.galleryUrls ?? [],
      location: venue.displayLocation,
      distance: distance,
      genres: venue.gigPreferences?.preferredGenres ?? [],
      rating: venue.rating ?? 0.0,
      reviewCount: venue.reviewCount ?? 0,
      isVerified: venue.isVerified,
      isBoosted: false,
      venue: venue,
    );
  }

  factory DiscoveryCard.fromGig(Gig gig, {double? distance}) {
    return DiscoveryCard(
      id: gig.id,
      isArtist: false,
      isGig: true,
      name: gig.title,
      bio: gig.description,
      primaryPhotoUrl: gig.venue?.coverPhoto ?? '',
      galleryUrls: const [],
      location: gig.location.venueAddress ?? gig.location.city,
      distance: distance,
      genres: gig.requiredGenres,
      rating: 0.0,
      reviewCount: 0,
      isVerified: false,
      isBoosted: false,
      gig: gig,
    );
  }

  factory DiscoveryCard.fromJson(Map<String, dynamic> json) {
    // Check type field first (most reliable from backend)
    final typeValue = json['type'];
    final type = typeValue?.toString().toLowerCase();

    if (type == 'gig') {
      final gig = Gig.fromJson(json);
      return DiscoveryCard.fromGig(
        gig,
        distance: (json['distance'] as num?)?.toDouble(),
      );
    }

    if (type == 'artist' || json['stageName'] != null || json['displayName'] != null) {
      final artist = Artist.fromJson(json);
      return DiscoveryCard.fromArtist(
        artist,
        distance: (json['distance'] as num?)?.toDouble(),
      );
    }

    // Default to venue
    final venue = Venue.fromJson(json);
    return DiscoveryCard.fromVenue(
      venue,
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }

  String get typeLabel => isGig ? 'Gig' : (isArtist ? 'Artist' : 'Venue');
  String get distanceLabel =>
      distance != null ? '${distance!.toStringAsFixed(1)} mi' : '';
}

/// Match Model
class Match {
  final String id;
  final String artistId;
  final String venueId;
  final Artist? artist;
  final Venue? venue;
  final MatchStatus status;
  final DateTime matchedAt;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final bool isViewedByArtist;
  final bool isViewedByVenue;
  
  // From otherUser field (new backend format)
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserPhoto;
  final String? otherUserType;
  final String? otherUserProfileId;

  Match({
    required this.id,
    required this.artistId,
    required this.venueId,
    this.artist,
    this.venue,
    this.status = MatchStatus.active,
    required this.matchedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.isViewedByArtist = false,
    this.isViewedByVenue = false,
    this.otherUserId,
    this.otherUserName,
    this.otherUserPhoto,
    this.otherUserType,
    this.otherUserProfileId,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    // Parse otherUser if present (new backend format)
    final otherUser = json['otherUser'] as Map<String, dynamic>?;
    final lastMessage = json['lastMessage'] as Map<String, dynamic>?;
    
    final matchId = json['_id'] ?? json['id'] ?? '';
    debugPrint('📇 [Match.fromJson] id=$matchId otherUser=${otherUser != null ? '{ name: ${otherUser['name']}, type: ${otherUser['type']}, photo: ${otherUser['profilePhoto'] != null}, profileId: ${otherUser['profileId']} }' : 'null'} '
        'lastMsg=${lastMessage?['content'] ?? json['lastMessagePreview']} unread=${json['unreadCount']}');

    return Match(
      id: json['_id'] ?? json['id'] ?? '',
      artistId: json['artistId'] is Map
          ? json['artistId']['_id']
          : json['artistId'] ?? json['artistUser'] ?? '',
      venueId: json['venueId'] is Map
          ? json['venueId']['_id']
          : json['venueId'] ?? json['venueUser'] ?? '',
      artist: json['artistId'] is Map
          ? Artist.fromJson(json['artistId'])
          : null,
      venue: json['venueId'] is Map ? Venue.fromJson(json['venueId']) : null,
      status: MatchStatus.fromString(json['status'] ?? 'active'),
      matchedAt:
          DateTime.tryParse(json['matchedAt'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
      lastMessageAt: lastMessage != null
          ? DateTime.tryParse(lastMessage['sentAt'] ?? '')
          : json['lastMessageAt'] != null
              ? DateTime.tryParse(json['lastMessageAt'])
              : null,
      lastMessagePreview: lastMessage?['content'] ?? json['lastMessagePreview'],
      unreadCount: json['unreadCount'] ?? 0,
      isViewedByArtist: json['isViewedByArtist'] ?? false,
      isViewedByVenue: json['isViewedByVenue'] ?? false,
      // New otherUser fields
      otherUserId: otherUser?['id'],
      otherUserName: otherUser?['name'],
      otherUserPhoto: otherUser?['profilePhoto'],
      otherUserType: otherUser?['type'],
      otherUserProfileId: otherUser?['profileId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'artistId': artistId,
    'venueId': venueId,
    'status': status.value,
    'matchedAt': matchedAt.toIso8601String(),
    'lastMessageAt': lastMessageAt?.toIso8601String(),
    'lastMessagePreview': lastMessagePreview,
    'unreadCount': unreadCount,
    'isViewedByArtist': isViewedByArtist,
    'isViewedByVenue': isViewedByVenue,
  };

  /// Get the "other" party name based on current user role
  String getOtherPartyName(bool currentUserIsArtist) {
    if (currentUserIsArtist) {
      return venue?.name ?? 'Unknown Venue';
    } else {
      return artist?.stageName ?? 'Unknown Artist';
    }
  }

  /// Get the "other" party photo based on current user role
  String getOtherPartyPhoto(bool currentUserIsArtist) {
    if (currentUserIsArtist) {
      return venue?.primaryPhoto ?? '';
    } else {
      return artist?.primaryPhoto ?? '';
    }
  }
}

/// Discovery Response (paginated)
class DiscoveryResponse {
  final List<DiscoveryCard> profiles;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  DiscoveryResponse({
    required this.profiles,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory DiscoveryResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns 'gigs' for artists, 'artists' for venues, or 'profiles'/'data' as fallback
    final rawProfiles =
        json['profiles'] ??
        json['items'] ??
        json['artists'] ??
        json['gigs'] ??
        json['data'] ??
        [];

    // Handle case where profiles might be nested in a 'data' object
    final profilesList = rawProfiles is Map ? rawProfiles['data'] ?? rawProfiles : rawProfiles;

    final List<DiscoveryCard> profiles = [];
    if (profilesList is List) {
      for (final item in profilesList) {
        try {
          if (item is Map<String, dynamic>) {
            profiles.add(DiscoveryCard.fromJson(item));
          }
        } catch (err) {
          debugPrint('Failed to parse discovery card: $err');
        }
      }
    }

    return DiscoveryResponse(
      profiles: profiles,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? profiles.length,
      hasMore: json['hasMore'] ?? (profiles.length >= (json['limit'] ?? 20)),
    );
  }
}

/// Match List Response (paginated)
class MatchListResponse {
  final List<Match> matches;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  MatchListResponse({
    required this.matches,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory MatchListResponse.fromJson(Map<String, dynamic> json) {
    return MatchListResponse(
      matches: (json['matches'] ?? json['data'] ?? [])
          .map<Match>((e) => Match.fromJson(e))
          .toList(),
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      hasMore: json['hasMore'] ?? ((json['page'] ?? 1) < (json['pages'] ?? 1)),
    );
  }
}

/// Who Liked Me Response
class WhoLikedMeResponse {
  final List<DiscoveryCard> profiles;
  final int count;
  final bool isPremiumFeature;

  WhoLikedMeResponse({
    required this.profiles,
    required this.count,
    this.isPremiumFeature = false,
  });

  factory WhoLikedMeResponse.fromJson(Map<String, dynamic> json) {
    return WhoLikedMeResponse(
      profiles: (json['profiles'] ?? json['data'] ?? [])
          .map<DiscoveryCard>((e) => DiscoveryCard.fromJson(e))
          .toList(),
      count: json['count'] ?? 0,
      isPremiumFeature: json['isPremiumFeature'] ?? false,
    );
  }
}
