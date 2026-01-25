part of '../edit_profile_v2_screen.dart';

/// Audio Sample Item with waveform visualization
class _AudioSampleItem extends StatelessWidget {
  final AudioSampleState sample;
  final int index;
  final VoidCallback onRemove;

  const _AudioSampleItem({
    super.key,
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
        border: sample.isUploading
            ? Border.all(color: AppColors.cyan.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.2),
                    AppColors.rose.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: sample.isUploading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.cyan),
                      ),
                    )
                  : Icon(
                      Icons.music_note_rounded,
                      color: AppColors.cyan,
                      size: 24,
                    ),
            ),
            // Reorder handle
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                'Uploading...',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 12,
                ),
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
                style: TextStyle(
                  color: AppColors.crimson,
                  fontSize: 12,
                ),
              ),
            
            // Waveform visualization (simplified)
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(15, (i) {
                    final height = 4.0 + (i % 5) * 3 + (i % 3) * 2;
                    return Container(
                      width: 2,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle_rounded,
                color: AppColors.textSec(brightness),
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            // Delete button
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.crimson,
                size: 20,
              ),
              tooltip: 'Remove',
            ),
          ],
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
