/// 👤 GIGMATCH Profile Screen
/// User profile and settings
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
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
                  ),

                  const SizedBox(height: 32),

                  // Stats
                  if (auth.isArtist && artist != null)
                    _ArtistStats(artist: artist)
                  else if (auth.isVenue && venue != null)
                    _VenueStats(venue: venue),

                  const SizedBox(height: 32),

                  // Menu items
                  _MenuItem(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  ),
                  _MenuItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  _MenuItem(
                    icon: Icons.star,
                    title: 'Upgrade to Premium',
                    onTap: () => Navigator.pushNamed(context, '/premium'),
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
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => Navigator.pushNamed(context, '/support'),
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),

                  const SizedBox(height: 24),

                  // Logout button
                  OutlinedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.crimson,
                      side: const BorderSide(color: AppColors.crimson),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Sign Out'),
                  ),

                  const SizedBox(height: 24),

                  // App version
                  Text(
                    'GigMatch v1.0.0',
                    style: TextStyle(
                      color: AppColors.mediumGray.withValues(alpha: 0.5),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text(
          'Sign Out?',
          style: TextStyle(color: AppColors.offWhite),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.mediumGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.mediumGray),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
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

  const _ProfileHeader({
    required this.name,
    this.photoUrl,
    required this.isArtist,
    this.stageName,
    this.venueName,
    required this.isVerified,
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
              backgroundColor: AppColors.charcoal,
              backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Icon(
                      isArtist ? Icons.music_note : Icons.business,
                      size: 40,
                      color: AppColors.mediumGray,
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
            color: AppColors.offWhite,
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

  const _ArtistStats({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '${artist.rating.toStringAsFixed(1)}',
            label: 'Rating',
            icon: Icons.star,
          ),
          _StatItem(
            value: '${artist.reviewCount}',
            label: 'Reviews',
            icon: Icons.rate_review,
          ),
          _StatItem(
            value: artist.genres.length.toString(),
            label: 'Genres',
            icon: Icons.music_note,
          ),
        ],
      ),
    );
  }
}

/// Venue Stats
class _VenueStats extends StatelessWidget {
  final dynamic venue;

  const _VenueStats({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '${venue.rating.toStringAsFixed(1)}',
            label: 'Rating',
            icon: Icons.star,
          ),
          _StatItem(
            value: '${venue.capacity}',
            label: 'Capacity',
            icon: Icons.people,
          ),
          _StatItem(
            value: '${venue.reviewCount}',
            label: 'Reviews',
            icon: Icons.rate_review,
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

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.crimson, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.offWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.mediumGray, fontSize: 12),
        ),
      ],
    );
  }
}

/// Menu Item
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.mediumGray),
        title: Text(title, style: const TextStyle(color: AppColors.offWhite)),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: AppColors.mediumGray),
      ),
    );
  }
}
