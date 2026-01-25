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

/// Helper to convert file to base64 data URI
Future<String> fileToBase64DataUri(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();
  final base64String = base64Encode(bytes);

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
      timestamp: json['timestamp'] ?? '',
      apiKey: json['apiKey'] ?? json['api_key'] ?? '',
      cloudName: json['cloudName'] ?? json['cloud_name'] ?? '',
      folder: json['folder'],
      publicId: json['publicId'] ?? json['public_id'],
    );
  }
}

class UploadService {
  final ApiClient _client = ApiClient();

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
  }) async {
    try {
      debugPrint('Uploading gallery image: $filePath');
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
  Future<UploadResponse> uploadAudio(String filePath) async {
    try {
      debugPrint('Uploading audio: $filePath');
      final base64Data = await fileToBase64DataUri(filePath);

      final response = await _client.post(
        Endpoints.uploadAudio,
        data: {'file': base64Data},
      );

      debugPrint('Audio uploaded: ${response.data}');
      return UploadResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Audio upload error: $e');
      rethrow;
    }
  }

  /// 🎬 Upload video sample (base64)
  Future<UploadResponse> uploadVideo(String filePath) async {
    try {
      debugPrint('Uploading video: $filePath');
      final base64Data = await fileToBase64DataUri(filePath);

      final response = await _client.post(
        Endpoints.uploadVideo,
        data: {'file': base64Data},
      );

      debugPrint('Video uploaded: ${response.data}');
      return UploadResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Video upload error: $e');
      rethrow;
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
      final dio = Dio();
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
    final sizeMB = await getFileSizeMB(filePath);
    final maxSize = isVideo ? 50.0 : 10.0;
    return sizeMB > maxSize;
  }
}
