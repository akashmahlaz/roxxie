import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 1: VENUE IDENTITY & ATMOSPHERE
///
/// Collects:
/// - Venue profile photo
/// - Venue capacity (slider)
/// - Vibe selection (chips)
/// - Amenities (checkboxes)

class VenueIdentityStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;

  const VenueIdentityStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
  });

  @override
  State<VenueIdentityStep> createState() => _VenueIdentityStepState();
}

class _VenueIdentityStepState extends State<VenueIdentityStep> {
  final ImagePicker _picker = ImagePicker();
  
  // Vibe options
  final List<String> _vibeOptions = [
    'Intimate', 'Rowdy', 'Upscale', 'Underground', 
    'Cozy', 'Industrial', 'Dark', 'Elegant', 'Casual'
  ];
  
  // Amenity options with icons
  final List<_AmenityOption> _amenityOptions = [
    _AmenityOption(id: 'pa_system', title: 'In-house PA System', icon: Icons.speaker_group_rounded),
    _AmenityOption(id: 'stage', title: 'Dedicated Stage', icon: Icons.theater_comedy_rounded),
    _AmenityOption(id: 'green_room', title: 'Artist Hospitality/Green Room', icon: Icons.emoji_food_beverage_rounded),
    _AmenityOption(id: 'lighting', title: 'Professional Lighting Rig', icon: Icons.lightbulb_rounded),
    _AmenityOption(id: 'parking', title: 'Parking Available', icon: Icons.local_parking_rounded),
    _AmenityOption(id: 'sound_engineer', title: 'Sound Engineer', icon: Icons.headphones_rounded),
  ];

  final Set<String> _selectedVibes = {};
  final Set<String> _selectedAmenities = {};

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    // Load capacity
    if (widget.profileData.capacity == 0) {
      widget.profileData.capacity = 150;
    }
    
    // Load vibes from amenities (we store vibes in a special format)
    for (final amenity in widget.profileData.amenities) {
      if (amenity.startsWith('vibe_')) {
        _selectedVibes.add(amenity.replaceFirst('vibe_', ''));
      } else {
        _selectedAmenities.add(amenity);
      }
    }
    
    // Load equipment as amenities
    if (widget.profileData.equipment.hasSoundSystem) _selectedAmenities.add('pa_system');
    if (widget.profileData.equipment.hasStage) _selectedAmenities.add('stage');
    if (widget.profileData.equipment.hasDressingRoom) _selectedAmenities.add('green_room');
    if (widget.profileData.equipment.hasLighting) _selectedAmenities.add('lighting');
    if (widget.profileData.equipment.hasParking) _selectedAmenities.add('parking');
  }

  void _saveData() {
    // Save amenities (combine vibes and actual amenities)
    final allAmenities = <String>[];
    for (final vibe in _selectedVibes) {
      allAmenities.add('vibe_$vibe');
    }
    allAmenities.addAll(_selectedAmenities);
    widget.profileData.amenities = allAmenities;
    
    // Save equipment
    widget.profileData.equipment.hasSoundSystem = _selectedAmenities.contains('pa_system');
    widget.profileData.equipment.hasStage = _selectedAmenities.contains('stage');
    widget.profileData.equipment.hasDressingRoom = _selectedAmenities.contains('green_room');
    widget.profileData.equipment.hasLighting = _selectedAmenities.contains('lighting');
    widget.profileData.equipment.hasParking = _selectedAmenities.contains('parking');
    
    widget.onDataChanged();
  }

  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          widget.profileData.profilePhotoUrl = image.path;
        });
        widget.onDataChanged();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us about your venue',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'High-quality photos and clear info attract the best talent.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════════
          // PROFILE PHOTO UPLOAD
          // ═══════════════════════════════════════════════════════════════════
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.graphite : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.crimson.withValues(alpha: 0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _buildPhotoContent(isDark),
                        ),
                      ),
                      // Edit button
                      Positioned(
                        bottom: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.crimson,
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
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.profileData.venueName != null) ...[
                  Text(
                    widget.profileData.venueName!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(brightness),
                    ),
                  ),
                  if (widget.profileData.location.city != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.profileData.location.city ?? ''}, ${widget.profileData.location.country ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // TECHNICAL & ATMOSPHERE SECTION
          // ═══════════════════════════════════════════════════════════════════
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.graphite.withValues(alpha: 0.3) : Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.crimson.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: AppColors.crimson,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Technical & Atmosphere',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(brightness),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Capacity Slider
                _buildCapacitySlider(isDark),
                const SizedBox(height: 28),

                // Vibe Selection
                _buildVibeSelection(isDark),
                const SizedBox(height: 28),

                // Amenities
                _buildAmenitiesSection(isDark),
              ],
            ),
          ),

          // Bottom padding
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildPhotoContent(bool isDark) {
    if (widget.profileData.profilePhotoUrl != null) {
      final path = widget.profileData.profilePhotoUrl!;
      if (path.startsWith('http')) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(path, fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: 0.3)),
          ],
        );
      } else {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(path), fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: 0.3)),
          ],
        );
      }
    }
    
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Icon(
        Icons.add_a_photo_rounded,
        size: 48,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildCapacitySlider(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Venue Capacity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text(isDark ? Brightness.dark : Brightness.light),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.profileData.capacity} people',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.crimson,
            inactiveTrackColor: isDark ? AppColors.slate : Colors.grey[300],
            thumbColor: AppColors.crimson,
            overlayColor: AppColors.crimson.withValues(alpha: 0.2),
            trackHeight: 8,
          ),
          child: Slider(
            value: widget.profileData.capacity.toDouble().clamp(20, 500),
            min: 20,
            max: 500,
            divisions: 48,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() {
                widget.profileData.capacity = value.round();
              });
              _saveData();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['20', '100', '250', '500+'].map((label) => 
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVibeSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The Vibe',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text(isDark ? Brightness.dark : Brightness.light),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _vibeOptions.map((vibe) {
            final isSelected = _selectedVibes.contains(vibe);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedVibes.remove(vibe);
                  } else {
                    _selectedVibes.add(vibe);
                  }
                });
                _saveData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.crimson.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppColors.crimson : (isDark ? AppColors.slate : Colors.grey[300]!),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  vibe,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.crimson : AppColors.text(isDark ? Brightness.dark : Brightness.light),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text(isDark ? Brightness.dark : Brightness.light),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_amenityOptions.length, (index) {
          final amenity = _amenityOptions[index];
          final isSelected = _selectedAmenities.contains(amenity.id);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedAmenities.remove(amenity.id);
                  } else {
                    _selectedAmenities.add(amenity.id);
                  }
                });
                _saveData();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.crimson.withValues(alpha: 0.5)
                        : (isDark ? AppColors.slate : Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      amenity.icon,
                      color: AppColors.crimson,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        amenity.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text(isDark ? Brightness.dark : Brightness.light),
                        ),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.crimson : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.crimson 
                              : (isDark ? AppColors.slate : Colors.grey[300]!),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AmenityOption {
  final String id;
  final String title;
  final IconData icon;

  _AmenityOption({
    required this.id,
    required this.title,
    required this.icon,
  });
}
