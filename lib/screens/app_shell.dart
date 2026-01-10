/// 🧭 App Shell (Role-based 5-tab Navigation)
///
/// Provides a modern, enterprise-grade navigation foundation:
/// - Uses Material 3 `NavigationBar`
/// - 5 tabs with role-based content (Artist vs Venue)
/// - Preserves per-tab navigation stack via nested Navigators
/// - Keeps tab positions consistent across roles
///
/// Tabs (Artist):
/// 1) Home      -> HomeScreen
/// 2) Discover  -> DiscoveryScreen (Artist: gigs feed later)
/// 3) Calendar  -> ArtistCalendarScreen
/// 4) Messages  -> MatchesScreen (entry to chats)
/// 5) Me        -> ProfileScreen
///
/// Tabs (Venue):
/// 1) Home      -> HomeScreen
/// 2) Discover  -> DiscoveryScreen (Venue: artists feed)
/// 3) Gigs      -> GigsScreen
/// 4) Messages  -> MatchesScreen
/// 5) Me        -> ProfileScreen
///
/// Notes:
/// - This file is intentionally UI-only and does not change auth/profile logic.
/// - We only display city/country in UI. Exact coordinates remain internal.
/// - We do not use HTML entities or emojis by default in this codebase.
///
/// Wiring:
/// - Replace `/home` route destination with `AppShell()` once ready.
///   (Example: in `main.dart`, map '/home' to `AppShell()`.)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/providers.dart';
import '../core/theme/theme.dart';

// Existing screens
import 'home_screen.dart';
import 'discovery_screen.dart';
import 'matches_screen.dart';
import 'profile_screen.dart';

// New placeholder screens already added
import 'artist/calendar_screen.dart';
import 'venue/gigs_screen.dart';

/// Tabs are fixed positions across roles:
/// 0 Home, 1 Discover, 2 RoleTab (Calendar|Gigs), 3 Messages, 4 Me
enum AppShellTab { home, discover, roleTab, messages, me }

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = AppShellTab.home});

  final AppShellTab initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;

  // Nested navigators to preserve state per tab
  final _homeNavKey = GlobalKey<NavigatorState>();
  final _discoverNavKey = GlobalKey<NavigatorState>();
  final _roleNavKey = GlobalKey<NavigatorState>();
  final _messagesNavKey = GlobalKey<NavigatorState>();
  final _meNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.index;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();

    // If auth hasn't decided yet, show a safe placeholder.
    // (Splash handles routing normally; this is defensive for direct entry.)
    if (auth.status == AuthStatus.initial || auth.status == AuthStatus.loading) {
      return Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.crimson),
        ),
      );
    }

    // Safety: if user is not authenticated, route away from shell.
    // App-level routing may already prevent this.
    if (!auth.isAuthenticated && auth.status != AuthStatus.profileIncomplete) {
      return Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: Center(
          child: Text(
            'Please sign in to continue.',
            style: TextStyle(color: AppColors.text(brightness)),
          ),
        ),
      );
    }

    final isArtist = auth.isArtist;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            _TabNavigator(
              navigatorKey: _homeNavKey,
              root: const HomeScreen(),
            ),
            _TabNavigator(
              navigatorKey: _discoverNavKey,
              root: const DiscoveryScreen(),
            ),
            _TabNavigator(
              navigatorKey: _roleNavKey,
              root: isArtist ? const ArtistCalendarScreen() : const GigsScreen(),
            ),
            _TabNavigator(
              navigatorKey: _messagesNavKey,
              root: const MatchesScreen(),
            ),
            _TabNavigator(
              navigatorKey: _meNavKey,
              root: const ProfileScreen(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(
        context: context,
        brightness: brightness,
        isArtist: isArtist,
      ),
    );
  }

  Widget _buildNavigationBar({
    required BuildContext context,
    required Brightness brightness,
    required bool isArtist,
  }) {
    // Modern Material 3 NavigationBar: clean, minimal, premium.
    // We use a subtle surface and clear selected indicator.
    final bg = AppColors.surface(brightness);
    final border = AppColors.border(brightness).withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: border, width: 1),
        ),
      ),
      child: NavigationBar(
        backgroundColor: bg,
        elevation: 0,
        height: 68,
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        indicatorColor: AppColors.crimson.withValues(
          alpha: brightness == Brightness.dark ? 0.18 : 0.14,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(isArtist ? Icons.calendar_month_outlined : Icons.work_outline_rounded),
            selectedIcon: Icon(isArtist ? Icons.calendar_month_rounded : Icons.work_rounded),
            label: isArtist ? 'Calendar' : 'Gigs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Me',
          ),
        ],
      ),
    );
  }

  void _onTap(int newIndex) {
    if (newIndex == _index) {
      // Re-tapping current tab pops to root of that tab.
      _popToRootForIndex(newIndex);
      return;
    }
    setState(() => _index = newIndex);
  }

  void _popToRootForIndex(int index) {
    final NavigatorState? nav = switch (AppShellTab.values[index]) {
      AppShellTab.home => _homeNavKey.currentState,
      AppShellTab.discover => _discoverNavKey.currentState,
      AppShellTab.roleTab => _roleNavKey.currentState,
      AppShellTab.messages => _messagesNavKey.currentState,
      AppShellTab.me => _meNavKey.currentState,
    };

    if (nav == null) return;
    nav.popUntil((route) => route.isFirst);
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.root,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => root,
        );
      },
    );
  }
}
