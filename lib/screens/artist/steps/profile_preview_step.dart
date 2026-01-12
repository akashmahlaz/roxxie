import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/models/artist_models.dart';
import '../artist_profile_setup_screen.dart';

/// Step 5: Profile Preview
/// - Preview how the profile will look to venues
/// - Final confirmation before completing setup

class ProfilePreviewStep extends StatelessWidget {
  final ArtistProfileData profileData;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const ProfilePreviewStep({
    super.key,
    required this.profileData,
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview notice
          _buildPreviewNotice(brightness),

          const SizedBox(height: 20),

          // Profile Card Preview
          _buildProfileCard(brightness),

          const SizedBox(height: 20),

          // Media Section Preview
          if (profileData.audioSamples.isNotEmpty ||
              profileData.videoSamples.isNotEmpty)
            _buildMediaSection(brightness),

          const SizedBox(height: 20),

          // Contact & Availability Summary
          _buildInfoSummary(brightness),

          const SizedBox(height: 32),

          // Complete Setup Button
          _buildNavigationButtons(context, brightness),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPreviewNotice(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.crimson.withValues(alpha: 0.1),
            AppColors.rose.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.visibility_rounded,
              color: AppColors.crimson,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Preview',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is how venues will see your profile in the discovery feed.',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Brightness brightness) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(brightness)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
                child: profileData.profilePhotoPath != null
                    ? Image.file(
                        File(profileData.profilePhotoPath!),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 220,
                        color: AppColors.surface(brightness),
                        child: Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 80,
                            color: AppColors.textTert(brightness),
                          ),
                        ),
                      ),
              ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.cardBackground(brightness),
                      ],
                    ),
                  ),
                ),
              ),

              // Genre tags
              Positioned(
                top: 16,
                left: 16,
                child: Wrap(
                  spacing: 8,
                  children: profileData.genres.take(3).map((genre) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        genre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Price badge
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.crimson,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_getCurrencySymbol()}${profileData.minPrice.toInt()}-${profileData.maxPrice.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Profile Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and stage name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileData.displayName ?? 'Artist Name',
                            style: TextStyle(
                              color: AppColors.text(brightness),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (profileData.stageName != null &&
                              profileData.stageName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              profileData.stageName!,
                              style: TextStyle(
                                color: AppColors.crimson,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Verified badge placeholder
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface(brightness),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        color: AppColors.textTert(brightness),
                        size: 18,
                      ),
                    ),
                  ],
                ),

                // Location
                if (profileData.city != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.textSec(brightness),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${profileData.city}${profileData.country != null ? ', ${profileData.country}' : ''}',
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${profileData.travelRadius}mi radius',
                        style: TextStyle(
                          color: AppColors.textTert(brightness),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],

                // Bio
                if (profileData.bio != null && profileData.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    profileData.bio!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],

                // Influences
                if (profileData.influences.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: AppColors.textTert(brightness),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Influenced by: ${profileData.influences.take(3).join(', ')}${profileData.influences.length > 3 ? '...' : ''}',
                          style: TextStyle(
                            color: AppColors.textTert(brightness),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Quick Contact Buttons (Preview)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.crimson,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.message_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Message',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (profileData.phone != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface(brightness),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border(brightness),
                          ),
                        ),
                        child: Icon(
                          Icons.phone_rounded,
                          color: AppColors.crimson,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media Samples',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Audio samples
        if (profileData.audioSamples.isNotEmpty) ...[
          ...profileData.audioSamples.map((sample) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.crimson.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.crimson,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sample.title,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (sample.duration != null)
                          Text(
                            _formatDuration(sample.duration!),
                            style: TextStyle(
                              color: AppColors.textTert(brightness),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.music_note_rounded,
                    color: AppColors.textTert(brightness),
                    size: 18,
                  ),
                ],
              ),
            );
          }),
        ],

        // Video samples
        if (profileData.videoSamples.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: profileData.videoSamples.length,
              itemBuilder: (context, index) {
                final video = profileData.videoSamples[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface(brightness),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(brightness)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.videocam_rounded,
                          color: AppColors.textTert(brightness),
                          size: 32,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Text(
                          video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
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
      ],
    );
  }

  Widget _buildInfoSummary(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Summary',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Summary items
          _buildSummaryItem(
            Icons.music_note_rounded,
            'Genres',
            profileData.genres.join(', '),
            brightness,
          ),
          _buildSummaryItem(
            Icons.attach_money_rounded,
            'Price Range',
            '${_getCurrencySymbol()}${profileData.minPrice.toInt()} - ${_getCurrencySymbol()}${profileData.maxPrice.toInt()}',
            brightness,
          ),
          _buildSummaryItem(
            Icons.calendar_month_rounded,
            'Availability',
            '${profileData.availability.length} dates selected',
            brightness,
          ),
          if (profileData.phone != null)
            _buildSummaryItem(
              Icons.phone_rounded,
              'Phone',
              profileData.phone!,
              brightness,
            ),
          if (profileData.email != null)
            _buildSummaryItem(
              Icons.email_rounded,
              'Email',
              profileData.email!,
              brightness,
            ),

          // Social links count
          _buildSocialLinksItem(brightness),
        ],
      ),
    );
  }

  Widget _buildSocialLinksItem(Brightness brightness) {
    final socialCount = [
      profileData.instagram,
      profileData.spotify,
      profileData.youtube,
      profileData.website,
    ].where((e) => e != null && e.isNotEmpty).length;

    if (socialCount == 0) return const SizedBox.shrink();

    return _buildSummaryItem(
      Icons.link_rounded,
      'Social Links',
      '$socialCount connected',
      brightness,
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String value,
    Brightness brightness,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.crimson, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, Brightness brightness) {
    return Column(
      children: [
        // Complete Setup Button
        GestureDetector(
          onTap: onComplete,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.crimson, AppColors.rose],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'Complete Setup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Back button
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Center(
              child: Text(
                'Back to Edit',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getCurrencySymbol() {
    switch (profileData.currency) {
      case 'USD':
      case 'CAD':
      case 'AUD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      default:
        return '\$';
    }
  }
}
