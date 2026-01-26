/// 🎸 GIGMATCH API Configuration
/// Central configuration for API endpoints and settings
library;

class ApiConfig {
  // 🌐 Base URLs
  // Production:
  // static const String baseUrl = 'https://gigmatch.onrender.com/api/v1';
  // static const String wsUrl = 'wss://gigmatch.onrender.com';

  // Local development (use your computer's IP for physical device)
  // For Android emulator use 10.0.2.2, for physical device use your LAN IP
  static const String baseUrl = 'http://10.188.28.168:3000/api/v1';
  static const String wsUrl = 'ws://10.188.28.168:3000';

  // ⏱️ Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // 🔑 Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingSkippedKey = 'onboarding_skipped';
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';

  // 📡 Endpoints
  static const String auth = '/auth';
  static const String artists = '/artists';
  static const String venues = '/venues';
  static const String swipes = '/swipes';
  static const String gigs = '/gigs';
  static const String matches = '/matches';
  static const String messages = '/messages';
  static const String upload = '/upload';

  // 🌍 External Services
  static const String googlePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
}

/// API Endpoints helper
