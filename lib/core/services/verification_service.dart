/// ✅ GIGMATCH Identity Verification Service
/// Handles ID verification, document upload, and status tracking
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api.dart';

/// Verification status enum
enum VerificationStatus {
  notStarted,
  inProgress,
  pendingReview,
  approved,
  rejected,
  expired;

  static VerificationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'not_started':
        return VerificationStatus.notStarted;
      case 'in_progress':
        return VerificationStatus.inProgress;
      case 'pending_review':
      case 'pending':
        return VerificationStatus.pendingReview;
      case 'approved':
      case 'verified':
        return VerificationStatus.approved;
      case 'rejected':
      case 'failed':
        return VerificationStatus.rejected;
      case 'expired':
        return VerificationStatus.expired;
      default:
        return VerificationStatus.notStarted;
    }
  }

  String get displayName {
    switch (this) {
      case VerificationStatus.notStarted:
        return 'Not Started';
      case VerificationStatus.inProgress:
        return 'In Progress';
      case VerificationStatus.pendingReview:
        return 'Pending Review';
      case VerificationStatus.approved:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.expired:
        return 'Expired';
    }
  }
}

/// Document type for verification
enum DocumentType {
  passport,
  driversLicense,
  nationalId,
  selfie,
  proofOfAddress;

  String get value {
    switch (this) {
      case DocumentType.passport:
        return 'passport';
      case DocumentType.driversLicense:
        return 'drivers_license';
      case DocumentType.nationalId:
        return 'national_id';
      case DocumentType.selfie:
        return 'selfie';
      case DocumentType.proofOfAddress:
        return 'proof_of_address';
    }
  }

  String get displayName {
    switch (this) {
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.driversLicense:
        return "Driver's License";
      case DocumentType.nationalId:
        return 'National ID';
      case DocumentType.selfie:
        return 'Selfie';
      case DocumentType.proofOfAddress:
        return 'Proof of Address';
    }
  }
}

/// Verification status response
class VerificationStatusResponse {
  final String? verificationId;
  final VerificationStatus status;
  final List<VerificationDocument> documents;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final bool canResubmit;
  final int? daysUntilExpiry;

  VerificationStatusResponse({
    this.verificationId,
    required this.status,
    this.documents = const [],
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.canResubmit = true,
    this.daysUntilExpiry,
  });

  factory VerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    return VerificationStatusResponse(
      verificationId: json['verificationId'] ?? json['id'],
      status: VerificationStatus.fromString(json['status']),
      documents: (json['documents'] as List?)
              ?.map((e) => VerificationDocument.fromJson(e))
              .toList() ??
          [],
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'])
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      canResubmit: json['canResubmit'] ?? true,
      daysUntilExpiry: json['daysUntilExpiry'],
    );
  }

  /// Returns empty/initial state
  factory VerificationStatusResponse.initial() {
    return VerificationStatusResponse(status: VerificationStatus.notStarted);
  }
}

/// Individual verification document
class VerificationDocument {
  final String id;
  final DocumentType type;
  final String? url;
  final bool isUploaded;
  final bool isVerified;
  final String? rejectionReason;

  VerificationDocument({
    required this.id,
    required this.type,
    this.url,
    this.isUploaded = false,
    this.isVerified = false,
    this.rejectionReason,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: json['id'] ?? '',
      type: _parseDocumentType(json['type']),
      url: json['url'],
      isUploaded: json['isUploaded'] ?? json['uploaded'] ?? false,
      isVerified: json['isVerified'] ?? json['verified'] ?? false,
      rejectionReason: json['rejectionReason'],
    );
  }

  static DocumentType _parseDocumentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'passport':
        return DocumentType.passport;
      case 'drivers_license':
      case 'driverslicense':
        return DocumentType.driversLicense;
      case 'national_id':
      case 'nationalid':
        return DocumentType.nationalId;
      case 'selfie':
        return DocumentType.selfie;
      case 'proof_of_address':
      case 'proofofaddress':
        return DocumentType.proofOfAddress;
      default:
        return DocumentType.nationalId;
    }
  }
}

/// Verification session response
class VerificationSession {
  final String sessionId;
  final String? uploadUrl;
  final DateTime expiresAt;

  VerificationSession({
    required this.sessionId,
    this.uploadUrl,
    required this.expiresAt,
  });

  factory VerificationSession.fromJson(Map<String, dynamic> json) {
    return VerificationSession(
      sessionId: json['sessionId'] ?? json['id'] ?? '',
      uploadUrl: json['uploadUrl'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(hours: 1)),
    );
  }
}

/// Service exception
class VerificationServiceError implements Exception {
  final String message;
  final String? code;

  VerificationServiceError(this.message, {this.code});

  @override
  String toString() => message;
}

/// 🔐 Verification Service
class VerificationService {
  final ApiClient _client = ApiClient();

  /// 📋 Get current verification status
  Future<VerificationStatusResponse> getStatus() async {
    try {
      final response = await _client.get(Endpoints.verificationStatus);
      return VerificationStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // User has not started verification
        return VerificationStatusResponse.initial();
      }
      debugPrint('Get verification status error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Get verification status error: $e');
      rethrow;
    }
  }

  /// 🚀 Start a new verification session
  Future<VerificationSession> startVerification({
    required DocumentType documentType,
  }) async {
    try {
      final response = await _client.post(
        Endpoints.verificationStart,
        data: {
          'documentType': documentType.value,
        },
      );
      return VerificationSession.fromJson(response.data);
    } catch (e) {
      debugPrint('Start verification error: $e');
      rethrow;
    }
  }

  /// 📤 Upload ID document (front or back)
  Future<VerificationDocument> uploadDocument({
    required File file,
    required DocumentType documentType,
    required String sessionId,
    bool isFrontSide = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'documentType': documentType.value,
        'sessionId': sessionId,
        'side': isFrontSide ? 'front' : 'back',
      });

      final response = await _client.post(
        Endpoints.verificationUploadDocument,
        data: formData,
      );

      return VerificationDocument.fromJson(response.data);
    } catch (e) {
      debugPrint('Upload document error: $e');
      rethrow;
    }
  }

  /// 🤳 Upload selfie for face matching
  Future<VerificationDocument> uploadSelfie({
    required File file,
    required String sessionId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'sessionId': sessionId,
      });

      final response = await _client.post(
        Endpoints.verificationUploadSelfie,
        data: formData,
      );

      return VerificationDocument.fromJson(response.data);
    } catch (e) {
      debugPrint('Upload selfie error: $e');
      rethrow;
    }
  }

  /// ✅ Submit verification for review
  Future<VerificationStatusResponse> submitForReview({
    required String sessionId,
  }) async {
    try {
      final response = await _client.post(
        Endpoints.verificationSubmit,
        data: {'sessionId': sessionId},
      );
      return VerificationStatusResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Submit verification error: $e');
      rethrow;
    }
  }

  /// 📄 Get verification details
  Future<VerificationStatusResponse> getVerificationDetails(
    String verificationId,
  ) async {
    try {
      final response = await _client.get(
        Endpoints.verificationDetails(verificationId),
      );
      return VerificationStatusResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Get verification details error: $e');
      rethrow;
    }
  }
}
