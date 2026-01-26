/// 🖼️ MEDIA SCREEN - Edit Profile Sub-Screen
///
/// Role-aware media management:
/// - Profile photo upload
/// - Gallery images
/// - Audio samples (Artist only)
/// - Video samples (Artist only)
///
/// Uses Cloudinary for all media uploads
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final _uploadService = UploadService();
  final _artistService = ArtistService();
  final _venueService = VenueService();
  final _imagePicker = ImagePicker();

  // Current media state
  String? _profilePhotoUrl;
  List<String> _galleryUrls = [];
  List<AudioSample> _audioSamples = [];
  List<VideoSample> _videoSamples = [];

  // Upload state
  bool _isUploadingPhoto = false;
  bool _isUploadingGallery = false;
  bool _isUploadingAudio = false;
  bool _isUploadingVideo = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    if (auth.isArtist && profile.artist != null) {
      final artist = profile.artist!;
      _profilePhotoUrl = artist.profilePhoto;
      _galleryUrls = List.from(artist.galleryUrls);
      _audioSamples = List.from(artist.audioSamples);
      _videoSamples = List.from(artist.videoSamples);
    } else if (!auth.isArtist && profile.venue != null) {
      final venue = profile.venue!;
      _profilePhotoUrl = venue.profilePhotoUrl;
      _galleryUrls = List.from(venue.galleryUrls ?? []);
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final response = await _uploadService.uploadProfilePhoto(picked.path);

      setState(() {
        _profilePhotoUrl = response.url;
      });
      _markChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Profile photo uploaded!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _pickGalleryImages() async {
    if (_galleryUrls.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum 6 gallery images allowed'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked.isEmpty) return;

      final remaining = 6 - _galleryUrls.length;
      final toUpload = picked.take(remaining).toList();

      setState(() => _isUploadingGallery = true);

      for (final image in toUpload) {
        try {
          final response = await _uploadService.uploadGalleryImage(
            image.path,
            index: _galleryUrls.length,
          );
          setState(() {
            _galleryUrls.add(response.url);
          });
        } catch (e) {
          debugPrint('Failed to upload gallery image: $e');
        }
      }

      _markChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${toUpload.length} image(s) uploaded!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingGallery = false);
      }
    }
  }

  Future<void> _pickAudioFile() async {
    if (_audioSamples.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum 3 audio samples allowed'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      // Check file size (max 10MB)
      final fileSize = await _uploadService.getFileSizeMB(file.path!);
      if (fileSize > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Audio file must be less than 10MB'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      setState(() => _isUploadingAudio = true);

      final response = await _uploadService.uploadAudio(file.path!);

      setState(() {
        _audioSamples.add(AudioSample(
          url: response.url,
          title: file.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
          cloudinaryPublicId: response.publicId,
        ));
      });
      _markChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Audio sample uploaded!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAudio = false);
      }
    }
  }

  Future<void> _pickVideoFile() async {
    if (_videoSamples.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum 2 video samples allowed'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );

      if (picked == null) return;

      // Check file size (max 50MB)
      final fileSize = await _uploadService.getFileSizeMB(picked.path);
      if (fileSize > 50) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Video file must be less than 50MB'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      setState(() => _isUploadingVideo = true);

      final response = await _uploadService.uploadVideo(picked.path);

      setState(() {
        _videoSamples.add(VideoSample(
          url: response.url,
          title: 'Video ${_videoSamples.length + 1}',
          cloudinaryPublicId: response.publicId,
        ));
      });
      _markChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Video sample uploaded!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingVideo = false);
      }
    }
  }

  void _removeGalleryImage(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _galleryUrls.removeAt(index);
    });
    _markChanged();
  }

  void _removeAudioSample(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _audioSamples.removeAt(index);
    });
    _markChanged();
  }

  void _removeVideoSample(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _videoSamples.removeAt(index);
    });
    _markChanged();
  }

  Future<void> _saveChanges() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSaving = true);

    try {
      if (auth.isArtist) {
        await _artistService.updateMyProfile(
          UpdateArtistRequest(
            galleryUrls: _galleryUrls,
            audioSamples: _audioSamples,
            videoSamples: _videoSamples,
          ),
        );
      } else {
        // Venue doesn't have audio/video samples
        await _venueService.updateMyProfile(
          UpdateVenueRequest(),
        );
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Media updated successfully!'),
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();
    final isArtist = auth.isArtist;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
            _buildProfilePhotoSection(brightness),

            const SizedBox(height: 32),

            // Gallery Section
            _buildGallerySection(brightness),

            // Audio Samples (Artist only)
            if (isArtist) ...[
              const SizedBox(height: 32),
              _buildAudioSection(brightness),
            ],

            // Video Samples (Artist only)
            if (isArtist) ...[
              const SizedBox(height: 32),
              _buildVideoSection(brightness),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
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
        'Media',
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
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
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

  Widget _buildProfilePhotoSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your main profile picture',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isUploadingPhoto ? null : _pickProfilePhoto,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface(brightness),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.3),
                width: 2,
              ),
              image: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_profilePhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _isUploadingPhoto
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.crimson,
                    ),
                  )
                : _profilePhotoUrl == null || _profilePhotoUrl!.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            color: AppColors.crimson,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              color: AppColors.crimson,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.crimson,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gallery',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_galleryUrls.length}/6 photos',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_galleryUrls.length < 6)
              IconButton(
                onPressed: _isUploadingGallery ? null : _pickGalleryImages,
                icon: _isUploadingGallery
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.crimson,
                        ),
                      )
                    : Icon(
                        Icons.add_photo_alternate,
                        color: AppColors.crimson,
                        size: 26,
                      ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_galleryUrls.isEmpty)
          _buildEmptyState(
            brightness,
            Icons.photo_library_outlined,
            'No gallery photos',
            'Add photos to showcase your work',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _galleryUrls.length,
            itemBuilder: (context, index) {
              return _buildGalleryItem(_galleryUrls[index], index, brightness);
            },
          ),
      ],
    );
  }

  Widget _buildGalleryItem(String url, int index, Brightness brightness) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeGalleryImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Samples',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_audioSamples.length}/3 tracks (max 10MB each)',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_audioSamples.length < 3)
              IconButton(
                onPressed: _isUploadingAudio ? null : _pickAudioFile,
                icon: _isUploadingAudio
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.crimson,
                        ),
                      )
                    : Icon(
                        Icons.add_circle_outline,
                        color: AppColors.crimson,
                        size: 26,
                      ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_audioSamples.isEmpty)
          _buildEmptyState(
            brightness,
            Icons.audiotrack_outlined,
            'No audio samples',
            'Add audio to let venues hear your music',
          )
        else
          ...List.generate(_audioSamples.length, (index) {
            return _buildAudioItem(_audioSamples[index], index, brightness);
          }),
      ],
    );
  }

  Widget _buildAudioItem(AudioSample sample, int index, Brightness brightness) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(brightness),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.audiotrack,
              color: AppColors.crimson,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sample.title ?? 'Audio ${index + 1}',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _removeAudioSample(index),
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video Samples',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_videoSamples.length}/2 videos (max 50MB each)',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_videoSamples.length < 2)
              IconButton(
                onPressed: _isUploadingVideo ? null : _pickVideoFile,
                icon: _isUploadingVideo
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.crimson,
                        ),
                      )
                    : Icon(
                        Icons.video_call,
                        color: AppColors.crimson,
                        size: 26,
                      ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_videoSamples.isEmpty)
          _buildEmptyState(
            brightness,
            Icons.videocam_outlined,
            'No video samples',
            'Add videos to show your live performances',
          )
        else
          ...List.generate(_videoSamples.length, (index) {
            return _buildVideoItem(_videoSamples[index], index, brightness);
          }),
      ],
    );
  }

  Widget _buildVideoItem(VideoSample sample, int index, Brightness brightness) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(brightness),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.graphite,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
              image: sample.thumbnailUrl != null
                  ? DecorationImage(
                      image: NetworkImage(sample.thumbnailUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: sample.thumbnailUrl == null
                ? Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: AppColors.crimson,
                      size: 48,
                    ),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sample.title ?? 'Video ${index + 1}',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeVideoSample(index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    Brightness brightness,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(brightness),
          width: 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.textSec(brightness),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
