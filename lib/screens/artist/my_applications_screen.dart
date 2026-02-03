/// 📋 My Applications Screen
///
/// Artist screen to track their submitted gig applications.
/// Features:
/// - View all applications with status
/// - Filter by status (all, pending, accepted, declined)
/// - Withdraw pending applications
/// - Navigate to gig details
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme.dart';
import '../../core/services/gigs_service.dart';
import '../../core/models/gig_models.dart';
import '../gig_details_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final GigsService _gigsService = GigsService();

  late TabController _tabController;
  bool _isLoading = true;
  List<ArtistGigApplication> _applications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apps = await _gigsService.getMyApplications();
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

  List<ArtistGigApplication> _filteredApplications(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _applications;
      case 1:
        return _applications
            .where((a) => a.status == GigApplicationStatus.pending)
            .toList();
      case 2:
        return _applications
            .where((a) => a.status == GigApplicationStatus.accepted)
            .toList();
      case 3:
        return _applications
            .where((a) =>
                a.status == GigApplicationStatus.rejected ||
                a.status == GigApplicationStatus.withdrawn)
            .toList();
      default:
        return _applications;
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
        title: Text(
          'My Applications',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w700,
          ),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.crimson,
          labelColor: AppColors.crimson,
          unselectedLabelColor: AppColors.textSec(brightness),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'All (${_applications.length})'),
            Tab(
              text:
                  'Pending (${_applications.where((a) => a.status == GigApplicationStatus.pending).length})',
            ),
            Tab(
              text:
                  'Accepted (${_applications.where((a) => a.status == GigApplicationStatus.accepted).length})',
            ),
            Tab(text: 'Other'),
          ],
        ),
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

    return TabBarView(
      controller: _tabController,
      children: List.generate(4, (index) {
        final filtered = _filteredApplications(index);

        if (filtered.isEmpty) {
          return _EmptyState(
            tabIndex: index,
            brightness: brightness,
          );
        }

        return RefreshIndicator(
          onRefresh: _loadApplications,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _ApplicationCard(
              application: filtered[i],
              brightness: brightness,
              onTap: () => _navigateToGigDetails(filtered[i]),
            ),
          ),
        );
      }),
    );
  }

  void _navigateToGigDetails(ArtistGigApplication application) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GigDetailsScreen(gigId: application.gigId),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int tabIndex;
  final Brightness brightness;

  const _EmptyState({
    required this.tabIndex,
    required this.brightness,
  });

  String get _message {
    switch (tabIndex) {
      case 0:
        return 'No applications yet';
      case 1:
        return 'No pending applications';
      case 2:
        return 'No accepted applications';
      case 3:
        return 'No declined or withdrawn applications';
      default:
        return 'No applications';
    }
  }

  String get _subtitle {
    switch (tabIndex) {
      case 0:
        return 'Apply to gigs to see them here';
      case 1:
        return 'All your applications have been reviewed';
      case 2:
        return 'Keep applying to get accepted!';
      case 3:
        return "That's a good thing!";
      default:
        return '';
    }
  }

  IconData get _icon {
    switch (tabIndex) {
      case 0:
        return Icons.inbox_outlined;
      case 1:
        return Icons.hourglass_empty;
      case 2:
        return Icons.check_circle_outline;
      case 3:
        return Icons.remove_circle_outline;
      default:
        return Icons.inbox_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _icon,
            size: 64,
            color: AppColors.textSec(brightness),
          ),
          const SizedBox(height: 16),
          Text(
            _message,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            style: TextStyle(
              color: AppColors.textSec(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ArtistGigApplication application;
  final Brightness brightness;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.application,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              // Status badge & date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusBadge(status: application.status),
                  Text(
                    DateFormat('MMM d, y').format(application.appliedAt),
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Gig title
              Text(
                application.gigTitle,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Venue info
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: application.venueInfo.photo != null
                        ? NetworkImage(application.venueInfo.photo!)
                        : null,
                    backgroundColor: AppColors.crimson.withValues(alpha: 0.1),
                    child: application.venueInfo.photo == null
                        ? Icon(
                            Icons.business,
                            size: 14,
                            color: AppColors.crimson,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      application.venueInfo.name,
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Gig details row
              Row(
                children: [
                  // Date
                  _DetailChip(
                    icon: Icons.calendar_today,
                    text: DateFormat('MMM d').format(application.gigDate),
                    brightness: brightness,
                  ),
                  const SizedBox(width: 8),
                  // Location
                  if (application.venueInfo.location != null)
                    Expanded(
                      child: _DetailChip(
                        icon: Icons.location_on,
                        text: application.venueInfo.location!,
                        brightness: brightness,
                      ),
                    ),
                ],
              ),

              // My proposal
              if (application.proposedRate != null || 
                  (application.message != null && application.message!.isNotEmpty)) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background(brightness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Proposal',
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (application.proposedRate != null)
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: AppColors.crimson,
                            ),
                            Text(
                              '\$${application.proposedRate!.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.crimson,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      if (application.message != null && 
                          application.message!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          application.message!,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Booking info if accepted
              if (application.status == GigApplicationStatus.accepted && 
                  application.bookingId != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Booking Created',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.success,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],

              // Rejection reason
              if (application.status == GigApplicationStatus.rejected && 
                  application.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        application.rejectionReason!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final GigApplicationStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
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

  String get _label {
    switch (status) {
      case GigApplicationStatus.pending:
        return 'PENDING';
      case GigApplicationStatus.accepted:
        return 'ACCEPTED';
      case GigApplicationStatus.rejected:
        return 'DECLINED';
      case GigApplicationStatus.withdrawn:
        return 'WITHDRAWN';
    }
  }

  IconData get _icon {
    switch (status) {
      case GigApplicationStatus.pending:
        return Icons.hourglass_empty;
      case GigApplicationStatus.accepted:
        return Icons.check_circle;
      case GigApplicationStatus.rejected:
        return Icons.cancel;
      case GigApplicationStatus.withdrawn:
        return Icons.undo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Brightness brightness;

  const _DetailChip({
    required this.icon,
    required this.text,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background(brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textSec(brightness),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
