/// 👤 GIGMATCH User Models
/// Core user data models

/// User Role Enum
enum UserRole {
  artist('artist'),
  venue('venue');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => UserRole.artist,
    );
  }
}

/// User Status
enum UserStatus {
  active('active'),
  inactive('inactive'),
  suspended('suspended'),
  pendingVerification('pending_verification');

  final String value;
  const UserStatus(this.value);

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => UserStatus.active,
    );
  }
}

/// Main User Model
class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final UserStatus status;
  final String? profilePhotoUrl;
  final String? phone;
  final bool isEmailVerified;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? artistId;
  final String? venueId;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.status = UserStatus.active,
    this.profilePhotoUrl,
    this.phone,
    this.isEmailVerified = false,
    this.isProfileComplete = false,
    required this.createdAt,
    required this.updatedAt,
    this.artistId,
    this.venueId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'artist'),
      status: UserStatus.fromString(json['status'] ?? 'active'),
      profilePhotoUrl: json['profilePhotoUrl'],
      phone: json['phone'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isProfileComplete: json['isProfileComplete'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      artistId: json['artistId'],
      venueId: json['venueId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.value,
    'status': status.value,
    'profilePhotoUrl': profilePhotoUrl,
    'phone': phone,
    'isEmailVerified': isEmailVerified,
    'isProfileComplete': isProfileComplete,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'artistId': artistId,
    'venueId': venueId,
  };

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    UserStatus? status,
    String? profilePhotoUrl,
    String? phone,
    bool? isEmailVerified,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? artistId,
    String? venueId,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      artistId: artistId ?? this.artistId,
      venueId: venueId ?? this.venueId,
    );
  }

  bool get isArtist => role == UserRole.artist;
  bool get isVenue => role == UserRole.venue;
}

/// Location Model
class Location {
  final String type;
  final List<double> coordinates; // [longitude, latitude]
  final String? city;
  final String? state;
  final String? country;
  final String? formattedAddress;

  Location({
    this.type = 'Point',
    required this.coordinates,
    this.city,
    this.state,
    this.country,
    this.formattedAddress,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'];
    List<double> coordinates = [0.0, 0.0];
    if (coords is List && coords.length >= 2) {
      coordinates = [
        (coords[0] as num).toDouble(),
        (coords[1] as num).toDouble(),
      ];
    }
    return Location(
      type: json['type'] ?? 'Point',
      coordinates: coordinates,
      city: json['city'],
      state: json['state'],
      country: json['country'],
      formattedAddress: json['formattedAddress'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (country != null) 'country': country,
    if (formattedAddress != null) 'formattedAddress': formattedAddress,
  };

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;
}

/// Social Links Model
class SocialLinks {
  final String? instagram;
  final String? spotify;
  final String? youtube;
  final String? soundcloud;
  final String? tiktok;
  final String? website;

  SocialLinks({
    this.instagram,
    this.spotify,
    this.youtube,
    this.soundcloud,
    this.tiktok,
    this.website,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      instagram: json['instagram'],
      spotify: json['spotify'],
      youtube: json['youtube'],
      soundcloud: json['soundcloud'],
      tiktok: json['tiktok'],
      website: json['website'],
    );
  }

  Map<String, dynamic> toJson() => {
    if (instagram != null) 'instagram': instagram,
    if (spotify != null) 'spotify': spotify,
    if (youtube != null) 'youtube': youtube,
    if (soundcloud != null) 'soundcloud': soundcloud,
    if (tiktok != null) 'tiktok': tiktok,
    if (website != null) 'website': website,
  };
}
