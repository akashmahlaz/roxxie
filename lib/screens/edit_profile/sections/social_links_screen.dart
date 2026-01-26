/// 🔗 SOCIAL LINKS SCREEN - Edit Profile Sub-Screen
///
/// Role-aware social links editing:
/// - Artist: Instagram, Spotify, YouTube, SoundCloud, TikTok, Website
/// - Venue: Instagram, Facebook, Website, Yelp
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({super.key});

  @override
  State<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artistService = ArtistService();
  final _venueService = VenueService();

  // Controllers - Artist
  late TextEditingController _instagramController;
  late TextEditingController _spotifyController;
  late TextEditingController _youtubeController;
  late TextEditingController _soundcloudController;
  late TextEditingController _tiktokController;
  late TextEditingController _websiteController;

  // Controllers - Venue
  late TextEditingController _facebookController;

  // State
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _instagramController = TextEditingController();
    _spotifyController = TextEditingController();
    _youtubeController = TextEditingController();
    _soundcloudController = TextEditingController();
    _tiktokController = TextEditingController();
    _websiteController = TextEditingController();
    _facebookController = TextEditingController();
    _initializeData();
  }

  void _initializeData() {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    if (auth.isArtist && profile.artist != null) {
      final artist = profile.artist!;
      final social = artist.socialLinks;
      if (social != null) {
        _instagramController.text = social.instagram ?? '';
        _spotifyController.text = social.spotify ?? '';
        _youtubeController.text = social.youtube ?? '';
        _soundcloudController.text = social.soundcloud ?? '';
        _tiktokController.text = social.tiktok ?? '';
        _websiteController.text = social.website ?? '';
      }
    } else if (!auth.isArtist && profile.venue != null) {
      final venue = profile.venue!;
      final social = venue.socialLinks;
      if (social != null) {
        _instagramController.text = social.instagram ?? '';
        _facebookController.text = social.facebook ?? '';
        _websiteController.text = social.website ?? '';
      }
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    try {
      if (auth.isArtist) {
        final socialLinks = SocialLinks(
          instagram: _instagramController.text.trim().isEmpty
              ? null
              : _instagramController.text.trim(),
          spotify: _spotifyController.text.trim().isEmpty
              ? null
              : _spotifyController.text.trim(),
          youtube: _youtubeController.text.trim().isEmpty
              ? null
              : _youtubeController.text.trim(),
          soundcloud: _soundcloudController.text.trim().isEmpty
              ? null
              : _soundcloudController.text.trim(),
          tiktok: _tiktokController.text.trim().isEmpty
              ? null
              : _tiktokController.text.trim(),
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
        );

        await _artistService.updateMyProfile(
          UpdateArtistRequest(socialLinks: socialLinks),
        );
      } else {
        final socialLinks = VenueSocialLinks()
          ..instagram = _instagramController.text.trim().isEmpty
              ? null
              : _instagramController.text.trim()
          ..facebook = _facebookController.text.trim().isEmpty
              ? null
              : _facebookController.text.trim()
          ..website = _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim();

        await _venueService.updateMyProfile(
          UpdateVenueRequest(socialLinks: socialLinks),
        );
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Social links updated!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _instagramController.dispose();
    _spotifyController.dispose();
    _youtubeController.dispose();
    _soundcloudController.dispose();
    _tiktokController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();
    final isArtist = auth.isArtist;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              _buildInfoCard(brightness),

              const SizedBox(height: 28),

              // Social Links
              if (isArtist) ...[
                _buildArtistSocialLinks(brightness),
              ] else ...[
                _buildVenueSocialLinks(brightness),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
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
        'Social Links',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_hasChanges)
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.crimson,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildInfoCard(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.cyan,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add your social profiles to help people find and connect with you. You can enter usernames or full URLs.',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistSocialLinks(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instagram
        _buildSocialField(
          brightness: brightness,
          label: 'Instagram',
          controller: _instagramController,
          hint: '@username or instagram.com/username',
          icon: Icons.camera_alt_outlined,
          color: const Color(0xFFE4405F),
        ),

        const SizedBox(height: 20),

        // Spotify
        _buildSocialField(
          brightness: brightness,
          label: 'Spotify',
          controller: _spotifyController,
          hint: 'Your Spotify artist URL',
          icon: Icons.music_note,
          color: const Color(0xFF1DB954),
        ),

        const SizedBox(height: 20),

        // YouTube
        _buildSocialField(
          brightness: brightness,
          label: 'YouTube',
          controller: _youtubeController,
          hint: '@channel or youtube.com/@channel',
          icon: Icons.play_circle_outline,
          color: const Color(0xFFFF0000),
        ),

        const SizedBox(height: 20),

        // SoundCloud
        _buildSocialField(
          brightness: brightness,
          label: 'SoundCloud',
          controller: _soundcloudController,
          hint: 'soundcloud.com/username',
          icon: Icons.cloud_outlined,
          color: const Color(0xFFFF5500),
        ),

        const SizedBox(height: 20),

        // TikTok
        _buildSocialField(
          brightness: brightness,
          label: 'TikTok',
          controller: _tiktokController,
          hint: '@username or tiktok.com/@username',
          icon: Icons.music_video,
          color: const Color(0xFF000000),
        ),

        const SizedBox(height: 20),

        // Website
        _buildSocialField(
          brightness: brightness,
          label: 'Website',
          controller: _websiteController,
          hint: 'yourwebsite.com',
          icon: Icons.language,
          color: AppColors.cyan,
        ),
      ],
    );
  }

  Widget _buildVenueSocialLinks(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instagram
        _buildSocialField(
          brightness: brightness,
          label: 'Instagram',
          controller: _instagramController,
          hint: '@username or instagram.com/username',
          icon: Icons.camera_alt_outlined,
          color: const Color(0xFFE4405F),
        ),

        const SizedBox(height: 20),

        // Facebook
        _buildSocialField(
          brightness: brightness,
          label: 'Facebook',
          controller: _facebookController,
          hint: 'facebook.com/yourpage',
          icon: Icons.facebook,
          color: const Color(0xFF1877F2),
        ),

        const SizedBox(height: 20),

        // Website
        _buildSocialField(
          brightness: brightness,
          label: 'Website',
          controller: _websiteController,
          hint: 'yourwebsite.com',
          icon: Icons.language,
          color: AppColors.cyan,
        ),
      ],
    );
  }

  Widget _buildSocialField({
    required Brightness brightness,
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border(brightness),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border(brightness),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: color,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }
}
