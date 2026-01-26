/// ✏️ GIGMATCH Edit Profile Screen - PROFESSIONAL VERSION
///
/// Features:
/// - Tabbed interface (Info, Media, Settings)
/// - Advanced location picker
/// - Media uploads (Gallery, Audio, Video)
/// - Social links
/// - Pricing & Equipment
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/services/upload_service.dart';
import '../core/services/venue_service.dart';
import '../core/models/models.dart';
import '../widgets/location_search_sheet.dart';
import '../widgets/media_upload_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();
  late TabController _tabController;

  // State
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _newProfilePhotoPath;

  // ─── INFO TAB CONTROLLERS ───
  late TextEditingController _nameController;
  late TextEditingController _stageNameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;

  // Location Data
  double? _latitude;
  double? _longitude;
  String? _country;

  // Genres
  List<String> _selectedGenres = [];

  // Socials
  late TextEditingController _instagramController;
  late TextEditingController _spotifyController;
  late TextEditingController _youtubeController;
  late TextEditingController _soundcloudController;

  // ─── MEDIA TAB DATA ───
  List<String> _galleryUrls = [];
  List<AudioSample> _audioSamples = [];
  List<VideoSample> _videoSamples = [];

  // ─── SETTINGS TAB CONTROLLERS ───
  late TextEditingController _phoneController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _equipmentController; // Comma separated
  late TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize with placeholders
    _nameController = TextEditingController();
    _stageNameController = TextEditingController();
    _bioController = TextEditingController();
    _cityController = TextEditingController();
    _instagramController = TextEditingController();
    _spotifyController = TextEditingController();
    _youtubeController = TextEditingController();
    _soundcloudController = TextEditingController();
    _phoneController = TextEditingController();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    _equipmentController = TextEditingController();
    _capacityController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentProfile());
  }

  void _loadCurrentProfile() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final artist = auth.artistProfile;
    final venue = auth.venueProfile;

    if (artist != null) {
      _nameController.text = user?.name ?? '';
      _stageNameController.text = artist.stageName;
      _bioController.text = artist.bio ?? '';

      // Location
      _cityController.text = artist.location?.city ?? artist.location?.formattedAddress ?? '';
      _latitude = artist.location?.latitude;
      _longitude = artist.location?.longitude;
      _country = artist.location?.country;

      _selectedGenres = List<String>.from(artist.genres);

      // Socials
      _instagramController.text = artist.socialLinks?.instagram ?? '';
      _spotifyController.text = artist.socialLinks?.spotify ?? '';
      _youtubeController.text = artist.socialLinks?.youtube ?? '';
      _soundcloudController.text = artist.socialLinks?.soundcloud ?? '';

      // Media
      _galleryUrls = List<String>.from(artist.galleryUrls);
      _audioSamples = List<AudioSample>.from(artist.audioSamples);
      _videoSamples = List<VideoSample>.from(artist.videoSamples);

      // Settings
      _phoneController.text = user?.phone ?? '';
      _minPriceController.text = artist.minPrice.toString();
      _maxPriceController.text = artist.maxPrice.toString();
      _equipmentController.text = artist.equipment.join(', ');
    } else if (venue != null) {
      _nameController.text = venue.name;
      _bioController.text = venue.description ?? '';
      _phoneController.text = venue.phone ?? '';
      _cityController.text = venue.location?.city ?? venue.location?.formattedAddress ?? '';
      _latitude = venue.location?.latitude;
      _longitude = venue.location?.longitude;
      _country = venue.location?.country;
      _capacityController.text = venue.capacity?.toString() ?? '';

      if (venue.gigPreferences != null) {
        _selectedGenres = List<String>.from(venue.gigPreferences!.preferredGenres);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _stageNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _instagramController.dispose();
    _spotifyController.dispose();
    _youtubeController.dispose();
    _soundcloudController.dispose();
    _phoneController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _equipmentController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // ─── ACTIONS ───

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

  void _openLocationPicker(Brightness brightness) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSearchSheet(brightness: brightness),
    );

    if (result != null && result is Map) {
      setState(() {
        _cityController.text = result['address'] ?? '';
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _country = result['country']; // Might be null depending on LocationService
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      String? uploadedPhotoUrl;

      // Upload profile photo if changed
      if (_newProfilePhotoPath != null) {
        final result = await _uploadService.uploadProfilePhoto(_newProfilePhotoPath!);
        uploadedPhotoUrl = result.url;
      }

      // 1. Update User Profile (Name, Photo)
      final userUpdates = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (uploadedPhotoUrl != null) 'profilePhotoUrl': uploadedPhotoUrl,
      };
      await auth.updateProfile(userUpdates);

      // 2. Update Artist Profile
      if (auth.isArtist) {
        final equipmentList = _equipmentController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final updateRequest = UpdateArtistRequest(
          stageName: _stageNameController.text.trim(),
          bio: _bioController.text.trim(),
          genres: _selectedGenres,
          location: _latitude != null && _longitude != null
              ? Location(
                  coordinates: [_longitude!, _latitude!],
                  city: _cityController.text,
                  country: _country,
                  formattedAddress: _cityController.text,
                )
              : null,
          socialLinks: SocialLinks(
            instagram: _instagramController.text.trim(),
            spotify: _spotifyController.text.trim(),
            youtube: _youtubeController.text.trim(),
            soundcloud: _soundcloudController.text.trim(),
          ),
          galleryUrls: _galleryUrls,
          audioSamples: _audioSamples,
          videoSamples: _videoSamples,
          minPrice: double.tryParse(_minPriceController.text) ?? 0,
          maxPrice: double.tryParse(_maxPriceController.text) ?? 0,
          equipment: equipmentList,
        );

        final success = await auth.updateArtistProfile(updateRequest);
        if (!success) throw Exception(auth.errorMessage ?? 'Failed to update artist profile');
      }
      // 3. Update Venue Profile
      else if (auth.isVenue) {
         final updateRequest = UpdateVenueRequest(
          venueName: _nameController.text.trim(),
          description: _bioController.text.trim(),
          phone: _phoneController.text.trim(),
          preferredGenres: _selectedGenres,
          capacity: int.tryParse(_capacityController.text.trim()),
          location: _latitude != null && _longitude != null
              ? VenueLocation(
                  coordinates: [_longitude!, _latitude!],
                  city: _cityController.text,
                  country: _country,
                  formattedAddress: _cityController.text,
                )
              : null,
        );

        final success = await auth.updateVenueProfile(updateRequest);
        if (!success) throw Exception(auth.errorMessage ?? 'Failed to update venue profile');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── UI BUILDERS ───

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();

    if (auth.isVenue) {
      return _buildVenueLayout(brightness);
    }

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: AppColors.background(brightness),
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: _buildAppBarActions(brightness),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(brightness),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.crimson,
                labelColor: AppColors.crimson,
                unselectedLabelColor: AppColors.textSec(brightness),
                tabs: const [
                  Tab(text: 'INFO'),
                  Tab(text: 'MEDIA'),
                  Tab(text: 'SETTINGS'),
                ],
              ),
            ),
          ];
        },
        body: Form(
          key: _formKey,
          onChanged: () => _hasChanges = true,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(brightness),
              _buildMediaTab(brightness),
              _buildSettingsTab(brightness),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueLayout(Brightness brightness) {
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.background(brightness),
        title: Text('Edit Venue Profile', style: TextStyle(color: AppColors.text(brightness))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: _buildAppBarActions(brightness),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => _hasChanges = true,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
             _buildPhotoSection(brightness),
             const SizedBox(height: 24),
            _buildTextField(brightness, _nameController, 'Venue Name', Icons.store),
            const SizedBox(height: 16),
            _buildTextField(brightness, _bioController, 'Description', Icons.info, maxLines: 4),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _openLocationPicker(brightness),
              child: AbsorbPointer(
                child: _buildTextField(brightness, _cityController, 'Location', Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(brightness, _phoneController, 'Phone', Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(brightness, _capacityController, 'Capacity', Icons.people, keyboardType: TextInputType.number),
             const SizedBox(height: 32),
            _buildSectionHeader(brightness, 'Preferred Genres'),
            _buildGenreSelector(brightness),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(Brightness brightness) {
    return [
      if (_isSaving)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.crimson)
          ),
        )
      else
        TextButton(
          onPressed: _hasChanges ? _saveProfile : null,
          child: Text(
            'SAVE',
            style: TextStyle(
              color: _hasChanges ? AppColors.crimson : AppColors.textSec(brightness),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    ];
  }

  Widget _buildPhotoSection(Brightness brightness) {
     final auth = context.watch<AuthProvider>();
    final currentPhoto = auth.user?.profilePhotoUrl;
     return Center(
      child: GestureDetector(
        onTap: _pickProfilePhoto,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.crimson, width: 3),
                image: _newProfilePhotoPath != null
                    ? DecorationImage(
                        image: FileImage(File(_newProfilePhotoPath!)),
                        fit: BoxFit.cover,
                      )
                    : currentPhoto != null
                        ? DecorationImage(
                            image: NetworkImage(currentPhoto),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: (_newProfilePhotoPath == null && currentPhoto == null)
                  ? Icon(Icons.store, size: 50, color: AppColors.textSec(brightness))
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.crimson,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Brightness brightness) {
    final auth = context.watch<AuthProvider>();
    final currentPhoto = auth.user?.profilePhotoUrl;

    return Container(
      color: AppColors.surface(brightness),
      child: Center(
        child: GestureDetector(
          onTap: _pickProfilePhoto,
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.crimson, width: 3),
                  image: _newProfilePhotoPath != null
                      ? DecorationImage(
                          image: FileImage(File(_newProfilePhotoPath!)),
                          fit: BoxFit.cover,
                        )
                      : currentPhoto != null
                          ? DecorationImage(
                              image: NetworkImage(currentPhoto),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: (_newProfilePhotoPath == null && currentPhoto == null)
                    ? Icon(Icons.person, size: 50, color: AppColors.textSec(brightness))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.crimson,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(Brightness brightness) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader(brightness, 'Basic Info'),
        _buildTextField(brightness, _nameController, 'Full Name', Icons.person),
        const SizedBox(height: 16),
        _buildTextField(brightness, _stageNameController, 'Stage Name', Icons.mic),
        const SizedBox(height: 16),
        _buildTextField(
          brightness,
          _bioController,
          'Bio',
          Icons.info,
          maxLines: 4,
        ),
        const SizedBox(height: 16),

        // Location
        GestureDetector(
          onTap: () => _openLocationPicker(brightness),
          child: AbsorbPointer(
            child: _buildTextField(
              brightness,
              _cityController,
              'Location',
              Icons.location_on,
            ),
          ),
        ),

        const SizedBox(height: 32),
        _buildSectionHeader(brightness, 'Genres'),
        _buildGenreSelector(brightness),

        const SizedBox(height: 32),
        _buildSectionHeader(brightness, 'Social Links'),
        _buildTextField(brightness, _instagramController, 'Instagram Username', Icons.camera_alt_outlined, prefixText: '@'),
        const SizedBox(height: 16),
        _buildTextField(brightness, _spotifyController, 'Spotify Artist URL', Icons.music_note),
        const SizedBox(height: 16),
        _buildTextField(brightness, _youtubeController, 'YouTube Channel URL', Icons.play_circle_outline),
        const SizedBox(height: 16),
        _buildTextField(brightness, _soundcloudController, 'SoundCloud URL', Icons.cloud_queue),
      ],
    );
  }

  Widget _buildMediaTab(Brightness brightness) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader(brightness, 'Photo Gallery'),
        GalleryUploadGrid(
          imageUrls: _galleryUrls,
          brightness: brightness,
          onChanged: (urls) => setState(() {
            _galleryUrls = urls;
            _hasChanges = true;
          }),
        ),

        const SizedBox(height: 32),
        _buildSectionHeader(brightness, 'Audio Tracks'),
        Text(
          'Upload your best tracks (MP3, WAV). Maximum 10MB per file.',
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 12),
        ),
        const SizedBox(height: 12),
        AudioUploadList(
          samples: _audioSamples,
          brightness: brightness,
          onChanged: (samples) => setState(() {
            _audioSamples = samples;
            _hasChanges = true;
          }),
        ),

        const SizedBox(height: 32),
        _buildSectionHeader(brightness, 'Videos'),
         Text(
          'Upload performance videos. Maximum 50MB per file.',
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 12),
        ),
        const SizedBox(height: 12),
        VideoUploadList(
          samples: _videoSamples,
          brightness: brightness,
          onChanged: (samples) => setState(() {
            _videoSamples = samples;
            _hasChanges = true;
          }),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(Brightness brightness) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader(brightness, 'Contact & Pricing'),
        _buildTextField(brightness, _phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildTextField(brightness, _minPriceController, 'Min Price (\$)', Icons.attach_money, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(brightness, _maxPriceController, 'Max Price (\$)', Icons.attach_money, keyboardType: TextInputType.number),
            ),
          ],
        ),

        const SizedBox(height: 32),
        _buildSectionHeader(brightness, 'Equipment'),
        Text(
          'List equipment you can bring (comma separated)',
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 12),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          brightness,
          _equipmentController,
          'e.g. PA System, Microphone, Guitar Amp',
          Icons.speaker,
          maxLines: 2,
        ),
      ],
    );
  }

  // ─── WIDGET HELPERS ───

  Widget _buildSectionHeader(Brightness brightness, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField(
    Brightness brightness,
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: AppColors.text(brightness)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textSec(brightness), size: 20),
              prefixText: prefixText,
              prefixStyle: TextStyle(color: AppColors.text(brightness)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreSelector(Brightness brightness) {
    final allGenres = [
      'Rock', 'Pop', 'Jazz', 'Blues', 'Country', 'Hip Hop', 'R&B',
      'Electronic', 'Classical', 'Folk', 'Indie', 'Metal', 'Reggae',
      'Soul', 'Funk', 'Latin', 'Alternative', 'Punk'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allGenres.map((genre) {
        final isSelected = _selectedGenres.contains(genre);
        return ChoiceChip(
          label: Text(genre),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                if (_selectedGenres.length < 5) {
                  _selectedGenres.add(genre);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Maximum 5 genres allowed')),
                  );
                }
              } else {
                _selectedGenres.remove(genre);
              }
              _hasChanges = true;
            });
          },
          selectedColor: AppColors.crimson,
          backgroundColor: AppColors.surface(brightness),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.text(brightness),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.crimson : AppColors.border(brightness),
            ),
          ),
        );
      }).toList(),
    );
  }
}
