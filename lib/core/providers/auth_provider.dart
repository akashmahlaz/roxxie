/// 🔐 GIGMATCH Auth Provider
/// State management for authentication
library;

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/services.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  profileIncomplete,
  needsRoleSelection,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SocialAuthService _socialAuthService = SocialAuthService();
  final ArtistService _artistService = ArtistService();
  final VenueService _venueService = VenueService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  Artist? _artistProfile;
  Venue? _venueProfile;
  String? _errorMessage;
  bool _isLoading = false;
  bool _onboardingSkipped = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNUP DATA: Store location data from signup for profile setup
  // This is needed because backend may not create venue profile immediately
  // ═══════════════════════════════════════════════════════════════════════════
  String? _signupCity;
  String? _signupCountry;
  double? _signupLatitude;
  double? _signupLongitude;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  Artist? get artistProfile => _artistProfile;

  // Signup location getters - for use in profile setup
  String? get signupCity => _signupCity;
  String? get signupCountry => _signupCountry;
  double? get signupLatitude => _signupLatitude;
  double? get signupLongitude => _signupLongitude;
  Venue? get venueProfile => _venueProfile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isArtist => _user?.role == UserRole.artist;
  bool get isVenue => _user?.role == UserRole.venue;
  bool get isProfileComplete => _user?.isProfileComplete ?? false;

  /// 🎯 Has completed onboarding (venue/artist profile exists)
  /// This is separate from isProfileComplete which is for full Me tab completion
  bool get hasCompletedOnboarding {
    if (_user == null) return false;
    if (_onboardingSkipped) return true;
    if (_user!.isVenue) return _venueProfile != null;
    if (_user!.isArtist) return _artistProfile != null;
    return false;
  }

  /// 🔄 Initialize - Check existing auth state
  Future<void> init() async {
    debugPrint('🔐 AuthProvider.init() starting...');
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      debugPrint('🔐 isLoggedIn check: $isLoggedIn');

      if (isLoggedIn) {
        // Try to get cached user first
        _user = await _authService.getCachedUser();
        debugPrint('🔐 Cached user: ${_user?.email ?? "null"}');

        _onboardingSkipped = await _authService.getOnboardingSkipped();
        final cachedProfileComplete = _user?.isProfileComplete ?? false;

        // Then fetch fresh profile
        try {
          debugPrint('🔐 Fetching fresh profile from server...');
          final updatedUser = await _authService.getProfile();
          debugPrint('🔐 Server profile fetched: ${updatedUser.email}');

          await _loadRoleProfile();
          // If cached user says complete, do not downgrade on stale backend data
          _user = cachedProfileComplete && !updatedUser.isProfileComplete
              ? updatedUser.copyWith(isProfileComplete: true)
              : updatedUser;

          // Use hasCompletedOnboarding (profile exists) instead of isProfileComplete
          _status = hasCompletedOnboarding
              ? AuthStatus.authenticated
              : AuthStatus.profileIncomplete;
          debugPrint('🔐 Auth status: $_status');
        } catch (e) {
          debugPrint('🔐 Profile fetch failed: $e, trying token refresh...');
          // Token might be expired, try refresh
          final refreshed = await _authService.refreshTokens();
          debugPrint('🔐 Token refresh result: $refreshed');

          if (refreshed) {
            final updatedUser = await _authService.getProfile();
            await _loadRoleProfile();
            // If cached user says complete, do not downgrade on stale backend data
            _user = cachedProfileComplete && !updatedUser.isProfileComplete
                ? updatedUser.copyWith(isProfileComplete: true)
                : updatedUser;

            // Use hasCompletedOnboarding (profile exists) instead of isProfileComplete
            _status = hasCompletedOnboarding
                ? AuthStatus.authenticated
                : AuthStatus.profileIncomplete;
          } else {
            debugPrint('🔐 Token refresh failed, setting unauthenticated');
            _status = AuthStatus.unauthenticated;
          }
        }
      } else {
        debugPrint('🔐 No token found, setting unauthenticated');
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('🔐 Auth init error: $e');
      _status = AuthStatus.unauthenticated;
    } finally {
      debugPrint('🔐 AuthProvider.init() complete. Status: $_status');
      _setLoading(false);
    }
  }

  /// 📝 Register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(
        RegisterRequest(
          email: email,
          password: password,
          name: name,
          role: role,
          phone: phone,
          city: city,
          country: country,
          latitude: latitude,
          longitude: longitude,
        ),
      );

      _user = response.user;
      _status = AuthStatus.profileIncomplete;

      // ═══════════════════════════════════════════════════════════════════════
      // STORE SIGNUP LOCATION DATA: Keep for profile setup screens
      // Backend may not create venue/artist profile immediately, so we store
      // the signup location data here for use in profile setup screens
      // ═══════════════════════════════════════════════════════════════════════
      _signupCity = city;
      _signupCountry = country;
      _signupLatitude = latitude;
      _signupLongitude = longitude;
      debugPrint(
        '📍 Stored signup location: $city, $country ($latitude, $longitude)',
      );

      // ═══════════════════════════════════════════════════════════════════════
      // LOAD ROLE PROFILE: Load the initial profile created with signup data
      // This ensures city/country/location from signup is available in setup
      // ═══════════════════════════════════════════════════════════════════════
      await _loadRoleProfile();

      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🔑 Login
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        LoginRequest(email: email, password: password),
      );

      _user = response.user;
      await _loadRoleProfile();

      // Use hasCompletedOnboarding (profile exists) instead of isProfileComplete
      if (hasCompletedOnboarding) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.profileIncomplete;
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOCIAL LOGIN
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🔵 Sign in with Google
  Future<bool> signInWithGoogle({UserRole? role}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _socialAuthService.signInWithGoogle(role: role);

      if (!result.success) {
        _setError(result.errorMessage ?? 'Google sign-in failed');
        return false;
      }

      _user = result.user;
      await _loadRoleProfile();

      if (result.needsRoleSelection) {
        _status = AuthStatus.needsRoleSelection;
      } else if (hasCompletedOnboarding) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.profileIncomplete;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Google sign-in failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🍎 Sign in with Apple
  Future<bool> signInWithApple({UserRole? role}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _socialAuthService.signInWithApple(role: role);

      if (!result.success) {
        _setError(result.errorMessage ?? 'Apple sign-in failed');
        return false;
      }

      _user = result.user;
      await _loadRoleProfile();

      if (result.needsRoleSelection) {
        _status = AuthStatus.needsRoleSelection;
      } else if (hasCompletedOnboarding) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.profileIncomplete;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Apple sign-in failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if Apple Sign-In is available
  Future<bool> isAppleSignInAvailable() async {
    return await _socialAuthService.isAppleSignInAvailable();
  }

  /// Update user role after social sign-in
  Future<bool> updateRole(UserRole role) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _socialAuthService.updateUserRole(role);
      if (success) {
        _user = _user?.copyWith(role: role);
        _status = AuthStatus.profileIncomplete;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to update role');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🚪 Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      await _socialAuthService.signOutGoogle();
    } finally {
      _user = null;
      _artistProfile = null;
      _venueProfile = null;
      _onboardingSkipped = false;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
    }
  }

  /// ✅ Mark onboarding as skipped (local-only fallback)
  Future<void> markOnboardingSkipped() async {
    _onboardingSkipped = true;
    await _authService.setOnboardingSkipped(true);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// 👤 Load role-specific profile
  Future<void> _loadRoleProfile() async {
    if (_user == null) return;

    try {
      if (_user!.isArtist) {
        _artistProfile = await _artistService.getMyProfile();
      } else if (_user!.isVenue) {
        _venueProfile = await _venueService.getMyProfile();
      }
    } catch (e) {
      debugPrint('Load role profile error: $e');
    }
  }

  /// ✏️ Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.updateProfile(updates);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Update failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🎸 Update artist profile
  Future<bool> updateArtistProfile(UpdateArtistRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      _artistProfile = await _artistService.updateMyProfile(request);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Update failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ Complete artist setup
  Future<bool> completeArtistSetup(UpdateArtistRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      _artistProfile = await _artistService.completeSetup(request);

      // Fetch fresh user data from backend to get updated hasCompletedSetup flag
      try {
        final updatedUser = await _authService.getProfile();
        // Ensure isProfileComplete is true even if backend hasn't synced
        _user = updatedUser.copyWith(isProfileComplete: true);
      } catch (e) {
        // If fetching updated user fails, still update local state
        debugPrint('Warning: Failed to fetch updated user profile: $e');
        _user = _user?.copyWith(isProfileComplete: true);
      }

      // Cache the user with isProfileComplete = true so app restart works correctly
      if (_user != null) {
        await _authService.cacheUser(_user!);
        debugPrint(
          '💾 [ArtistSetup] Cached user with isProfileComplete: ${_user!.isProfileComplete}',
        );
      }

      // Clear local onboarding skipped flag on success
      _onboardingSkipped = false;
      await _authService.setOnboardingSkipped(false);

      // Clear local onboarding skipped flag on success
      _onboardingSkipped = false;
      await _authService.setOnboardingSkipped(false);

      _status = AuthStatus.authenticated;
      debugPrint('✅ [ArtistSetup] Profile complete! Status: $_status');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Setup failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ Complete artist setup with raw data (bypasses model)
  Future<bool> completeArtistSetupWithData(Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      _artistProfile = await _artistService.completeSetupWithData(data);

      // Fetch fresh user data from backend to get updated hasCompletedSetup flag
      try {
        final updatedUser = await _authService.getProfile();
        // Ensure isProfileComplete is true even if backend hasn't synced
        _user = updatedUser.copyWith(isProfileComplete: true);
      } catch (e) {
        // If fetching updated user fails, still update local state
        debugPrint('Warning: Failed to fetch updated user profile: $e');
        _user = _user?.copyWith(isProfileComplete: true);
      }

      // Cache the user with isProfileComplete = true so app restart works correctly
      if (_user != null) {
        await _authService.cacheUser(_user!);
        debugPrint(
          '💾 [ArtistSetup] Cached user with isProfileComplete: ${_user!.isProfileComplete}',
        );
      }

      _status = AuthStatus.authenticated;
      debugPrint('✅ [ArtistSetup] Profile complete! Status: $_status');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Setup failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🏢 Update venue profile
  Future<bool> updateVenueProfile(UpdateVenueRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      _venueProfile = await _venueService.updateMyProfile(request);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Update failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ Complete venue setup
  Future<bool> completeVenueSetup(VenueProfileData profileData) async {
    _setLoading(true);
    _clearError();

    try {
      _venueProfile = await _venueService.completeSetup(profileData);

      // Fetch fresh user data from backend to get updated hasCompletedSetup flag
      try {
        final updatedUser = await _authService.getProfile();
        // Ensure isProfileComplete is true even if backend hasn't synced
        _user = updatedUser.copyWith(isProfileComplete: true);
      } catch (e) {
        // If fetching updated user fails, still update local state
        debugPrint('Warning: Failed to fetch updated user profile: $e');
        _user = _user?.copyWith(isProfileComplete: true);
      }

      // Cache the user with isProfileComplete = true so app restart works correctly
      if (_user != null) {
        await _authService.cacheUser(_user!);
        debugPrint(
          '💾 [VenueSetup] Cached user with isProfileComplete: ${_user!.isProfileComplete}',
        );
      }

      // Clear local onboarding skipped flag on success
      _onboardingSkipped = false;
      await _authService.setOnboardingSkipped(false);

      _status = AuthStatus.authenticated;
      debugPrint('✅ [VenueSetup] Profile complete! Status: $_status');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Setup failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🔒 Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.changePassword(
        ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      return true;
    } catch (e) {
      _setError('Password change failed');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 📧 Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.forgotPassword(email);
      return true;
    } catch (e) {
      _setError('Request failed');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ Verify email with token
  Future<bool> verifyEmail(String token) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.verifyEmail(token);
      // Update local user state
      if (_user != null) {
        _user = _user!.copyWith(isEmailVerified: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Verification failed');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 📧 Resend verification email
  Future<bool> resendVerificationEmail() async {
    if (_user?.email == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.resendVerificationEmail(_user!.email);
      return true;
    } catch (e) {
      _setError('Failed to resend verification email');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    // Only set error status if not already authenticated
    // This prevents kicking user out when profile updates fail
    if (_status != AuthStatus.authenticated) {
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
  }

  void _handleDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      _setError(data['message']);
    } else if (e.response?.statusCode == 401) {
      _setError('Invalid credentials');
    } else if (e.response?.statusCode == 409) {
      _setError('Email already registered');
    } else {
      _setError('Network error. Please try again.');
    }
  }
}
