/// 💬 GIGMATCH Media Types
/// Enum for different media types in chat
library;

import 'package:flutter/material.dart';

/// Enum representing different types of media that can be sent in chat
enum ChatMediaType {
  image,
  video,
  audio,
  document,
  location,
  contact;

  /// Get icon for this media type
  IconData get icon {
    switch (this) {
      case ChatMediaType.image:
        return Icons.image_rounded;
      case ChatMediaType.video:
        return Icons.videocam_rounded;
      case ChatMediaType.audio:
        return Icons.audiotrack_rounded;
      case ChatMediaType.document:
        return Icons.description_rounded;
      case ChatMediaType.location:
        return Icons.location_on_rounded;
      case ChatMediaType.contact:
        return Icons.person_rounded;
    }
  }

  /// Get display name for this media type
  String get displayName {
    switch (this) {
      case ChatMediaType.image:
        return 'Image';
      case ChatMediaType.video:
        return 'Video';
      case ChatMediaType.audio:
        return 'Audio';
      case ChatMediaType.document:
        return 'Document';
      case ChatMediaType.location:
        return 'Location';
      case ChatMediaType.contact:
        return 'Contact';
    }
  }

  /// Detect media type from URL or file extension
  static ChatMediaType fromUrl(String url) {
    final ext = url.split('.').last.toLowerCase();

    final imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp', 'svg'};
    final videoExts = {'mp4', 'mov', 'avi', 'webm', 'mkv', '3gp', 'flv', 'wmv'};
    final audioExts = {'mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac', 'wma', 'aiff'};
    final documentExts = {'pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx', 'zip'};

    if (imageExts.contains(ext)) return ChatMediaType.image;
    if (videoExts.contains(ext)) return ChatMediaType.video;
    if (audioExts.contains(ext)) return ChatMediaType.audio;
    if (documentExts.contains(ext)) return ChatMediaType.document;

    // Try to detect from URL patterns
    if (url.contains('/images/') || url.contains('/img/')) return ChatMediaType.image;
    if (url.contains('/videos/') || url.contains('/video/')) return ChatMediaType.video;
    if (url.contains('/audio/') || url.contains('/audio/')) return ChatMediaType.audio;

    return ChatMediaType.document;
  }

  /// Detect from MIME type
  static ChatMediaType fromMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) return ChatMediaType.image;
    if (mimeType.startsWith('video/')) return ChatMediaType.video;
    if (mimeType.startsWith('audio/')) return ChatMediaType.audio;
    if (mimeType == 'application/pdf') return ChatMediaType.document;
    if (mimeType.startsWith('text/')) return ChatMediaType.document;

    return ChatMediaType.document;
  }

  /// Check if this media type can be saved to gallery
  bool get canSaveToGallery {
    return this == ChatMediaType.image || this == ChatMediaType.video;
  }

  /// Check if this media type can be previewed in-app
  bool get canPreview {
    return this == ChatMediaType.image || this == ChatMediaType.video || this == ChatMediaType.audio;
  }
}
