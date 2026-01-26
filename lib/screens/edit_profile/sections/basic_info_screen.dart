/// 📝 BASIC INFO SCREEN - Edit Profile Sub-Screen
///
/// Role-aware basic info editing:
/// - Artist: Stage name, bio, genres, artist type
/// - Venue: Venue name, description, venue type
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../widgets/edit_profile_widgets.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artistService = ArtistService();
  final _venueService = VenueService();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  // State
  List<String> _selectedGenres = [];
  ArtistType _artistType = ArtistType.solo;
  String _venueType = 'bar';
  int? _bandSize;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Genre options
  static const List<String> _availableGenres = [
    'Rock',
    'Pop',
    'Jazz',
    'Blues',
    'R&B',
    'Hip Hop',
    'Electronic',
    'Country',
    'Folk',
    'Classical',
    'Reggae',
    'Soul',
    'Funk',
    'Metal',
    'Punk',
    'Indie',
    'Latin',
    'World',
    'Acoustic',
    'Alternative',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _initializeData();
  }

  void _initializeData() {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    if (auth.isArtist && profile.artist != null) {
      final artist = profile.artist!;
      _nameController.text = artist.stageName;
      _bioController.text = artist.bio ?? '';
      _selectedGenres = List.from(artist.genres);
      _artistType = artist.artistType;
      _bandSize = artist.bandSize;
    } else if (!auth.isArtist && profile.venue != null) {
      final venue = profile.venue!;
      _nameController.text = venue.name;
      _bioController.text = venue.description ?? '';
      _venueType = venue.venueType ?? 'bar';
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
        await _artistService.updateMyProfile(
          UpdateArtistRequest(
            stageName: _nameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            genres: _selectedGenres,
            artistType: _artistType,
            bandSize: _artistType == ArtistType.band ? _bandSize : null,
          ),
        );
      } else {
        await _venueService.updateMyProfile(
          UpdateVenueRequest(
            venueName: _nameController.text.trim(),
            description: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            venueType: _venueType,
          ),
        );
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Profile updated successfully!'),
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
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();
    final isArtist = auth.isArtist;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness, isArtist),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              EditProfileTextField(
                label: isArtist ? 'Stage Name' : 'Venue Name',
                controller: _nameController,
                hint: isArtist ? 'Enter your stage name' : 'Enter venue name',
                prefixIcon: isArtist ? Icons.mic : Icons.business,
                isRequired: true,
                onChanged: (_) => _markChanged(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isArtist
                        ? 'Stage name is required'
                        : 'Venue name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Bio/Description Field
              EditProfileTextField(
                label: isArtist ? 'Bio' : 'Description',
                controller: _bioController,
                hint: isArtist
                    ? 'Tell venues about yourself...'
                    : 'Describe your venue...',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
                maxLength: 500,
                onChanged: (_) => _markChanged(),
              ),

              const SizedBox(height: 24),

              // Artist Type or Venue Type
              if (isArtist) ...[
                _buildArtistTypeSelector(brightness),
                if (_artistType == ArtistType.band) ...[
                  const SizedBox(height: 24),
                  _buildBandSizeField(brightness),
                ],
              ] else ...[
                _buildVenueTypeSelector(brightness),
              ],

              const SizedBox(height: 24),

              // Genres
              _buildGenreSelector(brightness, isArtist),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness, bool isArtist) {
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
        'Basic Info',
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

  Widget _buildArtistTypeSelector(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artist Type',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ArtistType.values.map((type) {
            final isSelected = _artistType == type;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _artistType = type);
                _markChanged();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.border(brightness),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _formatArtistType(type),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.text(brightness),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatArtistType(ArtistType type) {
    switch (type) {
      case ArtistType.solo:
        return 'Solo';
      case ArtistType.band:
        return 'Band';
      case ArtistType.duo:
        return 'Duo';
      case ArtistType.dj:
        return 'DJ';
      case ArtistType.orchestra:
        return 'Orchestra';
      case ArtistType.ensemble:
        return 'Ensemble';
    }
  }

  Widget _buildBandSizeField(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Band Size',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [2, 3, 4, 5, 6, 7, 8, 10].map((size) {
            final isSelected = _bandSize == size;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _bandSize = size);
                _markChanged();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.border(brightness),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    size.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.text(brightness),
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVenueTypeSelector(Brightness brightness) {
    final venueTypes = VenueType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue Type',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            border: Border.all(
              color: AppColors.border(brightness),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _venueType,
              isExpanded: true,
              dropdownColor: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSec(brightness),
              ),
              items: venueTypes.map((type) {
                return DropdownMenuItem(
                  value: type.value,
                  child: Text(
                    type.displayName,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 15,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _venueType = value);
                  _markChanged();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreSelector(Brightness brightness, bool isArtist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArtist ? 'Genres' : 'Preferred Genres',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedGenres.length >= 5
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedGenres.length}/5',
                style: TextStyle(
                  color: _selectedGenres.length >= 5
                      ? AppColors.warning
                      : AppColors.crimson,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableGenres.map((genre) {
            final isSelected = _selectedGenres.contains(genre);
            final canSelect = _selectedGenres.length < 5 || isSelected;

            return GestureDetector(
              onTap: () {
                if (!canSelect && !isSelected) return;
                HapticFeedback.lightImpact();
                setState(() {
                  if (isSelected) {
                    _selectedGenres.remove(genre);
                  } else if (_selectedGenres.length < 5) {
                    _selectedGenres.add(genre);
                  }
                });
                _markChanged();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.border(brightness),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  genre,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : canSelect
                            ? AppColors.text(brightness)
                            : AppColors.textSec(brightness),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
