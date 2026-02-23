import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'core/theme/theme.dart';
import 'core/providers/providers.dart';
import 'core/services/error_handling_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/config/app_config.dart';
import 'core/services/hive_cache_service.dart';
import 'widgets/global_error_handler.dart';

// Screens - Ultra-Premium 2026 Design
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/role_selection_screen_v3.dart';
import 'screens/artist_signup_screen_v2.dart';
import 'screens/venue_signup_screen_v2.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/discovery_screen.dart';
import 'screens/chat_screen_v2.dart';
import 'screens/profile_screen_v3.dart';
import 'screens/messages_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/blocked_users_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/about_screen.dart';
import 'screens/support_screen.dart';
import 'screens/artist/artist_profile_setup_screen.dart';
import 'screens/venue/venue_profile_setup_screen.dart';
// Deprecated: PublicProfileScreen and ArtistPublicProfileScreen
// All routes now use ProfilePreviewScreen for consistency
import 'screens/profile_preview_screen.dart';
import 'screens/edit_profile/edit_profile_hub_screen.dart';

// New Enterprise Screens
import 'screens/wallet_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/gig_contract_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/gig_details_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/artist/calendar_screen.dart';
import 'screens/venue/create_gig_screen.dart';
import 'screens/venue/gigs_screen.dart';
import 'screens/booking_requests_screen.dart';

// Feed & Social Screens
import 'screens/create_post_screen.dart';
import 'screens/create_story_screen.dart';
import 'screens/story_viewer_screen.dart';

// App Shell (5-tab navigation)
import 'screens/app_shell.dart';

/// 🔥 Firebase Background Message Handler
/// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 [Firebase] Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up Firebase background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize error handling service
  await ErrorHandlingService().initialize();

  // 💾 Initialize Hive cache (must be before runApp)
  await initializeHiveCache();

  // Initialize Stripe with environment-specific publishable key
  Stripe.publishableKey = AppConfig.stripePublishableKey;

  // 🔗 Initialize Deep Link Service (before runApp so initial link is captured)
  await DeepLinkService().initialize();

  // Set system UI overlay style for premium immersive experience
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);

  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  runApp(const GigMatchApp());
}

/// 🎵 GIGMATCH - Where Artists Meet Stages
///
/// Ultra-premium music gig matching platform
/// Designed with world-class UI/UX principles

/// Global navigator key for deep link navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GigMatchApp extends StatefulWidget {
  const GigMatchApp({super.key});

  @override
  State<GigMatchApp> createState() => _GigMatchAppState();
}

class _GigMatchAppState extends State<GigMatchApp> {
  late final DeepLinkService _deepLinkService;
  StreamSubscription<String>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _deepLinkService = DeepLinkService();
    _listenToDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  /// Listen to incoming deep links and navigate accordingly
  void _listenToDeepLinks() {
    _deepLinkSub = _deepLinkService.deepLinkStream.listen((path) {
      debugPrint('🔗 [GigMatchApp] Deep link received: $path');
      _navigateToDeepLink(path);
    });

    // Check for pending deep link (app cold-started via link)
    final pending = _deepLinkService.pendingDeepLink;
    if (pending != null) {
      debugPrint('🔗 [GigMatchApp] Pending deep link: $pending');
      // Delay to let splash screen / auth check finish
      Future.delayed(const Duration(seconds: 2), () {
        _navigateToDeepLink(pending);
        _deepLinkService.clearPendingDeepLink();
      });
    }
  }

  /// Navigate to the correct screen based on deep link path
  void _navigateToDeepLink(String path) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('⚠️ [GigMatchApp] Navigator not ready for deep link: $path');
      return;
    }

    debugPrint('🔗 [GigMatchApp] Navigating to: $path');

    // Handle /share/* paths by stripping "share/" prefix
    String effectivePath = path;
    if (path.startsWith('/share/')) {
      effectivePath = '/${path.substring(7)}'; // /share/artist/123 -> /artist/123
    }

    // Use pushNamed which goes through onGenerateRoute
    navigator.pushNamed(effectivePath);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider - handles login, register, tokens
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),

        // Discovery Provider - swipe cards, profiles
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),

        // Match Provider - matches list, unread counts
        ChangeNotifierProvider(create: (_) => MatchProvider()),

        // Chat Provider - messages, real-time updates
        // Wire match-preview callback so chat updates flow to conversation list
        ChangeNotifierProxyProvider<MatchProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, matchProvider, chatProvider) {
            chatProvider!.onMatchPreviewUpdate = matchProvider.updateMatchPreview;
            return chatProvider;
          },
        ),

        // Profile Provider - artist/venue profile with real API data
        ChangeNotifierProvider(create: (_) => ProfileProvider()),

        // Explore Provider - search artists/venues
        ChangeNotifierProvider(create: (_) => ExploreProvider()),

        // Wallet Provider - earnings, transactions, payouts
        ChangeNotifierProvider(create: (_) => WalletProvider()),

        // Feed Provider - posts and stories
        ChangeNotifierProvider(create: (_) => FeedProvider()),
      ],
      child: GlobalErrorHandler(
        child: MaterialApp(
          title: 'GigMatch',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,

          // Apply both light and dark themes with Material 3
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,

          // Custom page transition to prevent white flashes
          builder: (context, child) {
            return child ?? const SizedBox.shrink();
          },

          // Named routes for navigation
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/role-selection': (context) => const RoleSelectionScreenV3(),
            '/artist-signup': (context) => const ArtistSignupScreenV2(),
            '/venue-signup': (context) => const VenueSignupScreenV2(),
            '/login': (context) => const LoginScreen(),
            '/login-old': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const AppShell(),
            '/discovery': (context) => const DiscoveryScreen(),
            '/matches': (context) => const MessagesScreen(),
            '/profile': (context) => const ProfileScreenV3(),
            '/edit-profile': (context) => const EditProfileHubScreen(),
            // Consolidated: both routes now use ProfilePreviewScreen
            // PublicProfileScreen is deprecated - kept for reference only
            '/public-profile': (context) => const ProfilePreviewScreen(),
            '/profile-preview': (context) => const ProfilePreviewScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/premium': (context) => const PremiumScreen(),
            '/about': (context) => const AboutScreen(),
            '/support': (context) => const SupportScreen(),
            '/artist-setup': (context) => const ArtistProfileSetupScreen(),
            '/venue-setup': (context) => const VenueProfileSetupScreen(),

            // Enterprise Screens
            '/wallet': (context) => const WalletScreen(),
            '/reviews': (context) => const ReviewsScreen(),
            '/contracts': (context) => const GigContractScreen(),
            '/messages': (context) => const MessagesScreen(),
            '/verification': (context) => const VerificationScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/analytics': (context) => const AnalyticsScreen(),
            '/calendar': (context) => const ArtistCalendarScreen(),
            '/create-gig': (context) => const CreateGigScreen(),
            '/my-gigs': (context) => const GigsScreen(),
            '/booking-requests': (context) => const BookingRequestsScreen(),

            // Feed & Social
            '/create-post': (context) => const CreatePostScreen(),
            '/create-story': (context) => const CreateStoryScreen(),

            // Block management
            '/blocked-users': (context) => const BlockedUsersScreen(),
          },

          // Handle dynamic routes with smooth transitions
          onGenerateRoute: (settings) {
            // Story viewer with arguments
            if (settings.name == '/story-viewer') {
              final args = settings.arguments as Map<String, dynamic>?;
              return _createFadeRoute(
                StoryViewerScreen(
                  storyId: args?['storyId'] ?? '',
                  userId: args?['userId'] ?? '',
                  initialItemIndex: args?['initialItemIndex'] ?? 0,
                ),
                settings,
              );
            }

            // Chat screen with match ID
            if (settings.name?.startsWith('/chat/') ?? false) {
              final matchId = settings.name!.split('/').last;
              return _createFadeRoute(ChatScreenV2(matchId: matchId), settings);
            }

            // Gig details screen with gig ID
            if (settings.name?.startsWith('/gig/') ?? false) {
              final gigId = settings.name!.split('/').last;
              return _createFadeRoute(GigDetailsScreen(gigId: gigId), settings);
            }

            // Contract screen with contract ID
            if (settings.name?.startsWith('/contract/') ?? false) {
              final contractId = settings.name!.split('/').last;
              return _createFadeRoute(
                GigContractScreen(contractId: contractId),
                settings,
              );
            }

            // Public profile with user ID (for viewing other artists)
            // Consolidated: now uses ProfilePreviewScreen instead of ArtistPublicProfileScreen
            if (settings.name?.startsWith('/profile/') ?? false) {
              final artistId = settings.name!.split('/').last;
              return _createFadeRoute(
                ProfilePreviewScreen(
                  profileId: artistId,
                  profileType: ProfileViewType.artist,
                ),
                settings,
              );
            }

            // Artist profile route
            if (settings.name?.startsWith('/artist/') ?? false) {
              final artistId = settings.name!.split('/').last;
              return _createFadeRoute(
                ProfilePreviewScreen(
                  profileId: artistId,
                  profileType: ProfileViewType.artist,
                ),
                settings,
              );
            }

            // Venue profile route
            if (settings.name?.startsWith('/venue/') ?? false) {
              final venueId = settings.name!.split('/').last;
              return _createFadeRoute(
                ProfilePreviewScreen(
                  profileId: venueId,
                  profileType: ProfileViewType.venue,
                ),
                settings,
              );
            }

            // Post deep link route (from shared links)
            if (settings.name?.startsWith('/post/') ?? false) {
              // Navigate to home feed — post-specific view can be added later
              debugPrint('🔗 [Router] Post deep link: ${settings.name}');
              return _createFadeRoute(const AppShell(), settings);
            }

            // Story deep link route (from shared links)
            if (settings.name?.startsWith('/story/') ?? false) {
              final storyId = settings.name!.split('/').last;
              debugPrint('🔗 [Router] Story deep link: $storyId');
              return _createFadeRoute(
                StoryViewerScreen(
                  storyId: storyId,
                  userId: '',
                ),
                settings,
              );
            }

            // Profile setup based on role
            if (settings.name == '/profile-setup') {
              return _createFadeRoute(
                Builder(
                  builder: (context) {
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.isArtist) {
                      return const ArtistProfileSetupScreen();
                    } else {
                      return const VenueProfileSetupScreen();
                    }
                  },
                ),
                settings,
              );
            }

            return null;
          },
        ),
      ),
    );
  }

  /// Create smooth fade transition to prevent white flashes
  static Route<T> _createFadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
