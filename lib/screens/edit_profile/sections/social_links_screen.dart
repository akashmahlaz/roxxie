/// 🔗 SOCIAL LINKS SCREEN - Edit Profile Sub-Screen
///
/// Role-aware social links editing with URL normalization:
/// - Artist: Instagram, Spotify, YouTube, SoundCloud, TikTok, Website
/// - Venue: Instagram, Facebook, Website
///
/// ⚠️ IMPORTANT: Backend requires FULL URLs, not just usernames
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Social platform configs
  static const List<_SocialPlatform> _artistPlatforms = [
    _SocialPlatform(
      key: 'instagram',
      label: 'Instagram',
      icon: Icons.camera_alt_outlined,
      color: Color(0xFFE4405F),
      hint: '@username',
      baseUrl: 'https://instagram.com/',
      placeholder: 'Enter your Instagram username',
    ),
    _SocialPlatform(
      key: 'spotify',
      label: 'Spotify',
      icon: Icons.music_note,
      color: Color(0xFF1DB954),
      hint: 'Artist URL or ID',
      baseUrl: 'https://open.spotify.com/artist/',
      placeholder: 'Paste your Spotify artist link',
    ),
    _SocialPlatform(
      key: 'youtube',
      label: 'YouTube',
      icon: Icons.play_circle_outline,
      color: Color(0xFFFF0000),
      hint: '@channel',
      baseUrl: 'https://youtube.com/',
      placeholder: 'Enter your YouTube channel',
    ),
    _SocialPlatform(
      key: 'soundcloud',
      label: 'SoundCloud',
      icon: Icons.cloud_outlined,
      color: Color(0xFFFF5500),
      hint: 'username',
      baseUrl: 'https://soundcloud.com/',
      placeholder: 'Enter your SoundCloud username',
    ),
    _SocialPlatform(
      key: 'tiktok',
      label: 'TikTok',
      icon: Icons.music_video,
      color: Color(0xFF000000),
      hint: '@username',
      baseUrl: 'https://tiktok.com/@',
      placeholder: 'Enter your TikTok username',
    ),
    _SocialPlatform(
      key: 'website',
      label: 'Website',
      icon: Icons.language,
      color: Color(0xFF00BCD4),
      hint: 'yoursite.com',
      baseUrl: 'https://',
      placeholder: 'Enter your website URL',
    ),
  ];

  static const List<_SocialPlatform> _venuePlatforms = [
    _SocialPlatform(
      key: 'instagram',
      label: 'Instagram',
      icon: Icons.camera_alt_outlined,
      color: Color(0xFFE4405F),
      hint: '@username',
      baseUrl: 'https://instagram.com/',
      placeholder: 'Enter your Instagram username',
    ),
    _SocialPlatform(
      key: 'facebook',
      label: 'Facebook',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
      hint: 'Page name',
      baseUrl: 'https://facebook.com/',
      placeholder: 'Enter your Facebook page',
    ),
    _SocialPlatform(
      key: 'website',
      label: 'Website',
      icon: Icons.language,
      color: Color(0xFF00BCD4),
      hint: 'yoursite.com',
      baseUrl: 'https://',
      placeholder: 'Enter your website URL',
    ),
  ];

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  void _initializeData() {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    if (auth.isArtist && profile.artist != null) {
      final artist = profile.artist!;
      final social = artist.socialLinks;
      if (social != null) {
        _instagramController.text = _extractDisplayValue(social.instagram, 'instagram');
        _spotifyController.text = _extractDisplayValue(social.spotify, 'spotify');
        _youtubeController.text = _extractDisplayValue(social.youtube, 'youtube');
        _soundcloudController.text = _extractDisplayValue(social.soundcloud, 'soundcloud');
        _tiktokController.text = _extractDisplayValue(social.tiktok, 'tiktok');
        _websiteController.text = _extractDisplayValue(social.website, 'website');
      }
    } else if (!auth.isArtist && profile.venue != null) {
      final venue = profile.venue!;
      final social = venue.socialLinks;
      if (social != null) {
        _instagramController.text = _extractDisplayValue(social.instagram, 'instagram');
        _facebookController.text = _extractDisplayValue(social.facebook, 'facebook');
        _websiteController.text = _extractDisplayValue(social.website, 'website');
      }
    }
    setState(() {});
  }

  /// Extract username/display value from full URL for display
  String _extractDisplayValue(String? url, String platform) {
    if (url == null || url.isEmpty) return '';
    
    // If it's already just a username (no http), return as-is
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return url;
    }

    // Extract username from URL
    switch (platform) {
      case 'instagram':
        final match = RegExp(r'instagram\.com/([^/?]+)').firstMatch(url);
        return match != null ? '@${match.group(1)}' : url;
      case 'tiktok':
        final match = RegExp(r'tiktok\.com/@?([^/?]+)').firstMatch(url);
        return match != null ? '@${match.group(1)}' : url;
      case 'youtube':
        final match = RegExp(r'youtube\.com/(@?[^/?]+)').firstMatch(url);
        return match != null ? match.group(1)! : url;
      case 'soundcloud':
        final match = RegExp(r'soundcloud\.com/([^/?]+)').firstMatch(url);
        return match?.group(1) ?? url;
      case 'facebook':
        final match = RegExp(r'facebook\.com/([^/?]+)').firstMatch(url);
        return match?.group(1) ?? url;
      case 'spotify':
        // Keep full URL for Spotify as it's complex
        return url;
      case 'website':
        // Remove protocol for cleaner display
        return url.replaceAll(RegExp(r'^https?://'), '');
      default:
        return url;
    }
  }

  /// Convert user input to full URL for backend
  String? _normalizeToUrl(String? input, String platform) {
    if (input == null || input.trim().isEmpty) return null;
    
    final value = input.trim();
    
    // Already a full URL
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    switch (platform) {
      case 'instagram':
        final handle = value.startsWith('@') ? value.substring(1) : value;
        return 'https://instagram.com/$handle';
      case 'tiktok':
        final handle = value.startsWith('@') ? value.substring(1) : value;
        return 'https://tiktok.com/@$handle';
      case 'youtube':
        if (value.startsWith('@')) {
          return 'https://youtube.com/$value';
        }
        return 'https://youtube.com/@$value';
      case 'soundcloud':
        return 'https://soundcloud.com/$value';
      case 'facebook':
        return 'https://facebook.com/$value';
      case 'spotify':
        // If it looks like an artist ID (alphanumeric), construct URL
        if (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
          return 'https://open.spotify.com/artist/$value';
        }
        return 'https://open.spotify.com/artist/$value';
      case 'website':
        if (value.startsWith('www.')) {
          return 'https://$value';
        }
        return 'https://$value';
      default:
        return value;
    }
  }

  TextEditingController _getController(String key) {
    switch (key) {
      case 'instagram':
        return _instagramController;
      case 'spotify':
        return _spotifyController;
      case 'youtube':
        return _youtubeController;
      case 'soundcloud':
        return _soundcloudController;
      case 'tiktok':
        return _tiktokController;
      case 'website':
        return _websiteController;
      case 'facebook':
        return _facebookController;
      default:
        return _websiteController;
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
    final profile = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    try {
      if (auth.isArtist) {
        // Create SocialLinks with normalized URLs
        final socialLinks = SocialLinks(
          instagram: _normalizeToUrl(_instagramController.text, 'instagram'),
          spotify: _normalizeToUrl(_spotifyController.text, 'spotify'),
          youtube: _normalizeToUrl(_youtubeController.text, 'youtube'),
          soundcloud: _normalizeToUrl(_soundcloudController.text, 'soundcloud'),
          tiktok: _normalizeToUrl(_tiktokController.text, 'tiktok'),
          website: _normalizeToUrl(_websiteController.text, 'website'),
        );

        await _artistService.updateMyProfile(
          UpdateArtistRequest(socialLinks: socialLinks),
        );
      } else {
        // Create VenueSocialLinks with normalized URLs
        final socialLinks = VenueSocialLinks()
          ..instagram = _normalizeToUrl(_instagramController.text, 'instagram')
          ..facebook = _normalizeToUrl(_facebookController.text, 'facebook')
          ..website = _normalizeToUrl(_websiteController.text, 'website');

        await _venueService.updateMyProfile(
          UpdateVenueRequest(socialLinks: socialLinks),
        );
      }

      // Refresh profile
      await profile.loadProfile(auth.isArtist);

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Text(
                'Social links saved!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      navigator.pop(true);
    } catch (e) {
      debugPrint('❌ Social links save error: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to save: ${e.toString().split(':').last.trim()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
    final platforms = isArtist ? _artistPlatforms : _venuePlatforms;

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
              // Header Card
              _buildHeaderCard(brightness, isArtist),

              const SizedBox(height: 28),

              // Section Title
              Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    color: AppColors.crimson,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Profiles',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Social Links List
              ...platforms.map((platform) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSocialCard(
                  brightness: brightness,
                  platform: platform,
                  controller: _getController(platform.key),
                ),
              )),

              const SizedBox(height: 24),

              // Tips Card
              _buildTipsCard(brightness),

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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _hasChanges
              ? TextButton(
                  key: const ValueKey('save'),
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
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.crimson,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                )
              : const SizedBox(key: ValueKey('empty'), width: 8),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderCard(Brightness brightness, bool isArtist) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.crimson.withValues(alpha: 0.1),
            AppColors.crimson.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.crimson.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
            ),
            child: Icon(
              Icons.share_rounded,
              color: AppColors.crimson,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect Your Socials',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isArtist
                      ? 'Let venues discover your music and online presence'
                      : 'Help artists find and connect with your venue',
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

  Widget _buildSocialCard({
    required Brightness brightness,
    required _SocialPlatform platform,
    required TextEditingController controller,
  }) {
    final hasValue = controller.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: hasValue
              ? platform.color.withValues(alpha: 0.3)
              : AppColors.border(brightness),
          width: 1,
        ),
        boxShadow: hasValue
            ? [
                BoxShadow(
                  color: platform.color.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: platform.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    platform.icon,
                    color: platform.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platform.label,
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        hasValue ? 'Connected' : 'Not connected',
                        style: TextStyle(
                          color: hasValue
                              ? AppColors.success
                              : AppColors.textSec(brightness),
                          fontSize: 12,
                          fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasValue)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.success,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: AppColors.border(brightness),
          ),

          // Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: controller,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: platform.placeholder,
                hintStyle: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Text(
                    platform.hint,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 14,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSec(brightness),
                          size: 18,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          controller.clear();
                          _markChanged();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background(brightness),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: platform.color,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (_) {
                _markChanged();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.cyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(brightness, 'Enter just your username - we\'ll format the URL'),
          const SizedBox(height: 8),
          _buildTipItem(brightness, 'Use @ for Instagram and TikTok usernames'),
          const SizedBox(height: 8),
          _buildTipItem(brightness, 'Paste full URLs if you prefer'),
        ],
      ),
    );
  }

  Widget _buildTipItem(Brightness brightness, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textSec(brightness),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Social platform configuration
class _SocialPlatform {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final String hint;
  final String baseUrl;
  final String placeholder;

  const _SocialPlatform({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.hint,
    required this.baseUrl,
    required this.placeholder,
  });
}
