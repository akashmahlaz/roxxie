/// ⭐ GIGMATCH Review Service
/// Handles review operations with backend API
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../exceptions.dart';

/// Review model
class Review {
  final String id;
  final String reviewerId;
  final String reviewerRole;
  final String reviewerName;
  final String? reviewerPhoto;
  final String targetId;
  final String targetType;
  final String gigId;
  final String gigTitle;
  final DateTime gigDate;
  final int overallRating;
  final int? performanceRating;
  final int? professionalismRating;
  final int? reliabilityRating;
  final int? venueQualityRating;
  final int? paymentRating;
  final String content;
  final List<String> tags;
  final List<String> photos;
  final String? response;
  final DateTime? responseDate;
  final String status;
  final int helpfulCount;
  final bool isVerifiedBooking;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.reviewerId,
    required this.reviewerRole,
    required this.reviewerName,
    this.reviewerPhoto,
    required this.targetId,
    required this.targetType,
    required this.gigId,
    required this.gigTitle,
    required this.gigDate,
    required this.overallRating,
    this.performanceRating,
    this.professionalismRating,
    this.reliabilityRating,
    this.venueQualityRating,
    this.paymentRating,
    required this.content,
    this.tags = const [],
    this.photos = const [],
    this.response,
    this.responseDate,
    required this.status,
    this.helpfulCount = 0,
    this.isVerifiedBooking = false,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? json['_id'] ?? '',
      reviewerId: json['reviewerId'] ?? '',
      reviewerRole: json['reviewerRole'] ?? 'artist',
      reviewerName: json['reviewerName'] ?? 'Anonymous',
      reviewerPhoto: json['reviewerPhoto'],
      targetId: json['targetId'] ?? '',
      targetType: json['targetType'] ?? 'Artist',
      gigId: json['gigId'] ?? '',
      gigTitle: json['gigTitle'] ?? '',
      gigDate: json['gigDate'] != null
          ? DateTime.parse(json['gigDate'])
          : DateTime.now(),
      overallRating: json['overallRating'] ?? 0,
      performanceRating: json['performanceRating'],
      professionalismRating: json['professionalismRating'],
      reliabilityRating: json['reliabilityRating'],
      venueQualityRating: json['venueQualityRating'],
      paymentRating: json['paymentRating'],
      content: json['content'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      response: json['response'],
      responseDate: json['responseDate'] != null
          ? DateTime.parse(json['responseDate'])
          : null,
      status: json['status'] ?? 'published',
      helpfulCount: json['helpfulCount'] ?? 0,
      isVerifiedBooking: json['isVerifiedBooking'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Review statistics
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final double? averagePerformance;
  final double? averageProfessionalism;
  final double? averageReliability;
  final double? averageVenueQuality;
  final double? averagePayment;
  final List<TagCount> topTags;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    this.averagePerformance,
    this.averageProfessionalism,
    this.averageReliability,
    this.averageVenueQuality,
    this.averagePayment,
    this.topTags = const [],
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    final distribution = json['ratingDistribution'] ?? {};
    return ReviewStats(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: {
        1: distribution['1'] ?? 0,
        2: distribution['2'] ?? 0,
        3: distribution['3'] ?? 0,
        4: distribution['4'] ?? 0,
        5: distribution['5'] ?? 0,
      },
      averagePerformance: json['averagePerformance']?.toDouble(),
      averageProfessionalism: json['averageProfessionalism']?.toDouble(),
      averageReliability: json['averageReliability']?.toDouble(),
      averageVenueQuality: json['averageVenueQuality']?.toDouble(),
      averagePayment: json['averagePayment']?.toDouble(),
      topTags: (json['topTags'] as List? ?? [])
          .map((e) => TagCount.fromJson(e))
          .toList(),
    );
  }

  factory ReviewStats.empty() {
    return ReviewStats(
      averageRating: 0,
      totalReviews: 0,
      ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      topTags: [],
    );
  }
}

class TagCount {
  final String tag;
  final int count;

  TagCount({required this.tag, required this.count});

  factory TagCount.fromJson(Map<String, dynamic> json) {
    return TagCount(tag: json['tag'] ?? '', count: json['count'] ?? 0);
  }
}

/// Create review request
class CreateReviewRequest {
  final String gigId;
  final int overallRating;
  final int? performanceRating;
  final int? professionalismRating;
  final int? reliabilityRating;
  final int? venueQualityRating;
  final int? paymentRating;
  final String content;
  final List<String>? tags;
  final List<String>? photos;

  CreateReviewRequest({
    required this.gigId,
    required this.overallRating,
    this.performanceRating,
    this.professionalismRating,
    this.reliabilityRating,
    this.venueQualityRating,
    this.paymentRating,
    required this.content,
    this.tags,
    this.photos,
  });

  Map<String, dynamic> toJson() {
    return {
      'gigId': gigId,
      'overallRating': overallRating,
      if (performanceRating != null) 'performanceRating': performanceRating,
      if (professionalismRating != null)
        'professionalismRating': professionalismRating,
      if (reliabilityRating != null) 'reliabilityRating': reliabilityRating,
      if (venueQualityRating != null) 'venueQualityRating': venueQualityRating,
      if (paymentRating != null) 'paymentRating': paymentRating,
      'content': content,
      if (tags != null) 'tags': tags,
      if (photos != null) 'photos': photos,
    };
  }
}

/// Reviews response with pagination
class ReviewsResponse {
  final List<Review> reviews;
  final int total;
  final bool hasMore;

  ReviewsResponse({
    required this.reviews,
    required this.total,
    required this.hasMore,
  });

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    return ReviewsResponse(
      reviews: (json['reviews'] as List? ?? [])
          .map((e) => Review.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// Review Service
class ReviewService {
  final ApiClient _client = ApiClient();

  /// Get reviews for an artist
  Future<ReviewsResponse> getArtistReviews(
    String artistId, {
    int page = 1,
    int limit = 10,
    String sortBy = 'newest',
    int? rating,
  }) async {
    try {
      debugPrint('⭐ [ReviewService] Getting reviews for artist: $artistId');

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        if (rating != null) 'rating': rating.toString(),
      };

      final response = await _client.get(
        '/reviews/artist/$artistId',
        queryParameters: queryParams,
      );

      return ReviewsResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [ReviewService] Get artist reviews failed: $e');
      throw _handleError(e);
    }
  }

  /// Get review stats for an artist
  Future<ReviewStats> getArtistStats(String artistId) async {
    try {
      debugPrint('⭐ [ReviewService] Getting stats for artist: $artistId');

      final response = await _client.get('/reviews/artist/$artistId/stats');
      return ReviewStats.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [ReviewService] Get artist stats failed: $e');
      throw _handleError(e);
    }
  }

  /// Get reviews for a venue
  Future<ReviewsResponse> getVenueReviews(
    String venueId, {
    int page = 1,
    int limit = 10,
    String sortBy = 'newest',
    int? rating,
  }) async {
    try {
      debugPrint('⭐ [ReviewService] Getting reviews for venue: $venueId');

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        if (rating != null) 'rating': rating.toString(),
      };

      final response = await _client.get(
        '/reviews/venue/$venueId',
        queryParameters: queryParams,
      );

      return ReviewsResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [ReviewService] Get venue reviews failed: $e');
      throw _handleError(e);
    }
  }

  /// Get review stats for a venue
  Future<ReviewStats> getVenueStats(String venueId) async {
    try {
      debugPrint('⭐ [ReviewService] Getting stats for venue: $venueId');

      final response = await _client.get('/reviews/venue/$venueId/stats');
      return ReviewStats.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [ReviewService] Get venue stats failed: $e');
      throw _handleError(e);
    }
  }

  /// Create a review
  Future<Review> createReview(CreateReviewRequest request) async {
    try {
      debugPrint('⭐ [ReviewService] Creating review for gig: ${request.gigId}');

      final response = await _client.post('/reviews', data: request.toJson());

      return Review.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [ReviewService] Create review failed: $e');
      throw _handleError(e);
    }
  }

  /// Get my written reviews
  Future<ReviewsResponse> getMyReviews({int page = 1, int limit = 10}) async {
    try {
      debugPrint('⭐ [ReviewService] Getting my reviews');

      final response = await _client.get(
        '/reviews/me',
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      return ReviewsResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [ReviewService] Get my reviews failed: $e');
      throw _handleError(e);
    }
  }

  /// Respond to a review
  Future<Review> respondToReview(String reviewId, String response) async {
    try {
      debugPrint('⭐ [ReviewService] Responding to review: $reviewId');

      final res = await _client.put(
        '/reviews/$reviewId/respond',
        data: {'response': response},
      );

      return Review.fromJson(res.data);
    } on DioException catch (e) {
      debugPrint('❌ [ReviewService] Respond to review failed: $e');
      throw _handleError(e);
    }
  }

  /// Mark review as helpful
  Future<void> markHelpful(String reviewId) async {
    try {
      debugPrint('⭐ [ReviewService] Marking review helpful: $reviewId');

      await _client.post('/reviews/$reviewId/helpful');
    } on DioException catch (e) {
      debugPrint('❌ [ReviewService] Mark helpful failed: $e');
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data?['message'] ?? 'Request failed';
      return ApiException(message, e.response!.statusCode ?? 500);
    }
    return ApiException('Network error', 0);
  }
}
