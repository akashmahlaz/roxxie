/// ✏️ GIGMATCH Edit Profile Screen
///
/// Modern, premium profile editor with:
/// - Smooth animations and transitions
/// - Real-time preview
/// - Photo/video/audio editing
/// - Cloudinary uploads
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
import '../widgets/widgets.dart';

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

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _stageNameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;

  // State
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _newProfilePhotoPath;
  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    // Initialize controllers with current data
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentProfile());
  }

  void _loadCurrentProfile() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final artist = auth.artistProfile;
    final venue = auth.venueProfile;

    _nameController = TextEditingController(
      text: auth.isArtist
          ? (artist?.displayName ?? user?.name)
          : (venue?.name ?? user?.name),
    );
    _bioController = TextEditingController(
      text: auth.isArtist ? artist?.bio : venue?.description,
    );
    _stageNameController = TextEditingController(text: artist?.stageName ?? '');
    _phoneController = TextEditingController(
      text: '', // Phone not available in Artist/Venue API response
    );
    _cityController = TextEditingController(
      text: auth.isArtist ? artist?.location?.city : venue?.location?.city,
    );

    if (auth.isArtist && artist != null) {
      _selectedGenres = List<String>.from(artist.genres);
    } else if (auth.isVenue && venue != null) {
      _selectedGenres = List<String>.from(
        venue.gigPreferences?.preferredGenres ?? [],
      );
    }

    setState(() {});
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _stageNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      String? uploadedPhotoUrl;

      // Upload new photo if selected
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

      // Build update data
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (uploadedPhotoUrl != null) 'profilePhotoUrl': uploadedPhotoUrl,
      };

      // Update user profile
      final success = await auth.updateProfile(updates);

      // Update role-specific profile
      if (auth.isArtist) {
        await auth.updateArtistProfile(
          UpdateArtistRequest(
            stageName: _stageNameController.text.trim().isEmpty
                ? null
                : _stageNameController.text.trim(),
            bio: _bioController.text.trim(),
            genres: _selectedGenres,
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

      if (success) {
        _showSuccessSnackBar('Profile updated successfully');
        Navigator.pop(context);
      } else {
        _showErrorSnackBar(auth.errorMessage ?? 'Failed to update profile');
      }
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
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          onChanged: () => setState(() => _hasChanges = true),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile Photo Section
              _buildPhotoSection(brightness, auth),

              const SizedBox(height: 32),

              // Basic Info Section
              _buildSectionHeader(
                'Basic Information',
                Icons.person_rounded,
                brightness,
              ),
              const SizedBox(height: 16),
              _buildNameField(brightness, auth),
              if (auth.isArtist) ...[
                const SizedBox(height: 16),
                _buildStageNameField(brightness),
              ],
              const SizedBox(height: 16),
              _buildBioField(brightness, auth),

              const SizedBox(height: 32),

              // Contact Section
              _buildSectionHeader(
                'Contact',
                Icons.contact_phone_rounded,
                brightness,
              ),
              const SizedBox(height: 16),
              _buildPhoneField(brightness),
              const SizedBox(height: 16),
              _buildCityField(brightness),

              const SizedBox(height: 32),

              // Genres Section
              _buildSectionHeader(
                auth.isArtist ? 'Your Genres' : 'Preferred Genres',
                Icons.music_note_rounded,
                brightness,
              ),
              const SizedBox(height: 16),
              _buildGenreSelector(brightness),

              const SizedBox(height: 40),

              // Save Button
              _buildSaveButton(brightness),

              const SizedBox(height: 20),
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
      leading: GlassBackButton(
        onPressed: () {
          if (_hasChanges) {
            _showDiscardDialog(brightness);
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
        ),
      ),
      centerTitle: true,
    );
  }

  void _showDiscardDialog(Brightness brightness) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Discard Changes?',
          style: TextStyle(color: AppColors.text(brightness)),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to leave?',
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.crimson),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(Brightness brightness, AuthProvider auth) {
    final currentPhotoUrl = auth.user?.profilePhotoUrl;

    return Center(
      child: GestureDetector(
        onTap: _pickProfilePhoto,
        child: Stack(
          children: [
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.crimson.withValues(alpha: 0.2),
                    AppColors.wine.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: AppColors.crimson, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: _newProfilePhotoPath != null
                    ? Image.file(
                        File(_newProfilePhotoPath!),
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      )
                    : (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty
                          ? Image.network(
                              currentPhotoUrl,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (_, _, _) =>
                                  _buildAvatarPlaceholder(brightness, auth),
                            )
                          : _buildAvatarPlaceholder(brightness, auth)),
              ),
            ),

            // Edit Badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(Brightness brightness, AuthProvider auth) {
    return Container(
      color: AppColors.surface(brightness),
      child: Icon(
        auth.isArtist ? Icons.music_note_rounded : Icons.business_rounded,
        size: 48,
        color: AppColors.crimson,
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Brightness brightness,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.crimson, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(Brightness brightness, AuthProvider auth) {
    return _buildTextField(
      controller: _nameController,
      label: auth.isArtist ? 'Display Name' : 'Venue Name',
      hint: auth.isArtist ? 'Your name' : 'Your venue name',
      icon: auth.isArtist ? Icons.person_rounded : Icons.storefront_rounded,
      brightness: brightness,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Name is required';
        }
        return null;
      },
    );
  }

  Widget _buildStageNameField(Brightness brightness) {
    return _buildTextField(
      controller: _stageNameController,
      label: 'Stage Name',
      hint: 'Your artist/band name',
      icon: Icons.star_rounded,
      brightness: brightness,
    );
  }

  Widget _buildBioField(Brightness brightness, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          auth.isArtist ? 'Bio' : 'Description',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: TextFormField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 500,
            style: TextStyle(color: AppColors.text(brightness)),
            decoration: InputDecoration(
              hintText: auth.isArtist
                  ? 'Tell venues about yourself, your music, and experience...'
                  : 'Describe your venue, atmosphere, and events...',
              hintStyle: TextStyle(color: AppColors.textSec(brightness)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(Brightness brightness) {
    return _buildTextField(
      controller: _phoneController,
      label: 'Phone Number',
      hint: '+1 (555) 123-4567',
      icon: Icons.phone_rounded,
      brightness: brightness,
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildCityField(Brightness brightness) {
    return _buildTextField(
      controller: _cityController,
      label: 'City',
      hint: 'Your city',
      icon: Icons.location_city_rounded,
      brightness: brightness,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Brightness brightness,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(color: AppColors.text(brightness)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textSec(brightness)),
              prefixIcon: Icon(icon, color: AppColors.crimson, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreSelector(Brightness brightness) {
    final allGenres = [
      'Rock',
      'Pop',
      'Jazz',
      'Blues',
      'Country',
      'Hip Hop',
      'R&B',
      'Electronic',
      'Classical',
      'Folk',
      'Indie',
      'Metal',
      'Reggae',
      'Soul',
      'Funk',
      'Latin',
      'World',
      'Alternative',
      'Punk',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimson.withValues(alpha: 0.15)
                  : AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.border(brightness),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              genre,
              style: TextStyle(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.text(brightness),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(Brightness brightness) {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _hasChanges && !_isSaving
              ? const LinearGradient(
                  colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                )
              : null,
          color: _hasChanges && !_isSaving
              ? null
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasChanges && !_isSaving
                ? Colors.transparent
                : AppColors.border(brightness),
          ),
          boxShadow: _hasChanges && !_isSaving
              ? [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isSaving
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.text(brightness),
                  ),
                )
              : Text(
                  'Save Changes',
                  style: TextStyle(
                    color: _hasChanges
                        ? Colors.white
                        : AppColors.textSec(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
