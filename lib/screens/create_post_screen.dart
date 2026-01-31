/// 📝 GIGMATCH Create Post Screen
///
/// Instagram-style post creation with:
/// - Image/video picker (up to 10 media)
/// - Caption with hashtag detection
/// - Location tagging
/// - Mentions support
/// - M3 design components
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/providers/providers.dart';
import '../core/services/upload_service.dart';
import '../core/theme/theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();

  final List<XFile> _selectedMedia = [];
  bool _isUploading = false;
  bool _isPosting = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  // Settings
  bool _commentsDisabled = false;
  bool _likesHidden = false;

  static const int _maxMedia = 10;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedMedia.length >= _maxMedia) {
      _showSnackBar('Maximum $_maxMedia media items allowed');
      return;
    }

    try {
      final remaining = _maxMedia - _selectedMedia.length;
      final images = await _imagePicker.pickMultiImage(
        limit: remaining,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedMedia.addAll(images);
        });
      }
    } catch (e) {
      debugPrint('Pick images error: $e');
      _showSnackBar('Failed to pick images');
    }
  }

  Future<void> _pickVideo() async {
    if (_selectedMedia.length >= _maxMedia) {
      _showSnackBar('Maximum $_maxMedia media items allowed');
      return;
    }

    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        setState(() {
          _selectedMedia.add(video);
        });
      }
    } catch (e) {
      debugPrint('Pick video error: $e');
      _showSnackBar('Failed to pick video');
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedMedia.length >= _maxMedia) {
      _showSnackBar('Maximum $_maxMedia media items allowed');
      return;
    }

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedMedia.add(photo);
        });
      }
    } catch (e) {
      debugPrint('Take photo error: $e');
      _showSnackBar('Failed to take photo');
    }
  }

  void _removeMedia(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  Future<void> _uploadAndPost() async {
    if (_selectedMedia.isEmpty) {
      _showSnackBar('Please add at least one photo or video');
      return;
    }

    // Cache navigator before async
    final nav = Navigator.of(context);
    final feedProvider = context.read<FeedProvider>();

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      // Upload all media
      final mediaList = <Map<String, dynamic>>[];
      for (var i = 0; i < _selectedMedia.length; i++) {
        final file = _selectedMedia[i];
        final isVideo = _isVideoFile(file.path);

        setState(() {
          _uploadProgress = i / _selectedMedia.length;
        });

        final response = isVideo
            ? await _uploadService.uploadVideo(file.path)
            : await _uploadService.uploadGalleryImage(file.path, index: i);

        mediaList.add({
          'type': isVideo ? 'video' : 'image',
          'url': response.url,
          'publicId': response.publicId,
          'width': response.width,
          'height': response.height,
          'order': i,
        });
      }

      setState(() {
        _isUploading = false;
        _isPosting = true;
      });

      // Extract hashtags from caption
      final hashtags = _extractHashtags(_captionController.text);

      // Create post
      await feedProvider.createPost(
        caption: _captionController.text.isNotEmpty
            ? _captionController.text
            : null,
        media: mediaList,
        hashtags: hashtags.isNotEmpty ? hashtags : null,
        commentsDisabled: _commentsDisabled,
        likesHidden: _likesHidden,
      );

      // Success - go back
      HapticFeedback.mediumImpact();
      nav.pop(true);
    } catch (e) {
      debugPrint('Create post error: $e');
      setState(() {
        _isUploading = false;
        _isPosting = false;
        _errorMessage = 'Failed to create post. Please try again.';
      });
      _showSnackBar(_errorMessage!);
    }
  }

  bool _isVideoFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'webm', 'mkv', '3gp'].contains(ext);
  }

  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#(\w+)');
    return regex
        .allMatches(text)
        .map((m) => m.group(1)!.toLowerCase())
        .toSet()
        .toList();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final canPost = _selectedMedia.isNotEmpty && !_isUploading && !_isPosting;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.background(brightness),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.text(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Post',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // M3 FilledButton for posting
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: canPost ? _uploadAndPost : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                disabledBackgroundColor: AppColors.crimson.withValues(
                  alpha: 0.3,
                ),
              ),
              child: _isUploading || _isPosting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Share'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Upload progress
            if (_isUploading)
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.surface(brightness),
                color: AppColors.crimson,
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media grid
                    _buildMediaGrid(brightness),

                    const SizedBox(height: 24),

                    // Add media buttons
                    _buildMediaButtons(brightness),

                    const SizedBox(height: 24),

                    // Caption field
                    _buildCaptionField(brightness),

                    const SizedBox(height: 24),

                    // Settings
                    _buildSettings(brightness),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(Brightness brightness) {
    if (_selectedMedia.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border(brightness),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 64,
                color: AppColors.textSec(brightness),
              ),
              const SizedBox(height: 16),
              Text(
                'Add photos or videos',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Up to $_maxMedia items',
                style: TextStyle(
                  color: AppColors.textSec(brightness).withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedMedia.length,
      itemBuilder: (context, index) {
        final file = _selectedMedia[index];
        final isVideo = _isVideoFile(file.path);

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isVideo
                  ? Container(
                      color: AppColors.surface(brightness),
                      child: Center(
                        child: Icon(
                          Icons.videocam_rounded,
                          color: AppColors.crimson,
                          size: 32,
                        ),
                      ),
                    )
                  : Image.file(File(file.path), fit: BoxFit.cover),
            ),
            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeMedia(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            // Video indicator
            if (isVideo)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            // Order indicator
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaButtons(Brightness brightness) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.crimson,
              side: BorderSide(color: AppColors.crimson),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Camera'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.crimson,
              side: BorderSide(color: AppColors.crimson),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.videocam_rounded),
            label: const Text('Video'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.crimson,
              side: BorderSide(color: AppColors.crimson),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionField(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          maxLines: 5,
          maxLength: 2200,
          decoration: InputDecoration(
            hintText: 'Write a caption... #hashtags @mentions',
            hintStyle: TextStyle(color: AppColors.textSec(brightness)),
            filled: true,
            fillColor: AppColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: TextStyle(color: AppColors.text(brightness)),
        ),
      ],
    );
  }

  Widget _buildSettings(Brightness brightness) {
    return Card(
      color: AppColors.surface(brightness),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Disable comments - M3 SwitchListTile
          SwitchListTile(
            title: Text(
              'Turn off comments',
              style: TextStyle(color: AppColors.text(brightness)),
            ),
            subtitle: Text(
              'People can\'t comment on this post',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
              ),
            ),
            value: _commentsDisabled,
            onChanged: (value) => setState(() => _commentsDisabled = value),
            activeTrackColor: AppColors.crimson,
          ),
          Divider(height: 1, color: AppColors.border(brightness)),
          // Hide likes - M3 SwitchListTile
          SwitchListTile(
            title: Text(
              'Hide like count',
              style: TextStyle(color: AppColors.text(brightness)),
            ),
            subtitle: Text(
              'Only you can see how many likes this post gets',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
              ),
            ),
            value: _likesHidden,
            onChanged: (value) => setState(() => _likesHidden = value),
            activeTrackColor: AppColors.crimson,
          ),
        ],
      ),
    );
  }
}
