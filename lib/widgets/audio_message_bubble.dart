/// 🎤 GIGMATCH Audio Message Bubble
///
/// Chat bubble for audio/voice messages
/// Features:
/// - Play/pause button
/// - Waveform visualization
/// - Duration display
/// - Progress tracking
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../core/theme/theme.dart';

class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int? durationSeconds;
  final bool isOwnMessage;
  final VoidCallback? onPlaybackStarted;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    this.durationSeconds,
    this.isOwnMessage = true,
    this.onPlaybackStarted,
  });

  @override
  State<AudioMessageBubble> createState() => AudioMessageBubbleState();
}

class AudioMessageBubbleState extends State<AudioMessageBubble> {
  late AudioPlayer _audioPlayer;

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

    // Set initial duration from message metadata
    if (widget.durationSeconds != null) {
      _totalDuration = Duration(seconds: widget.durationSeconds!);
    }

    _setupListeners();
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
        setState(() {
          _isPlaying = playerState.playing;
          _isLoading = playerState.processingState == ProcessingState.loading ||
              playerState.processingState == ProcessingState.buffering;
        });

        // Reset position when completed
        if (playerState.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Public method to pause playback from parent
  void pause() {
    _audioPlayer.pause();
  }

  /// Public method to stop playback from parent
  void stop() {
    _audioPlayer.stop();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Load audio if not loaded
      if (_audioPlayer.audioSource == null) {
        setState(() => _isLoading = true);
        try {
          await _audioPlayer.setUrl(widget.audioUrl);
        } catch (e) {
          debugPrint('❌ [AudioMessageBubble] Error loading audio: $e');
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      widget.onPlaybackStarted?.call();
      await _audioPlayer.play();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inMilliseconds > 0
        ? _position.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    final primaryColor = widget.isOwnMessage ? Colors.white : AppColors.crimson;
    final secondaryColor = widget.isOwnMessage
        ? Colors.white.withValues(alpha: 0.5)
        : AppColors.crimson.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _togglePlayback,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  )
                : Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        // Waveform and progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Waveform visualization
              _buildWaveform(progress, primaryColor, secondaryColor),
              const SizedBox(height: 4),
              // Duration
              Text(
                _isPlaying || _position.inSeconds > 0
                    ? '${_formatDuration(_position)} / ${_formatDuration(_totalDuration)}'
                    : _formatDuration(_totalDuration),
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform(
    double progress,
    Color primaryColor,
    Color secondaryColor,
  ) {
    // Generate pseudo-random waveform bars
    const barCount = 30;
    final barHeights = List.generate(barCount, (i) {
      // Create a pseudo-random but consistent pattern
      final value = ((i * 7 + 3) % 11) / 10.0;
      return 0.3 + value * 0.7;
    });

    return SizedBox(
      height: 24,
      child: Row(
        children: List.generate(barCount, (i) {
          final barProgress = i / barCount;
          final isPlayed = barProgress <= progress;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              height: 24 * barHeights[i],
              decoration: BoxDecoration(
                color: isPlayed ? primaryColor : secondaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
