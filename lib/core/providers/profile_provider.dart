/// 👤 GIGMATCH Profile Provider
/// State management for user profile with real API data
library;

import 'package:flutter/foundation.dart';
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

  /// Get profile completeness percentage from backend
  int get profileCompleteness {
    if (_artist != null) return _artist!.profileCompletionPercent;
    if (_venue != null) return _venue!.profileCompleteness;
    return 0;
  }

  /// Load artist profile
  Future<void> loadArtistProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    _status = ProfileStatus.loading;
    notifyListeners();

    try {
      debugPrint('👤 [ProfileProvider] Loading artist profile...');

      // Load artist profile
      _artist = await _artistService.getMyProfile();

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
      debugPrint(
        '👤 [ProfileProvider] Artist profile loaded: ${_artist!.displayName}',
      );
    } catch (e) {
      debugPrint('❌ [ProfileProvider] Failed to load artist profile: $e');
      _errorMessage = e.toString();
      _status = ProfileStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load venue profile
  Future<void> loadVenueProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    _status = ProfileStatus.loading;
    notifyListeners();

    try {
      debugPrint('👤 [ProfileProvider] Loading venue profile...');

      // Load venue profile
      _venue = await _venueService.getMyProfile();

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
      debugPrint('👤 [ProfileProvider] Venue profile loaded: ${_venue!.name}');
    } catch (e) {
      debugPrint('❌ [ProfileProvider] Failed to load venue profile: $e');
      _errorMessage = e.toString();
      _status = ProfileStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load profile based on role
  Future<void> loadProfile(bool isArtist) async {
    if (isArtist) {
      await loadArtistProfile();
    } else {
      await loadVenueProfile();
    }
  }

  /// Refresh profile
  Future<void> refresh(bool isArtist) async {
    await loadProfile(isArtist);
  }

  /// Clear profile data
  void clear() {
    _artist = null;
    _venue = null;
    _reviewStats = null;
    _status = ProfileStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
