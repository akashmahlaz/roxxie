/// ✏️ GIGMATCH Professional Profile Editor
///
/// Clean, single-scroll design with clear sections:
/// - Profile Photo
/// - Basic Info (name, bio, genres)
/// - Media (audio, video, photos)
/// - Pricing & Availability
///
/// All data saved to backend and synced with auth provider
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/services/services.dart';
import '../../core/models/models.dart';
import '../../widgets/smart_location_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _uploadService = UploadService();

  // Form controllers
  late TextEditingController _stageNameController;
  late TextEditingController _bioController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _spotifyController;
  late TextEditingController _youtubeController;

  // State
  // ignore: unused_field
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _profilePhotoUrl;
  File? _newProfilePhoto;
  List<String> _selectedGenres = [];
  ArtistType _artistType = ArtistType.solo;
  ExperienceLevel _experienceLevel = ExperienceLevel.intermediate;
  int _yearsOfExperience = 1;
  int _bandSize = 1;
  int _maxTravelDistance = 50;
  List<String> _equipment = [];
  List<AudioSample> _audioSamples = [];
  List<VideoSample> _videoSamples = [];
  List<String> _photoUrls = [];
  String _currency = 'USD';
  String _pricePer = 'hour';

  // Location (critical for matching algorithm)
  String? _city;
  String? _country;
  double? _latitude;
  double? _longitude;

  // Equipment input
  final _equipmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadProfile();
  }

  void _initControllers() {
    _stageNameController = TextEditingController();
    _bioController = TextEditingController();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    _websiteController = TextEditingController();
    _instagramController = TextEditingController();
    _spotifyController = TextEditingController();
    _youtubeController = TextEditingController();

    // Listen for changes
    for (final controller in [
      _stageNameController,
      _bioController,
      _minPriceController,
      _maxPriceController,
    ]) {
      controller.addListener(_markChanged);
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _loadProfile() {
    final auth = context.read<AuthProvider>();
    final artist = auth.artistProfile;

    if (artist != null) {
      setState(() {
        _stageNameController.text = artist.stageName;
        _bioController.text = artist.bio ?? '';
        _profilePhotoUrl = artist.profilePhoto;
        _selectedGenres = List<String>.from(artist.genres);
        _artistType = artist.artistType;
        _experienceLevel = artist.experienceLevel;
        _yearsOfExperience = artist.yearsOfExperience ?? 1;
        _bandSize = artist.bandSize ?? 1;
        _maxTravelDistance = artist.maxTravelDistance;
        _equipment = List<String>.from(artist.equipment);
        _audioSamples = List<AudioSample>.from(artist.audioSamples);
        _videoSamples = List<VideoSample>.from(artist.videoSamples);
        _photoUrls = List<String>.from(artist.galleryUrls);

        // Load location (critical for matching)
        if (artist.location != null) {
          _city = artist.location!.city;
          _country = artist.location!.country;
          _latitude = artist.location!.latitude;
          _longitude = artist.location!.longitude;
        }

        if (artist.priceRange != null) {
          _minPriceController.text = artist.priceRange!.min.toStringAsFixed(0);
          _maxPriceController.text = artist.priceRange!.max.toStringAsFixed(0);
          _currency = artist.priceRange!.currency;
          _pricePer = artist.priceRange!.per;
        }

        if (artist.socialLinks != null) {
          _websiteController.text = artist.socialLinks!.website ?? '';
          _instagramController.text = artist.socialLinks!.instagram ?? '';
          _spotifyController.text = artist.socialLinks!.spotify ?? '';
          _youtubeController.text = artist.socialLinks!.youtube ?? '';
        }
      });
    }

    // Reset changes flag after loading
    Future.microtask(() => _hasChanges = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stageNameController.dispose();
    _bioController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _spotifyController.dispose();
    _youtubeController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Photo Section
            _buildProfilePhotoSection(brightness),
            const SizedBox(height: 32),

            // Basic Info Section
            _buildSectionHeader(brightness, 'Basic Info', Icons.person_rounded),
            const SizedBox(height: 16),
            _buildBasicInfoSection(brightness),
            const SizedBox(height: 32),

            // Location Section (critical for matching algorithm)
            _buildSectionHeader(
              brightness,
              'Location',
              Icons.location_on_rounded,
            ),
            const SizedBox(height: 16),
            _buildLocationSection(brightness),
            const SizedBox(height: 32),

            // Artist Type Section
            _buildSectionHeader(
              brightness,
              'Artist Type',
              Icons.music_note_rounded,
            ),
            const SizedBox(height: 16),
            _buildArtistTypeSection(brightness),
            const SizedBox(height: 32),

            // Genres Section
            _buildSectionHeader(brightness, 'Genres', Icons.category_rounded),
            const SizedBox(height: 16),
            _buildGenresSection(brightness),
            const SizedBox(height: 32),

            // Media Section
            _buildSectionHeader(brightness, 'Media', Icons.perm_media_rounded),
            const SizedBox(height: 16),
            _buildMediaSection(brightness),
            const SizedBox(height: 32),

            // Pricing Section
            _buildSectionHeader(
              brightness,
              'Pricing',
              Icons.attach_money_rounded,
            ),
            const SizedBox(height: 16),
            _buildPricingSection(brightness),
            const SizedBox(height: 32),

            // Availability Section
            _buildSectionHeader(
              brightness,
              'Availability & Equipment',
              Icons.build_rounded,
            ),
            const SizedBox(height: 16),
            _buildAvailabilitySection(brightness),
            const SizedBox(height: 32),

            // Social Links Section
            _buildSectionHeader(brightness, 'Social Links', Icons.link_rounded),
            const SizedBox(height: 16),
            _buildSocialLinksSection(brightness),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveButton(brightness),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
    return AppBar(
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(brightness)),
        onPressed: () => _confirmExit(),
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/public-profile'),
          child: Text(
            'Preview',
            style: TextStyle(
              color: AppColors.crimson,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    Brightness brightness,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.crimson, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📸 PROFILE PHOTO SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfilePhotoSection(Brightness brightness) {
    return Center(
      child: Stack(
        children: [
          // Photo
          GestureDetector(
            onTap: _pickProfilePhoto,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.crimson, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: _newProfilePhoto != null
                    ? Image.file(_newProfilePhoto!, fit: BoxFit.cover)
                    : _profilePhotoUrl != null
                    ? Image.network(
                        _profilePhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _buildPhotoPlaceholder(brightness),
                      )
                    : _buildPhotoPlaceholder(brightness),
              ),
            ),
          ),

          // Camera button
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickProfilePhoto,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(Brightness brightness) {
    return Container(
      color: AppColors.surface(brightness),
      child: Icon(
        Icons.person_rounded,
        size: 60,
        color: AppColors.textSec(brightness),
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _newProfilePhoto = File(image.path);
        _hasChanges = true;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📝 BASIC INFO SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBasicInfoSection(Brightness brightness) {
    return Column(
      children: [
        // Stage Name
        _buildTextField(
          brightness: brightness,
          controller: _stageNameController,
          label: 'Stage Name',
          hint: 'Your performing name',
          icon: Icons.star_rounded,
        ),
        const SizedBox(height: 16),

        // Bio
        _buildTextField(
          brightness: brightness,
          controller: _bioController,
          label: 'Bio',
          hint:
              'Tell venues about yourself, your style, and what makes you unique...',
          icon: Icons.description_rounded,
          maxLines: 4,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required Brightness brightness,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: TextStyle(color: AppColors.text(brightness)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSec(brightness).withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(icon, color: AppColors.crimson, size: 20),
            prefixText: prefix,
            prefixStyle: TextStyle(color: AppColors.text(brightness)),
            filled: true,
            fillColor: AppColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.crimson, width: 2),
            ),
            counterStyle: TextStyle(color: AppColors.textSec(brightness)),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📍 LOCATION SECTION (Critical for matching algorithm)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLocationSection(Brightness brightness) {
    final hasLocation = _city != null && _country != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.divider(brightness),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasLocation
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasLocation
                      ? Icons.check_circle_rounded
                      : Icons.location_off_rounded,
                  color: hasLocation ? AppColors.success : AppColors.crimson,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation ? '$_city, $_country' : 'Location Required',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLocation
                          ? 'Used for matching with nearby venues'
                          : 'Set your location to match with venues',
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
          const SizedBox(height: 16),

          // Update Location Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showLocationPicker,
              icon: Icon(
                hasLocation
                    ? Icons.edit_location_rounded
                    : Icons.my_location_rounded,
                size: 20,
              ),
              label: Text(hasLocation ? 'Update Location' : 'Set Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.crimson,
                side: BorderSide(color: AppColors.crimson),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          if (!hasLocation) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your profile won\'t appear in venue searches without a location.',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppColors.background(brightness),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider(brightness),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Set Your Location',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textSec(brightness),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SmartLocationPicker(
                    initialCity: _city,
                    initialCountry: _country,
                    autoDetect: _city == null,
                    onLocationSelected: (city, country, lat, lng) {
                      setState(() {
                        _city = city;
                        _country = country;
                        _latitude = lat;
                        _longitude = lng;
                        _hasChanges = true;
                      });
                      Navigator.pop(context);
                      _showSnackBar('Location set to $city, $country');
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎭 ARTIST TYPE SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildArtistTypeSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Artist Type Grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ArtistType.values.map((type) {
            final isSelected = _artistType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _artistType = type;
                  _hasChanges = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.divider(brightness),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getArtistTypeIcon(type),
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSec(brightness),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.text(brightness),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Band size (only for band/duo/orchestra/ensemble)
        if (_artistType != ArtistType.solo && _artistType != ArtistType.dj) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Band Size: ',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_bandSize members',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _bandSize.clamp(2, 20).toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            activeColor: AppColors.crimson,
            onChanged: (v) {
              setState(() {
                _bandSize = v.round();
                _hasChanges = true;
              });
            },
          ),
        ],

        // Experience Level
        const SizedBox(height: 20),
        Text(
          'Experience Level',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ExperienceLevel.values.map((level) {
            final isSelected = _experienceLevel == level;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _experienceLevel = level;
                  _hasChanges = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.divider(brightness),
                  ),
                ),
                child: Text(
                  level.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.text(brightness),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Years of Experience
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Years of Experience: ',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.crimson,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_yearsOfExperience years',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _yearsOfExperience.clamp(1, 30).toDouble(),
          min: 1,
          max: 30,
          divisions: 29,
          activeColor: AppColors.crimson,
          onChanged: (v) {
            setState(() {
              _yearsOfExperience = v.round();
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  IconData _getArtistTypeIcon(ArtistType type) {
    switch (type) {
      case ArtistType.solo:
        return Icons.person_rounded;
      case ArtistType.duo:
        return Icons.people_rounded;
      case ArtistType.band:
        return Icons.groups_rounded;
      case ArtistType.dj:
        return Icons.album_rounded;
      case ArtistType.orchestra:
        return Icons.theater_comedy_rounded;
      case ArtistType.ensemble:
        return Icons.music_note_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎵 GENRES SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGenresSection(Brightness brightness) {
    final allGenres = [
      'Rock',
      'Pop',
      'Jazz',
      'Blues',
      'Classical',
      'R&B',
      'Hip-Hop',
      'Country',
      'Electronic',
      'Folk',
      'Reggae',
      'Latin',
      'Soul',
      'Funk',
      'Metal',
      'Indie',
      'Alternative',
      'World',
      'Gospel',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allGenres.map((genre) {
        final isSelected = _selectedGenres.contains(genre);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedGenres.remove(genre);
              } else {
                _selectedGenres.add(genre);
              }
              _hasChanges = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimson
                  : AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.divider(brightness),
              ),
            ),
            child: Text(
              genre,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.text(brightness),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎬 MEDIA SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMediaSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audio Samples
        _buildMediaSubsection(
          brightness: brightness,
          title: 'Audio Samples',
          icon: Icons.audiotrack_rounded,
          description: 'Upload your best tracks (max 10MB each)',
          items: _audioSamples.map((s) => s.url).toList(),
          onAdd: _addAudioSample,
          onRemove: (url) {
            setState(() {
              _audioSamples.removeWhere((s) => s.url == url);
              _hasChanges = true;
            });
          },
          itemBuilder: (url) {
            final sample = _audioSamples.firstWhere((s) => s.url == url);
            return _buildAudioItem(brightness, sample);
          },
        ),
        const SizedBox(height: 24),

        // Video Samples
        _buildMediaSubsection(
          brightness: brightness,
          title: 'Video Samples',
          icon: Icons.videocam_rounded,
          description: 'Show venues your live performances (max 50MB)',
          items: _videoSamples.map((s) => s.url).toList(),
          onAdd: _addVideoSample,
          onRemove: (url) {
            setState(() {
              _videoSamples.removeWhere((s) => s.url == url);
              _hasChanges = true;
            });
          },
          itemBuilder: (url) {
            final sample = _videoSamples.firstWhere((s) => s.url == url);
            return _buildVideoItem(brightness, sample);
          },
        ),
        const SizedBox(height: 24),

        // Photo Gallery
        _buildMediaSubsection(
          brightness: brightness,
          title: 'Photo Gallery',
          icon: Icons.photo_library_rounded,
          description: 'Add photos from your performances',
          items: _photoUrls,
          onAdd: _addPhoto,
          onRemove: (url) {
            setState(() {
              _photoUrls.remove(url);
              _hasChanges = true;
            });
          },
          itemBuilder: (url) => _buildPhotoItem(brightness, url),
          gridView: true,
        ),
      ],
    );
  }

  Widget _buildMediaSubsection({
    required Brightness brightness,
    required String title,
    required IconData icon,
    required String description,
    required List<String> items,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
    required Widget Function(String) itemBuilder,
    bool gridView = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.crimson, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              '${items.length} items',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 12),
        ),
        const SizedBox(height: 12),

        if (gridView)
          // Photo grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...items.map(
                (url) => Stack(
                  children: [
                    itemBuilder(url),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(url),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Add button
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface(brightness),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.crimson.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: AppColors.crimson,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        else
          // List view for audio/video
          Column(
            children: [
              ...items.map(
                (url) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    children: [
                      itemBuilder(url),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => onRemove(url),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Add button
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(brightness),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.crimson.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: AppColors.crimson),
                      const SizedBox(width: 8),
                      Text(
                        'Add $title',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAudioItem(Brightness brightness, AudioSample sample) {
    final title =
        sample.title ??
        Uri.parse(sample.url).pathSegments.lastOrNull ??
        'Audio Track';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.audiotrack_rounded,
              color: AppColors.crimson,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sample.durationSeconds != null)
                  Text(
                    '${sample.durationSeconds! ~/ 60}:${(sample.durationSeconds! % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.play_circle_rounded, color: AppColors.crimson, size: 32),
        ],
      ),
    );
  }

  Widget _buildVideoItem(Brightness brightness, VideoSample sample) {
    final title = sample.title ?? 'Video Sample';
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              image: sample.thumbnailUrl != null
                  ? DecorationImage(
                      image: NetworkImage(sample.thumbnailUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Center(
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (sample.durationSeconds != null)
                  Text(
                    '${sample.durationSeconds! ~/ 60}:${(sample.durationSeconds! % 60).toString().padLeft(2, '0')}',
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
    );
  }

  Widget _buildPhotoItem(Brightness brightness, String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.surface(brightness),
            child: Icon(
              Icons.broken_image_rounded,
              color: AppColors.textSec(brightness),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addAudioSample() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (max 10MB for audio)
        // ignore: dead_code, dead_null_aware_expression
        final fileSizeMB = (file.size ?? 0) / (1024 * 1024);
        if (fileSizeMB > 10) {
          _showSnackBar(
            'Audio file too large. Maximum size is 10MB (yours: ${fileSizeMB.toStringAsFixed(1)}MB)',
            isError: true,
          );
          return;
        }

        setState(() => _isLoading = true);

        try {
          final uploadResult = await _uploadService.uploadAudio(file.path!);

          setState(() {
            _audioSamples.add(
              AudioSample(
                url: uploadResult.url,
                title: file.name,
                cloudinaryPublicId: uploadResult.publicId,
              ),
            );
            _hasChanges = true;
            _isLoading = false;
          });

          _showSnackBar('Audio uploaded successfully!');
        } catch (e) {
          setState(() => _isLoading = false);

          // Handle 413 (Payload Too Large) error
          if (e.toString().contains('413')) {
            _showSnackBar(
              'File too large for upload. Try a smaller file (max 10MB).',
              isError: true,
            );
          } else {
            _showSnackBar('Upload failed. Please try again.', isError: true);
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to select audio file', isError: true);
    }
  }

  Future<void> _addVideoSample() async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        // Check file size (max 50MB for video)
        final fileSize = await File(video.path).length();
        final fileSizeMB = fileSize / (1024 * 1024);
        if (fileSizeMB > 50) {
          _showSnackBar(
            'Video file too large. Maximum size is 50MB (yours: ${fileSizeMB.toStringAsFixed(1)}MB)',
            isError: true,
          );
          return;
        }

        setState(() => _isLoading = true);

        try {
          final uploadResult = await _uploadService.uploadVideo(video.path);

          setState(() {
            _videoSamples.add(
              VideoSample(
                url: uploadResult.url,
                title: video.name,
                cloudinaryPublicId: uploadResult.publicId,
              ),
            );
            _hasChanges = true;
            _isLoading = false;
          });

          _showSnackBar('Video uploaded successfully!');
        } catch (e) {
          setState(() => _isLoading = false);

          // Handle 413 (Payload Too Large) error
          if (e.toString().contains('413')) {
            _showSnackBar(
              'Video too large for upload. Try a smaller file (max 50MB).',
              isError: true,
            );
          } else {
            _showSnackBar('Upload failed. Please try again.', isError: true);
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to select video file', isError: true);
    }
  }

  Future<void> _addPhoto() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() => _isLoading = true);

        try {
          for (final image in images) {
            final uploadResult = await _uploadService.uploadGalleryImage(
              image.path,
            );
            _photoUrls.add(uploadResult.url);
          }

          setState(() {
            _hasChanges = true;
            _isLoading = false;
          });

          _showSnackBar('${images.length} photo(s) uploaded!');
        } catch (e) {
          setState(() => _isLoading = false);
          _showSnackBar('Failed to upload some photos', isError: true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to select photos', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💰 PRICING SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPricingSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price Range
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                brightness: brightness,
                controller: _minPriceController,
                label: 'Min Price',
                hint: '100',
                icon: Icons.arrow_downward_rounded,
                keyboardType: TextInputType.number,
                prefix: '\$ ',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                brightness: brightness,
                controller: _maxPriceController,
                label: 'Max Price',
                hint: '500',
                icon: Icons.arrow_upward_rounded,
                keyboardType: TextInputType.number,
                prefix: '\$ ',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Rate Type
        Text(
          'Rate Type',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: ['hour', 'event', 'day'].map((type) {
            final isSelected = _pricePer == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _pricePer = type;
                  _hasChanges = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.divider(brightness),
                  ),
                ),
                child: Text(
                  'Per ${type[0].toUpperCase()}${type.substring(1)}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.text(brightness),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📍 AVAILABILITY SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAvailabilitySection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Travel Distance
        Row(
          children: [
            Text(
              'Max Travel Distance: ',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.crimson,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_maxTravelDistance miles',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _maxTravelDistance.clamp(10, 200).toDouble(),
          min: 10,
          max: 200,
          divisions: 19,
          activeColor: AppColors.crimson,
          onChanged: (v) {
            setState(() {
              _maxTravelDistance = v.round();
              _hasChanges = true;
            });
          },
        ),
        const SizedBox(height: 24),

        // Equipment
        Text(
          'Equipment You Bring',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        // Equipment chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._equipment.map(
              (item) => Chip(
                label: Text(item),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _equipment.remove(item);
                    _hasChanges = true;
                  });
                },
                backgroundColor: AppColors.crimson.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: AppColors.crimson),
                deleteIconColor: AppColors.crimson,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Add equipment
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _equipmentController,
                style: TextStyle(color: AppColors.text(brightness)),
                decoration: InputDecoration(
                  hintText: 'Add equipment (e.g., PA System, Microphones)',
                  hintStyle: TextStyle(
                    color: AppColors.textSec(brightness).withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surface(brightness),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_equipmentController.text.isNotEmpty) {
                  setState(() {
                    _equipment.add(_equipmentController.text);
                    _equipmentController.clear();
                    _hasChanges = true;
                  });
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔗 SOCIAL LINKS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSocialLinksSection(Brightness brightness) {
    return Column(
      children: [
        _buildTextField(
          brightness: brightness,
          controller: _websiteController,
          label: 'Website',
          hint: 'https://yourwebsite.com',
          icon: Icons.language_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          brightness: brightness,
          controller: _instagramController,
          label: 'Instagram',
          hint: '@username',
          icon: Icons.camera_alt_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          brightness: brightness,
          controller: _spotifyController,
          label: 'Spotify',
          hint: 'Spotify profile URL',
          icon: Icons.music_note_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          brightness: brightness,
          controller: _youtubeController,
          label: 'YouTube',
          hint: 'YouTube channel URL',
          icon: Icons.play_circle_rounded,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💾 SAVE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSaveButton(Brightness brightness) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.crimson,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: AppColors.crimson.withValues(alpha: 0.5),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate location (critical for matching)
    if (_city == null ||
        _country == null ||
        _latitude == null ||
        _longitude == null) {
      _showSnackBar(
        'Please set your location. It\'s required for matching with venues.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload new profile photo if changed
      String? photoUrl = _profilePhotoUrl;
      if (_newProfilePhoto != null) {
        final uploadResult = await _uploadService.uploadProfilePhoto(
          _newProfilePhoto!.path,
        );
        photoUrl = uploadResult.url;
      }

      // Build update request with ALL data including location
      final request = UpdateArtistRequest(
        stageName: _stageNameController.text.isNotEmpty
            ? _stageNameController.text
            : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        artistType: _artistType,
        genres: _selectedGenres.isNotEmpty ? _selectedGenres : null,
        experienceLevel: _experienceLevel,
        yearsOfExperience: _yearsOfExperience,
        bandSize: _bandSize,
        maxTravelDistance: _maxTravelDistance,
        equipment: _equipment.isNotEmpty ? _equipment : null,
        galleryUrls: _photoUrls.isNotEmpty ? _photoUrls : null,
        // Location is CRITICAL for matching algorithm
        location: Location(
          coordinates: [
            _longitude!,
            _latitude!,
          ], // [longitude, latitude] - GeoJSON format
          city: _city,
          country: _country,
        ),
        priceRange: PriceRange(
          min: double.tryParse(_minPriceController.text) ?? 100,
          max: double.tryParse(_maxPriceController.text) ?? 500,
          currency: _currency,
          per: _pricePer,
        ),
        socialLinks: SocialLinks(
          website: _websiteController.text.isNotEmpty
              ? _websiteController.text
              : null,
          instagram: _instagramController.text.isNotEmpty
              ? _instagramController.text
              : null,
          spotify: _spotifyController.text.isNotEmpty
              ? _spotifyController.text
              : null,
          youtube: _youtubeController.text.isNotEmpty
              ? _youtubeController.text
              : null,
        ),
        // Include audio/video samples for full profile sync
        audioSamples: _audioSamples.isNotEmpty ? _audioSamples : null,
        videoSamples: _videoSamples.isNotEmpty ? _videoSamples : null,
      );

      // Update profile via AuthProvider (updates backend + local state)
      if (mounted) {
        final success = await context.read<AuthProvider>().updateArtistProfile(
          request,
        );
        if (!success) {
          throw Exception('Failed to update profile');
        }
      }

      setState(() {
        _isSaving = false;
        _hasChanges = false;
        _newProfilePhoto = null;
        _profilePhotoUrl = photoUrl;
      });

      _showSnackBar('Profile saved successfully! ✓');
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar('Failed to save profile: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _confirmExit() {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Leave screen
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
