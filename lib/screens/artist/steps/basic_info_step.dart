import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/models/artist_models.dart';
import '../artist_profile_setup_screen.dart';

/// Step 1: Basic Info
/// - Display Name
/// - Stage Name (optional)
/// - Bio
/// - Genres (multi-select)
/// - Influences (tags)

class BasicInfoStep extends StatefulWidget {
  final ArtistProfileData profileData;
  final VoidCallback onNext;

  const BasicInfoStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _stageNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _influenceController = TextEditingController();

  final List<String> _availableGenres = [
    'Rock',
    'Jazz',
    'Pop',
    'Hip-Hop',
    'R&B',
    'Country',
    'Electronic',
    'Classical',
    'Folk',
    'Indie',
    'Metal',
    'Blues',
    'Reggae',
    'Soul',
    'Funk',
    'Latin',
    'World',
    'Alternative',
    'Punk',
    'Gospel',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill if data exists
    _displayNameController.text = widget.profileData.displayName ?? '';
    _stageNameController.text = widget.profileData.stageName ?? '';
    _bioController.text = widget.profileData.bio ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _stageNameController.dispose();
    _bioController.dispose();
    _influenceController.dispose();
    super.dispose();
  }

  void _addInfluence(String influence) {
    if (influence.isNotEmpty &&
        !widget.profileData.influences.contains(influence)) {
      setState(() {
        widget.profileData.influences.add(influence);
      });
      _influenceController.clear();
    }
  }

  void _removeInfluence(String influence) {
    setState(() {
      widget.profileData.influences.remove(influence);
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (widget.profileData.genres.contains(genre)) {
        widget.profileData.genres.remove(genre);
      } else {
        if (widget.profileData.genres.length < 5) {
          widget.profileData.genres.add(genre);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Maximum 5 genres allowed'),
              backgroundColor: AppColors.crimson,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    });
  }

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      widget.profileData.displayName = _displayNameController.text.trim();
      widget.profileData.stageName = _stageNameController.text.trim();
      widget.profileData.bio = _bioController.text.trim();

      if (widget.profileData.genres.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select at least one genre'),
            backgroundColor: AppColors.crimson,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Name
            _buildSectionTitle('Display Name *', brightness),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _displayNameController,
              hint: 'Your name or band name',
              brightness: brightness,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Display name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Stage Name (Optional)
            _buildSectionTitle('Stage Name', brightness, isOptional: true),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _stageNameController,
              hint: 'e.g., "The Velvet Tones"',
              brightness: brightness,
            ),

            const SizedBox(height: 20),

            // Bio
            _buildSectionTitle('Bio', brightness),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _bioController,
              hint:
                  'Tell venues about yourself, your style, and what makes you unique...',
              brightness: brightness,
              maxLines: 4,
              maxLength: 500,
            ),

            const SizedBox(height: 24),

            // Genres
            _buildSectionTitle(
              'Genres (select up to 5) *',
              brightness,
              subtitle: '${widget.profileData.genres.length}/5 selected',
            ),
            const SizedBox(height: 12),
            _buildGenreChips(brightness),

            const SizedBox(height: 24),

            // Influences
            _buildSectionTitle(
              'Musical Influences',
              brightness,
              isOptional: true,
              subtitle: 'Artists who inspire your sound',
            ),
            const SizedBox(height: 8),
            _buildInfluenceInput(brightness),
            const SizedBox(height: 12),
            _buildInfluenceTags(brightness),

            const SizedBox(height: 32),

            // Continue Button
            _buildContinueButton(brightness),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    Brightness brightness, {
    bool isOptional = false,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.border(brightness),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Optional',
                  style: TextStyle(
                    color: AppColors.textTert(brightness),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Brightness brightness,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.text(brightness), fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textTert(brightness),
          fontSize: 15,
        ),
        filled: true,
        fillColor: AppColors.inputFill(brightness),
        counterStyle: TextStyle(color: AppColors.textTert(brightness)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.crimson, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildGenreChips(Brightness brightness) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: _availableGenres.map((genre) {
        final isSelected = widget.profileData.genres.contains(genre);
        return GestureDetector(
          onTap: () => _toggleGenre(genre),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimson
                  : AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.border(brightness),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              genre,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.text(brightness),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfluenceInput(Brightness brightness) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _influenceController,
            style: TextStyle(color: AppColors.text(brightness), fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g., John Coltrane, Amy Winehouse',
              hintStyle: TextStyle(
                color: AppColors.textTert(brightness),
                fontSize: 15,
              ),
              filled: true,
              fillColor: AppColors.inputFill(brightness),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border(brightness)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border(brightness)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.crimson, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: _addInfluence,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _addInfluence(_influenceController.text.trim()),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.crimson,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildInfluenceTags(Brightness brightness) {
    if (widget.profileData.influences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.profileData.influences.map((influence) {
        return Container(
          padding: const EdgeInsets.only(left: 14, right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                influence,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removeInfluence(influence),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textTert(brightness),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(Brightness brightness) {
    return GestureDetector(
      onTap: _validateAndContinue,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.crimson,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
