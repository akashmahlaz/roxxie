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
class Endpoints {
  // Auth
  static const String register = '${ApiConfig.auth}/register';
  static const String login = '${ApiConfig.auth}/login';
  static const String refresh = '${ApiConfig.auth}/refresh';
  static const String logout = '${ApiConfig.auth}/logout';
  static const String forgotPassword = '${ApiConfig.auth}/forgot-password';
  static const String resetPassword = '${ApiConfig.auth}/reset-password';
  static const String changePassword = '${ApiConfig.auth}/change-password';
  static const String verifyEmail = '${ApiConfig.auth}/verify-email';
  static const String resendVerification =
      '${ApiConfig.auth}/resend-verification';
  static const String profile = '${ApiConfig.auth}/profile';
  static const String me = '${ApiConfig.auth}/me';

  // Artists
  static const String artistsSearch = '${ApiConfig.artists}/search';
  static const String artistsMe = '${ApiConfig.artists}/me';
  static const String artistsCompleteSetup =
      '${ApiConfig.artists}/me/complete-setup';
  static const String artistsBoost = '${ApiConfig.artists}/me/boost';
  static String artistById(String id) => '${ApiConfig.artists}/$id';

  // Venues
  static const String venuesSearch = '${ApiConfig.venues}/search';
  static const String venuesMe = '${ApiConfig.venues}/me';
  static const String venuesCompleteSetup =
      '${ApiConfig.venues}/me/complete-setup';
  static String venueById(String id) => '${ApiConfig.venues}/$id';

  // Swipes & Discovery
  static const String swipe = ApiConfig.swipes;
  static const String discover = '${ApiConfig.swipes}/discover';
  static const String whoLikedMe = '${ApiConfig.swipes}/who-liked-me';
  static const String undoSwipe = '${ApiConfig.swipes}/undo';

  // Gigs
  static const String gigsCreate = ApiConfig.gigs; // POST /gigs
  static const String gigsMine = '${ApiConfig.gigs}/mine'; // GET /gigs/mine
  static const String gigsDiscover = '${ApiConfig.gigs}/discover'; // GET /gigs/discover

  // Matches
  static const String matchesList = ApiConfig.matches;
  static const String matchesUnreadCount = '${ApiConfig.matches}/unread-count';
  static String matchById(String id) => '${ApiConfig.matches}/$id';
  static String matchView(String id) => '${ApiConfig.matches}/$id/view';

  // Messages
  static const String messagesSend = ApiConfig.messages;
  static const String messagesGet = ApiConfig.messages;
  static const String messagesUnreadCount =
      '${ApiConfig.messages}/unread-count';
  static const String messagesRead = '${ApiConfig.messages}/read';
  static String messageDelete(String id) => '${ApiConfig.messages}/$id';

  // Upload
  static const String uploadSignedParams = '${ApiConfig.upload}/signed-params';
  static const String uploadProfilePhoto = '${ApiConfig.upload}/profile-photo';
  static const String uploadGallery = '${ApiConfig.upload}/gallery';
  static const String uploadAudio = '${ApiConfig.upload}/audio';
  static const String uploadVideo = '${ApiConfig.upload}/video';
}
