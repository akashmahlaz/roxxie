/// 🔐 GIGMATCH Auth Service
/// Handles authentication, registration, and token management
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../models/models.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  /// 📝 Register new user
  Future<LoginResponse> register(RegisterRequest request) async {
    try {
      final response = await _client.post(
        Endpoints.authRegister,
        data: request.toJson(),
      );

      final loginResponse = LoginResponse.fromJson(response.data);

      // Save tokens and user data
      await _client.saveTokens(loginResponse.tokens);
      await _client.saveUser(jsonEncode(loginResponse.user.toJson()));

      return loginResponse;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  /// 🔑 Login with email and password
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _client.post(
        Endpoints.authLogin,
        data: request.toJson(),
      );

      final loginResponse = LoginResponse.fromJson(response.data);

      // Save tokens and user data
      await _client.saveTokens(loginResponse.tokens);
      await _client.saveUser(jsonEncode(loginResponse.user.toJson()));

      return loginResponse;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  /// 🚪 Logout
  Future<void> logout() async {
    try {
      await _client.post(Endpoints.authLogout);
    } catch (e) {
      debugPrint('Logout error (non-critical): $e');
    } finally {
      await _client.clearTokens();
    }
  }

  /// 🔄 Refresh tokens
  Future<bool> refreshTokens() async {
    return await _client.refreshTokens();
  }

  /// 👤 Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await _client.get(Endpoints.authMe);
      return User.fromJson(response.data);
    } catch (e) {
      debugPrint('Get profile error: $e');
      rethrow;
    }
  }

  /// ✏️ Update user profile
  Future<User> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await _client.patch(Endpoints.authUpdateProfile, data: updates);

      final user = User.fromJson(response.data);
      await _client.saveUser(jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  /// 🔒 Change password
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      await _client.post(Endpoints.authChangePassword, data: request.toJson());
    } catch (e) {
      debugPrint('Change password error: $e');
      rethrow;
    }
  }

  /// 📧 Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      await _client.post(
        Endpoints.authForgotPassword,
        data: ForgotPasswordRequest(email: email).toJson(),
      );
    } catch (e) {
      debugPrint('Forgot password error: $e');
      rethrow;
    }
  }

  /// 🔑 Reset password with token
  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _client.post(Endpoints.authResetPassword, data: request.toJson());
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    }
  }

  /// ✅ Verify email with token
  Future<void> verifyEmail(String token) async {
    try {
      await _client.post(Endpoints.authVerifyEmail, data: {'token': token});
    } catch (e) {
      debugPrint('Verify email error: $e');
      rethrow;
    }
  }

  /// 📧 Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _client.post(Endpoints.authResendVerification, data: {'email': email});
    } catch (e) {
      debugPrint('Resend verification error: $e');
      rethrow;
    }
  }

  /// ✅ Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _client.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// 📦 Get cached user
  Future<User?> getCachedUser() async {
    try {
      final userData = await _client.getUser();
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 💾 Save user to cache (for profile completion)
  Future<void> cacheUser(User user) async {
    await _client.saveUser(jsonEncode(user.toJson()));
  }

  /// ✅ Onboarding skipped flag
  Future<void> setOnboardingSkipped(bool value) async {
    await _client.saveOnboardingSkipped(value);
  }

  /// ✅ Read onboarding skipped flag
  Future<bool> getOnboardingSkipped() async {
    return await _client.getOnboardingSkipped();
  }
}
