/// 🖼️ GIGMATCH Gallery Service
/// Handles saving images and videos to device gallery
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import '../models/media_types.dart';
import 'media_download_service.dart';

/// GalleryService handles saving media to the device gallery
class GalleryService {
  static final GalleryService _instance = GalleryService._internal();
  factory GalleryService() => _instance;
  GalleryService._internal();

  final MediaDownloadService _downloadService = MediaDownloadService();

  /// Ensure gallery access permission
  Future<bool> _ensureAccess() async {
    final hasAccess = await Gal.hasAccess();
    if (hasAccess) {
      return true;
    }
    final granted = await Gal.requestAccess();
    return granted;
  }

  /// Save an image from URL to gallery
  Future<bool> saveImageToGallery(String url) async {
    try {
      if (!await _ensureAccess()) {
        throw Exception('Permission denied');
      }

      // Download to temp location first
      final tempPath = await _downloadService.downloadToCache(url);

      // Save to gallery
      await Gal.putImage(tempPath);
      return true;
    } catch (e) {
      debugPrint('Error saving image to gallery: $e');
      return false;
    }
  }

  /// Save a video from URL to gallery
  Future<bool> saveVideoToGallery(String url) async {
    try {
      if (!await _ensureAccess()) {
        throw Exception('Permission denied');
      }

      // Download to temp location first
      final tempPath = await _downloadService.downloadToCache(url);

      // Save to gallery
      await Gal.putVideo(tempPath);
      return true;
    } catch (e) {
      debugPrint('Error saving video to gallery: $e');
      return false;
    }
  }

  /// Save local file to gallery
  Future<bool> saveLocalFileToGallery(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      if (!await _ensureAccess()) {
        throw Exception('Permission denied');
      }

      final extension = filePath.split('.').last.toLowerCase();
      final imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp'};
      final videoExts = {'mp4', 'mov', 'avi'};

      if (imageExts.contains(extension)) {
        await Gal.putImage(filePath);
        return true;
      } else if (videoExts.contains(extension)) {
        await Gal.putVideo(filePath);
        return true;
      }

      throw Exception('Unsupported file type: $extension');
    } catch (e) {
      debugPrint('Error saving local file to gallery: $e');
      return false;
    }
  }

  /// Download and save media (handles both images and videos)
  Future<bool> saveMediaToGallery(String url) async {
    final mediaType = ChatMediaType.fromUrl(url);

    switch (mediaType) {
      case ChatMediaType.image:
        return await saveImageToGallery(url);
      case ChatMediaType.video:
        return await saveVideoToGallery(url);
      default:
        debugPrint('Cannot save media type ${mediaType.displayName} to gallery');
        return false;
    }
  }

  /// Check if file is already saved to gallery
  Future<bool> isInGallery(String fileName) async {
    // This is a simplified check - in production you'd need to query the media store
    return false;
  }

  /// Get gallery storage stats
  Future<GalleryStats> getGalleryStats() async {
    // Placeholder for gallery stats
    return GalleryStats(
      totalItems: 0,
      totalSize: 0,
    );
  }
}

/// Gallery statistics
class GalleryStats {
  final int totalItems;
  final int totalSize; // in bytes

  GalleryStats({
    required this.totalItems,
    required this.totalSize,
  });

  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    if (totalSize < 1024 * 1024 * 1024) return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
