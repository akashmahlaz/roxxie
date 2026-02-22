/// 🎵 Advanced Audio Player Widget
///
/// A beautiful, fully-featured audio player with:
/// - Animated waveform visualization
/// - Seekable slider with buffer indicator
/// - Play/pause, skip controls
/// - Volume control
/// - Track list with queue
/// - Material 3 design
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';

/// Audio player state for external control
class AudioPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final int? currentIndex;
  final String? error;

  const AudioPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.currentIndex,
    this.error,
  });

  double get progress => duration.inMilliseconds > 0
      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;

  double get bufferProgress => duration.inMilliseconds > 0
      ? (buffered.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;
}

/// Advanced Audio Player with Material 3 design
class AdvancedAudioPlayer extends StatefulWidget {
  final List<AudioSample> samples;
  final int initialIndex;
  final bool showTrackList;
  final bool showVolumeControl;
  final bool compact;
  final VoidCallback? onClose;

  const AdvancedAudioPlayer({
    super.key,
    required this.samples,
    this.initialIndex = 0,
    this.showTrackList = true,
    this.showVolumeControl = true,
    this.compact = false,
    this.onClose,
  });

  @override
  State<AdvancedAudioPlayer> createState() => _AdvancedAudioPlayerState();
}

class _AdvancedAudioPlayerState extends State<AdvancedAudioPlayer>
    with TickerProviderStateMixin {
  late AudioPlayer _player;
  late AnimationController _waveformController;

  // State
  AudioPlayerState _state = const AudioPlayerState();
  int _currentIndex = 0;
  double _volume = 0.8;
  bool _isSeeking = false;
  double _seekPosition = 0.0;

  // Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _player = AudioPlayer();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _setupListeners();
    _loadTrack(_currentIndex);
  }

  void _setupListeners() {
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _state = AudioPlayerState(
              isPlaying: state.playing,
              isLoading:
                  state.processingState == ProcessingState.loading ||
                  state.processingState == ProcessingState.buffering,
              position: _state.position,
              duration: _state.duration,
              buffered: _state.buffered,
              currentIndex: _currentIndex,
              error: _state.error,
            );
          });
        }
      }),
    );

    _subscriptions.add(
      _player.positionStream.listen((position) {
        if (mounted && !_isSeeking) {
          setState(() {
            _state = AudioPlayerState(
              isPlaying: _state.isPlaying,
              isLoading: _state.isLoading,
              position: position,
              duration: _state.duration,
              buffered: _state.buffered,
              currentIndex: _currentIndex,
              error: _state.error,
            );
          });
        }
      }),
    );

    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _state = AudioPlayerState(
              isPlaying: _state.isPlaying,
              isLoading: _state.isLoading,
              position: _state.position,
              duration: duration ?? Duration.zero,
              buffered: _state.buffered,
              currentIndex: _currentIndex,
              error: _state.error,
            );
          });
        }
      }),
    );

    _subscriptions.add(
      _player.bufferedPositionStream.listen((buffered) {
        if (mounted) {
          setState(() {
            _state = AudioPlayerState(
              isPlaying: _state.isPlaying,
              isLoading: _state.isLoading,
              position: _state.position,
              duration: _state.duration,
              buffered: buffered,
              currentIndex: _currentIndex,
              error: _state.error,
            );
          });
        }
      }),
    );

    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _playNext();
        }
      }),
    );
  }

  Future<void> _loadTrack(int index) async {
    if (index < 0 || index >= widget.samples.length) return;

    setState(() {
      _currentIndex = index;
      _state = AudioPlayerState(isLoading: true, currentIndex: index);
    });

    try {
      final sample = widget.samples[index];
      // Ensure HTTPS (Android blocks cleartext HTTP)
      final url = sample.url.startsWith('http://')
          ? sample.url.replaceFirst('http://', 'https://')
          : sample.url;
      await _player.setUrl(url);
      await _player.setVolume(_volume);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = AudioPlayerState(
            error: 'Failed to load audio',
            currentIndex: index,
          );
        });
      }
    }
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    if (_state.isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _playPrevious() {
    HapticFeedback.lightImpact();
    if (_currentIndex > 0) {
      _loadTrack(_currentIndex - 1);
      _player.play();
    }
  }

  void _playNext() {
    HapticFeedback.lightImpact();
    if (_currentIndex < widget.samples.length - 1) {
      _loadTrack(_currentIndex + 1);
      _player.play();
    }
  }

  void _seekTo(double value) {
    final position = Duration(
      milliseconds: (value * _state.duration.inMilliseconds).round(),
    );
    _player.seek(position);
  }

  void _setVolume(double value) {
    setState(() => _volume = value);
    _player.setVolume(value);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (widget.samples.isEmpty) {
      return _buildEmptyState(brightness);
    }

    return widget.compact
        ? _buildCompactPlayer(brightness)
        : _buildFullPlayer(brightness);
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
              Icons.music_off_rounded,
              size: 48,
              color: AppColors.textSec(brightness),
            ),
            const SizedBox(height: 16),
            Text(
              'No audio samples available',
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

  // ══════════════════════════════════════════════════════════════════════════
  // FULL PLAYER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFullPlayer(Brightness brightness) {
    final currentSample = widget.samples[_currentIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main player card
        Card.filled(
          color: AppColors.surface(brightness),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Track info header
              _buildTrackHeader(brightness, currentSample),

              // Waveform visualization
              _buildWaveform(brightness),

              // Seek slider
              _buildSeekSlider(brightness),

              // Time labels
              _buildTimeLabels(brightness),

              // Control buttons
              _buildControlButtons(brightness),

              // Volume control
              if (widget.showVolumeControl) _buildVolumeControl(brightness),

              const SizedBox(height: 8),
            ],
          ),
        ),

        // Track list
        if (widget.showTrackList && widget.samples.length > 1)
          _buildTrackList(brightness),
      ],
    );
  }

  Widget _buildTrackHeader(Brightness brightness, AudioSample sample) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // Album art / icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.crimson, AppColors.rose],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sample.title ?? 'Untitled Track',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Badge(
                      backgroundColor: AppColors.crimson.withValues(
                        alpha: 0.15,
                      ),
                      textColor: AppColors.crimson,
                      label: Text(
                        'Track ${_currentIndex + 1} of ${widget.samples.length}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    if (_state.isLoading) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.crimson,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Duration badge
          Badge(
            backgroundColor: AppColors.surface(brightness),
            textColor: AppColors.text(brightness),
            label: Text(
              _formatDuration(_state.duration),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform(Brightness brightness) {
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CustomPaint(
            painter: _WaveformPainter(
              progress: _state.progress,
              bufferProgress: _state.bufferProgress,
              isPlaying: _state.isPlaying,
              animationValue: _waveformController.value,
              activeColor: AppColors.crimson,
              inactiveColor: AppColors.crimson.withValues(alpha: 0.2),
              bufferColor: AppColors.crimson.withValues(alpha: 0.4),
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildSeekSlider(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: [
          // Buffer progress
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: AppColors.crimson.withValues(alpha: 0.3),
              inactiveTrackColor: AppColors.divider(brightness),
            ),
            child: Slider(value: _state.bufferProgress, onChanged: null),
          ),

          // Seek slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
                elevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: AppColors.crimson,
              inactiveTrackColor: Colors.transparent,
              thumbColor: AppColors.crimson,
              overlayColor: AppColors.crimson.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _isSeeking ? _seekPosition : _state.progress,
              onChangeStart: (value) {
                setState(() {
                  _isSeeking = true;
                  _seekPosition = value;
                });
              },
              onChanged: (value) {
                setState(() => _seekPosition = value);
              },
              onChangeEnd: (value) {
                _seekTo(value);
                setState(() => _isSeeking = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLabels(Brightness brightness) {
    final displayPosition = _isSeeking
        ? Duration(
            milliseconds: (_seekPosition * _state.duration.inMilliseconds)
                .round(),
          )
        : _state.position;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDuration(displayPosition),
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            _formatDuration(_state.duration),
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous
          IconButton.filledTonal(
            onPressed: _currentIndex > 0 ? _playPrevious : null,
            icon: const Icon(Icons.skip_previous_rounded),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: _currentIndex > 0
                  ? AppColors.crimson.withValues(alpha: 0.1)
                  : null,
              foregroundColor: _currentIndex > 0
                  ? AppColors.crimson
                  : AppColors.textSec(brightness),
            ),
          ),

          const SizedBox(width: 16),

          // Play/Pause
          IconButton.filled(
            onPressed: _state.error == null ? _togglePlayPause : null,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _state.isLoading
                  ? SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      key: ValueKey(_state.isPlaying),
                    ),
            ),
            iconSize: 36,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              minimumSize: const Size(72, 72),
            ),
          ),

          const SizedBox(width: 16),

          // Next
          IconButton.filledTonal(
            onPressed: _currentIndex < widget.samples.length - 1
                ? _playNext
                : null,
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: _currentIndex < widget.samples.length - 1
                  ? AppColors.crimson.withValues(alpha: 0.1)
                  : null,
              foregroundColor: _currentIndex < widget.samples.length - 1
                  ? AppColors.crimson
                  : AppColors.textSec(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(
            _volume == 0
                ? Icons.volume_off_rounded
                : _volume < 0.5
                ? Icons.volume_down_rounded
                : Icons.volume_up_rounded,
            color: AppColors.textSec(brightness),
            size: 20,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.textSec(brightness),
                inactiveTrackColor: AppColors.divider(brightness),
                thumbColor: AppColors.textSec(brightness),
              ),
              child: Slider(value: _volume, onChanged: _setVolume),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'All Tracks',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...widget.samples.asMap().entries.map((entry) {
            final index = entry.key;
            final sample = entry.value;
            final isActive = index == _currentIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card.outlined(
                color: isActive
                    ? AppColors.crimson.withValues(alpha: 0.08)
                    : AppColors.surface(brightness),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isActive
                        ? AppColors.crimson.withValues(alpha: 0.5)
                        : AppColors.divider(brightness),
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    if (index != _currentIndex) {
                      _loadTrack(index);
                      _player.play();
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.crimson
                          : AppColors.crimson.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isActive && _state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: isActive ? Colors.white : AppColors.crimson,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    sample.title ?? 'Track ${index + 1}',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: isActive && _state.isPlaying
                      ? Row(
                          children: [
                            Icon(
                              Icons.graphic_eq_rounded,
                              size: 14,
                              color: AppColors.crimson,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Now Playing',
                              style: TextStyle(
                                color: AppColors.crimson,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : null,
                  trailing: Badge(
                    backgroundColor: AppColors.surface(brightness),
                    textColor: AppColors.textSec(brightness),
                    label: Text(
                      _formatDuration(
                        Duration(seconds: sample.durationSeconds ?? 0),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPACT PLAYER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCompactPlayer(Brightness brightness) {
    final currentSample = widget.samples[_currentIndex];

    return Card.filled(
      color: AppColors.surface(brightness),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Album art
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.crimson, AppColors.rose],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Track info + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentSample.title ?? 'Untitled',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _state.progress,
                      backgroundColor: AppColors.crimson.withValues(
                        alpha: 0.15,
                      ),
                      color: AppColors.crimson,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Controls
            IconButton.filled(
              onPressed: _togglePlayPause,
              icon: Icon(
                _state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WAVEFORM PAINTER
// ══════════════════════════════════════════════════════════════════════════════

class _WaveformPainter extends CustomPainter {
  final double progress;
  final double bufferProgress;
  final bool isPlaying;
  final double animationValue;
  final Color activeColor;
  final Color inactiveColor;
  final Color bufferColor;

  _WaveformPainter({
    required this.progress,
    required this.bufferProgress,
    required this.isPlaying,
    required this.animationValue,
    required this.activeColor,
    required this.inactiveColor,
    required this.bufferColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 50;
    final barWidth = size.width / barCount * 0.6;
    final gap = size.width / barCount * 0.4;
    final maxHeight = size.height * 0.9;
    final centerY = size.height / 2;

    final random = math.Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap) + gap / 2;
      final normalizedX = i / barCount;

      // Generate pseudo-random height
      double baseHeight = random.nextDouble() * 0.6 + 0.2;

      // Add animation wave effect when playing
      double animatedHeight = baseHeight;
      if (isPlaying) {
        final wave =
            math.sin((animationValue * 2 * math.pi) + (i * 0.3)) * 0.15;
        animatedHeight = (baseHeight + wave).clamp(0.1, 1.0);
      }

      final height = animatedHeight * maxHeight;

      // Determine color based on progress
      Color barColor;
      if (normalizedX <= progress) {
        barColor = activeColor;
      } else if (normalizedX <= bufferProgress) {
        barColor = bufferColor;
      } else {
        barColor = inactiveColor;
      }

      final paint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: height,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.bufferProgress != bufferProgress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.animationValue != animationValue;
  }
}
