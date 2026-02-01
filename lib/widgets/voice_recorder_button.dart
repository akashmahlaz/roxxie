/// 🎙️ GIGMATCH Voice Recorder Button
///
/// Hold-to-record voice message button for chat
/// Features:
/// - Hold to record
/// - Swipe to cancel
/// - Visual recording indicator
/// - Duration display while recording
/// - Haptic feedback
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/theme/theme.dart';

class VoiceRecorderButton extends StatefulWidget {
  final Function(String audioPath, int durationSeconds) onRecordingComplete;
  final VoidCallback? onRecordingStarted;
  final VoidCallback? onRecordingCancelled;

  const VoiceRecorderButton({
    super.key,
    required this.onRecordingComplete,
    this.onRecordingStarted,
    this.onRecordingCancelled,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isRecording = false;
  bool _isCancelling = false;
  int _recordingDuration = 0;
  Timer? _durationTimer;
  String? _recordingPath;
  double _dragOffset = 0;

  static const double _cancelThreshold = -80;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Check permission
      if (!await _recorder.hasPermission()) {
        debugPrint('❌ [VoiceRecorder] No microphone permission');
        _showPermissionDeniedMessage();
        return;
      }

      // Get temp directory for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${tempDir.path}/voice_message_$timestamp.m4a';

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );

      // Start recording
      await _recorder.start(config, path: _recordingPath!);

      // Haptic feedback
      HapticFeedback.mediumImpact();

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _isCancelling = false;
        _dragOffset = 0;
      });

      // Start pulse animation
      _pulseController.repeat(reverse: true);

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() => _recordingDuration++);
        }
      });

      widget.onRecordingStarted?.call();
    } catch (e) {
      debugPrint('❌ [VoiceRecorder] Error starting recording: $e');
    }
  }

  Future<void> _stopRecording({bool cancelled = false}) async {
    _durationTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    if (!_isRecording) return;

    try {
      final path = await _recorder.stop();

      setState(() {
        _isRecording = false;
        _isCancelling = false;
        _dragOffset = 0;
      });

      if (cancelled || path == null) {
        // Delete the file if cancelled
        if (_recordingPath != null) {
          final file = File(_recordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        widget.onRecordingCancelled?.call();
        HapticFeedback.lightImpact();
      } else {
        // Recording completed successfully
        widget.onRecordingComplete(path, _recordingDuration);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('❌ [VoiceRecorder] Error stopping recording: $e');
      setState(() {
        _isRecording = false;
        _isCancelling = false;
      });
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isRecording) return;

    setState(() {
      _dragOffset += details.delta.dx;
      _isCancelling = _dragOffset < _cancelThreshold;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  void _showPermissionDeniedMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.mic_off_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Microphone permission is required for voice messages'),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () {
            // Open app settings
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return _buildRecordingOverlay();
    }

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(cancelled: _isCancelling),
      onLongPressMoveUpdate: (details) {
        _handleDragUpdate(DragUpdateDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
          delta: details.offsetFromOrigin,
        ));
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.crimson.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic_rounded,
          color: AppColors.crimson,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    final brightness = Theme.of(context).brightness;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel hint with slide animation
          AnimatedOpacity(
            opacity: _isCancelling ? 1.0 : 0.7,
            duration: const Duration(milliseconds: 150),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: _isCancelling
                      ? Colors.red
                      : AppColors.textSec(brightness),
                ),
                const SizedBox(width: 4),
                Text(
                  _isCancelling ? 'Release to cancel' : 'Slide to cancel',
                  style: TextStyle(
                    color: _isCancelling
                        ? Colors.red
                        : AppColors.textSec(brightness),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Recording duration
          Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              color: AppColors.crimson,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(width: 12),

          // Pulsing recording indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.crimson,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.crimson.withValues(
                          alpha: 0.5 * _pulseAnimation.value,
                        ),
                        blurRadius: 16 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
