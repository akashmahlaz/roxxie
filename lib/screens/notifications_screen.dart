/// 🔔 GIGMATCH Notifications Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass notification cards
/// - Animated notification badges
/// - Pull-to-refresh with shimmer loading
/// - Swipe-to-dismiss with haptic feedback
/// - Grouped by date with smart headers
/// - REAL API integration
///
/// All user notifications in one place
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../core/services/services.dart';
import '../widgets/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationHistoryService _notificationService =
      NotificationHistoryService();

  bool _isLoading = true;
  // ignore: unused_field
  String? _errorMessage;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _notificationService.getNotifications(limit: 50);

      setState(() {
        _notifications = response.notifications
            .map(
              (n) => NotificationItem(
                id: n.id,
                type: _mapNotificationType(n.type),
                title: n.title,
                message: n.body,
                timestamp: n.createdAt,
                isRead: n.isRead,
                data: n.data,
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      // Fall back to empty list on error
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  /// Map backend notification type strings to local NotificationType enum
  NotificationType _mapNotificationType(String type) {
    switch (type.toLowerCase()) {
      // Match notifications
      case 'match':
        return NotificationType.match;
      
      // Message/Chat notifications
      case 'message':
      case 'chat':
        return NotificationType.message;
      
      // Gig notifications
      case 'gig':
      case 'gig_opportunity':
      case 'gigopportunity':
      case 'gig_reminder':
      case 'gig_cancelled':
      case 'gig_confirmation':
        return NotificationType.gig;
      
      // Booking notifications (map to gig type for display)
      case 'booking_confirmation':
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_declined':
        return NotificationType.gig;
      
      // Profile notifications
      case 'profile':
      case 'profile_view':
        return NotificationType.profile;
      
      // Boost notifications
      case 'boost':
        return NotificationType.boost;
      
      // Payment notifications
      case 'payment':
      case 'payment_received':
        return NotificationType.payment;
      
      // Review notifications (map to profile type)
      case 'review_received':
        return NotificationType.profile;
      
      // System notifications (map to gig as fallback)
      case 'system':
      default:
        return NotificationType.gig;
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await _loadNotifications();
  }

  void _navigateFromNotification(NotificationItem notification) {
    final data = notification.data;
    final nav = Navigator.of(context, rootNavigator: true);

    switch (notification.type) {
      case NotificationType.message:
        // Navigate to chat
        final matchId = data?['matchId'] ?? data?['conversationId'];
        if (matchId != null && matchId.isNotEmpty) {
          nav.pushNamed('/chat/$matchId');
        }
        break;

      case NotificationType.match:
        // Navigate to matches or chat
        final matchId = data?['matchId'];
        if (matchId != null && matchId.isNotEmpty) {
          nav.pushNamed('/chat/$matchId');
        } else {
          nav.pushNamed('/messages');
        }
        break;

      case NotificationType.gig:
        // Navigate to gig details
        final gigId = data?['gigId'] ?? data?['gig'];
        if (gigId != null && gigId.isNotEmpty) {
          nav.pushNamed('/gig/$gigId');
        }
        break;

      case NotificationType.profile:
        // Navigate to profile
        final profileId = data?['profileId'] ?? data?['userId'];
        final isArtist = data?['isArtist'] == true;
        if (profileId != null && profileId.isNotEmpty) {
          final route = isArtist ? '/artist/$profileId' : '/venue/$profileId';
          nav.pushNamed(route);
        }
        break;

      case NotificationType.boost:
      case NotificationType.payment:
        // Navigate to wallet
        nav.pushNamed('/wallet');
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    HapticFeedback.selectionClick();

    try {
      await _notificationService.markAllAsRead();
      setState(() {
        for (var notification in _notifications) {
          notification.isRead = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications marked as read'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to mark as read'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _dismissNotification(NotificationItem notification) async {
    HapticFeedback.lightImpact();

    try {
      await _notificationService.deleteNotification(notification.id);
      setState(() {
        _notifications.remove(notification);
      });
    } catch (e) {
      debugPrint('Failed to delete notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        leading: const GlassBackButton(),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            AnimatedTapFeedback(
              onTap: _markAllAsRead,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Center(
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const _NotificationSkeletonList()
          : _notifications.isEmpty
          ? _buildEmptyState(brightness)
          : RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.crimson,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final showDateHeader =
                      index == 0 ||
                      !_isSameDay(
                        notification.timestamp,
                        _notifications[index - 1].timestamp,
                      );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDateHeader)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            _formatDateHeader(notification.timestamp),
                            style: TextStyle(
                              color: AppColors.textSec(brightness),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => _dismissNotification(notification),
                        child: _NotificationCard(
                          notification: notification,
                          brightness: brightness,
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            setState(() => notification.isRead = true);
                            
                            // Mark as read in backend
                            try {
                              await _notificationService.markAsRead(notification.id);
                            } catch (e) {
                              debugPrint('Failed to mark notification as read: $e');
                            }
                            
                            _navigateFromNotification(notification);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: AppColors.crimson,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something\nimportant happens',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (_isSameDay(timestamp, now)) {
      return 'Today';
    } else if (_isSameDay(timestamp, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📦 NOTIFICATION CARD
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final Brightness brightness;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface(brightness)
              : AppColors.crimson.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border(brightness)
                : AppColors.crimson.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getIconGradient(notification.type),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(notification.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.crimson,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      color: AppColors.textTert(brightness),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    return switch (type) {
      NotificationType.match => Icons.favorite_rounded,
      NotificationType.message => Icons.chat_bubble_rounded,
      NotificationType.gig => Icons.event_rounded,
      NotificationType.profile => Icons.visibility_rounded,
      NotificationType.boost => Icons.rocket_launch_rounded,
      NotificationType.payment => Icons.payments_rounded,
    };
  }

  List<Color> _getIconGradient(NotificationType type) {
    return switch (type) {
      NotificationType.match => [AppColors.crimson, const Color(0xFFFF6B6B)],
      NotificationType.message => [Colors.blue, Colors.lightBlue],
      NotificationType.gig => [Colors.orange, Colors.amber],
      NotificationType.profile => [Colors.purple, Colors.purpleAccent],
      NotificationType.boost => [Colors.deepPurple, Colors.purple],
      NotificationType.payment => [Colors.green, Colors.lightGreen],
    };
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💀 SKELETON LOADING
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationSkeletonList extends StatelessWidget {
  const _NotificationSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6,
        itemBuilder: (_, index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 44, height: 44, borderRadius: 12),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: 8),
                    SkeletonBox(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 60, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📊 MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum NotificationType { match, message, gig, profile, boost, payment }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.data,
  });
}
