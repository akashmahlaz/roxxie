/// 🏢 GIGMATCH Venue Models
/// Models for venue profiles and related data

import 'user_models.dart';

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
class Venue {
  final String id;
  final String userId;
  final String name;
  final String? bio;
  final VenueType venueType;
  final Location? location;
  final int capacity;
  final List<String> galleryUrls;
  final List<String> amenities;
  final List<OperatingHours> operatingHours;
  final GigPreferences? gigPreferences;
  final BudgetRange? budgetRange;
  final SocialLinks? socialLinks;
  final String? contactEmail;
  final String? contactPhone;
  final bool isVerified;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Venue({
    required this.id,
    required this.userId,
    required this.name,
    this.bio,
    required this.venueType,
    this.location,
    this.capacity = 0,
    this.galleryUrls = const [],
    this.amenities = const [],
    this.operatingHours = const [],
    this.gigPreferences,
    this.budgetRange,
    this.socialLinks,
    this.contactEmail,
    this.contactPhone,
    this.isVerified = false,
    this.isActive = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'],
      venueType: VenueType.fromString(json['venueType'] ?? 'bar'),
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,
      capacity: json['capacity'] ?? 0,
      galleryUrls: List<String>.from(json['galleryUrls'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      operatingHours:
          (json['operatingHours'] as List?)
              ?.map((e) => OperatingHours.fromJson(e))
              .toList() ??
          [],
      gigPreferences: json['gigPreferences'] != null
          ? GigPreferences.fromJson(json['gigPreferences'])
          : null,
      budgetRange: json['budgetRange'] != null
          ? BudgetRange.fromJson(json['budgetRange'])
          : null,
      socialLinks: json['socialLinks'] != null
          ? SocialLinks.fromJson(json['socialLinks'])
          : null,
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
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
    'contactPhone': contactPhone,
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
    if (providesEquipment != null)
      params['providesEquipment'] = providesEquipment.toString();
    return params;
  }
}

/// Update Venue Profile Request
class UpdateVenueRequest {
  final String? name;
  final String? bio;
  final VenueType? venueType;
  final Location? location;
  final int? capacity;
  final List<String>? galleryUrls;
  final List<String>? amenities;
  final List<OperatingHours>? operatingHours;
  final GigPreferences? gigPreferences;
  final BudgetRange? budgetRange;
  final SocialLinks? socialLinks;
  final String? contactEmail;
  final String? contactPhone;
  final bool? isActive;

  UpdateVenueRequest({
    this.name,
    this.bio,
    this.venueType,
    this.location,
    this.capacity,
    this.galleryUrls,
    this.amenities,
    this.operatingHours,
    this.gigPreferences,
    this.budgetRange,
    this.socialLinks,
    this.contactEmail,
    this.contactPhone,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (bio != null) json['bio'] = bio;
    if (venueType != null) json['venueType'] = venueType!.value;
    if (location != null) json['location'] = location!.toJson();
    if (capacity != null) json['capacity'] = capacity;
    if (galleryUrls != null) json['galleryUrls'] = galleryUrls;
    if (amenities != null) json['amenities'] = amenities;
    if (operatingHours != null) {
      json['operatingHours'] = operatingHours!.map((e) => e.toJson()).toList();
    }
    if (gigPreferences != null)
      json['gigPreferences'] = gigPreferences!.toJson();
    if (budgetRange != null) json['budgetRange'] = budgetRange!.toJson();
    if (socialLinks != null) json['socialLinks'] = socialLinks!.toJson();
    if (contactEmail != null) json['contactEmail'] = contactEmail;
    if (contactPhone != null) json['contactPhone'] = contactPhone;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }
}
