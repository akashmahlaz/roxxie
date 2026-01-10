/// 🏢 GIGMATCH Venue Models
/// Models for venue profiles and related data
library;

import 'user_models.dart';

/// Venue Profile Data Model for Onboarding
/// Used during the multi-step profile setup process
class VenueProfileData {
  // Basic Info
  String? venueName;
  String? description;
  String? venueType;

  // Location
  String? city;
  String? country;
  String? streetAddress;
  String? state;
  String? postalCode;
  double? latitude;
  double? longitude;

  // Contact
  String? phone;
  String? contactEmail;
  bool showPhoneOnProfile = false;

  // Social Links
  String? instagram;
  String? facebook;
  String? twitter;
  String? website;
  String? yelp;
  String? googleMaps;

  // Venue Details
  int capacity = 100;
  String currency = 'USD';

  // Equipment & Amenities
  bool hasSoundSystem = false;
  bool hasLighting = false;
  bool hasStage = false;
  bool hasDressingRoom = false;
  bool hasParking = false;
  bool hasBackline = false;
  List<String> additionalEquipment = [];

  // Operating Hours
  Map<String, Map<String, String>> operatingHours = {};

  // Budget & Preferences
  double minBudget = 0;
  double maxBudget = 5000;
  List<String> preferredGenres = [];

  // Media
  String? coverPhoto;
  String? logo;
  List<String> photoGallery = [];
  List<Map<String, String>> videos = [];

  // Reset all data
  void reset() {
    venueName = null;
    description = null;
    venueType = null;
    city = null;
    country = null;
    streetAddress = null;
    state = null;
    postalCode = null;
    latitude = null;
    longitude = null;
    phone = null;
    contactEmail = null;
    showPhoneOnProfile = false;
    instagram = null;
    facebook = null;
    twitter = null;
    website = null;
    yelp = null;
    googleMaps = null;
    capacity = 100;
    currency = 'USD';
    hasSoundSystem = false;
    hasLighting = false;
    hasStage = false;
    hasDressingRoom = false;
    hasParking = false;
    hasBackline = false;
    additionalEquipment.clear();
    operatingHours.clear();
    minBudget = 0;
    maxBudget = 5000;
    preferredGenres.clear();
    coverPhoto = null;
    logo = null;
    photoGallery.clear();
    videos.clear();
  }

  /// Validate required fields for profile completion
  List<String> validate() {
    final errors = <String>[];

    if (venueName == null || venueName!.trim().isEmpty) {
      errors.add('Venue name is required');
    }

    if (venueType == null || venueType!.trim().isEmpty) {
      errors.add('Venue type is required');
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

    if (capacity <= 0) {
      errors.add('Capacity must be greater than 0');
    }

    if (minBudget < 0) {
      errors.add('Minimum budget cannot be negative');
    }

    if (maxBudget < 0) {
      errors.add('Maximum budget cannot be negative');
    }

    if (minBudget > maxBudget) {
      errors.add('Minimum budget cannot be greater than maximum budget');
    }

    return errors;
  }

  /// Convert to backend DTO format
  Map<String, dynamic> toBackendDto() {
    final dto = <String, dynamic>{};

    // Basic info
    if (venueName != null && venueName!.isNotEmpty) {
      dto['venueName'] = venueName!;
    }
    if (description != null && description!.isNotEmpty) {
      dto['description'] = description!;
    }
    if (venueType != null && venueType!.isNotEmpty) {
      dto['venueType'] = venueType!;
    }

    // Location (required for completion)
    if (city != null && country != null && latitude != null && longitude != null) {
      dto['location'] = {
        'city': city!,
        'country': country!,
        'streetAddress': streetAddress,
        'state': state,
        'postalCode': postalCode,
        'coordinates': [longitude!, latitude!], // [longitude, latitude]
      };
    }

    // Contact
    if (phone != null && phone!.isNotEmpty) {
      dto['phone'] = phone!;
    }
    if (contactEmail != null && contactEmail!.isNotEmpty) {
      dto['contactEmail'] = contactEmail!;
    }
    dto['showPhoneOnProfile'] = showPhoneOnProfile;

    // Social links
    final socialLinks = <String, String>{};
    if (instagram != null && instagram!.isNotEmpty) {
      socialLinks['instagram'] = _normalizeUrl(instagram!, 'instagram.com');
    }
    if (facebook != null && facebook!.isNotEmpty) {
      socialLinks['facebook'] = _normalizeUrl(facebook!, 'facebook.com');
    }
    if (twitter != null && twitter!.isNotEmpty) {
      socialLinks['twitter'] = _normalizeUrl(twitter!, 'twitter.com');
    }
    if (website != null && website!.isNotEmpty) {
      socialLinks['website'] = _normalizeUrl(website!, '');
    }
    if (yelp != null && yelp!.isNotEmpty) {
      socialLinks['yelp'] = _normalizeUrl(yelp!, 'yelp.com');
    }
    if (googleMaps != null && googleMaps!.isNotEmpty) {
      socialLinks['googleMaps'] = _normalizeUrl(googleMaps!, 'maps.google.com');
    }

    if (socialLinks.isNotEmpty) {
      dto['socialLinks'] = socialLinks;
    }

    // Venue details
    dto['capacity'] = capacity;
    dto['currency'] = currency;

    // Equipment
    dto['equipment'] = {
      'hasSoundSystem': hasSoundSystem,
      'hasLighting': hasLighting,
      'hasStage': hasStage,
      'hasDressingRoom': hasDressingRoom,
      'hasParking': hasParking,
      'hasBackline': hasBackline,
      'additionalEquipment': additionalEquipment,
    };

    // Operating hours
    if (operatingHours.isNotEmpty) {
      dto['operatingHours'] = operatingHours;
    }

    // Budget
    dto['minBudget'] = minBudget;
    dto['maxBudget'] = maxBudget;

    // Preferences
    if (preferredGenres.isNotEmpty) {
      dto['preferredGenres'] = preferredGenres;
    }

    // Media
    if (coverPhoto != null && coverPhoto!.isNotEmpty) {
      dto['coverPhoto'] = coverPhoto!;
    }
    if (logo != null && logo!.isNotEmpty) {
      dto['logo'] = logo!;
    }
    if (photoGallery.isNotEmpty) {
      dto['photoGallery'] = photoGallery;
    }
    if (videos.isNotEmpty) {
      dto['videos'] = videos;
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
    const totalFields = 15;

    if (venueName != null && venueName!.isNotEmpty) score++;
    if (description != null && description!.length > 20) score++;
    if (venueType != null && venueType!.isNotEmpty) score++;
    if (city != null && country != null) score++;
    if (latitude != null && longitude != null) score++;
    if (phone != null && phone!.isNotEmpty) score++;
    if (contactEmail != null && contactEmail!.isNotEmpty) score++;
    if (socialLinks.isNotEmpty) score++;
    if (capacity > 0) score++;
    if (hasSoundSystem || hasLighting || hasStage) score++;
    if (operatingHours.isNotEmpty) score++;
    if (minBudget >= 0 && maxBudget > 0) score++;
    if (preferredGenres.isNotEmpty) score++;
    if (coverPhoto != null || logo != null) score++;
    if (photoGallery.isNotEmpty) score++;

    return ((score / totalFields) * 100).round();
  }

  /// Check if profile is complete enough for setup
  bool get isSetupReady {
    final errors = validate();
    return errors.isEmpty;
  }
}

/// Venue Type Enum
enum VenueType {
  bar('bar'),
  club('club'),
  restaurant('restaurant'),
  lounge('lounge'),
  concertHall('concert_hall'),
  theater('theater'),
  outdoorStage('outdoor_stage'),
  privateEvent('private_event'),
  hotel('hotel'),
  weddingVenue('wedding_venue'),
  corporateEvent('corporate_event'),
  festival('festival'),
  other('other');

  final String value;
  const VenueType(this.value);

  static VenueType fromString(String value) {
    return VenueType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => VenueType.bar,
    );
  }

  String get displayName {
    switch (this) {
      case VenueType.bar:
        return 'Bar';
      case VenueType.club:
        return 'Club';
      case VenueType.restaurant:
        return 'Restaurant';
      case VenueType.lounge:
        return 'Lounge';
      case VenueType.concertHall:
        return 'Concert Hall';
      case VenueType.theater:
        return 'Theater';
      case VenueType.outdoorStage:
        return 'Outdoor Stage';
      case VenueType.privateEvent:
        return 'Private Event';
      case VenueType.hotel:
        return 'Hotel';
      case VenueType.weddingVenue:
        return 'Wedding Venue';
      case VenueType.corporateEvent:
        return 'Corporate Event';
      case VenueType.festival:
        return 'Festival';
      case VenueType.other:
        return 'Other';
    }
  }
}

/// Operating Hours Model
class OperatingHours {
  final String day;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;

  OperatingHours({
    required this.day,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      day: json['day'] ?? '',
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      isClosed: json['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    if (openTime != null) 'openTime': openTime,
    if (closeTime != null) 'closeTime': closeTime,
    'isClosed': isClosed,
  };

  String get formatted =>
      isClosed ? 'Closed' : '${openTime ?? 'N/A'} - ${closeTime ?? 'N/A'}';
}

/// Gig Type Model (what kind of gigs venue is looking for)
class GigPreferences {
  final List<String> preferredGenres;
  final List<String> preferredDays;
  final String? typicalSetLength; // '1 hour', '2 hours', 'full night'
  final bool providesEquipment;
  final bool providesMeals;
  final bool providesAccommodation;
  final String? additionalRequirements;

  GigPreferences({
    this.preferredGenres = const [],
    this.preferredDays = const [],
    this.typicalSetLength,
    this.providesEquipment = false,
    this.providesMeals = false,
    this.providesAccommodation = false,
    this.additionalRequirements,
  });

  factory GigPreferences.fromJson(Map<String, dynamic> json) {
    return GigPreferences(
      preferredGenres: List<String>.from(json['preferredGenres'] ?? []),
      preferredDays: List<String>.from(json['preferredDays'] ?? []),
      typicalSetLength: json['typicalSetLength'],
      providesEquipment: json['providesEquipment'] ?? false,
      providesMeals: json['providesMeals'] ?? false,
      providesAccommodation: json['providesAccommodation'] ?? false,
      additionalRequirements: json['additionalRequirements'],
    );
  }

  Map<String, dynamic> toJson() => {
    'preferredGenres': preferredGenres,
    'preferredDays': preferredDays,
    if (typicalSetLength != null) 'typicalSetLength': typicalSetLength,
    'providesEquipment': providesEquipment,
    'providesMeals': providesMeals,
    'providesAccommodation': providesAccommodation,
    if (additionalRequirements != null)
      'additionalRequirements': additionalRequirements,
  };
}

/// Venue Budget Range
class BudgetRange {
  final double min;
  final double max;
  final String currency;
  final String per; // 'night', 'event', 'hour'

  BudgetRange({
    required this.min,
    required this.max,
    this.currency = 'USD',
    this.per = 'night',
  });

  factory BudgetRange.fromJson(Map<String, dynamic> json) {
    return BudgetRange(
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      per: json['per'] ?? 'night',
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

/// Venue Profile Model
///
/// Backend alignment (NestJS/Mongoose):
/// - venueName, description, venueType
/// - location { city, country, coordinates:[lng,lat], ... }
/// - preferredGenres
/// - coverPhoto/logo/photoGallery/videos
/// - phone/showPhoneOnProfile/contactEmail
/// - capacity/equipment/operatingHours
/// - minBudget/maxBudget/currency
///
/// Backward compatibility:
/// - Keep computed getters for legacy `name` and `bio` consumers.
class Venue {
  final String id;
  final String userId;

  /// Backend: venueName
  final String venueName;

  /// Backend: description
  final String? description;

  final VenueType venueType;
  final Location? location;

  /// Backend: preferredGenres
  final List<String> preferredGenres;

  /// Backend media
  final String? coverPhoto;
  final String? logo;
  final List<String> photoGallery;

  /// Contact (backend)
  final String? phone;
  final bool showPhoneOnProfile;
  final String? contactEmail;

  /// Core details
  final int capacity;

  /// Backward-compatible "amenities" (allowed by UpdateVenueDto)
  final List<String> amenities;

  /// Operating hours (app model uses a list)
  final List<OperatingHours> operatingHours;

  /// Legacy app-side preferences (allowed by UpdateVenueDto as `gigPreferences`)
  final GigPreferences? gigPreferences;

  /// Budget (backend-native)
  final double minBudget;
  final double maxBudget;
  final String currency;

  /// Backward-compatible: keep `budgetRange` for UI
  final BudgetRange? budgetRange;

  final SocialLinks? socialLinks;

  // Legacy getters (do not persist these to backend)
  String get name => venueName;
  String? get bio => description;
  List<String> get galleryUrls => photoGallery;

  final bool isVerified;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Venue({
    required this.id,
    required this.userId,
    required this.venueName,
    this.description,
    required this.venueType,
    this.location,
    this.preferredGenres = const [],
    this.coverPhoto,
    this.logo,
    this.photoGallery = const [],
    this.phone,
    this.showPhoneOnProfile = false,
    this.contactEmail,
    this.capacity = 0,
    this.amenities = const [],
    this.operatingHours = const [],
    this.gigPreferences,
    this.minBudget = 0.0,
    this.maxBudget = 0.0,
    this.currency = 'USD',
    this.budgetRange,
    this.socialLinks,
    this.isVerified = false,
    this.isActive = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    // Support both backend field names and older app field names.
    final venueName = (json['venueName'] ?? json['name'] ?? '') as String;
    final description = (json['description'] ?? json['bio']) as String?;
    final preferredGenres = List<String>.from(json['preferredGenres'] ?? []);
    final photoGallery = List<String>.from(
      json['photoGallery'] ?? json['galleryUrls'] ?? [],
    );

    // Budget can come as minBudget/maxBudget OR legacy budgetRange
    final minBudget = (json['minBudget'] as num?)?.toDouble();
    final maxBudget = (json['maxBudget'] as num?)?.toDouble();
    final currency = (json['currency'] ?? 'USD') as String;
    final budgetRange =
        json['budgetRange'] != null ? BudgetRange.fromJson(json['budgetRange']) : null;

    return Venue(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      venueName: venueName,
      description: description,
      venueType: VenueType.fromString(json['venueType'] ?? 'bar'),
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      preferredGenres: preferredGenres,
      coverPhoto: json['coverPhoto'],
      logo: json['logo'],
      photoGallery: photoGallery,
      phone: json['phone'],
      showPhoneOnProfile: json['showPhoneOnProfile'] ?? false,
      contactEmail: json['contactEmail'] ?? json['email'],
      capacity: json['capacity'] ?? 0,
      amenities: List<String>.from(json['amenities'] ?? []),
      operatingHours:
          (json['operatingHours'] as List?)
              ?.map((e) => OperatingHours.fromJson(e))
              .toList() ??
          [],
      gigPreferences: json['gigPreferences'] != null
          ? GigPreferences.fromJson(json['gigPreferences'])
          : null,
      minBudget: minBudget ?? budgetRange?.min ?? 0.0,
      maxBudget: maxBudget ?? budgetRange?.max ?? 0.0,
      currency: currency,
      budgetRange: budgetRange,
      socialLinks: json['socialLinks'] != null
          ? SocialLinks.fromJson(json['socialLinks'])
          : null,
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      rating: (json['averageRating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      reviewCount: json['totalReviews'] ?? json['reviewCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    // Keep legacy-friendly keys for existing UI usage,
    // but do NOT reintroduce removed fields like contactPhone.
    'name': name,
    'bio': bio,
    'venueType': venueType.value,
    'location': location?.toJson(),
    'capacity': capacity,
    'galleryUrls': galleryUrls,
    'amenities': amenities,
    'operatingHours': operatingHours.map((e) => e.toJson()).toList(),
    'gigPreferences': gigPreferences?.toJson(),
    'budgetRange': budgetRange?.toJson(),
    'socialLinks': socialLinks?.toJson(),
    'contactEmail': contactEmail,
    'isVerified': isVerified,
    'isActive': isActive,
    'rating': rating,
    'reviewCount': reviewCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  String get primaryPhoto => galleryUrls.isNotEmpty ? galleryUrls.first : '';
  String get displayLocation =>
      location?.city ?? location?.formattedAddress ?? 'Location not set';
}

/// Venue Search/Filter Params
class VenueSearchParams {
  final double? latitude;
  final double? longitude;
  final int? maxDistance;
  final VenueType? venueType;
  final List<String>? preferredGenres;
  final int? minCapacity;
  final int? maxCapacity;
  final double? minBudget;
  final double? maxBudget;
  final bool? providesEquipment;
  final int page;
  final int limit;

  VenueSearchParams({
    this.latitude,
    this.longitude,
    this.maxDistance,
    this.venueType,
    this.preferredGenres,
    this.minCapacity,
    this.maxCapacity,
    this.minBudget,
    this.maxBudget,
    this.providesEquipment,
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
    if (venueType != null) params['venueType'] = venueType!.value;
    if (preferredGenres != null && preferredGenres!.isNotEmpty) {
      params['preferredGenres'] = preferredGenres!.join(',');
    }
    if (minCapacity != null) params['minCapacity'] = minCapacity.toString();
    if (maxCapacity != null) params['maxCapacity'] = maxCapacity.toString();
    if (minBudget != null) params['minBudget'] = minBudget.toString();
    if (maxBudget != null) params['maxBudget'] = maxBudget.toString();
    if (providesEquipment != null) {
      params['providesEquipment'] = providesEquipment.toString();
    }
    return params;
  }
}

/// Update Venue Profile Request
///
/// Bulletproof DTO-safe mapping for backend `UpdateVenueDto` (NestJS ValidationPipe with whitelist+forbidNonWhitelisted).
///
/// Backend expects:
/// - venueName, venueType, description
/// - location { streetAddress?, city, state?, postalCode?, country, coordinates:[lng,lat] }
/// - preferredGenres
/// - phone, showPhoneOnProfile, contactEmail
/// - capacity, equipment, operatingHours
/// - minBudget, maxBudget, currency
///
/// UpdateVenueDto additionally allows:
/// - amenities
/// - budgetRange { min, max }
/// - gigPreferences { ... }
///
/// IMPORTANT:
/// - Never send unknown keys like `name`/`bio`/`galleryUrls` to backend.
/// - Keep coordinates ordering: [longitude, latitude].
/// - Do not send invalid coordinates [0,0].
class UpdateVenueRequest {
  // ✅ Backend DTO fields
  final String? venueName;
  final String? description;
  final VenueType? venueType;
  final Location? location;

  final List<String>? preferredGenres;

  final String? phone;
  final bool? showPhoneOnProfile;
  final String? contactEmail;

  final int? capacity;

  // Budget (preferred)
  final double? minBudget;
  final double? maxBudget;
  final String? currency;

  // Optional media (only if backend DTO supports them)
  final String? coverPhoto;
  final String? logo;
  final List<String>? photoGallery;

  // Allowed by UpdateVenueDto
  final List<String>? amenities;
  final BudgetRange? budgetRange;
  final GigPreferences? gigPreferences;
  final SocialLinks? socialLinks;

  // Legacy fields retained for UI/backward-compat, but NOT sent directly
  final String? name; // legacy -> venueName
  final String? bio; // legacy -> description
  final List<String>? galleryUrls; // legacy -> photoGallery

  UpdateVenueRequest({
    this.venueName,
    this.description,
    this.venueType,
    this.location,
    this.preferredGenres,
    this.phone,
    this.showPhoneOnProfile,
    this.contactEmail,
    this.capacity,
    this.minBudget,
    this.maxBudget,
    this.currency,
    this.coverPhoto,
    this.logo,
    this.photoGallery,
    this.amenities,
    this.budgetRange,
    this.gigPreferences,
    this.socialLinks,

    // legacy
    this.name,
    this.bio,
    this.galleryUrls,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    // Map legacy -> DTO-safe fields
    final resolvedVenueName = venueName ?? name;
    final resolvedDescription = description ?? bio;
    final resolvedPhotoGallery = photoGallery ?? galleryUrls;

    if (resolvedVenueName != null) json['venueName'] = resolvedVenueName;
    if (resolvedDescription != null) json['description'] = resolvedDescription;
    if (venueType != null) json['venueType'] = venueType!.value;

    if (preferredGenres != null) json['preferredGenres'] = preferredGenres;

    // Location: only send if valid and not [0,0]
    if (location != null &&
        location!.coordinates.length >= 2 &&
        location!.longitude.abs() > 0.000001 &&
        location!.latitude.abs() > 0.000001) {
      json['location'] = location!.toJson();
    }

    if (phone != null) json['phone'] = phone;
    if (showPhoneOnProfile != null) {
      json['showPhoneOnProfile'] = showPhoneOnProfile;
    }
    if (contactEmail != null) json['contactEmail'] = contactEmail;

    if (capacity != null) json['capacity'] = capacity;

    // Budget: prefer direct schema keys (works with CreateVenueDto too)
    if (minBudget != null) json['minBudget'] = minBudget;
    if (maxBudget != null) json['maxBudget'] = maxBudget;
    if (currency != null) json['currency'] = currency;

    // Optional media
    if (coverPhoto != null) json['coverPhoto'] = coverPhoto;
    if (logo != null) json['logo'] = logo;
    if (resolvedPhotoGallery != null) json['photoGallery'] = resolvedPhotoGallery;

    // Allowed extras by UpdateVenueDto
    if (amenities != null) json['amenities'] = amenities;
    if (budgetRange != null) json['budgetRange'] = budgetRange!.toJson();
    if (gigPreferences != null) json['gigPreferences'] = gigPreferences!.toJson();
    if (socialLinks != null) json['socialLinks'] = socialLinks!.toJson();

    return json;
  }
}
