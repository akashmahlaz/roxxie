/// 📺 GIGMATCH Story Viewer Screen
///
/// Full-screen story viewing experience with:
/// - Tap/swipe navigation between stories
/// - Progress bars for multi-item stories
/// - Auto-advance with pause on hold
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers/providers.dart';
import '../core/models/feed_models.dart';
import '../core/services/services.dart';
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
  bool _isOwnStory = false;
  final FeedService _feedService = FeedService();

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
    super.dispose();
  }

  Future<void> _loadStory() async {
    try {
      // Get story from provider or load fresh
      final feedProvider = context.read<FeedProvider>();
      final stories = feedProvider.stories;
      final found = stories.where((s) => s.id == widget.storyId).toList();

      if (found.isNotEmpty) {
        // Check if this is the user's own story
        final authProvider = context.read<AuthProvider>();
        final currentUserId = authProvider.user?.id;
        final storyUserId = found.first.author?.id ?? found.first.artistId ?? found.first.venueId;
        
        setState(() {
          _story = found.first;
          _isLoading = false;
          _isOwnStory = currentUserId != null && 
            (currentUserId == storyUserId ||
             currentUserId == found.first.artistId ||
             currentUserId == found.first.venueId);
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
    final duration = item.type == MediaType.video
        ? Duration(seconds: item.duration ?? 15)
        : const Duration(seconds: 5);

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

  void _shareStory() {
    HapticFeedback.lightImpact();
    _pause();
    final story = _story;
    if (story == null) { return; }

    final shareUrl = DeepLinkPatterns.shareableStoryUrl(story.id);
    final caption = _currentItem?.caption;
    final shareText = caption != null && caption.isNotEmpty
        ? '$caption\n\nCheck out this story on GigMatch! 🎵\n$shareUrl'
        : 'Check out this story on GigMatch! 🎵\n$shareUrl';

    debugPrint('📤 [StoryViewer] Sharing story ${story.id}: $shareUrl');
    SharePlus.instance.share(ShareParams(text: shareText));
    Clipboard.setData(ClipboardData(text: shareUrl));
    _resume();
  }

  Future<void> _deleteStory() async {
    final story = _story;
    if (story == null) { return; }
    
    _pause();
    
    // Cache context-dependent values before async gap
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final feedProvider = context.read<FeedProvider>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Story?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) {
      _resume();
      return;
    }
    
    try {
      await _feedService.deleteStory(story.id);
      
      // Remove from provider
      feedProvider.removeStoryLocally(story.id);
      
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Story deleted'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Delete story error: $e');
      _resume();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              child: Text(
                'Story not found',
                style: TextStyle(color: Colors.white),
              ),
            )
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
                      bottom: 40,
                      left: 16,
                      right: 16,
                      child: _buildCaption(),
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

  void _navigateToProfile() {
    final author = _story?.author;
    
    // DEBUG: Log all available IDs
    debugPrint('🎬 [StoryViewer] _navigateToProfile called');
    debugPrint('🎬 [StoryViewer] _story?.artistId: ${_story?.artistId}');
    debugPrint('🎬 [StoryViewer] _story?.venueId: ${_story?.venueId}');
    debugPrint('🎬 [StoryViewer] author?.artistId: ${author?.artistId}');
    debugPrint('🎬 [StoryViewer] author?.venueId: ${author?.venueId}');
    debugPrint('🎬 [StoryViewer] author?.role: ${author?.role}');
    debugPrint('🎬 [StoryViewer] author?.id (userId): ${author?.id}');
    
    final isVenue = _story?.venueId != null || author?.role == 'venue';
    String? profileId;
    if (isVenue) {
      profileId = _story?.venueId ?? author?.venueId;
    } else {
      profileId = _story?.artistId ?? author?.artistId;
    }
    
    debugPrint('🎬 [StoryViewer] isVenue: $isVenue, selected profileId: $profileId');

    if (profileId != null && profileId.isNotEmpty) {
      final route = isVenue ? '/venue/$profileId' : '/artist/$profileId';
      debugPrint('🎬 [StoryViewer] Navigating to: $route');
      final nav = Navigator.of(context, rootNavigator: true);
      nav.pushNamed(route);
    } else {
      debugPrint('❌ [StoryViewer] No valid profileId found - showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildHeader() {
    final author = _story?.author;

    return Row(
      children: [
        // Profile photo + name - tappable to open profile
        Expanded(
          child: GestureDetector(
            onTap: _navigateToProfile,
            child: Row(
              children: [
                Container(
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
                const SizedBox(width: 12),
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
              ],
            ),
          ),
        ),
        // Delete button (only for own stories)
        if (_isOwnStory)
          IconButton(
            onPressed: _deleteStory,
            icon: Icon(Icons.delete_rounded, color: AppColors.error),
          ),
        // Share button
        IconButton(
          onPressed: _shareStory,
          icon: const Icon(Icons.send_rounded, color: Colors.white),
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
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
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
