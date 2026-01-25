/// 👁️ GIGMATCH Public Profile View
///
/// Shows an artist's public profile as venues see it.
/// Fetches data from backend - works for any artist ID.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/services/services.dart';
import '../core/models/models.dart';

class ArtistPublicProfileScreen extends StatefulWidget {
  final String? artistId; // If null, shows current user's profile

  const ArtistPublicProfileScreen({super.key, this.artistId});

  @override
  State<ArtistPublicProfileScreen> createState() =>
      _ArtistPublicProfileScreenState();
}

class _ArtistPublicProfileScreenState extends State<ArtistPublicProfileScreen> {
  final _scrollController = ScrollController();
  final _artistService = ArtistService();
  final _reviewService = ReviewService();

  bool _isLoading = true;
  String? _error;
  Artist? _artist;
  ReviewStats? _reviewStats;
  List<Review>? _reviews;

  int _currentPhotoIndex = 0;
  int? _playingAudioIndex;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Artist artist;

      if (widget.artistId != null) {
        // Fetch other artist's profile from backend
        artist = await _artistService.getArtistById(widget.artistId!);
      } else {
        // Show current user's profile
        final auth = context.read<AuthProvider>();
        if (auth.artistProfile != null) {
          artist = auth.artistProfile!;
        } else {
          artist = await _artistService.getMyProfile();
        }
      }

      // Load reviews
      ReviewStats? stats;
      List<Review>? reviews;
      try {
        stats = await _reviewService.getArtistStats(artist.id);
        final reviewsResponse = await _reviewService.getArtistReviews(
          artist.id,
        );
        reviews = reviewsResponse.reviews;
      } catch (_) {
        // Reviews might not be available
      }

      if (mounted) {
        setState(() {
          _artist = artist;
          _reviewStats = stats;
          _reviews = reviews;
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isOwnProfile = widget.artistId == null;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: _isLoading
          ? _buildLoading(brightness)
          : _error != null
          ? _buildError(brightness)
          : _buildContent(brightness, isOwnProfile),
    );
  }

  Widget _buildLoading(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.crimson),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(color: AppColors.textSec(brightness)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.crimson,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(color: AppColors.textSec(brightness)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Brightness brightness, bool isOwnProfile) {
    final artist = _artist!;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // App Bar
        SliverAppBar(
          backgroundColor: AppColors.background(brightness),
          expandedHeight: 300,
          pinned: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (isOwnProfile)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white),
                ),
                onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
              ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_rounded, color: Colors.white),
              ),
              onPressed: () => _shareProfile(artist),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeroSection(brightness, artist),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Type
                _buildNameSection(brightness, artist),
                const SizedBox(height: 24),

                // Stats Row
                _buildStatsRow(brightness, artist),
                const SizedBox(height: 24),

                // Bio
                if (artist.bio != null && artist.bio!.isNotEmpty) ...[
                  _buildBioSection(brightness, artist),
                  const SizedBox(height: 24),
                ],

                // Genres
                if (artist.genres.isNotEmpty) ...[
                  _buildGenresSection(brightness, artist),
                  const SizedBox(height: 24),
                ],

                // Audio Samples
                if (artist.audioSamples.isNotEmpty) ...[
                  _buildAudioSection(brightness, artist),
                  const SizedBox(height: 24),
                ],

                // Video Samples
                if (artist.videoSamples.isNotEmpty) ...[
                  _buildVideoSection(brightness, artist),
                  const SizedBox(height: 24),
                ],

                // Photo Gallery
                if (artist.galleryUrls.isNotEmpty) ...[
                  _buildGallerySection(brightness, artist),
                  const SizedBox(height: 24),
                ],

                // Reviews
                if (_reviews != null && _reviews!.isNotEmpty) ...[
                  _buildReviewsSection(brightness),
                  const SizedBox(height: 24),
                ],

                // Pricing
                if (artist.priceRange != null) ...[
                  _buildPricingSection(brightness, artist),
                  const SizedBox(height: 24),
                ],

                // Equipment
                if (artist.equipment.isNotEmpty) ...[
                  _buildEquipmentSection(brightness, artist),
                  const SizedBox(height: 24),
                ],

                // Social Links
                if (artist.socialLinks != null) ...[
                  _buildSocialSection(brightness, artist),
                ],

                const SizedBox(height: 100), // Space for CTA
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(Brightness brightness, Artist artist) {
    final photos = [
      if (artist.profilePhoto != null) artist.profilePhoto!,
      ...artist.galleryUrls,
    ];

    if (photos.isEmpty) {
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

    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
          itemBuilder: (context, index) {
            return Image.network(
              photos[index],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surface(brightness),
                child: const Icon(Icons.broken_image, size: 60),
              ),
            );
          },
        ),

        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),

        // Page indicators
        if (photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (i) {
                return Container(
                  width: _currentPhotoIndex == i ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _currentPhotoIndex == i
                        ? AppColors.crimson
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildNameSection(Brightness brightness, Artist artist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                artist.stageName.isNotEmpty
                    ? artist.stageName
                    : (artist.displayName.isNotEmpty
                          ? artist.displayName
                          : 'Artist'),
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (artist.isVerified)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                artist.artistType.name.toUpperCase(),
                style: TextStyle(
                  color: AppColors.crimson,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.textSec(brightness),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    artist.location?.city ?? 'Location not set',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(Brightness brightness, Artist artist) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            brightness,
            Icons.star_rounded,
            _reviewStats?.averageRating.toStringAsFixed(1) ?? '—',
            'Rating',
            color: Colors.amber,
          ),
          _buildStatDivider(brightness),
          _buildStat(
            brightness,
            Icons.reviews_rounded,
            '${_reviewStats?.totalReviews ?? 0}',
            'Reviews',
          ),
          _buildStatDivider(brightness),
          _buildStat(
            brightness,
            Icons.timer_rounded,
            '${artist.yearsOfExperience ?? 0}y',
            'Experience',
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    Brightness brightness,
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.crimson, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatDivider(Brightness brightness) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider(brightness),
    );
  }

  Widget _buildBioSection(Brightness brightness, Artist artist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(brightness, 'About'),
        const SizedBox(height: 12),
        Text(
          artist.bio!,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGenresSection(Brightness brightness, Artist artist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(brightness, 'Genres'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: artist.genres.map((genre) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.crimson.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAudioSection(Brightness brightness, Artist artist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(brightness, 'Audio Samples'),
        const SizedBox(height: 12),
        ...artist.audioSamples.asMap().entries.map((entry) {
          final index = entry.key;
          final sample = entry.value;
          final isPlaying = _playingAudioIndex == index;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
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
                  onTap: () {
                    setState(() {
                      _playingAudioIndex = isPlaying ? null : index;
                    });
                    // TODO: Integrate audio player
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.crimson,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sample.title ?? 'Track ${index + 1}',
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider(brightness),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Duration
                if (sample.durationSeconds != null)
                  Text(
                    _formatDuration(sample.durationSeconds!),
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildVideoSection(Brightness brightness, Artist artist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(brightness, 'Video Samples'),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: artist.videoSamples.length,
            itemBuilder: (context, index) {
              final video = artist.videoSamples[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(
                  right: index < artist.videoSamples.length - 1 ? 12 : 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  image: video.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(video.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (video.thumbnailUrl == null)
                      Icon(
                        Icons.movie_rounded,
                        color: Colors.white24,
                        size: 48,
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Text(
                        video.title ?? 'Video ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection(Brightness brightness, Artist artist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(brightness, 'Photo Gallery'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: artist.galleryUrls.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                artist.galleryUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surface(brightness),
                  child: Icon(
                    Icons.broken_image,
                    color: AppColors.textSec(brightness),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewsSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(brightness, 'Reviews'),
            TextButton(
              onPressed: () {
                // Navigate to all reviews
              },
              child: Text(
                'See All',
                style: TextStyle(color: AppColors.crimson),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_reviews?.take(3) ?? []).map((review) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.crimson.withValues(alpha: 0.1),
                      backgroundImage: review.reviewerPhoto != null
                          ? NetworkImage(review.reviewerPhoto!)
                          : null,
                      child: review.reviewerPhoto == null
                          ? Text(
                              review.reviewerName[0].toUpperCase(),
                              style: TextStyle(
                                color: AppColors.crimson,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.reviewerName,
                            style: TextStyle(
                              color: AppColors.text(brightness),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < review.overallRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (review.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    review.content,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPricingSection(Brightness brightness, Artist artist) {
    final price = artist.priceRange!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(brightness, 'Pricing'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                color: AppColors.crimson,
                size: 32,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${price.currency} ${price.min.toStringAsFixed(0)} - ${price.max.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'per ${price.per}',
                    style: TextStyle(color: AppColors.textSec(brightness)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSection(Brightness brightness, Artist artist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(brightness, 'Equipment'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: artist.equipment.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(12),
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
                    item,
                    style: TextStyle(color: AppColors.text(brightness)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSocialSection(Brightness brightness, Artist artist) {
    final social = artist.socialLinks!;
    final links = <MapEntry<String, IconData>>[];

    if (social.website != null) {
      links.add(const MapEntry('Website', Icons.language_rounded));
    }
    if (social.instagram != null) {
      links.add(const MapEntry('Instagram', Icons.camera_alt_rounded));
    }
    if (social.spotify != null) {
      links.add(const MapEntry('Spotify', Icons.music_note_rounded));
    }
    if (social.youtube != null) {
      links.add(const MapEntry('YouTube', Icons.play_circle_rounded));
    }

    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(brightness, 'Connect'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: links.map((link) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(link.value, color: AppColors.crimson),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(Brightness brightness, String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.text(brightness),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _shareProfile(Artist artist) {
    final url = 'https://gigmatch.app/artist/${artist.id}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile link copied to clipboard!')),
    );
  }
}
