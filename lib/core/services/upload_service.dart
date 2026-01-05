/// 📤 GIGMATCH Upload Service
/// Handles file uploads to Cloudinary

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
      url: json['url'] ?? json['secure_url'] ?? '',
      publicId: json['publicId'] ?? json['public_id'] ?? '',
      resourceType: json['resourceType'] ?? json['resource_type'] ?? 'image',
      width: json['width'],
      height: json['height'],
      bytes: json['bytes'] ?? 0,
    );
  }
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

  /// 📝 Get signed upload parameters
  Future<SignedUploadParams> getSignedParams({
    required String resourceType, // 'image', 'video', 'audio'
    String? folder,
  }) async {
    try {
      final response = await _client.get(
        Endpoints.uploadSignedParams,
        queryParameters: {
          'resourceType': resourceType,
          if (folder != null) 'folder': folder,
        },
      );
      return SignedUploadParams.fromJson(response.data);
    } catch (e) {
      debugPrint('Get signed params error: $e');
      rethrow;
    }
  }

  /// 🖼️ Upload profile photo
  Future<UploadResponse> uploadProfilePhoto(
    File file, {
    Function(int, int)? onProgress,
  }) async {
    return _uploadFile(
      file: file,
      endpoint: Endpoints.uploadProfilePhoto,
      resourceType: 'image',
      onProgress: onProgress,
    );
  }

  /// 🖼️ Upload gallery image
  Future<UploadResponse> uploadGalleryImage(
    File file, {
    Function(int, int)? onProgress,
  }) async {
    return _uploadFile(
      file: file,
      endpoint: Endpoints.uploadGallery,
      resourceType: 'image',
      onProgress: onProgress,
    );
  }

  /// 🎵 Upload audio sample
  Future<UploadResponse> uploadAudio(
    File file, {
    Function(int, int)? onProgress,
  }) async {
    return _uploadFile(
      file: file,
      endpoint: Endpoints.uploadAudio,
      resourceType: 'audio',
      onProgress: onProgress,
    );
  }

  /// 🎬 Upload video sample
  Future<UploadResponse> uploadVideo(
    File file, {
    Function(int, int)? onProgress,
  }) async {
    return _uploadFile(
      file: file,
      endpoint: Endpoints.uploadVideo,
      resourceType: 'video',
      onProgress: onProgress,
    );
  }

  /// 📤 Internal upload method
  Future<UploadResponse> _uploadFile({
    required File file,
    required String endpoint,
    required String resourceType,
    Function(int, int)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'resourceType': resourceType,
      });

      final response = await _client.post(
        endpoint,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return UploadResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  /// 🔗 Direct upload to Cloudinary (for large files)
  Future<UploadResponse> uploadDirectToCloudinary({
    required File file,
    required String resourceType,
    Function(int, int)? onProgress,
  }) async {
    try {
      // Get signed params from our server
      final params = await getSignedParams(resourceType: resourceType);

      // Upload directly to Cloudinary
      final dio = Dio();
      final fileName = file.path.split('/').last;

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
}
