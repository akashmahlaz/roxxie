import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'core/theme/theme.dart';
import 'core/providers/providers.dart';
import 'core/services/error_handling_service.dart';
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
import 'screens/matches_screen_v2.dart';
import 'screens/chat_screen_v2.dart';
import 'screens/profile_screen_v3.dart';
import 'screens/messages_screen.dart';
import 'screens/settings_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling service
  await ErrorHandlingService().initialize();

  // Initialize Stripe with publishable key
  // TODO: Move to environment config for production
  Stripe.publishableKey = 'pk_test_51SmC3CFPTeSKTr2qb1nt2PAyUvI85xpBGjuEXnjD8s91QDROaCMaPNDmmUKTZ3KvXMPMDR0V13PzHZA8C2PqZcOO00SFROGUN9';

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

class GigMatchApp extends StatelessWidget {
  const GigMatchApp({super.key});

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
        ChangeNotifierProvider(create: (_) => ChatProvider()),

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
            '/matches': (context) => const MatchesScreenV2(),
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
