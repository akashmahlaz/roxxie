/// 🧳 Venue Gigs Screen (Placeholder)
///
/// This is a temporary, production-quality placeholder for the Venue "Gigs" tab.
/// It gives you:
/// - A modern, clean scaffold with empty state
/// - Clear CTAs to "Create Gig" and "Manage Drafts"
/// - A consistent structure we’ll later wire to real backend endpoints:
///   - GET    /api/v1/gigs/mine
///   - POST   /api/v1/gigs
///
/// Note: We keep UI strictly venue-focused here. Artist "Calendar" will be in
/// a separate file to avoid mixing roles.
library;

import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class GigsScreen extends StatelessWidget {
  const GigsScreen({super.key});

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
          'Gigs',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Create gig',
            onPressed: () => _showComingSoon(context, 'Create Gig'),
            icon: Icon(Icons.add_rounded, color: AppColors.text(brightness)),
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

              // Sections (placeholder list)
              Expanded(
                child: _EmptyState(
                  brightness: brightness,
                  title: 'No gigs yet',
                  subtitle:
                      'Create your first gig to start receiving applications and matching with artists.',
                  primaryCtaLabel: 'Create gig',
                  onPrimaryCta: () => _showComingSoon(context, 'Create Gig'),
                  secondaryCtaLabel: 'How it works',
                  onSecondaryCta: () => _showComingSoon(context, 'How it works'),
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
              Icons.calendar_month_rounded,
              color: AppColors.crimson,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post gigs. Get applications.',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep everything organized: drafts, open gigs, and completed bookings.',
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

class _EmptyState extends StatelessWidget {
  final Brightness brightness;
  final String title;
  final String subtitle;
  final String primaryCtaLabel;
  final VoidCallback onPrimaryCta;
  final String secondaryCtaLabel;
  final VoidCallback onSecondaryCta;

  const _EmptyState({
    required this.brightness,
    required this.title,
    required this.subtitle,
    required this.primaryCtaLabel,
    required this.onPrimaryCta,
    required this.secondaryCtaLabel,
    required this.onSecondaryCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border(brightness).withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                child: Icon(
                  Icons.add_business_rounded,
                  color: AppColors.crimson,
                  size: 30,
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onPrimaryCta,
                  child: Text(
                    primaryCtaLabel,
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
                  onPressed: onSecondaryCta,
                  child: Text(
                    secondaryCtaLabel,
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
        ),
      ),
    );
  }
}
