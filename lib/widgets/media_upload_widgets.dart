import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/theme.dart';
import '../core/services/upload_service.dart';
import '../core/models/models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// 📸 GALLERY UPLOAD GRID
// ═════════════════════════════════════════════════════════════════════════════

class GalleryUploadGrid extends StatefulWidget {
  final List<String> imageUrls;
  final Function(List<String>) onChanged;
  final Brightness brightness;

  const GalleryUploadGrid({
    super.key,
    required this.imageUrls,
    required this.onChanged,
    required this.brightness,
  });

  @override
  State<GalleryUploadGrid> createState() => _GalleryUploadGridState();
}

class _GalleryUploadGridState extends State<GalleryUploadGrid> {
  final _uploadService = UploadService();
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Upload image
      final response = await _uploadService.uploadGalleryImage(image.path);

      final newUrls = List<String>.from(widget.imageUrls)..add(response.url);
      widget.onChanged(newUrls);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) {
    final newUrls = List<String>.from(widget.imageUrls)..removeAt(index);
    widget.onChanged(newUrls);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: widget.imageUrls.length + 1,
      itemBuilder: (context, index) {
        // Add Button
        if (index == widget.imageUrls.length) {
          return GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface(widget.brightness),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textSec(widget.brightness).withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: AppColors.crimson,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: AppColors.textSec(widget.brightness),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }

        // Image Item
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface(widget.brightness),
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 🎵 AUDIO UPLOAD LIST
// ═════════════════════════════════════════════════════════════════════════════

class AudioUploadList extends StatefulWidget {
  final List<AudioSample> samples;
  final Function(List<AudioSample>) onChanged;
  final Brightness brightness;

  const AudioUploadList({
    super.key,
    required this.samples,
    required this.onChanged,
    required this.brightness,
  });

  @override
  State<AudioUploadList> createState() => _AudioUploadListState();
}

class _AudioUploadListState extends State<AudioUploadList> {
  final _uploadService = UploadService();
  bool _isUploading = false;

  Future<void> _pickAndUploadAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploading = true);

      final filePath = result.files.single.path!;
      UploadResponse response;

      // Try direct upload first if signed params endpoint exists (assumed true if method exists)
      // Otherwise fallback to backend proxy
      try {
        // We'll try standard upload first as it's safer without confirmed backend support for signed params
        response = await _uploadService.uploadAudio(filePath);
      } catch (e) {
        // Fallback or retry logic could go here
        rethrow;
      }

      // Ask for title
      if (!mounted) return;
      final titleController = TextEditingController(text: result.files.single.name);

      final String? title = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface(widget.brightness),
          title: Text('Track Title', style: TextStyle(color: AppColors.text(widget.brightness))),
          content: TextField(
            controller: titleController,
            style: TextStyle(color: AppColors.text(widget.brightness)),
            decoration: InputDecoration(
              hintText: 'Enter track title',
              hintStyle: TextStyle(color: AppColors.textSec(widget.brightness)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, titleController.text),
              child: const Text('Save', style: TextStyle(color: AppColors.crimson)),
            ),
          ],
        ),
      );

      if (title != null) {
        final newSample = AudioSample(
          url: response.url,
          title: title,
          cloudinaryPublicId: response.publicId,
          // Duration could be extracted if needed, but not critical
        );

        final newSamples = List<AudioSample>.from(widget.samples)..add(newSample);
        widget.onChanged(newSamples);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeSample(int index) {
    final newSamples = List<AudioSample>.from(widget.samples)..removeAt(index);
    widget.onChanged(newSamples);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.samples.asMap().entries.map((entry) {
          final index = entry.key;
          final sample = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface(widget.brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(widget.brightness)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.music_note_rounded, color: AppColors.crimson),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sample.title ?? 'Untitled Track',
                        style: TextStyle(
                          color: AppColors.text(widget.brightness),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Audio Sample',
                        style: TextStyle(
                          color: AppColors.textSec(widget.brightness),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.textSec(widget.brightness),
                  onPressed: () => _removeSample(index),
                ),
              ],
            ),
          );
        }),

        // Add Button
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadAudio,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.textSec(widget.brightness).withValues(alpha: 0.3),
                style: BorderStyle.none,
              ),
              color: AppColors.surface(widget.brightness).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, color: AppColors.crimson),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Audio',
                          style: TextStyle(
                            color: AppColors.text(widget.brightness),
                            fontWeight: FontWeight.w600,
                          ),
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

// ═════════════════════════════════════════════════════════════════════════════
// 🎬 VIDEO UPLOAD LIST
// ═════════════════════════════════════════════════════════════════════════════

class VideoUploadList extends StatefulWidget {
  final List<VideoSample> samples;
  final Function(List<VideoSample>) onChanged;
  final Brightness brightness;

  const VideoUploadList({
    super.key,
    required this.samples,
    required this.onChanged,
    required this.brightness,
  });

  @override
  State<VideoUploadList> createState() => _VideoUploadListState();
}

class _VideoUploadListState extends State<VideoUploadList> {
  final _uploadService = UploadService();
  bool _isUploading = false;

  Future<void> _pickAndUploadVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploading = true);

      final filePath = result.files.single.path!;
      UploadResponse response;

      try {
        response = await _uploadService.uploadVideo(filePath);
      } catch (e) {
        rethrow;
      }

      // Ask for title
      if (!mounted) return;
      final titleController = TextEditingController(text: result.files.single.name);

      final String? title = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface(widget.brightness),
          title: Text('Video Title', style: TextStyle(color: AppColors.text(widget.brightness))),
          content: TextField(
            controller: titleController,
            style: TextStyle(color: AppColors.text(widget.brightness)),
            decoration: InputDecoration(
              hintText: 'Enter video title',
              hintStyle: TextStyle(color: AppColors.textSec(widget.brightness)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, titleController.text),
              child: const Text('Save', style: TextStyle(color: AppColors.crimson)),
            ),
          ],
        ),
      );

      if (title != null) {
        final newSample = VideoSample(
          url: response.url,
          title: title,
          cloudinaryPublicId: response.publicId,
        );

        final newSamples = List<VideoSample>.from(widget.samples)..add(newSample);
        widget.onChanged(newSamples);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeSample(int index) {
    final newSamples = List<VideoSample>.from(widget.samples)..removeAt(index);
    widget.onChanged(newSamples);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.samples.asMap().entries.map((entry) {
          final index = entry.key;
          final sample = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface(widget.brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(widget.brightness)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_rounded, color: AppColors.crimson),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sample.title ?? 'Untitled Video',
                        style: TextStyle(
                          color: AppColors.text(widget.brightness),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Video Sample',
                        style: TextStyle(
                          color: AppColors.textSec(widget.brightness),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.textSec(widget.brightness),
                  onPressed: () => _removeSample(index),
                ),
              ],
            ),
          );
        }),

        // Add Button
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadVideo,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.textSec(widget.brightness).withValues(alpha: 0.3),
                style: BorderStyle.none,
              ),
              color: AppColors.surface(widget.brightness).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, color: AppColors.crimson),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Video',
                          style: TextStyle(
                            color: AppColors.text(widget.brightness),
                            fontWeight: FontWeight.w600,
                          ),
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
