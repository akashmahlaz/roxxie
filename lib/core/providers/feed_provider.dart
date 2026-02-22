/// 📱 GIGMATCH Feed Provider
/// State management for Instagram-style posts and stories
library;

import 'package:flutter/foundation.dart';
import '../models/feed_models.dart';
import '../services/feed_service.dart';

enum FeedStatus { initial, loading, loaded, error }

enum FeedSort { trending, latest, following }

class FeedProvider extends ChangeNotifier {
  final FeedService _feedService = FeedService();

  // Posts state
  FeedStatus _postsStatus = FeedStatus.initial;
  List<Post> _posts = [];
  bool _hasMorePosts = true;
  int _postsPage = 1;
  FeedSort _currentSort = FeedSort.trending;
  DateTime? _lastPostsFetch;

  // Stories state
  FeedStatus _storiesStatus = FeedStatus.initial;
  List<Story> _stories = [];
  bool _hasMoreStories = true;
  DateTime? _lastStoriesFetch;

  // Error
  String? _errorMessage;

  // Getters
  FeedStatus get postsStatus => _postsStatus;
  List<Post> get posts => _posts;
  bool get hasMorePosts => _hasMorePosts;
  FeedSort get currentSort => _currentSort;

  FeedStatus get storiesStatus => _storiesStatus;
  List<Story> get stories => _stories;
  bool get hasMoreStories => _hasMoreStories;

  String? get errorMessage => _errorMessage;

  bool get isLoading =>
      _postsStatus == FeedStatus.loading ||
      _storiesStatus == FeedStatus.loading;

  /// Whether posts data is stale (older than 5 minutes)
  bool get isPostsStale {
    if (_lastPostsFetch == null) return true;
    return DateTime.now().difference(_lastPostsFetch!) > const Duration(minutes: 5);
  }

  /// Whether stories data is stale (older than 2 minutes)
  bool get isStoriesStale {
    if (_lastStoriesFetch == null) return true;
    return DateTime.now().difference(_lastStoriesFetch!) > const Duration(minutes: 2);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POSTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load posts feed
  Future<void> loadPosts({bool refresh = false}) async {
    if (_postsStatus == FeedStatus.loading) return;

    if (refresh) {
      _postsPage = 1;
      _hasMorePosts = true;
    }

    if (!_hasMorePosts && !refresh) return;

    _postsStatus = FeedStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _feedService.getPostsFeed(
        page: _postsPage,
        limit: 20,
        sort: _currentSort.name,
      );

      if (refresh) {
        _posts = response.posts;
      } else {
        _posts = [..._posts, ...response.posts];
      }

      _hasMorePosts = response.hasMore;
      _postsPage++;
      _postsStatus = FeedStatus.loaded;
      _lastPostsFetch = DateTime.now();
    } catch (e) {
      _errorMessage = e.toString();
      _postsStatus = FeedStatus.error;
      debugPrint('FeedProvider.loadPosts error: $e');
    }

    notifyListeners();
  }

  /// Change sort order
  Future<void> changeSort(FeedSort sort) async {
    if (_currentSort == sort) return;
    _currentSort = sort;
    await loadPosts(refresh: true);
  }

  /// Toggle like on post (optimistic update)
  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final newLiked = !post.isLiked;
    final newCount = post.likeCount + (newLiked ? 1 : -1);

    // Optimistic update
    _posts[index] = post.copyWith(isLiked: newLiked, likeCount: newCount);
    notifyListeners();

    try {
      final result = await _feedService.toggleLike(postId);
      // Update with server response
      _posts[index] = post.copyWith(
        isLiked: result.liked,
        likeCount: result.likeCount,
      );
    } catch (e) {
      // Revert on error
      _posts[index] = post;
      debugPrint('FeedProvider.toggleLike error: $e');
    }

    notifyListeners();
  }

  /// Toggle save on post (optimistic update)
  Future<void> toggleSave(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final newSaved = !post.isSaved;

    // Optimistic update
    _posts[index] = post.copyWith(isSaved: newSaved);
    notifyListeners();

    try {
      final saved = await _feedService.toggleSave(postId);
      _posts[index] = post.copyWith(isSaved: saved);
    } catch (e) {
      // Revert on error
      _posts[index] = post;
      debugPrint('FeedProvider.toggleSave error: $e');
    }

    notifyListeners();
  }

  /// Add comment to post
  Future<void> addComment(String postId, String text) async {
    try {
      final updatedPost = await _feedService.addComment(postId, text);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('FeedProvider.addComment error: $e');
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _feedService.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('FeedProvider.deletePost error: $e');
      rethrow;
    }
  }

  /// Create a new post
  Future<Post> createPost({
    String? caption,
    required List<Map<String, dynamic>> media,
    List<String>? hashtags,
    bool commentsDisabled = false,
    bool likesHidden = false,
  }) async {
    try {
      final post = await _feedService.createPost(
        caption: caption,
        media: media,
        hashtags: hashtags,
        commentsDisabled: commentsDisabled,
        likesHidden: likesHidden,
      );
      // Add to beginning of feed
      _posts.insert(0, post);
      notifyListeners();
      return post;
    } catch (e) {
      debugPrint('FeedProvider.createPost error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load stories feed
  Future<void> loadStories({bool refresh = false}) async {
    if (_storiesStatus == FeedStatus.loading) return;

    _storiesStatus = FeedStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _feedService.getStoriesFeed();
      _stories = response.stories;
      _hasMoreStories = response.hasMore;
      _storiesStatus = FeedStatus.loaded;
      _lastStoriesFetch = DateTime.now();
    } catch (e) {
      _errorMessage = e.toString();
      _storiesStatus = FeedStatus.error;
      debugPrint('FeedProvider.loadStories error: $e');
    }

    notifyListeners();
  }

  /// Mark story item as viewed
  Future<void> markStoryViewed(String storyId, String itemId) async {
    try {
      await _feedService.markStoryViewed(storyId, itemId);
    } catch (e) {
      debugPrint('FeedProvider.markStoryViewed error: $e');
    }

    // Update local state
    final storyIndex = _stories.indexWhere((s) => s.id == storyId);
    if (storyIndex != -1) {
      // We'd need to rebuild the story with updated item
      // For simplicity, just reload stories after viewing
      // (Or implement a more sophisticated local update)
    }
  }

  /// Create a new story
  Future<Story> createStory({required List<Map<String, dynamic>> items}) async {
    try {
      final story = await _feedService.createStory(items: items);
      // Add or update user's story at beginning
      final existingIndex = _stories.indexWhere(
        (s) => s.userId == story.userId,
      );
      if (existingIndex != -1) {
        _stories[existingIndex] = story;
      } else {
        _stories.insert(0, story);
      }
      notifyListeners();
      return story;
    } catch (e) {
      debugPrint('FeedProvider.createStory error: $e');
      rethrow;
    }
  }

  /// Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      await _feedService.deleteStory(storyId);
      _stories.removeWhere((s) => s.id == storyId);
      notifyListeners();
    } catch (e) {
      debugPrint('FeedProvider.deleteStory error: $e');
      rethrow;
    }
  }

  /// Remove story from local state only (after API delete)
  void removeStoryLocally(String storyId) {
    _stories.removeWhere((s) => s.id == storyId);
    notifyListeners();
  }

  /// React to a story item
  Future<void> reactToStory(String storyId, String itemId, String emoji) async {
    try {
      await _feedService.reactToStory(storyId, itemId, emoji);
    } catch (e) {
      debugPrint('FeedProvider.reactToStory error: $e');
      // Don't rethrow - reactions are non-critical
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMBINED
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load both posts and stories
  Future<void> loadFeed({bool refresh = false}) async {
    await Future.wait([
      loadPosts(refresh: refresh),
      loadStories(refresh: refresh),
    ]);
  }

  /// Refresh entire feed
  Future<void> refresh() async {
    await loadFeed(refresh: true);
  }

  /// Load posts only if data is stale or empty
  Future<void> loadPostsIfStale() async {
    if (isPostsStale || _posts.isEmpty) {
      await loadPosts(refresh: true);
    }
  }

  /// Load stories only if data is stale or empty
  Future<void> loadStoriesIfStale() async {
    if (isStoriesStale || _stories.isEmpty) {
      await loadStories(refresh: true);
    }
  }

  /// Load entire feed only if stale
  Future<void> loadFeedIfStale() async {
    await Future.wait([
      if (isPostsStale || _posts.isEmpty) loadPosts(refresh: true),
      if (isStoriesStale || _stories.isEmpty) loadStories(refresh: true),
    ]);
  }

  /// Clear all data
  void clear() {
    _posts = [];
    _stories = [];
    _postsPage = 1;
    _hasMorePosts = true;
    _hasMoreStories = true;
    _postsStatus = FeedStatus.initial;
    _storiesStatus = FeedStatus.initial;
    _errorMessage = null;
    _lastPostsFetch = null;
    _lastStoriesFetch = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOST (Premium Feature)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Boost a post to the top of feeds (Pro/Premium only)
  Future<bool> boostPost(String postId) async {
    try {
      debugPrint('FeedProvider.boostPost: boosting post $postId');
      final boostedPost = await _feedService.boostPost(postId);

      // Update the post in the local list
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _posts[idx] = boostedPost;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('FeedProvider.boostPost error: $e');
      _errorMessage = 'Failed to boost post: $e';
      notifyListeners();
      return false;
    }
  }

  /// Boost a story to the top of the stories tray (Pro/Premium only)
  Future<bool> boostStory(String storyId) async {
    try {
      debugPrint('FeedProvider.boostStory: boosting story $storyId');
      final boostedStory = await _feedService.boostStory(storyId);

      // Update the story in the local list
      final idx = _stories.indexWhere((s) => s.id == storyId);
      if (idx != -1) {
        _stories[idx] = boostedStory;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('FeedProvider.boostStory error: $e');
      _errorMessage = 'Failed to boost story: $e';
      notifyListeners();
      return false;
    }
  }
}
