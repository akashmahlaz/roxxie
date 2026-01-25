part of '../edit_profile_v2_screen.dart';

/// Video Sample Item with thumbnail
class _VideoSampleItem extends StatelessWidget {
  final VideoSampleState sample;
  final int index;
  final VoidCallback onRemove;

  const _VideoSampleItem({
    required this.sample,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.background(brightness),
                borderRadius: BorderRadius.circular(10),
                image: sample.thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(sample.thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: sample.isUploading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.crimson),
                      ),
                    )
                  : sample.thumbnailUrl == null
                  ? Icon(
                      Icons.videocam_rounded,
                      color: AppColors.textSec(brightness),
                    )
                  : null,
            ),
            if (!sample.isUploading && sample.isUploaded)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
        title: Text(
          sample.title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (sample.isUploading)
              Text(
                'Uploading video...',
                style: TextStyle(color: AppColors.crimson, fontSize: 12),
              )
            else if (sample.isUploaded)
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(sample.duration),
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Upload failed',
                style: TextStyle(color: AppColors.crimson, fontSize: 12),
              ),
          ],
        ),
        trailing: IconButton(
          onPressed: onRemove,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: AppColors.crimson,
            size: 20,
          ),
          tooltip: 'Remove',
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
