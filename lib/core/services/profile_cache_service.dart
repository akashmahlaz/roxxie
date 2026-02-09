/// 👤 GIGMATCH Profile Cache Service
/// Local storage for participant profiles
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/artist_models.dart';
import '../models/venues_models.dart';
import 'hive_cache_service.dart';

/// Participant profile data class
class ParticipantProfile {
  final String id;
  final String name;
  final String? photoUrl;
  final String type; // 'artist' or 'venue'
  final String? bio;
  final String? location;
  final List<String>? genres;
  final double? rating;
  final int? reviewCount;
  final bool isVerified;

  ParticipantProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.type,
    this.bio,
    this.location,
    this.genres,
    this.rating,
    this.reviewCount,
    this.isVerified = false,
  });

  factory ParticipantProfile.fromArtist(Artist artist) => ParticipantProfile(
        id: artist.id,
        name: artist.displayName,
        photoUrl: artist.primaryPhoto,
        type: 'artist',
        bio: artist.bio,
        location: artist.displayLocation,
        genres: artist.genres,
        rating: artist.rating,
        reviewCount: artist.reviewCount,
        isVerified: artist.isVerified,
      );

  factory ParticipantProfile.fromVenue(Venue venue) => ParticipantProfile(
        id: venue.id,
        name: venue.name,
        photoUrl: venue.primaryPhoto,
        type: 'venue',
        bio: venue.bio,
        location: venue.displayLocation,
        genres: venue.gigPreferences?.preferredGenres,
        rating: venue.rating,
        reviewCount: venue.reviewCount,
        isVerified: venue.isVerified,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoUrl': photoUrl,
        'type': type,
        'bio': bio,
        'location': location,
        'genres': genres,
        'rating': rating,
        'reviewCount': reviewCount,
        'isVerified': isVerified,
      };

  factory ParticipantProfile.fromJson(Map<String, dynamic> json) => ParticipantProfile(
        id: json['id'],
        name: json['name'],
        photoUrl: json['photoUrl'],
        type: json['type'],
        bio: json['bio'],
        location: json['location'],
        genres: json['genres'] != null ? List<String>.from(json['genres']) : null,
        rating: json['rating'],
        reviewCount: json['reviewCount'],
        isVerified: json['isVerified'] ?? false,
      );
}

/// ProfileCacheService handles caching of participant profiles
class ProfileCacheService {
  static const String boxName = CacheBoxes.profiles;
  static const int maxCachedProfiles = 100;

  /// Get the Hive box for profiles
  Box<String> get _box => Hive.box<String>(boxName);

  /// Get a cached profile by ID
  Future<ParticipantProfile?> getCachedProfile(String profileId) async {
    try {
      final data = _box.get(profileId);
      if (data == null) return null;

      return ParticipantProfile.fromJson(jsonDecode(data));
    } catch (e) {
      debugPrint('Error getting cached profile: $e');
      return null;
    }
  }

  /// Cache a profile
  Future<void> cacheProfile(ParticipantProfile profile) async {
    try {
      final jsonString = jsonEncode(profile.toJson());
      await _box.put(profile.id, jsonString);

      // Evict old profiles if cache is full
      if (_box.keys.length > maxCachedProfiles) {
        await _evictOldProfiles();
      }
    } catch (e) {
      debugPrint('Error caching profile: $e');
    }
  }

  /// Cache an artist profile
  Future<void> cacheArtist(Artist artist) async {
    await cacheProfile(ParticipantProfile.fromArtist(artist));
  }

  /// Cache a venue profile
  Future<void> cacheVenue(Venue venue) async {
    await cacheProfile(ParticipantProfile.fromVenue(venue));
  }

  /// Evict oldest profiles when cache is full
  Future<void> _evictOldProfiles() async {
    try {
      final profiles = <String, ParticipantProfile>{};
      for (final key in _box.keys) {
        final data = _box.get(key);
        if (data != null) {
          try {
            final profile = ParticipantProfile.fromJson(
              jsonDecode(data),
            );
            profiles[key.toString()] = profile;
          } catch (_) {}
        }
      }

      // Sort by name and keep first N
      final sortedIds = profiles.keys.toList()
        ..sort((a, b) => profiles[a]!.name.compareTo(profiles[b]!.name));

      final idsToRemove = sortedIds.length > maxCachedProfiles
          ? sortedIds.sublist(maxCachedProfiles)
          : <String>[];

      for (final id in idsToRemove) {
        await _box.delete(id);
      }
    } catch (e) {
      debugPrint('Error evicting old profiles: $e');
    }
  }

  /// Get multiple profiles at once
  Future<Map<String, ParticipantProfile>> getMultipleProfiles(
    List<String> profileIds,
  ) async {
    final result = <String, ParticipantProfile>{};

    for (final id in profileIds) {
      final profile = await getCachedProfile(id);
      if (profile != null) {
        result[id] = profile;
      }
    }

    return result;
  }

  /// Search cached profiles
  Future<List<ParticipantProfile>> searchProfiles(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final results = <ParticipantProfile>[];

      for (final key in _box.keys) {
        final data = _box.get(key);
        if (data != null) {
          try {
            final profile = ParticipantProfile.fromJson(
              jsonDecode(data),
            );
            if (profile.name.toLowerCase().contains(lowerQuery) ||
                profile.genres?.any((g) => g.toLowerCase().contains(lowerQuery)) == true) {
              results.add(profile);
            }
          } catch (_) {}
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching profiles: $e');
      return [];
    }
  }

  /// Remove a profile from cache
  Future<void> evictProfile(String profileId) async {
    try {
      await _box.delete(profileId);
    } catch (e) {
      debugPrint('Error evicting profile: $e');
    }
  }

  /// Clear all profile cache
  Future<void> clearAll() async {
    await _box.clear();
  }
}
