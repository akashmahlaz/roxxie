/// 🏟️ Venue Profile View Screen — Enterprise Edition
///
/// 2026 Design Principles Applied:
/// - Parallax cover image with blur overlay
/// - Image gallery carousel with indicators
/// - Liquid Glass cards for sections
/// - Animated stats with counting effect
/// - Map preview integration ready
/// - Review carousel with venue ratings
/// - Quick action FAB for booking
///
/// Comprehensive venue profile viewing for artists
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

class VenueProfileViewScreen extends StatefulWidget {
  final String venueId;

  const VenueProfileViewScreen({super.key, required this.venueId});

  @override
  State<VenueProfileViewScreen> createState() => _VenueProfileViewScreenState();
}

class _VenueProfileViewScreenState extends State<VenueProfileViewScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _statsController;
  late PageController _galleryController;

  double _scrollOffset = 0;
  int _currentGalleryIndex = 0;
  bool _isLoading = true;
  VenueProfile? _venue;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _galleryController = PageController()
      ..addListener(() {
        final page = _galleryController.page?.round() ?? 0;
        if (page != _currentGalleryIndex) {
          setState(() => _currentGalleryIndex = page);
        }
      });
    _loadVenue();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _statsController.dispose();
    _galleryController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  Future<void> _loadVenue() async {
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _venue = VenueProfile(
        id: widget.venueId,
        name: 'Blue Note NYC',
        tagline: 'The Jazz Capital of the World',
        coverImages: [
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
          'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800',
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800',
        ],
        avatar: 'https://i.pravatar.cc/150?img=65',
        description:
            'Blue Note is the jazz capital of the world, featuring legendary artists and emerging talent '
            'seven nights a week. Since opening in 1981, we\'ve been the premier jazz venue in New York City, '
            'showcasing the best in jazz, blues, R&B, and world music.',
        address: '131 W 3rd St, New York, NY 10012',
        location: 'Greenwich Village, NYC',
        venueType: 'Jazz Club',
        capacity: 250,
        rating: 4.8,
        reviewCount: 342,
        gigsHosted: 1250,
        yearsActive: 43,
        avgPayment: '\$350 - \$800',
        amenities: [
          VenueAmenity(icon: Icons.speaker_rounded, label: 'Full PA System'),
          VenueAmenity(icon: Icons.restaurant_rounded, label: 'Dinner Service'),
          VenueAmenity(icon: Icons.local_bar_rounded, label: 'Full Bar'),
          VenueAmenity(
            icon: Icons.local_parking_rounded,
            label: 'Nearby Parking',
          ),
          VenueAmenity(icon: Icons.accessible_rounded, label: 'Accessible'),
          VenueAmenity(icon: Icons.wifi_rounded, label: 'WiFi'),
        ],
        genres: ['Jazz', 'Blues', 'Soul', 'R&B', 'World'],
        openGigs: 3,
        reviews: [
          VenueReview(
            id: '1',
            artistName: 'Marcus Rivera',
            artistImage: 'https://i.pravatar.cc/100?img=13',
            rating: 5,
            comment:
                'Incredible sound system and super professional staff. The crowd was amazing!',
            date: DateTime.now().subtract(const Duration(days: 5)),
          ),
          VenueReview(
            id: '2',
            artistName: 'Sarah\'s Jazz Quartet',
            artistImage: 'https://i.pravatar.cc/100?img=47',
            rating: 5,
            comment:
                'Best venue I\'ve ever played. The stage setup is perfect and they really take care of artists.',
            date: DateTime.now().subtract(const Duration(days: 12)),
          ),
          VenueReview(
            id: '3',
            artistName: 'The Midnight Run',
            artistImage: 'https://i.pravatar.cc/100?img=33',
            rating: 4,
            comment:
                'Great atmosphere and attentive audience. Would love to come back!',
            date: DateTime.now().subtract(const Duration(days: 28)),
          ),
        ],
        isVerified: true,
        isPremium: true,
        responseRate: 95,
        responseTime: '< 2 hours',
      );
      _isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _statsController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.38;

    if (_isLoading) {
      return _buildLoadingState(brightness);
    }

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Gallery
              SliverAppBar(
                expandedHeight: heroHeight,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.surface(brightness),
                leading: _buildBackButton(brightness),
                actions: [
                  _buildShareButton(brightness),
                  _buildMoreButton(brightness),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: _buildHeroGallery(heroHeight, brightness),
                ),
              ),

              // Content
              SliverToBoxAdapter(child: _buildProfileContent(brightness)),
            ],
          ),

          // FAB
          Positioned(right: 20, bottom: 100, child: _buildFAB(brightness)),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Brightness brightness) {
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: ShimmerBase(
        child: Column(
          children: [
            Container(height: 280, color: AppColors.surface(brightness)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: BorderRadius.circular(16),
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

  Widget _buildBackButton(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AnimatedTapFeedback(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(Brightness brightness) {
    return AnimatedTapFeedback(
      onTap: () => HapticFeedback.lightImpact(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton(Brightness brightness) {
    return AnimatedTapFeedback(
      onTap: () => HapticFeedback.lightImpact(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroGallery(double height, Brightness brightness) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image carousel
        PageView.builder(
          controller: _galleryController,
          itemCount: _venue!.coverImages.length,
          itemBuilder: (context, index) {
            final parallaxOffset = _scrollOffset * 0.5;
            return Transform.translate(
              offset: Offset(0, parallaxOffset),
              child: Image.network(
                _venue!.coverImages[index],
                fit: BoxFit.cover,
              ),
            );
          },
        ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Page indicators
        Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_venue!.coverImages.length, (index) {
              final isActive = index == _currentGalleryIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),

        // Venue info at bottom
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: NetworkImage(_venue!.avatar),
                    ),
                  ),
                  if (_venue!.isVerified)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.info,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _venue!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_venue!.isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _venue!.tagline,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _venue!.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD700),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_venue!.rating} (${_venue!.reviewCount})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
      ],
    );
  }

  Widget _buildProfileContent(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          _buildQuickStats(brightness),
          const SizedBox(height: 24),

          // Open Gigs CTA
          if (_venue!.openGigs > 0) ...[
            _buildOpenGigsCTA(brightness),
            const SizedBox(height: 24),
          ],

          // About
          _buildAboutSection(brightness),
          const SizedBox(height: 24),

          // Genres
          _buildGenresSection(brightness),
          const SizedBox(height: 24),

          // Amenities
          _buildAmenitiesSection(brightness),
          const SizedBox(height: 24),

          // Location
          _buildLocationSection(brightness),
          const SizedBox(height: 24),

          // Reviews
          _buildReviewsSection(brightness),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Brightness brightness) {
    return Row(
      children: [
        Expanded(
          child: _AnimatedStatCard(
            icon: Icons.event_rounded,
            label: 'Gigs Hosted',
            value: _venue!.gigsHosted,
            color: AppColors.crimson,
            controller: _statsController,
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AnimatedStatCard(
            icon: Icons.history_rounded,
            label: 'Years Active',
            value: _venue!.yearsActive,
            color: AppColors.info,
            controller: _statsController,
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AnimatedStatCard(
            icon: Icons.people_rounded,
            label: 'Capacity',
            value: _venue!.capacity,
            color: AppColors.success,
            controller: _statsController,
            brightness: brightness,
          ),
        ),
      ],
    );
  }

  Widget _buildOpenGigsCTA(Brightness brightness) {
    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.mediumImpact();
        // Navigate to venue's gigs
      },
      child: LiquidGlassContainer(
        borderRadius: 18,
        tintColor: AppColors.crimson.withValues(alpha: 0.08),
        showGlow: true,
        glowColor: AppColors.crimson.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.work_rounded,
                  color: AppColors.crimson,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_venue!.openGigs} Open Gig${_venue!.openGigs > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Apply now to perform here!',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection(Brightness brightness) {
    return LiquidGlassContainer(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.crimson,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _venue!.description,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  Icons.business_rounded,
                  _venue!.venueType,
                  brightness,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.attach_money_rounded,
                  _venue!.avgPayment,
                  brightness,
                  highlight: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    Brightness brightness, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.background(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border(brightness),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlight
                ? AppColors.success
                : AppColors.textSec(brightness),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: highlight ? AppColors.success : AppColors.text(brightness),
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenresSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Music Genres',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _venue!.genres
              .map(
                (genre) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.crimson, Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    genre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _venue!.amenities
              .map(
                (amenity) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface(brightness),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(brightness)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(amenity.icon, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        amenity.label,
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection(Brightness brightness) {
    return LiquidGlassContainer(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.crimson,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AnimatedTapFeedback(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Text(
                    'Get Directions',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Map placeholder
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.background(brightness),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      color: AppColors.textSec(brightness),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Map Preview',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _venue!.address,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Artist Reviews',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFD700),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _venue!.rating.toString(),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            AnimatedTapFeedback(
              onTap: () => HapticFeedback.lightImpact(),
              child: Text(
                'All ${_venue!.reviewCount} reviews',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...(_venue!.reviews
            .take(3)
            .map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewCard(review: review, brightness: brightness),
              ),
            )),
      ],
    );
  }

  Widget _buildFAB(Brightness brightness) {
    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showApplySheet(brightness);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.crimson, Color(0xFFFF6B6B)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Apply to Gigs',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplySheet(Brightness brightness) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Apply to ${_venue!.name}',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View open gigs and send your application',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'View ${_venue!.openGigs} Open Gigs',
              onPressed: () => Navigator.pop(context),
              icon: Icons.work_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class VenueProfile {
  final String id;
  final String name;
  final String tagline;
  final List<String> coverImages;
  final String avatar;
  final String description;
  final String address;
  final String location;
  final String venueType;
  final int capacity;
  final double rating;
  final int reviewCount;
  final int gigsHosted;
  final int yearsActive;
  final String avgPayment;
  final List<VenueAmenity> amenities;
  final List<String> genres;
  final int openGigs;
  final List<VenueReview> reviews;
  final bool isVerified;
  final bool isPremium;
  final int responseRate;
  final String responseTime;

  const VenueProfile({
    required this.id,
    required this.name,
    required this.tagline,
    required this.coverImages,
    required this.avatar,
    required this.description,
    required this.address,
    required this.location,
    required this.venueType,
    required this.capacity,
    required this.rating,
    required this.reviewCount,
    required this.gigsHosted,
    required this.yearsActive,
    required this.avgPayment,
    required this.amenities,
    required this.genres,
    required this.openGigs,
    required this.reviews,
    required this.isVerified,
    required this.isPremium,
    required this.responseRate,
    required this.responseTime,
  });
}

class VenueAmenity {
  final IconData icon;
  final String label;

  const VenueAmenity({required this.icon, required this.label});
}

class VenueReview {
  final String id;
  final String artistName;
  final String artistImage;
  final int rating;
  final String comment;
  final DateTime date;

  const VenueReview({
    required this.id,
    required this.artistName,
    required this.artistImage,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _AnimatedStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final AnimationController controller;
  final Brightness brightness;

  const _AnimatedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.controller,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final animatedValue = (value * controller.value).round();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                animatedValue.toString(),
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final VenueReview review;
  final Brightness brightness;

  const _ReviewCard({required this.review, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(review.artistImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.artistName,
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(review.date),
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).floor()} weeks ago';
    return '${(diff / 30).floor()} months ago';
  }
}
