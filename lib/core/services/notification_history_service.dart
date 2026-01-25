/// 🔔 GIGMATCH Notification History Service
/// Fetches and manages notifications from the backend API
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../exceptions.dart';

/// Notification model
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? deepLink;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.deepLink,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? json['_id'] ?? '',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      deepLink: json['deepLink'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      isRead: json['isRead'] ?? json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}

/// Paginated notifications response
class NotificationsResponse {
  final List<AppNotification> notifications;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  NotificationsResponse({
    required this.notifications,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      notifications:
          (json['notifications'] as List? ?? json['data'] as List? ?? [])
              .map((e) => AppNotification.fromJson(e))
              .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// Notification Service
class NotificationHistoryService {
  final ApiClient _client = ApiClient();

  /// Get user notifications
  Future<NotificationsResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      debugPrint('🔔 [NotificationService] Fetching notifications...');

      final response = await _client.get(
        Endpoints.notifications,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (unreadOnly) 'unreadOnly': true,
        },
      );

      return NotificationsResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [NotificationService] Get notifications failed: $e');
      throw _handleError(e);
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      debugPrint('🔔 [NotificationService] Fetching unread count...');

      final response = await _client.get('/notifications/unread');
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      debugPrint('❌ [NotificationService] Get unread count failed: $e');
      return 0; // Return 0 on error
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      debugPrint('🔔 [NotificationService] Marking as read: $notificationId');

      await _client.put(Endpoints.markNotificationRead(notificationId));
    } on DioException catch (e) {
      debugPrint('❌ [NotificationService] Mark as read failed: $e');
      throw _handleError(e);
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      debugPrint('🔔 [NotificationService] Marking all as read...');

      final response = await _client.put(Endpoints.markAllNotificationsRead);
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      debugPrint('❌ [NotificationService] Mark all as read failed: $e');
      throw _handleError(e);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      debugPrint('🔔 [NotificationService] Deleting: $notificationId');

      await _client.delete(Endpoints.deleteNotification(notificationId));
    } on DioException catch (e) {
      debugPrint('❌ [NotificationService] Delete failed: $e');
      throw _handleError(e);
    }
  }

  /// Clear all notifications
  Future<int> clearAll() async {
    try {
      debugPrint('🔔 [NotificationService] Clearing all notifications...');

      final response = await _client.delete(Endpoints.deleteAllNotifications);
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      debugPrint('❌ [NotificationService] Clear all failed: $e');
      throw _handleError(e);
    }
  }

  /// Handle DioException
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? 'Request failed';
      return ApiException(message, e.response?.statusCode ?? 500);
    }
    return NetworkException('Network error: ${e.message}');
  }
}
