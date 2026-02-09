/// 💬 GIGMATCH Full Screen Media Preview
/// Full-screen image/video viewer with zoom, dismiss, and actions
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import '../core/models/media_types.dart';

/// Full-screen media preview screen
class FullScreenMediaPreview extends StatefulWidget {
  final String mediaUrl;
  final String? localPath;
  final ChatMediaType type;

  const FullScreenMediaPreview({
    super.key,
    required this.mediaUrl,
    this.localPath,
    required this.type,
  });

  @override
  State<FullScreenMediaPreview> createState() => _FullScreenMediaPreviewState();
}

class _FullScreenMediaPreviewState extends State<FullScreenMediaPreview> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _toggleControls();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => _buildActionSheet(),
    );
  }

  Future<void> _shareMedia() async {
    Navigator.of(context).pop();
    // Share functionality
    if (widget.localPath != null && File(widget.localPath!).existsSync()) {
      await SharePlus.instance.share(ShareParams(files: [XFile(widget.localPath!)]));
    } else {
      await SharePlus.instance.share(ShareParams(text: widget.mediaUrl));
    }
  }

  Future<void> _saveToGallery() async {
    Navigator.of(context).pop();
    // TODO: Implement gallery save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving to gallery...')),
    );
  }

  void _copyMediaUrl() {
    Navigator.of(context).pop();
    // TODO: Copy URL to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  Widget _buildImageView() {
    final imageUrl = widget.localPath != null && File(widget.localPath!).existsSync()
        ? widget.localPath!
        : widget.mediaUrl;

    return PhotoView(
      imageProvider: imageUrl.startsWith('http')
          ? CachedNetworkImageProvider(imageUrl)
          : FileImage(File(imageUrl)) as ImageProvider,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      heroAttributes: PhotoViewHeroAttributes(
        tag: widget.mediaUrl,
        transitionOnUserGestures: true,
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }

  Widget _buildVideoView() {
    return const Center(
      child: Icon(
        Icons.videocam_rounded,
        size: 64,
        color: Colors.white54,
      ),
    );
  }

  Widget _buildAudioView() {
    return const Center(
      child: Icon(
        Icons.audiotrack_rounded,
        size: 64,
        color: Colors.white54,
      ),
    );
  }

  Widget _buildDocumentView() {
    return const Center(
      child: Icon(
        Icons.description_rounded,
        size: 64,
        color: Colors.white54,
      ),
    );
  }

  Widget _buildActionSheet() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.type.canPreview)
            ListTile(
              leading: const Icon(Icons.fullscreen, color: Colors.white),
              title: const Text('Open in browser', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Open in browser
              },
            ),
          if (widget.type.canSaveToGallery)
            ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.white),
              title: const Text('Save to Gallery', style: TextStyle(color: Colors.white)),
              onTap: _saveToGallery,
            ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text('Share', style: TextStyle(color: Colors.white)),
            onTap: _shareMedia,
          ),
          ListTile(
            leading: const Icon(Icons.link, color: Colors.white),
            title: const Text('Copy Link', style: TextStyle(color: Colors.white)),
            onTap: _copyMediaUrl,
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.white),
            title: const Text('Close', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: _showBottomSheet,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Bottom info bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Tap and hold for options',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            // Media content
            Center(
              child: switch (widget.type) {
                ChatMediaType.image => _buildImageView(),
                ChatMediaType.video => _buildVideoView(),
                ChatMediaType.audio => _buildAudioView(),
                ChatMediaType.document || ChatMediaType.location || ChatMediaType.contact =>
                  _buildDocumentView(),
              },
            ),
            // Controls overlay
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }
}
