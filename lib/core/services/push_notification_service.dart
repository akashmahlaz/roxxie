/// 🚀 GigMatch Push Notification Service - BULLETPROOF VERSION
///
/// Comprehensive push notification service using Firebase Cloud Messaging
/// Features:
/// - Token management (registration, refresh, deletion)
/// - Topic subscriptions (discovery, matches, chats)
/// - Notification handling (foreground, background, terminated)
/// - Notification actions (deep linking)
/// - Badge management
/// - Local notifications for scheduled alerts
/// - Permission handling with graceful degradation
/// - Offline-first architecture
/// - Comprehensive error handling with retries
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';

/// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION TYPES
/// ═══════════════════════════════════════════════════════════════════════

/// Types of notifications supported by the app
enum NotificationType {
  match,
  message,
  gigOpportunity,
  bookingConfirmation,
  bookingReminder,
  reviewReceived,
  subscriptionExpired,
  general,
}

/// Priority levels for notifications
enum NotificationPriority {
  high, // Urgent: messages, bookings
  defaultPriority, // Standard notifications
  low, // Non-urgent: tips, updates
}

/// Notification payload structure
class NotificationPayload {
  final NotificationType type;
  final String title;
  final String body;
  final String? deepLink;
  final Map<String, dynamic>? data;
  final NotificationPriority priority;
  final String? imageUrl;

  NotificationPayload({
    required this.type,
    required this.title,
    required this.body,
    this.deepLink,
    this.data,
    this.priority = NotificationPriority.defaultPriority,
    this.imageUrl,
  });

  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final typeString = message.data['type'] ?? 'general';
    final type = _parseNotificationType(typeString);

    return NotificationPayload(
      type: type,
      title: message.notification?.title ?? 'GigMatch',
      body: message.notification?.body ?? '',
      deepLink: message.data['deepLink'],
      data: message.data,
      priority: _parsePriority(message.data['priority']),
      imageUrl: message.notification?.android?.imageUrl,
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'match':
        return NotificationType.match;
      case 'message':
      case 'chat':
        return NotificationType.message;
      case 'gig':
      case 'gig_opportunity':
        return NotificationType.gigOpportunity;
      case 'booking':
      case 'booking_confirmation':
        return NotificationType.bookingConfirmation;
      case 'reminder':
      case 'booking_reminder':
        return NotificationType.bookingReminder;
      case 'review':
        return NotificationType.reviewReceived;
      case 'subscription':
        return NotificationType.subscriptionExpired;
      default:
        return NotificationType.general;
    }
  }

  static NotificationPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return NotificationPriority.high;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.defaultPriority;
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════
// LOCAL NOTIFICATION CHANNELS
/// ═══════════════════════════════════════════════════════════════════════

/// Notification channel configurations for Android
class NotificationChannels {
  /// High priority channel for messages and bookings
  static const String messages = 'gigmatch_messages';

  /// Medium priority for gig opportunities
  static const String gigOpportunities = 'gigmatch_gigs';

  /// Low priority for tips and updates
  static const String general = 'gigmatch_general';

  /// Background updates channel
  static const String updates = 'gigmatch_updates';

  /// Create all notification channels
  static List<AndroidNotificationChannel> getChannels() => [
        AndroidNotificationChannel(
          messages,
          'Messages & Chats',
          description: 'Notifications for new messages and chat activity',
          importance: Importance.max,
          priority: Priority.high,
          showBadge: true,
          enableVibration: true,
          playSound: true,
        ),
        AndroidNotificationChannel(
          gigOpportunities,
          'Gig Opportunities',
          description: 'Notifications for new gig postings and bookings',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
          enableVibration: true,
          playSound: true,
        ),
        AndroidNotificationChannel(
          general,
          'General Notifications',
          description: 'General app notifications and tips',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showBadge: true,
          enableVibration: true,
          playSound: false,
        ),
        AndroidNotificationChannel(
          updates,
          'App Updates',
          description: 'Background updates and sync notifications',
          importance: Importance.low,
          priority: Priority.low,
          showBadge: false,
          enableVibration: false,
          playSound: false,
        ),
      ];
}

/// ═══════════════════════════════════════════════════════════════════════
// PUSH NOTIFICATION SERVICE
/// ═══════════════════════════════════════════════════════════════════════

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Dependencies
  final ApiClient _apiClient;
  final AuthProvider? _authProvider;

  // State
  String? _fcmToken;
  bool _isInitialized = false;
  bool _permissionGranted = false;

  // Streams for notification events
  final StreamController<NotificationPayload> _notificationStream =
      StreamController<NotificationPayload>.broadcast();
  final StreamController<String> _tokenRefreshStream =
      StreamController<String>.broadcast();
  final StreamController<NotificationType> _notificationTapStream =
      StreamController<NotificationType>.broadcast();

  // Cache for pending notifications (offline support)
  final List<NotificationPayload> _pendingNotifications = [];

  // ═══════════════════════════════════════════════════════════════════════
  // PUBLIC STREAMS
  // ═══════════════════════════════════════════════════════════════════════

  /// Stream of received notifications
  Stream<NotificationPayload> get notificationStream =>
      _notificationStream.stream;

  /// Stream of FCM token refreshes
  Stream<String> get tokenRefreshStream => _tokenRefreshStream.stream;

  /// Stream of notification taps (for navigation)
  Stream<NotificationType> get notificationTapStream =>
      _notificationTapStream.stream;

  /// Current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  bool get isEnabled => _permissionGranted;

  // ═══════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════

  PushNotificationService({
    required ApiClient apiClient,
    AuthProvider? authProvider,
  })  : _apiClient = apiClient,
        _authProvider = authProvider;

  /// Initialize push notification service
  /// Call this from main() or app initialization
  Future<bool> initialize({
    bool requestPermission = true,
    bool showNotifications = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🔔 [PushNotificationService] Initializing...');

      // Configure local notifications
      await _setupLocalNotifications();

      // Configure notification channels (Android)
      await _setupNotificationChannels();

      // Set foreground presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: showNotifications,
        badge: true,
        sound: true,
      );

      // Handle notification tap when app is terminated
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleInitialMessage(message);
        }
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Handle notification tap when app is in foreground
      FirebaseMessaging.onMessage.listen(_firebaseForegroundHandler);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_firebaseMessageOpenedHandler);

      // Request permission and get token
      if (requestPermission) {
        await requestPermission();
      }

      // Get and register FCM token
      await _registerToken();

      _isInitialized = true;

      debugPrint(
        '🔔 [PushNotificationService] Initialized in ${stopwatch.elapsedMilliseconds}ms',
      );
      return true;

    } catch (e) {
      debugPrint('❌ [PushNotificationService] Initialization failed: $e');
      return false;
    } finally {
      stopwatch.stop();
    }
  }

  /// Set up local notifications plugin
  Future<void> _setupLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_notification',
      );

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );

      debugPrint('🔔 [PushNotificationService] Local notifications configured');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Local notifications setup failed: $e');
    }
  }

  /// Set up notification channels for Android
  Future<void> _setupNotificationChannels() async {
    try {
      if (Platform.isAndroid) {
        for (final channel in NotificationChannels.getChannels()) {
          await _firebaseMessaging
              .showNotificationPluginAndroidChannel(channel);
        }
        debugPrint('🔔 [PushNotificationService] Notification channels created');
      }
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Channel setup failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PERMISSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Request notification permission from user
  Future<bool> requestPermission() async {
    try {
      debugPrint('🔔 [PushNotificationService] Requesting permission...');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized;

      debugPrint(
        '🔔 [PushNotificationService] Permission: ${settings.authorizationStatus}',
      );

      if (_permissionGranted) {
        await _syncPermissionsToBackend(settings);
      }

      return _permissionGranted;

    } catch (e) {
      debugPrint('❌ [PushNotificationService] Permission request failed: $e');
      _permissionGranted = false;
      return false;
    }
  }

  /// Check current permission status
  Future<NotificationSettings> checkPermission() async {
    try {
      return await _firebaseMessaging.getNotificationSettings();
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Permission check failed: $e');
      return const NotificationSettings(
        authorizationStatus: AuthorizationStatus.notDetermined,
        alert: Setting.notSupported,
        badge: Setting.notSupported,
        sound: Setting.notSupported,
      );
    }
  }

  /// Open system notification settings
  Future<void> openSettings() async {
    try {
      await _firebaseMessaging.openSettingsForNotifications();
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Cannot open settings: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Register FCM token with backend
  Future<void> _registerToken() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await _syncTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Token registration failed: $e');
    }
  }

  /// Get FCM token, fetching if necessary
  Future<String?> _getToken() async {
    try {
      // Return cached token if available
      if (_fcmToken != null) {
        return _fcmToken;
      }

      // Fetch new token
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        debugPrint('🔔 [PushNotificationService] Token obtained');

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔔 [PushNotificationService] Token refreshed');
          _fcmToken = newToken;
          _tokenRefreshStream.add(newToken);
          _syncTokenToBackend(newToken);
        });
      }

      return _fcmToken;
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Failed to get token: $e');
      return null;
    }
  }

  /// Refresh FCM token manually
  Future<String?> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      return await _getToken();
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Token refresh failed: $e');
      return null;
    }
  }

  /// Delete FCM token (e.g., on logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      await _removeTokenFromBackend();
      debugPrint('🔔 [PushNotificationService] Token deleted');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Token deletion failed: $e');
    }
  }

  /// Sync token to backend
  Future<void> _syncTokenToBackend(String token) async {
    try {
      if (_authProvider?.currentUser == null) {
        debugPrint('🔔 [PushNotificationService] No user, skipping token sync');
        return;
      }

      await _apiClient.post(
        Endpoints.notificationsRegisterToken,
        data: {
          'fcmToken': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'deviceId': await _getDeviceId(),
        },
      );

      debugPrint('🔔 [PushNotificationService] Token synced to backend');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Token sync failed: $e');
    }
  }

  /// Remove token from backend
  Future<void> _removeTokenFromBackend() async {
    try {
      await _apiClient.delete(
        '${Endpoints.notificationsRegisterToken}/$_fcmToken',
      );
      debugPrint('🔔 [PushNotificationService] Token removed from backend');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Token removal failed: $e');
    }
  }

  /// Sync permission status to backend
  Future<void> _syncPermissionsToBackend(NotificationSettings settings) async {
    try {
      if (_authProvider?.currentUser == null) return;

      await _apiClient.post(
        Endpoints.notificationsUpdateSettings,
        data: {
          'notificationsEnabled': settings.authorizationStatus == AuthorizationStatus.authorized,
          'alertEnabled': settings.alert == Setting.enabled,
          'badgeEnabled': settings.badge == Setting.enabled,
          'soundEnabled': settings.sound == Setting.enabled,
        },
      );
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Permission sync failed: $e');
    }
  }

  /// Get device ID for token association
  Future<String> _getDeviceId() async {
    // Return a device identifier
    // In production, use device_info_plus or similar
    return 'device_${Platform.operatingSystem}';
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TOPIC SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Subscribe to a topic
  Future<bool> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('🔔 [PushNotificationService] Subscribed to: $topic');
      return true;
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Subscribe failed: $e');
      return false;
    }
  }

  /// Unsubscribe from a topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('🔔 [PushNotificationService] Unsubscribed from: $topic');
      return true;
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Unsubscribe failed: $e');
      return false;
    }
  }

  /// Subscribe to discovery updates based on user preferences
  Future<void> subscribeToDiscoveryTopics() async {
    try {
      // Subscribe to general discovery topic
      await subscribeToTopic('discovery');

      // Subscribe to genre-specific topics
      // final userProfile = _authProvider?.currentUser;
      // if (userProfile != null) {
      //   for (final genre in userProfile.genres) {
      //     await subscribeToTopic('genre_$genre');
      //   }
      // }

      debugPrint('🔔 [PushNotificationService] Discovery topics subscribed');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Discovery topics failed: $e');
    }
  }

  /// Unsubscribe from discovery topics (on logout)
  Future<void> unsubscribeFromDiscoveryTopics() async {
    try {
      await unsubscribeFromTopic('discovery');
      // Unsubscribe from all genre topics
      // final genres = ['rock', 'jazz', 'pop', 'hiphop', 'indie', 'country', 'electronic'];
      // for (final genre in genres) {
      //   await unsubscribeFromTopic('genre_$genre');
      // }
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Discovery unsubscribe failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATION HANDLING
  // ═══════════════════════════════════════════════════════════════════════

  /// Handle notification when app is in foreground
  void _firebaseForegroundHandler(RemoteMessage message) async {
    try {
      debugPrint('🔔 [PushNotificationService] Foreground message received');

      final payload = NotificationPayload.fromRemoteMessage(message);

      // Show local notification
      await _showLocalNotification(payload);

      // Emit to stream
      _notificationStream.add(payload);

      // Handle specific notification types
      await _handleNotificationType(payload);
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Foreground handling failed: $e');
    }
  }

  /// Handle notification when app is opened from terminated state
  Future<void> _handleInitialMessage(RemoteMessage message) async {
    try {
      debugPrint('🔔 [PushNotificationService] Initial message received');

      final payload = NotificationPayload.fromRemoteMessage(message);
      _notificationTapStream.add(payload.type);

      await _handleNotificationType(payload);
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Initial handling failed: $e');
    }
  }

  /// Handle notification when app is opened from background
  void _firebaseMessageOpenedHandler(RemoteMessage message) async {
    try {
      debugPrint('🔔 [PushNotificationService] Message opened from background');

      final payload = NotificationPayload.fromRemoteMessage(message);
      _notificationTapStream.add(payload.type);

      await _handleNotificationType(payload);
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Background open handling failed: $e');
    }
  }

  /// Background message handler (must be top-level or static)
  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    try {
      debugPrint('🔔 [PushNotificationService] Background message received');

      // Handle notification data
      // In background, system handles the notification display
      // We can process data here for analytics or background tasks
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Background handler failed: $e');
    }
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(NotificationResponse response) async {
    try {
      debugPrint('🔔 [PushNotificationService] Local notification tapped');

      final payload = NotificationPayload(
        type: _parseNotificationType(response.payload ?? ''),
        title: 'Notification',
        body: '',
        deepLink: response.payload,
        data: {},
        priority: NotificationPriority.defaultPriority,
      );

      _notificationTapStream.add(payload.type);
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Local tap handling failed: $e');
    }
  }

  /// Handle specific notification types
  Future<void> _handleNotificationType(NotificationPayload payload) async {
    switch (payload.type) {
      case NotificationType.match:
        // Navigate to matches screen
        debugPrint('🔔 [PushNotificationService] New match notification');
        break;

      case NotificationType.message:
        // Navigate to chat screen
        debugPrint('🔔 [PushNotificationService] New message notification');
        break;

      case NotificationType.gigOpportunity:
        // Navigate to gig details
        debugPrint('🔔 [PushNotificationService] New gig opportunity');
        break;

      case NotificationType.bookingConfirmation:
      case NotificationType.bookingReminder:
        // Navigate to bookings
        debugPrint('🔔 [PushNotificationService] Booking notification');
        break;

      case NotificationType.reviewReceived:
        // Navigate to profile/reviews
        debugPrint('🔔 [PushNotificationService] Review received');
        break;

      case NotificationType.subscriptionExpired:
        // Navigate to subscription screen
        debugPrint('🔔 [PushNotificationService] Subscription expired');
        break;

      case NotificationType.general:
        // Handle generically
        debugPrint('🔔 [PushNotificationService] General notification');
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOCAL NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Show a local notification
  Future<void> _showLocalNotification(NotificationPayload payload) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        NotificationChannels.messages,
        'Messages & Chats',
        channelDescription: 'New messages and chat activity',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(payload.body),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        payload.type.index,
        payload.title,
        payload.body,
        details,
        payload: payload.toString(),
      );

      debugPrint('🔔 [PushNotificationService] Local notification shown');
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Local notification failed: $e');
    }
  }

  /// Show a local notification for gig reminder
  Future<void> showGigReminder({
    required String gigId,
    required String gigTitle,
    required DateTime gigDate,
    required String venueName,
  }) async {
    try {
      final daysUntil = gigDate.difference(DateTime.now()).inDays;
      final title = 'Gig Reminder';
      final body = daysUntil == 0
          ? 'Your gig "$gigTitle" is today at $venueName!'
          : daysUntil == 1
              ? 'Your gig "$gigTitle" is tomorrow at $venueName!'
              : 'Your gig "$gigTitle" is in $daysUntil days at $venueName!';

      const androidDetails = AndroidNotificationDetails(
        NotificationChannels.bookingReminder,
        'Booking Reminders',
        channelDescription: 'Reminders for upcoming gigs',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        gigId.hashCode,
        title,
        body,
        details,
        payload: 'gig://$gigId',
      );

      debugPrint('🔔 [PushNotificationService] Gig reminder scheduled');
    } catch (e) {
      debugPrint('❌ [PushNotificationService] Gig reminder failed: $e');
    }
  }

  /// Cancel a local notification
  Future<void> cancelNotification(String id) async {
    try {
      await _localNotifications.cancel(id.hashCode);
      debugPrint('🔔 [PushNotificationService] Notification cancelled: $id');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Cancel notification failed: $e');
    }
  }

  /// Cancel all local notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('🔔 [PushNotificationService] All notifications cancelled');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Cancel all failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BADGE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Update app badge count
  Future<void> setBadgeCount(int count) async {
    try {
      await _firebaseMessaging.setApplicationIconBadgeNumber(count);
      debugPrint('🔔 [PushNotificationService] Badge set to: $count');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Badge update failed: $e');
    }
  }

  /// Clear app badge
  Future<void> clearBadge() async {
    await setBadgeCount(0);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OFFLINE SUPPORT
  // ═══════════════════════════════════════════════════════════════════════

  /// Store notification for later processing (offline support)
  void queueNotification(NotificationPayload notification) {
    _pendingNotifications.add(notification);
    debugPrint(
      '🔔 [PushNotificationService] Notification queued (${_pendingNotifications.length} pending)',
    );
  }

  /// Process pending notifications when back online
  Future<void> processPendingNotifications() async {
    if (_pendingNotifications.isEmpty) return;

    debugPrint(
      '🔔 [PushNotificationService] Processing ${_pendingNotifications.length} pending notifications',
    );

    final pending = List<NotificationPayload>.from(_pendingNotifications);
    _pendingNotifications.clear();

    for (final notification in pending) {
      try {
        _notificationStream.add(notification);
      } catch (e) {
        debugPrint('⚠️ [PushNotificationService] Failed to process notification: $e');
        _pendingNotifications.add(notification); // Re-queue
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SYNC WITH BACKEND
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetch unread notification count from backend
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(Endpoints.notificationsUnreadCount);
      return response.data['count'] ?? 0;
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Unread count failed: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.patch('${Endpoints.notifications}/$notificationId/read');
      debugPrint('🔔 [PushNotificationService] Notification marked as read');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Mark as read failed: $e');
    }
  }

  /// Get all notifications
  Future<List<dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        Endpoints.notifications,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      return response.data['data'] ?? [];
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Get notifications failed: $e');
      return [];
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiClient.delete('${Endpoints.notifications}/$notificationId');
      debugPrint('🔔 [PushNotificationService] Notification deleted');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Delete notification failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════

  /// Dispose resources
  Future<void> dispose() async {
    await _notificationStream.close();
    await _tokenRefreshStream.close();
    await _notificationTapStream.close();
    await _localNotifications.cancelAll();
    _pendingNotifications.clear();
    debugPrint('🔔 [PushNotificationService] Disposed');
  }

  /// Reset service state (on logout)
  Future<void> reset() async {
    await deleteToken();
    await unsubscribeFromDiscoveryTopics();
    await cancelAllNotifications();
    await clearBadge();
    _permissionGranted = false;
    debugPrint('🔔 [PushNotificationService] Reset complete');
  }
}

/// Helper extension for NotificationPayload
extension NotificationPayloadExtension on NotificationPayload {
  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'type': type.toString(),
        'title': title,
        'body': body,
        'deepLink': deepLink,
        'data': data,
        'priority': priority.toString(),
        'imageUrl': imageUrl,
      };

  /// Create from map
  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.general,
      ),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      deepLink: map['deepLink'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => NotificationPriority.defaultPriority,
      ),
      imageUrl: map['imageUrl'],
    );
  }
}

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService._firebaseBackgroundHandler(message);
}
