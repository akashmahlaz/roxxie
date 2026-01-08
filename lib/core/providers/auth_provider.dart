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
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ArtistService _artistService = ArtistService();
  final VenueService _venueService = VenueService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  Artist? _artistProfile;
  Venue? _venueProfile;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  Artist? get artistProfile => _artistProfile;
  Venue? get venueProfile => _venueProfile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isArtist => _user?.role == UserRole.artist;
  bool get isVenue => _user?.role == UserRole.venue;
  bool get isProfileComplete => _user?.isProfileComplete ?? false;

  /// 🔄 Initialize - Check existing auth state
  Future<void> init() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // Try to get cached user first
        _user = await _authService.getCachedUser();

        // Then fetch fresh profile
        try {
          _user = await _authService.getProfile();
          await _loadRoleProfile();

          if (_user!.isProfileComplete) {
            _status = AuthStatus.authenticated;
          } else {
            _status = AuthStatus.profileIncomplete;
          }
        } catch (e) {
          // Token might be expired, try refresh
          final refreshed = await _authService.refreshTokens();
          if (refreshed) {
            _user = await _authService.getProfile();
            await _loadRoleProfile();
            _status = _user!.isProfileComplete
                ? AuthStatus.authenticated
                : AuthStatus.profileIncomplete;
          } else {
            _status = AuthStatus.unauthenticated;
          }
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
      _status = AuthStatus.unauthenticated;
    } finally {
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

      if (_user!.isProfileComplete) {
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

  /// 🚪 Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
    } finally {
      _user = null;
      _artistProfile = null;
      _venueProfile = null;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
    }
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
        _user = updatedUser;
      } catch (e) {
        // If fetching updated user fails, still update local state
        debugPrint('Warning: Failed to fetch updated user profile: $e');
        _user = _user?.copyWith(isProfileComplete: true);
      }
      
      _status = AuthStatus.authenticated;
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
        _user = updatedUser;
      } catch (e) {
        // If fetching updated user fails, still update local state
        debugPrint('Warning: Failed to fetch updated user profile: $e');
        _user = _user?.copyWith(isProfileComplete: true);
      }
      
      _status = AuthStatus.authenticated;
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
  Future<bool> completeVenueSetup(UpdateVenueRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      _venueProfile = await _venueService.completeSetup(request);
      
      // Fetch fresh user data from backend to get updated hasCompletedSetup flag
      try {
        final updatedUser = await _authService.getProfile();
        _user = updatedUser;
      } catch (e) {
        // If fetching updated user fails, still update local state
        debugPrint('Warning: Failed to fetch updated user profile: $e');
        _user = _user?.copyWith(isProfileComplete: true);
      }
      
      _status = AuthStatus.authenticated;
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
    _status = AuthStatus.error;
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
