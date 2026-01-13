/// 🌐 GigMatch API Endpoints Configuration
///
/// Centralized API endpoint definitions for the entire app
/// All endpoints should be defined here for easy maintenance
library;

class Endpoints {
  // ═══════════════════════════════════════════════════════════════════════
  // BASE CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Base API URL (configured per environment)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// WebSocket URL
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:3000',
  );

  /// API Version
  static const String apiVersion = 'v1';

  // ═══════════════════════════════════════════════════════════════════════
  // AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════

  /// User registration
  static const String authRegister = '/auth/register';

  /// User login
  static const String authLogin = '/auth/login';

  /// User logout
  static const String authLogout = '/auth/logout';

  /// Refresh access token
  static const String authRefresh = '/auth/refresh';

  /// Forgot password request
  static const String authForgotPassword = '/auth/forgot-password';

  /// Reset password with token
  static const String authResetPassword = '/auth/reset-password';

  /// Verify email
  static const String authVerifyEmail = '/auth/verify-email';

  /// Resend verification email
  static const String authResendVerification = '/auth/resend-verification';

  /// Get current user profile
  static const String authMe = '/auth/me';

  /// Update current user
  static const String authUpdateProfile = '/auth/profile';

  /// Change password
  static const String authChangePassword = '/auth/change-password';

  /// Social auth providers
  static const String authGoogle = '/auth/google';
  static const String authApple = '/auth/apple';
  static const String authFacebook = '/auth/facebook';

  // ═══════════════════════════════════════════════════════════════════════
  // ARTISTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all artists (with pagination)
  static const String artists = '/artists';

  /// Get artist by ID
  static String artistById(String id) => '/artists/$id';

  /// Update artist profile
  static String updateArtist(String id) => '/artists/$id';

  /// Delete artist account
  static String deleteArtist(String id) => '/artists/$id';

  /// Complete artist setup (wizard)
  static const String artistSetup = '/artists/setup';

  /// Update artist availability
  static String artistAvailability(String id) => '/artists/$id/availability';

  /// Get artist calendar
  static String artistCalendar(String id) => '/artists/$id/calendar';

  /// Get artist's booked gigs
  static String artistBookings(String id) => '/artists/$id/bookings';

  /// Upload artist media
  static String artistMedia(String id) => '/artists/$id/media';

  /// Delete artist media
  static String artistMediaDelete(String id, String mediaId) =>
      '/artists/$id/media/$mediaId';

  /// Search artists
  static const String artistsSearch = '/artists/search';

  /// Get featured artists
  static const String artistsFeatured = '/artists/featured';

  /// Get artist reviews
  static String artistReviews(String id) => '/artists/$id/reviews';

  /// Get artist statistics
  static String artistStats(String id) => '/artists/$id/stats';

  /// Get current artist profile
  static const String artistsMe = '/artists/me';

  /// Complete artist setup
  static const String artistsCompleteSetup = '/artists/me/complete-setup';

  /// Boost artist profile
  static const String artistsBoost = '/artists/me/boost';

  // ════════════════════════════════════════════════════════════════════════
  // VENUES
  // ════════════════════════════════════════════════════════════════════════

  /// Get all venues (with pagination)
  static const String venues = '/venues';

  /// Get venue by ID
  static String venueById(String id) => '/venues/$id';

  /// Update venue profile
  static String updateVenue(String id) => '/venues/$id';

  /// Delete venue account
  static String deleteVenue(String id) => '/venues/$id';

  /// Complete venue setup (wizard)
  static const String venueSetup = '/venues/setup';

  /// Get venue's posted gigs
  static String venueGigs(String id) => '/venues/$id/gigs';

  /// Create new gig
  static String venueCreateGig(String id) => '/venues/$id/gigs';

  /// Update gig
  static String venueUpdateGig(String venueId, String gigId) =>
      '/venues/$venueId/gigs/$gigId';

  /// Delete gig
  static String venueDeleteGig(String venueId, String gigId) =>
      '/venues/$venueId/gigs/$gigId';

  /// Get venues me
  static const String venuesMe = '/venues/me';

  /// Complete venue setup
  static const String venuesCompleteSetup = '/venues/me/complete-setup';

  /// Get venue bookings
  static String venueBookings(String id) => '/venues/$id/bookings';

  /// Search venues
  static const String venuesSearch = '/venues/search';

  /// Get featured venues
  static const String venuesFeatured = '/venues/featured';

  /// Get venue reviews
  static String venueReviews(String id) => '/venues/$id/reviews';

  /// Get venue statistics
  static String venueStats(String id) => '/venues/$id/stats';

  // ═══════════════════════════════════════════════════════════════════════
  // DISCOVERY / SWIPES
  // ═══════════════════════════════════════════════════════════════════════

  /// Get discovery feed
  static const String discover = '/swipes/discover';
  static const String discoveryFeed = '/swipes/discover';

  /// Swipe on profile (POST /swipes/:targetId with {direction: 'right'|'left'})
  static const String swipe = '/swipes';
  
  /// Swipe on specific target
  static String swipeTarget(String targetId) => '/swipes/$targetId';

  /// Swipe right on profile (use swipeTarget instead)
  static const String swipeRight = '/swipes';

  /// Swipe left on profile (use swipeTarget instead)
  static const String swipeLeft = '/swipes';

  /// Undo swipe (DELETE /swipes/:swipeId)
  static String undoSwipe(String swipeId) => '/swipes/$swipeId';
  static String swipeUndo(String swipeId) => '/swipes/$swipeId';

  /// Get who liked me
  static const String whoLikedMe = '/swipes/who-liked-me';

  /// Get swipe history
  static const String swipeHistory = '/swipes/history';

  /// Get discovery filters
  static const String discoveryFilters = '/swipes/filters';

  /// Update discovery filters
  static const String discoveryFiltersUpdate = '/swipes/filters';

  /// Get recommendations
  static const String discoveryRecommendations = '/swipes/recommendations';

  // ═══════════════════════════════════════════════════════════════════════
  // MATCHES
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all matches
  static const String matches = '/matches';
  static const String matchesList = '/matches';

  /// Get match by ID
  static String matchById(String id) => '/matches/$id';

  /// Get match details (including conversation)
  static String matchDetails(String id) => '/matches/$id';

  /// View match
  static String matchView(String id) => '/matches/$id/view';

  /// Unmatch with user
  static String unmatch(String id) => '/matches/$id/unmatch';

  /// Report match
  static String reportMatch(String id) => '/matches/$id/report';

  /// Get mutual matches
  static const String mutualMatches = '/matches/mutual';

  /// Get new matches count
  static const String newMatchesCount = '/matches/unread-count';

  /// Get matches unread count
  static const String matchesUnreadCount = '/matches/unread-count';

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES / CHAT
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all conversations
  static const String messagesConversations = '/messages/conversations';

  /// Get conversation by ID
  static String conversationById(String id) => '/messages/conversations/$id';

  /// Get or create conversation
  static const String conversationGetOrCreate = '/messages/conversations/get-or-create';

  /// Archive conversation
  static String archiveConversation(String id) =>
      '/messages/conversations/$id/archive';

  /// Unarchive conversation
  static String unarchiveConversation(String id) =>
      '/messages/conversations/$id/unarchive';

  /// Pin conversation
  static String pinConversation(String id) => '/messages/conversations/$id/pin';

  /// Unpin conversation
  static String unpinConversation(String id) => '/messages/conversations/$id/unpin';

  /// Mute conversation
  static String muteConversation(String id) => '/messages/conversations/$id/mute';

  /// Unmute conversation
  static String unmuteConversation(String id) => '/messages/conversations/$id/unmute';

  /// Delete conversation
  static String deleteConversation(String id) => '/messages/conversations/$id';

  /// Get messages for conversation
  static String messages(String conversationId) => '/messages/$conversationId';

  /// Send message
  static String sendMessage(String conversationId) =>
      '/messages/$conversationId/send';

  /// Mark messages as read
  static String markMessagesRead(String conversationId) =>
      '/messages/$conversationId/read';

  /// Edit message
  static String editMessage(String conversationId, String messageId) =>
      '/messages/$conversationId/$messageId';

  /// Delete message
  static String deleteMessage(String conversationId, String messageId) =>
      '/messages/$conversationId/$messageId';

  /// Search messages
  static const String messagesSearch = '/messages/search';

  /// Get unread message count
  static const String messagesUnreadCount = '/messages/unread/count';

  // ═══════════════════════════════════════════════════════════════════════
  // GIGS / BOOKINGS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all gigs
  static const String gigs = '/gigs';

  /// Get gig by ID
  static String gigById(String id) => '/gigs/$id';

  /// Search gigs
  static const String gigsSearch = '/gigs/search';

  /// Get gigs near location
  static const String gigsNearby = '/gigs/nearby';

  /// Get gig categories
  static const String gigCategories = '/gigs/categories';

  /// Create gig (venue only)
  static const String gigsCreate = '/gigs/create';

  /// Get my gigs
  static const String gigsMine = '/gigs/mine';

  /// Discover gigs
  static const String gigsDiscover = '/gigs/discover';

  /// Create gig request/application
  static const String gigApply = '/gigs/apply';

  /// Get gig applications
  static String gigApplications(String gigId) => '/gigs/$gigId/applications';

  /// Respond to gig application
  static String respondToApplication(String gigId, String applicationId) =>
      '/gigs/$gigId/applications/$applicationId';

  /// Get user's gig applications
  static const String myGigApplications = '/gigs/my-applications';

  /// Withdraw gig application
  static String withdrawApplication(String applicationId) =>
      '/gigs/applications/$applicationId';

  // ═══════════════════════════════════════════════════════════════════════
  // BOOKINGS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all bookings
  static const String bookings = '/bookings';

  /// Get booking by ID
  static String bookingById(String id) => '/bookings/$id';

  /// Create booking
  static const String createBooking = '/bookings';

  /// Update booking status
  static String updateBooking(String id) => '/bookings/$id';

  /// Cancel booking
  static String cancelBooking(String id) => '/bookings/$id/cancel';

  /// Get booking timeline
  static String bookingTimeline(String id) => '/bookings/$id/timeline';

  /// Confirm booking completion
  static String confirmBooking(String id) => '/bookings/$id/confirm';

  /// Get user's bookings
  static const String myBookings = '/bookings/my';

  /// Get venue's bookings
  static String venueBookingsList(String venueId) => '/venues/$venueId/bookings';

  /// Get artist's bookings
  static String artistBookingsList(String artistId) => '/artists/$artistId/bookings';

  // ═══════════════════════════════════════════════════════════════════════
  // REVIEWS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get reviews
  static const String reviews = '/reviews';

  /// Get review by ID
  static String reviewById(String id) => '/reviews/$id';

  /// Create review
  static const String createReview = '/reviews';

  /// Update review
  static String updateReview(String id) => '/reviews/$id';

  /// Delete review
  static String deleteReview(String id) => '/reviews/$id';

  /// Get reviews for user
  static String userReviews(String userId, String userType) =>
      '/users/$userType/$userId/reviews';

  /// Get user's given reviews
  static const String myGivenReviews = '/reviews/given';

  /// Report review
  static String reportReview(String id) => '/reviews/$id/report';

  /// Respond to review
  static String respondToReview(String id) => '/reviews/$id/respond';

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all notifications
  static const String notifications = '/notifications';

  /// Get unread count
  static const String notificationsUnreadCount = '/notifications/unread/count';

  /// Mark notification as read
  static String markNotificationRead(String id) => '/notifications/$id/read';

  /// Mark all as read
  static const String markAllNotificationsRead = '/notifications/read-all';

  /// Delete notification
  static String deleteNotification(String id) => '/notifications/$id';

  /// Delete all notifications
  static const String deleteAllNotifications = '/notifications';

  /// Register push notification token
  static const String notificationsRegisterToken = '/notifications/token';

  /// Update notification settings
  static const String notificationsUpdateSettings = '/notifications/settings';

  // ═══════════════════════════════════════════════════════════════════════
  // SUBSCRIPTIONS & PAYMENTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get current subscription
  static const String subscriptionCurrent = '/subscription';

  /// Get available subscription plans
  static const String subscriptionPlans = '/subscription/plans';

  /// Create checkout session
  static const String subscriptionCreateCheckout = '/subscription/checkout';

  /// Verify checkout completion
  static const String subscriptionVerifyCheckout = '/subscription/verify';

  /// Cancel subscription
  static const String subscriptionCancel = '/subscription/cancel';

  /// Resume subscription
  static const String subscriptionResume = '/subscription/resume';

  /// Update subscription (upgrade/downgrade)
  static const String subscriptionUpdate = '/subscription/update';

  /// Start free trial
  static const String subscriptionStartTrial = '/subscription/trial';

  /// Use profile boost
  static const String subscriptionUseBoost = '/subscription/boost';

  /// Get payment methods
  static const String paymentMethods = '/subscription/payment-methods';

  /// Add payment method
  static const String paymentMethodsAdd = '/subscription/payment-methods/add';

  /// Set default payment method
  static const String paymentMethodsSetDefault = '/subscription/payment-methods/default';

  /// Remove payment method
  static String removePaymentMethod(String id) =>
      '/subscription/payment-methods/$id';

  /// Get invoices
  static const String invoices = '/subscription/invoices';

  /// Get invoice PDF
  static String invoicePdf(String id) => '/subscription/invoices/$id/pdf';

  /// Create billing portal session
  static const String billingPortalSession = '/subscription/portal';

  /// Restore purchases
  static const String subscriptionRestore = '/subscription/restore';

  // ═══════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get profile analytics
  static const String analyticsProfile = '/analytics/profile';

  /// Get discovery analytics
  static const String analyticsDiscovery = '/analytics/discovery';

  /// Get engagement analytics
  static const String analyticsEngagement = '/analytics/engagement';

  /// Get earnings analytics
  static const String analyticsEarnings = '/analytics/earnings';

  /// Get gig analytics
  static const String analyticsGigs = '/analytics/gigs';

  /// Export analytics data
  static const String analyticsExport = '/analytics/export';

  // ═══════════════════════════════════════════════════════════════════════
  // UPLOADS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get upload URL
  static const String uploadUrl = '/upload/url';

  /// Upload file
  static const String uploadFile = '/upload';

  /// Delete uploaded file
  static String deleteUpload(String key) => '/upload/$key';

  /// Get upload progress
  static String uploadProgress(String uploadId) => '/upload/progress/$uploadId';

  /// Cancel upload
  static String cancelUpload(String uploadId) => '/upload/cancel/$uploadId';

  // ═══════════════════════════════════════════════════════════════════════
  // COMMUNITY & SOCIAL
  // ═══════════════════════════════════════════════════════════════════════

  /// Get tips/articles
  static const String tips = '/community/tips';

  /// Get tip by ID
  static String tipById(String id) => '/community/tips/$id';

  /// Get forums
  static const String forums = '/community/forums';

  /// Get forum posts
  static String forumPosts(String forumId) => '/community/forums/$forumId/posts';

  /// Create forum post
  static String createForumPost(String forumId) => '/community/forums/$forumId/posts';

  /// Get networking events
  static const String networkingEvents = '/community/events';

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  /// Get messages
  static const String messagesGet = '/messages';

  /// Send message
  static const String messagesSend = '/messages/send';

  /// Mark messages as read
  static const String messagesRead = '/messages/read';

  /// Delete message
  static const String messageDelete = '/messages/delete';

  // ═══════════════════════════════════════════════════════════════════════
  // UPLOADS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get upload signed params
  static const String uploadSignedParams = '/upload/signed-params';

  /// Upload profile photo
  static const String uploadProfilePhoto = '/upload/profile-photo';

  /// Upload gallery images
  static const String uploadGallery = '/upload/gallery';

  /// Upload audio
  static const String uploadAudio = '/upload/audio';

  /// Upload video
  static const String uploadVideo = '/upload/video';

  // ═══════════════════════════════════════════════════════════════════════
  // SEARCH & DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════

  /// Global search
  static const String search = '/search';

  /// Get search suggestions
  static const String searchSuggestions = '/search/suggestions';

  /// Get trending searches
  static const String searchTrending = '/search/trending';

  /// Get popular genres
  static const String genres = '/genres';

  /// Get locations
  static const String locations = '/locations';

  /// Get featured content
  static const String featured = '/featured';

  // ═══════════════════════════════════════════════════════════════════════
  // SETTINGS & PREFERENCES
  // ═══════════════════════════════════════════════════════════════════════

  /// Get user settings
  static const String settings = '/settings';

  /// Update user settings
  static const String updateSettings = '/settings';

  /// Get privacy settings
  static const String privacySettings = '/settings/privacy';

  /// Update privacy settings
  static const String updatePrivacySettings = '/settings/privacy';

  /// Get notification settings
  static const String notificationSettings = '/settings/notifications';

  /// Update notification settings
  static const String updateNotificationSettings = '/settings/notifications';

  /// Delete account
  static const String deleteAccount = '/settings/delete-account';

  /// Export user data
  static const String exportData = '/settings/export';

  // ═══════════════════════════════════════════════════════════════════════
  // UTILITY
  // ═══════════════════════════════════════════════════════════════════════

  /// Health check
  static const String health = '/health';

  /// App version check
  static const String version = '/version';

  /// Supported countries
  static const String countries = '/utils/countries';

  /// Supported currencies
  static const String currencies = '/utils/currencies';

  /// Timezones
  static const String timezones = '/utils/timezones';

  /// Language strings
  static const String translations = '/utils/translations';

  // ═══════════════════════════════════════════════════════════════════════
  // HELP & SUPPORT
  // ═══════════════════════════════════════════════════════════════════════

  /// Contact support
  static const String contactSupport = '/support/contact';

  /// Report bug
  static const String reportBug = '/support/bug';

  /// Get FAQ
  static const String faq = '/support/faq';

  /// Get help articles
  static const String helpArticles = '/support/articles';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN (if applicable)
  // ═══════════════════════════════════════════════════════════════════════

  /// Admin dashboard
  static const String adminDashboard = '/admin';

  /// Admin users
  static const String adminUsers = '/admin/users';

  /// Admin artists
  static const String adminArtists = '/admin/artists';

  /// Admin venues
  static const String adminVenues = '/admin/venues';

  /// Admin gigs
  static const String adminGigs = '/admin/gigs';

  /// Admin reports
  static const String adminReports = '/admin/reports';

  /// Admin analytics
  static const String adminAnalytics = '/admin/analytics';

  /// Moderation actions
  static const String adminModeration = '/admin/moderation';
}
