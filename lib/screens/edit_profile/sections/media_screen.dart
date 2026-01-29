/// 🎬 MEDIA SCREEN - PREMIUM TAB-BASED ARCHITECTURE
///
/// Professional media management with:
/// ✅ Tab-based navigation (Audio | Video | Photos)
/// ✅ Inline audio player with waveform-style progress
/// ✅ Video grid with thumbnail previews
/// ✅ Profile photo hero + gallery grid
/// ✅ FAB with bottom sheet for add media
/// ✅ Samsung-inspired premium UI (24px radius)
library;

import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Media Screen with Premium Tab Architecture
class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Services
  final _artistService = ArtistService();
  final _venueService = VenueService();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _profilePhotoUrl;
  File? _newProfilePhoto;

  // Audio
  final List<_AudioItem> _audioSamples = [];
  int? _playingAudioIndex;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Video
  final List<_VideoItem> _videoSamples = [];

  // Photos (Gallery)
  final List<_PhotoItem> _galleryPhotos = [];

  bool get _isArtist => context.read<AuthProvider>().isArtist;

  bool get _hasActiveUploads =>
      _audioSamples.any((a) => a.isUploading) ||
      _videoSamples.any((v) => v.isUploading) ||
      _galleryPhotos.any((p) => p.isUploading) ||
      _newProfilePhoto != null;

  int get _activeUploadCount =>
      _audioSamples.where((a) => a.isUploading).length +
      _videoSamples.where((v) => v.isUploading).length +
      _galleryPhotos.where((p) => p.isUploading).length +
      (_newProfilePhoto != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    // Artists get 3 tabs (Audio, Video, Photos), Venues get 1 tab (Photos)
    _tabController = TabController(
      length: context.read<AuthProvider>().isArtist ? 3 : 1,
      vsync: this,
    );
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedia();
    });
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _audioPosition = pos);
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _playingAudioIndex = null;
            _audioPosition = Duration.zero;
          });
        }
        // Trigger rebuild for play/pause icon updates
        setState(() {});
      }
    });
  }

  @override
  void deactivate() {
    // Stop audio when navigating away to prevent decoder spam
    if (_audioPlayer.playing) {
      _audioPlayer.stop();
    }
    _playingAudioIndex = null;
    super.deactivate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    // Stop before dispose to ensure clean shutdown
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);

    try {
      final profile = context.read<ProfileProvider>();
      final auth = context.read<AuthProvider>();
      await profile.loadProfile(_isArtist);

      if (_isArtist) {
        final artist = profile.artist;
        if (artist != null) {
          // Use artist profile photo, fallback to Google/social photo
          _profilePhotoUrl = artist.profilePhoto ?? auth.user?.profilePhotoUrl;

          // Load audio samples
          _audioSamples.clear();
          for (final audio in artist.audioSamples) {
            _audioSamples.add(
              _AudioItem(
                id: audio.cloudinaryPublicId ?? DateTime.now().toString(),
                url: audio.url,
                title: audio.title ?? 'Untitled Track',
                durationSeconds: audio.durationSeconds ?? 0,
                isUploaded: true,
              ),
            );
          }

          // Load video samples
          _videoSamples.clear();
          for (final video in artist.videoSamples) {
            _videoSamples.add(
              _VideoItem(
                id: video.cloudinaryPublicId ?? DateTime.now().toString(),
                url: video.url,
                thumbnailUrl: video.thumbnailUrl,
                title: video.title ?? 'Untitled Video',
                durationSeconds: video.durationSeconds ?? 0,
                isUploaded: true,
              ),
            );
          }

          // Load gallery
          _galleryPhotos.clear();
          for (var i = 0; i < artist.galleryUrls.length; i++) {
            _galleryPhotos.add(
              _PhotoItem(
                id: 'gallery_$i',
                url: artist.galleryUrls[i],
                isUploaded: true,
              ),
            );
          }
        }
      } else {
        final venue = profile.venue;
        if (venue != null) {
          // Use venue profile photo, fallback to Google/social photo
          _profilePhotoUrl =
              venue.profilePhotoUrl ?? auth.user?.profilePhotoUrl;

          // Venues only have gallery photos
          _galleryPhotos.clear();
          final urls = venue.galleryUrls ?? [];
          for (var i = 0; i < urls.length; i++) {
            _galleryPhotos.add(
              _PhotoItem(id: 'gallery_$i', url: urls[i], isUploaded: true),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    setState(() => _isSaving = true);

    try {
      // Upload new profile photo if changed and capture the URL
      String? uploadedProfilePhotoUrl;
      if (_newProfilePhoto != null) {
        final uploadResult = await _uploadService.uploadProfilePhoto(
          _newProfilePhoto!.path,
        );
        uploadedProfilePhotoUrl = uploadResult.url;
      }

      if (_isArtist) {
        // Build audio samples list - always include even if empty to update
        final audioList = _audioSamples
            .where((a) => a.isUploaded && a.url != null)
            .map(
              (a) => AudioSample(
                url: a.url!,
                title: a.title,
                durationSeconds: a.durationSeconds,
                cloudinaryPublicId: a.id,
              ),
            )
            .toList();

        // Build video samples list - always include even if empty to update
        final videoList = _videoSamples
            .where((v) => v.isUploaded && v.url != null)
            .map(
              (v) => VideoSample(
                url: v.url!,
                title: v.title,
                thumbnailUrl: v.thumbnailUrl,
                durationSeconds: v.durationSeconds,
                cloudinaryPublicId: v.id,
              ),
            )
            .toList();

        // Build gallery URLs - always include even if empty to update
        final galleryUrls = _galleryPhotos
            .where((p) => p.isUploaded && p.url != null)
            .map((p) => p.url!)
            .toList();

        // Always send lists to ensure they're updated on server
        // Include profile photo URL if a new one was uploaded
        final request = UpdateArtistRequest(
          profilePhoto: uploadedProfilePhotoUrl,
          galleryUrls: galleryUrls, // Send even if empty
          audioSamples: audioList, // Send even if empty
          videoSamples: videoList, // Send even if empty
        );

        await _artistService.updateMyProfile(request);

        // Refresh profile provider to sync state
        if (mounted) {
          await context.read<ProfileProvider>().loadProfile(true);
        }
      } else {
        // Venue: Build gallery URLs from uploaded photos
        final galleryUrls = _galleryPhotos
            .where((p) => p.isUploaded && p.url != null)
            .map((p) => p.url!)
            .toList();

        // Update venue profile with new media
        final request = UpdateVenueRequest(
          profilePhotoUrl: uploadedProfilePhotoUrl,
          photoGallery: galleryUrls,
        );

        await _venueService.updateMyProfile(request);

        // Refresh profile provider to sync state
        if (mounted) {
          await context.read<ProfileProvider>().loadProfile(false);
        }
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Media saved successfully'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      nav.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to save: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: _isLoading
          ? _buildLoadingState(brightness)
          : _buildBody(brightness),
      floatingActionButton: _isLoading ? null : _buildFAB(brightness),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
    return AppBar(
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: AppColors.text(brightness),
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Media',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
          child: FilledButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.crimson,
              disabledBackgroundColor: AppColors.crimson.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 2,
              shadowColor: AppColors.crimson.withValues(alpha: 0.4),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
      bottom: _isArtist && !_isLoading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _buildTabBar(brightness),
            )
          : null,
    );
  }

  Widget _buildTabBar(Brightness brightness) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border(brightness), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.crimson,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSec(brightness),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: EdgeInsets.zero,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.audiotrack_rounded, size: 16),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text('Audio', overflow: TextOverflow.ellipsis),
                ),
                if (_audioSamples.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  _buildBadge(_audioSamples.length, brightness),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_rounded, size: 16),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text('Video', overflow: TextOverflow.ellipsis),
                ),
                if (_videoSamples.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  _buildBadge(_videoSamples.length, brightness),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library_rounded, size: 16),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text('Photos', overflow: TextOverflow.ellipsis),
                ),
                if (_galleryPhotos.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  _buildBadge(_galleryPhotos.length, brightness),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLoadingState(Brightness brightness) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.crimson),
    );
  }

  Widget _buildBody(Brightness brightness) {
    return Column(
      children: [
        _buildMediaHeader(brightness),
        if (_hasActiveUploads) _buildUploadQueue(brightness),
        Expanded(
          child: _isArtist
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAudioTab(brightness),
                    _buildVideoTab(brightness),
                    _buildPhotosTab(brightness),
                  ],
                )
              : _buildPhotosTab(brightness),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎵 AUDIO TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildAudioTab(Brightness brightness) {
    if (_audioSamples.isEmpty) {
      return _buildEmptyState(
        brightness,
        icon: Icons.audiotrack_rounded,
        title: 'No Audio Samples',
        subtitle: 'Add audio samples to showcase your music',
        actionLabel: 'Add Audio',
        onAction: _addAudio,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _audioSamples.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildAudioCard(_audioSamples[index], index, brightness),
    );
  }

  Widget _buildAudioCard(_AudioItem audio, int index, Brightness brightness) {
    final isPlaying = _playingAudioIndex == index && _audioPlayer.playing;
    final progress = _audioDuration.inMilliseconds > 0
        ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showNowPlaying(index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPlaying
                  ? AppColors.crimson.withValues(alpha: 0.5)
                  : AppColors.border(brightness),
              width: isPlaying ? 2 : 1,
            ),
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Play/Pause Button
                  GestureDetector(
                    onTap: () => _toggleAudioPlayback(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Title & Duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio.title,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatDuration(isPlaying ? _audioPosition : Duration.zero)} / ${_formatDuration(_audioDuration.inSeconds > 0 ? _audioDuration : Duration(seconds: audio.durationSeconds))}',
                          style: TextStyle(
                            color: isPlaying
                                ? AppColors.crimson
                                : AppColors.textSec(brightness),
                            fontSize: 13,
                            fontWeight: isPlaying
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Upload progress or delete button
                  if (audio.isUploading)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: audio.uploadProgress,
                        strokeWidth: 3,
                        color: AppColors.crimson,
                        backgroundColor: AppColors.border(brightness),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background(brightness),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.textSec(brightness),
                          size: 20,
                        ),
                        onPressed: () => _confirmDeleteAudio(index),
                        splashRadius: 20,
                      ),
                    ),
                ],
              ),

              // Progress bar - always show for better UX
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isPlaying ? progress : 0.0,
                  backgroundColor: AppColors.border(brightness),
                  color: AppColors.crimson,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show Spotify-style Now Playing sheet
  void _showNowPlaying(int index) {
    final audio = _audioSamples[index];
    final brightness = Theme.of(context).brightness;

    // Start playing if not already
    if (_playingAudioIndex != index) {
      _toggleAudioPlayback(index);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NowPlayingSheet(
        audio: audio,
        index: index,
        audioPlayer: _audioPlayer,
        audioSamplesLength: _audioSamples.length,
        brightness: brightness,
        onTogglePlayback: () => _toggleAudioPlayback(index),
        onNavigateTrack: (newIndex) {
          Navigator.pop(ctx);
          _showNowPlaying(newIndex);
        },
      ),
    );
  }

  Future<void> _toggleAudioPlayback(int index) async {
    final audio = _audioSamples[index];

    if (_playingAudioIndex == index && _audioPlayer.playing) {
      // Currently playing this - pause it
      await _audioPlayer.pause();
      // Keep the index so we can resume
    } else if (_playingAudioIndex == index && !_audioPlayer.playing) {
      // Paused on this track - resume
      await _audioPlayer.play();
    } else {
      // Different track or no track - stop current and play new
      await _audioPlayer.stop();
      setState(() {
        _playingAudioIndex = index;
        _audioPosition = Duration.zero;
      });

      if (audio.url != null) {
        try {
          await _audioPlayer.setUrl(audio.url!);
          _audioDuration = _audioPlayer.duration ?? Duration.zero;
          await _audioPlayer.play();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to play audio: $e'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            setState(() => _playingAudioIndex = null);
          }
        }
      }
    }
  }

  void _confirmDeleteAudio(int index) {
    final brightness = Theme.of(context).brightness;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        title: Text(
          'Delete Audio?',
          style: TextStyle(color: AppColors.text(brightness)),
        ),
        content: Text(
          'This will remove "${_audioSamples[index].title}" from your profile.',
          style: TextStyle(color: AppColors.textSec(brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                if (_playingAudioIndex == index) {
                  _audioPlayer.stop();
                  _playingAudioIndex = null;
                }
                _audioSamples.removeAt(index);
              });
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAudio() async {
    try {
      const XTypeGroup audioTypeGroup = XTypeGroup(
        label: 'audio',
        extensions: <String>['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'],
        mimeTypes: <String>['audio/*'],
      );
      final XFile? result = await openFile(
        acceptedTypeGroups: <XTypeGroup>[audioTypeGroup],
      );

      if (result != null) {
        final filePath = result.path;

        // Add to list with uploading state
        final newAudio = _AudioItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          localPath: filePath,
          title: result.name.split('.').first,
          isUploading: true,
        );

        setState(() => _audioSamples.add(newAudio));
        final index = _audioSamples.length - 1;

        // Upload
        try {
          final response = await _uploadService.uploadAudio(
            filePath,
            onProgress: (sent, total) {
              if (!mounted) return;
              final progress = total > 0 ? sent / total : 0.0;
              setState(() {
                _audioSamples[index] = _AudioItem(
                  id: newAudio.id,
                  localPath: newAudio.localPath,
                  title: newAudio.title,
                  durationSeconds: newAudio.durationSeconds,
                  isUploading: true,
                  uploadProgress: progress,
                );
              });
            },
          );

          if (mounted) {
            setState(() {
              _audioSamples[index] = _AudioItem(
                id: response.publicId,
                url: response.url,
                title: newAudio.title,
                durationSeconds: 0,
                isUploaded: true,
              );
            });
          }
        } on UploadException catch (e) {
          if (mounted) {
            setState(() => _audioSamples.removeAt(index));
            final msg = ScaffoldMessenger.of(context);
            msg.showSnackBar(
              SnackBar(
                content: Text(e.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: e.code == 'AUTH_EXPIRED'
                    ? SnackBarAction(
                        label: 'Login',
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (_) => false);
                        },
                      )
                    : null,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() => _audioSamples.removeAt(index));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload audio: $e'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Audio picker error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎬 VIDEO TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildVideoTab(Brightness brightness) {
    if (_videoSamples.isEmpty) {
      return _buildEmptyState(
        brightness,
        icon: Icons.videocam_rounded,
        title: 'No Video Samples',
        subtitle: 'Add video samples to show your performances',
        actionLabel: 'Add Video',
        onAction: _addVideo,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 12,
      ),
      itemCount: _videoSamples.length,
      itemBuilder: (context, index) =>
          _buildVideoCard(_videoSamples[index], index, brightness),
    );
  }

  Widget _buildVideoCard(_VideoItem video, int index, Brightness brightness) {
    return GestureDetector(
      onTap: () => _previewVideo(video),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.border(brightness), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (video.thumbnailUrl != null)
              Image.network(
                video.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _buildVideoPlaceholder(brightness),
              )
            else
              _buildVideoPlaceholder(brightness),

            // Play overlay
            if (!video.isUploading)
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

            // Upload progress
            if (video.isUploading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    value: video.uploadProgress > 0
                        ? video.uploadProgress
                        : null,
                    color: AppColors.crimson,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),

            // Delete button
            if (!video.isUploading)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _confirmDeleteVideo(index),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),

            // Duration badge
            if (video.durationSeconds > 0)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDuration(Duration(seconds: video.durationSeconds)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(Brightness brightness) {
    return Container(
      color: AppColors.charcoal,
      child: Icon(
        Icons.videocam_rounded,
        color: AppColors.textSec(brightness),
        size: 40,
      ),
    );
  }

  void _previewVideo(_VideoItem video) {
    if (video.url == null) return;

    // Open video in dialog
    showDialog(
      context: context,
      builder: (ctx) => _VideoPreviewDialog(videoUrl: video.url!),
    );
  }

  void _confirmDeleteVideo(int index) {
    final brightness = Theme.of(context).brightness;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        title: Text(
          'Delete Video?',
          style: TextStyle(color: AppColors.text(brightness)),
        ),
        content: Text(
          'This will remove the video from your profile.',
          style: TextStyle(color: AppColors.textSec(brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _videoSamples.removeAt(index));
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addVideo() async {
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (file == null) return;

      // Add to list with uploading state
      final newVideo = _VideoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        localPath: file.path,
        title: file.name.split('.').first,
        isUploading: true,
      );

      setState(() => _videoSamples.add(newVideo));
      final index = _videoSamples.length - 1;

      // Upload
      try {
        final response = await _uploadService.uploadVideo(
          file.path,
          onProgress: (sent, total) {
            if (!mounted) return;
            final progress = total > 0 ? sent / total : 0.0;
            setState(() {
              _videoSamples[index] = _VideoItem(
                id: newVideo.id,
                localPath: newVideo.localPath,
                title: newVideo.title,
                durationSeconds: newVideo.durationSeconds,
                isUploading: true,
                uploadProgress: progress,
              );
            });
          },
        );

        if (mounted) {
          setState(() {
            _videoSamples[index] = _VideoItem(
              id: response.publicId,
              url: response.url,
              thumbnailUrl: _generateVideoThumbnailUrl(response.url),
              title: newVideo.title,
              durationSeconds: 0,
              isUploaded: true,
            );
          });
        }
      } on UploadException catch (e) {
        if (mounted) {
          setState(() => _videoSamples.removeAt(index));
          final msg = ScaffoldMessenger.of(context);
          msg.showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: e.code == 'AUTH_EXPIRED'
                  ? SnackBarAction(
                      label: 'Login',
                      textColor: Colors.white,
                      onPressed: () {
                        // Navigate to login
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (_) => false);
                      },
                    )
                  : null,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _videoSamples.removeAt(index));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload video: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Video picker error: $e');
    }
  }

  String? _generateVideoThumbnailUrl(String videoUrl) {
    // Cloudinary auto-generates thumbnails - replace video with jpg
    if (videoUrl.contains('cloudinary.com')) {
      return videoUrl
          .replaceAll(
            '/video/upload/',
            '/video/upload/so_0,w_400,h_300,c_fill/',
          )
          .replaceAll('.mp4', '.jpg')
          .replaceAll('.mov', '.jpg')
          .replaceAll('.webm', '.jpg');
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📸 PHOTOS TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPhotosTab(Brightness brightness) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo Hero
          _buildProfilePhotoSection(brightness),

          const SizedBox(height: 28),

          // Gallery Section
          Text(
            'Gallery',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isArtist
                ? 'Add photos to showcase your performances and style'
                : 'Add photos to showcase your venue and atmosphere',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          if (_galleryPhotos.isEmpty)
            _buildEmptyState(
              brightness,
              icon: Icons.photo_library_rounded,
              title: 'No Gallery Photos',
              subtitle: 'Upload photos to make your profile stand out',
              actionLabel: 'Add Photos',
              onAction: _addGalleryPhoto,
            )
          else
            _buildGalleryGrid(brightness),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection(Brightness brightness) {
    final hasPhoto =
        _newProfilePhoto != null || (_profilePhotoUrl?.isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border(brightness), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_circle_outlined,
                color: AppColors.crimson,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Profile Photo',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Center(
            child: GestureDetector(
              onTap: _changeProfilePhoto,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.charcoal,
                      border: Border.all(
                        color: hasPhoto
                            ? AppColors.crimson.withValues(alpha: 0.5)
                            : AppColors.border(brightness),
                        width: 3,
                      ),
                      image: hasPhoto
                          ? DecorationImage(
                              image: _newProfilePhoto != null
                                  ? FileImage(_newProfilePhoto!)
                                  : NetworkImage(_profilePhotoUrl!)
                                        as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasPhoto
                        ? Icon(
                            Icons.person_rounded,
                            color: AppColors.textSec(brightness),
                            size: 48,
                          )
                        : null,
                  ),

                  // Edit badge
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface(brightness),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'Tap to change photo',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildImageSourceSheet(ctx),
    );

    if (source == null) return;

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file != null && mounted) {
        setState(() => _newProfilePhoto = File(file.path));
      }
    } on PlatformException catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  Widget _buildGalleryGrid(Brightness brightness) {
    // 3-column grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _galleryPhotos.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        if (index == _galleryPhotos.length) {
          // Add button
          return _buildAddPhotoButton(brightness);
        }
        return _buildGalleryPhotoCard(_galleryPhotos[index], index, brightness);
      },
    );
  }

  Widget _buildAddPhotoButton(Brightness brightness) {
    return GestureDetector(
      onTap: _addGalleryPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          border: Border.all(color: AppColors.border(brightness), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.crimson,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryPhotoCard(
    _PhotoItem photo,
    int index,
    Brightness brightness,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        border: Border.all(color: AppColors.border(brightness), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (photo.localPath != null)
            Image.file(File(photo.localPath!), fit: BoxFit.cover)
          else if (photo.url != null)
            Image.network(
              photo.url!,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                color: AppColors.charcoal,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSec(brightness),
                ),
              ),
            ),

          // Upload overlay
          if (photo.isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: CircularProgressIndicator(
                  value: photo.uploadProgress > 0 ? photo.uploadProgress : null,
                  color: AppColors.crimson,
                  strokeWidth: 2,
                ),
              ),
            ),

          // Delete button
          if (!photo.isUploading)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _confirmDeletePhoto(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addGalleryPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildImageSourceSheet(ctx),
    );

    if (source == null) return;

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file == null) return;

      // Add to list with uploading state
      final newPhoto = _PhotoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        localPath: file.path,
        isUploading: true,
      );

      setState(() => _galleryPhotos.add(newPhoto));
      final index = _galleryPhotos.length - 1;

      // Upload
      try {
        final response = await _uploadService.uploadGalleryImage(
          file.path,
          index: index,
          onProgress: (sent, total) {
            if (!mounted) return;
            final progress = total > 0 ? sent / total : 0.0;
            setState(() {
              _galleryPhotos[index] = _PhotoItem(
                id: newPhoto.id,
                localPath: newPhoto.localPath,
                isUploading: true,
                uploadProgress: progress,
              );
            });
          },
        );

        if (mounted) {
          setState(() {
            _galleryPhotos[index] = _PhotoItem(
              id: response.publicId,
              url: response.url,
              isUploaded: true,
            );
          });
        }
      } on UploadException catch (e) {
        if (mounted) {
          setState(() => _galleryPhotos.removeAt(index));
          final msg = ScaffoldMessenger.of(context);
          msg.showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: e.code == 'AUTH_EXPIRED'
                  ? SnackBarAction(
                      label: 'Login',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (_) => false);
                      },
                    )
                  : null,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _galleryPhotos.removeAt(index));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload photo: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  void _confirmDeletePhoto(int index) {
    final brightness = Theme.of(context).brightness;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        title: Text(
          'Delete Photo?',
          style: TextStyle(color: AppColors.text(brightness)),
        ),
        content: Text(
          'This will remove the photo from your gallery.',
          style: TextStyle(color: AppColors.textSec(brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _galleryPhotos.removeAt(index));
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔧 HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMediaHeader(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.crimson.withValues(alpha: 0.12),
              AppColors.crimson.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
              ),
              child: const Icon(
                Icons.perm_media_rounded,
                color: AppColors.crimson,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isArtist ? 'Your Media Portfolio' : 'Venue Media',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isArtist
                        ? 'Showcase your sound, stage, and visuals'
                        : 'Highlight your venue with professional media',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.crimson,
                borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
              ),
              child: Text(
                _isArtist
                    ? '${_audioSamples.length + _videoSamples.length + _galleryPhotos.length} items'
                    : '${_galleryPhotos.length} items',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadQueue(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.crimson,
                backgroundColor: AppColors.border(brightness),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Uploading $_activeUploadCount item${_activeUploadCount == 1 ? '' : 's'}...'
                ' You can keep browsing while we finish.',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    Brightness brightness, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.crimson, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(Brightness brightness) {
    return FloatingActionButton(
      onPressed: _showAddMediaSheet,
      backgroundColor: AppColors.crimson,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  void _showAddMediaSheet() {
    final brightness = Theme.of(context).brightness;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.textSec(
                        brightness,
                      ).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Add Media',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                // Options
                if (_isArtist) ...[
                  _buildMediaOption(
                    ctx,
                    icon: Icons.audiotrack_rounded,
                    title: 'Audio Sample',
                    subtitle: 'MP3, WAV, M4A up to 10MB',
                    onTap: () {
                      Navigator.pop(ctx);
                      _tabController.animateTo(0);
                      _addAudio();
                    },
                    brightness: brightness,
                  ),
                  const SizedBox(height: 10),
                  _buildMediaOption(
                    ctx,
                    icon: Icons.videocam_rounded,
                    title: 'Video Sample',
                    subtitle: 'MP4, MOV up to 50MB',
                    onTap: () {
                      Navigator.pop(ctx);
                      _tabController.animateTo(1);
                      _addVideo();
                    },
                    brightness: brightness,
                  ),
                  const SizedBox(height: 10),
                ],
                _buildMediaOption(
                  ctx,
                  icon: Icons.photo_library_rounded,
                  title: 'Gallery Photo',
                  subtitle: 'JPG, PNG up to 10MB',
                  onTap: () {
                    Navigator.pop(ctx);
                    if (_isArtist) {
                      _tabController.animateTo(2);
                    }
                    _addGalleryPhoto();
                  },
                  brightness: brightness,
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaOption(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Brightness brightness,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surface(brightness),
                AppColors.surface(brightness).withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(brightness), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.crimson.withValues(alpha: 0.2),
                      AppColors.crimson.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.crimson, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSec(brightness),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceSheet(BuildContext ctx) {
    final brightness = Theme.of(ctx).brightness;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSection),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(brightness),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Choose Source',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildSourceButton(
                      ctx,
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      source: ImageSource.camera,
                      brightness: brightness,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSourceButton(
                      ctx,
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      source: ImageSource.gallery,
                      brightness: brightness,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required ImageSource source,
    required Brightness brightness,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(ctx, source),
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            border: Border.all(color: AppColors.border(brightness), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.crimson, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// 📦 DATA CLASSES
// ════════════════════════════════════════════════════════════════════════════════

class _AudioItem {
  final String id;
  final String? localPath;
  final String? url;
  final String title;
  final int durationSeconds;
  final bool isUploading;
  final double uploadProgress;
  final bool isUploaded;

  _AudioItem({
    required this.id,
    this.localPath,
    this.url,
    this.title = 'Untitled',
    this.durationSeconds = 0,
    this.isUploading = false,
    // ignore: unused_element_parameter
    this.uploadProgress = 0,
    this.isUploaded = false,
  });
}

class _VideoItem {
  final String id;
  final String? localPath;
  final String? url;
  final String? thumbnailUrl;
  final String title;
  final int durationSeconds;
  final bool isUploading;
  final double uploadProgress;
  final bool isUploaded;

  _VideoItem({
    required this.id,
    this.localPath,
    this.url,
    this.thumbnailUrl,
    this.title = 'Untitled',
    this.durationSeconds = 0,
    this.isUploading = false,
    // ignore: unused_element_parameter
    this.uploadProgress = 0,
    this.isUploaded = false,
  });
}

class _PhotoItem {
  final String id;
  final String? localPath;
  final String? url;
  final bool isUploading;
  final double uploadProgress;
  final bool isUploaded;

  _PhotoItem({
    required this.id,
    this.localPath,
    this.url,
    this.isUploading = false,
    // ignore: unused_element_parameter
    this.uploadProgress = 0,
    this.isUploaded = false,
  });
}

// ════════════════════════════════════════════════════════════════════════════════
// 🎵 NOW PLAYING SHEET (StreamBuilder-based for real-time updates)
// ════════════════════════════════════════════════════════════════════════════════

class _NowPlayingSheet extends StatelessWidget {
  final _AudioItem audio;
  final int index;
  final AudioPlayer audioPlayer;
  final int audioSamplesLength;
  final Brightness brightness;
  final VoidCallback onTogglePlayback;
  final Function(int) onNavigateTrack;

  const _NowPlayingSheet({
    required this.audio,
    required this.index,
    required this.audioPlayer,
    required this.audioSamplesLength,
    required this.brightness,
    required this.onTogglePlayback,
    required this.onNavigateTrack,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: StreamBuilder<Duration>(
          stream: audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            return StreamBuilder<PlayerState>(
              stream: audioPlayer.playerStateStream,
              builder: (context, playerStateSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final playerState = playerStateSnapshot.data;
                final isPlaying = playerState?.playing ?? false;
                final duration =
                    audioPlayer.duration ??
                    Duration(seconds: audio.durationSeconds);
                final progress = duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;

                return Column(
                  children: [
                    // Drag handle
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border(brightness),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Album art placeholder with waveform
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.crimson.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.crimson.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Waveform visualization
                          CustomPaint(
                            size: const Size(160, 80),
                            painter: _WaveformPainter(
                              progress: progress,
                              color: AppColors.crimson,
                              backgroundColor: AppColors.crimson.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          // Music icon overlay
                          Icon(
                            Icons.music_note_rounded,
                            color: AppColors.crimson.withValues(alpha: 0.5),
                            size: 64,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Track title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        audio.title,
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Artist name
                    Text(
                      'Your Track',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 16,
                      ),
                    ),

                    const Spacer(),

                    // Progress slider - SEEKABLE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.crimson,
                              inactiveTrackColor: AppColors.crimson.withValues(
                                alpha: 0.2,
                              ),
                              thumbColor: AppColors.crimson,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                              trackHeight: 6,
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (value) {
                                final newPosition = Duration(
                                  milliseconds:
                                      (value * duration.inMilliseconds).toInt(),
                                );
                                audioPlayer.seek(newPosition);
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  color: AppColors.textSec(brightness),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: TextStyle(
                                  color: AppColors.textSec(brightness),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Skip back 10s
                        IconButton(
                          onPressed: () {
                            final newPos =
                                position - const Duration(seconds: 10);
                            audioPlayer.seek(
                              newPos < Duration.zero ? Duration.zero : newPos,
                            );
                          },
                          icon: Icon(
                            Icons.replay_10_rounded,
                            color: AppColors.text(brightness),
                            size: 32,
                          ),
                        ),

                        // Previous track
                        IconButton(
                          onPressed: index > 0
                              ? () => onNavigateTrack(index - 1)
                              : null,
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: index > 0
                                ? AppColors.text(brightness)
                                : AppColors.textSec(
                                    brightness,
                                  ).withValues(alpha: 0.3),
                            size: 36,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Play/Pause
                        GestureDetector(
                          onTap: onTogglePlayback,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.crimson,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.crimson.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Next track
                        IconButton(
                          onPressed: index < audioSamplesLength - 1
                              ? () => onNavigateTrack(index + 1)
                              : null,
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: index < audioSamplesLength - 1
                                ? AppColors.text(brightness)
                                : AppColors.textSec(
                                    brightness,
                                  ).withValues(alpha: 0.3),
                            size: 36,
                          ),
                        ),

                        // Skip forward 10s
                        IconButton(
                          onPressed: () {
                            final newPos =
                                position + const Duration(seconds: 10);
                            audioPlayer.seek(
                              newPos > duration ? duration : newPos,
                            );
                          },
                          icon: Icon(
                            Icons.forward_10_rounded,
                            color: AppColors.text(brightness),
                            size: 32,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// 🎵 WAVEFORM PAINTER
// ════════════════════════════════════════════════════════════════════════════════

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _WaveformPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 32;
    final barWidth = size.width / (barCount * 2);
    final maxHeight = size.height;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final activePaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (var i = 0; i < barCount; i++) {
      // Generate pseudo-random heights for waveform effect
      final seed = (i * 7 + 3) % 11;
      final heightFactor = 0.3 + (seed / 11) * 0.7;
      final barHeight = maxHeight * heightFactor;

      final x = i * (barWidth * 2) + barWidth;
      final top = (maxHeight - barHeight) / 2;
      final bottom = top + barHeight;

      // Draw background bar
      canvas.drawLine(Offset(x, top), Offset(x, bottom), backgroundPaint);

      // Draw active portion based on progress
      final progressX = size.width * progress;
      if (x <= progressX) {
        canvas.drawLine(Offset(x, top), Offset(x, bottom), activePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// �🎬 VIDEO PREVIEW DIALOG
// ════════════════════════════════════════════════════════════════════════════════

class _VideoPreviewDialog extends StatefulWidget {
  final String videoUrl;

  const _VideoPreviewDialog({required this.videoUrl});

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: AspectRatio(
        aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized)
              VideoPlayer(_controller)
            else
              const Center(
                child: CircularProgressIndicator(color: AppColors.crimson),
              ),

            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
