part of '../edit_profile_v2_screen.dart';

/// Basic Information Tab
/// - Name, Stage Name, Bio
/// - Contact info
/// - Genres
/// - Artist type & experience
/// - Social links
class _BasicInfoTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController stageNameController;
  final TextEditingController bioController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController websiteController;
  final TextEditingController instagramController;
  final TextEditingController spotifyController;
  final TextEditingController youtubeController;
  final List<String> selectedGenres;
  final ArtistType artistType;
  final ExperienceLevel experienceLevel;
  final int yearsOfExperience;
  final int bandSize;
  final bool isArtist;
  final Function(List<String>) onGenresChanged;
  final Function(ArtistType) onArtistTypeChanged;
  final Function(ExperienceLevel) onExperienceLevelChanged;
  final Function(int) onYearsChanged;
  final Function(int) onBandSizeChanged;

  const _BasicInfoTab({
    required this.nameController,
    required this.stageNameController,
    required this.bioController,
    required this.phoneController,
    required this.cityController,
    required this.websiteController,
    required this.instagramController,
    required this.spotifyController,
    required this.youtubeController,
    required this.selectedGenres,
    required this.artistType,
    required this.experienceLevel,
    required this.yearsOfExperience,
    required this.bandSize,
    required this.isArtist,
    required this.onGenresChanged,
    required this.onArtistTypeChanged,
    required this.onExperienceLevelChanged,
    required this.onYearsChanged,
    required this.onBandSizeChanged,
  });

  static const List<String> _allGenres = [
    'Rock', 'Pop', 'Jazz', 'Blues', 'Country', 'R&B', 'Hip Hop',
    'Electronic', 'Folk', 'Indie', 'Metal', 'Punk', 'Classical',
    'Reggae', 'Soul', 'Funk', 'Gospel', 'Latin', 'World', 'Alternative',
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Basic Info Section
        _buildSectionHeader(context, 'Basic Information', Icons.person_rounded),
        const SizedBox(height: 16),
        
        _buildTextField(
          context,
          controller: nameController,
          label: isArtist ? 'Display Name' : 'Venue Name',
          hint: isArtist ? 'Your artist/band name' : 'Your venue name',
          icon: isArtist ? Icons.music_note_rounded : Icons.business_rounded,
          validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
        ),
        
        if (isArtist) ...[
          const SizedBox(height: 16),
          _buildTextField(
            context,
            controller: stageNameController,
            label: 'Stage Name (Optional)',
            hint: 'Your stage persona',
            icon: Icons.star_rounded,
          ),
        ],
        
        const SizedBox(height: 16),
        _buildTextField(
          context,
          controller: bioController,
          label: isArtist ? 'Bio' : 'Description',
          hint: isArtist 
              ? 'Tell venues about your music, style, and experience...'
              : 'Describe your venue, atmosphere, and what makes it special...',
          icon: Icons.description_rounded,
          maxLines: 4,
          maxLength: 500,
        ),

        const SizedBox(height: 32),

        // Genres Section
        _buildSectionHeader(context, isArtist ? 'Your Genres' : 'Preferred Genres', Icons.category_rounded),
        const SizedBox(height: 12),
        Text(
          'Select up to 5 genres',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        _buildGenreChips(context),

        if (isArtist) ...[
          const SizedBox(height: 32),

          // Artist Type & Experience Section
          _buildSectionHeader(context, 'Artist Details', Icons.mic_rounded),
          const SizedBox(height: 16),
          
          _buildArtistTypeSelector(context),
          const SizedBox(height: 16),
          _buildExperienceLevelSelector(context),
          const SizedBox(height: 16),
          _buildYearsOfExperience(context),
          
          if (artistType == ArtistType.band) ...[
            const SizedBox(height: 16),
            _buildBandSizeSelector(context),
          ],
        ],

        const SizedBox(height: 32),

        // Contact Section
        _buildSectionHeader(context, 'Location', Icons.location_on_rounded),
        const SizedBox(height: 16),
        
        _buildTextField(
          context,
          controller: cityController,
          label: 'City',
          hint: 'Your city or location',
          icon: Icons.location_city_rounded,
        ),
        
        const SizedBox(height: 16),
        _buildTextField(
          context,
          controller: phoneController,
          label: 'Phone (Optional)',
          hint: 'Contact number for bookings',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 32),

        // Social Links Section
        _buildSectionHeader(context, 'Social Links', Icons.link_rounded),
        const SizedBox(height: 16),
        
        _buildSocialLinkField(
          context,
          controller: websiteController,
          label: 'Website',
          hint: 'https://yoursite.com',
          icon: Icons.language_rounded,
        ),
        const SizedBox(height: 12),
        _buildSocialLinkField(
          context,
          controller: instagramController,
          label: 'Instagram',
          hint: '@username',
          icon: Icons.camera_alt_rounded,
          color: const Color(0xFFE1306C),
        ),
        const SizedBox(height: 12),
        _buildSocialLinkField(
          context,
          controller: spotifyController,
          label: 'Spotify',
          hint: 'Artist profile link',
          icon: Icons.music_note_rounded,
          color: const Color(0xFF1DB954),
        ),
        const SizedBox(height: 12),
        _buildSocialLinkField(
          context,
          controller: youtubeController,
          label: 'YouTube',
          hint: 'Channel link',
          icon: Icons.play_circle_filled_rounded,
          color: const Color(0xFFFF0000),
        ),

        const SizedBox(height: 100), // Bottom padding for save button
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final brightness = Theme.of(context).brightness;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cyan.withValues(alpha: 0.2),
                AppColors.rose.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.cyan, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final brightness = Theme.of(context).brightness;
    
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.text(brightness)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSec(brightness).withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: AppColors.textSec(brightness)),
        prefixIcon: Icon(icon, color: AppColors.cyan),
        filled: true,
        fillColor: AppColors.surface(brightness),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.crimson, width: 2),
        ),
        counterStyle: TextStyle(color: AppColors.textSec(brightness)),
      ),
    );
  }

  Widget _buildSocialLinkField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color? color,
  }) {
    final brightness = Theme.of(context).brightness;
    
    return TextFormField(
      controller: controller,
      style: TextStyle(color: AppColors.text(brightness)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSec(brightness).withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: AppColors.textSec(brightness)),
        prefixIcon: Icon(icon, color: color ?? AppColors.textSec(brightness)),
        filled: true,
        fillColor: AppColors.surface(brightness),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color ?? AppColors.cyan, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildGenreChips(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allGenres.map((genre) {
        final isSelected = selectedGenres.contains(genre);
        final canSelect = isSelected || selectedGenres.length < 5;
        
        return FilterChip(
          label: Text(genre),
          selected: isSelected,
          onSelected: canSelect ? (selected) {
            if (selected) {
              onGenresChanged([...selectedGenres, genre]);
            } else {
              onGenresChanged(selectedGenres.where((g) => g != genre).toList());
            }
          } : null,
          backgroundColor: AppColors.surface(brightness),
          selectedColor: AppColors.cyan.withValues(alpha: 0.2),
          checkmarkColor: AppColors.cyan,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.cyan : AppColors.textSec(brightness),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.cyan : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        );
      }).toList(),
    );
  }

  Widget _buildArtistTypeSelector(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artist Type',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ArtistType.values.map((type) {
            final isSelected = artistType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != ArtistType.values.last ? 8 : 0,
                ),
                child: _SelectableCard(
                  label: type.displayName,
                  icon: _getArtistTypeIcon(type),
                  isSelected: isSelected,
                  onTap: () => onArtistTypeChanged(type),
                ),
              ),
            );
          }).toList(),
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

  Widget _buildExperienceLevelSelector(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Experience Level',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ExperienceLevel.values.map((level) {
              final isSelected = experienceLevel == level;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(level.displayName),
                  selected: isSelected,
                  onSelected: (_) => onExperienceLevelChanged(level),
                  backgroundColor: AppColors.surface(brightness),
                  selectedColor: AppColors.rose.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.rose : AppColors.textSec(brightness),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.rose : Colors.transparent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildYearsOfExperience(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Years of Experience',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$yearsOfExperience ${yearsOfExperience == 1 ? 'year' : 'years'}',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.cyan,
            inactiveTrackColor: AppColors.surface(brightness),
            thumbColor: AppColors.cyan,
            overlayColor: AppColors.cyan.withValues(alpha: 0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: yearsOfExperience.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (v) => onYearsChanged(v.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildBandSizeSelector(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Band Size',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.rose.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$bandSize ${bandSize == 1 ? 'member' : 'members'}',
                style: TextStyle(
                  color: AppColors.rose,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.rose,
            inactiveTrackColor: AppColors.surface(brightness),
            thumbColor: AppColors.rose,
            overlayColor: AppColors.rose.withValues(alpha: 0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: bandSize.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            onChanged: (v) => onBandSizeChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.cyan.withValues(alpha: 0.1)
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.cyan : AppColors.textSec(brightness),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.cyan : AppColors.textSec(brightness),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
