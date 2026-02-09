/// 📥 GIGMATCH Media Download Service
/// Handles downloading and caching media files locally
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// MediaDownloadService handles downloading media for offline access
class MediaDownloadService {
  static final MediaDownloadService _instance = MediaDownloadService._internal();
  factory MediaDownloadService() => _instance;
  MediaDownloadService._internal();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  /// Get the media cache directory
  Future<Directory> getMediaCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final mediaDir = Directory('${tempDir.path}/media_cache');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Get the media download directory (app-specific external storage)
  Future<Directory> getMediaDownloadDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${docsDir.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  /// Generate a unique filename from URL
  String _generateFilename(String url) {
    final uri = Uri.parse(url);
    final path = uri.pathSegments.last;
    if (path.isNotEmpty && path.contains('.')) {
      return path;
    }
    // Generate hash-based filename if no extension
    final hash = md5.convert(utf8.encode(url)).toString();
    return 'media_$hash';
  }

  /// Get local file path for a URL (cached location)
  Future<String?> getLocalPath(String url) async {
    try {
      final cacheDir = await getMediaCacheDir();
      final filename = _generateFilename(url);
      final file = File('${cacheDir.path}/$filename');
      if (await file.exists()) {
        return file.path;
      }
    } catch (e) {
      debugPrint('Error getting local path: $e');
    }
    return null;
  }

  /// Check if media is already downloaded
  Future<bool> isDownloaded(String url) async {
    final localPath = await getLocalPath(url);
    return localPath != null && await File(localPath).exists();
  }

  /// Download media to cache
  Future<String> downloadToCache(
    String url, {
    void Function(int, int)? onProgress,
    String? customFilename,
  }) async {
    final cacheDir = await getMediaCacheDir();
    final filename = customFilename ?? _generateFilename(url);
    final savePath = '${cacheDir.path}/$filename';

    // Return cached file if exists
    final file = File(savePath);
    if (await file.exists()) {
      debugPrint('Media already cached: $url');
      return savePath;
    }

    // Download the file
    final cancelToken = CancelToken();
    _cancelTokens[url] = cancelToken;

    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ),
      );

      _cancelTokens.remove(url);
      debugPrint('Media downloaded to cache: $savePath');
      return savePath;
    } catch (e) {
      _cancelTokens.remove(url);
      // Clean up partial file
      if (await file.exists()) {
        await file.delete();
      }
      throw Exception('Failed to download media: $e');
    }
  }

  /// Download media to downloads folder
  Future<String> downloadToDownloads(
    String url, {
    void Function(int, int)? onProgress,
    String? customFilename,
  }) async {
    final downloadDir = await getMediaDownloadDir();
    final filename = customFilename ?? _generateFilename(url);
    final savePath = '${downloadDir.path}/$filename';

    // Check if already exists
    final file = File(savePath);
    if (await file.exists()) {
      debugPrint('Media already in downloads: $savePath');
      return savePath;
    }

    // Download the file
    final cancelToken = CancelToken();
    _cancelTokens[url] = cancelToken;

    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );

      _cancelTokens.remove(url);
      debugPrint('Media downloaded to downloads: $savePath');
      return savePath;
    } catch (e) {
      _cancelTokens.remove(url);
      if (await file.exists()) {
        await file.delete();
      }
      throw Exception('Failed to download media: $e');
    }
  }

  /// Cancel an ongoing download
  void cancelDownload(String url) {
    final cancelToken = _cancelTokens[url];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled by user');
      _cancelTokens.remove(url);
    }
  }

  /// Get file size in bytes
  Future<int?> getFileSize(String url) async {
    try {
      final response = await _dio.head(url);
      return response.headers.value('content-length') != null
          ? int.parse(response.headers.value('content-length')!)
          : null;
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached media files
  Future<void> clearCache() async {
    try {
      final cacheDir = await getMediaCacheDir();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      debugPrint('Media cache cleared');
    } catch (e) {
      debugPrint('Error clearing media cache: $e');
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getMediaCacheDir();
      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Get cache size as formatted string
  Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Delete a specific cached file
  Future<void> deleteCachedFile(String url) async {
    final localPath = await getLocalPath(url);
    if (localPath != null) {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted cached file: $localPath');
      }
    }
  }

  /// Delete old cache files
  Future<void> deleteOldCache({int daysOld = 7}) async {
    try {
      final cacheDir = await getMediaCacheDir();
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));

      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final modified = await entity.lastModified();
          if (modified.isBefore(cutoff)) {
            await entity.delete();
          }
        }
      }
      debugPrint('Old cache files deleted');
    } catch (e) {
      debugPrint('Error deleting old cache: $e');
    }
  }
}
