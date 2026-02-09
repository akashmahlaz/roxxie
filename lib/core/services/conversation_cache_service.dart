/// 💕 GIGMATCH Conversation Cache Service
/// Local storage for conversation/match list
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/match_models.dart';
import 'hive_cache_service.dart';

/// ConversationCacheService handles caching of conversations locally
class ConversationCacheService {
  static const String boxName = CacheBoxes.conversations;

  /// Get the Hive box for conversations
  Box<String> get _box => Hive.box<String>(boxName);

  /// Get cached conversations
  Future<List<Match>> getCachedConversations() async {
    try {
      final data = _box.get('all_conversations');
      if (data == null) return [];

      final jsonList = jsonDecode(data) as List<dynamic>;
      return jsonList
          .map((json) => Match.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) {
          // Sort by last message time, then by match time
          if (a.lastMessageAt != null && b.lastMessageAt != null) {
            return b.lastMessageAt!.compareTo(a.lastMessageAt!);
          }
          if (a.lastMessageAt != null) return -1;
          if (b.lastMessageAt != null) return 1;
          return b.matchedAt.compareTo(a.matchedAt);
        });
    } catch (e) {
      debugPrint('Error getting cached conversations: $e');
      return [];
    }
  }

  /// Cache conversations list
  Future<void> cacheConversations(List<Match> conversations) async {
    try {
      final jsonList = conversations.map((m) => m.toJson()).toList();
      await _box.put('all_conversations', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error caching conversations: $e');
    }
  }

  /// Update a single conversation
  Future<void> updateConversation(Match match) async {
    try {
      final cached = await getCachedConversations();
      final index = cached.indexWhere((m) => m.id == match.id);

      if (index != -1) {
        cached[index] = match;
      } else {
        cached.insert(0, match);
      }

      await cacheConversations(cached);
    } catch (e) {
      debugPrint('Error updating conversation: $e');
    }
  }

  /// Remove a conversation from cache
  Future<void> removeConversation(String matchId) async {
    try {
      final cached = await getCachedConversations();
      cached.removeWhere((m) => m.id == matchId);
      await cacheConversations(cached);
    } catch (e) {
      debugPrint('Error removing conversation: $e');
    }
  }

  /// Get a specific conversation by ID
  Future<Match?> getConversation(String matchId) async {
    try {
      final cached = await getCachedConversations();
      return cached.firstWhere((m) => m.id == matchId);
    } catch (e) {
      return null;
    }
  }

  /// Get total unread count across all conversations
  Future<int> getTotalUnreadCount() async {
    try {
      final cached = await getCachedConversations();
      return cached.fold<int>(0, (sum, m) => sum + m.unreadCount);
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get conversations with unread messages
  Future<List<Match>> getUnreadConversations() async {
    try {
      final cached = await getCachedConversations();
      return cached.where((m) => m.unreadCount > 0).toList();
    } catch (e) {
      debugPrint('Error getting unread conversations: $e');
      return [];
    }
  }

  /// Search conversations by name
  Future<List<Match>> searchConversations(String query) async {
    try {
      final cached = await getCachedConversations();
      final lowerQuery = query.toLowerCase();
      return cached.where((m) {
        final name = m.artist?.stageName.toLowerCase() ?? '';
        final venueName = m.venue?.name.toLowerCase() ?? '';
        return name.contains(lowerQuery) || venueName.contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching conversations: $e');
      return [];
    }
  }

  /// Get archived conversations
  Future<List<Match>> getArchivedConversations() async {
    try {
      final cached = await getCachedConversations();
      return cached
          .where((m) => m.status == MatchStatus.archived)
          .toList();
    } catch (e) {
      debugPrint('Error getting archived conversations: $e');
      return [];
    }
  }

  /// Archive a conversation in cache
  Future<void> archiveConversation(String matchId) async {
    try {
      final cached = await getCachedConversations();
      final index = cached.indexWhere((m) => m.id == matchId);

      if (index != -1) {
        final oldMatch = cached[index];
        cached[index] = Match(
          id: oldMatch.id,
          artistId: oldMatch.artistId,
          venueId: oldMatch.venueId,
          artist: oldMatch.artist,
          venue: oldMatch.venue,
          status: MatchStatus.archived,
          matchedAt: oldMatch.matchedAt,
          lastMessageAt: oldMatch.lastMessageAt,
          lastMessagePreview: oldMatch.lastMessagePreview,
          unreadCount: oldMatch.unreadCount,
          isViewedByArtist: oldMatch.isViewedByArtist,
          isViewedByVenue: oldMatch.isViewedByVenue,
        );
        await cacheConversations(cached);
      }
    } catch (e) {
      debugPrint('Error archiving conversation: $e');
    }
  }

  /// Unarchive a conversation in cache
  Future<void> unarchiveConversation(String matchId) async {
    try {
      final cached = await getCachedConversations();
      final index = cached.indexWhere((m) => m.id == matchId);

      if (index != -1) {
        final oldMatch = cached[index];
        cached[index] = Match(
          id: oldMatch.id,
          artistId: oldMatch.artistId,
          venueId: oldMatch.venueId,
          artist: oldMatch.artist,
          venue: oldMatch.venue,
          status: MatchStatus.active,
          matchedAt: oldMatch.matchedAt,
          lastMessageAt: oldMatch.lastMessageAt,
          lastMessagePreview: oldMatch.lastMessagePreview,
          unreadCount: oldMatch.unreadCount,
          isViewedByArtist: oldMatch.isViewedByArtist,
          isViewedByVenue: oldMatch.isViewedByVenue,
        );
        await cacheConversations(cached);
      }
    } catch (e) {
      debugPrint('Error unarchiving conversation: $e');
    }
  }

  /// Check if there are cached conversations
  Future<bool> hasCachedConversations() async {
    try {
      final data = _box.get('all_conversations');
      return data != null && data.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clear all conversation cache
  Future<void> clearAll() async {
    await _box.clear();
  }
}
