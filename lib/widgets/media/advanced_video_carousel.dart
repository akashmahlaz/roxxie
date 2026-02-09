/// 🎬 Advanced Video Carousel Widget
///
/// A beautiful video section with:
/// - Auto-play muted on scroll into view
/// - Gesture controls (tap, double-tap, swipe)
/// - Full-screen expansion
/// - Material 3 design
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';

/// Advanced Video Carousel with Material 3 design
class AdvancedVideoCarousel extends StatefulWidget {
  final List<VideoSample> videos;
  final bool autoPlay;
  final bool showIndicators;

  const AdvancedVideoCarousel({
    super.key,
    required this.videos,
    this.autoPlay = true,
    this.showIndicators = true,
  });

  @override
  State<AdvancedVideoCarousel> createState() => _AdvancedVideoCarouselState();
}

class _AdvancedVideoCarouselState extends State<AdvancedVideoCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (widget.videos.isEmpty) {
      return _buildEmptyState(brightness);
    }

    return VisibilityDetector(
      key: const Key('video-carousel'),
      onVisibilityChanged: (info) {
        setState(() {
          _isVisible = info.visibleFraction > 0.5;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Video carousel
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.videos.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                HapticFeedback.selectionClick();
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _VideoCard(
                    video: widget.videos[index],
                    isActive: index == _currentIndex && _isVisible,
                    autoPlay: widget.autoPlay,
                    onTap: () => _openFullScreenPlayer(index),
                  ),
                );
              },
            ),
          ),

          // Page indicators
          if (widget.showIndicators && widget.videos.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.videos.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.crimson
                          : AppColors.crimson.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness) {
    return Card.filled(
      color: AppColors.surface(brightness),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              size: 48,
              color: AppColors.textSec(brightness),
            ),
            const SizedBox(height: 16),
            Text(
              'No video samples available',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenPlayer(int index) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _FullScreenVideoPlayer(videos: widget.videos, initialIndex: index),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VIDEO CARD
// ══════════════════════════════════════════════════════════════════════════════

class _VideoCard extends StatefulWidget {
  final VideoSample video;
  final bool isActive;
  final bool autoPlay;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.isActive,
    required this.autoPlay,
    required this.onTap,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  final bool _showPlayButton = true;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      _initializeController();
    }
  }

  @override
  void didUpdateWidget(covariant _VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive && widget.autoPlay) {
        _controller?.play();
        _controller?.setVolume(0);
      } else {
        _controller?.pause();
      }
    }
  }

  Future<void> _initializeController() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.url),
      );
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.setVolume(0); // Muted auto-play

      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.isActive && widget.autoPlay) {
          _controller!.play();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: () {
        // Toggle mute on double tap
        if (_controller != null) {
          final isMuted = _controller!.value.volume == 0;
          _controller!.setVolume(isMuted ? 1 : 0);
          HapticFeedback.lightImpact();
        }
      },
      child: Card.outlined(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: widget.isActive
                ? AppColors.crimson.withValues(alpha: 0.5)
                : AppColors.divider(brightness),
            width: widget.isActive ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video or thumbnail
            if (_isInitialized && _controller != null)
              VideoPlayer(_controller!)
            else if (widget.video.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: widget.video.thumbnailUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _buildPlaceholder(brightness),
              )
            else
              _buildPlaceholder(brightness),

            // Loading indicator
            if (!_isInitialized && !_hasError && widget.autoPlay)
              Center(
                child: CircularProgressIndicator(
                  color: AppColors.crimson,
                  strokeWidth: 3,
                ),
              ),

            // Play button overlay
            if (_showPlayButton || !_isInitialized)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

            // Video info overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.video.title ?? 'Video',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      textColor: Colors.white,
                      label: Text(
                        _formatDuration(widget.video.durationSeconds ?? 0),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Muted indicator
            if (_isInitialized && _controller?.value.volume == 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.volume_off_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Brightness brightness) {
    return Container(
      color: AppColors.surface(brightness),
      child: Center(
        child: Icon(
          Icons.videocam_rounded,
          color: AppColors.textSec(brightness),
          size: 48,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FULL SCREEN VIDEO PLAYER
// ══════════════════════════════════════════════════════════════════════════════

class _FullScreenVideoPlayer extends StatefulWidget {
  final List<VideoSample> videos;
  final int initialIndex;

  const _FullScreenVideoPlayer({
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late PageController _pageController;
  late VideoPlayerController _videoController;
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isSeeking = false;
  double _seekPosition = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final video = widget.videos[_currentIndex];
    _videoController = VideoPlayerController.networkUrl(Uri.parse(video.url));

    try {
      await _videoController.initialize();
      await _videoController.play();
      await _videoController.setVolume(1);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
      _startHideControlsTimer();
    } catch (_) {
      // Handle error
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _videoController.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    if (_videoController.value.isPlaying) {
      _videoController.pause();
      setState(() => _showControls = true);
    } else {
      _videoController.play();
      _startHideControlsTimer();
    }
    setState(() {});
  }

  void _seekTo(double value) {
    final position = Duration(
      milliseconds: (value * _videoController.value.duration.inMilliseconds)
          .round(),
    );
    _videoController.seekTo(position);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _pageController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentIndex + 1} / ${widget.videos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),
            ),

            // Video
            Expanded(
              child: GestureDetector(
                onTap: _toggleControls,
                onDoubleTapDown: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final tapX = details.globalPosition.dx;

                  if (tapX < screenWidth / 3) {
                    // Seek backward
                    _videoController.seekTo(
                      _videoController.value.position -
                          const Duration(seconds: 10),
                    );
                  } else if (tapX > screenWidth * 2 / 3) {
                    // Seek forward
                    _videoController.seekTo(
                      _videoController.value.position +
                          const Duration(seconds: 10),
                    );
                  } else {
                    // Toggle play/pause
                    _togglePlayPause();
                  }
                  HapticFeedback.lightImpact();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isInitialized)
                      AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      )
                    else
                      const CircularProgressIndicator(color: Colors.white),

                    // Play/Pause button
                    AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton.filled(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          _videoController.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        iconSize: 48,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.crimson,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 80),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildVideoControls(brightness),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls(Brightness brightness) {
    if (!_isInitialized) return const SizedBox(height: 100);

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _videoController,
      builder: (context, value, child) {
        final progress = value.duration.inMilliseconds > 0
            ? value.position.inMilliseconds / value.duration.inMilliseconds
            : 0.0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Seek slider
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  activeTrackColor: AppColors.crimson,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                  thumbColor: AppColors.crimson,
                ),
                child: Slider(
                  value: _isSeeking ? _seekPosition : progress.clamp(0.0, 1.0),
                  onChangeStart: (v) {
                    setState(() {
                      _isSeeking = true;
                      _seekPosition = v;
                    });
                  },
                  onChanged: (v) => setState(() => _seekPosition = v),
                  onChangeEnd: (v) {
                    _seekTo(v);
                    setState(() => _isSeeking = false);
                  },
                ),
              ),

              // Time labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(value.position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(value.duration),
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
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
