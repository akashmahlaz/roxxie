/// 🔐 GIGMATCH Permission Service
/// Handles runtime permissions for storage, media, and other access
library;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// PermissionService handles runtime permission requests
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check and request photo library permission (iOS)
  Future<bool> requestPhotoLibraryPermission() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }
      final result = await Permission.photos.request();
      return result.isGranted;
    }

    // Android 13+ uses granular media permissions
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Check if we need READ_MEDIA_IMAGES
      if (await _hasAndroid13OrHigher()) {
        final imageStatus = await Permission.mediaLibrary.status;
        if (imageStatus.isGranted) return true;
        if (imageStatus.isPermanentlyDenied) {
          openAppSettings();
          return false;
        }
        final result = await Permission.mediaLibrary.request();
        return result.isGranted;
      }

      // Older Android uses READ_EXTERNAL_STORAGE
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;
      if (storageStatus.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }
      final result = await Permission.storage.request();
      return result.isGranted;
    }

    return true;
  }

  /// Check and request video permission
  Future<bool> requestVideoPermission() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await requestPhotoLibraryPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (await _hasAndroid13OrHigher()) {
        final videoStatus = await Permission.videos.status;
        if (videoStatus.isGranted) return true;
        if (videoStatus.isPermanentlyDenied) {
          openAppSettings();
          return false;
        }
        final result = await Permission.videos.request();
        return result.isGranted;
      }

      return await requestPhotoLibraryPermission();
    }

    return true;
  }

  /// Check and request audio permission
  Future<bool> requestAudioPermission() async {
    if (kIsWeb) return true;

    // For audio recording, we need microphone permission
    final micStatus = await Permission.microphone.status;
    if (micStatus.isGranted) return true;
    if (micStatus.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Check and request storage permission for downloads
  Future<bool> requestDownloadPermission() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS doesn't need explicit permission for saving to gallery
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 10+ uses scoped storage
      if (await _hasAndroid10OrHigher()) {
        // Use MediaStore API for saving files
        return true;
      }

      // Older Android needs WRITE_EXTERNAL_STORAGE
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;
      if (storageStatus.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }
      final result = await Permission.storage.request();
      return result.isGranted;
    }

    return true;
  }

  /// Check notification permission (iOS 12+, Android 13+)
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (await _hasAndroid13OrHigher()) {
        final status = await Permission.notification.status;
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          openAppSettings();
          return false;
        }
        final result = await Permission.notification.request();
        return result.isGranted;
      }
    }

    return true;
  }

  /// Check if we have all required permissions for media operations
  Future<MediaPermissionsStatus> checkMediaPermissions() async {
    final photoGranted = await requestPhotoLibraryPermission();
    final videoGranted = await requestVideoPermission();

    return MediaPermissionsStatus(
      photos: photoGranted,
      videos: videoGranted,
      allGranted: photoGranted && videoGranted,
    );
  }

  /// Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await Permission.photos.status.isGranted;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (await _hasAndroid13OrHigher()) {
        return await Permission.mediaLibrary.status.isGranted ||
               await Permission.videos.status.isGranted ||
               await Permission.photos.status.isGranted;
      }

      return await Permission.storage.status.isGranted;
    }

    return true;
  }

  /// Helper to check Android version
  Future<bool> _hasAndroid10OrHigher() async {
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// Helper to check Android 13 (API 33) or higher
  Future<bool> _hasAndroid13OrHigher() async {
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// Open app settings
  void openAppSettingsPage() {
    openAppSettings();
  }
}

/// Status of media permissions
class MediaPermissionsStatus {
  final bool photos;
  final bool videos;
  final bool allGranted;

  MediaPermissionsStatus({
    required this.photos,
    required this.videos,
    required this.allGranted,
  });
}
