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

/// Venue Types (matches backend VenueType enum)
class VenueTypes {
  static const List<String> types = [
    'Bar',
    'Restaurant',
    'Club',
    'Concert Hall',
    'Hotel',
    'Lounge',
    'Cafe',
    'Brewery',
    'Winery',
    'Theater',
    'Jazz Club',
    'Rock Venue',
    'Outdoor Venue',
    'Corporate Event Space',
    'Wedding Venue',
    'Community Center',
    'Festival Grounds',
    'Private Event Space',
    'Recording Studio',
    'Rehearsal Space',
    'Other',
  ];

  static String toBackendValue(String displayName) {
    final mapping = {
      'Bar': 'bar',
      'Restaurant': 'restaurant',
      'Club': 'club',
      'Concert Hall': 'concert_hall',
      'Hotel': 'hotel',
      'Lounge': 'lounge',
      'Cafe': 'cafe',
      'Brewery': 'brewery',
      'Winery': 'winery',
      'Theater': 'theater',
      'Jazz Club': 'jazz_club',
      'Rock Venue': 'rock_venue',
      'Outdoor Venue': 'outdoor_venue',
      'Corporate Event Space': 'corporate_event_space',
      'Wedding Venue': 'wedding_venue',
      'Community Center': 'community_center',
      'Festival Grounds': 'festival_grounds',
      'Private Event Space': 'private_event_space',
      'Recording Studio': 'recording_studio',
      'Rehearsal Space': 'rehearsal_space',
      'Other': 'other',
    };
    return mapping[displayName] ?? 'other';
  }

  static String fromBackendValue(String backendValue) {
    final mapping = {
      'bar': 'Bar',
      'restaurant': 'Restaurant',
      'club': 'Club',
      'concert_hall': 'Concert Hall',
      'hotel': 'Hotel',
      'lounge': 'Lounge',
      'cafe': 'Cafe',
      'brewery': 'Brewery',
      'winery': 'Winery',
      'theater': 'Theater',
      'jazz_club': 'Jazz Club',
      'rock_venue': 'Rock Venue',
      'outdoor_venue': 'Outdoor Venue',
      'corporate_event_space': 'Corporate Event Space',
      'wedding_venue': 'Wedding Venue',
      'community_center': 'Community Center',
      'festival_grounds': 'Festival Grounds',
      'private_event_space': 'Private Event Space',
      'recording_studio': 'Recording Studio',
      'rehearsal_space': 'Rehearsal Space',
      'other': 'Other',
    };
    return mapping[backendValue] ?? 'Other';
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
  set latLng(double lat, double lng) {
    coordinates = [lng, lat];
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
  final String venueName;
  final String? venueType;
  final String? description;
  final int? capacity;
  final String? profilePhotoUrl;
  final VenueLocation? location;
  final double? reviewStatsAverageRating;
  final int? totalGigsHosted;
  final bool isVerified;
  final bool isOpenForBookings;
  final int profileCompleteness;
  final bool hasCompletedSetup;
  final DateTime? createdAt;

  Venue({
    required this.id,
    required this.userId,
    required this.venueName,
    this.venueType,
    this.description,
    this.capacity,
    this.profilePhotoUrl,
    this.location,
    this.reviewStatsAverageRating,
    this.totalGigsHosted,
    this.isVerified = false,
    this.isOpenForBookings = true,
    this.profileCompleteness = 0,
    this.hasCompletedSetup = false,
    this.createdAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    VenueLocation? location;
    if (json['location'] != null) {
      location = VenueLocation.fromJson(json['location']);
    }

    return Venue(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user'] ?? '',
      venueName: json['venueName'] ?? '',
      venueType: json['venueType'],
      description: json['description'],
      capacity: json['capacity'],
      profilePhotoUrl: json['profilePhotoUrl'],
      location: location,
      reviewStatsAverageRating = json['reviewStats']?['averageRating']?.toDouble(),
      totalGigsHosted = json['totalGigsHosted'],
      isVerified: json['isVerified'] ?? false,
      isOpenForBookings: json['isOpenForBookings'] ?? true,
      profileCompleteness: json['profileCompleteness'] ?? 0,
      hasCompletedSetup: json['hasCompletedSetup'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'venueName': venueName,
    'venueType': venueType,
    if (description != null) 'description': description,
    if (capacity != null) 'capacity': capacity,
    if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
    if (location != null) 'location': location!.toJson(),
    'isVerified': isVerified,
    'isOpenForBookings': isOpenForBookings,
    'profileCompleteness': profileCompleteness,
    'hasCompletedSetup': hasCompletedSetup,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}
