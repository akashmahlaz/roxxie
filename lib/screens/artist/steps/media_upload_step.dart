import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/upload_service.dart';
import '../../../core/models/artist_models.dart';

/// Step 2: Media Upload
/// - Profile Photo (required)
/// - Additional Photos (gallery)
/// - Audio Samples
/// - Video Samples

class MediaUploadStep extends StatefulWidget {
  final ArtistProfileData profileData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const MediaUploadStep({
    super.key,
    required this.profileData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<MediaUploadStep> createState() => _MediaUploadStepState();
}

class _MediaUploadStepState extends State<MediaUploadStep> {
  final ImagePicker _picker = ImagePicker();
  final UploadService _uploadService = UploadService();

  Future<void> _pickProfilePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null) {
      setState(() {
        widget.profileData.profilePhoto = image.path;
      });
    }
  }

  Future<void> _pickAdditionalPhotos() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (images.isNotEmpty) {
      setState(() {
        // Limit to 6 additional photos
        final remaining = 6 - widget.profileData.photoGallery.length;
        final toAdd = images.take(remaining).map((e) => e.path).toList();
        widget.profileData.photoGallery.addAll(toAdd);
      });

      if (images.length >
          6 - widget.profileData.photoGallery.length + images.length) {
        _showSnackBar('Maximum 6 photos allowed');
      }
    }
  }

  Future<void> _addAudioSample() async {
    // Use file_picker for audio files
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path == null) return;

      // Check file size (max 10MB)
      if (await _uploadService.isFileTooLarge(file.path!)) {
        _showSnackBar('Audio file too large (max 10MB)');
        return;
      }

      // Get title from user
      if (!mounted) return;
      final title = await showDialog<String>(
        context: context,
        builder: (context) => _AudioTitleDialog(fileName: file.name),
      );

      if (title != null && title.isNotEmpty) {
        setState(() {
          widget.profileData.audioSamples.add({
            'title': title,
            'url': file.path!,
            'durationSeconds': null,
            'cloudinaryPublicId': null,
          });
        });
      }
    }
  }

  Future<void> _addVideoSample() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (video != null) {
      // Show dialog to name the video
      if (!mounted) return;
      final title = await showDialog<String>(
        context: context,
        builder: (context) => _VideoTitleDialog(),
      );

      if (title != null && title.isNotEmpty) {
        setState(() {
          widget.profileData.videoSamples.add({
            'title': title,
            'url': video.path,
            'durationSeconds': null,
            'thumbnailUrl': null,
          });
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      widget.profileData.photoGallery.removeAt(index);
    });
  }

  void _removeAudioSample(int index) {
    setState(() {
      widget.profileData.audioSamples.removeAt(index);
    });
  }

  void _removeVideoSample(int index) {
    setState(() {
      widget.profileData.videoSamples.removeAt(index);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _validateAndContinue() {
    if (widget.profileData.profilePhoto == null) {
      _showSnackBar('Please add a profile photo');
      return;
    }
    widget.onNext();
  }

  // ignore: unused_element
  void _skipStep() {
    // Show confirmation if no photos added
    if (widget.profileData.profilePhoto == null) {
      _showSkipConfirmation();
    } else {
      widget.onNext();
    }
  }

  void _showSkipConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Photos?'),
        content: const Text(
          'Adding photos increases your chances of getting gigs by 5x. '
          'Are you sure you want to skip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add Photos'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onNext();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo Section
          _buildSectionTitle('Profile Photo *', brightness),
          const SizedBox(height: 4),
          Text(
            'This is the main photo venues will see',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _buildProfilePhotoUpload(brightness),

          const SizedBox(height: 28),

          // Gallery Section
          _buildSectionTitle(
            'Photo Gallery',
            brightness,
            subtitle: '${widget.profileData.photoGallery.length}/6 photos',
          ),
          const SizedBox(height: 12),
          _buildPhotoGallery(brightness),

          const SizedBox(height: 28),

          // Audio Samples Section
          _buildSectionTitle(
            'Audio Samples',
            brightness,
            subtitle: 'Let venues hear your sound',
          ),
          const SizedBox(height: 12),
          _buildAudioSamples(brightness),

          const SizedBox(height: 28),

          // Video Samples Section
          _buildSectionTitle(
            'Performance Videos',
            brightness,
            subtitle: 'Show your stage presence',
          ),
          const SizedBox(height: 12),
          _buildVideoSamples(brightness),

          const SizedBox(height: 32),

          // Navigation Buttons
          _buildNavigationButtons(brightness),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    Brightness brightness, {
    String? subtitle,
  }) {
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

  Widget _buildProfilePhotoUpload(Brightness brightness) {
    final hasPhoto = widget.profileData.profilePhoto != null;

    return GestureDetector(
      onTap: _pickProfilePhoto,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasPhoto ? AppColors.crimson : AppColors.border(brightness),
            width: hasPhoto ? 3 : 1,
          ),
          boxShadow: hasPhoto
              ? [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: hasPhoto
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.file(
                      File(widget.profileData.profilePhoto!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.crimson.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.crimson,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPhotoGallery(Brightness brightness) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.profileData.photoGallery.length + 1,
        itemBuilder: (context, index) {
          if (index == widget.profileData.photoGallery.length) {
            // Add button
            return GestureDetector(
              onTap: widget.profileData.photoGallery.length < 6
                  ? _pickAdditionalPhotos
                  : null,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      color: AppColors.textSec(brightness),
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Photo item
          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.file(
                    File(widget.profileData.photoGallery[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 16,
                child: GestureDetector(
                  onTap: () => _removePhoto(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
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
          );
        },
      ),
    );
  }

  Widget _buildAudioSamples(Brightness brightness) {
    return Column(
      children: [
        // Existing samples
        ...widget.profileData.audioSamples.asMap().entries.map((entry) {
          final index = entry.key;
          final sample = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: AppColors.crimson,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sample["title"],
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sample["durationSeconds"] != null)
                        Text(
                          _formatDuration(sample["durationSeconds"]!),
                          style: TextStyle(
                            color: AppColors.textTert(brightness),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeAudioSample(index),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.textTert(brightness),
                  ),
                ),
              ],
            ),
          );
        }),

        // Add button
        GestureDetector(
          onTap: _addAudioSample,
          child: Container(
            padding: const EdgeInsets.all(16),
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
                Icon(Icons.add_rounded, color: AppColors.crimson, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Audio Sample',
                  style: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSamples(Brightness brightness) {
    return Column(
      children: [
        // Existing videos
        ...widget.profileData.videoSamples.asMap().entries.map((entry) {
          final index = entry.key;
          final video = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_circle_filled_rounded,
                    color: AppColors.crimson,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    video["title"],
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeVideoSample(index),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.textTert(brightness),
                  ),
                ),
              ],
            ),
          );
        }),

        // Add button
        GestureDetector(
          onTap: _addVideoSample,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  color: AppColors.crimson,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Video',
                  style: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(Brightness brightness) {
    return Row(
      children: [
        // Back button
        Expanded(
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Center(
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Continue button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _validateAndContinue,
            child: Container(
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Dialog for audio title (after file is picked)
class _AudioTitleDialog extends StatefulWidget {
  final String fileName;

  const _AudioTitleDialog({required this.fileName});

  @override
  State<_AudioTitleDialog> createState() => _AudioTitleDialogState();
}

class _AudioTitleDialogState extends State<_AudioTitleDialog> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    // Pre-fill with filename (without extension)
    final nameWithoutExt = widget.fileName.contains('.')
        ? widget.fileName.substring(0, widget.fileName.lastIndexOf('.'))
        : widget.fileName;
    _titleController = TextEditingController(text: nameWithoutExt);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return AlertDialog(
      backgroundColor: AppColors.cardBackground(brightness),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Name Your Audio',
        style: TextStyle(color: AppColors.text(brightness)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Give your audio sample a title that venues will see.',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            style: TextStyle(color: AppColors.text(brightness)),
            decoration: InputDecoration(
              hintText: 'e.g., "Live Jazz Set"',
              hintStyle: TextStyle(color: AppColors.textTert(brightness)),
              filled: true,
              fillColor: AppColors.inputFill(brightness),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border(brightness)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border(brightness)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.crimson),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSec(brightness)),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              Navigator.pop(context, _titleController.text.trim());
            }
          },
          child: Text('Add', style: TextStyle(color: AppColors.crimson)),
        ),
      ],
    );
  }
}

// Dialog for video title
class _VideoTitleDialog extends StatefulWidget {
  @override
  State<_VideoTitleDialog> createState() => _VideoTitleDialogState();
}

class _VideoTitleDialogState extends State<_VideoTitleDialog> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return AlertDialog(
      backgroundColor: AppColors.cardBackground(brightness),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Video Title',
        style: TextStyle(color: AppColors.text(brightness)),
      ),
      content: TextField(
        controller: _titleController,
        autofocus: true,
        style: TextStyle(color: AppColors.text(brightness)),
        decoration: InputDecoration(
          hintText: 'e.g., "Live at Blue Note"',
          hintStyle: TextStyle(color: AppColors.textTert(brightness)),
          filled: true,
          fillColor: AppColors.inputFill(brightness),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border(brightness)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border(brightness)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.crimson),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSec(brightness)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _titleController.text.trim()),
          child: Text('Save', style: TextStyle(color: AppColors.crimson)),
        ),
      ],
    );
  }
}
