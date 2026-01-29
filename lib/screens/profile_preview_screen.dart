/// 👁️ GIGMATCH Profile Preview Screen
///
/// Unified public profile view for both artists and venues.
/// Shows how others will see your profile - responsive, polished design.
///
/// Features:
/// - Works for own profile preview (from Me tab)
/// - Works for external viewing via deep link (/artist/:id or /venue/:id)
/// - Responsive layout with beautiful animations
/// - Audio/video player for artists
/// - Photo gallery for venues
/// - Ratings and reviews section
/// - Share with deep link support
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/services/services.dart';
import '../core/models/models.dart';
import 'chat_screen.dart';

/// Profile type for the screen
enum ProfileViewType { artist, venue }

class ProfilePreviewScreen extends StatefulWidget {
  /// The ID of the profile to view. If null, shows current user's profile.
  final String? profileId;

  /// The type of profile (artist/venue). If null, auto-detected from auth.
  final ProfileViewType? profileType;

  const ProfilePreviewScreen({
    super.key,
    this.profileId,
    this.profileType,
  });

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen>
    with TickerProviderStateMixin {
  // Controllers
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late AudioPlayer _audioPlayer;

  // State
  bool _isLoading = true;
  String? _error;
  double _scrollOffset = 0;

  // Profile data
  Artist? _artist;
  Venue? _venue;
  bool _isArtist = true;
  bool _isOwnProfile = true;

  // Audio state
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  bool _audioLoading = false;
  String? _audioError;
  int? _playingAudioIndex;

  // Photo state
  int _currentPhotoIndex = 0;

  // Reviews (loaded for future enhancement - show individual reviews)
  // ignore: unused_field
  ReviewStats? _reviewStats;
  // ignore: unused_field
  List<Review>? _reviews;

  // Services
  final _artistService = ArtistService();
  final _venueService = VenueService();
  final _reviewService = ReviewService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
    _loadProfile();
  }

  void _setupAudioListeners() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _audioPosition = position);
      }
    });
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _audioDuration = duration ?? Duration.zero);
      }
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted && state.processingState == ProcessingState.completed) {
        setState(() {
          _playingAudioIndex = null;
          _audioPosition = Duration.zero;
        });
      }
    });
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      if (widget.profileId != null) {
        // External profile view via deep link
        _isOwnProfile = false;
        if (widget.profileType == ProfileViewType.venue) {
          _isArtist = false;
          _venue = await _venueService.getVenueById(widget.profileId!);
        } else {
          _isArtist = true;
          _artist = await _artistService.getArtistById(widget.profileId!);
        }
      } else {
        // Own profile preview
        _isOwnProfile = true;
        _isArtist = auth.isArtist;
        if (_isArtist) {
          _artist = auth.artistProfile ?? await _artistService.getMyProfile();
        } else {
          _venue = auth.venueProfile ?? await _venueService.getMyProfile();
        }
      }

      // Load reviews
      await _loadReviews();

      if (mounted) {
        _fadeController.forward();
        setState(() => _isLoading = false);
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
    _scrollController.dispose();
    _fadeController.dispose();
    _audioPlayer.dispose();
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
      return _artist?.stageName ?? _artist?.displayName ?? 'Artist';
    }
    return _venue?.name ?? 'Venue';
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
      bottomNavigationBar:
          !_isLoading && _error == null && !_isOwnProfile
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
        SliverToBoxAdapter(
          child: _buildProfileInfoCard(brightness),
        ),

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

                // Media Section (Audio/Video for artists, Gallery for venues)
                if (_isArtist) ...[
                  _buildAudioSection(brightness),
                  _buildVideoSection(brightness),
                ],
                _buildGallerySection(brightness),

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
  // SLIVER APP BAR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(Brightness brightness) {
    final headerOpacity = (_scrollOffset / 200).clamp(0.0, 1.0);
    final photos = _isArtist
        ? [
            if (_artist?.profilePhoto != null) _artist!.profilePhoto!,
            ...(_artist?.galleryUrls ?? []),
          ]
        : (_venue?.galleryUrls ?? []);

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: headerOpacity > 0.5
          ? AppColors.surface(brightness).withValues(alpha: headerOpacity)
          : Colors.transparent,
      elevation: 0,
      leading: _buildAppBarButton(
        Icons.arrow_back_rounded,
        () => Navigator.pop(context),
      ),
      actions: [
        if (_isOwnProfile)
          _buildAppBarButton(
            Icons.edit_rounded,
            () => Navigator.pushNamed(context, '/edit-profile'),
          ),
        _buildAppBarButton(Icons.share_rounded, _shareProfile),
      ],
      title: AnimatedOpacity(
        opacity: headerOpacity,
        duration: const Duration(milliseconds: 200),
        child: Text(
          _profileName,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Photo Carousel
            if (photos.isNotEmpty)
              PageView.builder(
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
                itemBuilder: (context, index) {
                  return Image.network(
                    photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _buildPhotoPlaceholder(brightness),
                  );
                },
              )
            else
              _buildPhotoPlaceholder(brightness),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.transparent,
                      AppColors.background(brightness).withValues(alpha: 0.9),
                      AppColors.background(brightness),
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.85, 1.0],
                  ),
                ),
              ),
            ),

            // Photo indicators
            if (photos.length > 1)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(photos.length, (index) {
                    final isActive = index == _currentPhotoIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 24 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),

            // Own profile preview banner
            if (_isOwnProfile)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Preview Mode — This is how others see your profile',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarButton(IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.3),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(Brightness brightness) {
    return Container(
      color: AppColors.surface(brightness),
      child: Center(
        child: Icon(
          _isArtist ? Icons.person_rounded : Icons.business_rounded,
          size: 80,
          color: AppColors.textSec(brightness),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE INFO CARD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileInfoCard(Brightness brightness) {
    final avatarUrl =
        _isArtist ? _artist?.profilePhoto : _venue?.profilePhotoUrl;
    final isVerified =
        _isArtist ? (_artist?.isVerified ?? false) : (_venue?.isVerified ?? false);
    final location = _isArtist
        ? _artist?.location?.city
        : _venue?.location?.city;
    final artistType = _artist?.artistType.name.toUpperCase();

    return Transform.translate(
      offset: const Offset(0, -40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background(brightness),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
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
            const SizedBox(width: 16),

            // Name and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _profileName,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Location and type
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      if (location != null && location.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: AppColors.textSec(brightness),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: TextStyle(
                                color: AppColors.textSec(brightness),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      if (_isArtist && artistType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.rose.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            artistType,
                            style: TextStyle(
                              color: AppColors.rose,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (!_isArtist && _venue?.venueType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _venue!.venueType!.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildAvatarFallback(Brightness brightness) {
    return Container(
      color: AppColors.surface(brightness),
      child: Icon(
        _isArtist ? Icons.person_rounded : Icons.business_rounded,
        size: 40,
        color: AppColors.textSec(brightness),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(Brightness brightness) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: _isArtist
              ? [
                  _buildStatItem(
                    brightness,
                    Icons.star_rounded,
                    (_artist?.averageRating ?? 0).toStringAsFixed(1),
                    'Rating',
                    AppColors.warning,
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    Icons.event_rounded,
                    (_artist?.completedGigs ?? 0).toString(),
                    'Gigs',
                    AppColors.rose,
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    Icons.reviews_rounded,
                    (_artist?.totalReviews ?? 0).toString(),
                    'Reviews',
                    AppColors.crimson,
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    Icons.verified_user_rounded,
                    '${_artist?.reliabilityScore ?? 100}%',
                    'Reliable',
                    AppColors.success,
                  ),
                ]
              : [
                  _buildStatItem(
                    brightness,
                    Icons.star_rounded,
                    (_venue?.reviewStatsAverageRating ?? _venue?.rating ?? 0).toStringAsFixed(1),
                    'Rating',
                    AppColors.warning,
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    Icons.event_rounded,
                    (_venue?.totalGigsHosted ?? 0).toString(),
                    'Gigs Hosted',
                    AppColors.rose,
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    Icons.people_rounded,
                    (_venue?.capacity ?? 0).toString(),
                    'Capacity',
                    AppColors.cyan,
                  ),
                  _buildStatDivider(brightness),
                  _buildStatItem(
                    brightness,
                    Icons.reviews_rounded,
                    (_venue?.reviewCount ?? 0).toString(),
                    'Reviews',
                    AppColors.crimson,
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    Brightness brightness,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontWeight: FontWeight.w800,
              fontSize: 18,
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
  }

  Widget _buildStatDivider(Brightness brightness) {
    return Container(
      width: 1,
      height: 44,
      color: AppColors.divider(brightness),
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
  // AUDIO SECTION (Artists only)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAudioSection(Brightness brightness) {
    final samples = _artist?.audioSamples ?? [];
    if (samples.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      brightness,
      title: 'Music Samples',
      icon: Icons.audiotrack_rounded,
      child: Column(
        children: samples.asMap().entries.map((entry) {
          return _buildAudioPlayer(brightness, entry.value, entry.key);
        }).toList(),
      ),
    );
  }

  Widget _buildAudioPlayer(Brightness brightness, AudioSample sample, int index) {
    final isPlaying = _playingAudioIndex == index;
    final hasUrl = sample.url.isNotEmpty;
    final progress = _audioDuration.inMilliseconds > 0
        ? (_audioPosition.inMilliseconds / _audioDuration.inMilliseconds)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: isPlaying
            ? Border.all(color: AppColors.crimson, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: hasUrl ? () => _toggleAudioPlayback(sample, index) : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.crimson, AppColors.rose],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _audioLoading && isPlaying
                    ? Icons.hourglass_top_rounded
                    : isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sample.title ?? 'Untitled Track',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                if (_audioError != null && isPlaying)
                  Text(
                    _audioError!,
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isPlaying ? progress.clamp(0.0, 1.0) : 0.0,
                      minHeight: 6,
                      backgroundColor: AppColors.crimson.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(AppColors.crimson),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Duration
          Text(
            isPlaying
                ? _formatDuration(_audioPosition.inSeconds)
                : _formatDuration(sample.durationSeconds ?? 0),
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAudioPlayback(AudioSample sample, int index) async {
    if (sample.url.isEmpty) return;

    HapticFeedback.lightImpact();

    if (_playingAudioIndex == index) {
      await _audioPlayer.pause();
      setState(() => _playingAudioIndex = null);
      return;
    }

    setState(() {
      _audioLoading = true;
      _audioError = null;
    });

    try {
      await _audioPlayer.setUrl(sample.url);
      await _audioPlayer.play();
      if (mounted) {
        setState(() {
          _playingAudioIndex = index;
          _audioLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _audioLoading = false;
          _audioError = 'Unable to play audio';
          _playingAudioIndex = null;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VIDEO SECTION (Artists only)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildVideoSection(Brightness brightness) {
    final samples = _artist?.videoSamples ?? [];
    if (samples.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      brightness,
      title: 'Video Samples',
      icon: Icons.videocam_rounded,
      child: SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: samples.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final video = samples[index];
            return _buildVideoThumbnail(brightness, video);
          },
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(Brightness brightness, VideoSample video) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openVideoPlayer(video, brightness);
      },
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video.thumbnailUrl != null)
              Image.network(
                video.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surface(brightness),
                  child: Icon(
                    Icons.videocam_rounded,
                    color: AppColors.textSec(brightness),
                    size: 40,
                  ),
                ),
              )
            else
              Container(
                color: AppColors.surface(brightness),
                child: Icon(
                  Icons.videocam_rounded,
                  color: AppColors.textSec(brightness),
                  size: 40,
                ),
              ),

            // Play button overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            // Title
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  video.title ?? 'Video',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoPlayer(VideoSample video, Brightness brightness) {
    if (video.url.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _VideoPlayerSheet(
        videoUrl: video.url,
        title: video.title ?? 'Video',
        brightness: brightness,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GALLERY SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildGallerySection(Brightness brightness) {
    final photos = _isArtist
        ? (_artist?.galleryUrls ?? [])
        : (_venue?.galleryUrls ?? []);

    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      brightness,
      title: 'Gallery',
      icon: Icons.photo_library_rounded,
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openGalleryViewer(photos, index, brightness),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  photos[index],
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 120,
                    height: 120,
                    color: AppColors.surface(brightness),
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.textSec(brightness),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openGalleryViewer(
    List<String> photos,
    int initialIndex,
    Brightness brightness,
  ) {
    showDialog(
      context: context,
      builder: (context) => _GalleryViewerDialog(
        photos: photos,
        initialIndex: initialIndex,
        brightness: brightness,
      ),
    );
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
    final hasVenuePricing = venuePrefs != null &&
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
        socialItems.add(_SocialItem(Icons.language_rounded, 'Website', links.website!, null));
      }
      if (links.instagram != null && links.instagram!.isNotEmpty) {
        socialItems.add(_SocialItem(Icons.camera_alt_rounded, 'Instagram', links.instagram!, const Color(0xFFE1306C)));
      }
      if (links.spotify != null && links.spotify!.isNotEmpty) {
        socialItems.add(_SocialItem(Icons.music_note_rounded, 'Spotify', links.spotify!, const Color(0xFF1DB954)));
      }
      if (links.youtube != null && links.youtube!.isNotEmpty) {
        socialItems.add(_SocialItem(Icons.play_circle_rounded, 'YouTube', links.youtube!, const Color(0xFFFF0000)));
      }
      if (links.tiktok != null && links.tiktok!.isNotEmpty) {
        socialItems.add(_SocialItem(Icons.music_video_rounded, 'TikTok', links.tiktok!, null));
      }
    } else if (!_isArtist && _venue?.socialLinks != null) {
      final links = _venue!.socialLinks!;
      if (links.website != null && links.website!.isNotEmpty) {
        socialItems.add(_SocialItem(Icons.language_rounded, 'Website', links.website!, null));
      }
      if (links.instagram != null && links.instagram!.isNotEmpty) {
        socialItems.add(_SocialItem(Icons.camera_alt_rounded, 'Instagram', links.instagram!, const Color(0xFFE1306C)));
      }
      if (links.facebook != null && links.facebook!.isNotEmpty) {
        socialItems.add(_SocialItem(Icons.facebook_rounded, 'Facebook', links.facebook!, const Color(0xFF1877F2)));
      }
      if (links.tiktok != null && links.tiktok!.isNotEmpty) {
        socialItems.add(_SocialItem(Icons.music_video_rounded, 'TikTok', links.tiktok!, null));
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
                  color: (item.color ?? AppColors.crimson).withValues(alpha: 0.1),
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
    final uri = url.startsWith('http') ? Uri.parse(url) : Uri.parse('https://$url');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open link')),
        );
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
                if (id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(participantId: id),
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

// ══════════════════════════════════════════════════════════════════════════════
// VIDEO PLAYER SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _VideoPlayerSheet extends StatefulWidget {
  final String videoUrl;
  final String title;
  final Brightness brightness;

  const _VideoPlayerSheet({
    required this.videoUrl,
    required this.title,
    required this.brightness,
  });

  @override
  State<_VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<_VideoPlayerSheet> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.play();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.surface(widget.brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSec(widget.brightness).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: AppColors.text(widget.brightness),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.textSec(widget.brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Video
          AspectRatio(
            aspectRatio:
                _isInitialized ? _controller.value.aspectRatio : 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _hasError
                  ? Container(
                      color: AppColors.surface(widget.brightness),
                      child: Center(
                        child: Text(
                          'Unable to play video',
                          style: TextStyle(
                            color: AppColors.textSec(widget.brightness),
                          ),
                        ),
                      ),
                    )
                  : _isInitialized
                      ? Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            VideoPlayer(_controller),
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: AppColors.crimson,
                                bufferedColor:
                                    AppColors.crimson.withValues(alpha: 0.3),
                                backgroundColor: AppColors.textSec(
                                        widget.brightness)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 16,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_controller.value.isPlaying) {
                                      _controller.pause();
                                    } else {
                                      _controller.play();
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: AppColors.surface(widget.brightness),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.crimson),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GALLERY VIEWER DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _GalleryViewerDialog extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final Brightness brightness;

  const _GalleryViewerDialog({
    required this.photos,
    required this.initialIndex,
    required this.brightness,
  });

  @override
  State<_GalleryViewerDialog> createState() => _GalleryViewerDialogState();
}

class _GalleryViewerDialogState extends State<_GalleryViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Photos
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    widget.photos[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),

          // Page indicator
          if (widget.photos.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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
