/// 👤 GIGMATCH Profile Provider
/// State management for user profile with real API data + Hive cache
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/models.dart';
import '../services/services.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final ArtistService _artistService = ArtistService();
  final VenueService _venueService = VenueService();
  final ReviewService _reviewService = ReviewService();

  ProfileStatus _status = ProfileStatus.initial;
  Artist? _artist;
  Venue? _venue;
  ReviewStats? _reviewStats;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  ProfileStatus get status => _status;
  Artist? get artist => _artist;
  Venue? get venue => _venue;
  ReviewStats? get reviewStats => _reviewStats;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // Computed getters for profile data
  String get displayName {
    if (_artist != null) {
      return _artist!.stageName.isNotEmpty
          ? _artist!.stageName
          : _artist!.displayName;
    }
    if (_venue != null) return _venue!.name;
    return 'User';
  }

  String? get profilePhoto {
    if (_artist != null) return _artist!.profilePhoto;
    if (_venue != null) return _venue!.profilePhotoUrl;
    return null;
  }

  double get rating {
    if (_artist != null) return _artist!.averageRating;
    if (_venue != null) return _venue!.reviewStatsAverageRating ?? 0;
    return 0;
  }

  int get totalReviews {
    if (_artist != null) return _artist!.totalReviews;
    if (_venue != null) return _venue!.reviewCount ?? 0;
    return 0;
  }

  int get completedGigs {
    if (_artist != null) return _artist!.completedGigs;
    if (_venue != null) return _venue!.totalGigsHosted ?? 0;
    return 0;
  }

  int get capacity {
    if (_venue != null) return _venue!.capacity ?? 0;
    return 0;
  }

  List<String> get genres {
    if (_artist != null) return _artist!.genres;
    if (_venue != null) return _venue!.gigPreferences?.preferredGenres ?? [];
    return [];
  }

  String? get bio {
    if (_artist != null) return _artist!.bio;
    if (_venue != null) return _venue!.description;
    return null;
  }

  bool get isVerified {
    if (_artist != null) return _artist!.isVerified;
    if (_venue != null) return _venue!.isVerified;
    return false;
  }

  String get subscriptionTier {
    if (_artist != null) return _artist!.subscriptionTier;
    return 'free';
  }

  int get profileViews {
    if (_artist != null) return _artist!.profileViews;
    return 0;
  }

  int get profileCompleteness {
    if (_venue != null) return _venue!.profileCompleteness;
    if (_artist != null) return _artist!.profileCompletionPercent;
    return 0;
  }

  bool get hasCompletedSetup {
    if (_venue != null) return _venue!.hasCompletedSetup;
    if (_artist != null) return _artist!.hasCompletedSetup;
    return false;
  }

  // Cache keys
  static const String _artistCacheKey = 'my_artist_profile';
  static const String _venueCacheKey = 'my_venue_profile';
  DateTime? _lastFetchTime;

  /// Whether cached data is stale (older than 5 minutes)
  bool get _isStale {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > const Duration(minutes: 5);
  }

  /// Load artist profile (cache-first, then network refresh)
  Future<void> loadArtistProfile() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _status = ProfileStatus.loading;
    notifyListeners();

    try {
      debugPrint('👤 [ProfileProvider] Loading artist profile...');

      // 1. Show cached data immediately
      if (_artist == null) {
        final cached = _loadCachedArtist();
        if (cached != null) {
          _artist = cached;
          _status = ProfileStatus.loaded;
          notifyListeners();
          debugPrint('👤 [ProfileProvider] Showing cached artist profile');
        }
      }

      // 2. Fetch fresh from network
      final freshArtist = await _artistService.getMyProfile();
      _artist = freshArtist;

      // 3. Cache the fresh data
      await _cacheArtist(freshArtist);

      // Load review stats if we have artist ID
      if (_artist != null) {
        try {
          _reviewStats = await _reviewService.getArtistStats(_artist!.id);
        } catch (e) {
          debugPrint('⚠️ [ProfileProvider] Failed to load artist reviews: $e');
          _reviewStats = ReviewStats.empty();
        }
      }

      _status = ProfileStatus.loaded;
      _lastFetchTime = DateTime.now();
      debugPrint(
        '👤 [ProfileProvider] Artist profile loaded: ${_artist?.displayName ?? 'Unknown'}',
      );
    } catch (e) {
      debugPrint('❌ [ProfileProvider] Failed to load artist profile: $e');
      // If we have cached data, keep showing it
      if (_artist != null) {
        _status = ProfileStatus.loaded;
        debugPrint('👤 [ProfileProvider] Using cached artist profile (offline)');
      } else {
        _errorMessage = e.toString();
        _status = ProfileStatus.error;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load venue profile (cache-first, then network refresh)
  Future<void> loadVenueProfile() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _status = ProfileStatus.loading;
    notifyListeners();

    try {
      debugPrint('👤 [ProfileProvider] Loading venue profile...');

      // 1. Show cached data immediately
      if (_venue == null) {
        final cached = _loadCachedVenue();
        if (cached != null) {
          _venue = cached;
          _status = ProfileStatus.loaded;
          notifyListeners();
          debugPrint('👤 [ProfileProvider] Showing cached venue profile');
        }
      }

      // 2. Fetch fresh from network
      final freshVenue = await _venueService.getMyProfile();
      _venue = freshVenue;

      // 3. Cache the fresh data
      await _cacheVenue(freshVenue);

      // Load review stats if we have venue ID
      if (_venue != null) {
        try {
          _reviewStats = await _reviewService.getVenueStats(_venue!.id);
        } catch (e) {
          debugPrint('⚠️ [ProfileProvider] Failed to load venue reviews: $e');
          _reviewStats = ReviewStats.empty();
        }
      }

      _status = ProfileStatus.loaded;
      _lastFetchTime = DateTime.now();
      debugPrint('👤 [ProfileProvider] Venue profile loaded: ${_venue?.name ?? 'Unknown'}');
    } catch (e) {
      debugPrint('❌ [ProfileProvider] Failed to load venue profile: $e');
      // If we have cached data, keep showing it
      if (_venue != null) {
        _status = ProfileStatus.loaded;
        debugPrint('👤 [ProfileProvider] Using cached venue profile (offline)');
      } else {
        _errorMessage = e.toString();
        _status = ProfileStatus.error;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load profile based on role (skips if data is fresh)
  Future<void> loadProfile(bool isArtist) async {
    if (!_isStale && _status == ProfileStatus.loaded) {
      return;
    }
    if (isArtist) {
      await loadArtistProfile();
    } else {
      await loadVenueProfile();
    }
  }

  /// Force refresh profile (ignores staleness)
  Future<void> refresh(bool isArtist) async {
    _lastFetchTime = null; // Reset so _isStale returns true
    if (isArtist) {
      await loadArtistProfile();
    } else {
      await loadVenueProfile();
    }
  }

  /// Clear profile data
  void clear() {
    _artist = null;
    _venue = null;
    _reviewStats = null;
    _status = ProfileStatus.initial;
    _errorMessage = null;
    _lastFetchTime = null;
    notifyListeners();
  }

  // ─── Cache Helpers ─────────────────────────────────────────────────────

  /// Load cached artist from Hive
  Artist? _loadCachedArtist() {
    try {
      final box = Hive.box<String>(CacheBoxes.profiles);
      final data = box.get(_artistCacheKey);
      if (data == null) return null;
      return Artist.fromJson(jsonDecode(data));
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to load cached artist: $e');
      return null;
    }
  }

  /// Load cached venue from Hive
  Venue? _loadCachedVenue() {
    try {
      final box = Hive.box<String>(CacheBoxes.profiles);
      final data = box.get(_venueCacheKey);
      if (data == null) return null;
      return Venue.fromJson(jsonDecode(data));
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to load cached venue: $e');
      return null;
    }
  }

  /// Cache artist profile to Hive
  Future<void> _cacheArtist(Artist artist) async {
    try {
      final box = Hive.box<String>(CacheBoxes.profiles);
      await box.put(_artistCacheKey, jsonEncode(artist.toJson()));
      debugPrint('💾 [ProfileProvider] Artist profile cached');
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to cache artist: $e');
    }
  }

  /// Cache venue profile to Hive
  Future<void> _cacheVenue(Venue venue) async {
    try {
      final box = Hive.box<String>(CacheBoxes.profiles);
      await box.put(_venueCacheKey, jsonEncode(venue.toJson()));
      debugPrint('💾 [ProfileProvider] Venue profile cached');
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to cache venue: $e');
    }
  }
}
