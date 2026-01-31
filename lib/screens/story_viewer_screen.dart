/// 📺 GIGMATCH Story Viewer Screen
///
/// Full-screen story viewing experience with:
/// - Tap/swipe navigation between stories
/// - Progress bars for multi-item stories
/// - Reactions and replies
/// - Auto-advance with pause on hold
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../core/providers/providers.dart';
import '../core/models/feed_models.dart';
import '../core/theme/theme.dart';

class StoryViewerScreen extends StatefulWidget {
  final String storyId;
  final String userId;
  final int initialItemIndex;

  const StoryViewerScreen({
    super.key,
    required this.storyId,
    required this.userId,
    this.initialItemIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Story? _story;
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isLoading = true;
  Timer? _autoAdvanceTimer;

  // Reaction sheet
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialItemIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progressController.addListener(_onProgressUpdate);
    _loadStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _autoAdvanceTimer?.cancel();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadStory() async {
    try {
      // Get story from provider or load fresh
      final feedProvider = context.read<FeedProvider>();
      final stories = feedProvider.stories;
      final found = stories.where((s) => s.id == widget.storyId).toList();

      if (found.isNotEmpty) {
        setState(() {
          _story = found.first;
          _isLoading = false;
        });
        _markAsViewed();
        _startProgress();
      }
    } catch (e) {
      debugPrint('Load story error: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _startProgress() {
    final item = _currentItem;
    if (item == null) {
      return;
    }

    // Duration based on item type (images 5s, videos by duration)
    final duration =
        item.type == MediaType.video ? Duration(seconds: item.duration ?? 15) : const Duration(seconds: 5);

    _progressController.duration = duration;
    _progressController.reset();
    _progressController.forward();
  }

  void _onProgressUpdate() {
    if (_progressController.isCompleted) {
      _goToNext();
    }
  }

  void _goToNext() {
    if (_story == null) {
      return;
    }

    if (_currentIndex < _story!.items.length - 1) {
      setState(() => _currentIndex++);
      _markAsViewed();
      _startProgress();
    } else {
      // End of story
      Navigator.pop(context);
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startProgress();
    } else {
      // Go to previous user's story or exit
      Navigator.pop(context);
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _progressController.forward();
    }
  }

  void _markAsViewed() {
    final item = _currentItem;
    if (item != null && _story != null) {
      context.read<FeedProvider>().markStoryViewed(_story!.id, item.id);
    }
  }

  StoryItem? get _currentItem {
    if (_story == null || _story!.items.isEmpty) {
      return null;
    }
    if (_currentIndex >= _story!.items.length) {
      return null;
    }
    return _story!.items[_currentIndex];
  }

  void _sendReaction(String emoji) {
    HapticFeedback.mediumImpact();
    final item = _currentItem;
    if (item != null && _story != null) {
      context.read<FeedProvider>().reactToStory(_story!.id, item.id, emoji);
    }
    _resume();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.crimson),
            )
          : _story == null
              ? const Center(
                  child: Text('Story not found',
                      style: TextStyle(color: Colors.white)))
              : GestureDetector(
                  onTapDown: (_) => _pause(),
                  onTapUp: (details) {
                    final width = MediaQuery.of(context).size.width;
                    if (details.globalPosition.dx < width / 3) {
                      _goToPrevious();
                    } else if (details.globalPosition.dx > width * 2 / 3) {
                      _goToNext();
                    } else {
                      _resume();
                    }
                  },
                  onLongPressStart: (_) => _pause(),
                  onLongPressEnd: (_) => _resume(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Story content
                      _buildContent(),

                      // Overlay gradient
                      _buildOverlayGradient(),

                      // Progress bars
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 12,
                        right: 12,
                        child: _buildProgressBars(),
                      ),

                      // Header
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 24,
                        left: 12,
                        right: 12,
                        child: _buildHeader(),
                      ),

                      // Caption
                      if (_currentItem?.caption != null)
                        Positioned(
                          bottom: 120,
                          left: 16,
                          right: 16,
                          child: _buildCaption(),
                        ),

                      // Bottom reactions
                      Positioned(
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                        left: 16,
                        right: 16,
                        child: _buildReactions(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildContent() {
    final item = _currentItem;
    if (item == null) {
      return const SizedBox.shrink();
    }

    if (item.type == MediaType.video) {
      // Video placeholder - would use video_player in production
      return Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (item.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: item.thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: item.url,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: AppColors.crimson),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.error_outline, color: Colors.white, size: 48),
      ),
    );
  }

  Widget _buildOverlayGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.6),
          ],
          stops: const [0.0, 0.2, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    if (_story == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: List.generate(_story!.items.length, (index) {
        return Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: index == _currentIndex
                ? AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  )
                : index < _currentIndex
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white,
                        ),
                      )
                    : null,
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    final author = _story?.author;

    return Row(
      children: [
        // Profile photo
        GestureDetector(
          onTap: () {
            final route = _story?.author?.role == 'venue'
                ? '/venue/${_story?.userId}'
                : '/artist/${_story?.userId}';
            Navigator.pushNamed(context, route);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: author?.profilePhoto != null
                  ? CachedNetworkImage(
                      imageUrl: author!.profilePhoto!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name & time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                author?.name ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatTimeAgo(_story?.createdAt ?? DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Close button
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCaption() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _currentItem?.caption ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReactions() {
    return Row(
      children: [
        // Reply input
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: TextField(
              controller: _replyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Send message...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                border: InputBorder.none,
              ),
              onTap: _pause,
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  // Send reply logic
                  _replyController.clear();
                }
                _resume();
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Quick reactions
        _buildReactionButton('❤️'),
        _buildReactionButton('🔥'),
        _buildReactionButton('👏'),
        _buildReactionButton('😂'),
      ],
    );
  }

  Widget _buildReactionButton(String emoji) {
    return GestureDetector(
      onTap: () => _sendReaction(emoji),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
