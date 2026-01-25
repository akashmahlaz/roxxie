part of '../edit_profile_v2_screen.dart';

/// Photo Gallery Item with remove button
class _PhotoGalleryItem extends StatelessWidget {
  final PhotoGalleryState photo;
  final int index;
  final VoidCallback onRemove;

  const _PhotoGalleryItem({
    required this.photo,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Stack(
      children: [
        // Photo
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
            border: photo.isUploading
                ? Border.all(color: AppColors.cyan, width: 2)
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: photo.isUploading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.cyan),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uploading',
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              : photo.localPath != null
                  ? Image.file(
                      File(photo.localPath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : photo.url != null
                      ? Image.network(
                          photo.url!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => _buildErrorWidget(brightness),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.cyan),
                              ),
                            );
                          },
                        )
                      : _buildErrorWidget(brightness),
        ),

        // Index badge
        Positioned(
          top: 4,
          left: 4,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),

        // Upload success indicator
        if (photo.isUploaded && !photo.isUploading)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: AppColors.textSec(brightness),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'Error',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
