/// 📋 Booking Requests Screen — Enterprise Edition
///
/// 2026 Design Principles Applied:
/// - Swipe-to-action cards (accept/decline)
/// - Real-time status updates with optimistic UI
/// - Liquid Glass request cards
/// - Tab-based organization (Incoming/Outgoing/History)
/// - Quick response with pre-built messages
/// - Timeline view for booking history
/// - Push notifications integration ready
///
/// Comprehensive booking management for artists and venues
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

enum RequestStatus { pending, accepted, declined, cancelled, completed }

enum RequestTab { incoming, outgoing, history }

class BookingRequest {
  final String id;
  final String gigTitle;
  final DateTime gigDate;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final double payment;
  final String senderName;
  final String senderImage;
  final String senderId;
  final String venueName;
  final String venueLocation;
  final RequestStatus status;
  final DateTime sentAt;
  final String? message;
  final bool isIncoming;

  const BookingRequest({
    required this.id,
    required this.gigTitle,
    required this.gigDate,
    required this.startTime,
    this.endTime,
    required this.payment,
    required this.senderName,
    required this.senderImage,
    required this.senderId,
    required this.venueName,
    required this.venueLocation,
    required this.status,
    required this.sentAt,
    this.message,
    required this.isIncoming,
  });

  BookingRequest copyWith({RequestStatus? status}) {
    return BookingRequest(
      id: id,
      gigTitle: gigTitle,
      gigDate: gigDate,
      startTime: startTime,
      endTime: endTime,
      payment: payment,
      senderName: senderName,
      senderImage: senderImage,
      senderId: senderId,
      venueName: venueName,
      venueLocation: venueLocation,
      status: status ?? this.status,
      sentAt: sentAt,
      message: message,
      isIncoming: isIncoming,
    );
  }
}

class BookingRequestsScreen extends StatefulWidget {
  final bool isArtist;

  const BookingRequestsScreen({super.key, this.isArtist = true});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<BookingRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _requests = [
        // Incoming pending
        BookingRequest(
          id: '1',
          gigTitle: 'Friday Night Jazz Session',
          gigDate: DateTime.now().add(const Duration(days: 5)),
          startTime: const TimeOfDay(hour: 20, minute: 0),
          endTime: const TimeOfDay(hour: 23, minute: 30),
          payment: 450,
          senderName: 'Blue Note NYC',
          senderImage: 'https://i.pravatar.cc/150?img=65',
          senderId: 'venue1',
          venueName: 'Blue Note NYC',
          venueLocation: 'Greenwich Village, NYC',
          status: RequestStatus.pending,
          sentAt: DateTime.now().subtract(const Duration(hours: 2)),
          message: 'We loved your demo reel! Would you be available for our Friday jazz night?',
          isIncoming: true,
        ),
        BookingRequest(
          id: '2',
          gigTitle: 'Saturday Rock Night',
          gigDate: DateTime.now().add(const Duration(days: 8)),
          startTime: const TimeOfDay(hour: 21, minute: 0),
          endTime: const TimeOfDay(hour: 1, minute: 0),
          payment: 600,
          senderName: 'The Bowery Ballroom',
          senderImage: 'https://i.pravatar.cc/150?img=52',
          senderId: 'venue2',
          venueName: 'The Bowery Ballroom',
          venueLocation: 'Lower East Side, NYC',
          status: RequestStatus.pending,
          sentAt: DateTime.now().subtract(const Duration(days: 1)),
          message: 'Your band would be perfect for our Saturday special!',
          isIncoming: true,
        ),
        // Outgoing pending
        BookingRequest(
          id: '3',
          gigTitle: 'Sunday Brunch Session',
          gigDate: DateTime.now().add(const Duration(days: 3)),
          startTime: const TimeOfDay(hour: 11, minute: 0),
          endTime: const TimeOfDay(hour: 14, minute: 0),
          payment: 250,
          senderName: 'The Garden Café',
          senderImage: 'https://i.pravatar.cc/150?img=43',
          senderId: 'venue3',
          venueName: 'The Garden Café',
          venueLocation: 'Upper West Side, NYC',
          status: RequestStatus.pending,
          sentAt: DateTime.now().subtract(const Duration(days: 2)),
          message: 'I\'d love to perform at your Sunday brunch!',
          isIncoming: false,
        ),
        // Accepted
        BookingRequest(
          id: '4',
          gigTitle: 'Corporate Holiday Party',
          gigDate: DateTime.now().add(const Duration(days: 12)),
          startTime: const TimeOfDay(hour: 19, minute: 0),
          endTime: const TimeOfDay(hour: 22, minute: 0),
          payment: 800,
          senderName: 'Grand Hyatt NYC',
          senderImage: 'https://i.pravatar.cc/150?img=67',
          senderId: 'venue4',
          venueName: 'Grand Hyatt NYC',
          venueLocation: 'Midtown, NYC',
          status: RequestStatus.accepted,
          sentAt: DateTime.now().subtract(const Duration(days: 5)),
          isIncoming: true,
        ),
        // Completed
        BookingRequest(
          id: '5',
          gigTitle: 'Last Saturday Jazz Night',
          gigDate: DateTime.now().subtract(const Duration(days: 7)),
          startTime: const TimeOfDay(hour: 20, minute: 0),
          endTime: const TimeOfDay(hour: 23, minute: 0),
          payment: 400,
          senderName: 'Village Vanguard',
          senderImage: 'https://i.pravatar.cc/150?img=59',
          senderId: 'venue5',
          venueName: 'Village Vanguard',
          venueLocation: 'Greenwich Village, NYC',
          status: RequestStatus.completed,
          sentAt: DateTime.now().subtract(const Duration(days: 14)),
          isIncoming: true,
        ),
        // Declined
        BookingRequest(
          id: '6',
          gigTitle: 'Open Mic Night',
          gigDate: DateTime.now().add(const Duration(days: 2)),
          startTime: const TimeOfDay(hour: 19, minute: 0),
          payment: 150,
          senderName: 'Coffee House',
          senderImage: 'https://i.pravatar.cc/150?img=38',
          senderId: 'venue6',
          venueName: 'Coffee House',
          venueLocation: 'Brooklyn, NYC',
          status: RequestStatus.declined,
          sentAt: DateTime.now().subtract(const Duration(days: 3)),
          isIncoming: false,
        ),
      ];
      _isLoading = false;
    });
  }

  List<BookingRequest> get _incomingRequests =>
      _requests.where((r) => r.isIncoming && r.status == RequestStatus.pending).toList();

  List<BookingRequest> get _outgoingRequests =>
      _requests.where((r) => !r.isIncoming && r.status == RequestStatus.pending).toList();

  List<BookingRequest> get _historyRequests =>
      _requests.where((r) => r.status != RequestStatus.pending).toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

  void _acceptRequest(BookingRequest request) {
    HapticFeedback.mediumImpact();
    setState(() {
      final index = _requests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _requests[index] = request.copyWith(status: RequestStatus.accepted);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const AnimatedSuccessCheck(size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Booking accepted! ${request.senderName} has been notified.'),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _declineRequest(BookingRequest request) {
    HapticFeedback.mediumImpact();
    _showDeclineDialog(request);
  }

  void _showDeclineDialog(BookingRequest request) {
    final brightness = Theme.of(context).brightness;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Decline Request?',
          style: TextStyle(color: AppColors.text(brightness)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like to send a message to ${request.senderName}?',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
            const SizedBox(height: 16),
            _QuickResponseButton(
              text: 'Thanks, but I\'m not available',
              onTap: () => _performDecline(request, 'Thanks for reaching out, but I\'m not available for this date.'),
              brightness: brightness,
            ),
            const SizedBox(height: 8),
            _QuickResponseButton(
              text: 'Schedule conflict',
              onTap: () => _performDecline(request, 'Unfortunately, I have a scheduling conflict.'),
              brightness: brightness,
            ),
            const SizedBox(height: 8),
            _QuickResponseButton(
              text: 'Decline without message',
              onTap: () => _performDecline(request, null),
              brightness: brightness,
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  void _performDecline(BookingRequest request, String? message) {
    Navigator.pop(context);
    setState(() {
      final index = _requests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _requests[index] = request.copyWith(status: RequestStatus.declined);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request declined${message != null ? ' with message' : ''}'),
        backgroundColor: AppColors.textSec(Theme.of(context).brightness),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: _isLoading
          ? _buildSkeleton(brightness)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(_incomingRequests, RequestTab.incoming, brightness),
                _buildRequestList(_outgoingRequests, RequestTab.outgoing, brightness),
                _buildRequestList(_historyRequests, RequestTab.history, brightness),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
    return AppBar(
      backgroundColor: AppColors.surface(brightness),
      elevation: 0,
      centerTitle: false,
      leading: const GlassBackButton(),
      title: Text(
        'Booking Requests',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.crimson,
          unselectedLabelColor: AppColors.textSec(brightness),
          indicatorColor: AppColors.crimson,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Incoming'),
                  if (_incomingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_incomingRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Outgoing (${_outgoingRequests.length})'),
            const Tab(text: 'History'),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(Brightness brightness) {
    return ShimmerBase(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList(List<BookingRequest> requests, RequestTab tab, Brightness brightness) {
    if (requests.isEmpty) {
      return _buildEmptyState(tab, brightness);
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: AppColors.crimson,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: tab == RequestTab.incoming
                ? _SwipeableRequestCard(
                    request: request,
                    brightness: brightness,
                    onAccept: () => _acceptRequest(request),
                    onDecline: () => _declineRequest(request),
                    onTap: () => _showRequestDetails(request),
                  )
                : _RequestCard(
                    request: request,
                    brightness: brightness,
                    onTap: () => _showRequestDetails(request),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(RequestTab tab, Brightness brightness) {
    final config = _getEmptyStateConfig(tab);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.crimson.withValues(alpha: 0.15),
                    AppColors.wine.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                config['icon'] as IconData,
                color: AppColors.crimson,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              config['title'] as String,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              config['subtitle'] as String,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getEmptyStateConfig(RequestTab tab) {
    switch (tab) {
      case RequestTab.incoming:
        return {
          'icon': Icons.inbox_rounded,
          'title': 'No Incoming Requests',
          'subtitle': widget.isArtist
              ? 'When venues want to book you, their requests will appear here.'
              : 'Artist applications to your gigs will appear here.',
        };
      case RequestTab.outgoing:
        return {
          'icon': Icons.send_rounded,
          'title': 'No Outgoing Requests',
          'subtitle': widget.isArtist
              ? 'Apply to gigs to see your pending requests here.'
              : 'Send booking requests to artists to see them here.',
        };
      case RequestTab.history:
        return {
          'icon': Icons.history_rounded,
          'title': 'No History Yet',
          'subtitle': 'Your accepted, declined, and completed bookings will appear here.',
        };
    }
  }

  void _showRequestDetails(BookingRequest request) {
    HapticFeedback.lightImpact();
    final brightness = Theme.of(context).brightness;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(request.senderImage),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.senderName,
                                style: TextStyle(
                                  color: AppColors.text(brightness),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: AppColors.textSec(brightness),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.venueLocation,
                                    style: TextStyle(
                                      color: AppColors.textSec(brightness),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(request.status, brightness),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Gig details
                    LiquidGlassContainer(
                      borderRadius: 16,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.gigTitle,
                              style: TextStyle(
                                color: AppColors.text(brightness),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.calendar_today_rounded,
                              _formatDate(request.gigDate),
                              brightness,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.access_time_rounded,
                              _formatTimeRange(request.startTime, request.endTime),
                              brightness,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.attach_money_rounded,
                              '\$${request.payment.toStringAsFixed(0)}',
                              brightness,
                              highlight: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (request.message != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Message',
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background(brightness),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          request.message!,
                          style: TextStyle(
                            color: AppColors.textSec(brightness),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],

                    // Actions
                    if (request.status == RequestStatus.pending && request.isIncoming) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _declineRequest(request);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Decline',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: GradientButton(
                              text: 'Accept',
                              onPressed: () {
                                Navigator.pop(context);
                                _acceptRequest(request);
                              },
                              icon: Icons.check_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Brightness brightness, {bool highlight = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: highlight ? AppColors.success : AppColors.textSec(brightness),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: highlight ? AppColors.success : AppColors.text(brightness),
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(RequestStatus status, Brightness brightness) {
    Color color;
    String label;

    switch (status) {
      case RequestStatus.pending:
        color = AppColors.warning;
        label = 'Pending';
        break;
      case RequestStatus.accepted:
        color = AppColors.success;
        label = 'Accepted';
        break;
      case RequestStatus.declined:
        color = AppColors.error;
        label = 'Declined';
        break;
      case RequestStatus.cancelled:
        color = AppColors.textSec(brightness);
        label = 'Cancelled';
        break;
      case RequestStatus.completed:
        color = AppColors.info;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTimeRange(TimeOfDay start, TimeOfDay? end) {
    String format(TimeOfDay t) {
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:${t.minute.toString().padLeft(2, '0')} $period';
    }
    if (end != null) {
      return '${format(start)} - ${format(end)}';
    }
    return format(start);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SWIPEABLE REQUEST CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _SwipeableRequestCard extends StatefulWidget {
  final BookingRequest request;
  final Brightness brightness;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  const _SwipeableRequestCard({
    required this.request,
    required this.brightness,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });

  @override
  State<_SwipeableRequestCard> createState() => _SwipeableRequestCardState();
}

class _SwipeableRequestCardState extends State<_SwipeableRequestCard> {
  double _dragOffset = 0;
  final double _threshold = 80;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-_threshold * 1.5, _threshold * 1.5);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset > _threshold) {
      widget.onAccept();
    } else if (_dragOffset < -_threshold) {
      widget.onDecline();
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset / _threshold).clamp(-1.0, 1.0);

    return Stack(
      children: [
        // Background indicators
        Positioned.fill(
          child: Row(
            children: [
              // Accept indicator (left swipe reveals right side)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: progress > 0 ? progress * 0.3 : 0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: AnimatedOpacity(
                    opacity: progress > 0.3 ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Accept',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Decline indicator
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: progress < 0 ? -progress * 0.3 : 0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: AnimatedOpacity(
                    opacity: progress < -0.3 ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Decline',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.cancel_rounded, color: AppColors.error, size: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main card
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: _RequestCard(
              request: widget.request,
              brightness: widget.brightness,
              onTap: widget.onTap,
              showActions: true,
              onAccept: widget.onAccept,
              onDecline: widget.onDecline,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REQUEST CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _RequestCard extends StatelessWidget {
  final BookingRequest request;
  final Brightness brightness;
  final VoidCallback onTap;
  final bool showActions;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _RequestCard({
    required this.request,
    required this.brightness,
    required this.onTap,
    this.showActions = false,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: onTap,
      child: LiquidGlassContainer(
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(request.senderImage),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.senderName,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _timeAgo(request.sentAt),
                          style: TextStyle(
                            color: AppColors.textSec(brightness),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${request.payment.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Gig info
              Text(
                request.gigTitle,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSec(brightness)),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(request.gigDate),
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSec(brightness)),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(request.startTime),
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // Message preview
              if (request.message != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background(brightness),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    request.message!,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // Quick actions
              if (showActions && request.status == RequestStatus.pending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedTapFeedback(
                        onTap: onDecline ?? () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                              const SizedBox(width: 6),
                              Text(
                                'Decline',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: AnimatedTapFeedback(
                        onTap: onAccept ?? () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.success, Color(0xFF4ADE80)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 18, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Accept',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// QUICK RESPONSE BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickResponseButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Brightness brightness;
  final bool isOutlined;

  const _QuickResponseButton({
    required this.text,
    required this.onTap,
    required this.brightness,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : AppColors.background(brightness),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
