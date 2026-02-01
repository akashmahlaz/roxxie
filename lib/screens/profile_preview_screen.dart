/// 👁️ GIGMATCH Profile Preview Screen
///
/// Unified public profile view for both artists and venues.
/// Shows how others will see your profile - responsive, polished design.
///
/// Features:
/// - Works for own profile preview (from Me tab)
/// - Works for external viewing via deep link (/artist/:id or /venue/:id)
/// - Responsive layout with beautiful animations
/// - Advanced audio player with waveform and seek
/// - Video carousel with auto-play
/// - Photo gallery with lightbox
/// - Ratings and reviews section
/// - Share with deep link support
/// - Material 3 components throughout
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/services/services.dart';
import '../core/models/models.dart';
import '../widgets/media/media.dart';
import 'chat_screen_v2.dart';

/// Media type for segmented button
enum MediaType { audio, video, photos }

/// Profile type for the screen
enum ProfileViewType { artist, venue }

class ProfilePreviewScreen extends StatefulWidget {
  /// The ID of the profile to view. If null, shows current user's profile.
  final String? profileId;

  /// The type of profile (artist/venue). If null, auto-detected from auth.
  final ProfileViewType? profileType;

  const ProfilePreviewScreen({super.key, this.profileId, this.profileType});

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen>
    with TickerProviderStateMixin {
  // Controllers
  late ScrollController _scrollController;
  late AnimationController _fadeController;

  // Use ValueNotifier instead of setState for scroll offset - prevents full tree rebuild
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  // Profile data
  Artist? _artist;
  Venue? _venue;
  bool _isArtist = true;
  bool _isOwnProfile = true;
  String _userName = ''; // Cached user name for fallback

  // Media state
  MediaType _selectedMediaType = MediaType.audio;

  // Reviews (loaded for future enhancement - show individual reviews)
  // ignore: unused_field
  ReviewStats? _reviewStats;
  // ignore: unused_field
  List<Review>? _reviews;

  // Services
  final _artistService = ArtistService();
  final _venueService = VenueService();
  final _reviewService = ReviewService();
  
  // Loading state
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadProfile();
  }

  void _onScroll() {
    // Update ValueNotifier instead of calling setState - prevents full tree rebuild
    _scrollOffset.value = _scrollController.offset;
  }

  Future<void> _loadProfile() async {
    debugPrint('👁️ [ProfilePreview] _loadProfile called');
    debugPrint('👁️ [ProfilePreview] widget.profileId: ${widget.profileId}');
    debugPrint('👁️ [ProfilePreview] widget.profileType: ${widget.profileType}');
    
    // Cache context-dependent values before any async operations
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cache user name for fallback (auth already cached above)
      _userName = auth.user?.name ?? '';

      if (widget.profileId != null) {
        // External profile view via deep link
        _isOwnProfile = false;
        debugPrint('👁️ [ProfilePreview] Loading external profile...');
        if (widget.profileType == ProfileViewType.venue) {
          _isArtist = false;
          debugPrint('👁️ [ProfilePreview] Fetching venue by ID: ${widget.profileId}');
          _venue = await _venueService.getVenueById(widget.profileId!);
          debugPrint('👁️ [ProfilePreview] Venue loaded: ${_venue?.venueName}');
        } else {
          _isArtist = true;
          debugPrint('👁️ [ProfilePreview] Fetching artist by ID: ${widget.profileId}');
          _artist = await _artistService.getArtistById(widget.profileId!);
          debugPrint('👁️ [ProfilePreview] Artist loaded: ${_artist?.displayName}');
        }
      } else {
        // Own profile preview - always fetch fresh data to show latest updates
        _isOwnProfile = true;
        _isArtist = auth.isArtist;
        debugPrint('👁️ [ProfilePreview] Loading own profile, isArtist: $_isArtist');
        if (_isArtist) {
          _artist = await _artistService.getMyProfile();
        } else {
          _venue = await _venueService.getMyProfile();
        }
      }

      // Load reviews
      await _loadReviews();

      if (mounted) {
        _fadeController.forward();
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfilePreview] Error loading profile: $e');
      debugPrint('❌ [ProfilePreview] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReviews() async {
    try {
      if (_isArtist && _artist != null) {
        _reviewStats = await _reviewService.getArtistStats(_artist!.id);
        final response = await _reviewService.getArtistReviews(_artist!.id);
        _reviews = response.reviews;
      } else if (!_isArtist && _venue != null) {
        _reviewStats = await _reviewService.getVenueStats(_venue!.id);
        final response = await _reviewService.getVenueReviews(_venue!.id);
        _reviews = response.reviews;
      }
    } catch (_) {
      // Reviews might not be available - non-critical
    }
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _profileId {
    if (_isArtist) {
      return _artist?.id ?? '';
    }
    return _venue?.id ?? '';
  }

  String get _profileName {
    if (_isArtist) {
      return _artist?.stageName ??
          _artist?.displayName ??
          (_userName.isNotEmpty ? _userName : 'Artist');
    }
    return _venue?.name ?? (_userName.isNotEmpty ? _userName : 'Venue');
  }

  String get _deepLinkUrl {
    final type = _isArtist ? 'artist' : 'venue';
    return 'https://gigmatch.app/$type/$_profileId';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: _isLoading
          ? _buildLoading(brightness)
          : _error != null
          ? _buildError(brightness)
          : _buildContent(brightness),
      bottomNavigationBar: !_isLoading && _error == null && !_isOwnProfile
          ? _buildActionBar(brightness)
          : null,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOADING & ERROR STATES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLoading(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.crimson),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.crimson,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load profile',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadProfile,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildContent(Brightness brightness) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Collapsing App Bar with Hero Image
        _buildSliverAppBar(brightness),

        // Profile Info Card
        SliverToBoxAdapter(child: _buildProfileInfoCard(brightness)),

        // Stats Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildStatsRow(brightness),
          ),
        ),

        // Content Sections
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // About/Bio Section
                _buildAboutSection(brightness),

                // Genres Section
                _buildGenresSection(brightness),

                // Media Section (Audio/Video/Photos with segmented navigation)
                _buildMediaSection(brightness),

                // Equipment Section (artists only)
                if (_isArtist) _buildEquipmentSection(brightness),

                // Venue Info (venues only)
                if (!_isArtist) _buildVenueInfoSection(brightness),

                // Pricing Section
                _buildPricingSection(brightness),

                // Social Links Section
                _buildSocialSection(brightness),

                // Reviews Section
                _buildReviewsSection(brightness),

                // Bottom spacing
                SizedBox(height: _isOwnProfile ? 40 : 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIVER APP BAR - Modern 2026 Design
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Use ValueListenableBuilder to only rebuild the app bar, not the entire tree
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (context, scrollOffset, _) {
        final isCollapsed = scrollOffset > 80;

        // Simple solid background
        final backgroundColor = isDark
            ? const Color(0xFF0A0A0C)
            : const Color(0xFFFCFCFC);

        return SliverAppBar(
          expandedHeight: 56, // Minimal - just enough for status bar + nav
          pinned: true,
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: _buildAppBarButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
            isCollapsed: isCollapsed,
            brightness: brightness,
          ),
          actions: [
            if (_isOwnProfile)
              _buildAppBarButton(
                icon: Icons.edit_outlined,
                onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                isCollapsed: isCollapsed,
                brightness: brightness,
              ),
            _buildAppBarButton(
              icon: Icons.ios_share_rounded,
              onPressed: _shareProfile,
              isCollapsed: isCollapsed,
              brightness: brightness,
            ),
          ],
          // Collapsed state: show name
          title: AnimatedOpacity(
            opacity: isCollapsed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Text(
              _profileName,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isCollapsed,
    required Brightness brightness,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: AppColors.text(brightness),
        size: 24,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE INFO CARD
  // ══════════════════════════════════════════════════════════════════════════

  String? _getDisplayLocation() {
    // Use built-in display location getters when available
    if (_isArtist) {
      final artist = _artist;
      if (artist == null) return null;

      // Artist has displayLocation getter
      final display = artist.displayLocation;
      if (display == 'Location not set' || display.contains('+')) {
        return null;
      }
      return display;
    } else {
      final venue = _venue;
      if (venue == null) return null;

      // Venue has displayLocation field
      final displayLocation = venue.displayLocation;
      if (displayLocation != null &&
          displayLocation.isNotEmpty &&
          !displayLocation.contains('+')) {
        return displayLocation;
      }

      // Fallback to location city
      final loc = venue.location;
      if (loc != null) {
        final city = loc.city;
        if (city != null && city.isNotEmpty && !city.contains('+')) {
          return city;
        }
      }
      return null;
    }
  }

  Widget _buildProfileInfoCard(Brightness brightness) {
    // Get avatar URL with Google photo fallback
    final auth = context.read<AuthProvider>();
    String? avatarUrl;
    if (_isArtist) {
      avatarUrl = _artist?.profilePhoto;
    } else {
      avatarUrl = _venue?.profilePhotoUrl;
    }
    avatarUrl ??= auth.user?.profilePhotoUrl;

    final isVerified = _isArtist
        ? (_artist?.isVerified ?? false)
        : (_venue?.isVerified ?? false);
    final location = _getDisplayLocation();
    final artistType = _isArtist ? _artist?.artistType.name : null;
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // Large centered avatar with subtle ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _buildAvatarFallback(brightness),
                      )
                    : _buildAvatarFallback(brightness),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Name with verification badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _profileName,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.verified,
                  color: const Color(0xFF3B82F6), // Soft blue
                  size: 22,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Type badge and location - muted colors
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (artistType != null || (!_isArtist && _venue?.venueType != null)) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isArtist
                        ? artistType!.toUpperCase()
                        : _venue!.venueType!.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
              if (location != null && location.isNotEmpty) ...[
                if (artistType != null || (!_isArtist && _venue?.venueType != null))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '•',
                      style: TextStyle(
                        color: AppColors.textSec(brightness).withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textSec(brightness),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      child: Center(
        child: Icon(
          _isArtist ? Icons.person_rounded : Icons.business_rounded,
          size: 48,
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: _isArtist
              ? [
                  _buildStatItem(
                    brightness,
                    (_artist?.averageRating ?? 0).toStringAsFixed(1),
                    'Rating',
                    showStar: true,
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    (_artist?.completedGigs ?? 0).toString(),
                    'Gigs',
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    (_artist?.totalReviews ?? 0).toString(),
                    'Reviews',
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    '${_artist?.reliabilityScore ?? 100}%',
                    'Reliable',
                  ),
                ]
              : [
                  _buildStatItem(
                    brightness,
                    (_venue?.reviewStatsAverageRating ?? _venue?.rating ?? 0)
                        .toStringAsFixed(1),
                    'Rating',
                    showStar: true,
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    (_venue?.totalGigsHosted ?? 0).toString(),
                    'Hosted',
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    (_venue?.capacity ?? 0).toString(),
                    'Capacity',
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    (_venue?.reviewCount ?? 0).toString(),
                    'Reviews',
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    Brightness brightness,
    String value,
    String label, {
    bool showStar = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showStar) ...[
                Icon(
                  Icons.star_rounded,
                  color: const Color(0xFFFFB800),
                  size: 18,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(Brightness brightness) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.divider(brightness).withValues(alpha: 0.3),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABOUT SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAboutSection(Brightness brightness) {
    final bio = _isArtist ? _artist?.bio : _venue?.description;
    if (bio == null || bio.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      brightness,
      title: 'About',
      icon: Icons.info_outline_rounded,
      child: Text(
        bio,
        style: TextStyle(
          color: AppColors.textSec(brightness),
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GENRES SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildGenresSection(Brightness brightness) {
    final genres = _isArtist
        ? (_artist?.genres ?? [])
        : (_venue?.gigPreferences?.preferredGenres ?? []);

    if (genres.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      brightness,
      title: _isArtist ? 'Genres' : 'Preferred Genres',
      icon: Icons.music_note_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: genres.map((genre) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.crimson.withValues(alpha: 0.15),
                  AppColors.rose.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              genre,
              style: TextStyle(
                color: AppColors.crimson,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UNIFIED MEDIA SECTION (Audio/Video/Photos with Material 3 SegmentedButton)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMediaSection(Brightness brightness) {
    final audioSamples = _isArtist
        ? (_artist?.audioSamples ?? [])
        : <AudioSample>[];
    final videoSamples = _isArtist
        ? (_artist?.videoSamples ?? [])
        : <VideoSample>[];
    final photos = _isArtist
        ? (_artist?.galleryUrls ?? [])
        : (_venue?.galleryUrls ?? []);

    // Check what media is available
    final hasAudio = audioSamples.isNotEmpty;
    final hasVideo = videoSamples.isNotEmpty;
    final hasPhotos = photos.isNotEmpty;

    // If no media at all, show empty state
    if (!hasAudio && !hasVideo && !hasPhotos) {
      return _buildSection(
        brightness,
        title: 'Media',
        icon: Icons.perm_media_rounded,
        child: Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.perm_media_outlined,
                  size: 48,
                  color: AppColors.textSec(brightness),
                ),
                const SizedBox(height: 12),
                Text(
                  'No media available',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Build available segments
    final availableTypes = <MediaType>[];
    if (hasAudio) availableTypes.add(MediaType.audio);
    if (hasVideo) availableTypes.add(MediaType.video);
    if (hasPhotos) availableTypes.add(MediaType.photos);

    // Determine effective selected type without modifying state during build
    final effectiveSelectedType = availableTypes.contains(_selectedMediaType)
        ? _selectedMediaType
        : availableTypes.first;

    return _buildSection(
      brightness,
      title: 'Media',
      icon: Icons.perm_media_rounded,
      trailing: _buildMediaCount(
        brightness,
        audioSamples.length,
        videoSamples.length,
        photos.length,
      ),
      child: Column(
        children: [
          // Material 3 SegmentedButton for media type switching
          if (availableTypes.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<MediaType>(
                  segments: [
                    if (hasAudio)
                      ButtonSegment<MediaType>(
                        value: MediaType.audio,
                        label: const Text('Audio'),
                        icon: const Icon(Icons.audiotrack_rounded, size: 18),
                      ),
                    if (hasVideo)
                      ButtonSegment<MediaType>(
                        value: MediaType.video,
                        label: const Text('Video'),
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                      ),
                    if (hasPhotos)
                      ButtonSegment<MediaType>(
                        value: MediaType.photos,
                        label: const Text('Photos'),
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                      ),
                  ],
                  selected: {effectiveSelectedType},
                  onSelectionChanged: (selected) {
                    HapticFeedback.lightImpact();
                    if (mounted) {
                      setState(() => _selectedMediaType = selected.first);
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.crimson.withValues(alpha: 0.15);
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.crimson;
                      }
                      return AppColors.textSec(brightness);
                    }),
                    side: WidgetStateProperty.all(
                      BorderSide(
                        color: AppColors.crimson.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Media content based on selected type
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildMediaContent(
              brightness,
              audioSamples,
              videoSamples,
              photos,
              effectiveSelectedType,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCount(
    Brightness brightness,
    int audio,
    int video,
    int photos,
  ) {
    final counts = <String>[];
    if (audio > 0) counts.add('$audio tracks');
    if (video > 0) counts.add('$video videos');
    if (photos > 0) counts.add('$photos photos');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: counts.asMap().entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.key > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 10,
                  ),
                ),
              ),
            Badge(
              label: Text(entry.value),
              backgroundColor: AppColors.crimson.withValues(alpha: 0.15),
              textColor: AppColors.crimson,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMediaContent(
    Brightness brightness,
    List<AudioSample> audioSamples,
    List<VideoSample> videoSamples,
    List<String> photos,
    MediaType selectedType,
  ) {
    switch (selectedType) {
      case MediaType.audio:
        return AdvancedAudioPlayer(
          key: const ValueKey('audio'),
          samples: audioSamples,
        );
      case MediaType.video:
        return AdvancedVideoCarousel(
          key: const ValueKey('video'),
          videos: videoSamples,
        );
      case MediaType.photos:
        return AdvancedPhotoGallery(
          key: const ValueKey('photos'),
          photos: photos,
          layout: GalleryLayout.featured,
        );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EQUIPMENT SECTION (Artists only)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEquipmentSection(Brightness brightness) {
    final equipment = _artist?.equipment ?? [];
    if (equipment.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      brightness,
      title: 'Equipment',
      icon: Icons.speaker_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: equipment.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Text(
                  item,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VENUE INFO SECTION (Venues only)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildVenueInfoSection(Brightness brightness) {
    if (_isArtist || _venue == null) {
      return const SizedBox.shrink();
    }

    // Build amenities from gig preferences
    final prefs = _venue!.gigPreferences;
    final amenities = <_AmenityItem>[
      if (prefs?.providesMusicianMeals == true)
        _AmenityItem(Icons.restaurant_rounded, 'Meals Provided'),
      if (prefs?.providesDrinks == true)
        _AmenityItem(Icons.local_bar_rounded, 'Drinks Provided'),
      if (prefs?.providesGreenRoomRefreshments == true)
        _AmenityItem(Icons.room_service_rounded, 'Green Room'),
      if (prefs?.providesAccommodation == true)
        _AmenityItem(Icons.hotel_rounded, 'Accommodation'),
      if (prefs?.providesPromotion == true)
        _AmenityItem(Icons.campaign_rounded, 'Promotion'),
      if (prefs?.acceptsDemos == true)
        _AmenityItem(Icons.headphones_rounded, 'Accepts Demos'),
    ];

    if (amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      brightness,
      title: 'What We Offer',
      icon: Icons.business_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: amenities.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: AppColors.cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRICING SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPricingSection(Brightness brightness) {
    final priceRange = _isArtist ? _artist?.priceRange : null;
    final venuePrefs = !_isArtist ? _venue?.gigPreferences : null;

    // Check if we have any pricing data
    final hasArtistPricing = priceRange != null;
    final hasVenuePricing =
        venuePrefs != null &&
        (venuePrefs.minBudget > 0 || venuePrefs.maxBudget > 0);

    if (!hasArtistPricing && !hasVenuePricing) {
      return const SizedBox.shrink();
    }

    final minPrice = priceRange?.min ?? venuePrefs?.minBudget ?? 0;
    final maxPrice = priceRange?.max ?? venuePrefs?.maxBudget ?? 0;
    final per = priceRange?.per ?? 'gig';

    return _buildSection(
      brightness,
      title: _isArtist ? 'Pricing' : 'Budget Range',
      icon: Icons.attach_money_rounded,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.crimson.withValues(alpha: 0.1),
              AppColors.rose.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.payments_rounded,
                color: AppColors.crimson,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${minPrice.toInt()} - \$${maxPrice.toInt()}',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                Text(
                  'per $per',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SOCIAL LINKS SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSocialSection(Brightness brightness) {
    // Build social items based on profile type
    final socialItems = <_SocialItem>[];

    if (_isArtist && _artist?.socialLinks != null) {
      final links = _artist!.socialLinks!;
      if (links.website != null && links.website!.isNotEmpty) {
        socialItems.add(
          _SocialItem(Icons.language_rounded, 'Website', links.website!, null),
        );
      }
      if (links.instagram != null && links.instagram!.isNotEmpty) {
        socialItems.add(
          _SocialItem(
            Icons.camera_alt_rounded,
            'Instagram',
            links.instagram!,
            const Color(0xFFE1306C),
          ),
        );
      }
      if (links.spotify != null && links.spotify!.isNotEmpty) {
        socialItems.add(
          _SocialItem(
            Icons.music_note_rounded,
            'Spotify',
            links.spotify!,
            const Color(0xFF1DB954),
          ),
        );
      }
      if (links.youtube != null && links.youtube!.isNotEmpty) {
        socialItems.add(
          _SocialItem(
            Icons.play_circle_rounded,
            'YouTube',
            links.youtube!,
            const Color(0xFFFF0000),
          ),
        );
      }
      if (links.tiktok != null && links.tiktok!.isNotEmpty) {
        socialItems.add(
          _SocialItem(Icons.music_video_rounded, 'TikTok', links.tiktok!, null),
        );
      }
    } else if (!_isArtist && _venue?.socialLinks != null) {
      final links = _venue!.socialLinks!;
      if (links.website != null && links.website!.isNotEmpty) {
        socialItems.add(
          _SocialItem(Icons.language_rounded, 'Website', links.website!, null),
        );
      }
      if (links.instagram != null && links.instagram!.isNotEmpty) {
        socialItems.add(
          _SocialItem(
            Icons.camera_alt_rounded,
            'Instagram',
            links.instagram!,
            const Color(0xFFE1306C),
          ),
        );
      }
      if (links.facebook != null && links.facebook!.isNotEmpty) {
        socialItems.add(
          _SocialItem(
            Icons.facebook_rounded,
            'Facebook',
            links.facebook!,
            const Color(0xFF1877F2),
          ),
        );
      }
      if (links.tiktok != null && links.tiktok!.isNotEmpty) {
        socialItems.add(
          _SocialItem(Icons.music_video_rounded, 'TikTok', links.tiktok!, null),
        );
      }
    }

    if (socialItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      brightness,
      title: 'Connect',
      icon: Icons.link_rounded,
      child: Row(
        children: socialItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _openUrl(item.url),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (item.color ?? AppColors.crimson).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: item.color ?? AppColors.crimson,
                  size: 24,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = url.startsWith('http')
        ? Uri.parse(url)
        : Uri.parse('https://$url');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to open link')));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REVIEWS SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildReviewsSection(Brightness brightness) {
    final rating = _isArtist
        ? (_artist?.averageRating ?? 0)
        : (_venue?.reviewStatsAverageRating ?? _venue?.rating ?? 0);
    final reviewCount = _isArtist
        ? (_artist?.totalReviews ?? 0)
        : (_venue?.reviewCount ?? 0);

    return _buildSection(
      brightness,
      title: 'Reviews',
      icon: Icons.star_rounded,
      trailing: TextButton(
        onPressed: () => Navigator.pushNamed(context, '/reviews'),
        child: Text(
          'See All',
          style: TextStyle(
            color: AppColors.crimson,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Big rating
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w800,
                fontSize: 44,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating.floor()
                          ? Icons.star_rounded
                          : (index < rating)
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.warning,
                      size: 22,
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  '$reviewCount reviews',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION BUILDER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSection(
    Brightness brightness, {
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.crimson, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTION BAR (for external viewing)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildActionBar(Brightness brightness) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        border: Border(top: BorderSide(color: AppColors.divider(brightness))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Message button
          Container(
            decoration: BoxDecoration(
              color: AppColors.background(brightness),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () {
                final id = _isArtist ? _artist?.id : _venue?.id;
                if (id != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreenV2(participantId: id),
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.text(brightness),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Book/Inquire button
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Navigate to booking flow
                HapticFeedback.mediumImpact();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text(
                _isArtist ? 'Book This Artist' : 'Inquire About Venue',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARE PROFILE
  // ══════════════════════════════════════════════════════════════════════════

  void _shareProfile() {
    HapticFeedback.mediumImpact();

    final message = 'Check out $_profileName on GigMatch! 🎵\n$_deepLinkUrl';

    SharePlus.instance.share(ShareParams(text: message));
    Clipboard.setData(ClipboardData(text: _deepLinkUrl));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(child: Text('Profile link copied!')),
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

// ══════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ══════════════════════════════════════════════════════════════════════════════

class _SocialItem {
  final IconData icon;
  final String label;
  final String url;
  final Color? color;

  _SocialItem(this.icon, this.label, this.url, this.color);
}

class _AmenityItem {
  final IconData icon;
  final String label;

  _AmenityItem(this.icon, this.label);
}
