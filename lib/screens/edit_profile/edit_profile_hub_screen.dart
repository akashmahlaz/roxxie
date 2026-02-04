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
    // Schedule loadProfile after frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfile();
      }
    });
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Skeleton
          _buildHeaderSkeleton(brightness),

          const SizedBox(height: 32),

          // Section Title Skeleton
          _buildShimmerBox(brightness, width: 120, height: 18),

          const SizedBox(height: 16),

          // Section Cards Skeleton
          for (int i = 0; i < 5; i++) ...[
            _buildSectionSkeleton(brightness),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.border(brightness),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Photo Skeleton
          _ShimmerBox(
            brightness: brightness,
            width: 80,
            height: 80,
            borderRadius: 40,
          ),

          const SizedBox(width: 18),

          // Name and Role Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(brightness, width: 160, height: 24),
                const SizedBox(height: 12),
                _buildShimmerBox(brightness, width: 70, height: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSkeleton(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.border(brightness),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon Skeleton
          _ShimmerBox(
            brightness: brightness,
            width: 52,
            height: 52,
            borderRadius: AppSpacing.radiusIcon,
          ),

          const SizedBox(width: 16),

          // Title and Subtitle Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(brightness, width: 110, height: 17),
                const SizedBox(height: 10),
                _buildShimmerBox(brightness, width: 190, height: 14),
              ],
            ),
          ),

          // Arrow Skeleton
          _buildShimmerBox(brightness, width: 24, height: 24),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(
    Brightness brightness, {
    required double width,
    required double height,
    double? borderRadius,
  }) {
    return _ShimmerBox(
      brightness: brightness,
      width: width,
      height: height,
      borderRadius: borderRadius ?? 8,
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
    final auth = context.read<AuthProvider>();
    // Get photo with Google/social photo fallback
    final photoUrl = profile.profilePhoto ?? auth.user?.profilePhotoUrl;
    // Get name with Google/social name fallback
    final userName = auth.user?.name;
    final displayName = profile.displayName.isNotEmpty
        ? profile.displayName
        : (userName != null && userName.isNotEmpty ? userName : 'User');
    // Get email from user
    final email = auth.user?.email ?? '';
    final role = isArtist ? 'Artist' : 'Venue';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/edit-profile/media'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: AppColors.border(brightness),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Profile Photo - Clean design, tap to edit
            Semantics(
              label: 'Profile photo, tap to edit',
              button: true,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.crimson.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              _buildDefaultAvatar(isArtist, brightness),
                        )
                      : _buildDefaultAvatar(isArtist, brightness),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Name, Email and Role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isArtist
                          ? AppColors.crimson.withValues(alpha: 0.1)
                          : AppColors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: isArtist ? AppColors.crimson : AppColors.cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Edit indicator
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSec(brightness),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isArtist, Brightness brightness) {
    return Center(
      child: Icon(
        isArtist ? Icons.mic_rounded : Icons.business_rounded,
        color: AppColors.crimson.withValues(alpha: 0.5),
        size: 32,
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
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: section.isComplete
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border(brightness),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: section.isComplete
                  ? AppColors.success.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: section.isComplete
                    ? LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.15),
                          AppColors.success.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.crimson.withValues(alpha: 0.15),
                          AppColors.crimson.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
              ),
              child: Icon(
                section.icon,
                color: section.isComplete ? AppColors.success : AppColors.crimson,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    section.subtitle,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                      height: 1.3,
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
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.crimson,
                    size: 20,
                  ),
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

/// Shimmer loading box with animation
class _ShimmerBox extends StatefulWidget {
  final Brightness brightness;
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.brightness,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.grey.shade800
        : Colors.grey.shade300;
    final highlightColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
