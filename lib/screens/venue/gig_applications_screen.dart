/// 📋 Gig Applications Screen
///
/// Venue screen to manage applications for a specific gig.
/// Features:
/// - View all pending/accepted/rejected applications
/// - Accept application and create booking
/// - Decline applications with optional reason
/// - View artist details
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme.dart';
import '../../core/services/gigs_service.dart';
import '../../core/models/gig_models.dart';

class GigApplicationsScreen extends StatefulWidget {
  final String gigId;
  final String gigTitle;

  const GigApplicationsScreen({
    super.key,
    required this.gigId,
    required this.gigTitle,
  });

  @override
  State<GigApplicationsScreen> createState() => _GigApplicationsScreenState();
}

class _GigApplicationsScreenState extends State<GigApplicationsScreen> {
  final GigsService _gigsService = GigsService();

  bool _isLoading = true;
  List<VenueGigApplication> _applications = [];
  String? _error;
  String? _processingArtistId;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apps = await _gigsService.getGigApplications(widget.gigId);
      if (mounted) {
        setState(() {
          _applications = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptApplication(VenueGigApplication application) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show dialog to confirm booking details
    final result = await _showAcceptDialog(application);
    if (result == null) return;

    setState(() => _processingArtistId = application.artistId);
    HapticFeedback.mediumImpact();

    try {
      await _gigsService.acceptApplicationAndCreateBooking(
        gigId: widget.gigId,
        artistId: application.artistId,
        agreedAmount: result['agreedAmount'] as double,
        startTime: result['startTime'] as String,
        endTime: result['endTime'] as String?,
        specialRequests: result['specialRequests'] as String?,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${application.artistName} accepted! Booking created.'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      _loadApplications();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to accept: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingArtistId = null);
      }
    }
  }

  Future<Map<String, dynamic>?> _showAcceptDialog(VenueGigApplication application) async {
    final brightness = Theme.of(context).brightness;
    double agreedAmount = application.proposedRate ?? 0;
    String startTime = '20:00';

    final amountController = TextEditingController(
      text: agreedAmount > 0 ? agreedAmount.toStringAsFixed(0) : '',
    );
    final startTimeController = TextEditingController(text: startTime);
    final endTimeController = TextEditingController();
    final requestsController = TextEditingController();

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Accept Application',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: application.artistPhoto != null
                        ? CachedNetworkImageProvider(application.artistPhoto!)
                        : null,
                    child: application.artistPhoto == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.artistName,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (application.artistRating != null)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                application.artistRating!.toStringAsFixed(1),
                                style: TextStyle(
                                  color: AppColors.textSec(brightness),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Proposed rate display
              if (application.proposedRate != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'Proposed: \$${application.proposedRate!.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Agreed amount
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Agreed Amount (\$)',
                  labelStyle: TextStyle(color: AppColors.textSec(brightness)),
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Start time
              TextField(
                controller: startTimeController,
                decoration: InputDecoration(
                  labelText: 'Start Time (HH:MM)',
                  labelStyle: TextStyle(color: AppColors.textSec(brightness)),
                  prefixIcon: const Icon(Icons.schedule),
                  hintText: '20:00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // End time (optional)
              TextField(
                controller: endTimeController,
                decoration: InputDecoration(
                  labelText: 'End Time (optional)',
                  labelStyle: TextStyle(color: AppColors.textSec(brightness)),
                  prefixIcon: const Icon(Icons.schedule_outlined),
                  hintText: '23:00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Special requests
              TextField(
                controller: requestsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Special Requests (optional)',
                  labelStyle: TextStyle(color: AppColors.textSec(brightness)),
                  prefixIcon: const Icon(Icons.note_add),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a valid amount'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'agreedAmount': amount,
                'startTime': startTimeController.text.isNotEmpty
                    ? startTimeController.text
                    : '20:00',
                'endTime': endTimeController.text.isNotEmpty
                    ? endTimeController.text
                    : null,
                'specialRequests': requestsController.text.isNotEmpty
                    ? requestsController.text
                    : null,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Accept & Create Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _declineApplication(VenueGigApplication application) async {
    final brightness = Theme.of(context).brightness;
    final messenger = ScaffoldMessenger.of(context);
    String reason = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Decline Application',
          style: TextStyle(color: AppColors.text(brightness)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Decline application from ${application.artistName}?',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => reason = v,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingArtistId = application.artistId);
    HapticFeedback.lightImpact();

    try {
      await _gigsService.declineApplication(
        gigId: widget.gigId,
        artistId: application.artistId,
        reason: reason.isNotEmpty ? reason : null,
      );

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Application declined'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      _loadApplications();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingArtistId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applications',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.gigTitle,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.text(brightness)),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: _buildBody(brightness),
    );
  }

  Widget _buildBody(Brightness brightness) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load applications',
              style: TextStyle(color: AppColors.text(brightness)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadApplications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSec(brightness),
            ),
            const SizedBox(height: 16),
            Text(
              'No applications yet',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Artists will appear here when they apply',
              style: TextStyle(
                color: AppColors.textSec(brightness),
              ),
            ),
          ],
        ),
      );
    }

    // Group applications by status
    final pending = _applications.where((a) => a.status == GigApplicationStatus.pending).toList();
    final accepted = _applications.where((a) => a.status == GigApplicationStatus.accepted).toList();
    final rejected = _applications.where((a) => a.status == GigApplicationStatus.rejected).toList();

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats row
          Row(
            children: [
              _StatBadge(
                label: 'Pending',
                count: pending.length,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                label: 'Accepted',
                count: accepted.length,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                label: 'Declined',
                count: rejected.length,
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pending applications
          if (pending.isNotEmpty) ...[
            _SectionHeader(title: 'Pending (${pending.length})', brightness: brightness),
            ...pending.map((app) => _ApplicationCard(
              application: app,
              isProcessing: _processingArtistId == app.artistId,
              onAccept: () => _acceptApplication(app),
              onDecline: () => _declineApplication(app),
              brightness: brightness,
              showActions: true,
            )),
            const SizedBox(height: 24),
          ],

          // Accepted applications
          if (accepted.isNotEmpty) ...[
            _SectionHeader(title: 'Accepted (${accepted.length})', brightness: brightness),
            ...accepted.map((app) => _ApplicationCard(
              application: app,
              isProcessing: false,
              onAccept: null,
              onDecline: null,
              brightness: brightness,
              showActions: false,
            )),
            const SizedBox(height: 24),
          ],

          // Rejected applications
          if (rejected.isNotEmpty) ...[
            _SectionHeader(title: 'Declined (${rejected.length})', brightness: brightness),
            ...rejected.map((app) => _ApplicationCard(
              application: app,
              isProcessing: false,
              onAccept: null,
              onDecline: null,
              brightness: brightness,
              showActions: false,
            )),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Brightness brightness;

  const _SectionHeader({required this.title, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final VenueGigApplication application;
  final bool isProcessing;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final Brightness brightness;
  final bool showActions;

  const _ApplicationCard({
    required this.application,
    required this.isProcessing,
    required this.onAccept,
    required this.onDecline,
    required this.brightness,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: application.artistPhoto != null
                      ? CachedNetworkImageProvider(application.artistPhoto!)
                      : null,
                  backgroundColor: AppColors.crimson.withValues(alpha: 0.1),
                  child: application.artistPhoto == null
                      ? Icon(Icons.person, color: AppColors.crimson)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.artistName,
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (application.artistGenres.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: application.artistGenres
                                .take(3)
                                .map((g) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.crimson.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        g,
                                        style: TextStyle(
                                          color: AppColors.crimson,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                // Rating badge
                if (application.artistRating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          application.artistRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Message
            if (application.message != null && application.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background(brightness),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  application.message!,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            // Proposed rate & applied date
            const SizedBox(height: 12),
            Row(
              children: [
                if (application.proposedRate != null) ...[
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: AppColors.success,
                  ),
                  Text(
                    '\$${application.proposedRate!.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textSec(brightness),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, y').format(application.appliedAt),
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Actions
            if (showActions && onAccept != null && onDecline != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isProcessing ? null : onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.crimson,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Accept & Book'),
                    ),
                  ),
                ],
              ),
            ],

            // Status badge for non-pending
            if (!showActions) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(application.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  application.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(application.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(GigApplicationStatus status) {
    switch (status) {
      case GigApplicationStatus.pending:
        return Colors.amber;
      case GigApplicationStatus.accepted:
        return AppColors.success;
      case GigApplicationStatus.rejected:
        return AppColors.error;
      case GigApplicationStatus.withdrawn:
        return Colors.grey;
    }
  }
}
