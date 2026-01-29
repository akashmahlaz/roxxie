/// 👁️ GIGMATCH Public Profile View
///
/// Shows what venues/artists see when viewing your profile
/// - Hero section with photo/video
/// - Audio player with samples
/// - Stats and reviews
/// - Booking CTA
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user's profile

  const PublicProfileScreen({super.key, this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;
  late AudioPlayer _audioPlayer;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  bool _audioLoading = false;
  String? _audioError;

  double _headerOpacity = 0.0;
  int _currentPhotoIndex = 0;
  int? _playingAudioIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _audioPlayer = AudioPlayer();
    _audioPlayer.positionStream.listen((position) {
      if (!mounted) {
        return;
      }
      setState(() => _audioPosition = position);
    });
    _audioPlayer.durationStream.listen((duration) {
      if (!mounted) {
        return;
      }
      setState(() => _audioDuration = duration ?? Duration.zero);
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingAudioIndex = null;
          _audioPosition = Duration.zero;
        });
      }
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _headerOpacity = (offset / 200).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();
    final artist = auth.artistProfile;
    final venue = auth.venueProfile;
    final isArtist = auth.isArtist;
    final isOwnProfile = widget.userId == null;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(brightness, isOwnProfile, isArtist, artist),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: _buildHeroSection(
              context,
              brightness,
              isArtist,
              artist,
              venue,
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: _buildMainContent(
              context,
              brightness,
              isArtist,
              artist,
              venue,
              isOwnProfile,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwnProfile
          ? null
          : _buildBookingBar(context, brightness, isArtist),
    );
  }

  PreferredSizeWidget _buildAppBar(
    Brightness brightness,
    bool isOwnProfile,
    bool isArtist,
    Artist? artist,
  ) {
    return AppBar(
      backgroundColor: _headerOpacity > 0.5
          ? AppColors.surface(brightness).withValues(alpha: _headerOpacity)
          : Colors.transparent,
      elevation: 0,
      leading: GlassBackButton(onPressed: () => Navigator.pop(context)),
      title: AnimatedOpacity(
        opacity: _headerOpacity,
        duration: const Duration(milliseconds: 200),
        child: Text(
          isArtist
              ? (artist?.stageName ?? artist?.displayName ?? 'Artist')
              : 'Venue',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _shareProfile,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        if (isOwnProfile)
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  void _shareProfile() {
    final auth = context.read<AuthProvider>();
    final profileUrl = 'https://gigmatch.app/profile/${auth.user?.id ?? ''}';
    final message = 'Check out my profile on GigMatch! 🎵\n$profileUrl';
    SharePlus.instance.share(ShareParams(text: message));
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile link copied to clipboard!')),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    Brightness brightness,
    bool isArtist,
    Artist? artist,
    Venue? venue,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final photos = isArtist
        ? (artist?.galleryUrls ?? [])
        : (venue?.galleryUrls ?? []);
    final primaryPhoto = isArtist
        ? artist?.profilePhoto
        : (photos.isNotEmpty ? photos.first : null);

    return SizedBox(
      height: screenHeight * 0.55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo carousel
          if (photos.isNotEmpty)
            PageView.builder(
              itemCount: photos.length,
              onPageChanged: (index) =>
                  setState(() => _currentPhotoIndex = index),
              itemBuilder: (context, index) {
                return Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildPhotoPlaceholder(brightness),
                );
              },
            )
          else if (primaryPhoto != null)
            Image.network(
              primaryPhoto,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPhotoPlaceholder(brightness),
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
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.background(brightness).withValues(alpha: 0.8),
                    AppColors.background(brightness),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Photo indicators
          if (photos.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
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

          // Profile info at bottom of hero
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildProfileAvatar(brightness, isArtist, artist, venue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and verified badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isArtist
                                    ? (artist?.stageName ??
                                          artist?.displayName ??
                                          'Artist')
                                    : (venue?.name ?? 'Venue'),
                                style: TextStyle(
                                  color: AppColors.text(brightness),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if ((isArtist && artist?.isVerified == true) ||
                                (!isArtist && venue?.isVerified == true))
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.crimson,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Location and artist type
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: AppColors.textSec(brightness),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isArtist
                                  ? (artist?.location?.city ??
                                        'Location not set')
                                  : (venue?.location?.city ??
                                        'Location not set'),
                              style: TextStyle(
                                color: AppColors.textSec(brightness),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isArtist && artist != null) ...[
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
                                  artist.artistType.name.toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.rose,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Genres
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              (isArtist
                                      ? (artist?.genres ?? [])
                                      : (venue
                                                ?.gigPreferences
                                                ?.preferredGenres ??
                                            []))
                                  .take(4)
                                  .map(
                                    (genre) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.crimson.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        genre,
                                        style: TextStyle(
                                          color: AppColors.crimson,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
    Brightness brightness,
    bool isArtist,
    Artist? artist,
    Venue? venue,
  ) {
    final avatarUrl = isArtist ? artist?.profilePhoto : venue?.profilePhotoUrl;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background(brightness), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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
                errorBuilder: (_, _, _) => _buildAvatarFallback(brightness),
              )
            : _buildAvatarFallback(brightness),
      ),
    );
  }

  Widget _buildAvatarFallback(Brightness brightness) {
    return Container(
      color: AppColors.surface(brightness),
      child: Icon(
        Icons.person_rounded,
        size: 32,
        color: AppColors.textSec(brightness),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(Brightness brightness) {
    return Container(
      color: AppColors.surface(brightness),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 80,
          color: AppColors.textSec(brightness),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    Brightness brightness,
    bool isArtist,
    Artist? artist,
    Venue? venue,
    bool isOwnProfile,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          _buildStatsRow(context, brightness, isArtist, artist, venue),
          const SizedBox(height: 24),

          // Bio Section
          _buildSection(
            context,
            brightness,
            title: 'About',
            icon: Icons.info_outline_rounded,
            child: Text(
              isArtist
                  ? (artist?.bio ?? 'No bio yet')
                  : (venue?.description ?? 'No description yet'),
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Audio Samples Section (Artists only)
          if (isArtist && artist != null && artist.audioSamples.isNotEmpty) ...[
            _buildSection(
              context,
              brightness,
              title: 'Music Samples',
              icon: Icons.audiotrack_rounded,
              child: Column(
                children: artist.audioSamples.asMap().entries.map((entry) {
                  return _buildAudioPlayer(
                    context,
                    brightness,
                    entry.value,
                    entry.key,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Video Samples Section (Artists only)
          if (isArtist && artist != null && artist.videoSamples.isNotEmpty) ...[
            _buildSection(
              context,
              brightness,
              title: 'Video Samples',
              icon: Icons.videocam_rounded,
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: artist.videoSamples.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final video = artist.videoSamples[index];
                    return _buildVideoThumbnail(context, brightness, video);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Equipment Section (Artists only)
          if (isArtist && artist != null && artist.equipment.isNotEmpty) ...[
            _buildSection(
              context,
              brightness,
              title: 'Equipment',
              icon: Icons.speaker_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: artist.equipment.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 16,
                        ),
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
            ),
            const SizedBox(height: 24),
          ],

          // Pricing Section
          if (isArtist && artist?.priceRange != null) ...[
            _buildSection(
              context,
              brightness,
              title: 'Pricing',
              icon: Icons.attach_money_rounded,
              child: _buildPricingCard(
                context,
                brightness,
                artist!.priceRange!,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Social Links
          if (isArtist && artist?.socialLinks != null) ...[
            _buildSection(
              context,
              brightness,
              title: 'Connect',
              icon: Icons.link_rounded,
              child: _buildSocialLinks(
                context,
                brightness,
                artist!.socialLinks!,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Reviews Preview
          _buildSection(
            context,
            brightness,
            title: 'Reviews',
            icon: Icons.star_rounded,
            trailing: TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed('/reviews');
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child: _buildReviewsPreview(context, brightness, isArtist, artist),
          ),

          SizedBox(height: isOwnProfile ? 40 : 100),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    Brightness brightness,
    bool isArtist,
    Artist? artist,
    Venue? venue,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatItem(
            context,
            brightness,
            icon: Icons.star_rounded,
            value: isArtist
                ? (artist?.averageRating ?? 0).toStringAsFixed(1)
                : '4.8',
            label: 'Rating',
            color: AppColors.warning,
          ),
          _buildStatDivider(brightness),
          _buildStatItem(
            context,
            brightness,
            icon: Icons.event_rounded,
            value: isArtist ? (artist?.completedGigs ?? 0).toString() : '0',
            label: 'Gigs',
            color: AppColors.rose,
          ),
          _buildStatDivider(brightness),
          _buildStatItem(
            context,
            brightness,
            icon: Icons.reviews_rounded,
            value: isArtist ? (artist?.totalReviews ?? 0).toString() : '0',
            label: 'Reviews',
            color: AppColors.crimson,
          ),
          _buildStatDivider(brightness),
          _buildStatItem(
            context,
            brightness,
            icon: Icons.verified_user_rounded,
            value: isArtist ? '${artist?.reliabilityScore ?? 100}%' : '100%',
            label: 'Reliable',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    Brightness brightness, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
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
      height: 40,
      color: AppColors.divider(brightness),
    );
  }

  Widget _buildSection(
    BuildContext context,
    Brightness brightness, {
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.crimson, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildAudioPlayer(
    BuildContext context,
    Brightness brightness,
    AudioSample sample,
    int index,
  ) {
    final isPlaying = _playingAudioIndex == index;
    final hasUrl = (sample.url.isNotEmpty);
    final progress = _audioDuration.inMilliseconds > 0
        ? (_audioPosition.inMilliseconds / _audioDuration.inMilliseconds)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.crimson, AppColors.rose],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _audioLoading && isPlaying
                    ? Icons.hourglass_top_rounded
                    : isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Track info and waveform
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sample.title ?? 'Untitled Track',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Progress + waveform
                if (_audioError != null && isPlaying) ...[
                  Text(
                    _audioError!,
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: isPlaying ? progress.clamp(0.0, 1.0) : 0.0,
                    minHeight: 6,
                    backgroundColor: AppColors.crimson.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(AppColors.crimson),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 16,
                  child: Row(
                    children: List.generate(24, (i) {
                      final height = 5.0 + (i % 6) * 2.0;
                      final barProgress = isPlaying ? (i / 24) : 0.0;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: height,
                          decoration: BoxDecoration(
                            color: barProgress < progress
                                ? AppColors.crimson
                                : AppColors.crimson.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Duration
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDuration(sample.durationSeconds ?? 0),
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              if (isPlaying)
                Text(
                  _formatDuration(_audioPosition.inSeconds),
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildVideoThumbnail(
    BuildContext context,
    Brightness brightness,
    VideoSample video,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openVideoPlayer(video, brightness);
      },
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
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

            // Play overlay
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

            // Title at bottom
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

  Widget _buildPricingCard(
    BuildContext context,
    Brightness brightness,
    PriceRange priceRange,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.crimson.withValues(alpha: 0.1),
            AppColors.rose.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, color: AppColors.crimson, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${priceRange.min.toInt()} - \$${priceRange.max.toInt()}',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              Text(
                'per ${priceRange.per}',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks(
    BuildContext context,
    Brightness brightness,
    SocialLinks links,
  ) {
    final socialItems = <_SocialLinkItem>[
      if (links.website != null && links.website!.isNotEmpty)
        _SocialLinkItem(
          Icons.language_rounded,
          'Website',
          links.website!,
          null,
        ),
      if (links.instagram != null && links.instagram!.isNotEmpty)
        _SocialLinkItem(
          Icons.camera_alt_rounded,
          'Instagram',
          links.instagram!,
          const Color(0xFFE1306C),
        ),
      if (links.spotify != null && links.spotify!.isNotEmpty)
        _SocialLinkItem(
          Icons.music_note_rounded,
          'Spotify',
          links.spotify!,
          const Color(0xFF1DB954),
        ),
      if (links.youtube != null && links.youtube!.isNotEmpty)
        _SocialLinkItem(
          Icons.play_circle_rounded,
          'YouTube',
          links.youtube!,
          const Color(0xFFFF0000),
        ),
    ];

    if (socialItems.isEmpty) {
      return Text(
        'No social links added',
        style: TextStyle(
          color: AppColors.textSec(brightness),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      children: socialItems.map((item) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _openSocialLink(item.url, brightness),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (item.color ?? AppColors.crimson).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
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
    );
  }

  Future<void> _toggleAudioPlayback(AudioSample sample, int index) async {
    if (sample.url.isEmpty) {
      return;
    }

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
      if (!mounted) {
        return;
      }
      setState(() {
        _playingAudioIndex = index;
        _audioLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _audioLoading = false;
        _audioError = 'Unable to play audio';
        _playingAudioIndex = null;
      });
    }
  }

  Future<void> _openSocialLink(String url, Brightness brightness) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = _normalizeUrl(url);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Unable to open link'),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Unable to open link'),
          backgroundColor: AppColors.crimson,
        ),
      );
    }
  }

  Uri _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Uri.parse(url);
    }
    return Uri.parse('https://$url');
  }

  void _openVideoPlayer(VideoSample video, Brightness brightness) {
    if (video.url.isEmpty) {
      return;
    }
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

  Widget _buildReviewsPreview(
    BuildContext context,
    Brightness brightness,
    bool isArtist,
    Artist? artist,
  ) {
    // Show placeholder if no reviews
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Big rating number
              Text(
                (artist?.averageRating ?? 0).toStringAsFixed(1),
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w800,
                  fontSize: 40,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      final rating = artist?.averageRating ?? 0;
                      return Icon(
                        index < rating.floor()
                            ? Icons.star_rounded
                            : (index < rating)
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${artist?.totalReviews ?? 0} reviews',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingBar(
    BuildContext context,
    Brightness brightness,
    bool isArtist,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        border: Border(top: BorderSide(color: AppColors.divider(brightness))),
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
                if (widget.userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(participantId: widget.userId),
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

          // Book button
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Navigate to booking flow
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text(
                isArtist ? 'Book This Artist' : 'Inquire About Venue',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLinkItem {
  final IconData icon;
  final String label;
  final String url;
  final Color? color;

  _SocialLinkItem(this.icon, this.label, this.url, this.color);
}

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
      if (!mounted) {
        return;
      }
      setState(() => _isInitialized = true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _hasError = true);
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSec(
                widget.brightness,
              ).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
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
          AspectRatio(
            aspectRatio: _isInitialized
                ? _controller.value.aspectRatio
                : 16 / 9,
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
                            bufferedColor: AppColors.crimson.withValues(
                              alpha: 0.3,
                            ),
                            backgroundColor: AppColors.textSec(
                              widget.brightness,
                            ).withValues(alpha: 0.2),
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
                          valueColor: AlwaysStoppedAnimation(AppColors.crimson),
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
