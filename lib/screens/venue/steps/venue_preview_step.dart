import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/models/venue_models.dart';

/// 👁️ STEP 5: VENUE PREVIEW
///
/// Shows:
/// - Full preview of the venue profile
/// - Summary of all entered information
/// - Complete setup button

class VenuePreviewStep extends StatelessWidget {
  final VenueProfileData profileData;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  const VenuePreviewStep({
    super.key,
    required this.profileData,
    required this.onBack,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Header
          _buildPreviewHeader(brightness),

          const SizedBox(height: 24),

          // Venue Profile Card
          _buildVenueCard(brightness),

          // Gallery Section
          if (profileData.venuePhotos.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildGallerySection(brightness),
          ],

          const SizedBox(height: 24),

          // Details Summary
          _buildDetailsSummary(brightness),

          const SizedBox(height: 24),

          // Gig Preferences Summary
          _buildGigPreferencesSummary(brightness),

          const SizedBox(height: 24),

          // What You Provide
          _buildPerksSummary(brightness),

          const SizedBox(height: 40),

          // Navigation Buttons
          _buildNavigationButtons(context, brightness),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGallerySection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library_rounded,
              color: AppColors.crimson,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Gallery',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${profileData.venuePhotos.length}',
                style: const TextStyle(
                  color: AppColors.crimson,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profileData.venuePhotos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final photo = profileData.venuePhotos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface(brightness),
                    image: DecorationImage(
                      image: _getImageProvider(photo),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewHeader(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.crimson.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.preview_rounded,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This is how artists will see your venue',
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
    );
  }

  /// Helper to get proper image provider for local or network images
  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  Widget _buildVenueCard(Brightness brightness) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(brightness)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Photo
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
              image: profileData.coverPhoto != null
                  ? DecorationImage(
                      image: _getImageProvider(profileData.coverPhoto!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Placeholder only if no cover photo
                if (profileData.coverPhoto == null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          color: AppColors.crimson.withValues(alpha: 0.5),
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No cover photo',
                          style: TextStyle(
                            color: AppColors.textSec(brightness),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Gradient overlay for text readability
                if (profileData.coverPhoto != null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Venue Type Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (profileData.venueType?.isNotEmpty ?? false)
                              ? profileData.venueType!
                              : 'Venue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Capacity Badge
                if (profileData.capacity > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profileData.capacity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Venue Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Location
                Text(
                  (profileData.venueName?.isNotEmpty ?? false)
                      ? profileData.venueName!
                      : 'Your Venue Name',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: AppColors.textSec(brightness),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (profileData.city?.isNotEmpty ?? false)
                          ? '${profileData.city}${(profileData.country?.isNotEmpty ?? false) ? ', ${profileData.country}' : ''}'
                          : 'City, Country',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                if ((profileData.description?.isNotEmpty ?? false)) ...[
                  Text(
                    profileData.description!,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],

                // Budget Range
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Typical Budget',
                            style: TextStyle(
                              color: AppColors.textSec(brightness),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getCurrencySymbol()}${(profileData.minBudget ?? 0.0).toInt()} - ${_getCurrencySymbol()}${(profileData.maxBudget ?? 0.0).toInt()}',
                            style: const TextStyle(
                              color: AppColors.crimson,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.crimson,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.message_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Contact',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSummary(Brightness brightness) {
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
            'Contact & Details',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          if ((profileData.address?.isNotEmpty ?? false))
            _buildDetailItem(
              Icons.home_rounded,
              'Address',
              profileData.address!,
              brightness,
            ),

          if (profileData.phone != null && profileData.phone!.isNotEmpty)
            _buildDetailItem(
              Icons.phone_rounded,
              'Phone',
              profileData.phone!,
              brightness,
            ),

          if (profileData.email != null && profileData.email!.isNotEmpty)
            _buildDetailItem(
              Icons.email_rounded,
              'Email',
              profileData.email!,
              brightness,
            ),

          if (profileData.website != null && profileData.website!.isNotEmpty)
            _buildDetailItem(
              Icons.language_rounded,
              'Website',
              profileData.website!,
              brightness,
            ),

          if (profileData.instagram != null &&
              profileData.instagram!.isNotEmpty)
            _buildDetailItem(
              Icons.camera_alt_rounded,
              'Instagram',
              profileData.instagram!,
              brightness,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    Brightness brightness,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.crimson, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGigPreferencesSummary(Brightness brightness) {
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
            'Gig Preferences',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Preferred Genres
          if (profileData.preferredGenres.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.crimson,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: profileData.preferredGenres.map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.crimson.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: AppColors.crimson,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Typical Slots
          if (profileData.typicalSlots.isNotEmpty)
            _buildDetailItem(
              Icons.access_time_rounded,
              'Slots',
              profileData.typicalSlots.join(', '),
              brightness,
            ),

          // Set Length
          _buildDetailItem(
            Icons.timer_rounded,
            'Set Length',
            _formatSetLength(profileData.typicalSetLength),
            brightness,
          ),
        ],
      ),
    );
  }

  Widget _buildPerksSummary(Brightness brightness) {
    final perks = <String>[];
    if (profileData.providesAccommodation) perks.add('Accommodation');
    if (profileData.providesMeals) perks.add('Meals');
    if (profileData.providesEquipment) perks.add('Equipment');

    if (perks.isEmpty) return const SizedBox.shrink();

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
            'What We Provide',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: perks.map((perk) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      perk,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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

  String _formatSetLength(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hour${hours > 1 ? 's' : ''}';
    return '$hours hr ${mins}min';
  }

  Widget _buildNavigationButtons(BuildContext context, Brightness brightness) {
    return Column(
      children: [
        // Complete Setup Button
        GestureDetector(
          onTap: onComplete,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.crimson, Color(0xFFFF4D6D)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Complete Setup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Back Button
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.text(brightness),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Back to Edit',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
