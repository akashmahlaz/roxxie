/// 🎯 GIGMATCH Centralized Chat Manager
///
/// Single entry point for opening ANY chat conversation.
/// All screens use this instead of constructing ChatScreenV2 directly.
///
/// Features:
/// - Resolves matchId ↔ participantId in all directions
/// - Caches resolved data to avoid repeat API calls
/// - Handles getOrCreateConversation for profile→chat flow
/// - Provides participant info from cache/backend
/// - Single data class (ChatTarget) for all navigation
///
/// Usage:
///   final target = await ChatManager.instance.resolveChat(
///     matchId: matchId,             // from messages/notifications
///     participantId: artistId,      // from profile preview
///     participantType: 'artist',
///     participantName: name,
///     participantPhoto: photo,
///   );
///   if (target != null) {
///     Navigator.push(context, MaterialPageRoute(
///       builder: (_) => ChatScreenV2.fromTarget(target),
///     ));
///   }
library;

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../exceptions.dart';
import '../models/models.dart';
import 'chat_service.dart';
import 'swipe_service.dart';

/// Immutable data class representing a fully-resolved chat target.
/// Contains everything ChatScreenV2 needs to render immediately.
class ChatTarget {
  final String matchId;
  final String? participantId;
  final String participantName;
  final String? participantPhoto;
  final bool isParticipantArtist;
  final bool isMuted;

  const ChatTarget({
    required this.matchId,
    this.participantId,
    required this.participantName,
    this.participantPhoto,
    required this.isParticipantArtist,
    this.isMuted = false,
  });

  @override
  String toString() =>
      'ChatTarget(matchId=$matchId, name=$participantName, artist=$isParticipantArtist)';
}

/// Error thrown when a conversation is blocked.
/// Callers can catch this specifically to show user-friendly messages.
class ChatBlockedError implements Exception {
  final String message;
  ChatBlockedError(this.message);

  @override
  String toString() => 'ChatBlockedError: $message';
}

/// Centralized chat resolution & navigation helper.
///
/// Resolves any combination of matchId / participantId into a [ChatTarget]
/// that ChatScreenV2 can render without additional API calls.
class ChatManager {
  ChatManager._();
  static final ChatManager instance = ChatManager._();

  // Cache: matchId → ChatTarget  (avoid re-fetching within session)
  final Map<String, ChatTarget> _cache = {};

  /// Clear cache (e.g. on logout)
  void clearCache() {
    _cache.clear();
    debugPrint('🎯 [ChatManager] Cache cleared');
  }

  /// Resolve a chat target from whatever data the caller has.
  ///
  /// Accepts any combination:
  /// - [matchId] only  → fetches match details to get participant info
  /// - [participantId] only  → calls getOrCreateConversation
  /// - Both → uses what's available, fills in the rest
  ///
  /// Returns null only if resolution completely fails.
  Future<ChatTarget?> resolveChat({
    String? matchId,
    String? participantId,
    String? participantType,
    String? participantName,
    String? participantPhoto,
    bool? isParticipantArtist,
    bool? isMuted,
    // Optional: pass cached Match object to avoid API calls
    Match? cachedMatch,
    // Optional: caller's auth context
    bool? isCurrentUserArtist,
  }) async {
    debugPrint(
      '🎯 [ChatManager] resolveChat: matchId=$matchId, '
      'participantId=$participantId, name=$participantName',
    );

    // Fast path: if we have a cached target with full data, return it
    if (matchId != null && _cache.containsKey(matchId)) {
      final cached = _cache[matchId]!;
      debugPrint('🎯 [ChatManager] Cache hit for matchId=$matchId');
      // Update with any fresher data the caller has
      final updated = ChatTarget(
        matchId: cached.matchId,
        participantId: participantId ?? cached.participantId,
        participantName: participantName ?? cached.participantName,
        participantPhoto: participantPhoto ?? cached.participantPhoto,
        isParticipantArtist: isParticipantArtist ?? cached.isParticipantArtist,
        isMuted: isMuted ?? cached.isMuted,
      );
      _cache[matchId] = updated;
      return updated;
    }

    try {
      // ─── CASE 1: participantId provided, no matchId ───
      // (Profile preview → Chat)
      if (matchId == null && participantId != null) {
        return await _resolveFromParticipant(
          participantId: participantId,
          participantType: participantType ?? (isParticipantArtist == true ? 'artist' : 'venue'),
          participantName: participantName,
          participantPhoto: participantPhoto,
          isParticipantArtist: isParticipantArtist ?? true,
          isMuted: isMuted,
        );
      }

      // ─── CASE 2: matchId provided ───
      // (Messages screen, notifications, deep links)
      if (matchId != null) {
        return await _resolveFromMatch(
          matchId: matchId,
          participantId: participantId,
          participantName: participantName,
          participantPhoto: participantPhoto,
          isParticipantArtist: isParticipantArtist,
          isMuted: isMuted,
          cachedMatch: cachedMatch,
          isCurrentUserArtist: isCurrentUserArtist,
        );
      }

      debugPrint('❌ [ChatManager] No matchId or participantId provided');
      return null;
    } catch (e) {
      debugPrint('❌ [ChatManager] resolveChat failed: $e');

      // If we have enough data to show a partial UI, return it
      if (matchId != null && participantName != null) {
        final fallback = ChatTarget(
          matchId: matchId,
          participantId: participantId,
          participantName: participantName,
          participantPhoto: participantPhoto,
          isParticipantArtist: isParticipantArtist ?? true,
          isMuted: isMuted ?? false,
        );
        _cache[matchId] = fallback;
        return fallback;
      }

      return null;
    }
  }

  /// Resolve from participantId → getOrCreateConversation → matchId
  Future<ChatTarget?> _resolveFromParticipant({
    required String participantId,
    required String participantType,
    String? participantName,
    String? participantPhoto,
    required bool isParticipantArtist,
    bool? isMuted,
  }) async {
    debugPrint('🎯 [ChatManager] Resolving from participantId=$participantId');

    try {
      final chatService = ChatService();
      final conversation = await chatService.getOrCreateConversation(
        participantId: participantId,
        participantType: participantType,
      );

      final target = ChatTarget(
        matchId: conversation.id,
        participantId: participantId,
        participantName: participantName ?? conversation.participantName,
        participantPhoto: participantPhoto ?? conversation.participantPhoto,
        isParticipantArtist: isParticipantArtist,
        isMuted: isMuted ?? conversation.isMuted,
      );

      _cache[conversation.id] = target;
      debugPrint('🎯 [ChatManager] Resolved: matchId=${conversation.id}, name=${target.participantName}');
      return target;
    } on DioException catch (e) {
      // Handle blocked error — provide clear message to caller
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message']?.toString() ?? '';

      if (statusCode == 400 && message.toLowerCase().contains('blocked')) {
        debugPrint('🚫 [ChatManager] Conversation blocked: $message');
        throw ChatBlockedError(message);
      }
      rethrow;
    } on ChatServiceError catch (e) {
      // Handle blocked error from ChatService wrapper
      if (e.toString().toLowerCase().contains('blocked')) {
        debugPrint('🚫 [ChatManager] Chat service blocked error: $e');
        throw ChatBlockedError(e.toString());
      }
      rethrow;
    }
  }

  /// Resolve from matchId → fetch match details → participant info
  Future<ChatTarget?> _resolveFromMatch({
    required String matchId,
    String? participantId,
    String? participantName,
    String? participantPhoto,
    bool? isParticipantArtist,
    bool? isMuted,
    Match? cachedMatch,
    bool? isCurrentUserArtist,
  }) async {
    debugPrint('🎯 [ChatManager] Resolving from matchId=$matchId');

    // If caller already has all the info, just build target
    if (participantName != null && participantName.isNotEmpty) {
      final target = ChatTarget(
        matchId: matchId,
        participantId: participantId,
        participantName: participantName,
        participantPhoto: participantPhoto,
        isParticipantArtist: isParticipantArtist ?? true,
        isMuted: isMuted ?? false,
      );
      _cache[matchId] = target;
      return target;
    }

    // Try to extract from a cached Match object
    if (cachedMatch != null) {
      final target = _extractFromMatch(
        cachedMatch,
        matchId: matchId,
        isCurrentUserArtist: isCurrentUserArtist,
      );
      if (target != null) {
        _cache[matchId] = target;
        return target;
      }
    }

    // Fetch match details from backend
    try {
      final matchService = MatchService();
      final match = await matchService.getMatchById(matchId);
      final target = _extractFromMatch(
        match,
        matchId: matchId,
        isCurrentUserArtist: isCurrentUserArtist,
      );
      if (target != null) {
        _cache[matchId] = target;
        return target;
      }
    } catch (e) {
      debugPrint('⚠️ [ChatManager] Failed to fetch match $matchId: $e');
    }

    // Last resort: return minimal target so chat can still try to load
    final target = ChatTarget(
      matchId: matchId,
      participantId: participantId,
      participantName: participantName ?? 'Chat',
      participantPhoto: participantPhoto,
      isParticipantArtist: isParticipantArtist ?? true,
      isMuted: isMuted ?? false,
    );
    _cache[matchId] = target;
    return target;
  }

  /// Extract participant info from a Match object
  ChatTarget? _extractFromMatch(
    Match match, {
    required String matchId,
    bool? isCurrentUserArtist,
  }) {
    // Use otherUser fields (new enriched backend format)
    String? name = match.otherUserName;
    String? photo = match.otherUserPhoto;
    String? profileId = match.otherUserProfileId;
    bool isArtist = match.otherUserType == 'artist';

    // Fallback to artist/venue objects
    if (name == null || name.isEmpty) {
      if (isCurrentUserArtist == true) {
        name = match.venue?.name;
        photo ??= match.venue?.profilePhotoUrl;
        profileId ??= match.venueId;
        isArtist = false;
      } else {
        name = match.artist?.stageName;
        photo ??= match.artist?.profilePhoto;
        profileId ??= match.artistId;
        isArtist = true;
      }
    }

    if (name == null || name.isEmpty) {
      return null;
    }

    return ChatTarget(
      matchId: matchId,
      participantId: profileId,
      participantName: name,
      participantPhoto: photo,
      isParticipantArtist: isArtist,
      isMuted: match.isMuted,
    );
  }

  /// Pre-populate cache from a list of matches (call after loading matches)
  void cacheFromMatches(List<Match> matches, {bool? isCurrentUserArtist}) {
    for (final match in matches) {
      final target = _extractFromMatch(
        match,
        matchId: match.id,
        isCurrentUserArtist: isCurrentUserArtist,
      );
      if (target != null) {
        _cache[match.id] = target;
      }
    }
    debugPrint('🎯 [ChatManager] Cached ${matches.length} match targets');
  }
}
