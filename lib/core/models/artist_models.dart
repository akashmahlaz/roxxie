/// 🎸 GIGMATCH Artist Models
/// Models for artist profiles and related data

import 'user_models.dart';

/// Artist Type Enum
enum ArtistType {
  solo('solo'),
  band('band'),
  duo('duo'),
  dj('dj'),
  orchestra('orchestra'),
  ensemble('ensemble');

  final String value;
  const ArtistType(this.value);

  static ArtistType fromString(String value) {
    return ArtistType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ArtistType.solo,
    );
  }
}

/// Experience Level
enum ExperienceLevel {
  beginner('beginner'),
  intermediate('intermediate'),
  professional('professional'),
  expert('expert');

  final String value;
  const ExperienceLevel(this.value);

  static ExperienceLevel fromString(String value) {
    return ExperienceLevel.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ExperienceLevel.intermediate,
    );
  }
}

/// Audio Sample Model
class AudioSample {
  final String url;
  final String? title;
  final int? durationSeconds;
  final String? cloudinaryPublicId;

  AudioSample({
    required this.url,
    this.title,
    this.durationSeconds,
    this.cloudinaryPublicId,
  });

  factory AudioSample.fromJson(Map<String, dynamic> json) {
    return AudioSample(
      url: json['url'] ?? '',
      title: json['title'],
      durationSeconds: json['durationSeconds'],
      cloudinaryPublicId: json['cloudinaryPublicId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    if (title != null) 'title': title,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (cloudinaryPublicId != null) 'cloudinaryPublicId': cloudinaryPublicId,
  };
}

/// Video Sample Model
class VideoSample {
  final String url;
  final String? title;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? cloudinaryPublicId;

  VideoSample({
    required this.url,
    this.title,
    this.thumbnailUrl,
    this.durationSeconds,
    this.cloudinaryPublicId,
  });

  factory VideoSample.fromJson(Map<String, dynamic> json) {
    return VideoSample(
      url: json['url'] ?? '',
      title: json['title'],
      thumbnailUrl: json['thumbnailUrl'],
      durationSeconds: json['durationSeconds'],
      cloudinaryPublicId: json['cloudinaryPublicId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    if (title != null) 'title': title,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (cloudinaryPublicId != null) 'cloudinaryPublicId': cloudinaryPublicId,
  };
}

/// Price Range Model
class PriceRange {
  final double min;
  final double max;
  final String currency;
  final String per; // 'hour', 'show', 'night'

  PriceRange({
    required this.min,
    required this.max,
    this.currency = 'USD',
    this.per = 'show',
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      per: json['per'] ?? 'show',
    );
  }

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'currency': currency,
    'per': per,
  };

  String get formatted => '\$$min - \$$max / $per';
}

/// Artist Profile Model
class Artist {
  final String id;
  final String userId;
  final String stageName;
  final String? bio;
  final ArtistType artistType;
  final List<String> genres;
  final ExperienceLevel experienceLevel;
  final int? yearsOfExperience;
  final Location? location;
  final int maxTravelDistance;
  final List<String> galleryUrls;
  final List<AudioSample> audioSamples;
  final List<VideoSample> videoSamples;
  final SocialLinks? socialLinks;
  final PriceRange? priceRange;
  final List<String> equipment;
  final int? bandSize;
  final bool isAvailable;
  final bool isVerified;
  final bool isBoosted;
  final DateTime? boostedUntil;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Artist({
    required this.id,
    required this.userId,
    required this.stageName,
    this.bio,
    required this.artistType,
    required this.genres,
    required this.experienceLevel,
    this.yearsOfExperience,
    this.location,
    this.maxTravelDistance = 50,
    this.galleryUrls = const [],
    this.audioSamples = const [],
    this.videoSamples = const [],
    this.socialLinks,
    this.priceRange,
    this.equipment = const [],
    this.bandSize,
    this.isAvailable = true,
    this.isVerified = false,
    this.isBoosted = false,
    this.boostedUntil,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      stageName: json['stageName'] ?? '',
      bio: json['bio'],
      artistType: ArtistType.fromString(json['artistType'] ?? 'solo'),
      genres: List<String>.from(json['genres'] ?? []),
      experienceLevel: ExperienceLevel.fromString(
        json['experienceLevel'] ?? 'intermediate',
      ),
      yearsOfExperience: json['yearsOfExperience'],
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,
      maxTravelDistance: json['maxTravelDistance'] ?? 50,
      galleryUrls: List<String>.from(json['galleryUrls'] ?? []),
      audioSamples:
          (json['audioSamples'] as List?)
              ?.map((e) => AudioSample.fromJson(e))
              .toList() ??
          [],
      videoSamples:
          (json['videoSamples'] as List?)
              ?.map((e) => VideoSample.fromJson(e))
              .toList() ??
          [],
      socialLinks: json['socialLinks'] != null
          ? SocialLinks.fromJson(json['socialLinks'])
          : null,
      priceRange: json['priceRange'] != null
          ? PriceRange.fromJson(json['priceRange'])
          : null,
      equipment: List<String>.from(json['equipment'] ?? []),
      bandSize: json['bandSize'],
      isAvailable: json['isAvailable'] ?? true,
      isVerified: json['isVerified'] ?? false,
      isBoosted: json['isBoosted'] ?? false,
      boostedUntil: json['boostedUntil'] != null
          ? DateTime.tryParse(json['boostedUntil'])
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'stageName': stageName,
    'bio': bio,
    'artistType': artistType.value,
    'genres': genres,
    'experienceLevel': experienceLevel.value,
    'yearsOfExperience': yearsOfExperience,
    'location': location?.toJson(),
    'maxTravelDistance': maxTravelDistance,
    'galleryUrls': galleryUrls,
    'audioSamples': audioSamples.map((e) => e.toJson()).toList(),
    'videoSamples': videoSamples.map((e) => e.toJson()).toList(),
    'socialLinks': socialLinks?.toJson(),
    'priceRange': priceRange?.toJson(),
    'equipment': equipment,
    'bandSize': bandSize,
    'isAvailable': isAvailable,
    'isVerified': isVerified,
    'isBoosted': isBoosted,
    'boostedUntil': boostedUntil?.toIso8601String(),
    'rating': rating,
    'reviewCount': reviewCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  String get primaryPhoto => galleryUrls.isNotEmpty ? galleryUrls.first : '';
  String get displayLocation =>
      location?.city ?? location?.formattedAddress ?? 'Location not set';
}

/// Artist Search/Filter Params
class ArtistSearchParams {
  final double? latitude;
  final double? longitude;
  final int? maxDistance;
  final List<String>? genres;
  final ArtistType? artistType;
  final ExperienceLevel? experienceLevel;
  final double? minPrice;
  final double? maxPrice;
  final bool? isAvailable;
  final int page;
  final int limit;

  ArtistSearchParams({
    this.latitude,
    this.longitude,
    this.maxDistance,
    this.genres,
    this.artistType,
    this.experienceLevel,
    this.minPrice,
    this.maxPrice,
    this.isAvailable,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (latitude != null) params['latitude'] = latitude.toString();
    if (longitude != null) params['longitude'] = longitude.toString();
    if (maxDistance != null) params['maxDistance'] = maxDistance.toString();
    if (genres != null && genres!.isNotEmpty)
      params['genres'] = genres!.join(',');
    if (artistType != null) params['artistType'] = artistType!.value;
    if (experienceLevel != null)
      params['experienceLevel'] = experienceLevel!.value;
    if (minPrice != null) params['minPrice'] = minPrice.toString();
    if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
    if (isAvailable != null) params['isAvailable'] = isAvailable.toString();
    return params;
  }
}

/// Update Artist Profile Request
class UpdateArtistRequest {
  final String? stageName;
  final String? bio;
  final ArtistType? artistType;
  final List<String>? genres;
  final ExperienceLevel? experienceLevel;
  final int? yearsOfExperience;
  final Location? location;
  final int? maxTravelDistance;
  final List<String>? galleryUrls;
  final SocialLinks? socialLinks;
  final PriceRange? priceRange;
  final List<String>? equipment;
  final int? bandSize;
  final bool? isAvailable;

  UpdateArtistRequest({
    this.stageName,
    this.bio,
    this.artistType,
    this.genres,
    this.experienceLevel,
    this.yearsOfExperience,
    this.location,
    this.maxTravelDistance,
    this.galleryUrls,
    this.socialLinks,
    this.priceRange,
    this.equipment,
    this.bandSize,
    this.isAvailable,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (stageName != null) json['stageName'] = stageName;
    if (bio != null) json['bio'] = bio;
    if (artistType != null) json['artistType'] = artistType!.value;
    if (genres != null) json['genres'] = genres;
    if (experienceLevel != null)
      json['experienceLevel'] = experienceLevel!.value;
    if (yearsOfExperience != null)
      json['yearsOfExperience'] = yearsOfExperience;
    if (location != null) json['location'] = location!.toJson();
    if (maxTravelDistance != null)
      json['maxTravelDistance'] = maxTravelDistance;
    if (galleryUrls != null) json['galleryUrls'] = galleryUrls;
    if (socialLinks != null) json['socialLinks'] = socialLinks!.toJson();
    if (priceRange != null) json['priceRange'] = priceRange!.toJson();
    if (equipment != null) json['equipment'] = equipment;
    if (bandSize != null) json['bandSize'] = bandSize;
    if (isAvailable != null) json['isAvailable'] = isAvailable;
    return json;
  }
}
