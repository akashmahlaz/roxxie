/// 🔐 GIGMATCH Auth Models
/// Models for authentication, tokens, and user data

import 'user_models.dart';

/// Auth Tokens
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] ?? json['access_token'] ?? '',
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}

/// Login Response
class LoginResponse {
  final User user;
  final AuthTokens tokens;
  final String? message;

  LoginResponse({required this.user, required this.tokens, this.message});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user']),
      tokens: AuthTokens.fromJson(json),
      message: json['message'],
    );
  }
}

/// Register Request
class RegisterRequest {
  final String email;
  final String password;
  final String name;
  final UserRole role;
  final String? phone;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
    'role': role.value,
    if (phone != null) 'phone': phone,
  };
}

/// Login Request
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Change Password Request
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  };
}

/// Forgot Password Request
class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

/// Reset Password Request
class ResetPasswordRequest {
  final String token;
  final String newPassword;

  ResetPasswordRequest({required this.token, required this.newPassword});

  Map<String, dynamic> toJson() => {'token': token, 'newPassword': newPassword};
}
