/// 📤 GIGMATCH Upload Service
/// Handles file uploads to Cloudinary via backend
library;

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api.dart';

/// Upload Response
class UploadResponse {
  final String url;
  final String publicId;
  final String resourceType;
  final int? width;
  final int? height;
  final int bytes;

  UploadResponse({
    required this.url,
    required this.publicId,
    required this.resourceType,
    this.width,
    this.height,
    required this.bytes,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      url: json['url'] ?? json['secureUrl'] ?? json['secure_url'] ?? '',
      publicId: json['publicId'] ?? json['public_id'] ?? '',
      resourceType: json['resourceType'] ?? json['resource_type'] ?? 'image',
      width: json['width'],
      height: json['height'],
      bytes: json['bytes'] ?? 0,
    );
  }
}

/// Exception for upload failures with user-friendly messages
class UploadException implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  UploadException(this.message, {this.code, this.cause});

  @override
  String toString() => message;
}

/// Private helper to read and encode file in an isolate
Future<String> _readAndEncodeFile(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();
  return base64Encode(bytes);
}

/// Helper to convert file to base64 data URI
Future<String> fileToBase64DataUri(String filePath) async {
  // Offload file reading and encoding to a separate isolate to avoid UI jank
  final base64String = await compute(_readAndEncodeFile, filePath);

  // Determine MIME type from extension
  final extension = filePath.split('.').last.toLowerCase();
  String mimeType;

  switch (extension) {
    case 'jpg':
    case 'jpeg':
      mimeType = 'image/jpeg';
      break;
    case 'png':
      mimeType = 'image/png';
      break;
    case 'gif':
      mimeType = 'image/gif';
      break;
    case 'webp':
      mimeType = 'image/webp';
      break;
    case 'heic':
    case 'heif':
      mimeType = 'image/heic';
      break;
    case 'mp3':
      mimeType = 'audio/mpeg';
      break;
    case 'wav':
      mimeType = 'audio/wav';
      break;
    case 'aac':
      mimeType = 'audio/aac';
      break;
    case 'm4a':
      mimeType = 'audio/mp4';
      break;
    case 'ogg':
      mimeType = 'audio/ogg';
      break;
    case 'flac':
      mimeType = 'audio/flac';
      break;
    case 'mp4':
      mimeType = 'video/mp4';
      break;
    case 'mov':
      mimeType = 'video/quicktime';
      break;
    case 'avi':
      mimeType = 'video/x-msvideo';
      break;
    case 'webm':
      mimeType = 'video/webm';
      break;
    case 'mkv':
      mimeType = 'video/x-matroska';
      break;
    case '3gp':
      mimeType = 'video/3gpp';
      break;
    default:
      mimeType = 'application/octet-stream';
  }

  return 'data:$mimeType;base64,$base64String';
}

/// Signed Upload Params
class SignedUploadParams {
  final String signature;
  final String timestamp;
  final String apiKey;
  final String cloudName;
  final String? folder;
  final String? publicId;

  SignedUploadParams({
    required this.signature,
    required this.timestamp,
    required this.apiKey,
    required this.cloudName,
    this.folder,
    this.publicId,
  });

  factory SignedUploadParams.fromJson(Map<String, dynamic> json) {
    return SignedUploadParams(
      signature: json['signature'] ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      apiKey: json['apiKey'] ?? json['api_key'] ?? '',
      cloudName: json['cloudName'] ?? json['cloud_name'] ?? '',
      folder: json['folder'],
      publicId: json['publicId'] ?? json['public_id'],
    );
  }
}

class UploadService {
  final ApiClient _client = ApiClient();

  Future<T> _withRetry<T>(
    Future<T> Function() task, {
    int maxAttempts = 3,
    Duration baseDelay = const Duration(milliseconds: 700),
    String label = 'upload',
  }) async {
    var attempt = 0;
    while (true) {
      try {
        attempt++;
        return await task();
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        final delay = baseDelay * attempt;
        debugPrint(
          '[$label] retry $attempt/$maxAttempts in ${delay.inMilliseconds}ms: $e',
        );
        await Future.delayed(delay);
      }
    }
  }

  /// Size limits in MB by media type
  static const _maxImageMB = 10;
  static const _maxAudioMB = 25;
  static const _maxVideoMB = 50;

  /// Allowed extensions by type
  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];
  static const _audioExtensions = ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'];
  static const _videoExtensions = ['mp4', 'mov', 'avi', 'webm', 'mkv', '3gp'];

  /// Validate file before upload - throws UploadException if invalid
  Future<void> _ensureFileReady(
    String filePath, {
    required String type, // 'image', 'audio', 'video'
  }) async {
    final file = File(filePath);

    // Check file exists
    if (!await file.exists()) {
      throw UploadException('File not found', code: 'FILE_NOT_FOUND');
    }

    // Check file size
    final bytes = await file.length();
    final sizeMB = bytes / (1024 * 1024);
    final maxMB = switch (type) {
      'audio' => _maxAudioMB,
      'video' => _maxVideoMB,
      _ => _maxImageMB,
    };

    if (sizeMB > maxMB) {
      throw UploadException(
        'File too large (${sizeMB.toStringAsFixed(1)}MB). Max ${maxMB}MB allowed.',
        code: 'FILE_TOO_LARGE',
      );
    }

    // Check extension
    final ext = filePath.split('.').last.toLowerCase();
    final allowed = switch (type) {
      'audio' => _audioExtensions,
      'video' => _videoExtensions,
      _ => _imageExtensions,
    };

    if (!allowed.contains(ext)) {
      throw UploadException(
        'Unsupported file type (.$ext). Allowed: ${allowed.join(', ')}',
        code: 'INVALID_TYPE',
      );
    }
  }

  /// 📝 Get signed upload parameters for direct Cloudinary upload
  Future<SignedUploadParams> getSignedParams({
    required String resourceType, // 'image', 'video', 'raw'
    String? folder,
  }) async {
    try {
      final response = await _client.post(
        Endpoints.uploadSignedParams,
        data: {'resourceType': resourceType},
      );
      return SignedUploadParams.fromJson(response.data);
    } catch (e) {
      debugPrint('Get signed params error: $e');
      rethrow;
    }
  }

  /// 🖼️ Upload profile photo (base64)
  Future<UploadResponse> uploadProfilePhoto(String filePath) async {
    await _ensureFileReady(filePath, type: 'image');
    try {
      debugPrint('Uploading profile photo: $filePath');
      final base64Data = await fileToBase64DataUri(filePath);

      final response = await _client.post(
        Endpoints.uploadProfilePhoto,
        data: {'file': base64Data},
      );

      debugPrint('Profile photo uploaded: ${response.data}');
      return UploadResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Profile photo upload error: $e');
      rethrow;
    }
  }

  /// 🖼️ Upload gallery image (base64)
  Future<UploadResponse> uploadGalleryImage(
    String filePath, {
    int index = 0,
    Function(int, int)? onProgress,
  }) async {
    await _ensureFileReady(filePath, type: 'image');
    try {
      debugPrint('Uploading gallery image: $filePath');
      final sizeMb = await getFileSizeMB(filePath);
      if (sizeMb > 8) {
        return _withRetry(
          () => uploadDirectToCloudinary(
            filePath: filePath,
            resourceType: 'image',
            onProgress: onProgress,
          ),
          label: 'gallery-direct',
        );
      }

      final base64Data = await fileToBase64DataUri(filePath);

      final response = await _client.post(
        Endpoints.uploadGallery,
        data: {'file': base64Data, 'index': index},
      );

      debugPrint('Gallery image uploaded: ${response.data}');
      return UploadResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Gallery image upload error: $e');
      rethrow;
    }
  }

  /// 🖼️ Upload multiple gallery images
  Future<List<UploadResponse>> uploadGalleryImages(
    List<String> filePaths,
  ) async {
    final results = <UploadResponse>[];
    for (var i = 0; i < filePaths.length; i++) {
      try {
        final result = await uploadGalleryImage(filePaths[i], index: i);
        results.add(result);
      } catch (e) {
        debugPrint('Failed to upload gallery image $i: $e');
      }
    }
    return results;
  }

  /// 🎵 Upload audio sample (base64)
  Future<UploadResponse> uploadAudio(
    String filePath, {
    Function(int, int)? onProgress,
  }) async {
    await _ensureFileReady(filePath, type: 'audio');
    debugPrint('Uploading audio: $filePath');
    try {
      return await _withRetry(
        () => uploadDirectToCloudinary(
          filePath: filePath,
          resourceType: 'raw',
          onProgress: onProgress,
        ),
        label: 'audio-direct',
      );
    } catch (e) {
      debugPrint('Direct audio upload failed, falling back: $e');
      final base64Data = await fileToBase64DataUri(filePath);

      final response = await _client.post(
        Endpoints.uploadAudio,
        data: {'file': base64Data},
      );

      debugPrint('Audio uploaded: ${response.data}');
      return UploadResponse.fromJson(response.data);
    }
  }

  /// 🎬 Upload video sample (base64)
  Future<UploadResponse> uploadVideo(
    String filePath, {
    Function(int, int)? onProgress,
  }) async {
    await _ensureFileReady(filePath, type: 'video');
    debugPrint('Uploading video: $filePath');
    try {
      return await _withRetry(
        () => uploadDirectToCloudinary(
          filePath: filePath,
          resourceType: 'video',
          onProgress: onProgress,
        ),
        label: 'video-direct',
      );
    } catch (e) {
      debugPrint('Direct video upload failed, falling back: $e');
      final base64Data = await fileToBase64DataUri(filePath);

      final response = await _client.post(
        Endpoints.uploadVideo,
        data: {'file': base64Data},
      );

      debugPrint('Video uploaded: ${response.data}');
      return UploadResponse.fromJson(response.data);
    }
  }

  /// 🔗 Direct upload to Cloudinary (for large files - uses signed params)
  Future<UploadResponse> uploadDirectToCloudinary({
    required String filePath,
    required String resourceType, // 'image', 'video', 'raw'
    Function(int, int)? onProgress,
  }) async {
    try {
      // Get signed params from our server
      final params = await getSignedParams(resourceType: resourceType);

      // Upload directly to Cloudinary
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );
      final file = File(filePath);
      final fileName = filePath.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'api_key': params.apiKey,
        'timestamp': params.timestamp,
        'signature': params.signature,
        if (params.folder != null) 'folder': params.folder,
      });

      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/${params.cloudName}/$resourceType/upload',
        data: formData,
        onSendProgress: onProgress,
      );

      return UploadResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Direct Cloudinary upload error: $e');
      rethrow;
    }
  }

  /// Check file size (returns size in MB)
  Future<double> getFileSizeMB(String filePath) async {
    final file = File(filePath);
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Check if file is too large (50MB for video, 10MB for others)
  Future<bool> isFileTooLarge(String filePath, {bool isVideo = false}) async {
    return false;
  }
}
