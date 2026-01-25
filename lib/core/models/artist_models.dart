/// 🎸 GIGMATCH Artist Models
/// Models for artist profiles and related data
library;

import 'user_models.dart';

/// Artist Profile Data Model for Onboarding
/// Used during the multi-step profile setup process
class ArtistProfileData {
  // Basic Info
  String? displayName;
  String? stageName;
  String? bio;
  List<String> genres = [];
  List<String> influences = [];

  // Media
  String? profilePhoto;
  List<String> photoGallery = [];
  List<Map<String, dynamic>> audioSamples = [];
  List<Map<String, dynamic>> videoSamples = [];

  // Contact
  String? phone;
  String? email;
  bool showPhoneOnProfile = false;

  // Social Links
  String? instagram;
  String? spotify;
  String? youtube;
  String? website;
  String? soundcloud;
  String? tiktok;

  // Location
  String? city;
  String? country;
  double? latitude;
  double? longitude;
  int travelRadius = 50;

  // Availability
  List<Map<String, dynamic>> availability = [];

  // Pricing
  double minPrice = 100.0;
  double maxPrice = 1000.0;
  String currency = 'USD';

  // Equipment
  List<String> equipment = [];

  // Band Info
  int? bandSize;

  // Reset all data
  void reset() {
    displayName = null;
    stageName = null;
    bio = null;
    genres.clear();
    influences.clear();
    profilePhoto = null;
    photoGallery.clear();
    audioSamples.clear();
    videoSamples.clear();
    phone = null;
    email = null;
    showPhoneOnProfile = false;
    instagram = null;
    spotify = null;
    youtube = null;
    website = null;
    soundcloud = null;
    tiktok = null;
    city = null;
    country = null;
    latitude = null;
    longitude = null;
    travelRadius = 50;
    availability.clear();
    minPrice = 100.0;
    maxPrice = 1000.0;
    currency = 'USD';
    equipment.clear();
    bandSize = null;
  }

  /// Validate required fields for profile completion
  List<String> validate() {
    final errors = <String>[];

    if (displayName == null || displayName!.trim().isEmpty) {
      errors.add('Display name is required');
    }

    if (genres.isEmpty) {
      errors.add('At least one genre must be selected');
    }

    if (genres.length > 5) {
      errors.add('Maximum 5 genres allowed');
    }

    if (city == null || city!.trim().isEmpty) {
      errors.add('City is required');
    }

    if (country == null || country!.trim().isEmpty) {
      errors.add('Country is required');
    }

    if (latitude == null || longitude == null) {
      errors.add('Location coordinates are required');
    } else if (latitude!.abs() < 0.000001 || longitude!.abs() < 0.000001) {
      errors.add('Valid location coordinates are required');
    }

    if (minPrice <= 0) {
      errors.add('Minimum price must be greater than 0');
    }

    if (maxPrice <= 0) {
      errors.add('Maximum price must be greater than 0');
    }

    if (minPrice > maxPrice) {
      errors.add('Minimum price cannot be greater than maximum price');
    }

    return errors;
  }

  /// Convert to backend DTO format
  Map<String, dynamic> toBackendDto() {
    final dto = <String, dynamic>{};

    // Basic info
    if (displayName != null && displayName!.isNotEmpty) {
      dto['displayName'] = displayName!;
    }
    if (stageName != null && stageName!.isNotEmpty) {
      dto['stageName'] = stageName!;
    }
    if (bio != null && bio!.isNotEmpty) {
      dto['bio'] = bio!;
    }
    if (genres.isNotEmpty) {
      dto['genres'] = genres;
    }

    // Location (required for completion)
    if (city != null && country != null && latitude != null && longitude != null) {
      dto['location'] = {
        'city': city!,
        'country': country!,
        'coordinates': [longitude!, latitude!], // [longitude, latitude]
        'travelRadius': travelRadius,
      };
    }

    // Pricing
    dto['minPrice'] = minPrice;
    dto['maxPrice'] = maxPrice;
    dto['currency'] = currency;

    // Social links
    final socialLinks = <String, String>{};
    if (instagram != null && instagram!.isNotEmpty) {
      socialLinks['instagram'] = _normalizeUrl(instagram!, 'instagram.com');
    }
    if (spotify != null && spotify!.isNotEmpty) {
      socialLinks['spotify'] = _normalizeUrl(spotify!, 'open.spotify.com/artist');
    }
    if (youtube != null && youtube!.isNotEmpty) {
      socialLinks['youtube'] = _normalizeUrl(youtube!, 'youtube.com/@');
    }
    if (website != null && website!.isNotEmpty) {
      socialLinks['website'] = _normalizeUrl(website!, '');
    }
    if (soundcloud != null && soundcloud!.isNotEmpty) {
      socialLinks['soundcloud'] = _normalizeUrl(soundcloud!, 'soundcloud.com');
    }
    if (tiktok != null && tiktok!.isNotEmpty) {
      socialLinks['tiktok'] = _normalizeUrl(tiktok!, 'tiktok.com/@');
    }

    if (socialLinks.isNotEmpty) {
      dto['socialLinks'] = socialLinks;
    }

    // Contact
    if (phone != null && phone!.isNotEmpty) {
      dto['phone'] = phone!;
    }
    dto['showPhoneOnProfile'] = showPhoneOnProfile;

    // Equipment
    if (equipment.isNotEmpty) {
      dto['equipment'] = equipment;
    }

    // Band size
    if (bandSize != null) {
      dto['bandSize'] = bandSize!;
    }

    // Availability - convert to backend format
    if (availability.isNotEmpty) {
      dto['availability'] = availability.map((slot) {
        return {
          'date': slot['date'], // Already in ISO8601 string format
          'startTime': slot['startTime'],
          'endTime': slot['endTime'],
          'isAvailable': slot['isBooked'] != true, // Invert isBooked to isAvailable
        };
      }).toList();
    }

    return dto;
  }

  /// Normalize social media URLs
  String _normalizeUrl(String input, String domain) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    if (input.startsWith('www.')) {
      return 'https://$input';
    }
    if (domain.isNotEmpty && input.contains(domain)) {
      return 'https://$input';
    }
    if (domain.isEmpty) {
      return input;
    }
    return 'https://$domain/$input';
  }

  /// Get profile completion percentage
  int getCompletionPercentage() {
    int score = 0;
    const totalFields = 12;

    if (displayName != null && displayName!.isNotEmpty) score++;
    if (bio != null && bio!.length > 20) score++;
    if (genres.isNotEmpty) score++;
    if (profilePhoto != null) score++;
    if (photoGallery.isNotEmpty) score++;
    if (audioSamples.isNotEmpty) score++;
    if (videoSamples.isNotEmpty) score++;
    if (city != null && country != null) score++;
    if (latitude != null && longitude != null) score++;
    if (minPrice > 0 && maxPrice > 0) score++;
    if (_hasSocialLinks()) score++;
    if (availability.isNotEmpty) score++;

    return ((score / totalFields) * 100).round();
  }

  /// Check if profile has any social links
  bool _hasSocialLinks() {
    return (instagram?.isNotEmpty ?? false) ||
           (spotify?.isNotEmpty ?? false) ||
           (youtube?.isNotEmpty ?? false) ||
           (website?.isNotEmpty ?? false) ||
           (soundcloud?.isNotEmpty ?? false) ||
           (tiktok?.isNotEmpty ?? false);
  }

  /// Check if profile is complete enough for setup
  bool get isSetupReady {
    final errors = validate();
    return errors.isEmpty;
  }
}

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
  final String? profilePhoto;

  // Compatibility getter for displayName
  String get displayName => stageName;
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

  // Price range getters for compatibility with UI
  double get minPrice => priceRange?.min ?? 100.0;
  double get maxPrice => priceRange?.max ?? 1000.0;
  String get currency => priceRange?.currency ?? 'USD';

  // Compatibility getter for travel radius
  int get travelRadius => maxTravelDistance;

  Artist({
    required this.id,
    required this.userId,
    required this.stageName,
    this.profilePhoto,
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
      profilePhoto: json['profilePhoto'],
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

  /// Primary photo - prefer profilePhoto, then first gallery photo
  String get primaryPhoto => profilePhoto ?? (galleryUrls.isNotEmpty ? galleryUrls.first : '');
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
    if (genres != null && genres!.isNotEmpty) {
      params['genres'] = genres!.join(',');
    }
    if (artistType != null) params['artistType'] = artistType!.value;
    if (experienceLevel != null) {
      params['experienceLevel'] = experienceLevel!.value;
    }
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
  final double? minPrice;
  final double? maxPrice;

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
    this.minPrice,
    this.maxPrice,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (stageName != null) json['stageName'] = stageName;
    if (bio != null) json['bio'] = bio;
    if (artistType != null) json['artistType'] = artistType!.value;
    if (genres != null) json['genres'] = genres;
    if (experienceLevel != null) {
      json['experienceLevel'] = experienceLevel!.value;
    }
    if (yearsOfExperience != null) {
      json['yearsOfExperience'] = yearsOfExperience;
    }
    if (location != null) json['location'] = location!.toJson();
    if (maxTravelDistance != null) {
      json['maxTravelDistance'] = maxTravelDistance;
    }
    if (galleryUrls != null) json['galleryUrls'] = galleryUrls;
    if (socialLinks != null) json['socialLinks'] = socialLinks!.toJson();
    if (priceRange != null) json['priceRange'] = priceRange!.toJson();
    if (equipment != null) json['equipment'] = equipment;
    if (bandSize != null) json['bandSize'] = bandSize;
    if (isAvailable != null) json['isAvailable'] = isAvailable;
    return json;
  }
}
