/// 🎤 Gig Models
/// Data models for Gig discovery (Artist feed) and Venue gig management.
///
/// Notes:
/// - Backend is NestJS + MongoDB.
/// - Gig location supports exact geospatial coordinates:
///   - Backend schema stores `location.geo` as GeoJSON Point with coordinates [lng, lat].
/// - This file keeps models tolerant to backend evolution (extra fields ignored).
library;

import 'package:json_annotation/json_annotation.dart';

part 'gig_models.g.dart';

/// GeoJSON Point representation
@JsonSerializable(explicitToJson: true)
class GeoPoint {
  /// Should be "Point"
  final String type;

  /// Coordinates in [longitude, latitude]
  final List<double> coordinates;

  const GeoPoint({required this.type, required this.coordinates});

  factory GeoPoint.fromJson(Map<String, dynamic> json) =>
      _$GeoPointFromJson(json);

  Map<String, dynamic> toJson() => _$GeoPointToJson(this);

  double? get longitude => coordinates.isNotEmpty ? coordinates[0] : null;

  double? get latitude => coordinates.length > 1 ? coordinates[1] : null;
}

/// Gig location used for discovery and display.
/// Backend stores:
/// - location.city, location.country (and optional venueAddress/state/postalCode)
/// - location.geo { type: "Point", coordinates: [lng, lat] }
@JsonSerializable(explicitToJson: true)
class GigLocation {
  final String? venueAddress;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;

  /// GeoJSON Point (exact)
  final GeoPoint? geo;

  const GigLocation({
    this.venueAddress,
    required this.city,
    this.state,
    this.postalCode,
    required this.country,
    this.geo,
  });

  factory GigLocation.fromJson(Map<String, dynamic> json) =>
      _$GigLocationFromJson(json);

  Map<String, dynamic> toJson() => _$GigLocationToJson(this);

  double? get longitude => geo?.longitude;
  double? get latitude => geo?.latitude;

  String get cityCountry => '$city, $country';
}

/// Perks offered for a gig.
@JsonSerializable(explicitToJson: true)
class GigPerks {
  final bool providesFood;
  final bool providesDrinks;
  final bool providesAccommodation;
  final bool providesTransport;
  final bool providesEquipment;
  final bool providesParking;
  final List<String> additionalPerks;

  const GigPerks({
    this.providesFood = false,
    this.providesDrinks = false,
    this.providesAccommodation = false,
    this.providesTransport = false,
    this.providesEquipment = false,
    this.providesParking = false,
    this.additionalPerks = const [],
  });

  factory GigPerks.fromJson(Map<String, dynamic> json) =>
      _$GigPerksFromJson(json);

  Map<String, dynamic> toJson() => _$GigPerksToJson(this);
}

/// Application status for a gig application.
enum GigApplicationStatus {
  @JsonValue('pending')
  pending,

  @JsonValue('accepted')
  accepted,

  @JsonValue('rejected')
  rejected,

  @JsonValue('withdrawn')
  withdrawn,
}

@JsonSerializable(explicitToJson: true)
class GigApplication {
  /// Artist profile id
  final String artist;

  final DateTime appliedAt;

  final String? message;

  final double? proposedRate;

  final GigApplicationStatus status;

  const GigApplication({
    required this.artist,
    required this.appliedAt,
    this.message,
    this.proposedRate,
    required this.status,
  });

  factory GigApplication.fromJson(Map<String, dynamic> json) =>
      _$GigApplicationFromJson(json);

  Map<String, dynamic> toJson() => _$GigApplicationToJson(this);
}

/// How payment is structured.
enum GigPaymentType {
  @JsonValue('fixed')
  fixed,

  @JsonValue('negotiable')
  negotiable,

  @JsonValue('per_hour')
  perHour,
}

/// Gig status lifecycle.
enum GigStatus {
  @JsonValue('draft')
  draft,

  @JsonValue('open')
  open,

  @JsonValue('in_progress')
  inProgress,

  @JsonValue('filled')
  filled,

  @JsonValue('completed')
  completed,

  @JsonValue('cancelled')
  cancelled,
}

/// Minimal venue data sometimes returned by backend when populating gig.venue.
/// (We keep this flexible; backend may populate partial fields.)
@JsonSerializable(explicitToJson: true)
class GigVenueSummary {
  @JsonKey(name: '_id')
  final String id;

  final String? venueName;

  final String? venueType;

  final String? coverPhoto;

  final GigLocation? location;

  const GigVenueSummary({
    required this.id,
    this.venueName,
    this.venueType,
    this.coverPhoto,
    this.location,
  });

  factory GigVenueSummary.fromJson(Map<String, dynamic> json) =>
      _$GigVenueSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$GigVenueSummaryToJson(this);
}

/// Core Gig model used across:
/// - Artist discovery feed
/// - Venue gig management
@JsonSerializable(explicitToJson: true)
class Gig {
  @JsonKey(name: '_id')
  final String id;

  /// Can be an id or a populated object depending on backend query.
  /// If populated, it will map to [GigVenueSummary].
  @JsonKey(fromJson: _venueFromJson, toJson: _venueToJson)
  final GigVenueSummary? venue;

  /// User id of who posted
  final String? postedBy;

  final String title;

  final String? description;

  final DateTime date;

  final String startTime;

  final String? endTime;

  final int durationMinutes;

  final int numberOfSets;

  final List<String> requiredGenres;

  final String? specificRequirements;

  final int artistsNeeded;

  final double budget;

  final String currency;

  final GigPaymentType paymentType;

  final GigStatus status;

  /// Exact gig location (required for geo discovery on backend).
  final GigLocation location;

  final bool isPublic;

  final bool acceptingApplications;

  final GigPerks? perks;

  final int viewCount;

  final int applicationCount;

  final List<GigApplication> applications;

  final List<String> bookedArtists;

  final DateTime? cancelledAt;
  final String? cancellationReason;

  final DateTime? completedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Gig({
    required this.id,
    this.venue,
    this.postedBy,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 60,
    this.numberOfSets = 1,
    this.requiredGenres = const [],
    this.specificRequirements,
    this.artistsNeeded = 1,
    required this.budget,
    this.currency = 'USD',
    this.paymentType = GigPaymentType.fixed,
    this.status = GigStatus.draft,
    required this.location,
    this.isPublic = true,
    this.acceptingApplications = true,
    this.perks,
    this.viewCount = 0,
    this.applicationCount = 0,
    this.applications = const [],
    this.bookedArtists = const [],
    this.cancelledAt,
    this.cancellationReason,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Gig.fromJson(Map<String, dynamic> json) => _$GigFromJson(json);

  Map<String, dynamic> toJson() => _$GigToJson(this);

  /// Convenience: "Jan 8 • 19:30"
  String get dateTimeLabel {
    final d = date;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$mm/$dd • $startTime';
  }

  String get cityCountry => location.cityCountry;
}

/// Generic paginated response for gig discovery and "mine".
@JsonSerializable(explicitToJson: true)
class PaginatedGigsResponse {
  final List<Gig> items;
  final int total;
  final int page;
  final int pages;

  const PaginatedGigsResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory PaginatedGigsResponse.fromJson(Map<String, dynamic> json) =>
      _$PaginatedGigsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaginatedGigsResponseToJson(this);
}

/// Request model for creating a gig (Venue).
///
/// Matches backend CreateGigDto shape closely, including geoCoordinates as [lng, lat].
@JsonSerializable(explicitToJson: true)
class CreateGigRequest {
  final String venueId;
  final String title;
  final String? description;

  /// ISO8601 date string
  final String date;

  final String startTime;
  final String? endTime;

  final int? durationMinutes;
  final int? numberOfSets;

  final List<String>? requiredGenres;
  final String? specificRequirements;
  final int? artistsNeeded;

  final double budget;
  final String? currency;
  final GigPaymentType? paymentType;

  final CreateGigLocationRequest location;

  final bool? isPublic;
  final bool? acceptingApplications;
  final GigPerks? perks;

  /// "draft" or "open" initial
  @JsonKey(toJson: _gigStatusToWire)
  final GigStatus? status;

  const CreateGigRequest({
    required this.venueId,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.numberOfSets,
    this.requiredGenres,
    this.specificRequirements,
    this.artistsNeeded,
    required this.budget,
    this.currency,
    this.paymentType,
    required this.location,
    this.isPublic,
    this.acceptingApplications,
    this.perks,
    this.status,
  });

  factory CreateGigRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGigRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateGigRequestToJson(this);
}

/// Request model for updating a gig (Venue).
/// All fields are optional to support partial updates.
class UpdateGigRequest {
  final String? title;
  final String? description;
  final String? date;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final int? numberOfSets;
  final List<String>? requiredGenres;
  final String? specificRequirements;
  final int? artistsNeeded;
  final double? budget;
  final String? currency;
  final GigPaymentType? paymentType;
  final CreateGigLocationRequest? location;
  final bool? isPublic;
  final bool? acceptingApplications;
  final GigPerks? perks;
  final GigStatus? status;

  const UpdateGigRequest({
    this.title,
    this.description,
    this.date,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.numberOfSets,
    this.requiredGenres,
    this.specificRequirements,
    this.artistsNeeded,
    this.budget,
    this.currency,
    this.paymentType,
    this.location,
    this.isPublic,
    this.acceptingApplications,
    this.perks,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (date != null) data['date'] = date;
    if (startTime != null) data['startTime'] = startTime;
    if (endTime != null) data['endTime'] = endTime;
    if (durationMinutes != null) data['durationMinutes'] = durationMinutes;
    if (numberOfSets != null) data['numberOfSets'] = numberOfSets;
    if (requiredGenres != null) data['requiredGenres'] = requiredGenres;
    if (specificRequirements != null) {
      data['specificRequirements'] = specificRequirements;
    }
    if (artistsNeeded != null) data['artistsNeeded'] = artistsNeeded;
    if (budget != null) data['budget'] = budget;
    if (currency != null) data['currency'] = currency;
    if (paymentType != null) {
      data['paymentType'] = _$GigPaymentTypeEnumMap[paymentType!];
    }
    if (location != null) data['location'] = location!.toJson();
    if (isPublic != null) data['isPublic'] = isPublic;
    if (acceptingApplications != null) {
      data['acceptingApplications'] = acceptingApplications;
    }
    if (perks != null) data['perks'] = perks!.toJson();
    if (status != null) data['status'] = _gigStatusToWire(status);

    return data;
  }
}

@JsonSerializable(explicitToJson: true)
class CreateGigLocationRequest {
  final String? venueAddress;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;

  /// [longitude, latitude]
  final List<double> geoCoordinates;

  const CreateGigLocationRequest({
    this.venueAddress,
    required this.city,
    this.state,
    this.postalCode,
    required this.country,
    required this.geoCoordinates,
  });

  factory CreateGigLocationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGigLocationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateGigLocationRequestToJson(this);
}

/// Request model for gig discovery (Artist).
@JsonSerializable(explicitToJson: true)
class DiscoverGigsQuery {
  final List<String>? genres;
  final double? latitude;
  final double? longitude;

  final double? radiusKm;

  final double? minBudget;
  final double? maxBudget;

  final int? page;
  final int? limit;

  /// relevance | date | budget | distance | newest
  final String? sortBy;

  const DiscoverGigsQuery({
    this.genres,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.minBudget,
    this.maxBudget,
    this.page,
    this.limit,
    this.sortBy,
  });

  factory DiscoverGigsQuery.fromJson(Map<String, dynamic> json) =>
      _$DiscoverGigsQueryFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoverGigsQueryToJson(this);

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (genres != null && genres!.isNotEmpty) params['genres'] = genres;
    if (latitude != null) params['latitude'] = latitude;
    if (longitude != null) params['longitude'] = longitude;
    if (radiusKm != null) params['radiusKm'] = radiusKm;

    if (minBudget != null) params['minBudget'] = minBudget;
    if (maxBudget != null) params['maxBudget'] = maxBudget;

    if (page != null) params['page'] = page;
    if (limit != null) params['limit'] = limit;
    if (sortBy != null) params['sortBy'] = sortBy;

    return params;
  }
}

/// --- Helpers for flexible backend responses ---

GigVenueSummary? _venueFromJson(dynamic value) {
  // Backend may return venue as populated object or as string id.
  if (value == null) return null;
  if (value is String) {
    return GigVenueSummary(id: value);
  }
  if (value is Map<String, dynamic>) {
    return GigVenueSummary.fromJson(value);
  }
  // Unknown shape: ignore to keep app resilient
  return null;
}

dynamic _venueToJson(GigVenueSummary? venue) {
  if (venue == null) return null;
  return venue.toJson();
}

String? _gigStatusToWire(GigStatus? status) {
  // Only draft/open are accepted for CreateGigRequest in backend,
  // but we keep it tolerant.
  if (status == null) return null;
  switch (status) {
    case GigStatus.draft:
      return 'draft';
    case GigStatus.open:
      return 'open';
    case GigStatus.inProgress:
      return 'in_progress';
    case GigStatus.filled:
      return 'filled';
    case GigStatus.completed:
      return 'completed';
    case GigStatus.cancelled:
      return 'cancelled';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// APPLICATION MANAGEMENT MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Application info from Venue's perspective (with artist details)
class VenueGigApplication {
  final String id;
  final String artistId;
  final String artistName;
  final String? artistPhoto;
  final List<String> artistGenres;
  final double? artistRating;
  final String? message;
  final double? proposedRate;
  final DateTime appliedAt;
  final GigApplicationStatus status;

  VenueGigApplication({
    required this.id,
    required this.artistId,
    required this.artistName,
    this.artistPhoto,
    this.artistGenres = const [],
    this.artistRating,
    this.message,
    this.proposedRate,
    required this.appliedAt,
    required this.status,
  });

  factory VenueGigApplication.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'];
    String artistId = '';
    String artistName = 'Unknown Artist';
    String? artistPhoto;
    List<String> artistGenres = [];
    double? artistRating;

    if (artist is Map<String, dynamic>) {
      artistId = artist['_id']?.toString() ?? artist['id']?.toString() ?? '';
      artistName = artist['stageName'] ?? artist['name'] ?? 'Unknown Artist';
      artistPhoto = artist['profilePhoto'] ?? artist['photo'];
      artistGenres = List<String>.from(artist['genres'] ?? []);
      artistRating = (artist['averageRating'] as num?)?.toDouble();
    } else if (artist is String) {
      artistId = artist;
    }

    return VenueGigApplication(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      artistId: artistId,
      artistName: artistName,
      artistPhoto: artistPhoto,
      artistGenres: artistGenres,
      artistRating: artistRating,
      message: json['message'],
      proposedRate: (json['proposedRate'] as num?)?.toDouble(),
      appliedAt: DateTime.tryParse(json['appliedAt']?.toString() ?? '') ?? DateTime.now(),
      status: _parseApplicationStatus(json['status']),
    );
  }
}

/// Application info from Artist's perspective (with gig/venue details)
class ArtistGigApplication {
  final String gigId;
  final String gigTitle;
  final DateTime gigDate;
  final String gigStatus;
  final ApplicationDetails application;
  final VenueInfo? venue;
  final String? bookingId;
  final String? rejectionReason;

  ArtistGigApplication({
    required this.gigId,
    required this.gigTitle,
    required this.gigDate,
    required this.gigStatus,
    required this.application,
    this.venue,
    this.bookingId,
    this.rejectionReason,
  });

  factory ArtistGigApplication.fromJson(Map<String, dynamic> json) {
    return ArtistGigApplication(
      gigId: json['gigId']?.toString() ?? '',
      gigTitle: json['gigTitle']?.toString() ?? '',
      gigDate: DateTime.tryParse(json['gigDate']?.toString() ?? '') ?? DateTime.now(),
      gigStatus: json['gigStatus']?.toString() ?? '',
      application: ApplicationDetails.fromJson(json['application'] ?? {}),
      venue: json['venue'] != null ? VenueInfo.fromJson(json['venue']) : null,
      bookingId: json['bookingId']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }

  // Convenience getters to access nested application properties
  GigApplicationStatus get status => application.status;
  DateTime get appliedAt => application.appliedAt;
  String? get message => application.message;
  double? get proposedRate => application.proposedRate;
  
  // Convenience getter for venue info (wrapped in helper class)
  ArtistApplicationVenueInfo get venueInfo => ArtistApplicationVenueInfo(venue);
}

/// Helper class for accessing venue info with fallbacks
class ArtistApplicationVenueInfo {
  final VenueInfo? _venue;

  const ArtistApplicationVenueInfo(this._venue);

  String get name => _venue?.venueName ?? 'Unknown Venue';
  String? get photo => _venue?.coverPhoto;
  String? get location => _venue?.locationDisplay;
  String get id => _venue?.id ?? '';
}

/// Application details subset
class ApplicationDetails {
  final String id;
  final DateTime appliedAt;
  final String? message;
  final double? proposedRate;
  final GigApplicationStatus status;

  ApplicationDetails({
    required this.id,
    required this.appliedAt,
    this.message,
    this.proposedRate,
    required this.status,
  });

  factory ApplicationDetails.fromJson(Map<String, dynamic> json) {
    return ApplicationDetails(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      appliedAt: DateTime.tryParse(json['appliedAt']?.toString() ?? '') ?? DateTime.now(),
      message: json['message'],
      proposedRate: (json['proposedRate'] as num?)?.toDouble(),
      status: _parseApplicationStatus(json['status']),
    );
  }
}

/// Venue info for artist's application view
class VenueInfo {
  final String id;
  final String venueName;
  final String? venueType;
  final String? coverPhoto;
  final String? city;
  final String? country;

  VenueInfo({
    required this.id,
    required this.venueName,
    this.venueType,
    this.coverPhoto,
    this.city,
    this.country,
  });

  factory VenueInfo.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return VenueInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      venueName: json['venueName']?.toString() ?? 'Unknown Venue',
      venueType: json['venueType'],
      coverPhoto: json['coverPhoto'],
      city: location?['city'],
      country: location?['country'],
    );
  }

  String get locationDisplay {
    if (city != null && country != null) {
      return '$city, $country';
    }
    return city ?? country ?? '';
  }
}

/// Result from accepting an application
class AcceptApplicationResult {
  final String message;
  final Gig gig;
  final dynamic booking;

  AcceptApplicationResult({
    required this.message,
    required this.gig,
    this.booking,
  });

  factory AcceptApplicationResult.fromJson(Map<String, dynamic> json) {
    return AcceptApplicationResult(
      message: json['message']?.toString() ?? 'Application accepted',
      gig: Gig.fromJson(json['gig'] ?? {}),
      booking: json['booking'],
    );
  }
}

GigApplicationStatus _parseApplicationStatus(dynamic status) {
  if (status == null) return GigApplicationStatus.pending;
  final str = status.toString().toLowerCase();
  switch (str) {
    case 'accepted':
      return GigApplicationStatus.accepted;
    case 'rejected':
      return GigApplicationStatus.rejected;
    case 'declined':
      return GigApplicationStatus.rejected;
    case 'withdrawn':
      return GigApplicationStatus.withdrawn;
    default:
      return GigApplicationStatus.pending;
  }
}

/// Paginated response for artist's applications
class PaginatedApplicationsResponse {
  final List<ArtistGigApplication> applications;
  final int total;
  final int page;
  final int pages;
  final bool hasMore;

  PaginatedApplicationsResponse({
    required this.applications,
    required this.total,
    required this.page,
    required this.pages,
  }) : hasMore = page < pages;

  factory PaginatedApplicationsResponse.fromJson(Map<String, dynamic> json) {
    final apps = (json['applications'] as List?)
            ?.map((a) => ArtistGigApplication.fromJson(a))
            .toList() ??
        [];

    return PaginatedApplicationsResponse(
      applications: apps,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pages: json['pages'] ?? 1,
    );
  }
}
