/// 🎨 EDIT PROFILE HUB - MODULAR ROLE-AWARE DESIGN
///
/// A clean, professional edit profile experience with:
/// ✅ Role-specific sections (Artist vs Venue)
/// ✅ Modular sub-screens for each section
/// ✅ Smooth navigation with completion indicators
/// ✅ Clean professional UI
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';

import 'sections/basic_info_screen.dart';
import 'sections/location_screen.dart';
import 'sections/media_screen.dart';
import 'sections/pricing_screen.dart';
import 'sections/social_links_screen.dart';

/// Edit Profile Hub - Main navigation screen for profile editing
class EditProfileHubScreen extends StatefulWidget {
  const EditProfileHubScreen({super.key});

  @override
  State<EditProfileHubScreen> createState() => _EditProfileHubScreenState();
}

class _EditProfileHubScreenState extends State<EditProfileHubScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    setState(() => _isLoading = true);

    try {
      await profile.loadProfile(auth.isArtist);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToSection(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    // Refresh profile after returning from sub-screen
    if (mounted) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final isArtist = auth.isArtist;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: _isLoading
          ? _buildLoadingState(brightness)
          : _buildContent(context, profile, isArtist, brightness),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
    return AppBar(
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: AppColors.text(brightness),
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLoadingState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.crimson,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProfileProvider profile,
    bool isArtist,
    Brightness brightness,
  ) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: AppColors.crimson,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(profile, isArtist, brightness),

            const SizedBox(height: 32),

            // Section List
            _buildSectionsList(profile, isArtist, brightness),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    ProfileProvider profile,
    bool isArtist,
    Brightness brightness,
  ) {
    final photoUrl = profile.profilePhoto;
    final displayName = profile.displayName;
    final role = isArtist ? 'Artist' : 'Venue';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(brightness),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Photo
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.crimson.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.3),
                width: 2,
              ),
              image: photoUrl != null && photoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null || photoUrl.isEmpty
                ? Icon(
                    isArtist ? Icons.mic : Icons.business,
                    color: AppColors.crimson,
                    size: 32,
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // Name and Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isArtist
                        ? AppColors.crimson.withValues(alpha: 0.1)
                        : AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: isArtist ? AppColors.crimson : AppColors.cyan,
                      fontSize: 12,
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

  Widget _buildSectionsList(
    ProfileProvider profile,
    bool isArtist,
    Brightness brightness,
  ) {
    final sections = _getSections(profile, isArtist);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Sections',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...sections.map((section) => _buildSectionCard(section, brightness)),
      ],
    );
  }

  List<_ProfileSection> _getSections(ProfileProvider profile, bool isArtist) {
    if (isArtist) {
      return [
        _ProfileSection(
          icon: Icons.person_outline,
          title: 'Basic Info',
          subtitle: 'Name, bio, genres, and artist type',
          screen: const BasicInfoScreen(),
          isComplete: _checkBasicInfoComplete(profile),
        ),
        _ProfileSection(
          icon: Icons.location_on_outlined,
          title: 'Location',
          subtitle: 'City, travel radius, and address',
          screen: const LocationScreen(),
          isComplete: _checkLocationComplete(profile),
        ),
        _ProfileSection(
          icon: Icons.photo_library_outlined,
          title: 'Media',
          subtitle: 'Photos, audio samples, and videos',
          screen: const MediaScreen(),
          isComplete: _checkMediaComplete(profile),
        ),
        _ProfileSection(
          icon: Icons.attach_money,
          title: 'Pricing',
          subtitle: 'Your rates and payment preferences',
          screen: const PricingScreen(),
          isComplete: _checkPricingComplete(profile),
        ),
        _ProfileSection(
          icon: Icons.link,
          title: 'Social Links',
          subtitle: 'Connect your social profiles',
          screen: const SocialLinksScreen(),
          isComplete: _checkSocialComplete(profile),
        ),
      ];
    } else {
      // Venue sections
      return [
        _ProfileSection(
          icon: Icons.business_outlined,
          title: 'Basic Info',
          subtitle: 'Venue name, type, and description',
          screen: const BasicInfoScreen(),
          isComplete: _checkBasicInfoComplete(profile),
        ),
        _ProfileSection(
          icon: Icons.location_on_outlined,
          title: 'Location',
          subtitle: 'Address, city, and coordinates',
          screen: const LocationScreen(),
          isComplete: _checkLocationComplete(profile),
        ),
        _ProfileSection(
          icon: Icons.photo_library_outlined,
          title: 'Media',
          subtitle: 'Venue photos and gallery',
          screen: const MediaScreen(),
          isComplete: _checkMediaComplete(profile),
        ),
        _ProfileSection(
          icon: Icons.payments_outlined,
          title: 'Budget & Capacity',
          subtitle: 'Budget range and venue capacity',
          screen: const PricingScreen(),
          isComplete: _checkPricingComplete(profile),
        ),
        _ProfileSection(
          icon: Icons.link,
          title: 'Social Links',
          subtitle: 'Website and social profiles',
          screen: const SocialLinksScreen(),
          isComplete: _checkSocialComplete(profile),
        ),
      ];
    }
  }

  bool _checkBasicInfoComplete(ProfileProvider profile) {
    if (profile.artist != null) {
      final artist = profile.artist!;
      return artist.stageName.isNotEmpty &&
          artist.genres.isNotEmpty;
    } else if (profile.venue != null) {
      final venue = profile.venue!;
      return venue.name.isNotEmpty;
    }
    return false;
  }

  bool _checkLocationComplete(ProfileProvider profile) {
    if (profile.artist != null) {
      final artist = profile.artist!;
      return artist.location?.city != null &&
          artist.location!.city!.isNotEmpty;
    } else if (profile.venue != null) {
      final venue = profile.venue!;
      return venue.location?.city != null;
    }
    return false;
  }

  bool _checkMediaComplete(ProfileProvider profile) {
    if (profile.artist != null) {
      final artist = profile.artist!;
      return artist.profilePhoto != null || artist.galleryUrls.isNotEmpty;
    } else if (profile.venue != null) {
      final venue = profile.venue!;
      return venue.profilePhotoUrl != null ||
          (venue.galleryUrls?.isNotEmpty ?? false);
    }
    return false;
  }

  bool _checkPricingComplete(ProfileProvider profile) {
    if (profile.artist != null) {
      final artist = profile.artist!;
      return artist.minPrice > 0 && artist.maxPrice > 0;
    } else if (profile.venue != null) {
      final venue = profile.venue!;
      return (venue.gigPreferences?.minBudget ?? 0) > 0;
    }
    return false;
  }

  bool _checkSocialComplete(ProfileProvider profile) {
    if (profile.artist != null) {
      final artist = profile.artist!;
      final social = artist.socialLinks;
      return social != null &&
          (social.instagram != null ||
              social.spotify != null ||
              social.youtube != null ||
              social.website != null);
    } else if (profile.venue != null) {
      final venue = profile.venue!;
      final social = venue.socialLinks;
      return social != null &&
          (social.instagram != null || social.website != null);
    }
    return false;
  }

  Widget _buildSectionCard(_ProfileSection section, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToSection(section.screen);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: section.isComplete
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border(brightness),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: section.isComplete
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                section.icon,
                color: section.isComplete ? AppColors.success : AppColors.crimson,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    section.subtitle,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Status and Arrow
            Row(
              children: [
                if (section.isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Complete',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSec(brightness),
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile Section Data Model
class _ProfileSection {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;
  final bool isComplete;

  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
    this.isComplete = false,
  });
}
