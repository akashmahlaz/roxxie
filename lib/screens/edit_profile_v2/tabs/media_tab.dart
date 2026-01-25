part of '../edit_profile_v2_screen.dart';

/// Media Tab
/// - Audio samples with waveform preview
/// - Video samples with thumbnails
/// - Photo gallery with drag-to-reorder
class _MediaTab extends StatefulWidget {
  final List<AudioSampleState> audioSamples;
  final List<VideoSampleState> videoSamples;
  final List<PhotoGalleryState> galleryPhotos;
  final Function(AudioSampleState) onAudioAdded;
  final Function(int) onAudioRemoved;
  final Function(int, int) onAudioReordered;
  final Function(VideoSampleState) onVideoAdded;
  final Function(int) onVideoRemoved;
  final Function(PhotoGalleryState) onPhotoAdded;
  final Function(int) onPhotoRemoved;
  final bool isArtist;

  const _MediaTab({
    required this.audioSamples,
    required this.videoSamples,
    required this.galleryPhotos,
    required this.onAudioAdded,
    required this.onAudioRemoved,
    required this.onAudioReordered,
    required this.onVideoAdded,
    required this.onVideoRemoved,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    required this.isArtist,
  });

  @override
  State<_MediaTab> createState() => _MediaTabState();
}

class _MediaTabState extends State<_MediaTab> {
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        
        final sample = AudioSampleState(
          id: id,
          title: file.name.replaceAll(RegExp(r'\.(mp3|wav|m4a|aac)$'), ''),
          isUploading: true,
        );
        
        widget.onAudioAdded(sample);
        
        // Upload to Cloudinary
        try {
          if (file.path != null) {
            final uploadResult = await _uploadService.uploadAudio(file.path!);
            sample.url = uploadResult.url;
            sample.isUploaded = true;
            sample.isUploading = false;
            setState(() {});
          }
        } catch (e) {
          sample.isUploading = false;
          _showError('Failed to upload audio: $e');
        }
      }
    } catch (e) {
      _showError('Error picking audio file: $e');
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );

      if (video != null) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        
        final sample = VideoSampleState(
          id: id,
          title: video.name.replaceAll(RegExp(r'\.(mp4|mov|avi)$'), ''),
          isUploading: true,
        );
        
        widget.onVideoAdded(sample);
        
        // Upload to Cloudinary
        try {
          final uploadResult = await _uploadService.uploadVideo(video.path);
          sample.url = uploadResult.url;
          // Thumbnail generated from video URL with Cloudinary transformation
          sample.thumbnailUrl = uploadResult.url.replaceAll('/video/upload/', '/video/upload/so_0,c_thumb,w_320,h_180/');
          sample.isUploaded = true;
          sample.isUploading = false;
          setState(() {});
        } catch (e) {
          sample.isUploading = false;
          _showError('Failed to upload video: $e');
        }
      }
    } catch (e) {
      _showError('Error picking video file: $e');
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      for (final image in images) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        
        final photo = PhotoGalleryState(
          id: id,
          localPath: image.path,
          isUploading: true,
        );
        
        widget.onPhotoAdded(photo);
        
        // Upload to Cloudinary
        try {
          final uploadResult = await _uploadService.uploadGalleryImage(image.path);
          photo.url = uploadResult.url;
          photo.isUploaded = true;
          photo.isUploading = false;
          setState(() {});
        } catch (e) {
          photo.isUploading = false;
          _showError('Failed to upload photo: $e');
        }
      }
    } catch (e) {
      _showError('Error picking photos: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.crimson,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Audio Samples Section
        _buildSectionHeader(
          context,
          'Audio Samples',
          Icons.audiotrack_rounded,
          subtitle: 'Upload up to 5 audio tracks (MP3, WAV, M4A)',
          count: '${widget.audioSamples.length}/5',
        ),
        const SizedBox(height: 12),
        
        if (widget.audioSamples.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.music_note_rounded,
            title: 'No audio samples yet',
            subtitle: 'Upload your best tracks to showcase your sound',
            onAdd: widget.audioSamples.length < 5 ? _pickAudioFile : null,
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.audioSamples.length,
            onReorder: widget.onAudioReordered,
            itemBuilder: (context, index) {
              final sample = widget.audioSamples[index];
              return _AudioSampleItem(
                key: ValueKey(sample.id),
                sample: sample,
                index: index,
                onRemove: () => widget.onAudioRemoved(index),
              );
            },
          ),
        
        if (widget.audioSamples.isNotEmpty && widget.audioSamples.length < 5) ...[
          const SizedBox(height: 12),
          _buildAddButton(
            context,
            label: 'Add Audio',
            icon: Icons.add_rounded,
            onTap: _pickAudioFile,
          ),
        ],

        const SizedBox(height: 32),

        // Video Samples Section
        _buildSectionHeader(
          context,
          'Video Samples',
          Icons.videocam_rounded,
          subtitle: 'Upload up to 3 performance videos (max 3 min each)',
          count: '${widget.videoSamples.length}/3',
        ),
        const SizedBox(height: 12),
        
        if (widget.videoSamples.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.video_library_rounded,
            title: 'No video samples yet',
            subtitle: 'Show venues what you look like on stage',
            onAdd: widget.videoSamples.length < 3 ? _pickVideoFile : null,
          )
        else
          Column(
            children: widget.videoSamples.asMap().entries.map((entry) {
              return _VideoSampleItem(
                sample: entry.value,
                index: entry.key,
                onRemove: () => widget.onVideoRemoved(entry.key),
              );
            }).toList(),
          ),
        
        if (widget.videoSamples.isNotEmpty && widget.videoSamples.length < 3) ...[
          const SizedBox(height: 12),
          _buildAddButton(
            context,
            label: 'Add Video',
            icon: Icons.videocam_rounded,
            onTap: _pickVideoFile,
          ),
        ],

        const SizedBox(height: 32),

        // Photo Gallery Section
        _buildSectionHeader(
          context,
          'Photo Gallery',
          Icons.photo_library_rounded,
          subtitle: 'Upload up to 10 high-quality photos',
          count: '${widget.galleryPhotos.length}/10',
        ),
        const SizedBox(height: 12),
        
        if (widget.galleryPhotos.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.image_rounded,
            title: 'No photos yet',
            subtitle: 'Add photos of performances, promo shots, etc.',
            onAdd: widget.galleryPhotos.length < 10 ? _pickPhotos : null,
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.galleryPhotos.length + (widget.galleryPhotos.length < 10 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == widget.galleryPhotos.length) {
                return _buildAddPhotoTile(context);
              }
              final photo = widget.galleryPhotos[index];
              return _PhotoGalleryItem(
                photo: photo,
                index: index,
                onRemove: () => widget.onPhotoRemoved(index),
              );
            },
          ),

        const SizedBox(height: 32),

        // Tips Section
        _buildTipsCard(context),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    String? subtitle,
    String? count,
  }) {
    final brightness = Theme.of(context).brightness;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onAdd,
  }) {
    final brightness = Theme.of(context).brightness;
    
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider(brightness),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.cyan, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
            if (onAdd != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cyan, AppColors.rose],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Add Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.cyan, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoTile(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return InkWell(
      onTap: _pickPhotos,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              color: AppColors.cyan,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.05),
            AppColors.rose.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Media Tips',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(context, '🎵', 'Audio: Use high-quality recordings (320kbps MP3 or WAV)'),
          _buildTipItem(context, '🎬', 'Video: Good lighting and clear audio make a difference'),
          _buildTipItem(context, '📸', 'Photos: Professional shots get 3x more profile views'),
          _buildTipItem(context, '⭐', 'First items appear on your discovery card'),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String emoji, String text) {
    final brightness = Theme.of(context).brightness;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
