/// 🏢 GIGMATCH Venue Models - BULLETPROOF VERSION
///
/// Updated to sync with NestJS backend DTOs:
/// - venue.schema.ts (877 lines)
/// - complete-venue-setup.dto.ts (1063 lines)
///
/// Features:
/// - Complete field mapping to backend DTOs
/// - GeoJSON coordinate format [lng, lat]
/// - Validation aligned with backend
/// - Profile completeness scoring
library;

import 'user_models.dart';

/// Venue Type Enum (matches backend VenueType enum)
enum VenueType {
  bar('bar', 'Bar'),
  restaurant('restaurant', 'Restaurant'),
  club('club', 'Club'),
  concertHall('concert_hall', 'Concert Hall'),
  hotel('hotel', 'Hotel'),
  lounge('lounge', 'Lounge'),
  cafe('cafe', 'Cafe'),
  brewery('brewery', 'Brewery'),
  winery('winery', 'Winery'),
  theater('theater', 'Theater'),
  jazzClub('jazz_club', 'Jazz Club'),
  rockVenue('rock_venue', 'Rock Venue'),
  outdoorVenue('outdoor_venue', 'Outdoor Venue'),
  corporateEventSpace('corporate_event_space', 'Corporate Event Space'),
  weddingVenue('wedding_venue', 'Wedding Venue'),
  communityCenter('community_center', 'Community Center'),
  festivalGrounds('festival_grounds', 'Festival Grounds'),
  privateEventSpace('private_event_space', 'Private Event Space'),
  recordingStudio('recording_studio', 'Recording Studio'),
  rehearsalSpace('rehearsal_space', 'Rehearsal Space'),
  other('other', 'Other');

  const VenueType(this.value, this.displayName);

  final String value;
  final String displayName;

  static VenueType fromString(String value) {
    return VenueType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => VenueType.other,
    );
  }

  static String fromBackendValue(String backendValue) {
    return VenueType.fromString(backendValue).displayName;
  }
}

/// Social Links Model for compatibility
class VenueSocialLinksCompat {
  String? instagram;
  String? website;
  String? facebook;
  String? twitter;
  String? tiktok;
  String? soundcloud;
  String? spotify;
  String? youtube;
  String? linkedin;

  VenueSocialLinksCompat({
    this.instagram,
    this.website,
    this.facebook,
    this.twitter,
    this.tiktok,
    this.soundcloud,
    this.spotify,
    this.youtube,
    this.linkedin,
  });

  Map<String, dynamic> toJson() => {
    if (instagram != null) 'instagram': instagram,
    if (website != null) 'website': website,
    if (facebook != null) 'facebook': facebook,
    if (twitter != null) 'twitter': twitter,
    if (tiktok != null) 'tiktok': tiktok,
    if (soundcloud != null) 'soundcloud': soundcloud,
    if (spotify != null) 'spotify': spotify,
    if (youtube != null) 'youtube': youtube,
    if (linkedin != null) 'linkedin': linkedin,
  };
}

/// Budget Range Model for compatibility
class BudgetRange {
  final double? min;
  final double? max;
  final String? currency;

  BudgetRange({
    this.min,
    this.max,
    this.currency,
  });

  Map<String, dynamic> toJson() => {
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (currency != null) 'currency': currency,
  };
}

/// Venue Types Helper Class
class VenueTypes {
  static List<String> get types => VenueType.values.map((e) => e.displayName).toList();

  static String toBackendValue(String displayName) {
    try {
      final type = VenueType.values.firstWhere(
        (e) => e.displayName == displayName,
      );
      return type.value;
    } catch (e) {
      return 'other';
    }
  }

  static String fromBackendValue(String backendValue) {
    try {
      final type = VenueType.values.firstWhere(
        (e) => e.value == backendValue,
      );
      return type.displayName;
    } catch (e) {
      return 'Other';
    }
  }

  static VenueType fromDisplayName(String displayName) {
    return VenueType.values.firstWhere(
      (e) => e.displayName == displayName,
      orElse: () => VenueType.other,
    );
  }

  static String toDisplayName(VenueType type) {
    return type.displayName;
  }
}

/// Venue Amenities (matches backend COMMON_AMENITIES)
class VenueAmenities {
  static const List<String> amenities = [
    'Professional Stage',
    'Sound System',
    'Stage Monitors',
    'Lighting System',
    'DJ Equipment',
    'Projector',
    'Microphones',
    'Backline',
    'Piano',
    'Drums',
    'Green Room',
    'Dressing Room',
    'Loading Dock',
    'Parking',
    'Valet Parking',
    'Wheelchair Accessible',
    'Outdoor Seating',
    'VIP Area',
    'Catering',
    'Full Bar',
    'Kitchen',
    'WiFi',
    'Air Conditioning',
    'Heating',
  ];
}

/// Gig Types (matches backend GigType enum)
class GigTypes {
  static const List<String> types = [
    'Open Mic',
    'Cover Band',
    'Original Music',
    'DJ Set',
    'Live Band',
    'Acoustic',
    'Private Event',
    'Corporate Event',
    'Wedding',
    'Fundraiser',
    'Festival',
    'Residency',
  ];

  static String toBackendValue(String displayName) {
    final mapping = {
      'Open Mic': 'open_mic',
      'Cover Band': 'cover_band',
      'Original Music': 'original_music',
      'DJ Set': 'dj_set',
      'Live Band': 'live_band',
      'Acoustic': 'acoustic',
      'Private Event': 'private_event',
      'Corporate Event': 'corporate_event',
      'Wedding': 'wedding',
      'Fundraiser': 'fundraiser',
      'Festival': 'festival',
      'Residency': 'residency',
    };
    return mapping[displayName] ?? 'original_music';
  }
}

/// Valid genres for venue preferences (matches backend VALID_VENUE_GENRES)
class ValidVenueGenres {
  static const List<String> genres = [
    'Rock',
    'Pop',
    'Jazz',
    'Hip-Hop',
    'Electronic',
    'R&B',
    'Country',
    'Classical',
    'Folk',
    'Metal',
    'Indie',
    'Blues',
    'Reggae',
    'Latin',
    'Soul',
    'Funk',
    'Alternative',
    'Punk',
    'Gospel',
    'World',
    'K-Pop',
    'EDM',
    'House',
    'Techno',
    'Ambient',
    'Musical Theatre',
    'Acoustic',
    'Bluegrass',
    'Celtic',
    'Afrobeat',
    'All Genres',
  ];
}

/// Payment Types (matches backend PaymentType enum)
class PaymentTypes {
  static const List<String> types = [
    'Fixed Fee',
    'Door Split',
    'Hourly Rate',
    'Negotiable',
    'No Pay',
    'Tip Based',
  ];

  static String toBackendValue(String displayName) {
    final mapping = {
      'Fixed Fee': 'fixed_fee',
      'Door Split': 'door_split',
      'Hourly Rate': 'hourly_rate',
      'Negotiable': 'negotiable',
      'No Pay': 'no_pay',
      'Tip Based': 'tip_based',
    };
    return mapping[displayName] ?? 'negotiable';
  }
}

/// Currencies (matches backend Currency enum)
class Currencies {
  static const List<String> codes = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'INR', 'JPY'];
}

/// Operating Hours Model
class OperatingHours {
  String? dayOfWeek;
  String? openTime;
  String? closeTime;
  bool isOpen = true;
  String? notes;

  OperatingHours({
    this.dayOfWeek,
    this.openTime,
    this.closeTime,
    this.isOpen = true,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
    if (openTime != null) 'openTime': openTime,
    if (closeTime != null) 'closeTime': closeTime,
    'isOpen': isOpen,
    if (notes != null) 'notes': notes,
  };

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      dayOfWeek: json['dayOfWeek'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      isOpen: json['isOpen'] ?? true,
      notes: json['notes'],
    );
  }
}

/// Equipment Model (matches backend VenueEquipment)
class VenueEquipment {
  bool hasSoundSystem = false;
  String? soundSystemDetails;
  bool hasLighting = false;
  String? lightingDetails;
  bool hasStage = false;
  bool hasBackline = false;
  String? backlineDetails;
  bool hasDressingRoom = false;
  bool hasGreenRoom = false;
  bool hasParking = false;
  String? parkingDetails;
  bool hasValet = false;
  bool hasCatering = false;
  bool hasBar = false;
  bool hasKitchen = false;
  bool hasOutdoorSpace = false;
  bool hasAirConditioning = false;
  bool hasHeating = false;
  bool isWheelchairAccessible = false;
  bool hasWifi = false;
  String? wifiDetails;
  bool hasProjector = false;
  bool hasMicrophones = false;
  List<String> additionalEquipment = [];
  String? equipmentNotes;

  /// Default constructor
  VenueEquipment();

  Map<String, dynamic> toJson() => {
    'hasSoundSystem': hasSoundSystem,
    if (soundSystemDetails != null) 'soundSystemDetails': soundSystemDetails,
    'hasLighting': hasLighting,
    if (lightingDetails != null) 'lightingDetails': lightingDetails,
    'hasStage': hasStage,
    'hasBackline': hasBackline,
    if (backlineDetails != null) 'backlineDetails': backlineDetails,
    'hasDressingRoom': hasDressingRoom,
    'hasGreenRoom': hasGreenRoom,
    'hasParking': hasParking,
    if (parkingDetails != null) 'parkingDetails': parkingDetails,
    'hasValet': hasValet,
    'hasCatering': hasCatering,
    'hasBar': hasBar,
    'hasKitchen': hasKitchen,
    'hasOutdoorSpace': hasOutdoorSpace,
    'hasAirConditioning': hasAirConditioning,
    'hasHeating': hasHeating,
    'isWheelchairAccessible': isWheelchairAccessible,
    'hasWifi': hasWifi,
    if (wifiDetails != null) 'wifiDetails': wifiDetails,
    'hasProjector': hasProjector,
    'hasMicrophones': hasMicrophones,
    if (additionalEquipment.isNotEmpty) 'additionalEquipment': additionalEquipment,
    if (equipmentNotes != null) 'equipmentNotes': equipmentNotes,
  };

  factory VenueEquipment.fromJson(Map<String, dynamic> json) {
    final equipment = VenueEquipment();
    equipment.hasSoundSystem = json['hasSoundSystem'] ?? false;
    equipment.soundSystemDetails = json['soundSystemDetails'];
    equipment.hasLighting = json['hasLighting'] ?? false;
    equipment.lightingDetails = json['lightingDetails'];
    equipment.hasStage = json['hasStage'] ?? false;
    equipment.hasBackline = json['hasBackline'] ?? false;
    equipment.backlineDetails = json['backlineDetails'];
    equipment.hasDressingRoom = json['hasDressingRoom'] ?? false;
    equipment.hasGreenRoom = json['hasGreenRoom'] ?? false;
    equipment.hasParking = json['hasParking'] ?? false;
    equipment.parkingDetails = json['parkingDetails'];
    equipment.hasValet = json['hasValet'] ?? false;
    equipment.hasCatering = json['hasCatering'] ?? false;
    equipment.hasBar = json['hasBar'] ?? false;
    equipment.hasKitchen = json['hasKitchen'] ?? false;
    equipment.hasOutdoorSpace = json['hasOutdoorSpace'] ?? false;
    equipment.hasAirConditioning = json['hasAirConditioning'] ?? false;
    equipment.hasHeating = json['hasHeating'] ?? false;
    equipment.isWheelchairAccessible = json['isWheelchairAccessible'] ?? false;
    equipment.hasWifi = json['hasWifi'] ?? false;
    equipment.wifiDetails = json['wifiDetails'];
    equipment.hasProjector = json['hasProjector'] ?? false;
    equipment.hasMicrophones = json['hasMicrophones'] ?? false;
    if (json['additionalEquipment'] != null) {
      equipment.additionalEquipment = List<String>.from(json['additionalEquipment']);
    }
    equipment.equipmentNotes = json['equipmentNotes'];
    return equipment;
  }
}

/// Social Links Model
class VenueSocialLinks {
  String? instagram;
  String? facebook;
  String? twitter;
  String? website;
  String? yelp;
  String? googleMaps;
  String? tiktok;

  /// Default constructor
  VenueSocialLinks();

  Map<String, dynamic> toJson() => {
    if (instagram != null) 'instagram': _normalizeSocialHandle(instagram!),
    if (facebook != null) 'facebook': _normalizeUrl(facebook!),
    if (twitter != null) 'twitter': _normalizeSocialHandle(twitter!),
    if (website != null) 'website': _normalizeUrl(website!),
    if (yelp != null) 'yelp': _normalizeUrl(yelp!),
    if (googleMaps != null) 'googleMaps': _normalizeUrl(googleMaps!),
    if (tiktok != null) 'tiktok': _normalizeSocialHandle(tiktok!),
  };

  factory VenueSocialLinks.fromJson(Map<String, dynamic> json) {
    return VenueSocialLinks()
      ..instagram = json['instagram']
      ..facebook = json['facebook']
      ..twitter = json['twitter']
      ..website = json['website']
      ..yelp = json['yelp']
      ..googleMaps = json['googleMaps']
      ..tiktok = json['tiktok'];
  }

  static String _normalizeUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    if (input.startsWith('www.')) {
      return 'https://$input';
    }
    return 'https://$input';
  }

  static String _normalizeSocialHandle(String input) {
    if (input.startsWith('@')) {
      return input.substring(1);
    }
    if (input.startsWith('http')) {
      return input;
    }
    return input;
  }
}

/// Photo Gallery Model
class VenuePhoto {
  String url;
  String? caption;
  int order = 0;
  bool isPrimary = false;
  DateTime? uploadedAt;

  VenuePhoto({
    required this.url,
    this.caption,
    this.order = 0,
    this.isPrimary = false,
    this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    if (caption != null) 'caption': caption,
    'order': order,
    'isPrimary': isPrimary,
    if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
  };

  factory VenuePhoto.fromJson(Map<String, dynamic> json) {
    return VenuePhoto(
      url: json['url'] ?? '',
      caption: json['caption'],
      order: json['order'] ?? 0,
      isPrimary: json['isPrimary'] ?? false,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'])
          : null,
    );
  }
}

/// Virtual Tour Model
class VirtualTour {
  String? tourUrl;
  String? videoUrl;
  String? googleMapsUrl;

  /// Default constructor
  VirtualTour();

  Map<String, dynamic> toJson() => {
    if (tourUrl != null) 'tourUrl': tourUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (googleMapsUrl != null) 'googleMapsUrl': googleMapsUrl,
  };

  factory VirtualTour.fromJson(Map<String, dynamic> json) {
    return VirtualTour()
      ..tourUrl = json['tourUrl']
      ..videoUrl = json['videoUrl']
      ..googleMapsUrl = json['googleMapsUrl'];
  }
}

/// Location Model with GeoJSON format
class VenueLocation {
  String? type;
  List<double> coordinates; // [longitude, latitude] - GeoJSON format
  String? streetAddress;
  String? city;
  String? state;
  String? country;
  String? postalCode;
  String? formattedAddress;
  String? neighborhood;

  VenueLocation({
    this.type = 'Point',
    List<double>? coordinates,
    this.streetAddress,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.formattedAddress,
    this.neighborhood,
  }) : coordinates = coordinates ?? [0.0, 0.0];

  /// Get longitude (GeoJSON format: [lng, lat])
  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;

  /// Get latitude (GeoJSON format: [lng, lat])
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;

  /// Set coordinates from lat/lng (converts to GeoJSON [lng, lat])
  set lat(double lat) {
    if (coordinates.isNotEmpty) {
      coordinates[1] = lat;
    } else {
      coordinates = [0.0, lat];
    }
  }

  /// Set longitude coordinate
  set lng(double lng) {
    if (coordinates.isNotEmpty) {
      coordinates[0] = lng;
    } else {
      coordinates = [lng, 0.0];
    }
  }

  /// Check if coordinates are valid (not [0,0])
  bool get hasValidCoordinates {
    return longitude != 0.0 && latitude != 0.0;
  }

  Map<String, dynamic> toJson() => {
    'type': type ?? 'Point',
    'coordinates': coordinates,
    if (streetAddress != null) 'streetAddress': streetAddress,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (country != null) 'country': country,
    if (postalCode != null) 'postalCode': postalCode,
    if (formattedAddress != null) 'formattedAddress': formattedAddress,
    if (neighborhood != null) 'neighborhood': neighborhood,
  };

  factory VenueLocation.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'];
    List<double> coordinates = [0.0, 0.0];
    if (coords is List && coords.length >= 2) {
      coordinates = [
        (coords[0] as num).toDouble(),
        (coords[1] as num).toDouble(),
      ];
    }
    return VenueLocation(
      type: json['type'] ?? 'Point',
      coordinates: coordinates,
      streetAddress: json['streetAddress'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
      formattedAddress: json['formattedAddress'],
      neighborhood: json['neighborhood'],
    );
  }
}

/// Gig Preferences Model (matches backend GigPreferencesDto)
class GigPreferences {
  List<String> preferredGenres = [];
  List<String> gigTypes = [];
  String? paymentType;
  double minBudget = 0;
  double maxBudget = 0;
  String currency = 'USD';
  double avgGigDuration = 3;
  bool providesMusicianMeals = false;
  bool providesGreenRoomRefreshments = false;
  String? notesForArtists;
  bool openToNewArtists = true;
  bool acceptsDemos = false;
  String? demoSubmissionEmail;

  /// Default constructor
  GigPreferences();

  Map<String, dynamic> toJson() => {
    'preferredGenres': preferredGenres,
    'gigTypes': gigTypes.map((e) => GigTypes.toBackendValue(e)).toList(),
    if (paymentType != null) 'paymentType': PaymentTypes.toBackendValue(paymentType!),
    'minBudget': minBudget,
    'maxBudget': maxBudget,
    'currency': currency,
    'avgGigDuration': avgGigDuration,
    'providesMusicianMeals': providesMusicianMeals,
    'providesGreenRoomRefreshments': providesGreenRoomRefreshments,
    if (notesForArtists != null) 'notesForArtists': notesForArtists,
    'openToNewArtists': openToNewArtists,
    'acceptsDemos': acceptsDemos,
    if (demoSubmissionEmail != null) 'demoSubmissionEmail': demoSubmissionEmail,
  };

  factory GigPreferences.fromJson(Map<String, dynamic> json) {
    final prefs = GigPreferences();
    if (json['preferredGenres'] != null) {
      prefs.preferredGenres = List<String>.from(json['preferredGenres']);
    }
    if (json['gigTypes'] != null) {
      prefs.gigTypes = List<String>.from(json['gigTypes']);
    }
    prefs.paymentType = json['paymentType'];
    prefs.minBudget = (json['minBudget'] ?? 0).toDouble();
    prefs.maxBudget = (json['maxBudget'] ?? 0).toDouble();
    prefs.currency = json['currency'] ?? 'USD';
    prefs.avgGigDuration = (json['avgGigDuration'] ?? 3).toDouble();
    prefs.providesMusicianMeals = json['providesMusicianMeals'] ?? false;
    prefs.providesGreenRoomRefreshments = json['providesGreenRoomRefreshments'] ?? false;
    prefs.notesForArtists = json['notesForArtists'];
    prefs.openToNewArtists = json['openToNewArtists'] ?? true;
    prefs.acceptsDemos = json['acceptsDemos'] ?? false;
    prefs.demoSubmissionEmail = json['demoSubmissionEmail'];
    return prefs;
  }
}

/// Venue Profile Data Model for Onboarding (matches backend CompleteVenueSetupDto)
class VenueProfileData {
  // ═══════════════════════════════════════════════════════════════════════
  // STEP 1: BASIC INFO
  // ═══════════════════════════════════════════════════════════════════════
  String? venueName;
  String? venueType; // Display name (e.g., 'Jazz Club')
  String? description;
  int capacity = 100;
  List<String> amenities = [];

  String? contactPerson;
  String? contactRole;
  int? yearEstablished;

  // Additional convenience properties for backward compatibility
  String? get city => location.city;
  set city(String? value) => location.city = value;
  String? get country => location.country;
  set country(String? value) => location.country = value;
  String? get address => location.formattedAddress;
  set address(String? value) => location.formattedAddress = value;
  double? get minBudget => gigPreferences.minBudget;
  set minBudget(double? value) => gigPreferences.minBudget = value ?? 0;
  double? get maxBudget => gigPreferences.maxBudget;
  set maxBudget(double? value) => gigPreferences.maxBudget = value ?? 0;
  String? get currency => gigPreferences.currency;
  set currency(String? value) => gigPreferences.currency = value ?? 'USD';
  String? get instagram => socialLinks.instagram;
  set instagram(String? value) => socialLinks.instagram = value;
  String? get website => socialLinks.website;
  set website(String? value) => socialLinks.website = value;
  bool? get showPhone => showPhoneOnProfile;
  set showPhone(bool? value) => showPhoneOnProfile = value ?? false;
  String? get email => bookingEmail;
  set email(String? value) => bookingEmail = value;
  List<String> get typicalSlots => [];
  set typicalSlots(List<String> value) { /* no-op for now */ }
  int get typicalSetLength => 180; // 3 hours default
  set typicalSetLength(int value) { /* no-op for now */ }
  bool get providesEquipment => false;
  set providesEquipment(bool value) { /* no-op for now */ }
  bool get providesMeals => gigPreferences.providesMusicianMeals;
  set providesMeals(bool value) => gigPreferences.providesMusicianMeals = value;
  bool get providesAccommodation => false;
  set providesAccommodation(bool value) { /* no-op for now */ }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 2: MEDIA
  // ═══════════════════════════════════════════════════════════════════════
  String? profilePhotoUrl;
  List<VenuePhoto> photoGallery = [];
  VirtualTour? virtualTour;

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 3: DETAILS & LOCATION
  // ═══════════════════════════════════════════════════════════════════════
  String? phone;
  bool showPhoneOnProfile = false;
  String? bookingEmail;
  String? eventsEmail;
  VenueLocation location = VenueLocation();
  List<OperatingHours> operatingHours = [];
  VenueEquipment equipment = VenueEquipment();
  VenueSocialLinks socialLinks = VenueSocialLinks();
  String? directions;
  String? loadInInstructions;

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 4: GIG PREFERENCES (Direct Properties for Convenience)
  // ═══════════════════════════════════════════════════════════════════════
  List<String> preferredGenres = [];

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 4: GIG PREFERENCES
  // ═══════════════════════════════════════════════════════════════════════
  GigPreferences gigPreferences = GigPreferences();

  // ═══════════════════════════════════════════════════════════════════════
  // PREFERENCES & DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════
  bool isActive = true;
  bool isVisible = true;
  String? houseRules;
  bool hasPromotedActs = false;
  List<String> notablePastActs = [];

  // ═══════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Get backend venue type value
  String? get backendVenueType {
    if (venueType == null) return null;
    return VenueTypes.toBackendValue(venueType!);
  }

  /// Convert location to backend format with [lng, lat]
  Map<String, dynamic>? get locationPayload {
    if (location.city == null || location.country == null) {
      return null;
    }

    final payload = <String, dynamic>{
      'city': location.city,
      'country': location.country,
    };

    if (location.streetAddress != null) {
      payload['streetAddress'] = location.streetAddress;
    }
    if (location.state != null) {
      payload['state'] = location.state;
    }
    if (location.postalCode != null) {
      payload['postalCode'] = location.postalCode;
    }
    if (location.neighborhood != null) {
      payload['neighborhood'] = location.neighborhood;
    }

    // Only include coordinates if valid (not [0,0])
    if (location.hasValidCoordinates) {
      payload['coordinates'] = location.coordinates; // [lng, lat]
    }

    return payload;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Reset all data
  void reset() {
    venueName = null;
    venueType = null;
    description = null;
    capacity = 100;
    amenities.clear();
    contactPerson = null;
    contactRole = null;
    yearEstablished = null;
    profilePhotoUrl = null;
    photoGallery.clear();
    virtualTour = null;
    phone = null;
    showPhoneOnProfile = false;
    bookingEmail = null;
    eventsEmail = null;
    location = VenueLocation();
    operatingHours.clear();
    equipment = VenueEquipment();
    socialLinks = VenueSocialLinks();
    directions = null;
    loadInInstructions = null;
    gigPreferences = GigPreferences();
    isActive = true;
    isVisible = true;
    houseRules = null;
    hasPromotedActs = false;
    notablePastActs.clear();
  }

  /// Validate required fields for profile completion
  List<String> validate() {
    final errors = <String>[];

    // Step 1: Basic Info
    if (venueName == null || venueName!.trim().isEmpty) {
      errors.add('Venue name is required');
    }
    if (venueName != null && venueName!.trim().length < 2) {
      errors.add('Venue name must be at least 2 characters');
    }
    if (venueType == null || venueType!.trim().isEmpty) {
      errors.add('Venue type is required');
    }

    // Step 3: Location
    if (location.city == null || location.city!.trim().isEmpty) {
      errors.add('City is required');
    }
    if (location.country == null || location.country!.trim().isEmpty) {
      errors.add('Country is required');
    }

    // Step 4: Gig Preferences
    if (gigPreferences.preferredGenres.isEmpty) {
      errors.add('Select at least one preferred genre');
    }

    return errors;
  }

  /// Convert to backend DTO format (matches CompleteVenueSetupDto)
  Map<String, dynamic> toBackendDto() {
    final dto = <String, dynamic>{};

    // ═══════════════════════════════════════════════════════════════════
    // STEP 1: BASIC INFO
    // ═══════════════════════════════════════════════════════════════════
    dto['venueName'] = venueName;
    if (backendVenueType != null) {
      dto['venueType'] = backendVenueType;
    }
    if (description != null && description!.isNotEmpty) {
      dto['description'] = description;
    }
    if (capacity > 0) {
      dto['capacity'] = capacity;
    }
    if (amenities.isNotEmpty) {
      dto['amenities'] = amenities;
    }
    if (contactPerson != null) {
      dto['contactPerson'] = contactPerson;
    }
    if (contactRole != null) {
      dto['contactRole'] = contactRole;
    }
    if (yearEstablished != null) {
      dto['yearEstablished'] = yearEstablished;
    }

    // ═══════════════════════════════════════════════════════════════════
    // STEP 2: MEDIA
    // ═══════════════════════════════════════════════════════════════════
    if (profilePhotoUrl != null) {
      dto['profilePhotoUrl'] = profilePhotoUrl;
    }
    if (photoGallery.isNotEmpty) {
      dto['photoGallery'] = photoGallery.map((p) => p.toJson()).toList();
    }
    if (virtualTour != null) {
      dto['virtualTour'] = virtualTour!.toJson();
    }

    // ═══════════════════════════════════════════════════════════════════
    // STEP 3: DETAILS & LOCATION
    // ═══════════════════════════════════════════════════════════════════
    if (phone != null) {
      dto['phone'] = phone;
    }
    dto['showPhoneOnProfile'] = showPhoneOnProfile;
    if (bookingEmail != null) {
      dto['bookingEmail'] = bookingEmail;
    }
    if (eventsEmail != null) {
      dto['eventsEmail'] = eventsEmail;
    }

    // Location (required for completion)
    final locPayload = locationPayload;
    if (locPayload != null) {
      dto['location'] = locPayload;
    }

    // Operating Hours
    if (operatingHours.isNotEmpty) {
      dto['operatingHours'] = {
        'monday': operatingHours[0].toJson(),
        'tuesday': operatingHours[1].toJson(),
        'wednesday': operatingHours[2].toJson(),
        'thursday': operatingHours[3].toJson(),
        'friday': operatingHours[4].toJson(),
        'saturday': operatingHours[5].toJson(),
        'sunday': operatingHours[6].toJson(),
      };
    }

    // Equipment
    dto['equipment'] = equipment.toJson();

    // Social Links
    final socialJson = socialLinks.toJson();
    if (socialJson.isNotEmpty) {
      dto['socialLinks'] = socialJson;
    }

    if (directions != null) {
      dto['directions'] = directions;
    }
    if (loadInInstructions != null) {
      dto['loadInInstructions'] = loadInInstructions;
    }

    // ═══════════════════════════════════════════════════════════════════
    // STEP 4: GIG PREFERENCES
    // ═══════════════════════════════════════════════════════════════════
    dto['gigPreferences'] = gigPreferences.toJson();

    // ═══════════════════════════════════════════════════════════════════
    // PREFERENCES & DISCOVERY
    // ═══════════════════════════════════════════════════════════════════
    dto['isActive'] = isActive;
    dto['isVisible'] = isVisible;
    if (houseRules != null) {
      dto['houseRules'] = houseRules;
    }
    dto['hasPromotedActs'] = hasPromotedActs;
    if (notablePastActs.isNotEmpty) {
      dto['notablePastActs'] = notablePastActs;
    }

    return dto;
  }

  /// Get profile completion percentage (0-100)
  int getCompletionPercentage() {
    int score = 0;
    const maxScore = 100;

    // Basic Info (25 points)
    if (venueName != null && venueName!.isNotEmpty) score += 5;
    if (description != null && description!.length >= 50) score += 10;
    if (venueType != null) score += 5;
    if (capacity > 0) score += 5;

    // Location (15 points)
    if (location.city != null) score += 5;
    if (location.streetAddress != null) score += 5;
    if (location.hasValidCoordinates) score += 5;

    // Contact (15 points)
    if (phone != null) score += 5;
    if (bookingEmail != null) score += 5;
    if (socialLinks.website != null) score += 5;

    // Media (20 points)
    if (profilePhotoUrl != null) score += 10;
    if (photoGallery.isNotEmpty) score += 5;
    if (virtualTour?.googleMapsUrl != null) score += 5;

    // Equipment (10 points)
    if (equipment.hasSoundSystem) score += 5;
    if (equipment.hasStage) score += 5;

    // Preferences (10 points)
    if (gigPreferences.preferredGenres.isNotEmpty) score += 5;
    if (gigPreferences.minBudget > 0 || gigPreferences.maxBudget > 0) score += 5;

    // Additional (5 points)
    if (amenities.isNotEmpty) score += 5;

    return (score * maxScore / 100).round();
  }

  /// Check if profile is complete enough for submission
  bool get isSetupReady {
    return getCompletionPercentage() >= 50;
  }

  /// Check if profile is fully complete
  bool get isFullyComplete {
    return getCompletionPercentage() >= 80;
  }

  /// Parse backend response to update local model
  void updateFromBackendResponse(Map<String, dynamic> json) {
    // Basic Info
    venueName = json['venueName'];
    venueType = json['venueType'] != null
        ? VenueTypes.fromBackendValue(json['venueType'])
        : null;
    description = json['description'];
    capacity = json['capacity'] ?? 100;
    if (json['amenities'] != null) {
      amenities = List<String>.from(json['amenities']);
    }
    contactPerson = json['contactPerson'];
    contactRole = json['contactRole'];
    yearEstablished = json['yearEstablished'];

    // Media
    profilePhotoUrl = json['profilePhotoUrl'];
    if (json['photoGallery'] != null) {
      photoGallery = (json['photoGallery'] as List)
          .map((p) => VenuePhoto.fromJson(p))
          .toList();
    }
    if (json['virtualTour'] != null) {
      virtualTour = VirtualTour.fromJson(json['virtualTour']);
    }

    // Location & Contact
    phone = json['phone'];
    showPhoneOnProfile = json['showPhoneOnProfile'] ?? false;
    bookingEmail = json['bookingEmail'];
    eventsEmail = json['eventsEmail'];
    if (json['location'] != null) {
      location = VenueLocation.fromJson(json['location']);
    }
    if (json['equipment'] != null) {
      equipment = VenueEquipment.fromJson(json['equipment']);
    }
    if (json['socialLinks'] != null) {
      socialLinks = VenueSocialLinks.fromJson(json['socialLinks']);
    }
    directions = json['directions'];
    loadInInstructions = json['loadInInstructions'];

    // Gig Preferences
    if (json['gigPreferences'] != null) {
      gigPreferences = GigPreferences.fromJson(json['gigPreferences']);
    }

    // Other
    isActive = json['isActive'] ?? true;
    isVisible = json['isVisible'] ?? true;
    houseRules = json['houseRules'];
    hasPromotedActs = json['hasPromotedActs'] ?? false;
    if (json['notablePastActs'] != null) {
      notablePastActs = List<String>.from(json['notablePastActs']);
    }
  }
}

/// Venue model for API responses (matches backend Venue schema)
class Venue {
  final String id;
  final String userId;
  final String name;
  final String? bio;
  final String? description;
  final String? venueType;
  final int? capacity;
  final String? profilePhotoUrl;
  final List<String>? galleryUrls;
  final VenueLocation? location;
  final String? displayLocation;
  final Map<String, dynamic>? gigPreferences;
  final double? reviewStatsAverageRating;
  final int? totalGigsHosted;
  final int? reviewCount;
  final double? rating;
  final bool isVerified;
  final bool isOpenForBookings;
  final int profileCompleteness;
  final bool hasCompletedSetup;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Additional properties for compatibility
  String get primaryPhoto => profilePhotoUrl ?? '';

  Venue({
    required this.id,
    required this.userId,
    required this.name,
    this.bio,
    this.description,
    this.venueType,
    this.capacity,
    this.profilePhotoUrl,
    this.galleryUrls,
    this.location,
    this.displayLocation,
    this.gigPreferences,
    this.reviewStatsAverageRating,
    this.totalGigsHosted,
    this.reviewCount,
    this.rating,
    this.isVerified = false,
    this.isOpenForBookings = true,
    this.profileCompleteness = 0,
    this.hasCompletedSetup = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    VenueLocation? location;
    if (json['location'] != null) {
      location = VenueLocation.fromJson(json['location']);
    }

    return Venue(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user'] ?? '',
      name: json['name'] ?? json['venueName'] ?? '',
      bio: json['bio'],
      description: json['description'],
      venueType: json['venueType'],
      capacity: json['capacity'],
      profilePhotoUrl: json['profilePhotoUrl'],
      galleryUrls: json['galleryUrls'] != null
          ? List<String>.from(json['galleryUrls'])
          : null,
      location: location,
      displayLocation: json['displayLocation'],
      gigPreferences: json['gigPreferences'],
      reviewStatsAverageRating: json['reviewStats']?['averageRating']?.toDouble(),
      totalGigsHosted: json['totalGigsHosted'],
      reviewCount: json['reviewCount'],
      rating: json['rating']?.toDouble(),
      isVerified: json['isVerified'] ?? false,
      isOpenForBookings: json['isOpenForBookings'] ?? true,
      profileCompleteness: json['profileCompleteness'] ?? 0,
      hasCompletedSetup: json['hasCompletedSetup'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    if (bio != null) 'bio': bio,
    if (description != null) 'description': description,
    'venueType': venueType,
    if (capacity != null) 'capacity': capacity,
    if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
    if (galleryUrls != null) 'galleryUrls': galleryUrls,
    if (location != null) 'location': location!.toJson(),
    if (displayLocation != null) 'displayLocation': displayLocation,
    if (gigPreferences != null) 'gigPreferences': gigPreferences,
    'isVerified': isVerified,
    'isOpenForBookings': isOpenForBookings,
    'profileCompleteness': profileCompleteness,
    'hasCompletedSetup': hasCompletedSetup,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}
