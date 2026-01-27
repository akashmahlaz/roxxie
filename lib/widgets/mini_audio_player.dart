/// 🎵 GIGMATCH Mini Audio Player
///
/// Compact audio preview widget for discovery cards
/// Features:
/// - Play/pause with animated icon
/// - Animated progress bar
/// - Duration display
/// - Auto-pause when card swiped
/// - Glassmorphism design
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../core/theme/theme.dart';

class MiniAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String? title;
  final Duration? duration;
  final bool autoPlay;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;

  const MiniAudioPlayer({
    super.key,
    required this.audioUrl,
    this.title,
    this.duration,
    this.autoPlay = false,
    this.onPlay,
    this.onPause,
  });

  @override
  State<MiniAudioPlayer> createState() => MiniAudioPlayerState();
}

class MiniAudioPlayerState extends State<MiniAudioPlayer>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _pulseController;

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _initAudio();
    _setupListeners();
  }

  Future<void> _initAudio() async {
    try {
      setState(() => _isLoading = true);

      await _audioPlayer.setUrl(widget.audioUrl);

      if (widget.autoPlay) {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('❌ [MiniAudioPlayer] Error loading audio: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupListeners() {
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() => _totalDuration = duration);
      }
    });

    _playerStateSubscription =
        _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        final isPlaying = playerState.playing;
        setState(() => _isPlaying = isPlaying);

        if (isPlaying) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }

        // Handle completion
        if (playerState.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      }
    });
  }

  Future<void> _togglePlayPause() async {
    HapticFeedback.lightImpact();

    if (_isPlaying) {
      await _audioPlayer.pause();
      widget.onPause?.call();
    } else {
      await _audioPlayer.play();
      widget.onPlay?.call();
    }
  }

  /// Public method to pause from parent (e.g., when card is swiped)
  void pause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    }
  }

  /// Public method to stop and reset
  void stop() {
    _audioPlayer.stop();
    _audioPlayer.seek(Duration.zero);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    if (_totalDuration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _totalDuration.inMilliseconds;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final displayDuration = widget.duration ?? _totalDuration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.crimson,
                        AppColors.crimson.withValues(
                          alpha: 0.8 + (_pulseController.value * 0.2),
                        ),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: _isPlaying
                        ? [
                            BoxShadow(
                              color: AppColors.crimson.withValues(
                                alpha: 0.4 + (_pulseController.value * 0.2),
                              ),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          // Progress Bar & Time
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (if provided)
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 4),

                // Progress bar
                Container(
                  height: 4,
                  constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.crimson,
                            AppColors.crimson.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                // Duration
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      ' / ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _formatDuration(displayDuration),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Audio preview chip for multiple samples
class AudioPreviewChip extends StatelessWidget {
  final int sampleCount;
  final VoidCallback onTap;

  const AudioPreviewChip({
    super.key,
    required this.sampleCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headphones_rounded,
              color: AppColors.crimson,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '$sampleCount sample${sampleCount > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
