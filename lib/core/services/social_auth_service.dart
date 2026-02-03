/// 🔐 GIGMATCH Social Authentication Service
///
/// Handles Google and Apple Sign-In with backend integration.
/// Provides unified interface for social authentication.
library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../api/api.dart';
import '../models/models.dart';

/// Social auth provider types
enum SocialAuthProvider { google, apple }

/// Result of social authentication
class SocialAuthResult {
  final bool success;
  final User? user;
  final AuthTokens? tokens;
  final bool isNewUser;
  final bool needsRoleSelection;
  final String? errorMessage;

  SocialAuthResult({
    required this.success,
    this.user,
    this.tokens,
    this.isNewUser = false,
    this.needsRoleSelection = false,
    this.errorMessage,
  });

  factory SocialAuthResult.success({
    required User user,
    required AuthTokens tokens,
    bool isNewUser = false,
    bool needsRoleSelection = false,
  }) {
    return SocialAuthResult(
      success: true,
      user: user,
      tokens: tokens,
      isNewUser: isNewUser,
      needsRoleSelection: needsRoleSelection,
    );
  }

  factory SocialAuthResult.failure(String message) {
    return SocialAuthResult(success: false, errorMessage: message);
  }
}

class SocialAuthService {
  final ApiClient _client = ApiClient();

  // ═══════════════════════════════════════════════════════════════════════════
  // GOOGLE SIGN-IN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sign in with Google
  ///
  /// If [role] is provided, it will be used for new user registration.
  /// If not provided and user is new, needsRoleSelection will be true.
  Future<SocialAuthResult> signInWithGoogle({UserRole? role}) async {
    try {
      // google_sign_in v7 uses singleton pattern
      final googleSignIn = GoogleSignIn.instance;

      // Web Client ID from Google Cloud Console (used for backend token verification)
      const serverClientId =
          '591438057904-vel7lra283ge5lnf4bv7ui3vp1pnommm.apps.googleusercontent.com';

      // Initialize must be called first with serverClientId
      await googleSignIn.initialize(
        clientId: null, // Not needed for Android/iOS
        serverClientId:
            serverClientId, // Web OAuth client ID from Google Cloud Console
      );

      // Use authenticate() for v7 (replaces signIn())
      // First try lightweight authentication
      GoogleSignInAccount? googleUser;

      // Check if we can use authenticate (not supported on web)
      if (googleSignIn.supportsAuthenticate()) {
        googleUser = await googleSignIn.authenticate();
      } else {
        // For web, attempt lightweight authentication
        final futureOrNull = googleSignIn.attemptLightweightAuthentication();
        if (futureOrNull != null) {
          googleUser = await futureOrNull;
        }
      }

      if (googleUser == null) {
        return SocialAuthResult.failure('Google sign-in was cancelled');
      }

      // Get the ID token from authentication
      final authentication = googleUser.authentication;
      final String? idToken = authentication.idToken;

      if (idToken == null) {
        return SocialAuthResult.failure('Failed to get Google ID token');
      }

      // Send to backend
      return await _authenticateWithBackend(
        provider: SocialAuthProvider.google,
        idToken: idToken,
        role: role,
        email: googleUser.email,
        name: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );
    } on GoogleSignInException catch (e) {
      debugPrint('Google sign-in exception: ${e.code}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return SocialAuthResult.failure('Google sign-in was cancelled');
      }
      return SocialAuthResult.failure(
        'Google sign-in failed: ${e.description ?? e.code.name}',
      );
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return SocialAuthResult.failure('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google sign-out error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPLE SIGN-IN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if Apple Sign-In is available on this device
  Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }

  /// Sign in with Apple
  ///
  /// If [role] is provided, it will be used for new user registration.
  /// If not provided and user is new, needsRoleSelection will be true.
  Future<SocialAuthResult> signInWithApple({UserRole? role}) async {
    try {
      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final String? identityToken = credential.identityToken;
      final String authorizationCode = credential.authorizationCode;

      if (identityToken == null) {
        return SocialAuthResult.failure('Failed to get Apple identity token');
      }

      // Build name from Apple credential (only available on first sign-in)
      String? name;
      if (credential.givenName != null || credential.familyName != null) {
        name = [
          credential.givenName,
          credential.familyName,
        ].where((n) => n != null && n.isNotEmpty).join(' ');
      }

      // Send to backend
      return await _authenticateWithBackend(
        provider: SocialAuthProvider.apple,
        idToken: identityToken,
        authorizationCode: authorizationCode,
        role: role,
        email: credential.email,
        name: name,
        rawNonce: rawNonce,
      );
    } catch (e) {
      debugPrint('Apple sign-in error: $e');

      if (e is SignInWithAppleAuthorizationException) {
        switch (e.code) {
          case AuthorizationErrorCode.canceled:
            return SocialAuthResult.failure('Apple sign-in was cancelled');
          case AuthorizationErrorCode.failed:
            return SocialAuthResult.failure('Apple sign-in failed');
          case AuthorizationErrorCode.invalidResponse:
            return SocialAuthResult.failure('Invalid response from Apple');
          case AuthorizationErrorCode.notHandled:
            return SocialAuthResult.failure('Apple sign-in not handled');
          case AuthorizationErrorCode.notInteractive:
            return SocialAuthResult.failure(
              'Apple sign-in requires interaction',
            );
          case AuthorizationErrorCode.unknown:
            return SocialAuthResult.failure('Unknown Apple sign-in error');
          case AuthorizationErrorCode.credentialExport:
            return SocialAuthResult.failure('Apple credential export error');
          case AuthorizationErrorCode.credentialImport:
            return SocialAuthResult.failure('Apple credential import error');
          case AuthorizationErrorCode.matchedExcludedCredential:
            return SocialAuthResult.failure('Apple credential excluded');
        }
      }

      return SocialAuthResult.failure('Apple sign-in failed: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKEND AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<SocialAuthResult> _authenticateWithBackend({
    required SocialAuthProvider provider,
    required String idToken,
    String? authorizationCode,
    UserRole? role,
    String? email,
    String? name,
    String? photoUrl,
    String? rawNonce,
  }) async {
    try {
      final endpoint = provider == SocialAuthProvider.google
          ? Endpoints.authGoogle
          : Endpoints.authApple;

      final data = <String, dynamic>{
        'idToken': idToken,
        if (authorizationCode case final ac?) 'authorizationCode': ac,
        if (role case final r?) 'role': r.name,
        if (email case final e?) 'email': e,
        if (name case final n?) 'name': n,
        if (photoUrl case final p?) 'photoUrl': p,
        if (rawNonce case final n?) 'nonce': n,
      };

      final response = await _client.post(endpoint, data: data);
      final loginResponse = LoginResponse.fromJson(response.data);

      // Save tokens and user data
      await _client.saveTokens(loginResponse.tokens);
      await _client.saveUser(jsonEncode(loginResponse.user.toJson()));

      // Check if user needs role selection (new social user without role)
      final needsRole = response.data['needsRoleSelection'] == true;

      return SocialAuthResult.success(
        user: loginResponse.user,
        tokens: loginResponse.tokens,
        isNewUser: response.data['isNewUser'] == true,
        needsRoleSelection: needsRole,
      );
    } catch (e) {
      debugPrint('Backend auth error: $e');
      return SocialAuthResult.failure(
        'Authentication failed. Please try again.',
      );
    }
  }

  /// Update role for social auth user
  Future<bool> updateUserRole(UserRole role) async {
    try {
      await _client.patch(
        Endpoints.authUpdateProfile,
        data: {'role': role.name},
      );
      return true;
    } catch (e) {
      debugPrint('Update role error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
