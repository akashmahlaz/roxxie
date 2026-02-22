/// 📱 GIGMATCH Feed Models
/// Models for Instagram-style posts and stories
library;

import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════════════════════
// POST MEDIA
// ═══════════════════════════════════════════════════════════════════════════

enum MediaType { image, video }

class PostMedia {
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final String? publicId;
  final int? width;
  final int? height;
  final int? duration;
  final int order;

  const PostMedia({
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.publicId,
    this.width,
    this.height,
    this.duration,
    this.order = 0,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      type: json['type'] == 'video' ? MediaType.video : MediaType.image,
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      publicId: json['publicId'],
      width: json['width'],
      height: json['height'],
      duration: json['duration'],
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == MediaType.video ? 'video' : 'image',
      'url': url,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (publicId != null) 'publicId': publicId,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration,
      'order': order,
    };
  }

  double get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return width! / height!;
    }
    return 1.0; // Default square
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POST AUTHOR
// ═══════════════════════════════════════════════════════════════════════════

class PostAuthor {
  final String id;
  final String fullName;
  final String role;
  final String? profilePhoto;
  final String? displayName;
  final bool isVerified;

  /// The artist profile ID (NOT the user account ID).
  /// Use this for navigating to /artist/:id routes.
  final String? artistId;

  /// The venue profile ID (NOT the user account ID).
  /// Use this for navigating to /venue/:id routes.
  final String? venueId;

  const PostAuthor({
    required this.id,
    required this.fullName,
    required this.role,
    this.profilePhoto,
    this.displayName,
    this.isVerified = false,
    this.artistId,
    this.venueId,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    final artistProfile = json['artistProfile'] as Map<String, dynamic>?;
    final venueProfile = json['venueProfile'] as Map<String, dynamic>?;

    // DEBUG: Log the raw JSON to see what we're receiving
    debugPrint('🔍 PostAuthor.fromJson - raw json keys: ${json.keys}');
    debugPrint('🔍 PostAuthor.fromJson - artistProfile: $artistProfile');
    debugPrint('🔍 PostAuthor.fromJson - venueProfile: $venueProfile');

    String? profilePhoto;
    String? displayName;
    bool isVerified = false;
    String? artistId;
    String? venueId;

    if (artistProfile != null) {
      profilePhoto = artistProfile['profilePhoto'];
      displayName = artistProfile['stageName'] ?? artistProfile['displayName'];
      isVerified = artistProfile['isVerified'] ?? false;
      // Extract the artist profile ID for navigation
      artistId =
          artistProfile['_id']?.toString() ?? artistProfile['id']?.toString();
      debugPrint('🔍 PostAuthor - extracted artistId from profile: $artistId');
    }
    if (venueProfile != null) {
      profilePhoto ??= venueProfile['profilePhotoUrl'];
      displayName ??= venueProfile['name'];
      isVerified = isVerified || (venueProfile['isVerified'] ?? false);
      // Extract the venue profile ID for navigation
      venueId =
          venueProfile['_id']?.toString() ?? venueProfile['id']?.toString();
      debugPrint('🔍 PostAuthor - extracted venueId from profile: $venueId');
    }

    final result = PostAuthor(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'artist',
      profilePhoto: profilePhoto,
      displayName: displayName,
      isVerified: isVerified,
      artistId: artistId,
      venueId: venueId,
    );
    
    debugPrint('🔍 PostAuthor created - userId: ${result.id}, artistId: ${result.artistId}, venueId: ${result.venueId}, role: ${result.role}');
    
    return result;
  }

  String get name => displayName ?? fullName;
}

// ═══════════════════════════════════════════════════════════════════════════
// POST COMMENT
// ═══════════════════════════════════════════════════════════════════════════

class PostComment {
  final String id;
  final String userId;
  final String text;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;
  final PostAuthor? author;

  const PostComment({
    required this.id,
    required this.userId,
    required this.text,
    this.likeCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.author,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      text: json['text'] ?? '',
      likeCount: (json['likes'] as List?)?.length ?? 0,
      isLiked: false, // Will be enriched separately if needed
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      author: json['userId'] is Map
          ? PostAuthor.fromJson(json['userId'])
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POST
// ═══════════════════════════════════════════════════════════════════════════

class Post {
  final String id;
  final String userId;
  final String? artistId;
  final String? venueId;
  final String? caption;
  final List<PostMedia> media;
  final List<String> hashtags;
  final String? locationName;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final bool isLiked;
  final bool isSaved;
  final bool isPinned;
  final bool commentsDisabled;
  final bool likesHidden;
  final bool isBoosted;
  final DateTime createdAt;
  final PostAuthor? author;
  final List<PostComment> comments;

  const Post({
    required this.id,
    required this.userId,
    this.artistId,
    this.venueId,
    this.caption,
    required this.media,
    this.hashtags = const [],
    this.locationName,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isPinned = false,
    this.commentsDisabled = false,
    this.likesHidden = false,
    this.isBoosted = false,
    required this.createdAt,
    this.author,
    this.comments = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      artistId: json['artistId']?.toString(),
      venueId: json['venueId']?.toString(),
      caption: json['caption'],
      media:
          (json['media'] as List?)
              ?.map((m) => PostMedia.fromJson(m))
              .toList() ??
          [],
      hashtags: (json['hashtags'] as List?)?.cast<String>() ?? [],
      locationName: json['locationName'],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      isPinned: json['isPinned'] ?? false,
      commentsDisabled: json['commentsDisabled'] ?? false,
      likesHidden: json['likesHidden'] ?? false,
      isBoosted: json['isBoosted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      author: json['author'] != null
          ? PostAuthor.fromJson(json['author'])
          : null,
      comments:
          (json['comments'] as List?)
              ?.map((c) => PostComment.fromJson(c))
              .toList() ??
          [],
    );
  }

  Post copyWith({
    bool? isLiked,
    bool? isSaved,
    bool? isBoosted,
    int? likeCount,
    int? commentCount,
    List<PostComment>? comments,
  }) {
    return Post(
      id: id,
      userId: userId,
      artistId: artistId,
      venueId: venueId,
      caption: caption,
      media: media,
      hashtags: hashtags,
      locationName: locationName,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount,
      viewCount: viewCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isPinned: isPinned,
      commentsDisabled: commentsDisabled,
      likesHidden: likesHidden,
      isBoosted: isBoosted ?? this.isBoosted,
      createdAt: createdAt,
      author: author,
      comments: comments ?? this.comments,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STORY ITEM
// ═══════════════════════════════════════════════════════════════════════════

class StoryItem {
  final String id;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final int? duration;
  final String? caption;
  final String? link;
  final String? linkText;
  final List<String> hashtags;
  final bool isViewed;
  final DateTime createdAt;

  const StoryItem({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.duration,
    this.caption,
    this.link,
    this.linkText,
    this.hashtags = const [],
    this.isViewed = false,
    required this.createdAt,
  });

  factory StoryItem.fromJson(
    Map<String, dynamic> json, {
    bool isViewed = false,
  }) {
    return StoryItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type'] == 'video' ? MediaType.video : MediaType.image,
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      caption: json['caption'],
      link: json['link'],
      linkText: json['linkText'],
      hashtags: (json['hashtags'] as List?)?.cast<String>() ?? [],
      isViewed: isViewed,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == MediaType.video ? 'video' : 'image',
      'url': url,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (duration != null) 'duration': duration,
      if (caption != null) 'caption': caption,
      if (link != null) 'link': link,
      if (linkText != null) 'linkText': linkText,
      if (hashtags.isNotEmpty) 'hashtags': hashtags,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STORY
// ═══════════════════════════════════════════════════════════════════════════

class Story {
  final String id;
  final String userId;
  final String? artistId;
  final String? venueId;
  final List<StoryItem> items;
  final DateTime expiresAt;
  final bool hasUnviewed;
  final bool isBoosted;
  final String? latestItemUrl;
  final DateTime createdAt;
  final PostAuthor? author;

  const Story({
    required this.id,
    required this.userId,
    this.artistId,
    this.venueId,
    required this.items,
    required this.expiresAt,
    this.hasUnviewed = true,
    this.isBoosted = false,
    this.latestItemUrl,
    required this.createdAt,
    this.author,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final viewedItemIds =
        (json['viewedItemIds'] as List?)?.cast<String>() ?? [];

    // DEBUG: Log the raw Story JSON to verify artistId/venueId
    debugPrint('📖 Story.fromJson - id: ${json['_id'] ?? json['id']}');
    debugPrint('📖 Story.fromJson - raw artistId: ${json['artistId']} (type: ${json['artistId']?.runtimeType})');
    debugPrint('📖 Story.fromJson - raw venueId: ${json['venueId']} (type: ${json['venueId']?.runtimeType})');
    debugPrint('📖 Story.fromJson - author present: ${json['author'] != null}');

    return Story(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      artistId: json['artistId']?.toString(),
      venueId: json['venueId']?.toString(),
      items:
          (json['items'] as List?)?.map((i) {
            final itemId = i['_id']?.toString() ?? i['id']?.toString() ?? '';
            return StoryItem.fromJson(
              i,
              isViewed: viewedItemIds.contains(itemId),
            );
          }).toList() ??
          [],
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(hours: 24)),
      hasUnviewed: json['hasUnviewed'] ?? true,
      isBoosted: json['isBoosted'] ?? false,
      latestItemUrl: json['latestItemUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      author: json['author'] != null
          ? PostAuthor.fromJson(json['author'])
          : null,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ═══════════════════════════════════════════════════════════════════════════
// FEED RESPONSE
// ═══════════════════════════════════════════════════════════════════════════

class PostsFeedResponse {
  final List<Post> posts;
  final bool hasMore;
  final int total;

  const PostsFeedResponse({
    required this.posts,
    required this.hasMore,
    required this.total,
  });

  factory PostsFeedResponse.fromJson(Map<String, dynamic> json) {
    return PostsFeedResponse(
      posts:
          (json['posts'] as List?)?.map((p) => Post.fromJson(p)).toList() ?? [],
      hasMore: json['hasMore'] ?? false,
      total: json['total'] ?? 0,
    );
  }
}

class StoriesFeedResponse {
  final List<Story> stories;
  final bool hasMore;

  const StoriesFeedResponse({required this.stories, required this.hasMore});

  factory StoriesFeedResponse.fromJson(Map<String, dynamic> json) {
    return StoriesFeedResponse(
      stories:
          (json['stories'] as List?)?.map((s) => Story.fromJson(s)).toList() ??
          [],
      hasMore: json['hasMore'] ?? false,
    );
  }
}
