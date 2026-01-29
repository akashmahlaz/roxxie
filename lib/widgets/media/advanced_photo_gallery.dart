/// 📷 Advanced Photo Gallery Widget
///
/// A beautiful gallery with:
/// - Grid or carousel layout
/// - Full-screen lightbox with zoom/pan
/// - Smooth transitions with Hero
/// - Material 3 design
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/theme.dart';

/// Photo gallery layout options
enum GalleryLayout { grid, carousel, featured }

/// Advanced Photo Gallery with Material 3 design
class AdvancedPhotoGallery extends StatefulWidget {
  final List<String> photos;
  final GalleryLayout layout;
  final int crossAxisCount;
  final double aspectRatio;

  const AdvancedPhotoGallery({
    super.key,
    required this.photos,
    this.layout = GalleryLayout.grid,
    this.crossAxisCount = 3,
    this.aspectRatio = 1.0,
  });

  @override
  State<AdvancedPhotoGallery> createState() => _AdvancedPhotoGalleryState();
}

class _AdvancedPhotoGalleryState extends State<AdvancedPhotoGallery> {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (widget.photos.isEmpty) {
      return _buildEmptyState(brightness);
    }

    return switch (widget.layout) {
      GalleryLayout.grid => _buildGridGallery(brightness),
      GalleryLayout.carousel => _buildCarouselGallery(brightness),
      GalleryLayout.featured => _buildFeaturedGallery(brightness),
    };
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
              Icons.photo_library_outlined,
              size: 48,
              color: AppColors.textSec(brightness),
            ),
            const SizedBox(height: 16),
            Text(
              'No photos available',
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
  // GRID GALLERY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildGridGallery(Brightness brightness) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: widget.aspectRatio,
      ),
      itemCount: widget.photos.length > 6 ? 6 : widget.photos.length,
      itemBuilder: (context, index) {
        final isLastWithMore = index == 5 && widget.photos.length > 6;

        return GestureDetector(
          onTap: () => _openLightbox(index),
          child: Hero(
            tag: 'gallery-photo-$index',
            child: Card.outlined(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.divider(brightness)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.photos[index],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _buildPlaceholder(brightness),
                    errorWidget: (_, _, _) => _buildErrorWidget(brightness),
                  ),
                  if (isLastWithMore)
                    Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Center(
                        child: Text(
                          '+${widget.photos.length - 6}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CAROUSEL GALLERY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCarouselGallery(Brightness brightness) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openLightbox(index),
            child: Hero(
              tag: 'gallery-photo-$index',
              child: Card.outlined(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.divider(brightness)),
                ),
                child: SizedBox(
                  width: 140,
                  child: CachedNetworkImage(
                    imageUrl: widget.photos[index],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _buildPlaceholder(brightness),
                    errorWidget: (_, _, _) => _buildErrorWidget(brightness),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FEATURED GALLERY (Large first image + grid)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFeaturedGallery(Brightness brightness) {
    return Column(
      children: [
        // Featured image
        if (widget.photos.isNotEmpty)
          GestureDetector(
            onTap: () => _openLightbox(0),
            child: Hero(
              tag: 'gallery-photo-0',
              child: Card.outlined(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.divider(brightness)),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: widget.photos[0],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _buildPlaceholder(brightness),
                    errorWidget: (_, _, _) => _buildErrorWidget(brightness),
                  ),
                ),
              ),
            ),
          ),

        // Thumbnail grid
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length - 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final photoIndex = index + 1;
                return GestureDetector(
                  onTap: () => _openLightbox(photoIndex),
                  child: Hero(
                    tag: 'gallery-photo-$photoIndex',
                    child: Card.outlined(
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.divider(brightness)),
                      ),
                      child: SizedBox(
                        width: 70,
                        child: CachedNetworkImage(
                          imageUrl: widget.photos[photoIndex],
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _buildPlaceholder(brightness),
                          errorWidget: (_, _, _) =>
                              _buildErrorWidget(brightness),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPlaceholder(Brightness brightness) {
    return Container(
      color: AppColors.surface(brightness),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.crimson,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Brightness brightness) {
    return Container(
      color: AppColors.surface(brightness),
      child: Icon(
        Icons.broken_image_rounded,
        color: AppColors.textSec(brightness),
      ),
    );
  }

  void _openLightbox(int initialIndex) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _PhotoLightbox(photos: widget.photos, initialIndex: initialIndex),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PHOTO LIGHTBOX
// ══════════════════════════════════════════════════════════════════════════════

class _PhotoLightbox extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoLightbox({required this.photos, required this.initialIndex});

  @override
  State<_PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<_PhotoLightbox> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Photos
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                HapticFeedback.selectionClick();
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: 'gallery-photo-$index',
                      child: CachedNetworkImage(
                        imageUrl: widget.photos[index],
                        fit: BoxFit.contain,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.5,
                              ),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${widget.photos.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            onPressed: () {
                              // Share functionality
                            },
                            icon: const Icon(Icons.share_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.5,
                              ),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Thumbnail strip
                    if (widget.photos.length > 1)
                      Container(
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: widget.photos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isActive = index == _currentIndex;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.crimson
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.photos[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
