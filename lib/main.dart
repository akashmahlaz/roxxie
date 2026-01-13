import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme.dart';
import 'core/providers/providers.dart';
import 'core/services/error_handling_service.dart';

// Screens
import 'screens/splash_screen_v2.dart';
import 'screens/onboarding_screen_v2.dart';
import 'screens/role_selection_screen_v2.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/discovery_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/about_screen.dart';
import 'screens/support_screen.dart';
import 'screens/artist/artist_profile_setup_screen.dart';
import 'screens/venue/venue_profile_setup_screen.dart';

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

        // Named routes for navigation
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreenV2(),
          '/onboarding': (context) => const OnboardingScreenV2(),
          '/role-selection': (context) => const RoleSelectionScreenV2(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const AppShell(),
          '/discovery': (context) => const DiscoveryScreen(),
          '/matches': (context) => const MatchesScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/premium': (context) => const PremiumScreen(),
          '/about': (context) => const AboutScreen(),
          '/support': (context) => const SupportScreen(),
          '/artist-setup': (context) => const ArtistProfileSetupScreen(),
          '/venue-setup': (context) => const VenueProfileSetupScreen(),
        },

        // Handle dynamic routes (e.g., chat with ID)
        onGenerateRoute: (settings) {
          // Chat screen with match ID
          if (settings.name?.startsWith('/chat/') ?? false) {
            final matchId = settings.name!.split('/').last;
            return MaterialPageRoute(
              builder: (context) => ChatScreen(matchId: matchId),
            );
          }

          // Profile setup based on role
          if (settings.name == '/profile-setup') {
            return MaterialPageRoute(
              builder: (context) {
                final authProvider = context.read<AuthProvider>();
                if (authProvider.isArtist) {
                  return const ArtistProfileSetupScreen();
                } else {
                  return const VenueProfileSetupScreen();
                }
              },
            );
          }

          return null;
        },
      ),
    );
  }
}
