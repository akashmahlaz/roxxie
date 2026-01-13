import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/venue_models.dart';
import '../../../core/theme/theme.dart';

/// 📸 STEP 2: VENUE MEDIA
///
/// Collects:
/// - Cover photo
/// - Venue photos (gallery)
/// - Past event photos

class VenueMediaStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const VenueMediaStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<VenueMediaStep> createState() => _VenueMediaStepState();
}

class _VenueMediaStepState extends State<VenueMediaStep> {
  final ImagePicker _picker = ImagePicker();

  void _showSnack(String message, {bool isError = false}) {
    final brightness = Theme.of(context).brightness;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.crimson : AppColors.surface(brightness),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Helper to get correct ImageProvider based on path type
  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  Future<void> _pickCoverPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        widget.profileData.coverPhoto = image.path;
      });
      widget.onDataChanged();
    }
  }

  Future<void> _pickVenuePhotos() async {
    final current = List<String>.from(widget.profileData.venuePhotos);
    final remaining = 8 - current.length;
    if (remaining <= 0) {
      _showSnack('You can add up to 8 venue photos.', isError: true);
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (!mounted || images.isEmpty) return;

    final toAdd = images.take(remaining).map((img) => img.path).toList();
    setState(() {
      widget.profileData.venuePhotos = [...current, ...toAdd];
    });
    widget.onDataChanged();

    if (images.length > remaining) {
      _showSnack('Only $remaining photo(s) were added (limit 8).');
    }
  }

  Future<void> _pickEventPhotos() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (images.isNotEmpty) {
      setState(() {
        // Limit to 10 photos
        final remaining = 10 - widget.profileData.pastEventPhotos.length;
        widget.profileData.pastEventPhotos.addAll(
          images.take(remaining).map((img) => img.path),
        );
      });
      widget.onDataChanged();
    }
  }

  void _removeVenuePhoto(int index) {
    final current = List<String>.from(widget.profileData.venuePhotos);
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    setState(() {
      widget.profileData.venuePhotos = current;
    });
    widget.onDataChanged();
  }

  void _removeEventPhoto(int index) {
    setState(() {
      widget.profileData.pastEventPhotos.removeAt(index);
    });
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Photo Section
          _buildSectionTitle(
            'Cover Photo',
            'This is the first thing artists see',
            brightness,
          ),
          const SizedBox(height: 14),
          _buildCoverPhotoSection(brightness),

          const SizedBox(height: 32),

          // Venue Photos
          _buildSectionTitle(
            'Venue Photos',
            'Show off your space (up to 8)',
            brightness,
          ),
          const SizedBox(height: 14),
          _buildVenuePhotosSection(brightness),

          const SizedBox(height: 32),

          // Past Events Photos
          _buildSectionTitle(
            'Past Events',
            'Show artists what performing at your venue looks like (up to 10)',
            brightness,
          ),
          const SizedBox(height: 14),
          _buildEventPhotosSection(brightness),

          const SizedBox(height: 40),

          // Navigation Buttons
          _buildNavigationButtons(brightness),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    String subtitle,
    Brightness brightness,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCoverPhotoSection(Brightness brightness) {
    return GestureDetector(
      onTap: _pickCoverPhoto,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.profileData.coverPhoto != null
                ? AppColors.crimson
                : AppColors.border(brightness),
            width: widget.profileData.coverPhoto != null ? 2 : 1,
          ),
          image: widget.profileData.coverPhoto != null
              ? DecorationImage(
                  image: _getImageProvider(widget.profileData.coverPhoto!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: widget.profileData.coverPhoto == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.crimson.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: AppColors.crimson,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add Cover Photo',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended: 1920x1080',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.profileData.coverPhoto = null;
                        });
                        widget.onDataChanged();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _pickCoverPhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVenuePhotosSection(Brightness brightness) {
    return Column(
      children: [
        // Photo Grid
        if (widget.profileData.venuePhotos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: widget.profileData.venuePhotos.length,
            itemBuilder: (context, index) {
              return _buildPhotoItem(
                widget.profileData.venuePhotos[index],
                () => _removeVenuePhoto(index),
                brightness,
              );
            },
          ),
          const SizedBox(height: 14),
        ],

        // Add Button
        if (widget.profileData.venuePhotos.length < 8)
          _buildAddPhotoButton(
            'Add Venue Photos',
            '${widget.profileData.venuePhotos.length} of 8 added',
            Icons.business_rounded,
            _pickVenuePhotos,
            brightness,
          ),
      ],
    );
  }

  Widget _buildEventPhotosSection(Brightness brightness) {
    return Column(
      children: [
        // Photo Grid
        if (widget.profileData.pastEventPhotos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: widget.profileData.pastEventPhotos.length,
            itemBuilder: (context, index) {
              return _buildPhotoItem(
                widget.profileData.pastEventPhotos[index],
                () => _removeEventPhoto(index),
                brightness,
              );
            },
          ),
          const SizedBox(height: 14),
        ],

        // Add Button
        if (widget.profileData.pastEventPhotos.length < 10)
          _buildAddPhotoButton(
            'Add Event Photos',
            '${widget.profileData.pastEventPhotos.length} of 10 added',
            Icons.celebration_rounded,
            _pickEventPhotos,
            brightness,
          ),
      ],
    );
  }

  Widget _buildPhotoItem(
    String imagePath,
    VoidCallback onRemove,
    Brightness brightness,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Use proper image provider based on path type
            Image(
              image: _getImageProvider(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surface(brightness),
                child: const Icon(Icons.broken_image_rounded, color: AppColors.crimson),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    Brightness brightness,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border(brightness),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.crimson, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.crimson,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(Brightness brightness) {
    return Row(
      children: [
        // Back Button
        Expanded(
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.text(brightness),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Continue Button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: widget.onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
