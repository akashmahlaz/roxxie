// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gig_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoPoint _$GeoPointFromJson(Map<String, dynamic> json) => GeoPoint(
  type: json['type'] as String,
  coordinates: (json['coordinates'] as List<dynamic>)
      .map((e) => (e as num).toDouble())
      .toList(),
);

Map<String, dynamic> _$GeoPointToJson(GeoPoint instance) => <String, dynamic>{
  'type': instance.type,
  'coordinates': instance.coordinates,
};

GigLocation _$GigLocationFromJson(Map<String, dynamic> json) => GigLocation(
  venueAddress: json['venueAddress'] as String?,
  city: json['city'] as String,
  state: json['state'] as String?,
  postalCode: json['postalCode'] as String?,
  country: json['country'] as String,
  geo: json['geo'] == null
      ? null
      : GeoPoint.fromJson(json['geo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GigLocationToJson(GigLocation instance) =>
    <String, dynamic>{
      'venueAddress': instance.venueAddress,
      'city': instance.city,
      'state': instance.state,
      'postalCode': instance.postalCode,
      'country': instance.country,
      'geo': instance.geo?.toJson(),
    };

GigPerks _$GigPerksFromJson(Map<String, dynamic> json) => GigPerks(
  providesFood: json['providesFood'] as bool? ?? false,
  providesDrinks: json['providesDrinks'] as bool? ?? false,
  providesAccommodation: json['providesAccommodation'] as bool? ?? false,
  providesTransport: json['providesTransport'] as bool? ?? false,
  providesEquipment: json['providesEquipment'] as bool? ?? false,
  providesParking: json['providesParking'] as bool? ?? false,
  additionalPerks:
      (json['additionalPerks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$GigPerksToJson(GigPerks instance) => <String, dynamic>{
  'providesFood': instance.providesFood,
  'providesDrinks': instance.providesDrinks,
  'providesAccommodation': instance.providesAccommodation,
  'providesTransport': instance.providesTransport,
  'providesEquipment': instance.providesEquipment,
  'providesParking': instance.providesParking,
  'additionalPerks': instance.additionalPerks,
};

GigApplication _$GigApplicationFromJson(Map<String, dynamic> json) =>
    GigApplication(
      artist: json['artist'] as String,
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      message: json['message'] as String?,
      proposedRate: (json['proposedRate'] as num?)?.toDouble(),
      status: $enumDecode(_$GigApplicationStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$GigApplicationToJson(GigApplication instance) =>
    <String, dynamic>{
      'artist': instance.artist,
      'appliedAt': instance.appliedAt.toIso8601String(),
      'message': instance.message,
      'proposedRate': instance.proposedRate,
      'status': _$GigApplicationStatusEnumMap[instance.status]!,
    };

const _$GigApplicationStatusEnumMap = {
  GigApplicationStatus.pending: 'pending',
  GigApplicationStatus.accepted: 'accepted',
  GigApplicationStatus.rejected: 'rejected',
  GigApplicationStatus.withdrawn: 'withdrawn',
};

// GigVenueSummary now has custom fromJson/toJson — generated code removed.

Gig _$GigFromJson(Map<String, dynamic> json) => Gig(
  id: json['_id'] as String,
  venue: _venueFromJson(json['venue']),
  postedBy: json['postedBy'] as String?,
  title: json['title'] as String,
  description: json['description'] as String?,
  date: DateTime.parse(json['date'] as String),
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String?,
  durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
  numberOfSets: (json['numberOfSets'] as num?)?.toInt() ?? 1,
  gigType: json['gigType'] as String?,
  requiredGenres:
      (json['requiredGenres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  specificRequirements: json['specificRequirements'] as String?,
  artistsNeeded: (json['artistsNeeded'] as num?)?.toInt() ?? 1,
  budget: (json['budget'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'USD',
  paymentType:
      $enumDecodeNullable(_$GigPaymentTypeEnumMap, json['paymentType']) ??
      GigPaymentType.fixed,
  status:
      $enumDecodeNullable(_$GigStatusEnumMap, json['status']) ??
      GigStatus.draft,
  location: GigLocation.fromJson(json['location'] as Map<String, dynamic>),
  isPublic: json['isPublic'] as bool? ?? true,
  acceptingApplications: json['acceptingApplications'] as bool? ?? true,
  perks: json['perks'] == null
      ? null
      : GigPerks.fromJson(json['perks'] as Map<String, dynamic>),
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
  applicationCount: (json['applicationCount'] as num?)?.toInt() ?? 0,
  applications:
      (json['applications'] as List<dynamic>?)
          ?.map((e) => GigApplication.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  bookedArtists: json['bookedArtists'] == null
      ? const []
      : _bookedArtistsFromJson(json['bookedArtists']),
  cancelledAt: json['cancelledAt'] == null
      ? null
      : DateTime.parse(json['cancelledAt'] as String),
  cancellationReason: json['cancellationReason'] as String?,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GigToJson(Gig instance) => <String, dynamic>{
  '_id': instance.id,
  'venue': _venueToJson(instance.venue),
  'postedBy': instance.postedBy,
  'title': instance.title,
  'description': instance.description,
  'date': instance.date.toIso8601String(),
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'durationMinutes': instance.durationMinutes,
  'numberOfSets': instance.numberOfSets,
  'gigType': instance.gigType,
  'requiredGenres': instance.requiredGenres,
  'specificRequirements': instance.specificRequirements,
  'artistsNeeded': instance.artistsNeeded,
  'budget': instance.budget,
  'currency': instance.currency,
  'paymentType': _$GigPaymentTypeEnumMap[instance.paymentType]!,
  'status': _$GigStatusEnumMap[instance.status]!,
  'location': instance.location.toJson(),
  'isPublic': instance.isPublic,
  'acceptingApplications': instance.acceptingApplications,
  'perks': instance.perks?.toJson(),
  'viewCount': instance.viewCount,
  'applicationCount': instance.applicationCount,
  'applications': instance.applications.map((e) => e.toJson()).toList(),
  'bookedArtists': _bookedArtistsToJson(instance.bookedArtists),
  'cancelledAt': instance.cancelledAt?.toIso8601String(),
  'cancellationReason': instance.cancellationReason,
  'completedAt': instance.completedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$GigPaymentTypeEnumMap = {
  GigPaymentType.fixed: 'fixed',
  GigPaymentType.negotiable: 'negotiable',
  GigPaymentType.perHour: 'per_hour',
};

const _$GigStatusEnumMap = {
  GigStatus.draft: 'draft',
  GigStatus.open: 'open',
  GigStatus.inProgress: 'in_progress',
  GigStatus.filled: 'filled',
  GigStatus.completed: 'completed',
  GigStatus.cancelled: 'cancelled',
};

PaginatedGigsResponse _$PaginatedGigsResponseFromJson(
  Map<String, dynamic> json,
) => PaginatedGigsResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => Gig.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$PaginatedGigsResponseToJson(
  PaginatedGigsResponse instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'page': instance.page,
  'pages': instance.pages,
};

CreateGigRequest _$CreateGigRequestFromJson(Map<String, dynamic> json) =>
    CreateGigRequest(
      venueId: json['venueId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      numberOfSets: (json['numberOfSets'] as num?)?.toInt(),
      gigType: json['gigType'] as String?,
      requiredGenres: (json['requiredGenres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      specificRequirements: json['specificRequirements'] as String?,
      artistsNeeded: (json['artistsNeeded'] as num?)?.toInt(),
      budget: (json['budget'] as num).toDouble(),
      currency: json['currency'] as String?,
      paymentType: $enumDecodeNullable(
        _$GigPaymentTypeEnumMap,
        json['paymentType'],
      ),
      location: CreateGigLocationRequest.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      isPublic: json['isPublic'] as bool?,
      acceptingApplications: json['acceptingApplications'] as bool?,
      perks: json['perks'] == null
          ? null
          : GigPerks.fromJson(json['perks'] as Map<String, dynamic>),
      status: $enumDecodeNullable(_$GigStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$CreateGigRequestToJson(CreateGigRequest instance) =>
    <String, dynamic>{
      'venueId': instance.venueId,
      'title': instance.title,
      'description': instance.description,
      'date': instance.date,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'durationMinutes': instance.durationMinutes,
      'numberOfSets': instance.numberOfSets,
      'gigType': instance.gigType,
      'requiredGenres': instance.requiredGenres,
      'specificRequirements': instance.specificRequirements,
      'artistsNeeded': instance.artistsNeeded,
      'budget': instance.budget,
      'currency': instance.currency,
      'paymentType': _$GigPaymentTypeEnumMap[instance.paymentType],
      'location': instance.location.toJson(),
      'isPublic': instance.isPublic,
      'acceptingApplications': instance.acceptingApplications,
      'perks': instance.perks?.toJson(),
      'status': _gigStatusToWire(instance.status),
    };

CreateGigLocationRequest _$CreateGigLocationRequestFromJson(
  Map<String, dynamic> json,
) => CreateGigLocationRequest(
  venueAddress: json['venueAddress'] as String?,
  city: json['city'] as String,
  state: json['state'] as String?,
  postalCode: json['postalCode'] as String?,
  country: json['country'] as String,
  geoCoordinates: (json['geoCoordinates'] as List<dynamic>)
      .map((e) => (e as num).toDouble())
      .toList(),
);

Map<String, dynamic> _$CreateGigLocationRequestToJson(
  CreateGigLocationRequest instance,
) => <String, dynamic>{
  'venueAddress': instance.venueAddress,
  'city': instance.city,
  'state': instance.state,
  'postalCode': instance.postalCode,
  'country': instance.country,
  'geoCoordinates': instance.geoCoordinates,
};

DiscoverGigsQuery _$DiscoverGigsQueryFromJson(Map<String, dynamic> json) =>
    DiscoverGigsQuery(
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusKm: (json['radiusKm'] as num?)?.toDouble(),
      minBudget: (json['minBudget'] as num?)?.toDouble(),
      maxBudget: (json['maxBudget'] as num?)?.toDouble(),
      page: (json['page'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      sortBy: json['sortBy'] as String?,
    );

Map<String, dynamic> _$DiscoverGigsQueryToJson(DiscoverGigsQuery instance) =>
    <String, dynamic>{
      'genres': instance.genres,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radiusKm': instance.radiusKm,
      'minBudget': instance.minBudget,
      'maxBudget': instance.maxBudget,
      'page': instance.page,
      'limit': instance.limit,
      'sortBy': instance.sortBy,
    };
