import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme.dart';
import 'core/providers/providers.dart';
import 'core/services/error_handling_service.dart';

// Screens - Ultra-Premium 2026 Design
import 'screens/splash_screen_v3.dart';
import 'screens/onboarding_screen_v3.dart';
import 'screens/role_selection_screen_v3.dart';
import 'screens/artist_signup_screen_v2.dart';
import 'screens/venue_signup_screen_v2.dart';
import 'screens/login_screen_v2.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/discovery_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/about_screen.dart';
import 'screens/support_screen.dart';
import 'screens/artist/artist_profile_setup_screen.dart';
import 'screens/venue/venue_profile_setup_screen.dart';

// New Enterprise Screens
import 'screens/wallet_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/gig_contract_screen.dart';
import 'screens/messages_list_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/gig_details_screen.dart';

// App Shell (5-tab navigation)
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling service
  await ErrorHandlingService().initialize();

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
      ],
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
          '/': (context) => const SplashScreenV3(),
          '/onboarding': (context) => const OnboardingScreenV3(),
          '/role-selection': (context) => const RoleSelectionScreenV3(),
          '/artist-signup': (context) => const ArtistSignupScreenV2(),
          '/venue-signup': (context) => const VenueSignupScreenV2(),
          '/login': (context) => const LoginScreenV2(),
          '/login-old': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const AppShell(),
          '/discovery': (context) => const DiscoveryScreen(),
          '/matches': (context) => const MatchesScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
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
          '/messages': (context) => const MessagesListScreen(),
          '/explore': (context) => const ExploreScreen(),
          '/verification': (context) => const VerificationScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },

        // Handle dynamic routes with smooth transitions
        onGenerateRoute: (settings) {
          // Chat screen with match ID
          if (settings.name?.startsWith('/chat/') ?? false) {
            final matchId = settings.name!.split('/').last;
            return _createFadeRoute(
              ChatScreen(matchId: matchId),
              settings,
            );
          }

          // Gig details screen with gig ID
          if (settings.name?.startsWith('/gig/') ?? false) {
            final gigId = settings.name!.split('/').last;
            return _createFadeRoute(
              GigDetailsScreen(gigId: gigId),
              settings,
            );
          }

          // Contract screen with contract ID
          if (settings.name?.startsWith('/contract/') ?? false) {
            final contractId = settings.name!.split('/').last;
            return _createFadeRoute(
              GigContractScreen(contractId: contractId),
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
    );
  }

  /// Create smooth fade transition to prevent white flashes
  static Route<T> _createFadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
