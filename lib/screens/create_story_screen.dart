/// 📸 GIGMATCH Create Story Screen
///
/// Instagram-style story creation with:
/// - Full-screen camera/gallery picker
/// - Story item preview with caption overlay
/// - Stickers and text overlays
/// - M3 design components
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/providers/providers.dart';
import '../core/services/upload_service.dart';
import '../core/theme/theme.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _captionController = TextEditingController();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();

  XFile? _selectedMedia;
  bool _isVideo = false;
  bool _isUploading = false;
  bool _isPosting = false;
  bool _showCaptionInput = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final hasPermission = await _ensureGalleryPermission();
      if (!hasPermission) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Allow photo/video access to continue.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      if (!mounted) {
        return;
      }

      // Show bottom sheet to choose image or video
      final type = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildMediaTypeSheet(),
      );

      if (type == null) {
        return;
      }

      if (type == 'image') {
        final image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
        );
        if (image != null) {
          setState(() {
            _selectedMedia = image;
            _isVideo = false;
          });
        }
      } else {
        final video = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 30),
        );
        if (video != null) {
          setState(() {
            _selectedMedia = video;
            _isVideo = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Pick from gallery error: $e');
      _showSnackBar('Failed to pick media');
    }
  }

  Future<void> _takePhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final hasPermission = await _ensureCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Allow camera access to take a photo.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (photo != null) {
        setState(() {
          _selectedMedia = photo;
          _isVideo = false;
        });
      }
    } catch (e) {
      debugPrint('Take photo error: $e');
      _showSnackBar('Failed to take photo');
    }
  }

  Future<void> _recordVideo() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final hasPermission = await _ensureCameraPermission(
        needsMicrophone: true,
      );
      if (!hasPermission) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Allow camera/microphone access to record.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        setState(() {
          _selectedMedia = video;
          _isVideo = true;
        });
      }
    } catch (e) {
      debugPrint('Record video error: $e');
      _showSnackBar('Failed to record video');
    }
  }

  void _clearMedia() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMedia = null;
      _isVideo = false;
      _captionController.clear();
      _showCaptionInput = false;
    });
  }

  Future<void> _uploadAndPost() async {
    if (_selectedMedia == null) {
      _showSnackBar('Please select a photo or video');
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
      // Upload media
      final response = _isVideo
          ? await _uploadService.uploadVideo(_selectedMedia!.path)
          : await _uploadService.uploadGalleryImage(_selectedMedia!.path);

      setState(() {
        _uploadProgress = 1.0;
        _isUploading = false;
        _isPosting = true;
      });

      // Create story item
      final storyItem = {
        'type': _isVideo ? 'video' : 'image',
        'url': response.url,
        'caption': _captionController.text.isNotEmpty
            ? _captionController.text
            : null,
        'duration': _isVideo ? 15 : 5, // 5 seconds for images, 15 for videos
      };

      // Create story
      await feedProvider.createStory(items: [storyItem]);

      // Success - go back
      HapticFeedback.mediumImpact();
      nav.pop(true);
    } catch (e) {
      debugPrint('Create story error: $e');
      setState(() {
        _isUploading = false;
        _isPosting = false;
        _errorMessage = 'Failed to create story. Please try again.';
      });
      _showSnackBar(_errorMessage!);
    }
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

  Future<bool> _ensureGalleryPermission() async {
    final statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.storage,
    ].request();

    final granted = statuses.values.any(
      (status) => status.isGranted || status.isLimited,
    );
    return granted;
  }

  Future<bool> _ensureCameraPermission({bool needsMicrophone = false}) async {
    final permissions = <Permission>[Permission.camera];
    if (needsMicrophone) {
      permissions.add(Permission.microphone);
    }
    final statuses = await permissions.request();
    final granted = statuses.values.every((status) => status.isGranted);
    return granted;
  }

  Widget _buildMediaTypeSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(Theme.of(context).brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_rounded, color: AppColors.crimson),
              ),
              title: const Text('Photo'),
              subtitle: const Text('Select an image from gallery'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.videocam_rounded, color: AppColors.crimson),
              ),
              title: const Text('Video'),
              subtitle: const Text('Select a video (max 30 seconds)'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _selectedMedia == null
            ? _buildMediaPicker(brightness)
            : _buildPreview(brightness),
      ),
    );
  }

  Widget _buildMediaPicker(Brightness brightness) {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Add to Story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 48), // Balance
            ],
          ),
        ),

        // Main content area
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    size: 80,
                    color: AppColors.crimson,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Create Your Story',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Share moments that disappear after 24 hours',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom action buttons
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Gallery button
              Expanded(
                child: FilledButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Gallery'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surface(Brightness.dark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Camera button
              Expanded(
                child: FilledButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Photo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Video button
              Expanded(
                child: FilledButton.icon(
                  onPressed: _recordVideo,
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Video'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surface(Brightness.dark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(Brightness brightness) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media preview
        if (_isVideo)
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_rounded, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Video Preview',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Image.file(File(_selectedMedia!.path), fit: BoxFit.cover),

        // Overlay gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.2, 0.7, 1.0],
            ),
          ),
        ),

        // Top bar
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: _clearMedia,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                ),
              ),
              Row(
                children: [
                  // Add text button
                  IconButton(
                    icon: const Icon(
                      Icons.text_fields_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() => _showCaptionInput = true),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stickers button (placeholder)
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _showSnackBar('Stickers coming soon!');
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Caption overlay
        if (_showCaptionInput || _captionController.text.isNotEmpty)
          Positioned(
            left: 24,
            right: 24,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _captionController,
                autofocus: _showCaptionInput,
                maxLines: 3,
                maxLength: 250,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  counterStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                onSubmitted: (_) => setState(() => _showCaptionInput = false),
              ),
            ),
          ),

        // Bottom share button
        Positioned(
          bottom: 32,
          left: 24,
          right: 24,
          child: Column(
            children: [
              // Progress indicator
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        color: AppColors.crimson,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

              // Share button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_isUploading || _isPosting)
                      ? null
                      : _uploadAndPost,
                  icon: _isUploading || _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isPosting ? 'Sharing...' : 'Share to Story'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    disabledBackgroundColor: AppColors.crimson.withValues(
                      alpha: 0.5,
                    ),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
