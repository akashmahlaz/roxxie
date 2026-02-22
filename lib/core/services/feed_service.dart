/// 📱 GIGMATCH Feed Service
/// API service for posts and stories
library;

import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/feed_models.dart';

class FeedService {
  final ApiClient _client = ApiClient();

  // ═══════════════════════════════════════════════════════════════════════════
  // POSTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get posts feed
  Future<PostsFeedResponse> getPostsFeed({
    int page = 1,
    int limit = 20,
    String sort = 'trending',
    String? hashtag,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort,
        if (hashtag != null) 'hashtag': hashtag,
      };

      final response = await _client.dio.get(
        Endpoints.postsFeed,
        queryParameters: queryParams,
      );

      return PostsFeedResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('FeedService.getPostsFeed error: $e');
      rethrow;
    }
  }

  /// Create a post
  Future<Post> createPost({
    String? caption,
    required List<Map<String, dynamic>> media,
    List<String>? hashtags,
    Map<String, dynamic>? location,
    bool commentsDisabled = false,
    bool likesHidden = false,
  }) async {
    try {
      final response = await _client.dio.post(
        Endpoints.postsCreate,
        data: {
          if (caption != null) 'caption': caption,
          'media': media,
          if (hashtags != null) 'hashtags': hashtags,
          if (location != null) 'location': location,
          'commentsDisabled': commentsDisabled,
          'likesHidden': likesHidden,
        },
      );

      return Post.fromJson(response.data);
    } catch (e) {
      debugPrint('FeedService.createPost error: $e');
      rethrow;
    }
  }

  /// Get single post
  Future<Post> getPost(String postId) async {
    try {
      final response = await _client.dio.get(Endpoints.postById(postId));
      return Post.fromJson(response.data);
    } catch (e) {
      debugPrint('FeedService.getPost error: $e');
      rethrow;
    }
  }

  /// Toggle like on post
  Future<({bool liked, int likeCount})> toggleLike(String postId) async {
    try {
      final response = await _client.dio.post(Endpoints.postLike(postId));
      return (
        liked: response.data['liked'] as bool,
        likeCount: response.data['likeCount'] as int,
      );
    } catch (e) {
      debugPrint('FeedService.toggleLike error: $e');
      rethrow;
    }
  }

  /// Toggle save on post
  Future<bool> toggleSave(String postId) async {
    try {
      final response = await _client.dio.post(Endpoints.postSave(postId));
      return response.data['saved'] as bool;
    } catch (e) {
      debugPrint('FeedService.toggleSave error: $e');
      rethrow;
    }
  }

  /// Add comment to post
  Future<Post> addComment(String postId, String text) async {
    try {
      final response = await _client.dio.post(
        Endpoints.postComments(postId),
        data: {'text': text},
      );
      return Post.fromJson(response.data);
    } catch (e) {
      debugPrint('FeedService.addComment error: $e');
      rethrow;
    }
  }

  /// Delete comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _client.dio.delete(Endpoints.postCommentDelete(postId, commentId));
    } catch (e) {
      debugPrint('FeedService.deleteComment error: $e');
      rethrow;
    }
  }

  /// Delete post
  Future<void> deletePost(String postId) async {
    try {
      await _client.dio.delete(Endpoints.postDelete(postId));
    } catch (e) {
      debugPrint('FeedService.deletePost error: $e');
      rethrow;
    }
  }

  /// Get user's posts
  Future<PostsFeedResponse> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        Endpoints.userPosts(userId),
        queryParameters: {'page': page, 'limit': limit},
      );
      return PostsFeedResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('FeedService.getUserPosts error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get stories feed
  Future<StoriesFeedResponse> getStoriesFeed({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _client.dio.get(
        Endpoints.storiesFeed,
        queryParameters: {'page': page, 'limit': limit},
      );

      return StoriesFeedResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('FeedService.getStoriesFeed error: $e');
      rethrow;
    }
  }

  /// Create a story
  Future<Story> createStory({
    required List<Map<String, dynamic>> items,
    int expiryHours = 24,
  }) async {
    try {
      final response = await _client.dio.post(
        Endpoints.storiesCreate,
        data: {'items': items, 'expiryHours': expiryHours},
      );

      return Story.fromJson(response.data);
    } catch (e) {
      debugPrint('FeedService.createStory error: $e');
      rethrow;
    }
  }

  /// Get single story
  Future<Story> getStory(String storyId) async {
    try {
      final response = await _client.dio.get(Endpoints.storyById(storyId));
      return Story.fromJson(response.data);
    } catch (e) {
      debugPrint('FeedService.getStory error: $e');
      rethrow;
    }
  }

  /// Get user's story
  Future<Story?> getUserStory(String userId) async {
    try {
      final response = await _client.dio.get(Endpoints.userStory(userId));
      if (response.data == null) return null;
      return Story.fromJson(response.data);
    } catch (e) {
      debugPrint('FeedService.getUserStory error: $e');
      return null;
    }
  }

  /// Mark story item as viewed
  Future<void> markStoryViewed(String storyId, String itemId) async {
    try {
      await _client.dio.post(Endpoints.storyItemView(storyId, itemId));
    } catch (e) {
      debugPrint('FeedService.markStoryViewed error: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  /// React to story item
  Future<void> reactToStory(String storyId, String itemId, String emoji) async {
    try {
      await _client.dio.post(
        Endpoints.storyReact(storyId),
        data: {'itemId': itemId, 'emoji': emoji},
      );
    } catch (e) {
      debugPrint('FeedService.reactToStory error: $e');
      rethrow;
    }
  }

  /// Delete story
  Future<void> deleteStory(String storyId) async {
    try {
      await _client.dio.delete(Endpoints.storyDelete(storyId));
    } catch (e) {
      debugPrint('FeedService.deleteStory error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOST (Premium Feature)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Boost a post to the top of feeds (Pro/Premium only)
  Future<Post> boostPost(String postId) async {
    try {
      debugPrint('FeedService.boostPost: boosting post $postId');
      final response = await _client.dio.post(Endpoints.postBoost(postId));
      final postData = response.data['post'] ?? response.data;
      return Post.fromJson(postData);
    } catch (e) {
      debugPrint('FeedService.boostPost error: $e');
      rethrow;
    }
  }

  /// Boost a story to the top of the stories tray (Pro/Premium only)
  Future<Story> boostStory(String storyId) async {
    try {
      debugPrint('FeedService.boostStory: boosting story $storyId');
      final response = await _client.dio.post(Endpoints.storyBoost(storyId));
      final storyData = response.data['story'] ?? response.data;
      return Story.fromJson(storyData);
    } catch (e) {
      debugPrint('FeedService.boostStory error: $e');
      rethrow;
    }
  }
}
