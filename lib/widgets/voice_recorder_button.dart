/// 🎙️ GIGMATCH Voice Recorder Button — Professional Tap-to-Record
///
/// Tap to start recording, tap again to send. Clean, reliable UX.
/// Features:
/// - Tap to start/stop recording (no fragile long-press)
/// - Fixed 48×48 size — never causes layout overflow
/// - Parent handles recording UI (timer, cancel)
/// - Duration callback for parent timer display
/// - Haptic feedback
/// - Permission handling
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
  final ValueChanged<int>? onDurationChanged;

  const VoiceRecorderButton({
    super.key,
    required this.onRecordingComplete,
    this.onRecordingStarted,
    this.onRecordingCancelled,
    this.onDurationChanged,
  });

  @override
  State<VoiceRecorderButton> createState() => VoiceRecorderButtonState();
}

class VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _durationTimer;
  String? _recordingPath;

  bool get isRecording => _isRecording;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    // Stop recording if active when widget is disposed (e.g. cancel)
    if (_isRecording) {
      _recorder.stop().then((_) {
        // Clean up temp file
        if (_recordingPath != null) {
          final file = File(_recordingPath!);
          file.exists().then((exists) {
            if (exists) {
              file.delete();
            }
          });
        }
      });
    }
    _recorder.dispose();
    super.dispose();
  }

  /// Called by parent to cancel an active recording
  void cancelRecording() {
    if (!_isRecording) return;
    debugPrint('🎙️ [VoiceRecorder] Recording cancelled by parent');
    _stopRecording(cancelled: true);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording(cancelled: false);
    } else {
      await _startRecording();
    }
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
      debugPrint('🎙️ [VoiceRecorder] Recording started: $_recordingPath');

      // Haptic feedback
      HapticFeedback.mediumImpact();

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Start pulse animation
      _pulseController.repeat(reverse: true);

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() => _recordingDuration++);
          widget.onDurationChanged?.call(_recordingDuration);
        }
      });

      widget.onRecordingStarted?.call();
    } catch (e) {
      debugPrint('❌ [VoiceRecorder] Error starting recording: $e');
    }
  }

  Future<void> _stopRecording({required bool cancelled}) async {
    _durationTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    if (!_isRecording) return;

    try {
      final path = await _recorder.stop();
      debugPrint(
        '🎙️ [VoiceRecorder] Recording stopped. cancelled=$cancelled, '
        'path=$path, duration=${_recordingDuration}s',
      );

      setState(() {
        _isRecording = false;
      });

      if (cancelled || path == null || _recordingDuration < 1) {
        // Delete the file if cancelled or too short
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
      });
      widget.onRecordingCancelled?.call();
    }
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
              child: Text(
                'Microphone permission is required for voice messages',
              ),
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
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always 48×48 — prevents unbounded constraint crash
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = _isRecording ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isRecording
                      ? [Colors.red.shade600, Colors.red.shade400]
                      : [
                          AppColors.crimson,
                          AppColors.crimson.withValues(alpha: 0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : AppColors.crimson)
                        .withValues(alpha: 0.3 * scale),
                    blurRadius: _isRecording ? 16 * scale : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
