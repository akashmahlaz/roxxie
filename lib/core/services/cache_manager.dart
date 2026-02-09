/// 🗂️ GIGMATCH Cache Manager
/// Custom cache managers for different image types with separate buckets
library;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache manager for avatar/profile images
/// - Short staleness (7 days) since profiles update frequently
/// - Max 500 files (covers all matched/discovered profiles)
class AvatarCacheManager extends CacheManager with ImageCacheManager {
  static const String key = 'gigmatchAvatarCache';

  static final AvatarCacheManager _instance = AvatarCacheManager._();
  factory AvatarCacheManager() => _instance;

  AvatarCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 500,
          ),
        );
}

/// Cache manager for gallery/media images
/// - Medium staleness (3 days) since gallery images are larger
/// - Max 200 files to manage storage
class GalleryCacheManager extends CacheManager with ImageCacheManager {
  static const String key = 'gigmatchGalleryCache';

  static final GalleryCacheManager _instance = GalleryCacheManager._();
  factory GalleryCacheManager() => _instance;

  GalleryCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 3),
            maxNrOfCacheObjects: 200,
          ),
        );
}

/// Cache manager for thumbnail images (video thumbnails, story previews)
/// - Short staleness (2 days)
/// - Max 300 files
class ThumbnailCacheManager extends CacheManager with ImageCacheManager {
  static const String key = 'gigmatchThumbnailCache';

  static final ThumbnailCacheManager _instance = ThumbnailCacheManager._();
  factory ThumbnailCacheManager() => _instance;

  ThumbnailCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 2),
            maxNrOfCacheObjects: 300,
          ),
        );
}
