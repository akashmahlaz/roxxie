/// 🎯 GIGMATCH Discovery Provider
/// State management for swiping and discovery
library;

import 'package:flutter/foundation.dart';
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

  // Pagination
  int _page = 1;
  bool _hasMore = true;
  final int _limit = 20;

  // Filters
  double? _latitude;
  double? _longitude;
  int? _maxDistance;
  List<String>? _genres;

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
        maxDistance: _maxDistance,
        genres: _genres,
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
    _moveToNext();

    try {
      final response = await _swipeService.like(card.id);

      if (response.isMatch) {
        _lastMatch = response.match;
        notifyListeners();
        return true; // Indicates a match!
      }

      _preloadMoreIfNeeded();
      return false;
    } catch (e) {
      debugPrint('Like error: $e');
      // Put card back on error (optional)
      return false;
    }
  }

  /// 👎 Swipe left (pass)
  Future<void> pass() async {
    if (!hasCards) return;

    final card = currentCard!;
    _moveToNext();

    try {
      await _swipeService.pass(card.id);
      _preloadMoreIfNeeded();
    } catch (e) {
      debugPrint('Pass error: $e');
    }
  }

  /// ⭐ Super like
  Future<bool> superLike() async {
    if (!hasCards) return false;

    final card = currentCard!;
    _moveToNext();

    try {
      final response = await _swipeService.superLike(card.id);

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
    if (_currentIndex == 0) return false;

    try {
      final success = await _swipeService.undoLastSwipe();
      if (success) {
        _currentIndex--;
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
    int? maxDistance,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    _maxDistance = maxDistance;
    loadCards(refresh: true);
  }

  /// 🎵 Set genre filter
  void setGenreFilter(List<String> genres) {
    _genres = List<String>.from(genres);
    loadCards(refresh: true);
  }

  /// 🧹 Clear filters
  void clearFilters() {
    _latitude = null;
    _longitude = null;
    _maxDistance = null;
    _genres = null;
    loadCards(refresh: true);
  }

  /// ✨ Clear last match (after showing match animation)
  void clearLastMatch() {
    _lastMatch = null;
    notifyListeners();
  }

  // Internal methods
  void _moveToNext() {
    _currentIndex++;
    notifyListeners();
  }

  void _preloadMoreIfNeeded() {
    // Load more when 5 cards remaining
    if (remainingCards < 5 && _hasMore && !_isLoading) {
      loadCards();
    }
  }
}
