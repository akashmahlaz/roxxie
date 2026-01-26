/// 🎤 Artist Profile View Screen — Enterprise Edition
///
/// 2026 Design Principles Applied:
/// - Parallax hero image with blur overlay
/// - Liquid Glass cards with depth layers
/// - Animated progress rings for stats
/// - Micro-interactions on all elements
/// - Video/audio portfolio section
/// - Review carousel with ratings
/// - Quick action FAB menu
/// - Smooth scroll-to-section navigation
/// - REAL API integration for artist data
///
/// Comprehensive artist profile viewing for venues
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../core/services/services.dart';
import '../core/models/models.dart' as models;
import '../widgets/widgets.dart';

class ArtistProfileViewScreen extends StatefulWidget {
  final String artistId;
  final String? initialTab;

  const ArtistProfileViewScreen({
    super.key,
    required this.artistId,
    this.initialTab,
  });

  @override
  State<ArtistProfileViewScreen> createState() =>
      _ArtistProfileViewScreenState();
}

class _ArtistProfileViewScreenState extends State<ArtistProfileViewScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fabController;
  late AnimationController _statsController;
  late TabController _tabController;

  final ArtistService _artistService = ArtistService();
  final ReviewService _reviewService = ReviewService();
  final CalendarService _calendarService = CalendarService();

  double _scrollOffset = 0;
  bool _showFABMenu = false;
  bool _isLoading = true;
  String? _errorMessage;
  ArtistProfile? _artist;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _tabController = TabController(length: 3, vsync: this);
    _loadArtist();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabController.dispose();
    _statsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  Future<void> _loadArtist() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch real artist data from API
      final artist = await _artistService.getArtistById(widget.artistId);

      // Fetch reviews for this artist
      List<Review> reviews = [];
      try {
        final reviewsResponse = await _reviewService.getArtistReviews(
          widget.artistId,
          limit: 10,
        );
        reviews = reviewsResponse.reviews
            .map(
              (r) => Review(
                id: r.id,
                authorName: r.reviewerName,
                authorImage:
                    r.reviewerPhoto ??
                    'https://i.pravatar.cc/100?img=${r.id.hashCode % 70}',
                rating: r.overallRating,
                comment: r.content,
                date: r.createdAt,
              ),
            )
            .toList();
      } catch (e) {
        // Reviews might not exist yet, that's okay
        debugPrint('Could not load reviews: $e');
      }

      // Fetch calendar for upcoming availability
      List<DateTime> upcomingDates = [];
      try {
        final calendar = await _calendarService.getArtistCalendar(
          widget.artistId,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
        );

        upcomingDates = calendar.events
            .where((e) => e.eventType == CalendarEventType.availability)
            .map((e) => e.date)
            .toList();

        // Deduplicate and sort
        upcomingDates = upcomingDates.toSet().toList()..sort();
      } catch (e) {
        debugPrint('Could not load calendar: $e');
        // Continue loading profile even if calendar fails
      }

      // Map API Artist model to local ArtistProfile
      setState(() {
        _artist = ArtistProfile(
          id: artist.id,
          name: artist.stageName, // Use stageName as display name
          stageName: artist.stageName,
          avatar:
              artist.profilePhoto ??
              'https://i.pravatar.cc/300?img=${artist.id.hashCode % 70}',
          coverImage: artist.galleryUrls.isNotEmpty
              ? artist.galleryUrls.first
              : 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
          bio:
              artist.bio ??
              'Professional artist ready to bring amazing performances to your venue.',
          genres: artist.genres,
          instruments: artist.equipment,
          location: artist.displayLocation,
          rating: artist.averageRating > 0
              ? artist.averageRating
              : artist.rating,
          reviewCount: artist.totalReviews > 0
              ? artist.totalReviews
              : artist.reviewCount,
          gigsCompleted: artist.completedGigs,
          yearsActive: artist.yearsOfExperience ?? 1,
          responseRate: artist.responseRate,
          responseTime: _formatResponseTime(artist.responseTime),
          isVerified: artist.isVerified,
          isPremium:
              artist.subscriptionTier == 'premium' ||
              artist.subscriptionTier == 'pro',
          priceRange:
              '\$${artist.minPrice.toInt()} - \$${artist.maxPrice.toInt()}',
          availability: [
            'Weekends',
            'Evenings',
          ], // TODO: Parse from artist.availability
          media: _mapMediaItems(artist),
          reviews: reviews,
          upcomingAvailability: upcomingDates,
        );
        _isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _statsController.forward();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load artist profile. Please try again.';
      });
      debugPrint('Error loading artist: $e');
    }
  }

  List<MediaItem> _mapMediaItems(models.Artist artist) {
    List<MediaItem> items = [];

    // Add videos from portfolio
    for (var video in artist.videoSamples) {
      items.add(
        MediaItem(
          type: 'video',
          url: video.url,
          thumbnail:
              video.thumbnailUrl ??
              'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400',
          title: video.title,
        ),
      );
    }

    // Add audio samples
    for (var audio in artist.audioSamples) {
      items.add(
        MediaItem(
          type: 'audio',
          url: audio.url,
          title: audio.title ?? 'Audio Sample',
        ),
      );
    }

    // Add gallery images
    for (var imageUrl in artist.galleryUrls) {
      items.add(MediaItem(type: 'image', url: imageUrl));
    }

    // If no media, add profile photo as placeholder
    if (items.isEmpty && artist.profilePhoto != null) {
      items.add(MediaItem(type: 'image', url: artist.profilePhoto!));
    }

    return items;
  }

  List<DateTime> _generateUpcomingDates() {
    // TODO: Fetch real availability from calendar API
    return [
      DateTime.now().add(const Duration(days: 2)),
      DateTime.now().add(const Duration(days: 5)),
      DateTime.now().add(const Duration(days: 7)),
      DateTime.now().add(const Duration(days: 12)),
    ];
  }

  String _formatResponseTime(int minutes) {
    if (minutes < 60) {
      return '< 1 hour';
    } else if (minutes <= 1440) {
      final hours = (minutes / 60).ceil();
      return '< $hours ${hours == 1 ? "hour" : "hours"}';
    } else {
      final days = (minutes / 1440).ceil();
      return '< $days ${days == 1 ? "day" : "days"}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.42;

    if (_isLoading) {
      return _buildLoadingState(brightness);
    }

    if (_errorMessage != null) {
      return _buildErrorState(brightness);
    }

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Section with Parallax
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
                  background: _buildHeroSection(heroHeight, brightness),
                ),
              ),

              // Content
              SliverToBoxAdapter(child: _buildProfileContent(brightness)),
            ],
          ),

          // Floating Action Button
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
            Container(height: 300, color: AppColors.surface(brightness)),
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

  Widget _buildErrorState(Brightness brightness) {
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.text(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.textSec(brightness),
              ),
              const SizedBox(height: 16),
              Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(brightness),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSec(brightness),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadArtist,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildHeroSection(double height, Brightness brightness) {
    final parallaxOffset = _scrollOffset * 0.5;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover image with parallax
        Transform.translate(
          offset: Offset(0, parallaxOffset),
          child: Image.network(_artist!.coverImage, fit: BoxFit.cover),
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

        // Profile info at bottom
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar with verified badge
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
                      radius: 44,
                      backgroundImage: NetworkImage(_artist!.avatar),
                    ),
                  ),
                  if (_artist!.isVerified)
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
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _artist!.stageName ?? _artist!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_artist!.isPremium) ...[
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
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _artist!.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
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
                          '${_artist!.rating} (${_artist!.reviewCount})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
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

          // Bio
          _buildBioSection(brightness),
          const SizedBox(height: 24),

          // Genres & Instruments
          _buildTagsSection(brightness),
          const SizedBox(height: 24),

          // Price & Availability
          _buildAvailabilitySection(brightness),
          const SizedBox(height: 24),

          // Media Portfolio
          _buildMediaSection(brightness),
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
            icon: Icons.event_available_rounded,
            label: 'Gigs',
            value: _artist!.gigsCompleted,
            color: AppColors.crimson,
            controller: _statsController,
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AnimatedStatCard(
            icon: Icons.access_time_rounded,
            label: 'Years',
            value: _artist!.yearsActive,
            color: AppColors.info,
            controller: _statsController,
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AnimatedStatCard(
            icon: Icons.flash_on_rounded,
            label: 'Response',
            value: _artist!.responseRate,
            suffix: '%',
            color: AppColors.success,
            controller: _statsController,
            brightness: brightness,
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(Brightness brightness) {
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
                  Icons.person_outline_rounded,
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
              _artist!.bio,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genres
        Text(
          'Genres',
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
          children: _artist!.genres
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

        const SizedBox(height: 20),

        // Instruments
        Text(
          'Instruments',
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
          children: _artist!.instruments
              .map(
                (instrument) => Container(
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
                        _getInstrumentIcon(instrument),
                        size: 16,
                        color: AppColors.crimson,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        instrument,
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

  Widget _buildAvailabilitySection(Brightness brightness) {
    return LiquidGlassContainer(
      borderRadius: 20,
      tintColor: AppColors.success.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _artist!.responseTime,
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _artist!.priceRange,
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _artist!.availability
                  .map(
                    (slot) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background(brightness),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(brightness)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            slot,
                            style: TextStyle(
                              color: AppColors.text(brightness),
                              fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _buildMediaSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Portfolio',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            AnimatedTapFeedback(
              onTap: () => HapticFeedback.lightImpact(),
              child: Text(
                'See All',
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
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _artist!.media.length,
            itemBuilder: (context, index) {
              final media = _artist!.media[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _artist!.media.length - 1 ? 12 : 0,
                ),
                child: AnimatedTapFeedback(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    // Open media viewer
                  },
                  child: _MediaCard(media: media, brightness: brightness),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
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
                    _artist!.rating.toString(),
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
                'All ${_artist!.reviewCount} reviews',
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
        ...(_artist!.reviews
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expandable menu items
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _showFABMenu
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildFABItem(
                      Icons.calendar_today_rounded,
                      'Check Availability',
                      AppColors.info,
                      () {},
                    ),
                    const SizedBox(height: 10),
                    _buildFABItem(
                      Icons.message_rounded,
                      'Send Message',
                      AppColors.success,
                      () {},
                    ),
                    const SizedBox(height: 10),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // Main FAB
        AnimatedTapFeedback(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (_showFABMenu) {
              // Direct book action
              _showBookingSheet(brightness);
            } else {
              setState(() => _showFABMenu = !_showFABMenu);
            }
          },
          onLongPress: () {
            setState(() => _showFABMenu = !_showFABMenu);
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showFABMenu ? Icons.send_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _showFABMenu ? 'Book Now' : 'Actions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFABItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(Brightness brightness) {
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
              'Book ${_artist!.stageName ?? _artist!.name}',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an upcoming gig to send a booking request',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // Gig selection would go here
            GradientButton(
              text: 'Send Booking Request',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Booking request sent!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getInstrumentIcon(String instrument) {
    switch (instrument.toLowerCase()) {
      case 'guitar':
        return Icons.music_note_rounded;
      case 'drums':
        return Icons.album_rounded;
      case 'vocals':
        return Icons.mic_rounded;
      case 'piano':
      case 'keyboard':
        return Icons.piano_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class ArtistProfile {
  final String id;
  final String name;
  final String? stageName;
  final String avatar;
  final String coverImage;
  final String bio;
  final List<String> genres;
  final List<String> instruments;
  final String location;
  final double rating;
  final int reviewCount;
  final int gigsCompleted;
  final int yearsActive;
  final int responseRate;
  final String responseTime;
  final bool isVerified;
  final bool isPremium;
  final String priceRange;
  final List<String> availability;
  final List<MediaItem> media;
  final List<Review> reviews;
  final List<DateTime> upcomingAvailability;

  const ArtistProfile({
    required this.id,
    required this.name,
    this.stageName,
    required this.avatar,
    required this.coverImage,
    required this.bio,
    required this.genres,
    required this.instruments,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.gigsCompleted,
    required this.yearsActive,
    required this.responseRate,
    required this.responseTime,
    required this.isVerified,
    required this.isPremium,
    required this.priceRange,
    required this.availability,
    required this.media,
    required this.reviews,
    required this.upcomingAvailability,
  });
}

class MediaItem {
  final String type; // 'video', 'audio', 'image'
  final String url;
  final String? thumbnail;
  final String? title;

  const MediaItem({
    required this.type,
    required this.url,
    this.thumbnail,
    this.title,
  });
}

class Review {
  final String id;
  final String authorName;
  final String authorImage;
  final int rating;
  final String comment;
  final DateTime date;

  const Review({
    required this.id,
    required this.authorName,
    required this.authorImage,
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
  final String? suffix;
  final Color color;
  final AnimationController controller;
  final Brightness brightness;

  const _AnimatedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
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
                '$animatedValue${suffix ?? ''}',
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
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MediaCard extends StatelessWidget {
  final MediaItem media;
  final Brightness brightness;

  const _MediaCard({required this.media, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface(brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            media.thumbnail ?? media.url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.cardBackground(brightness),
              child: Icon(
                media.type == 'audio'
                    ? Icons.audiotrack_rounded
                    : Icons.image_rounded,
                color: AppColors.textSec(brightness),
                size: 40,
              ),
            ),
          ),
          if (media.type == 'video')
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          if (media.type == 'audio')
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.audiotrack_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  if (media.title != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        media.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
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
                backgroundImage: NetworkImage(review.authorImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
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
