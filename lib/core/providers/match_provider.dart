/// 💕 GIGMATCH Match Provider
/// State management for matches
library;

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

enum MatchListStatus { initial, loading, loaded, error }

enum MatchFilterType { all, unread, archived }

class MatchProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  final SwipeService _swipeService = SwipeService();

  MatchListStatus _status = MatchListStatus.initial;
  List<Match> _matches = [];
  int _unreadCount = 0;
  String? _errorMessage;
  bool _isLoading = false;

  // Who Liked Me state
  List<DiscoveryCard> _whoLikedMe = [];
  int _whoLikedMeCount = 0;
  bool _whoLikedMeLoading = false;
  bool _isPremiumFeature = false;

  // Filter state
  MatchFilterType _filterType = MatchFilterType.all;
  String _searchQuery = '';

  // Pagination
  int _page = 1;
  bool _hasMore = true;
  final int _limit = 20;

  // Getters
  MatchListStatus get status => _status;
  List<Match> get matches => _matches;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // Who Liked Me getters
  List<DiscoveryCard> get whoLikedMe => _whoLikedMe;
  int get whoLikedMeCount => _whoLikedMeCount;
  bool get whoLikedMeLoading => _whoLikedMeLoading;
  bool get isPremiumFeature => _isPremiumFeature;

  // Filter getters
  MatchFilterType get filterType => _filterType;
  String get searchQuery => _searchQuery;

  // Filtered lists
  List<Match> get activeMatches =>
      _matches.where((m) => m.status == MatchStatus.active).toList();
  List<Match> get archivedMatches =>
      _matches.where((m) => m.status == MatchStatus.archived).toList();
  List<Match> get newMatches =>
      _matches.where((m) => m.lastMessageAt == null).toList();
  List<Match> get conversationMatches =>
      _matches.where((m) => m.lastMessageAt != null).toList();

  /// 🔎 Get filtered matches based on current filter
  List<Match> get filteredMatches {
    List<Match> result = _matches;

    // Apply filter type
    switch (_filterType) {
      case MatchFilterType.all:
        result = result.where((m) => m.status == MatchStatus.active).toList();
        break;
      case MatchFilterType.unread:
        result = result.where((m) => m.status == MatchStatus.active).toList();
        // TODO: Add unread flag to Match model when available from backend
        break;
      case MatchFilterType.archived:
        result = result.where((m) => m.status == MatchStatus.archived).toList();
        break;
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((m) {
        // Search in both artist and venue names
        final artistName = (m.artist?.stageName ?? '').toLowerCase();
        final venueName = (m.venue?.name ?? '').toLowerCase();
        return artistName.contains(query) || venueName.contains(query);
      }).toList();
    }

    return result;
  }

  /// 🔎 Filtered new matches (no conversation yet)
  List<Match> get filteredNewMatches {
    return filteredMatches.where((m) => m.lastMessageAt == null).toList();
  }

  /// 💬 Filtered conversation matches (has messages)
  List<Match> get filteredConversationMatches {
    return filteredMatches.where((m) => m.lastMessageAt != null).toList();
  }

  /// 🎛️ Set filter type
  void setFilterType(MatchFilterType type) {
    _filterType = type;
    notifyListeners();
  }

  /// 🔍 Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 🔄 Load matches
  Future<void> loadMatches({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _page = 1;
      _hasMore = true;
      _matches = [];
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _status = _matches.isEmpty ? MatchListStatus.loading : _status;
    notifyListeners();

    try {
      final response = await _matchService.getMatches(
        page: _page,
        limit: _limit,
      );

      if (refresh) {
        _matches = response.matches;
      } else {
        _matches.addAll(response.matches);
      }

      _hasMore = response.hasMore;
      _page++;
      _status = MatchListStatus.loaded;
      _errorMessage = null;

      // Also fetch unread count
      await refreshUnreadCount();
    } catch (e) {
      debugPrint('Load matches error: $e');
      _errorMessage = 'Failed to load matches';
      _status = MatchListStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 💕 Load who liked me (premium feature)
  Future<void> loadWhoLikedMe() async {
    if (_whoLikedMeLoading) return;

    _whoLikedMeLoading = true;
    notifyListeners();

    try {
      final response = await _swipeService.getWhoLikedMe();
      _whoLikedMe = response.profiles;
      _whoLikedMeCount = response.count;
      _isPremiumFeature = response.isPremiumFeature;
    } catch (e) {
      debugPrint('Load who liked me error: $e');
      // Non-critical, don't set error state
    } finally {
      _whoLikedMeLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([loadMatches(refresh: true), loadWhoLikedMe()]);
  }

  /// 🔢 Refresh unread count
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _matchService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Get unread count error: $e');
    }
  }

  /// 👁️ Mark match as viewed
  Future<void> markAsViewed(String matchId) async {
    try {
      await _matchService.markAsViewed(matchId);

      // Update local state
      final index = _matches.indexWhere((m) => m.id == matchId);
      if (index != -1) {
        // The match would be updated server-side, we could refresh or update locally
      }
    } catch (e) {
      debugPrint('Mark as viewed error: $e');
    }
  }

  /// 🗑️ Archive match
  Future<bool> archiveMatch(String matchId) async {
    try {
      await _matchService.archiveMatch(matchId);

      // Update local state
      final index = _matches.indexWhere((m) => m.id == matchId);
      if (index != -1) {
        _matches.removeAt(index);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Archive match error: $e');
      return false;
    }
  }

  /// � Unarchive match
  Future<bool> unarchiveMatch(String matchId) async {
    try {
      await _matchService.unarchiveMatch(matchId);
      // Reload to get the match back
      await loadMatches(refresh: true);
      return true;
    } catch (e) {
      debugPrint('Unarchive match error: $e');
      return false;
    }
  }

  /// 💔 Unmatch (delete conversation)
  Future<bool> unmatch(String matchId) async {
    try {
      await _matchService.unmatch(matchId);

      // Remove from list
      _matches.removeWhere((m) => m.id == matchId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Unmatch error: $e');
      return false;
    }
  }

  /// �🚫 Block match
  Future<bool> blockMatch(String matchId) async {
    try {
      await _matchService.blockMatch(matchId);

      // Remove from list
      _matches.removeWhere((m) => m.id == matchId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Block match error: $e');
      return false;
    }
  }

  /// 🆕 Add new match (from WebSocket event)
  void addNewMatch(Match match) {
    _matches.insert(0, match);
    _unreadCount++;
    notifyListeners();
  }

  /// 🔄 Update match (e.g., last message)
  void updateMatch(Match updatedMatch) {
    final index = _matches.indexWhere((m) => m.id == updatedMatch.id);
    if (index != -1) {
      _matches[index] = updatedMatch;
      notifyListeners();
    }
  }

  /// 🔍 Get match by ID
  Match? getMatchById(String id) {
    try {
      return _matches.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
}
