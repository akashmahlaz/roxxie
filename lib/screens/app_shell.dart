/// 🧭 App Shell (Role-based 5-tab Navigation) — 2026 Edition
///
/// 2026 Design Principles Applied:
/// - Haptic feedback on tab selection
/// - Animated tab indicators with scale effects
/// - Badge notifications with pulsing animation
/// - Smooth page transitions
/// - Custom navigation bar with glass morphism
/// - Role-based adaptive content
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
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/providers/providers.dart';
import '../core/theme/theme.dart';

// Existing screens
import 'home_screen.dart';
import 'discovery_screen.dart';
import 'messages_screen.dart';
import 'profile_screen_v3.dart';

// New screens
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

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late int _index;
  bool _didRedirectAuth = false;

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

    // Load initial match data for badge counts + connect chat WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().refreshUnreadCount();
      // Initialize WebSocket for real-time messaging
      final chatProvider = context.read<ChatProvider>();
      final auth = context.read<AuthProvider>();
      if (auth.user?.id != null) {
        chatProvider.setCurrentUserId(auth.user!.id);
      }
      chatProvider.initSocket();
      chatProvider.refreshUnreadCount();
      debugPrint('🔌 [AppShell] WebSocket + unread count initialized for user: ${auth.user?.id}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();

    // If auth hasn't decided yet, show a safe placeholder.
    // (Splash handles routing normally; this is defensive for direct entry.)
    if (auth.status == AuthStatus.initial ||
        auth.status == AuthStatus.loading) {
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
      if (!_didRedirectAuth) {
        _didRedirectAuth = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        });
      }
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

    // If user needs to finish setup, send them to profile setup
    if (auth.status == AuthStatus.profileIncomplete) {
      if (!_didRedirectAuth) {
        _didRedirectAuth = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil('/profile-setup', (route) => false);
        });
      }
      return Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.crimson),
        ),
      );
    }

    _didRedirectAuth = false;

    final isArtist = auth.isArtist;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Try to pop nested navigator first
        final nav = _currentTabNavigator;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          // Go to home tab instead of exiting
          setState(() => _index = 0);
        }
        // If already on home tab root, do nothing (don't exit app)
      },
      child: Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: SafeArea(
          top: false,
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              _TabNavigator(navigatorKey: _homeNavKey, root: const HomeScreen()),
              _TabNavigator(
                navigatorKey: _discoverNavKey,
                root: const DiscoveryScreen(),
              ),
              _TabNavigator(
                navigatorKey: _roleNavKey,
                root: isArtist
                    ? const ArtistCalendarScreen()
                    : const GigsScreen(),
              ),
              _TabNavigator(
                navigatorKey: _messagesNavKey,
                root: const MessagesScreen(),
              ),
              _TabNavigator(
                navigatorKey: _meNavKey,
                root: const ProfileScreenV3(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildNavigationBar(
          context: context,
          brightness: brightness,
          isArtist: isArtist,
        ),
      ),
    );
  }

  Widget _buildNavigationBar({
    required BuildContext context,
    required Brightness brightness,
    required bool isArtist,
  }) {
    // Modern 2026 glass morphism navigation bar
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: AppColors.border(brightness).withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Consumer2<MatchProvider, ChatProvider>(
                builder: (context, matchProvider, chatProvider, _) {
                  // Use max of match-level unread (conversations with unread)
                  // and chat-level total unread (individual messages) for badge
                  final unreadMessages = chatProvider.totalUnread > 0
                      ? chatProvider.totalUnread
                      : matchProvider.unreadCount;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Home',
                        brightness: brightness,
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.explore_outlined,
                        activeIcon: Icons.explore_rounded,
                        label: 'Discover',
                        brightness: brightness,
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: isArtist
                            ? Icons.calendar_month_outlined
                            : Icons.work_outline_rounded,
                        activeIcon: isArtist
                            ? Icons.calendar_month_rounded
                            : Icons.work_rounded,
                        label: isArtist ? 'Calendar' : 'Gigs',
                        brightness: brightness,
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: 'Messages',
                        brightness: brightness,
                        badgeCount: unreadMessages,
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Me',
                        brightness: brightness,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Brightness brightness,
    int badgeCount = 0,
  }) {
    final isSelected = _index == index;

    // Build the icon widget
    Widget iconWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.crimson.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? activeIcon : icon,
        size: 24,
        color: isSelected ? AppColors.crimson : AppColors.textSec(brightness),
      ),
    );

    // Wrap with Badge if there's an unread count
    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
        backgroundColor: AppColors.crimson,
        textColor: Colors.white,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with scale animation
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: iconWidget,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.textSec(brightness),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(int newIndex) {
    HapticFeedback.selectionClick();
    if (newIndex == _index) {
      // Re-tapping current tab pops to root of that tab.
      _popToRootForIndex(newIndex);
      return;
    }
    setState(() => _index = newIndex);
  }

  /// Get the NavigatorState for the currently active tab
  NavigatorState? get _currentTabNavigator {
    return switch (AppShellTab.values[_index]) {
      AppShellTab.home => _homeNavKey.currentState,
      AppShellTab.discover => _discoverNavKey.currentState,
      AppShellTab.roleTab => _roleNavKey.currentState,
      AppShellTab.messages => _messagesNavKey.currentState,
      AppShellTab.me => _meNavKey.currentState,
    };
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
  const _TabNavigator({required this.navigatorKey, required this.root});

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
