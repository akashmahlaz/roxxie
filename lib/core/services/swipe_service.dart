/// 🎯 GIGMATCH Swipe & Discovery Service
/// Handles swiping, discovery, and match operations
library;

import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../models/models.dart';

class SwipeService {
  final ApiClient _client = ApiClient();

  /// 🔍 Get discovery profiles (cards to swipe)
  Future<DiscoveryResponse> getDiscoveryProfiles({
    int page = 1,
    int limit = 20,
    double? latitude,
    double? longitude,
    int? maxDistance,
    List<String>? genres,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (maxDistance != null) {
        queryParams['maxDistance'] = maxDistance.toString();
      }
      if (genres != null && genres.isNotEmpty) {
        queryParams['genres'] = genres.join(',');
      }

      final response = await _client.get(
        Endpoints.discover,
        queryParameters: queryParams,
      );

      return DiscoveryResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Get discovery profiles error: $e');
      rethrow;
    }
  }

  /// 👍 Swipe right (like)
  Future<SwipeResponse> like(String targetId) async {
    return _swipe(SwipeRequest(targetId: targetId, action: SwipeAction.like));
  }

  /// 👎 Swipe left (pass)
  Future<SwipeResponse> pass(String targetId) async {
    return _swipe(SwipeRequest(targetId: targetId, action: SwipeAction.pass));
  }

  /// ⭐ Super like
  Future<SwipeResponse> superLike(String targetId) async {
    return _swipe(
      SwipeRequest(targetId: targetId, action: SwipeAction.superLike),
    );
  }

  /// 🔄 Swipe action
  Future<SwipeResponse> _swipe(SwipeRequest request) async {
    try {
      // Backend expects POST /swipes/:targetId with body {direction: 'right'|'left'}
      final direction =
          request.action == SwipeAction.like ||
              request.action == SwipeAction.superLike
          ? 'right'
          : 'left';

      final response = await _client.post(
        '${Endpoints.swipe}/${request.targetId}',
        data: {
          'direction': direction,
          'isSuperLike': request.action == SwipeAction.superLike,
        },
      );
      return SwipeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Swipe error: $e');
      rethrow;
    }
  }

  /// ↩️ Undo last swipe (premium feature)
  /// Note: Backend requires swipeId, this is a placeholder
  Future<bool> undoLastSwipe([String? swipeId]) async {
    try {
      if (swipeId == null) {
        debugPrint('⚠️ Cannot undo without swipeId');
        return false;
      }
      await _client.delete(Endpoints.undoSwipe(swipeId));
      return true;
    } catch (e) {
      debugPrint('Undo swipe error: $e');
      return false;
    }
  }

  /// 💕 Get who liked me (premium feature)
  Future<WhoLikedMeResponse> getWhoLikedMe() async {
    try {
      final response = await _client.get(Endpoints.whoLikedMe);
      return WhoLikedMeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Get who liked me error: $e');
      rethrow;
    }
  }
}

/// 🎯 Match Service
class MatchService {
  final ApiClient _client = ApiClient();

  /// 📋 Get all matches
  Future<MatchListResponse> getMatches({
    int page = 1,
    int limit = 20,
    MatchStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) queryParams['status'] = status.value;

      final response = await _client.get(
        Endpoints.matchesList,
        queryParameters: queryParams,
      );

      return MatchListResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Get matches error: $e');
      rethrow;
    }
  }

  /// 🔍 Get match by ID
  Future<Match> getMatchById(String id) async {
    try {
      final response = await _client.get(Endpoints.matchById(id));
      return Match.fromJson(response.data);
    } catch (e) {
      debugPrint('Get match by ID error: $e');
      rethrow;
    }
  }

  /// 👁️ Mark match as viewed
  Future<void> markAsViewed(String matchId) async {
    try {
      await _client.post(Endpoints.matchView(matchId));
    } catch (e) {
      debugPrint('Mark as viewed error: $e');
    }
  }

  /// 🔢 Get unread match count
  Future<int> getUnreadCount() async {
    try {
      final response = await _client.get(Endpoints.matchesUnreadCount);
      return response.data['count'] ?? 0;
    } catch (e) {
      debugPrint('Get unread count error: $e');
      return 0;
    }
  }

  /// 🗑️ Archive/unmatch
  Future<void> archiveMatch(String matchId) async {
    try {
      await _client.patch(
        Endpoints.matchById(matchId),
        data: {'status': MatchStatus.archived.value},
      );
    } catch (e) {
      debugPrint('Archive match error: $e');
      rethrow;
    }
  }

  /// 🚫 Block match
  Future<void> blockMatch(String matchId) async {
    try {
      await _client.patch(
        Endpoints.matchById(matchId),
        data: {'status': MatchStatus.blocked.value},
      );
    } catch (e) {
      debugPrint('Block match error: $e');
      rethrow;
    }
  }
}
