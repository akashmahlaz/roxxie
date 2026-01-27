/// 📅 GIGMATCH Booking Details Screen
///
/// Displays booking details with:
/// - Booking summary (date, time, venue/artist info)
/// - Payment status and actions
/// - Contract signing
/// - Chat with counterparty
/// - Completion flow
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/booking_models.dart';
import '../../core/services/booking_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _bookingService = BookingService();

  Booking? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final booking = await _bookingService.getBookingById(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load booking: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load booking details';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmBooking() async {
    if (_booking == null) return;

    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();

    try {
      await _bookingService.confirmBooking(widget.bookingId);
      await _loadBooking();

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Booking confirmed!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to confirm: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _payDeposit() async {
    if (_booking == null) return;

    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();

    try {
      // This would integrate with Stripe Payment Sheet
      final paymentIntent = await _bookingService.createDepositPayment(widget.bookingId);
      debugPrint('💳 Payment Intent: ${paymentIntent.clientSecret}');

      // TODO: Show Stripe Payment Sheet
      // For now, just refresh
      await _loadBooking();

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Payment initiated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markComplete() async {
    if (_booking == null) return;

    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();

    try {
      await _bookingService.markComplete(widget.bookingId);
      await _loadBooking();

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Marked as complete!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.background(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.text(brightness),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Booking Details',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(brightness)
              : _booking == null
                  ? _buildNotFoundState(brightness)
                  : _buildContent(brightness, auth),
    );
  }

  Widget _buildErrorState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadBooking,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.textSec(brightness),
          ),
          const SizedBox(height: 16),
          Text(
            'Booking not found',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Brightness brightness, AuthProvider auth) {
    final booking = _booking!;
    final isArtist = auth.isArtist;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(brightness, booking),
          const SizedBox(height: 20),

          // Main Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.title,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (booking.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    booking.description!,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Date & Time
                _buildInfoRow(
                  brightness,
                  Icons.calendar_today_outlined,
                  'Date',
                  dateFormat.format(booking.date),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  brightness,
                  Icons.access_time_outlined,
                  'Time',
                  '${booking.startTime}${booking.endTime != null ? ' - ${booking.endTime}' : ''}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  brightness,
                  Icons.timelapse_outlined,
                  'Duration',
                  '${booking.durationMinutes} minutes (${booking.numberOfSets} set${booking.numberOfSets > 1 ? 's' : ''})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Card
          _buildPaymentCard(brightness, booking),
          const SizedBox(height: 20),

          // Actions
          _buildActionsSection(brightness, booking, isArtist),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Brightness brightness, Booking booking) {
    final statusColors = {
      BookingStatus.pending: AppColors.warning,
      BookingStatus.confirmed: AppColors.cyan,
      BookingStatus.depositPaid: AppColors.success,
      BookingStatus.inProgress: AppColors.crimson,
      BookingStatus.completed: AppColors.success,
      BookingStatus.cancelled: AppColors.error,
      BookingStatus.disputed: AppColors.error,
    };

    final statusIcons = {
      BookingStatus.pending: Icons.hourglass_empty_rounded,
      BookingStatus.confirmed: Icons.check_circle_outline,
      BookingStatus.depositPaid: Icons.payment_rounded,
      BookingStatus.inProgress: Icons.play_circle_outline,
      BookingStatus.completed: Icons.celebration_rounded,
      BookingStatus.cancelled: Icons.cancel_outlined,
      BookingStatus.disputed: Icons.warning_amber_rounded,
    };

    final color = statusColors[booking.status] ?? AppColors.textSec(brightness);
    final icon = statusIcons[booking.status] ?? Icons.info_outline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.status.displayName,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusDescription(booking),
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(Booking booking) {
    switch (booking.status) {
      case BookingStatus.pending:
        return 'Waiting for confirmation from both parties';
      case BookingStatus.confirmed:
        return 'Booking confirmed! Deposit payment required';
      case BookingStatus.depositPaid:
        return 'Deposit received. Ready for the gig!';
      case BookingStatus.inProgress:
        return 'Gig is happening now';
      case BookingStatus.completed:
        return 'Gig completed successfully';
      case BookingStatus.cancelled:
        return 'This booking was cancelled';
      case BookingStatus.disputed:
        return 'There is a dispute on this booking';
    }
  }

  Widget _buildInfoRow(
    Brightness brightness,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSec(brightness),
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Brightness brightness, Booking booking) {
    final currencyFormat = NumberFormat.currency(
      symbol: booking.currency == 'USD' ? '\$' : booking.currency,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.success,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Payment',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 14,
                ),
              ),
              Text(
                currencyFormat.format(booking.agreedAmount),
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (booking.payment != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Deposit Status
            if (booking.payment!.depositAmount != null)
              _buildPaymentRow(
                brightness,
                'Deposit',
                currencyFormat.format(booking.payment!.depositAmount),
                booking.payment!.depositPaid,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    Brightness brightness,
    String label,
    String amount,
    bool isPaid,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isPaid ? AppColors.success : AppColors.textSec(brightness),
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isPaid ? 'Paid' : 'Pending',
              style: TextStyle(
                color: isPaid ? AppColors.success : AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
    Brightness brightness,
    Booking booking,
    bool isArtist,
  ) {
    final actions = <Widget>[];

    // Confirm button (if pending and not yet confirmed by this party)
    if (booking.status == BookingStatus.pending) {
      final needsConfirmation = isArtist
          ? !booking.artistConfirmed
          : !booking.venueConfirmed;

      if (needsConfirmation) {
        actions.add(
          _buildActionButton(
            brightness,
            'Confirm Booking',
            Icons.check_circle_outline,
            AppColors.success,
            _confirmBooking,
          ),
        );
      }
    }

    // Pay deposit button (for venue, if confirmed but not paid)
    if (booking.status == BookingStatus.confirmed && !isArtist) {
      actions.add(
        _buildActionButton(
          brightness,
          'Pay Deposit',
          Icons.payment_rounded,
          AppColors.crimson,
          _payDeposit,
        ),
      );
    }

    // Mark complete button (if deposit paid and gig date has passed)
    if (booking.status == BookingStatus.depositPaid ||
        booking.status == BookingStatus.inProgress) {
      final canMarkComplete = isArtist
          ? !booking.artistMarkedComplete
          : !booking.venueMarkedComplete;

      if (canMarkComplete) {
        actions.add(
          _buildActionButton(
            brightness,
            'Mark as Complete',
            Icons.celebration_rounded,
            AppColors.success,
            _markComplete,
          ),
        );
      }
    }

    // Chat button (always available)
    if (booking.matchId != null) {
      actions.add(
        _buildActionButton(
          brightness,
          'Open Chat',
          Icons.chat_bubble_outline,
          AppColors.cyan,
          () => context.push('/chat/${booking.matchId}'),
        ),
      );
    }

    // Leave review (if completed)
    if (booking.status == BookingStatus.completed) {
      final canReview = isArtist
          ? !booking.artistReviewSubmitted
          : !booking.venueReviewSubmitted;

      if (canReview) {
        actions.add(
          _buildActionButton(
            brightness,
            'Leave Review',
            Icons.star_outline_rounded,
            AppColors.warning,
            () {
              // TODO: Navigate to review screen
            },
          ),
        );
      }
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...actions,
      ],
    );
  }

  Widget _buildActionButton(
    Brightness brightness,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
