/// ✏️ GIGMATCH Professional Profile Edit System V2
///
/// Complete multi-tab profile editor with:
/// - Tab-based navigation (Basic, Media, Pricing, Availability)
/// - Real-time upload progress
/// - Drag-and-drop media ordering
/// - Auto-save drafts
/// - Live preview
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/services/services.dart';
import '../../core/models/models.dart';
import '../../widgets/widgets.dart';

// Export all edit profile components
part 'tabs/basic_info_tab.dart';
part 'tabs/media_tab.dart';
part 'tabs/pricing_tab.dart';
part 'tabs/availability_tab.dart';
part 'widgets/media_upload_card.dart';
part 'widgets/audio_sample_item.dart';
part 'widgets/video_sample_item.dart';
part 'widgets/photo_gallery_item.dart';

// Helper extensions for display names
extension ArtistTypeDisplay on ArtistType {
  String get displayName {
    switch (this) {
      case ArtistType.solo:
        return 'Solo';
      case ArtistType.duo:
        return 'Duo';
      case ArtistType.band:
        return 'Band';
      case ArtistType.dj:
        return 'DJ';
      case ArtistType.orchestra:
        return 'Orchestra';
      case ArtistType.ensemble:
        return 'Ensemble';
    }
  }
}

extension ExperienceLevelDisplay on ExperienceLevel {
  String get displayName {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.professional:
        return 'Professional';
      case ExperienceLevel.expert:
        return 'Expert';
    }
  }
}

class EditProfileV2Screen extends StatefulWidget {
  const EditProfileV2Screen({super.key});

  @override
  State<EditProfileV2Screen> createState() => _EditProfileV2ScreenState();
}

class _EditProfileV2ScreenState extends State<EditProfileV2Screen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _stageNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _spotifyController;
  late TextEditingController _youtubeController;

  // State
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isLoadingProfile = true;
  String? _newProfilePhotoPath;
  String? _currentProfilePhotoUrl;
  List<String> _selectedGenres = [];
  List<AudioSampleState> _audioSamples = [];
  List<VideoSampleState> _videoSamples = [];
  List<PhotoGalleryState> _galleryPhotos = [];
  String _pricePer = 'show';
  String _currency = 'USD';
  int _yearsOfExperience = 1;
  int _bandSize = 1;
  int _maxTravelDistance = 50;
  ArtistType _artistType = ArtistType.solo;
  ExperienceLevel _experienceLevel = ExperienceLevel.beginner;
  List<String> _equipment = [];

  // Tab configuration
  final List<_TabConfig> _tabs = [
    _TabConfig('Basic', Icons.person_rounded),
    _TabConfig('Media', Icons.perm_media_rounded),
    _TabConfig('Pricing', Icons.attach_money_rounded),
    _TabConfig('More', Icons.tune_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentProfile());
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _stageNameController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _minPriceController = TextEditingController(text: '100');
    _maxPriceController = TextEditingController(text: '500');
    _websiteController = TextEditingController();
    _instagramController = TextEditingController();
    _spotifyController = TextEditingController();
    _youtubeController = TextEditingController();
  }

  Future<void> _loadCurrentProfile() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final artist = auth.artistProfile;
    final venue = auth.venueProfile;

    setState(() {
      if (auth.isArtist && artist != null) {
        _nameController.text = artist.displayName.isNotEmpty
            ? artist.displayName
            : (user?.name ?? '');
        _stageNameController.text = artist.stageName;
        _bioController.text = artist.bio ?? '';
        _cityController.text = artist.location?.city ?? '';
        _selectedGenres = List<String>.from(artist.genres);
        _currentProfilePhotoUrl = artist.profilePhoto;
        _artistType = artist.artistType;
        _experienceLevel = artist.experienceLevel;
        _yearsOfExperience = artist.yearsOfExperience ?? 0;
        _maxTravelDistance = artist.maxTravelDistance;
        _bandSize = artist.bandSize ?? 1;
        _equipment = List<String>.from(artist.equipment);

        // Load price range
        if (artist.priceRange != null) {
          _minPriceController.text = artist.priceRange!.min.toStringAsFixed(0);
          _maxPriceController.text = artist.priceRange!.max.toStringAsFixed(0);
          _pricePer = artist.priceRange!.per;
          _currency = artist.priceRange!.currency;
        }

        // Load social links
        if (artist.socialLinks != null) {
          _websiteController.text = artist.socialLinks!.website ?? '';
          _instagramController.text = artist.socialLinks!.instagram ?? '';
          _spotifyController.text = artist.socialLinks!.spotify ?? '';
          _youtubeController.text = artist.socialLinks!.youtube ?? '';
        }

        // Load media
        _audioSamples = artist.audioSamples
            .map(
              (s) => AudioSampleState(
                id: s.url,
                url: s.url,
                title: s.title ?? 'Untitled',
                duration: s.durationSeconds ?? 0,
                isUploaded: true,
              ),
            )
            .toList();

        _videoSamples = artist.videoSamples
            .map(
              (s) => VideoSampleState(
                id: s.url,
                url: s.url,
                title: s.title ?? 'Untitled',
                thumbnailUrl: s.thumbnailUrl,
                duration: s.durationSeconds ?? 0,
                isUploaded: true,
              ),
            )
            .toList();

        _galleryPhotos = artist.galleryUrls
            .map(
              (url) => PhotoGalleryState(id: url, url: url, isUploaded: true),
            )
            .toList();
      } else if (auth.isVenue && venue != null) {
        _nameController.text = venue.name;
        _bioController.text = venue.description ?? '';
        _cityController.text = venue.location?.city ?? '';
        final photos = venue.galleryUrls ?? [];
        _currentProfilePhotoUrl = photos.isNotEmpty
            ? photos.first
            : venue.profilePhotoUrl;
        _selectedGenres = List<String>.from(
          venue.gigPreferences?.preferredGenres ?? [],
        );
      }

      _isLoadingProfile = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _stageNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _spotifyController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _newProfilePhotoPath = image.path;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      // Switch to tab with errors
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = context.read<AuthProvider>();
      String? uploadedPhotoUrl;

      // Upload new profile photo if selected
      if (_newProfilePhotoPath != null) {
        try {
          final result = await _uploadService.uploadProfilePhoto(
            _newProfilePhotoPath!,
          );
          uploadedPhotoUrl = result.url;
        } catch (e) {
          debugPrint('Photo upload failed: $e');
        }
      }

      // Build update data for user
      final userUpdates = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (uploadedPhotoUrl != null) 'profilePhotoUrl': uploadedPhotoUrl,
      };

      // Update user profile
      await auth.updateProfile(userUpdates);

      // Update role-specific profile
      if (auth.isArtist) {
        final priceRange = PriceRange(
          min: double.tryParse(_minPriceController.text) ?? 100,
          max: double.tryParse(_maxPriceController.text) ?? 500,
          currency: _currency,
          per: _pricePer,
        );

        final socialLinks = SocialLinks(
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
          instagram: _instagramController.text.trim().isEmpty
              ? null
              : _instagramController.text.trim(),
          spotify: _spotifyController.text.trim().isEmpty
              ? null
              : _spotifyController.text.trim(),
          youtube: _youtubeController.text.trim().isEmpty
              ? null
              : _youtubeController.text.trim(),
        );

        await auth.updateArtistProfile(
          UpdateArtistRequest(
            stageName: _stageNameController.text.trim().isEmpty
                ? null
                : _stageNameController.text.trim(),
            bio: _bioController.text.trim(),
            artistType: _artistType,
            genres: _selectedGenres,
            experienceLevel: _experienceLevel,
            yearsOfExperience: _yearsOfExperience,
            maxTravelDistance: _maxTravelDistance,
            bandSize: _bandSize,
            equipment: _equipment,
            priceRange: priceRange,
            socialLinks: socialLinks,
            galleryUrls: _galleryPhotos
                .where((p) => p.isUploaded)
                .map((p) => p.url!)
                .toList(),
          ),
        );
      } else if (auth.isVenue) {
        await auth.updateVenueProfile(
          UpdateVenueRequest(
            venueName: _nameController.text.trim(),
            description: _bioController.text.trim(),
            preferredGenres: _selectedGenres,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          ),
        );
      }

      if (!mounted) return;

      HapticFeedback.heavyImpact();
      _showSuccessSnackBar('Profile updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDiscardDialog() {
    final brightness = Theme.of(context).brightness;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Discard Changes?',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to leave without saving?',
          style: TextStyle(color: AppColors.textSec(brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Editing',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close edit screen
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimson),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();
    final isArtist = auth.isArtist;

    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: Form(
        key: _formKey,
        onChanged: _markChanged,
        child: Column(
          children: [
            // Profile Photo Header
            _buildProfilePhotoHeader(brightness),

            // Tab Bar
            _buildTabBar(brightness),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BasicInfoTab(
                    nameController: _nameController,
                    stageNameController: _stageNameController,
                    bioController: _bioController,
                    phoneController: _phoneController,
                    cityController: _cityController,
                    selectedGenres: _selectedGenres,
                    artistType: _artistType,
                    experienceLevel: _experienceLevel,
                    yearsOfExperience: _yearsOfExperience,
                    bandSize: _bandSize,
                    isArtist: isArtist,
                    onGenresChanged: (genres) => setState(() {
                      _selectedGenres = genres;
                      _markChanged();
                    }),
                    onArtistTypeChanged: (type) => setState(() {
                      _artistType = type;
                      _markChanged();
                    }),
                    onExperienceLevelChanged: (level) => setState(() {
                      _experienceLevel = level;
                      _markChanged();
                    }),
                    onYearsChanged: (years) => setState(() {
                      _yearsOfExperience = years;
                      _markChanged();
                    }),
                    onBandSizeChanged: (size) => setState(() {
                      _bandSize = size;
                      _markChanged();
                    }),
                    websiteController: _websiteController,
                    instagramController: _instagramController,
                    spotifyController: _spotifyController,
                    youtubeController: _youtubeController,
                  ),
                  _MediaTab(
                    audioSamples: _audioSamples,
                    videoSamples: _videoSamples,
                    galleryPhotos: _galleryPhotos,
                    onAudioAdded: (sample) => setState(() {
                      _audioSamples.add(sample);
                      _markChanged();
                    }),
                    onAudioRemoved: (index) => setState(() {
                      _audioSamples.removeAt(index);
                      _markChanged();
                    }),
                    onAudioReordered: (oldIndex, newIndex) => setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _audioSamples.removeAt(oldIndex);
                      _audioSamples.insert(newIndex, item);
                      _markChanged();
                    }),
                    onVideoAdded: (sample) => setState(() {
                      _videoSamples.add(sample);
                      _markChanged();
                    }),
                    onVideoRemoved: (index) => setState(() {
                      _videoSamples.removeAt(index);
                      _markChanged();
                    }),
                    onPhotoAdded: (photo) => setState(() {
                      _galleryPhotos.add(photo);
                      _markChanged();
                    }),
                    onPhotoRemoved: (index) => setState(() {
                      _galleryPhotos.removeAt(index);
                      _markChanged();
                    }),
                    isArtist: isArtist,
                  ),
                  _PricingTab(
                    minPriceController: _minPriceController,
                    maxPriceController: _maxPriceController,
                    pricePer: _pricePer,
                    currency: _currency,
                    onPricePerChanged: (per) => setState(() {
                      _pricePer = per;
                      _markChanged();
                    }),
                    onCurrencyChanged: (currency) => setState(() {
                      _currency = currency;
                      _markChanged();
                    }),
                    isArtist: isArtist,
                  ),
                  _AvailabilityTab(
                    maxTravelDistance: _maxTravelDistance,
                    equipment: _equipment,
                    onTravelDistanceChanged: (distance) => setState(() {
                      _maxTravelDistance = distance;
                      _markChanged();
                    }),
                    onEquipmentChanged: (equipment) => setState(() {
                      _equipment = equipment;
                      _markChanged();
                    }),
                    isArtist: isArtist,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(brightness),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
    return AppBar(
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      leading: GlassBackButton(
        onPressed: () {
          if (_hasChanges) {
            _showDiscardDialog();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed('/public-profile');
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 18,
                color: AppColors.crimson,
              ),
              const SizedBox(width: 4),
              Text(
                'Preview',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhotoHeader(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GestureDetector(
        onTap: _pickProfilePhoto,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Photo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.crimson, AppColors.rose],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: _newProfilePhotoPath != null
                    ? Image.file(File(_newProfilePhotoPath!), fit: BoxFit.cover)
                    : _currentProfilePhotoUrl != null
                    ? Image.network(
                        _currentProfilePhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _buildDefaultAvatar(brightness),
                      )
                    : _buildDefaultAvatar(brightness),
              ),
            ),
            // Edit badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background(brightness),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.black,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(Brightness brightness) {
    return Container(
      color: AppColors.surface(brightness),
      child: Icon(
        Icons.person_rounded,
        size: 50,
        color: AppColors.textSec(brightness),
      ),
    );
  }

  Widget _buildTabBar(Brightness brightness) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.crimson,
              AppColors.crimson.withValues(alpha: 0.8),
            ],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSec(brightness),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: _tabs
            .map(
              (tab) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 16),
                    const SizedBox(width: 4),
                    Text(tab.label),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBottomBar(Brightness brightness) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          border: Border(
            top: BorderSide(color: AppColors.divider(brightness), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Unsaved indicator
            if (_hasChanges)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Unsaved',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final IconData icon;

  _TabConfig(this.label, this.icon);
}

// State classes for media items
class AudioSampleState {
  final String id;
  String? url;
  String title;
  int duration;
  bool isUploaded;
  bool isUploading;
  double uploadProgress;

  AudioSampleState({
    required this.id,
    this.url,
    required this.title,
    this.duration = 0,
    this.isUploaded = false,
    this.isUploading = false,
    this.uploadProgress = 0,
  });
}

class VideoSampleState {
  final String id;
  String? url;
  String title;
  String? thumbnailUrl;
  int duration;
  bool isUploaded;
  bool isUploading;
  double uploadProgress;

  VideoSampleState({
    required this.id,
    this.url,
    required this.title,
    this.thumbnailUrl,
    this.duration = 0,
    this.isUploaded = false,
    this.isUploading = false,
    this.uploadProgress = 0,
  });
}

class PhotoGalleryState {
  final String id;
  String? url;
  String? localPath;
  String? caption;
  bool isUploaded;
  bool isUploading;
  double uploadProgress;

  PhotoGalleryState({
    required this.id,
    this.url,
    this.localPath,
    this.caption,
    this.isUploaded = false,
    this.isUploading = false,
    this.uploadProgress = 0,
  });
}
