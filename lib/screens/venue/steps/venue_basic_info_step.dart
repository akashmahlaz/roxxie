import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme.dart';
import '../venue_profile_setup_screen.dart';

/// 🏢 STEP 1: VENUE BASIC INFO
///
/// Collects:
/// - Venue name
/// - Venue type (dropdown)
/// - Capacity
/// - Description
/// - Amenities (multi-select)

class VenueBasicInfoStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;

  const VenueBasicInfoStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
  });

  @override
  State<VenueBasicInfoStep> createState() => _VenueBasicInfoStepState();
}

class _VenueBasicInfoStepState extends State<VenueBasicInfoStep> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileData.venueName);
    _descriptionController = TextEditingController(
      text: widget.profileData.description,
    );
    _capacityController = TextEditingController(
      text: widget.profileData.capacity > 0
          ? widget.profileData.capacity.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      widget.profileData.venueName.isNotEmpty &&
      widget.profileData.venueType.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Venue Name
          _buildSectionTitle('Venue Name *', brightness),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _nameController,
            hint: 'Enter your venue name',
            icon: Icons.storefront_rounded,
            brightness: brightness,
            onChanged: (value) {
              widget.profileData.venueName = value;
              widget.onDataChanged();
            },
          ),

          const SizedBox(height: 28),

          // Venue Type
          _buildSectionTitle('Venue Type *', brightness),
          const SizedBox(height: 10),
          _buildVenueTypeSelector(brightness),

          const SizedBox(height: 28),

          // Capacity
          _buildSectionTitle('Capacity', brightness),
          const SizedBox(height: 4),
          Text(
            'How many guests can you accommodate?',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          _buildCapacityField(brightness),

          const SizedBox(height: 28),

          // Description
          _buildSectionTitle('Description', brightness),
          const SizedBox(height: 4),
          Text(
            'Tell artists about your venue',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          _buildDescriptionField(brightness),

          const SizedBox(height: 28),

          // Amenities
          _buildSectionTitle('Amenities', brightness),
          const SizedBox(height: 4),
          Text(
            'What do you offer performers?',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          _buildAmenitiesGrid(brightness),

          const SizedBox(height: 40),

          // Continue Button
          _buildContinueButton(brightness),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Brightness brightness) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.text(brightness),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Brightness brightness,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: TextField(
        controller: controller,
        onChanged: (value) {
          onChanged(value);
          setState(() {});
        },
        style: TextStyle(color: AppColors.text(brightness)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSec(brightness)),
          prefixIcon: Icon(icon, color: AppColors.crimson),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildVenueTypeSelector(Brightness brightness) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: VenueTypes.types.map((type) {
        final isSelected = widget.profileData.venueType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              widget.profileData.venueType = type;
            });
            widget.onDataChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimson.withValues(alpha: 0.15)
                  : AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.border(brightness),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.crimson,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  type,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCapacityField(Brightness brightness) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: TextField(
        controller: _capacityController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          widget.profileData.capacity = int.tryParse(value) ?? 0;
          widget.onDataChanged();
        },
        style: TextStyle(color: AppColors.text(brightness)),
        decoration: InputDecoration(
          hintText: 'e.g., 200',
          hintStyle: TextStyle(color: AppColors.textSec(brightness)),
          prefixIcon: const Icon(
            Icons.people_rounded,
            color: AppColors.crimson,
          ),
          suffixText: 'guests',
          suffixStyle: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(Brightness brightness) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 4,
        maxLength: 500,
        onChanged: (value) {
          widget.profileData.description = value;
          widget.onDataChanged();
        },
        style: TextStyle(color: AppColors.text(brightness)),
        decoration: InputDecoration(
          hintText:
              'Describe your venue, atmosphere, the type of events you host...',
          hintStyle: TextStyle(color: AppColors.textSec(brightness)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterStyle: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAmenitiesGrid(Brightness brightness) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: VenueAmenities.amenities.map((amenity) {
        final isSelected = widget.profileData.amenities.contains(amenity);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                widget.profileData.amenities.remove(amenity);
              } else {
                widget.profileData.amenities.add(amenity);
              }
            });
            widget.onDataChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.crimson.withValues(alpha: 0.15)
                  : AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.border(brightness),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 18,
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.textSec(brightness),
                ),
                const SizedBox(width: 6),
                Text(
                  amenity,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.text(brightness),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(Brightness brightness) {
    return GestureDetector(
      onTap: _isValid ? widget.onNext : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isValid
              ? const LinearGradient(
                  colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                )
              : null,
          color: _isValid ? null : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isValid ? Colors.transparent : AppColors.border(brightness),
          ),
          boxShadow: _isValid
              ? [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: TextStyle(
                color: _isValid ? Colors.white : AppColors.textSec(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              color: _isValid ? Colors.white : AppColors.textSec(brightness),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
