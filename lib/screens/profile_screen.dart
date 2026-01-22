/// 👤 GIGMATCH Profile Screen
/// 
/// 2026 Design Principles Applied:
/// - Liquid Glass effects for cards
/// - Micro-interactions on all tap targets
/// - Animated statistics
/// - Premium badge animations
///
/// User profile and settings with dynamic theming
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final user = auth.user;
            final artist = auth.artistProfile;
            final venue = auth.venueProfile;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile header
                  _ProfileHeader(
                    name: user?.name ?? 'User',
                    photoUrl: user?.profilePhotoUrl,
                    isArtist: auth.isArtist,
                    stageName: artist?.stageName,
                    venueName: venue?.name,
                    isVerified:
                        artist?.isVerified ?? venue?.isVerified ?? false,
                    brightness: brightness,
                  ),

                  const SizedBox(height: 24),

                  // Bio Section
                  if (auth.isArtist && artist?.bio != null && artist!.bio!.isNotEmpty)
                    _BioSection(bio: artist.bio!, brightness: brightness)
                  else if (auth.isVenue && venue?.description != null && venue!.description!.isNotEmpty)
                    _BioSection(bio: venue.description!, brightness: brightness),

                  const SizedBox(height: 20),

                  // Stats
                  if (auth.isArtist && artist != null)
                    _ArtistStats(artist: artist, brightness: brightness)
                  else if (auth.isVenue && venue != null)
                    _VenueStats(venue: venue, brightness: brightness),

                  const SizedBox(height: 24),
                  
                  // Contact & Location Info (Venue Only)
                  if (auth.isVenue && venue != null)
                    _VenueContactSection(venue: venue, brightness: brightness),

                  const SizedBox(height: 24),

                  // Media Gallery Section
                  if (auth.isArtist && artist != null)
                    _ArtistMediaSection(artist: artist, brightness: brightness)
                  else if (auth.isVenue && venue != null)
                    _VenueGallerySection(venue: venue, brightness: brightness),

                  const SizedBox(height: 24),

                  // Menu items
                  _MenuItem(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                    brightness: brightness,
                  ),
                  _MenuItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                    brightness: brightness,
                  ),
                  _MenuItem(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Upgrade to Premium',
                    onTap: () => Navigator.pushNamed(context, '/premium'),
                    brightness: brightness,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () => Navigator.pushNamed(context, '/support'),
                    brightness: brightness,
                  ),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    onTap: () => Navigator.pushNamed(context, '/about'),
                    brightness: brightness,
                  ),

                  const SizedBox(height: 24),

                  // Logout button
                  OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, brightness),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.crimson,
                      side: const BorderSide(color: AppColors.crimson),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App version
                  Text(
                    'GigMatch v1.0.0',
                    style: TextStyle(
                      color: AppColors.textTert(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, Brightness brightness) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        title: Text(
          'Sign Out?',
          style: TextStyle(color: AppColors.text(brightness)),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSec(brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/role-selection',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.crimson),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile Header
class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool isArtist;
  final String? stageName;
  final String? venueName;
  final bool isVerified;
  final Brightness brightness;

  const _ProfileHeader({
    required this.name,
    this.photoUrl,
    required this.isArtist,
    this.stageName,
    this.venueName,
    required this.isVerified,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surface(brightness),
              backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Icon(
                      isArtist ? Icons.music_note : Icons.business,
                      size: 40,
                      color: AppColors.textSec(brightness),
                    )
                  : null,
            ),
            if (isVerified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Name
        Text(
          isArtist ? (stageName ?? name) : (venueName ?? name),
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.text(brightness),
          ),
        ),

        // Role badge
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isArtist ? 'Artist' : 'Venue',
            style: const TextStyle(
              color: AppColors.crimson,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Artist Stats
class _ArtistStats extends StatelessWidget {
  final dynamic artist;
  final Brightness brightness;

  const _ArtistStats({required this.artist, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '${artist.rating.toStringAsFixed(1)}',
            label: 'Rating',
            icon: Icons.star,
            brightness: brightness,
          ),
          _StatItem(
            value: '${artist.reviewCount}',
            label: 'Reviews',
            icon: Icons.rate_review,
            brightness: brightness,
          ),
          _StatItem(
            value: artist.genres.length.toString(),
            label: 'Genres',
            icon: Icons.music_note,
            brightness: brightness,
          ),
        ],
      ),
    );
  }
}

/// Venue Stats
class _VenueStats extends StatelessWidget {
  final dynamic venue;
  final Brightness brightness;

  const _VenueStats({required this.venue, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '${venue.rating.toStringAsFixed(1)}',
            label: 'Rating',
            icon: Icons.star,
            brightness: brightness,
          ),
          _StatItem(
            value: '${venue.capacity}',
            label: 'Capacity',
            icon: Icons.people,
            brightness: brightness,
          ),
          _StatItem(
            value: '${venue.reviewCount}',
            label: 'Reviews',
            icon: Icons.rate_review,
            brightness: brightness,
          ),
        ],
      ),
    );
  }
}

/// Stat Item
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Brightness brightness;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    // Try to parse numeric value for animation
    final numericValue = double.tryParse(value.replaceAll(',', ''));
    
    return AnimatedTapFeedback(
      onTap: () => HapticFeedback.selectionClick(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.crimson, size: 22),
          ),
          const SizedBox(height: 10),
          if (numericValue != null && numericValue % 1 == 0)
            AnimatedCounter(
              value: numericValue.toInt(),
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
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
}

/// Menu Item
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Brightness brightness;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedTapFeedback(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border(brightness),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.crimson, size: 22),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: trailing ?? Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSec(brightness),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bio Section
class _BioSection extends StatelessWidget {
  final String bio;
  final Brightness brightness;

  const _BioSection({required this.bio, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: AppColors.crimson,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bio,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Artist Media Section
class _ArtistMediaSection extends StatelessWidget {
  final dynamic artist;
  final Brightness brightness;

  const _ArtistMediaSection({required this.artist, required this.brightness});

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = artist.audioSamples != null && (artist.audioSamples as List).isNotEmpty;
    final hasPhotos = artist.galleryUrls != null && (artist.galleryUrls as List).isNotEmpty;
    
    if (!hasAudio && !hasPhotos) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audio Samples
        if (hasAudio) ...[
          _SectionHeader(
            icon: Icons.headphones_rounded,
            title: 'Audio Samples',
            count: (artist.audioSamples as List).length,
            brightness: brightness,
          ),
          const SizedBox(height: 12),
          ...(artist.audioSamples as List).take(3).map<Widget>((sample) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                    child: const Icon(
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
                          sample['title'] ?? 'Untitled Track',
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (sample['durationSeconds'] != null)
                          Text(
                            _formatDuration(sample['durationSeconds']),
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
          const SizedBox(height: 16),
        ],

        // Gallery Photos
        if (hasPhotos) ...[
          _SectionHeader(
            icon: Icons.photo_library_rounded,
            title: 'Gallery',
            count: (artist.galleryUrls as List).length,
            brightness: brightness,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: (artist.galleryUrls as List).length > 5 ? 5 : (artist.galleryUrls as List).length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photo = (artist.galleryUrls as List)[index];
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
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 📞 VENUE CONTACT SECTION - Phone, Email, Address, Social Links
// ═══════════════════════════════════════════════════════════════════════════════

/// Contact & Location Section for Venues
class _VenueContactSection extends StatelessWidget {
  final dynamic venue;
  final Brightness brightness;

  const _VenueContactSection({required this.venue, required this.brightness});

  @override
  Widget build(BuildContext context) {
    // Gather available contact info
    final hasPhone = venue.phone != null && venue.phone.isNotEmpty;
    final hasEmail = venue.contactEmail != null && venue.contactEmail.isNotEmpty;
    final hasAddress = venue.location?.streetAddress != null || 
                       venue.location?.city != null ||
                       venue.displayLocation != null;
    final hasWebsite = venue.socialLinks?.website != null;
    final hasInstagram = venue.socialLinks?.instagram != null;
    final hasOperatingHours = venue.operatingHours != null && (venue.operatingHours as List).isNotEmpty;
    
    // Don't render if no contact info available
    if (!hasPhone && !hasEmail && !hasAddress && !hasWebsite && !hasInstagram && !hasOperatingHours) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contact Info Card
        if (hasPhone || hasEmail || hasAddress || hasWebsite || hasInstagram)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                Row(
                  children: [
                    Icon(
                      Icons.contact_phone_rounded,
                      color: AppColors.crimson,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Contact Info',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Phone
                if (hasPhone)
                  _ContactRow(
                    icon: Icons.phone_rounded,
                    value: venue.phone!,
                    brightness: brightness,
                  ),
                
                // Email
                if (hasEmail)
                  _ContactRow(
                    icon: Icons.email_rounded,
                    value: venue.contactEmail!,
                    brightness: brightness,
                  ),
                
                // Address
                if (hasAddress)
                  _ContactRow(
                    icon: Icons.location_on_rounded,
                    value: _buildAddressString(venue),
                    brightness: brightness,
                  ),
                
                // Website
                if (hasWebsite)
                  _ContactRow(
                    icon: Icons.language_rounded,
                    value: venue.socialLinks!.website!,
                    brightness: brightness,
                    isLink: true,
                  ),
                
                // Instagram
                if (hasInstagram)
                  _ContactRow(
                    icon: Icons.camera_alt_rounded,
                    value: venue.socialLinks!.instagram!,
                    brightness: brightness,
                    isLink: true,
                  ),
              ],
            ),
          ),
        
        // Operating Hours Card
        if (hasOperatingHours) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: AppColors.crimson,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Operating Hours',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Hours list
                ...(venue.operatingHours as List).map<Widget>((hours) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hours.dayOfWeek.toString().substring(0, 3),
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          hours.isOpen
                              ? '${hours.openTime ?? '--:--'} - ${hours.closeTime ?? '--:--'}'
                              : 'Closed',
                          style: TextStyle(
                            color: hours.isOpen 
                                ? AppColors.textSec(brightness)
                                : AppColors.crimson,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  String _buildAddressString(dynamic venue) {
    final parts = <String>[];
    
    if (venue.location?.streetAddress != null && venue.location.streetAddress.isNotEmpty) {
      parts.add(venue.location.streetAddress);
    }
    if (venue.location?.city != null && venue.location.city.isNotEmpty) {
      parts.add(venue.location.city);
    }
    if (venue.location?.country != null && venue.location.country.isNotEmpty) {
      parts.add(venue.location.country);
    }
    
    if (parts.isEmpty && venue.displayLocation != null) {
      return venue.displayLocation;
    }
    
    return parts.join(', ');
  }
}

/// Contact Info Row Widget
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final Brightness brightness;
  final bool isLink;

  const _ContactRow({
    required this.icon,
    required this.value,
    required this.brightness,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.crimson, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isLink ? AppColors.crimson : AppColors.text(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Venue Gallery Section
class _VenueGallerySection extends StatelessWidget {
  final dynamic venue;
  final Brightness brightness;

  const _VenueGallerySection({required this.venue, required this.brightness});

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = venue.galleryUrls != null && (venue.galleryUrls as List).isNotEmpty;
    
    if (!hasPhotos) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.photo_library_rounded,
          title: 'Venue Gallery',
          count: (venue.galleryUrls as List).length,
          brightness: brightness,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: (venue.galleryUrls as List).length > 5 ? 5 : (venue.galleryUrls as List).length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final photo = (venue.galleryUrls as List)[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 160,
                  height: 120,
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
}

/// Section Header
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Brightness brightness;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.crimson, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
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
            '$count',
            style: const TextStyle(
              color: AppColors.crimson,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
