/// 🧭 GIGMATCH App Router - Deep Link & Navigation
///
/// Declarative navigation with go_router for:
/// - Type-safe routing
/// - Deep link handling (app links)
/// - Notification navigation
/// - Shareable profile/gig URLs
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';

// Screens
import '../../screens/splash_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/role_selection_screen_v3.dart';
import '../../screens/artist_signup_screen_v2.dart';
import '../../screens/venue_signup_screen_v2.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/app_shell.dart';
import '../../screens/chat_screen_v2.dart';
import '../../screens/gig_details_screen.dart';
import '../../screens/gig_contract_screen.dart';
import '../../screens/profile_preview_screen.dart';
import '../../screens/profile_screen_v3.dart';
import '../../screens/edit_profile/edit_profile_hub_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/premium_screen.dart';
import '../../screens/about_screen.dart';
import '../../screens/support_screen.dart';
import '../../screens/wallet_screen.dart';
import '../../screens/reviews_screen.dart';
import '../../screens/verification_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/analytics_screen.dart';
import '../../screens/artist/calendar_screen.dart';
import '../../screens/artist/artist_profile_setup_screen.dart';
import '../../screens/venue/venue_profile_setup_screen.dart';
import '../../screens/booking/booking_details_screen.dart';

/// Global navigator key for accessing navigation from services
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// App Router configuration with deep link support
class AppRouter {
  final AuthProvider authProvider;

  AppRouter({required this.authProvider});

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,

    // Redirect logic based on auth state
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isAuthRoute =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/artist-signup') ||
          state.matchedLocation.startsWith('/venue-signup') ||
          state.matchedLocation.startsWith('/role-selection');
      final isSplash = state.matchedLocation == '/';

      // Allow splash screen always
      if (isSplash) {
        return null;
      }

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isAuthRoute && !isOnboarding) {
        return '/login';
      }

      // If logged in and trying to access auth route
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),

    routes: [
      // ══════════════════════════════════════════════════════════════════
      // SPLASH & ONBOARDING
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ══════════════════════════════════════════════════════════════════
      // AUTHENTICATION
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreenV3(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/artist-signup',
        name: 'artist-signup',
        builder: (context, state) => const ArtistSignupScreenV2(),
      ),
      GoRoute(
        path: '/venue-signup',
        name: 'venue-signup',
        builder: (context, state) => const VenueSignupScreenV2(),
      ),

      // ══════════════════════════════════════════════════════════════════
      // MAIN APP (with shell navigation)
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const AppShell(),
      ),

      // ══════════════════════════════════════════════════════════════════
      // PROFILE SETUP
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/artist-setup',
        name: 'artist-setup',
        builder: (context, state) => const ArtistProfileSetupScreen(),
      ),
      GoRoute(
        path: '/venue-setup',
        name: 'venue-setup',
        builder: (context, state) => const VenueProfileSetupScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) {
          final auth = context.read<AuthProvider>();
          if (auth.isArtist) {
            return const ArtistProfileSetupScreen();
          }
          return const VenueProfileSetupScreen();
        },
      ),

      // ══════════════════════════════════════════════════════════════════
      // CHAT - Deep linkable
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/chat/:matchId',
        name: 'chat',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return ChatScreenV2(matchId: matchId);
        },
      ),

      // ══════════════════════════════════════════════════════════════════
      // GIGS - Deep linkable
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/gig/:gigId',
        name: 'gig-details',
        builder: (context, state) {
          final gigId = state.pathParameters['gigId']!;
          return GigDetailsScreen(gigId: gigId);
        },
      ),

      // ══════════════════════════════════════════════════════════════════
      // BOOKINGS - Deep linkable
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/booking/:bookingId',
        name: 'booking-details',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return BookingDetailsScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/contracts',
        name: 'contracts',
        builder: (context, state) => const GigContractScreen(),
      ),
      GoRoute(
        path: '/contract/:contractId',
        name: 'contract-details',
        builder: (context, state) {
          final contractId = state.pathParameters['contractId']!;
          return GigContractScreen(contractId: contractId);
        },
      ),

      // ══════════════════════════════════════════════════════════════════
      // PROFILES - Deep linkable (shareable)
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/artist/:artistId',
        name: 'artist-profile',
        builder: (context, state) {
          final artistId = state.pathParameters['artistId']!;
          return ProfilePreviewScreen(
            profileId: artistId,
            profileType: ProfileViewType.artist,
          );
        },
      ),
      GoRoute(
        path: '/venue/:venueId',
        name: 'venue-profile',
        builder: (context, state) {
          final venueId = state.pathParameters['venueId']!;
          return ProfilePreviewScreen(
            profileId: venueId,
            profileType: ProfileViewType.venue,
          );
        },
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'public-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfilePreviewScreen(
            profileId: userId,
            profileType: ProfileViewType.artist,
          );
        },
      ),
      GoRoute(
        path: '/profile-preview',
        name: 'profile-preview',
        builder: (context, state) => const ProfilePreviewScreen(),
      ),

      // ══════════════════════════════════════════════════════════════════
      // MY PROFILE & SETTINGS
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/profile',
        name: 'my-profile',
        builder: (context, state) => const ProfileScreenV3(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileHubScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ══════════════════════════════════════════════════════════════════
      // ENTERPRISE FEATURES
      // ══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/wallet',
        name: 'wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/reviews',
        name: 'reviews',
        builder: (context, state) => const ReviewsScreen(),
      ),
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const ArtistCalendarScreen(),
      ),
      GoRoute(
        path: '/premium',
        name: 'premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportScreen(),
      ),
    ],
  );

  /// Navigate to a deep link path
  void handleDeepLink(String path) {
    debugPrint('🔗 [AppRouter] Handling deep link: $path');
    router.go(path);
  }

  /// Navigate from notification payload
  void navigateFromNotification(Map<String, dynamic> data) {
    final deepLink = data['deepLink'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      handleDeepLink(deepLink);
    }
  }
}
