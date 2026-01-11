/// 📊 GigMatch Analytics Service - BULLETPROOF VERSION
///
/// Comprehensive analytics service for tracking user engagement and insights
/// Features:
/// - Profile views tracking
/// - Discovery/swipe analytics
/// - Engagement metrics
/// - Gig performance tracking
/// - Earnings analytics (for artists)
/// - Subscription analytics
/// - Offline support with queue
/// - Comprehensive error handling
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api.dart';
import '../providers/auth_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════
// ANALYTICS EVENT TYPES
/// ═══════════════════════════════════════════════════════════════════════

/// Types of analytics events
enum AnalyticsEventType {
  profileView,
  swipeRight,
  swipeLeft,
  match,
  messageSent,
  messageReceived,
  bookingCreated,
  bookingCompleted,
  reviewGiven,
  reviewReceived,
  gigViewed,
  gigApplied,
  searchPerformed,
  filterUsed,
  boostUsed,
  subscriptionUpgraded,
  subscriptionDowngraded,
  mediaUploaded,
  mediaViewed,
  appOpened,
  appBackgrounded,
  share,
  download,
}

/// ═══════════════════════════════════════════════════════════════════════
// DATA MODELS
/// ═══════════════════════════════════════════════════════════════════════

/// Profile view analytics
class ProfileViewAnalytics {
  final int totalViews;
  final int uniqueViewers;
  final Map<String, int> viewsByDay;
  final Map<String, int> viewsBySource;
  final double avgTimeOnProfile;
  final List<TopViewer> topViewers;

  const ProfileViewAnalytics({
    required this.totalViews,
    required this.uniqueViewers,
    required this.viewsByDay,
    required this.viewsBySource,
    required this.avgTimeOnProfile,
    required this.topViewers,
  });

  factory ProfileViewAnalytics.fromJson(Map<String, dynamic> json) {
    return ProfileViewAnalytics(
      totalViews: json['totalViews'] ?? 0,
      uniqueViewers: json['uniqueViewers'] ?? 0,
      viewsByDay: Map<String, int>.from(json['viewsByDay'] ?? {}),
      viewsBySource: Map<String, int>.from(json['viewsBySource'] ?? {}),
      avgTimeOnProfile: (json['avgTimeOnProfile'] ?? 0).toDouble(),
      topViewers: (json['topViewers'] as List?)
              ?.map((e) => TopViewer.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Top viewer information
class TopViewer {
  final String userId;
  final String userName;
  final String? userPhoto;
  final String userType;
  final int viewCount;
  final DateTime? lastViewed;

  const TopViewer({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.userType,
    required this.viewCount,
    this.lastViewed,
  });

  factory TopViewer.fromJson(Map<String, dynamic> json) {
    return TopViewer(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhoto: json['userPhoto'],
      userType: json['userType'] ?? 'artist',
      viewCount: json['viewCount'] ?? 0,
      lastViewed:
          json['lastViewed'] != null ? DateTime.tryParse(json['lastViewed']) : null,
    );
  }
}

/// Discovery/swipe analytics
class DiscoveryAnalytics {
  final int totalSwipesRight;
  final int totalSwipesLeft;
  final int matchesReceived;
  final int matchesMade;
  final double matchRate;
  final Map<String, int> swipesByGenre;
  final Map<String, int> matchesByGenre;
  final int boostCount;
  final DateTime? lastSwipeAt;
  final List<SwipeSession> recentSessions;

  const DiscoveryAnalytics({
    required this.totalSwipesRight,
    required this.totalSwipesLeft,
    required this.matchesReceived,
    required this.matchesMade,
    required this.matchRate,
    required this.swipesByGenre,
    required this.matchesByGenre,
    required this.boostCount,
    this.lastSwipeAt,
    required this.recentSessions,
  });

  factory DiscoveryAnalytics.fromJson(Map<String, dynamic> json) {
    return DiscoveryAnalytics(
      totalSwipesRight: json['totalSwipesRight'] ?? 0,
      totalSwipesLeft: json['totalSwipesLeft'] ?? 0,
      matchesReceived: json['matchesReceived'] ?? 0,
      matchesMade: json['matchesMade'] ?? 0,
      matchRate: (json['matchRate'] ?? 0).toDouble(),
      swipesByGenre: Map<String, int>.from(json['swipesByGenre'] ?? {}),
      matchesByGenre: Map<String, int>.from(json['matchesByGenre'] ?? {}),
      boostCount: json['boostCount'] ?? 0,
      lastSwipeAt:
          json['lastSwipeAt'] != null ? DateTime.tryParse(json['lastSwipeAt']) : null,
      recentSessions: (json['recentSessions'] as List?)
              ?.map((e) => SwipeSession.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Swipe session data
class SwipeSession {
  final DateTime startedAt;
  final DateTime? endedAt;
  final int swipesRight;
  final int swipesLeft;
  final int matches;
  final int durationSeconds;

  const SwipeSession({
    required this.startedAt,
    this.endedAt,
    required this.swipesRight,
    required this.swipesLeft,
    required this.matches,
    required this.durationSeconds,
  });

  factory SwipeSession.fromJson(Map<String, dynamic> json) {
    return SwipeSession(
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt']) ?? DateTime.now()
          : DateTime.now(),
      endedAt:
          json['endedAt'] != null ? DateTime.tryParse(json['endedAt']) : null,
      swipesRight: json['swipesRight'] ?? 0,
      swipesLeft: json['swipesLeft'] ?? 0,
      matches: json['matches'] ?? 0,
      durationSeconds: json['durationSeconds'] ?? 0,
    );
  }
}

/// Engagement analytics
class EngagementAnalytics {
  final int totalMessagesSent;
  final int totalMessagesReceived;
  final int totalConversations;
  final int avgResponseTimeMinutes;
  final int totalBookings;
  final int completedBookings;
  final int canceledBookings;
  final int reviewsGiven;
  final int reviewsReceived;
  final double avgRatingGiven;
  final double avgRatingReceived;
  final Map<String, int> activityByDay;
  final int activeDays;

  const EngagementAnalytics({
    required this.totalMessagesSent,
    required this.totalMessagesReceived,
    required this.totalConversations,
    required this.avgResponseTimeMinutes,
    required this.totalBookings,
    required this.completedBookings,
    required this.canceledBookings,
    required this.reviewsGiven,
    required this.reviewsReceived,
    required this.avgRatingGiven,
    required this.avgRatingReceived,
    required this.activityByDay,
    required this.activeDays,
  });

  factory EngagementAnalytics.fromJson(Map<String, dynamic> json) {
    return EngagementAnalytics(
      totalMessagesSent: json['totalMessagesSent'] ?? 0,
      totalMessagesReceived: json['totalMessagesReceived'] ?? 0,
      totalConversations: json['totalConversations'] ?? 0,
      avgResponseTimeMinutes: json['avgResponseTimeMinutes'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      canceledBookings: json['canceledBookings'] ?? 0,
      reviewsGiven: json['reviewsGiven'] ?? 0,
      reviewsReceived: json['reviewsReceived'] ?? 0,
      avgRatingGiven: (json['avgRatingGiven'] ?? 0).toDouble(),
      avgRatingReceived: (json['avgRatingReceived'] ?? 0).toDouble(),
      activityByDay: Map<String, int>.from(json['activityByDay'] ?? {}),
      activeDays: json['activeDays'] ?? 0,
    );
  }
}

/// Gig analytics (for artists)
class GigAnalytics {
  final int gigsApplied;
  final int gigsBooked;
  final int gigsCompleted;
  final int gigsCanceled;
  final double bookingRate;
  final double completionRate;
  final double avgEarningsPerGig;
  final double totalEarnings;
  final Map<String, double> earningsByMonth;
  final Map<String, int> gigsByVenueType;
  final List<RecentGig> recentGigs;

  const GigAnalytics({
    required this.gigsApplied,
    required this.gigsBooked,
    required this.gigsCompleted,
    required this.gigsCanceled,
    required this.bookingRate,
    required this.completionRate,
    required this.avgEarningsPerGig,
    required this.totalEarnings,
    required this.earningsByMonth,
    required this.gigsByVenueType,
    required this.recentGigs,
  });

  factory GigAnalytics.fromJson(Map<String, dynamic> json) {
    return GigAnalytics(
      gigsApplied: json['gigsApplied'] ?? 0,
      gigsBooked: json['gigsBooked'] ?? 0,
      gigsCompleted: json['gigsCompleted'] ?? 0,
      gigsCanceled: json['gigsCanceled'] ?? 0,
      bookingRate: (json['bookingRate'] ?? 0).toDouble(),
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      avgEarningsPerGig: (json['avgEarningsPerGig'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      earningsByMonth: Map<String, double>.from(json['earningsByMonth'] ?? {}),
      gigsByVenueType: Map<String, int>.from(json['gigsByVenueType'] ?? {}),
      recentGigs: (json['recentGigs'] as List?)
              ?.map((e) => RecentGig.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Recent gig data
class RecentGig {
  final String gigId;
  final String gigTitle;
  final String venueName;
  final double amount;
  final DateTime date;
  final String status;
  final double? rating;

  const RecentGig({
    required this.gigId,
    required this.gigTitle,
    required this.venueName,
    required this.amount,
    required this.date,
    required this.status,
    this.rating,
  });

  factory RecentGig.fromJson(Map<String, dynamic> json) {
    return RecentGig(
      gigId: json['gigId'] ?? '',
      gigTitle: json['gigTitle'] ?? '',
      venueName: json['venueName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date:
          json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
      status: json['status'] ?? 'pending',
      rating: json['rating']?.toDouble(),
    );
  }
}

/// Earnings summary
class EarningsSummary {
  final double totalEarnings;
  final double pendingEarnings;
  final double paidEarnings;
  final double avgPerGig;
  final int totalGigs;
  final Map<String, double> earningsByMonth;
  final Map<String, double> earningsByVenue;
  final List<Payout> recentPayouts;

  const EarningsSummary({
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.paidEarnings,
    required this.avgPerGig,
    required this.totalGigs,
    required this.earningsByMonth,
    required this.earningsByVenue,
    required this.recentPayouts,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      pendingEarnings: (json['pendingEarnings'] ?? 0).toDouble(),
      paidEarnings: (json['paidEarnings'] ?? 0).toDouble(),
      avgPerGig: (json['avgPerGig'] ?? 0).toDouble(),
      totalGigs: json['totalGigs'] ?? 0,
      earningsByMonth: Map<String, double>.from(json['earningsByMonth'] ?? {}),
      earningsByVenue: Map<String, double>.from(json['earningsByVenue'] ?? {}),
      recentPayouts: (json['recentPayouts'] as List?)
              ?.map((e) => Payout.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Payout data
class Payout {
  final String id;
  final double amount;
  final String status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? paidAt;

  const Payout({
    required this.id,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.paidAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt']) ?? DateTime.now()
          : DateTime.now(),
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'])
          : null,
      paidAt:
          json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
    );
  }
}

/// Analytics overview/dashboard data
class AnalyticsOverview {
  final ProfileViewAnalytics? profileViews;
  final DiscoveryAnalytics? discovery;
  final EngagementAnalytics? engagement;
  final GigAnalytics? gigs;
  final EarningsSummary? earnings;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String periodLabel;

  const AnalyticsOverview({
    this.profileViews,
    this.discovery,
    this.engagement,
    this.gigs,
    this.earnings,
    required this.periodStart,
    required this.periodEnd,
    required this.periodLabel,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      profileViews: json['profileViews'] != null
          ? ProfileViewAnalytics.fromJson(json['profileViews'])
          : null,
      discovery: json['discovery'] != null
          ? DiscoveryAnalytics.fromJson(json['discovery'])
          : null,
      engagement: json['engagement'] != null
          ? EngagementAnalytics.fromJson(json['engagement'])
          : null,
      gigs:
          json['gigs'] != null ? GigAnalytics.fromJson(json['gigs']) : null,
      earnings: json['earnings'] != null
          ? EarningsSummary.fromJson(json['earnings'])
          : null,
      periodStart: json['periodStart'] != null
          ? DateTime.tryParse(json['periodStart']) ?? DateTime.now()
          : DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: json['periodEnd'] != null
          ? DateTime.tryParse(json['periodEnd']) ?? DateTime.now()
          : DateTime.now(),
      periodLabel: json['periodLabel'] ?? 'Last 30 days',
    );
  }
}

/// Analytics period options
enum AnalyticsPeriod {
  today,
  week,
  month,
  quarter,
  year,
  allTime,
}

/// ═══════════════════════════════════════════════════════════════════════
// ANALYTICS SERVICE
/// ═══════════════════════════════════════════════════════════════════════

class AnalyticsService {
  final ApiClient _client;
  final AuthProvider? _authProvider;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  // State
  AnalyticsOverview? _overview;
  ProfileViewAnalytics? _profileViews;
  DiscoveryAnalytics? _discovery;
  EngagementAnalytics? _engagement;
  GigAnalytics? _gigs;
  EarningsSummary? _earnings;

  // Cache
  DateTime? _lastFetch;
  static const Duration _cacheValidity = Duration(minutes: 5);

  // Streams
  final StreamController<AnalyticsOverview> _overviewStream =
      StreamController<AnalyticsOverview>.broadcast();
  final StreamController<ProfileViewAnalytics> _profileViewsStream =
      StreamController<ProfileViewAnalytics>.broadcast();
  final StreamController<DiscoveryAnalytics> _discoveryStream =
      StreamController<DiscoveryAnalytics>.broadcast();
  final StreamController<EngagementAnalytics> _engagementStream =
      StreamController<EngagementAnalytics>.broadcast();
  final StreamController<AnalyticsEventType> _eventStream =
      StreamController<AnalyticsEventType>.broadcast();

  // Event queue for offline support
  final List<Map<String, dynamic>> _eventQueue = [];

  // ═══════════════════════════════════════════════════════════════════════
  // PUBLIC STREAMS & GETTERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Stream of overview changes
  Stream<AnalyticsOverview> get overviewStream => _overviewStream.stream;

  /// Stream of profile views changes
  Stream<ProfileViewAnalytics> get profileViewsStream =>
      _profileViewsStream.stream;

  /// Stream of discovery changes
  Stream<DiscoveryAnalytics> get discoveryStream => _discoveryStream.stream;

  /// Stream of engagement changes
  Stream<EngagementAnalytics> get engagementStream => _engagementStream.stream;

  /// Stream of tracked events
  Stream<AnalyticsEventType> get eventStream => _eventStream.stream;

  /// Cached overview
  AnalyticsOverview? get overview => _overview;

  /// Cached profile views
  ProfileViewAnalytics? get profileViews => _profileViews;

  /// Cached discovery analytics
  DiscoveryAnalytics? get discovery => _discovery;

  /// Cached engagement analytics
  EngagementAnalytics? get engagement => _engagement;

  /// Check if cache is valid
  bool get _isCacheValid =>
      _lastFetch != null &&
      DateTime.now().difference(_lastFetch!) < _cacheValidity;

  // ═══════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════

  AnalyticsService({
    required ApiClient apiClient,
    AuthProvider? authProvider,
  })  : _client = apiClient,
        _authProvider = authProvider;

  /// Initialize analytics service
  Future<bool> initialize() async {
    try {
      debugPrint('📊 [AnalyticsService] Initializing...');

      // Sync any pending events
      await _syncEventQueue();

      debugPrint('📊 [AnalyticsService] Initialized');
      return true;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Initialization failed: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OVERVIEW / DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  /// Get analytics overview/dashboard data
  Future<AnalyticsOverview> getOverview({
    AnalyticsPeriod period = AnalyticsPeriod.month,
  }) async {
    try {
      debugPrint('📊 [AnalyticsService] Fetching overview...');

      // Return cached data if valid
      if (_overview != null && _isCacheValid) {
        debugPrint('📊 [AnalyticsService] Returning cached overview');
        return _overview!;
      }

      final response = await _client.get(
        Endpoints.analyticsProfile,
        queryParameters: {'period': _periodToString(period)},
      );

      if (response.data == null) {
        throw AnalyticsException('Failed to load analytics overview');
      }

      _overview = AnalyticsOverview.fromJson(response.data as Map<String, dynamic>);

      // Emit to stream
      _overviewStream.add(_overview!);
      _lastFetch = DateTime.now();

      debugPrint('📊 [AnalyticsService] Overview loaded');
      return _overview!;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Failed to get overview: $e');
      rethrow;
    }
  }

  /// Refresh all analytics data
  Future<void> refreshAll() async {
    try {
      debugPrint('📊 [AnalyticsService] Refreshing all analytics...');

      _lastFetch = null;

      await Future.wait([
        getOverview(),
        getProfileViews(),
        getDiscoveryAnalytics(),
        getEngagementAnalytics(),
        getGigAnalytics(),
        if (_authProvider?.currentUser?.role == 'artist') getEarningsSummary(),
      ]);

      debugPrint('📊 [AnalyticsService] All analytics refreshed');
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Refresh failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROFILE VIEWS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get profile view analytics
  Future<ProfileViewAnalytics> getProfileViews({
    AnalyticsPeriod period = AnalyticsPeriod.month,
  }) async {
    try {
      debugPrint('📊 [AnalyticsService] Fetching profile views...');

      // Return cached data if valid
      if (_profileViews != null && _isCacheValid) {
        return _profileViews!;
      }

      final response = await _client.get(
        '${Endpoints.analyticsProfile}/views',
        queryParameters: {'period': _periodToString(period)},
      );

      if (response.data == null) {
        throw AnalyticsException('Failed to load profile views');
      }

      _profileViews =
          ProfileViewAnalytics.fromJson(response.data as Map<String, dynamic>);

      // Emit to stream
      _profileViewsStream.add(_profileViews!);

      return _profileViews!;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Failed to get profile views: $e');
      rethrow;
    }
  }

  /// Track a profile view (when someone views your profile)
  Future<void> trackProfileView({
    required String viewerId,
    required String viewerType,
    String source = 'discovery', // discovery, search, match, direct
  }) async {
    final event = {
      'type': AnalyticsEventType.profileView.name,
      'viewerId': viewerId,
      'viewerType': viewerType,
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  /// Get unique viewer count
  Future<int> getUniqueViewers() async {
    final views = await getProfileViews();
    return views.uniqueViewers;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISCOVERY ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get discovery/swipe analytics
  Future<DiscoveryAnalytics> getDiscoveryAnalytics({
    AnalyticsPeriod period = AnalyticsPeriod.month,
  }) async {
    try {
      debugPrint('📊 [AnalyticsService] Fetching discovery analytics...');

      // Return cached data if valid
      if (_discovery != null && _isCacheValid) {
        return _discovery!;
      }

      final response = await _client.get(
        Endpoints.analyticsDiscovery,
        queryParameters: {'period': _periodToString(period)},
      );

      if (response.data == null) {
        throw AnalyticsException('Failed to load discovery analytics');
      }

      _discovery =
          DiscoveryAnalytics.fromJson(response.data as Map<String, dynamic>);

      // Emit to stream
      _discoveryStream.add(_discovery!);

      return _discovery!;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Failed to get discovery analytics: $e');
      rethrow;
    }
  }

  /// Track a swipe action
  Future<void> trackSwipe({
    required String targetUserId,
    required String targetUserType,
    required bool isRightSwipe,
    String? genre,
  }) async {
    final event = {
      'type': (isRightSwipe
              ? AnalyticsEventType.swipeRight
              : AnalyticsEventType.swipeLeft)
          .name,
      'targetUserId': targetUserId,
      'targetUserType': targetUserType,
      'genre': genre,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  /// Get match rate percentage
  Future<double> getMatchRate() async {
    final analytics = await getDiscoveryAnalytics();
    return analytics.matchRate;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENGAGEMENT ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get engagement analytics
  Future<EngagementAnalytics> getEngagementAnalytics({
    AnalyticsPeriod period = AnalyticsPeriod.month,
  }) async {
    try {
      debugPrint('📊 [AnalyticsService] Fetching engagement analytics...');

      // Return cached data if valid
      if (_engagement != null && _isCacheValid) {
        return _engagement!;
      }

      final response = await _client.get(
        Endpoints.analyticsEngagement,
        queryParameters: {'period': _periodToString(period)},
      );

      if (response.data == null) {
        throw AnalyticsException('Failed to load engagement analytics');
      }

      _engagement =
          EngagementAnalytics.fromJson(response.data as Map<String, dynamic>);

      // Emit to stream
      _engagementStream.add(_engagement!);

      return _engagement!;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Failed to get engagement analytics: $e');
      rethrow;
    }
  }

  /// Track a message sent
  Future<void> trackMessageSent({
    required String conversationId,
    required String recipientId,
    bool hasMedia = false,
  }) async {
    final event = {
      'type': AnalyticsEventType.messageSent.name,
      'conversationId': conversationId,
      'recipientId': recipientId,
      'hasMedia': hasMedia,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  /// Track app opened
  Future<void> trackAppOpened() async {
    final event = {
      'type': AnalyticsEventType.appOpened.name,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  /// Get average response time in minutes
  Future<int> getAvgResponseTime() async {
    final analytics = await getEngagementAnalytics();
    return analytics.avgResponseTimeMinutes;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GIG ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get gig analytics (for artists)
  Future<GigAnalytics> getGigAnalytics({
    AnalyticsPeriod period = AnalyticsPeriod.month,
  }) async {
    try {
      debugPrint('📊 [AnalyticsService] Fetching gig analytics...');

      // Return cached data if valid
      if (_gigs != null && _isCacheValid) {
        return _gigs!;
      }

      final response = await _client.get(
        Endpoints.analyticsGigs,
        queryParameters: {'period': _periodToString(period)},
      );

      if (response.data == null) {
        throw AnalyticsException('Failed to load gig analytics');
      }

      _gigs = GigAnalytics.fromJson(response.data as Map<String, dynamic>);

      return _gigs!;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Failed to get gig analytics: $e');
      rethrow;
    }
  }

  /// Track gig application
  Future<void> trackGigApplied({
    required String gigId,
    required String venueId,
  }) async {
    final event = {
      'type': AnalyticsEventType.gigApplied.name,
      'gigId': gigId,
      'venueId': venueId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  /// Track booking completion
  Future<void> trackBookingCompleted({
    required String bookingId,
    double? amount,
  }) async {
    final event = {
      'type': AnalyticsEventType.bookingCompleted.name,
      'bookingId': bookingId,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  /// Get booking rate
  Future<double> getBookingRate() async {
    final analytics = await getGigAnalytics();
    return analytics.bookingRate;
  }

  /// Get completion rate
  Future<double> getCompletionRate() async {
    final analytics = await getGigAnalytics();
    return analytics.completionRate;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EARNINGS ANALYTICS (FOR ARTISTS)
  // ═══════════════════════════════════════════════════════════════════════

  /// Get earnings summary (for artists)
  Future<EarningsSummary> getEarningsSummary({
    AnalyticsPeriod period = AnalyticsPeriod.month,
  }) async {
    try {
      debugPrint('📊 [AnalyticsService] Fetching earnings summary...');

      // Return cached data if valid
      if (_earnings != null && _isCacheValid) {
        return _earnings!;
      }

      final response = await _client.get(
        Endpoints.analyticsEarnings,
        queryParameters: {'period': _periodToString(period)},
      );

      if (response.data == null) {
        throw AnalyticsException('Failed to load earnings');
      }

      _earnings =
          EarningsSummary.fromJson(response.data as Map<String, dynamic>);

      return _earnings!;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Failed to get earnings: $e');
      rethrow;
    }
  }

  /// Get total earnings
  Future<double> getTotalEarnings() async {
    final summary = await getEarningsSummary();
    return summary.totalEarnings;
  }

  /// Get pending earnings
  Future<double> getPendingEarnings() async {
    final summary = await getEarningsSummary();
    return summary.pendingEarnings;
  }

  /// Request payout
  Future<bool> requestPayout(double amount) async {
    try {
      debugPrint('📊 [AnalyticsService] Requesting payout of \$$amount');

      final response = await _client.post(
        '/subscription/payout',
        data: {'amount': amount},
      );

      return response.data != null && response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Payout request failed: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EVENT TRACKING
  // ═══════════════════════════════════════════════════════════════════════

  /// Track a custom event
  Future<void> trackEvent(
    AnalyticsEventType eventType, {
    Map<String, dynamic>? additionalData,
  }) async {
    final event = {
      'type': eventType.name,
      'timestamp': DateTime.now().toIso8601String(),
      if (additionalData != null) ...additionalData,
    };

    await _trackEvent(event);
  }

  /// Internal event tracking with queue
  Future<void> _trackEvent(Map<String, dynamic> event) async {
    try {
      // Add to queue first (optimistic)
      _eventQueue.add(event);

      // Emit to stream
      final eventType = _parseEventType(event['type'] as String);
      _eventStream.add(eventType);

      // Try to send to server
      await _sendEvent(event);
    } catch (e) {
      debugPrint('⚠️ [AnalyticsService] Event tracking failed: $e');
      // Event remains in queue for retry
    }
  }

  /// Send event to server
  Future<void> _sendEvent(Map<String, dynamic> event) async {
    try {
      await _client.post('/analytics/track', data: event);
      _eventQueue.remove(event);
    } catch (e) {
      debugPrint('⚠️ [AnalyticsService] Failed to send event: $e');
    }
  }

  /// Sync event queue to server
  Future<void> _syncEventQueue() async {
    if (_eventQueue.isEmpty) return;

    debugPrint(
      '📊 [AnalyticsService] Syncing ${_eventQueue.length} queued events',
    );

    final events = List<Map<String, dynamic>>.from(_eventQueue);
    _eventQueue.clear();

    try {
      await _client.post('/analytics/track/batch', data: {'events': events});
    } catch (e) {
      debugPrint('⚠️ [AnalyticsService] Batch sync failed: $e');
      // Re-queue failed events
      _eventQueue.addAll(events);
    }
  }

  /// Parse event type from string
  AnalyticsEventType _parseEventType(String type) {
    try {
      return AnalyticsEventType.values.firstWhere((e) => e.name == type);
    } catch (e) {
      return AnalyticsEventType.profileView;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SEARCH & FILTERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Track a search performed
  Future<void> trackSearch({
    required String query,
    List<String>? filters,
    int? resultsCount,
  }) async {
    final event = {
      'type': AnalyticsEventType.searchPerformed.name,
      'query': query,
      'filters': filters,
      'resultsCount': resultsCount,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  /// Track filter usage
  Future<void> trackFilterUsed({
    required String filterType,
    dynamic filterValue,
  }) async {
    final event = {
      'type': AnalyticsEventType.filterUsed.name,
      'filterType': filterType,
      'filterValue': filterValue,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOOST TRACKING
  // ═══════════════════════════════════════════════════════════════════════

  /// Track profile boost usage
  Future<void> trackBoostUsed({
    String boostType = 'profile',
    int duration = 24, // hours
  }) async {
    final event = {
      'type': AnalyticsEventType.boostUsed.name,
      'boostType': boostType,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  /// Get remaining boosts
  Future<int> getRemainingBoosts() async {
    try {
      final response = await _client.get('/subscription/boosts/remaining');
      return response.data?['count'] ?? 0;
    } catch (e) {
      debugPrint('⚠️ [AnalyticsService] Failed to get remaining boosts: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REVIEWS ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get review analytics
  Future<Map<String, dynamic>> getReviewAnalytics({
    AnalyticsPeriod period = AnalyticsPeriod.month,
  }) async {
    try {
      final response = await _client.get(
        '/analytics/reviews',
        queryParameters: {'period': _periodToString(period)},
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Failed to get review analytics: $e');
      return {};
    }
  }

  /// Track review given
  Future<void> trackReviewGiven({
    required String recipientId,
    required double rating,
  }) async {
    final event = {
      'type': AnalyticsEventType.reviewGiven.name,
      'recipientId': recipientId,
      'rating': rating,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  /// Track review received
  Future<void> trackReviewReceived({
    required String reviewerId,
    required double rating,
  }) async {
    final event = {
      'type': AnalyticsEventType.reviewReceived.name,
      'reviewerId': reviewerId,
      'rating': rating,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _trackEvent(event);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXPORT & REPORTING
  // ═══════════════════════════════════════════════════════════════════════

  /// Export analytics data
  Future<String?> exportAnalytics({
    AnalyticsPeriod period = AnalyticsPeriod.month,
    String format = 'json', // json, csv
  }) async {
    try {
      debugPrint('📊 [AnalyticsService] Exporting analytics...');

      final response = await _client.get(
        Endpoints.analyticsExport,
        queryParameters: {
          'period': _periodToString(period),
          'format': format,
        },
      );

      if (response.data != null) {
        return response.data['downloadUrl'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Export failed: $e');
      return null;
    }
  }

  /// Generate PDF report
  Future<String?> generateReport({
    AnalyticsPeriod period = AnalyticsPeriod.month,
    List<String>? sections,
  }) async {
    try {
      debugPrint('📊 [AnalyticsService] Generating report...');

      final response = await _client.post(
        '/analytics/report',
        data: {
          'period': _periodToString(period),
          'sections': sections,
        },
      );

      if (response.data != null) {
        return response.data['reportUrl'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Report generation failed: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Convert period enum to string
  String _periodToString(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.today:
        return 'today';
      case AnalyticsPeriod.week:
        return 'week';
      case AnalyticsPeriod.month:
        return 'month';
      case AnalyticsPeriod.quarter:
        return 'quarter';
      case AnalyticsPeriod.year:
        return 'year';
      case AnalyticsPeriod.allTime:
        return 'all';
    }
  }

  /// Calculate percentage change
  double calculateChange(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  /// Format number for display
  String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Format currency for display
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════

  /// Dispose resources
  Future<void> dispose() async {
    await _overviewStream.close();
    await _profileViewsStream.close();
    await _discoveryStream.close();
    await _engagementStream.close();
    await _eventStream.close();

    _overview = null;
    _profileViews = null;
    _discovery = null;
    _engagement = null;
    _gigs = null;
    _earnings = null;
    _eventQueue.clear();

    debugPrint('📊 [AnalyticsService] Disposed');
  }

  /// Reset service state (on logout)
  Future<void> reset() async {
    await dispose();
    _lastFetch = null;
    debugPrint('📊 [AnalyticsService] Reset complete');
  }
}

/// ═══════════════════════════════════════════════════════════════════════
// EXCEPTION CLASS
/// ═══════════════════════════════════════════════════════════════════════

class AnalyticsException implements Exception {
  final String message;
  final dynamic originalError;

  const AnalyticsException(
    this.message, {
    this.originalError,
  });

  @override
  String toString() => 'AnalyticsException: $message';
}
