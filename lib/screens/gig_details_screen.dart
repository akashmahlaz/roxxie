/// 🎫 GIGMATCH Gig Details Screen
///
/// 2026 Design Principles Applied:
/// - Hero image with liquid glass overlay
/// - Micro-interactions on all buttons
/// - Optimistic booking state
/// - Animated countdown timer
/// - Rich media gallery
///
/// Complete gig/booking details with actions
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

class GigDetailsScreen extends StatefulWidget {
  final String? gigId;
  
  const GigDetailsScreen({super.key, this.gigId});

  @override
  State<GigDetailsScreen> createState() => _GigDetailsScreenState();
}

class _GigDetailsScreenState extends State<GigDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  bool _isAccepted = false;

  // Mock data - would come from provider
  final _gig = GigDetails(
    id: '1',
    venueName: 'The Velvet Lounge',
    venueImage: '',
    location: '123 Jazz Street, Downtown',
    date: DateTime.now().add(const Duration(days: 3)),
    startTime: '8:00 PM',
    endTime: '11:00 PM',
    genre: 'Jazz / Soul',
    payment: 350,
    description: 'Looking for a talented jazz performer for our Saturday night showcase. We have a grand piano and professional sound system. House is usually packed with 150+ guests.',
    requirements: [
      'Must bring own instruments (except piano)',
      '2 x 45-minute sets with 15-minute break',
      'Sound check at 6:00 PM',
      'Professional attire required',
    ],
    amenities: [
      'Grand Piano',
      'Professional PA',
      'Green Room',
      'Free Parking',
      'Meal Included',
    ],
    status: GigStatus.pending,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _acceptGig() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _isAccepted = true; // Optimistic update
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const AnimatedSuccessCheck(size: 20, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Gig accepted! Check your calendar.'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _declineGig() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(Theme.of(context).brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Decline this gig?',
          style: TextStyle(color: AppColors.text(Theme.of(context).brightness)),
        ),
        content: Text(
          'You can always apply again if you change your mind.',
          style: TextStyle(color: AppColors.textSec(Theme.of(context).brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSec(Theme.of(context).brightness)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Decline',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final daysUntil = _gig.date.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Hero Image App Bar
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.surface(brightness),
              leading: AnimatedTapFeedback(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              actions: [
                AnimatedTapFeedback(
                  onTap: () => HapticFeedback.selectionClick(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background gradient (placeholder for image)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E3A5F),
                            Color(0xFF0D1B2A),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    // Venue info overlay
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_gig.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(_gig.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _gig.venueName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _gig.location,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Cards
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: _formatDate(_gig.date),
                            highlight: daysUntil <= 3,
                            brightness: brightness,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.access_time_rounded,
                            label: 'Time',
                            value: '${_gig.startTime} - ${_gig.endTime}',
                            brightness: brightness,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.attach_money_rounded,
                            label: 'Payment',
                            value: '\$${_gig.payment}',
                            highlight: true,
                            brightness: brightness,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Countdown
                  if (daysUntil >= 0 && daysUntil <= 7)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: LiquidGlassContainer(
                        borderRadius: 16,
                        tintColor: AppColors.crimson.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.crimson.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.timer_rounded,
                                  color: AppColors.crimson,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      daysUntil == 0 ? 'Today!' : '$daysUntil days to go',
                                      style: TextStyle(
                                        color: AppColors.text(brightness),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Sound check at 6:00 PM',
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
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Genre
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.crimson.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.music_note_rounded,
                                color: AppColors.crimson,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _gig.genre,
                                style: TextStyle(
                                  color: AppColors.crimson,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  _SectionHeader(title: 'About This Gig', brightness: brightness),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _gig.description,
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Requirements
                  _SectionHeader(title: 'Requirements', brightness: brightness),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: _gig.requirements.map((req) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.crimson,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                req,
                                style: TextStyle(
                                  color: AppColors.text(brightness),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Amenities
                  _SectionHeader(title: 'Amenities', brightness: brightness),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _gig.amenities.map((amenity) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface(brightness),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border(brightness)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              amenity,
                              style: TextStyle(
                                color: AppColors.text(brightness),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),

                  const SizedBox(height: 120), // Space for bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Action Bar
      bottomNavigationBar: _gig.status == GigStatus.pending
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                border: Border(
                  top: BorderSide(color: AppColors.border(brightness)),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Decline button
                    AnimatedTapFeedback(
                      onTap: _declineGig,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Accept button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading || _isAccepted ? null : _acceptGig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAccepted 
                              ? AppColors.success 
                              : AppColors.crimson,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isAccepted 
                                      ? Icons.check_rounded 
                                      : Icons.check_circle_outline_rounded),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isAccepted ? 'Accepted!' : 'Accept Gig',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Color _getStatusColor(GigStatus status) {
    return switch (status) {
      GigStatus.pending => Colors.orange,
      GigStatus.confirmed => AppColors.success,
      GigStatus.completed => Colors.blue,
      GigStatus.cancelled => AppColors.error,
    };
  }

  String _getStatusText(GigStatus status) {
    return switch (status) {
      GigStatus.pending => 'PENDING RESPONSE',
      GigStatus.confirmed => 'CONFIRMED',
      GigStatus.completed => 'COMPLETED',
      GigStatus.cancelled => 'CANCELLED',
    };
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📦 SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final Brightness brightness;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.crimson.withValues(alpha: 0.1)
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? AppColors.crimson.withValues(alpha: 0.3)
                : AppColors.border(brightness),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: highlight ? AppColors.crimson : AppColors.textSec(brightness),
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 11,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📊 MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum GigStatus { pending, confirmed, completed, cancelled }

class GigDetails {
  final String id;
  final String venueName;
  final String venueImage;
  final String location;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String genre;
  final int payment;
  final String description;
  final List<String> requirements;
  final List<String> amenities;
  final GigStatus status;

  GigDetails({
    required this.id,
    required this.venueName,
    required this.venueImage,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.genre,
    required this.payment,
    required this.description,
    required this.requirements,
    required this.amenities,
    required this.status,
  });
}
