/// 💬 GIGMATCH Message Cache Service
/// Local message storage using Hive for offline access
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/message_models.dart';
import 'hive_cache_service.dart';

/// MessageCacheService handles caching of chat messages locally
class MessageCacheService {
  static const String boxName = CacheBoxes.messages;
  static const int maxMessagesPerConversation = 100;

  /// Get the Hive box for messages
  Box<String> get _box => Hive.box<String>(boxName);

  /// Get cached messages for a conversation
  Future<List<Message>> getCachedMessages(String matchId) async {
    try {
      final data = _box.get(matchId);
      if (data == null) return [];

      final jsonList = jsonDecode(data) as List<dynamic>;
      return jsonList
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint('Error getting cached messages: $e');
      return [];
    }
  }

  /// Cache messages for a conversation
  Future<void> cacheMessages(String matchId, List<Message> messages) async {
    try {
      // Only keep the last N messages
      final sortedMessages = [...messages]..sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );
      final limitedMessages = sortedMessages.length > maxMessagesPerConversation
          ? sortedMessages.sublist(sortedMessages.length - maxMessagesPerConversation)
          : sortedMessages;

      final jsonList = limitedMessages.map((m) => m.toJson()).toList();
      await _box.put(matchId, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error caching messages: $e');
    }
  }

  /// Add a single message to cache
  Future<void> addMessage(String matchId, Message message) async {
    try {
      final cached = await getCachedMessages(matchId);

      // Check if message already exists
      if (cached.any((m) => m.id == message.id)) return;

      // Add new message
      cached.add(message);
      await cacheMessages(matchId, cached);
    } catch (e) {
      debugPrint('Error adding message to cache: $e');
    }
  }

  /// Update an existing message in cache
  Future<void> updateMessage(String matchId, Message message) async {
    try {
      final cached = await getCachedMessages(matchId);
      final index = cached.indexWhere((m) => m.id == message.id);

      if (index != -1) {
        cached[index] = message;
        await cacheMessages(matchId, cached);
      }
    } catch (e) {
      debugPrint('Error updating message in cache: $e');
    }
  }

  /// Delete a message from cache
  Future<void> deleteMessage(String matchId, String messageId) async {
    try {
      final cached = await getCachedMessages(matchId);
      cached.removeWhere((m) => m.id == messageId);
      await cacheMessages(matchId, cached);
    } catch (e) {
      debugPrint('Error deleting message from cache: $e');
    }
  }

  /// Clear cache for a specific conversation
  Future<void> clearConversation(String matchId) async {
    try {
      await _box.delete(matchId);
    } catch (e) {
      debugPrint('Error clearing conversation cache: $e');
    }
  }

  /// Get the most recent message for a conversation
  Future<Message?> getLatestMessage(String matchId) async {
    try {
      final messages = await getCachedMessages(matchId);
      if (messages.isEmpty) return null;
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return messages.first;
    } catch (e) {
      debugPrint('Error getting latest message: $e');
      return null;
    }
  }

  /// Get unread messages count from cache
  Future<int> getUnreadCount(String matchId) async {
    try {
      final messages = await getCachedMessages(matchId);
      return messages.where((m) => !m.isRead).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Search messages in cache
  Future<List<Message>> searchMessages(
    String matchId,
    String query,
  ) async {
    try {
      final messages = await getCachedMessages(matchId);
      final lowerQuery = query.toLowerCase();
      return messages.where((m) {
        if (m.content.toLowerCase().contains(lowerQuery)) return true;
        return false;
      }).toList();
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }

  /// Get message by ID
  Future<Message?> getMessage(String matchId, String messageId) async {
    try {
      final messages = await getCachedMessages(matchId);
      return messages.firstWhere((m) => m.id == messageId);
    } catch (e) {
      return null;
    }
  }

  /// Check if conversation is cached
  Future<bool> hasCachedConversation(String matchId) async {
    try {
      return _box.containsKey(matchId);
    } catch (e) {
      return false;
    }
  }

  /// Get all cached conversation IDs
  Future<List<String>> getAllCachedConversationIds() async {
    try {
      return _box.keys.map((k) => k.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all message cache
  Future<void> clearAll() async {
    await _box.clear();
  }
}

/// Pending message data class for offline queue
class PendingMessageData {
  final String tempId;
  final String matchId;
  final Message message;
  final DateTime createdAt;
  int retryCount;

  PendingMessageData({
    required this.tempId,
    required this.matchId,
    required this.message,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
          'tempId': tempId,
          'matchId': matchId,
          'message': jsonEncode(message.toJson()),
          'createdAt': createdAt.toIso8601String(),
          'retryCount': retryCount,
        };

  factory PendingMessageData.fromJson(Map<String, dynamic> json) => PendingMessageData(
          tempId: json['tempId'] as String,
          matchId: json['matchId'] as String,
          message: Message.fromJson(jsonDecode(json['message'] as String) as Map<String, dynamic>),
          createdAt: DateTime.parse(json['createdAt'] as String),
          retryCount: (json['retryCount'] as int?) ?? 0,
        );
}
