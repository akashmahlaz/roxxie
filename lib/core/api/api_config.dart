/// 🎸 GIGMATCH API Configuration
/// Central configuration for API endpoints and settings
library;

class ApiConfig {
  // 🌐 Base URLs
  static const String baseUrl = 'https://gigmatch.onrender.com/api/v1';
  static const String wsUrl = 'wss://gigmatch.onrender.com';

  // For local development, uncomment these:
  // static const String baseUrl = 'http://localhost:3000/api/v1';
  // static const String wsUrl = 'ws://localhost:3000';

  // ⏱️ Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // 🔑 Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingSkippedKey = 'onboarding_skipped';

  // 📡 Endpoints
  static const String auth = '/auth';
  static const String artists = '/artists';
  static const String venues = '/venues';
  static const String swipes = '/swipes';
  static const String gigs = '/gigs';
  static const String matches = '/matches';
  static const String messages = '/messages';
  static const String upload = '/upload';
}

/// API Endpoints helper

