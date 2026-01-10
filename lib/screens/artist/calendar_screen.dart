/// 📅 Artist Calendar Screen (Placeholder)
///
/// Purpose:
/// - Dedicated tab for managing availability (enterprise UX requirement)
/// - Shows upcoming gigs/bookings (later), and availability blocks
/// - Provides modern empty states and clear CTAs
///
/// This is a production-quality placeholder UI that we will later connect to:
/// - Artist availability endpoints (to be implemented/verified in backend)
/// - Booking state machine (requests → confirmed → completed)
///
/// Privacy:
/// - Exact coordinates are stored on backend, but we only display city/country
///   in UI (no lat/lng shown).
library;

import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class ArtistCalendarScreen extends StatelessWidget {
  const ArtistCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.background(brightness),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Calendar',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add availability',
            onPressed: () => _showComingSoon(context, 'Add availability'),
            icon: Icon(
              Icons.add_rounded,
              color: AppColors.text(brightness),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(brightness: brightness),
              const SizedBox(height: 16),

              // Placeholder sections
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _SectionTitle(
                      brightness: brightness,
                      title: 'Upcoming',
                      subtitle: 'Confirmed gigs and booking requests will appear here.',
                    ),
                    const SizedBox(height: 10),
                    _EmptyStateCard(
                      brightness: brightness,
                      icon: Icons.event_available_rounded,
                      title: 'No upcoming gigs yet',
                      subtitle:
                          'When venues book you, your confirmed gigs will show up here. Keep your availability updated to get booked faster.',
                      primaryLabel: 'Set availability',
                      onPrimary: () => _showComingSoon(context, 'Set availability'),
                      secondaryLabel: 'How booking works',
                      onSecondary: () => _showComingSoon(context, 'How booking works'),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(
                      brightness: brightness,
                      title: 'Availability',
                      subtitle: 'Your bookable time windows (visible to venues).',
                    ),
                    const SizedBox(height: 10),
                    _AvailabilityPlaceholderList(brightness: brightness),
                    const SizedBox(height: 12),
                    _ProTipCard(brightness: brightness),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final brightness = Theme.of(context).brightness;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming next.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardBackground(brightness),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Brightness brightness;
  const _HeaderCard({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(brightness),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppColors.crimson,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay bookable. Stay organized.',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set your availability so venues can confidently send booking requests.',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final Brightness brightness;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.brightness,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 12.5,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final Brightness brightness;
  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  const _EmptyStateCard({
    required this.brightness,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.crimson.withValues(alpha: 0.20),
                  AppColors.wine.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.crimson, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onPrimary,
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text(brightness),
                side: BorderSide(
                  color: AppColors.border(brightness).withValues(alpha: 0.9),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onSecondary,
              child: Text(
                secondaryLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(brightness),
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPlaceholderList extends StatelessWidget {
  final Brightness brightness;
  const _AvailabilityPlaceholderList({required this.brightness});

  @override
  Widget build(BuildContext context) {
    // Placeholder rows that demonstrate the intended layout:
    // - Day chip
    // - Time window
    // - Status pill
    return Column(
      children: const [
        _AvailabilityRow(
          dayLabel: 'Fri',
          dateLabel: 'This week',
          timeLabel: '7:00 PM – 11:00 PM',
          statusLabel: 'Available',
          statusType: _AvailabilityStatusType.available,
        ),
        SizedBox(height: 10),
        _AvailabilityRow(
          dayLabel: 'Sat',
          dateLabel: 'This week',
          timeLabel: '6:00 PM – 10:00 PM',
          statusLabel: 'Available',
          statusType: _AvailabilityStatusType.available,
        ),
        SizedBox(height: 10),
        _AvailabilityRow(
          dayLabel: 'Sun',
          dateLabel: 'This week',
          timeLabel: '—',
          statusLabel: 'Not set',
          statusType: _AvailabilityStatusType.unset,
        ),
      ],
    );
  }
}

enum _AvailabilityStatusType { available, unavailable, unset }

class _AvailabilityRow extends StatelessWidget {
  final String dayLabel;
  final String dateLabel;
  final String timeLabel;
  final String statusLabel;
  final _AvailabilityStatusType statusType;

  const _AvailabilityRow({
    required this.dayLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.statusLabel,
    required this.statusType,
  });

  Color _pillBg(Brightness b) {
    switch (statusType) {
      case _AvailabilityStatusType.available:
        return AppColors.crimson.withValues(alpha: b == Brightness.dark ? 0.16 : 0.12);
      case _AvailabilityStatusType.unavailable:
        return Colors.red.withValues(alpha: 0.12);
      case _AvailabilityStatusType.unset:
        return AppColors.border(b).withValues(alpha: 0.25);
    }
  }

  Color _pillFg(Brightness b) {
    switch (statusType) {
      case _AvailabilityStatusType.available:
        return AppColors.crimson;
      case _AvailabilityStatusType.unavailable:
        return Colors.redAccent;
      case _AvailabilityStatusType.unset:
        return AppColors.textSec(b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Edit availability is coming next.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.cardBackground(brightness),
          ),
        );
      },
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border(brightness).withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border(brightness).withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 10.5,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to edit',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _pillBg(brightness),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: _pillFg(brightness),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTert(brightness),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProTipCard extends StatelessWidget {
  final Brightness brightness;
  const _ProTipCard({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(brightness),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border(brightness).withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.wine.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.wine,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro tip',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Artists with updated availability get booked faster. Set recurring time windows for weekends.',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
