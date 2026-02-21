/// 🎸 GIGMATCH API Configuration
/// Central configuration for API endpoints and settings
library;

class ApiConfig {
  // 🌐 Base URLs
  // Defaults to production. Override for local/dev with:
  // flutter run --dart-define=API_BASE_URL=http://<LAN-IP>:3000/api/v1 \
  //             --dart-define=WS_BASE_URL=ws://<LAN-IP>:3000
  static const String _defaultBaseUrl = 'http://10.183.58.168:3000/api/v1';
  static const String _defaultWsUrl = 'ws://10.183.58.168:3000';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: _defaultWsUrl,
  );

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
  static const String rememberMeKey = 'remember_me';

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
