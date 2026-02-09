/// 🎯 GIGMATCH Discovery Provider
/// State management for swiping and discovery
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/services.dart';

enum DiscoveryStatus { initial, loading, loaded, empty, error }

class DiscoveryProvider extends ChangeNotifier {
  final SwipeService _swipeService = SwipeService();

  DiscoveryStatus _status = DiscoveryStatus.initial;
  List<DiscoveryCard> _cards = [];
  int _currentIndex = 0;
  Match? _lastMatch;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isArtist = true; // Default to artist, set externally based on user role

  // Pagination
  int _page = 1;
  bool _hasMore = true;
  final int _limit = 20;

  // Filters
  double? _latitude;
  double? _longitude;
  int? _radiusMiles;
  List<String>? _genres;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;

  // Track swipeIds for undo (last N swipes)
  final List<String> _swipeHistory = [];
  static const int _maxSwipeHistorySize = 10;

  // Getters
  DiscoveryStatus get status => _status;
  List<DiscoveryCard> get cards => _cards;
  DiscoveryCard? get currentCard =>
      _cards.isNotEmpty && _currentIndex < _cards.length
      ? _cards[_currentIndex]
      : null;
  int get currentIndex => _currentIndex;
  int get remainingCards => _cards.length - _currentIndex;
  Match? get lastMatch => _lastMatch;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  /// Whether the current user is an artist (vs venue)
  /// Set this externally based on auth state before loading discovery
  bool get isArtist => _isArtist;

  /// Set the user role - call this before loading discovery
  void setUserRole(bool isArtist) {
    if (_isArtist != isArtist) {
      _isArtist = isArtist;
      _cards = [];
      _currentIndex = 0;
      _page = 1;
      _hasMore = true;
      notifyListeners();
    }
  }
  bool get hasCards => _cards.isNotEmpty && _currentIndex < _cards.length;
  List<String>? get selectedGenres => _genres;

  /// 🔄 Load discovery cards
  Future<void> loadCards({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _page = 1;
      _hasMore = true;
      _cards = [];
      _currentIndex = 0;
      _swipeHistory.clear();
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _status = _cards.isEmpty ? DiscoveryStatus.loading : _status;
    notifyListeners();

    try {
      final response = await _swipeService.getDiscoveryProfiles(
        page: _page,
        limit: _limit,
        latitude: _latitude,
        longitude: _longitude,
        radiusMiles: _radiusMiles,
        genres: _genres,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
      );

      if (refresh) {
        _cards = response.profiles;
      } else {
        _cards.addAll(response.profiles);
      }

      _hasMore = response.hasMore;
      _page++;

      _status = _cards.isEmpty ? DiscoveryStatus.empty : DiscoveryStatus.loaded;
    } catch (e) {
      debugPrint('Load cards error: $e');
      _errorMessage = 'Failed to load profiles';
      _status = DiscoveryStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 👍 Swipe right (like)
  Future<bool> like() async {
    if (!hasCards) return false;

    final card = currentCard!;
    final targetType = card.isArtist ? 'artist' : 'venue';
    _moveToNext();

    try {
      final response = await _swipeService.like(
        card.id,
        targetType: targetType,
      );

      // Track swipeId for undo functionality (with synchronization)
      if (response.swipeId != null) {
        _addSwipeToHistory(response.swipeId!);
      }

      if (response.isMatch) {
        _lastMatch = response.match;
        notifyListeners();
        return true;
      }

      _preloadMoreIfNeeded();
      return false;
    } catch (e) {
      debugPrint('Like error: $e');
      return false;
    }
  }

  /// 👎 Swipe left (pass)
  Future<void> pass() async {
    if (!hasCards) return;

    final card = currentCard!;
    final targetType = card.isArtist ? 'artist' : 'venue';
    _moveToNext();

    try {
      final response = await _swipeService.pass(
        card.id,
        targetType: targetType,
      );

      // Track swipeId for undo functionality (with synchronization)
      if (response.swipeId != null) {
        _addSwipeToHistory(response.swipeId!);
      }

      _preloadMoreIfNeeded();
    } catch (e) {
      debugPrint('Pass error: $e');
    }
  }

  /// ⭐ Super like
  Future<bool> superLike() async {
    if (!hasCards) return false;

    final card = currentCard!;
    final targetType = card.isArtist ? 'artist' : 'venue';
    _moveToNext();

    try {
      final response = await _swipeService.superLike(
        card.id,
        targetType: targetType,
      );

      // Track swipeId for undo functionality (with synchronization)
      if (response.swipeId != null) {
        _addSwipeToHistory(response.swipeId!);
      }

      if (response.isMatch) {
        _lastMatch = response.match;
        notifyListeners();
        return true;
      }

      _preloadMoreIfNeeded();
      return false;
    } catch (e) {
      debugPrint('Super like error: $e');
      return false;
    }
  }

  /// ↩️ Undo last swipe
  Future<bool> undo() async {
    if (_currentIndex <= 0 || _swipeHistory.isEmpty) return false;

    final lastSwipeId = _swipeHistory.first;

    try {
      final success = await _swipeService.undoLastSwipe(lastSwipeId);
      if (success) {
        _removeSwipeFromHistory();
        _currentIndex = (_currentIndex - 1).clamp(0, _cards.length - 1);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Undo error: $e');
      return false;
    }
  }

  /// 📍 Set location filter
  void setLocationFilter({
    required double latitude,
    required double longitude,
    int? radiusMiles,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    _radiusMiles = radiusMiles;
    loadCards(refresh: true);
  }

  /// 🎵 Set genre filter
  void setGenreFilter(List<String> genres) {
    _genres = List<String>.from(genres);
    loadCards(refresh: true);
  }

  /// 💵 Set price range filter
  void setPriceRangeFilter({double? minPrice, double? maxPrice}) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    loadCards(refresh: true);
  }

  /// ⭐ Set minimum rating filter
  void setMinRatingFilter(double? minRating) {
    _minRating = minRating;
    loadCards(refresh: true);
  }

  /// 💵⭐ Set price and rating filters together
  void setPriceAndRatingFilters({
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minRating = minRating;
    loadCards(refresh: true);
  }

  /// 📍 Clear location filter
  void clearLocationFilter() {
    _latitude = null;
    _longitude = null;
    _radiusMiles = null;
    loadCards(refresh: true);
  }

  /// 🧹 Clear filters
  void clearFilters() {
    _latitude = null;
    _longitude = null;
    _radiusMiles = null;
    _genres = null;
    _minPrice = null;
    _maxPrice = null;
    _minRating = null;
    loadCards(refresh: true);
  }

  /// ✨ Clear last match (after showing match animation)
  void clearLastMatch() {
    _lastMatch = null;
    notifyListeners();
  }

  // Internal methods - thread-safe swipe history management
  void _addSwipeToHistory(String swipeId) {
    _swipeHistory.insert(0, swipeId);
    // Trim to max size
    while (_swipeHistory.length > _maxSwipeHistorySize) {
      _swipeHistory.removeLast();
    }
  }

  void _removeSwipeFromHistory() {
    if (_swipeHistory.isNotEmpty) {
      _swipeHistory.removeAt(0);
    }
  }

  void _moveToNext() {
    _currentIndex++;
    _prefetchUpcomingImages();
    notifyListeners();
  }

  void _preloadMoreIfNeeded() {
    // Load more when 5 cards remaining
    if (remainingCards < 5 && _hasMore && !_isLoading) {
      loadCards();
    }
  }

  /// Prefetch images for next 3 discovery cards for smooth UX
  void _prefetchUpcomingImages() {
    const prefetchCount = 3;
    for (int i = 0; i < prefetchCount; i++) {
      final idx = _currentIndex + 1 + i;
      if (idx < _cards.length) {
        final card = _cards[idx];
        // Prefetch primary photo
        if (card.primaryPhotoUrl.isNotEmpty) {
          _prefetchImage(card.primaryPhotoUrl);
        }
        // Prefetch first gallery image
        if (card.galleryUrls.isNotEmpty) {
          _prefetchImage(card.galleryUrls.first);
        }
      }
    }
  }

  /// Prefetch a single image URL into the cache
  void _prefetchImage(String url) {
    try {
      CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
    } catch (_) {
      // Silently ignore prefetch errors
    }
  }
}
