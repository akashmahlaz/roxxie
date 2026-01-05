/// 💕 GIGMATCH Match Provider
/// State management for matches
library;

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

enum MatchListStatus { initial, loading, loaded, error }

class MatchProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();

  MatchListStatus _status = MatchListStatus.initial;
  List<Match> _matches = [];
  int _unreadCount = 0;
  String? _errorMessage;
  bool _isLoading = false;

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

  // Filtered lists
  List<Match> get activeMatches =>
      _matches.where((m) => m.status == MatchStatus.active).toList();
  List<Match> get archivedMatches =>
      _matches.where((m) => m.status == MatchStatus.archived).toList();
  List<Match> get newMatches =>
      _matches.where((m) => m.lastMessageAt == null).toList();
  List<Match> get conversationMatches =>
      _matches.where((m) => m.lastMessageAt != null).toList();

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

  /// 🚫 Block match
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
