/// 📤 GIGMATCH Pending Message Queue Service
/// Persistent queue for offline message sending
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/message_models.dart';
import 'hive_cache_service.dart';

/// Pending message structure for offline queue
class PendingMessage {
  final String tempId;
  final String matchId;
  final Message message;
  final DateTime createdAt;
  int retryCount;
  String? error;

  PendingMessage({
    required this.tempId,
    required this.matchId,
    required this.message,
    required this.createdAt,
    this.retryCount = 0,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'tempId': tempId,
        'matchId': matchId,
        'message': jsonEncode(message.toJson()),
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'error': error,
      };

  factory PendingMessage.fromJson(Map<String, dynamic> json) => PendingMessage(
        tempId: json['tempId'],
        matchId: json['matchId'],
        message: Message.fromJson(jsonDecode(json['message'])),
        createdAt: DateTime.parse(json['createdAt']),
        retryCount: json['retryCount'] ?? 0,
        error: json['error'],
      );

  void incrementRetry() {
    retryCount++;
  }

  void setError(String errorMessage) {
    error = errorMessage;
  }
}

/// PendingMessageQueueService handles persistent queue for offline messages
class PendingMessageQueueService {
  static const String boxName = CacheBoxes.pendingQueue;
  static const int maxRetries = 3;

  /// Get the Hive box for pending messages
  Box<String> get _box => Hive.box<String>(boxName);

  /// Queue key for pending messages list
  static const String _queueKey = 'pending_queue';

  /// Add a message to the pending queue
  Future<void> add(PendingMessage pending) async {
    try {
      final queue = await _getQueue();
      queue.add(pending.toJson());
      await _saveQueue(queue);
    } catch (e) {
      debugPrint('Error adding to pending queue: $e');
    }
  }

  /// Remove a message from the queue
  Future<void> remove(String tempId) async {
    try {
      final queue = await _getQueue();
      queue.removeWhere((item) => item['tempId'] == tempId);
      await _saveQueue(queue);
    } catch (e) {
      debugPrint('Error removing from pending queue: $e');
    }
  }

  /// Get all pending messages
  Future<List<PendingMessage>> getQueue() async {
    try {
      final queue = await _getQueue();
      return queue
          .map((item) => PendingMessage.fromJson(item))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint('Error getting pending queue: $e');
      return [];
    }
  }

  /// Get pending messages for a specific conversation
  Future<List<PendingMessage>> getMessagesForMatch(String matchId) async {
    try {
      final queue = await _getQueue();
      return queue
          .where((item) => item['matchId'] == matchId)
          .map((item) => PendingMessage.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting messages for match: $e');
      return [];
    }
  }

  /// Update retry count for a message
  Future<void> incrementRetry(String tempId) async {
    try {
      final queue = await _getQueue();
      final index = queue.indexWhere((item) => item['tempId'] == tempId);
      if (index != -1) {
        queue[index]['retryCount'] = (queue[index]['retryCount'] ?? 0) + 1;
        await _saveQueue(queue);
      }
    } catch (e) {
      debugPrint('Error incrementing retry: $e');
    }
  }

  /// Update error for a message
  Future<void> setError(String tempId, String errorMessage) async {
    try {
      final queue = await _getQueue();
      final index = queue.indexWhere((item) => item['tempId'] == tempId);
      if (index != -1) {
        queue[index]['error'] = errorMessage;
        await _saveQueue(queue);
      }
    } catch (e) {
      debugPrint('Error setting error: $e');
    }
  }

  /// Mark message as failed after max retries
  Future<void> markAsFailed(String tempId) async {
    try {
      final queue = await _getQueue();
      final index = queue.indexWhere((item) => item['tempId'] == tempId);
      if (index != -1) {
        queue[index]['retryCount'] = maxRetries;
        await _saveQueue(queue);
      }
    } catch (e) {
      debugPrint('Error marking as failed: $e');
    }
  }

  /// Get messages that need retry
  Future<List<PendingMessage>> getRetryableMessages() async {
    try {
      final queue = await _getQueue();
      return queue
          .where((item) => (item['retryCount'] ?? 0) < maxRetries)
          .map((item) => PendingMessage.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting retryable messages: $e');
      return [];
    }
  }

  /// Get failed messages
  Future<List<PendingMessage>> getFailedMessages() async {
    try {
      final queue = await _getQueue();
      return queue
          .where((item) => (item['retryCount'] ?? 0) >= maxRetries)
          .map((item) => PendingMessage.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting failed messages: $e');
      return [];
    }
  }

  /// Clear all pending messages
  Future<void> clear() async {
    try {
      await _box.delete(_queueKey);
    } catch (e) {
      debugPrint('Error clearing pending queue: $e');
    }
  }

  /// Get queue count
  Future<int> getCount() async {
    try {
      final queue = await _getQueue();
      return queue.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get failed count
  Future<int> getFailedCount() async {
    try {
      final queue = await _getQueue();
      return queue.where((item) => (item['retryCount'] ?? 0) >= maxRetries).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get retryable count
  Future<int> getRetryableCount() async {
    try {
      final queue = await _getQueue();
      return queue.where((item) => (item['retryCount'] ?? 0) < maxRetries).length;
    } catch (e) {
      return 0;
    }
  }

  /// Helper: Get queue from box
  Future<List<Map<String, dynamic>>> _getQueue() async {
    try {
      final data = _box.get(_queueKey);
      if (data == null) return [];
      return (jsonDecode(data) as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting queue: $e');
      return [];
    }
  }

  /// Helper: Save queue to box
  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    await _box.put(_queueKey, jsonEncode(queue));
  }
}

/// Helper function to create pending message from send params
PendingMessage createPendingMessage({
  required String matchId,
  required String content,
  required String tempId,
  required String senderId,
  required String senderName,
  required String senderType,
}) {
  return PendingMessage(
    tempId: tempId,
    matchId: matchId,
    message: Message(
      id: tempId,
      matchId: matchId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    ),
    createdAt: DateTime.now(),
  );
}
