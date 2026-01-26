///  GIGMATCH Explore Provider
/// State management for search and explore functionality
library;

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

enum ExploreStatus { initial, loading, loaded, error }

/// Search result types
enum SearchResultType { artist, venue, all }

/// Unified search result
class ExploreResult {
  final String id;
  final String name;
  final String type;
  final String? location;
  final double? rating;
  final int? reviews;
  final String? photo;
  final List<String> genres;
  final bool isArtist;

  ExploreResult({
    required this.id,
    required this.name,
    required this.type,
    this.location,
    this.rating,
    this.reviews,
    this.photo,
    this.genres = const [],
    required this.isArtist,
  });

  factory ExploreResult.fromArtist(Artist artist) {
    return ExploreResult(
      id: artist.id,
      name: artist.displayName,
      type: artist.artistType.value,
      location: artist.location?.city,
      rating: artist.rating,
      reviews: artist.totalReviews,
      photo: artist.profilePhoto,
      genres: artist.genres,
      isArtist: true,
    );
  }

  factory ExploreResult.fromVenue(Venue venue) {
    return ExploreResult(
      id: venue.id,
      name: venue.name,
      type: venue.venueType ?? 'Venue',
      location: venue.location?.city,
      rating: venue.rating,
      reviews: venue.reviewCount,
      photo: venue.profilePhotoUrl,
      genres: venue.gigPreferences?.preferredGenres ?? [],
      isArtist: false,
    );
  }
}

/// Trending item from API or local analytics
class TrendingResult {
  final int rank;
  final String id;
  final String name;
  final String type;
  final String? photo;
  final double? rating;
  final bool isHot;
  final bool isArtist;

  TrendingResult({
    required this.rank,
    required this.id,
    required this.name,
    required this.type,
    this.photo,
    this.rating,
    this.isHot = false,
    required this.isArtist,
  });
}

/// Category for browsing
class ExploreCategory {
  final String name;
  final String genreId;
  final int count;

  ExploreCategory({
    required this.name,
    required this.genreId,
    this.count = 0,
  });
}

class ExploreProvider extends ChangeNotifier {
  final ArtistService _artistService = ArtistService();
  final VenueService _venueService = VenueService();

  ExploreStatus _status = ExploreStatus.initial;
  List<ExploreResult> _results = [];
  List<TrendingResult> _trending = [];
  List<String> _recentSearches = [];
  final List<String> _suggestions = [];
  String? _errorMessage;
  bool _isLoading = false;

  // Current search state
  String _query = '';
  SearchResultType _searchType = SearchResultType.all;
  String? _selectedGenre;

  // Pagination
  int _page = 1;
  bool _hasMore = true;
  final int _limit = 20;

  // Getters
  ExploreStatus get status => _status;
  List<ExploreResult> get results => _results;
  List<TrendingResult> get trending => _trending;
  List<String> get recentSearches => _recentSearches;
  List<String> get suggestions => _suggestions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String get query => _query;
  SearchResultType get searchType => _searchType;
  String? get selectedGenre => _selectedGenre;
  bool get hasMore => _hasMore;

  /// 🔍 Search artists and venues
  Future<void> search(String query, {bool refresh = true}) async {
    if (query.trim().isEmpty) {
      _results = [];
      _status = ExploreStatus.initial;
      notifyListeners();
      return;
    }

    if (refresh) {
      _page = 1;
      _hasMore = true;
      _results = [];
    }

    if (!_hasMore && !refresh) return;

    _query = query;
    _isLoading = true;
    _status = _results.isEmpty ? ExploreStatus.loading : _status;
    notifyListeners();

    try {
      List<ExploreResult> newResults = [];

      // Search based on type
      if (_searchType == SearchResultType.all ||
          _searchType == SearchResultType.artist) {
        final artists = await _searchArtists(query);
        newResults.addAll(artists.map(ExploreResult.fromArtist));
      }

      if (_searchType == SearchResultType.all ||
          _searchType == SearchResultType.venue) {
        final venues = await _searchVenues(query);
        newResults.addAll(venues.map(ExploreResult.fromVenue));
      }

      // Sort by rating
      newResults.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      if (refresh) {
        _results = newResults;
      } else {
        _results.addAll(newResults);
      }

      _hasMore = newResults.length >= _limit;
      _page++;
      _status = ExploreStatus.loaded;
      _errorMessage = null;

      // Add to recent searches
      _addToRecentSearches(query);
    } catch (e) {
      debugPrint('Search error: $e');
      _errorMessage = 'Failed to search. Please try again.';
      _status = ExploreStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Artist>> _searchArtists(String query) async {
    // Create search params - using genres filter if query matches a genre
    final params = ArtistSearchParams(
      page: _page,
      limit: _limit,
      genres: _selectedGenre != null ? [_selectedGenre!] : null,
    );

    return await _artistService.searchArtists(params);
  }

  Future<List<Venue>> _searchVenues(String query) async {
    final params = VenueSearchParams(
      page: _page,
      limit: _limit,
      genres: _selectedGenre != null ? [_selectedGenre!] : null,
    );

    return await _venueService.searchVenues(params);
  }

  /// 🔥 Load trending (top rated artists/venues)
  Future<void> loadTrending() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get top rated artists
      final artists = await _artistService.searchArtists(
        ArtistSearchParams(page: 1, limit: 5),
      );

      // Get top rated venues
      final venues = await _venueService.searchVenues(
        VenueSearchParams(page: 1, limit: 5),
      );

      // Combine and rank
      List<TrendingResult> trendingList = [];
      int rank = 1;

      // Add artists
      for (final artist in artists) {
        trendingList.add(TrendingResult(
          rank: rank++,
          id: artist.id,
          name: artist.displayName,
          type: artist.artistType.value,
          photo: artist.profilePhoto,
          rating: artist.rating,
          isHot: artist.rating >= 4.8,
          isArtist: true,
        ));
      }

      // Add venues
      for (final venue in venues) {
        trendingList.add(TrendingResult(
          rank: rank++,
          id: venue.id,
          name: venue.name,
          type: venue.venueType ?? 'Venue',
          photo: venue.profilePhotoUrl,
          rating: venue.rating,
          isHot: (venue.rating ?? 0) >= 4.8,
          isArtist: false,
        ));
      }

      // Sort by rating and take top 10
      trendingList.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      _trending = trendingList.take(10).toList();

      // Re-rank after sorting
      for (int i = 0; i < _trending.length; i++) {
        _trending[i] = TrendingResult(
          rank: i + 1,
          id: _trending[i].id,
          name: _trending[i].name,
          type: _trending[i].type,
          photo: _trending[i].photo,
          rating: _trending[i].rating,
          isHot: _trending[i].isHot,
          isArtist: _trending[i].isArtist,
        );
      }
    } catch (e) {
      debugPrint('Load trending error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔍 Search by genre/category
  Future<void> searchByGenre(String genre) async {
    _selectedGenre = genre;
    await search(genre, refresh: true);
  }

  /// 🎛️ Set search type filter
  void setSearchType(SearchResultType type) {
    _searchType = type;
    if (_query.isNotEmpty) {
      search(_query, refresh: true);
    }
    notifyListeners();
  }

  /// Clear genre filter
  void clearGenreFilter() {
    _selectedGenre = null;
    notifyListeners();
  }

  /// 📝 Add to recent searches
  void _addToRecentSearches(String query) {
    if (query.trim().isEmpty) return;

    _recentSearches.remove(query);
    _recentSearches.insert(0, query);

    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
  }

  /// 🗑️ Remove from recent searches
  void removeRecentSearch(String query) {
    _recentSearches.remove(query);
    notifyListeners();
  }

  /// 🧹 Clear all recent searches
  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  /// 🔄 Clear search results
  void clearResults() {
    _results = [];
    _query = '';
    _status = ExploreStatus.initial;
    notifyListeners();
  }

  /// 📍 Load more results
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _query.isEmpty) return;
    await search(_query, refresh: false);
  }
}
