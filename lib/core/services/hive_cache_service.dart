/// 💾 GIGMATCH Hive Cache Service
/// Centralized Hive initialization and configuration for caching
library;

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Cache box names
class CacheBoxes {
  static const String messages = 'messages';
  static const String conversations = 'conversations';
  static const String profiles = 'profiles';
  static const String pendingQueue = 'pending_queue';
  static const String mediaCache = 'media_cache';
  static const String settings = 'settings';
}

/// Cache keys for settings box
class CacheKeys {
  static const String lastSyncTime = 'last_sync_time';
  static const String lastReadTimestamps = 'last_read_timestamps';
  static const String cachedMessageIds = 'cached_message_ids';
}

/// Initialize Hive and open all boxes
Future<void> initializeHiveCache() async {
  await Hive.initFlutter('gigmatch_cache');

  // Register adapters
  _registerAdapters();

  // Open boxes with dynamic type (storing JSON strings)
  await Hive.openBox<String>(CacheBoxes.messages);
  await Hive.openBox<String>(CacheBoxes.conversations);
  await Hive.openBox<String>(CacheBoxes.profiles);
  await Hive.openBox<String>(CacheBoxes.pendingQueue);
  await Hive.openBox<String>(CacheBoxes.mediaCache);
  await Hive.openBox<String>(CacheBoxes.settings);

  debugPrint('✅ Hive cache initialized');
}

/// Register Hive type adapters
void _registerAdapters() {
  // Using default String adapter
}

/// Close all boxes (call on app exit)
Future<void> closeHiveCache() async {
  await Hive.close();
  debugPrint('✅ Hive cache closed');
}

/// Clear all cached data
Future<void> clearAllCache() async {
  for (final boxName in [
    CacheBoxes.messages,
    CacheBoxes.conversations,
    CacheBoxes.profiles,
    CacheBoxes.pendingQueue,
    CacheBoxes.mediaCache,
    CacheBoxes.settings,
  ]) {
    final box = Hive.box<String>(boxName);
    await box.clear();
  }
  debugPrint('✅ All cache cleared');
}

/// Clear old cache (items older than specified days)
Future<void> clearOldCache({int daysOld = 30}) async {
  final cutoff = DateTime.now().subtract(Duration(days: daysOld));
  final messagesBox = Hive.box<String>(CacheBoxes.messages);

  // Get all keys and remove old entries
  final keysToRemove = <dynamic>[];
  for (final key in messagesBox.keys) {
    try {
      final timestamp = DateTime.parse(key.toString());
      if (timestamp.isBefore(cutoff)) {
        keysToRemove.add(key);
      }
    } catch (_) {
      // Key not a timestamp, skip
    }
  }

  for (final key in keysToRemove) {
    await messagesBox.delete(key);
  }

  debugPrint('✅ Old cache cleared (${keysToRemove.length} items)');
}

/// Get cache statistics
CacheStats getCacheStats() {
  return CacheStats(
    messagesCount: Hive.box<String>(CacheBoxes.messages).keys.length,
    conversationsCount: Hive.box<String>(CacheBoxes.conversations).keys.length,
    profilesCount: Hive.box<String>(CacheBoxes.profiles).keys.length,
    pendingQueueCount: Hive.box<String>(CacheBoxes.pendingQueue).keys.length,
    mediaCacheCount: Hive.box<String>(CacheBoxes.mediaCache).keys.length,
  );
}

/// Cache statistics
class CacheStats {
  final int messagesCount;
  final int conversationsCount;
  final int profilesCount;
  final int pendingQueueCount;
  final int mediaCacheCount;

  CacheStats({
    required this.messagesCount,
    required this.conversationsCount,
    required this.profilesCount,
    required this.pendingQueueCount,
    required this.mediaCacheCount,
  });

  int get totalItems =>
      messagesCount +
      conversationsCount +
      profilesCount +
      pendingQueueCount +
      mediaCacheCount;
}
