/// 🏠 GIGMATCH Dashboard Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass UI effects
/// - Micro-interactions on all touch targets
/// - Animated counters for statistics
/// - Contextual/time-aware UI
/// - Shimmer loading states
/// - Optimistic state updates
///
/// Modern Material 3 dashboard - NO INTERNAL NAVIGATION
/// Navigation is handled by AppShell only
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final chatProvider = context.read<ChatProvider>();
    final discoveryProvider = context.read<DiscoveryProvider>();
    final matchProvider = context.read<MatchProvider>();

    // Initialize WebSocket connection
    chatProvider.initSocket();

    // Load data in parallel
    await Future.wait([
      discoveryProvider.loadCards(refresh: true),
      matchProvider.loadMatches(refresh: true),
    ]);

    chatProvider.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();
    final matchProvider = context.watch<MatchProvider>();
    final discoveryProvider = context.watch<DiscoveryProvider>();

    final userName = auth.user?.name ?? 'Artist';
    final isArtist = auth.isArtist;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _initializeData,
          color: AppColors.crimson,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Modern App Bar
              _buildAppBar(brightness, userName),

              // Quick Stats
              SliverToBoxAdapter(
                child: _buildQuickStats(
                  brightness,
                  matchProvider,
                  discoveryProvider,
                ),
              ),

              // Action Cards
              SliverToBoxAdapter(
                child: _buildActionCards(brightness, isArtist),
              ),

              // Recent Matches Preview
              SliverToBoxAdapter(
                child: _buildRecentMatches(brightness, matchProvider),
              ),

              // Activity Feed
              SliverToBoxAdapter(child: _buildActivitySection(brightness)),

              // Bottom padding for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Brightness brightness, String userName) {
    // Use contextual greeting from 2026 design patterns
    final greeting = getContextualGreeting();
    final greetingIcon = getTimeOfDayIcon();

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background(brightness),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    greetingIcon,
                    color: AppColors.textSec(brightness),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    greeting,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                userName.split(' ').first,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Notification bell with animated badge
        AnimatedTapFeedback(
          onTap: () {
            HapticFeedback.selectionClick();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.text(brightness),
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.crimson,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface(brightness),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildQuickStats(
    Brightness brightness,
    MatchProvider matchProvider,
    DiscoveryProvider discoveryProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.favorite_rounded,
              iconColor: AppColors.crimson,
              value: '${matchProvider.matches.length}',
              label: 'Matches',
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.visibility_rounded,
              iconColor: Colors.blue,
              value: '${discoveryProvider.remainingCards}',
              label: 'To Discover',
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.chat_bubble_rounded,
              iconColor: Colors.green,
              value: '${matchProvider.unreadCount}',
              label: 'Messages',
              brightness: brightness,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(Brightness brightness, bool isArtist) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.explore_rounded,
                  title: 'Discover',
                  subtitle: isArtist ? 'Find venues' : 'Find artists',
                  gradient: [AppColors.crimson, Colors.deepOrange],
                  onTap: () {},
                  brightness: brightness,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.rocket_launch_rounded,
                  title: 'Boost',
                  subtitle: 'Get more views',
                  gradient: [Colors.purple, Colors.deepPurple],
                  onTap: () => Navigator.pushNamed(context, '/premium'),
                  brightness: brightness,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMatches(
    Brightness brightness,
    MatchProvider matchProvider,
  ) {
    final recentMatches = matchProvider.newMatches.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Matches',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (recentMatches.isEmpty)
            _buildEmptyMatchesCard(brightness)
          else
            _buildMatchesList(recentMatches, brightness),
        ],
      ),
    );
  }

  Widget _buildEmptyMatchesCard(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                color: AppColors.crimson,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No matches yet',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start swiping to find your gig!',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(List<dynamic> recentMatches, Brightness brightness) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: recentMatches.length,
        itemBuilder: (context, index) {
          final match = recentMatches[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < recentMatches.length - 1 ? 12 : 0,
            ),
            child: _MatchPreviewCard(
              match: match,
              brightness: brightness,
              onTap: () => Navigator.pushNamed(context, '/chat/${match.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivitySection(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Activity',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LiquidGlassContainer(
            borderRadius: 20,
            blur: 12,
            tintColor: AppColors.crimson.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ActivityItem(
                    icon: Icons.visibility_rounded,
                    title: 'Profile Views',
                    value: '23 this week',
                    brightness: brightness,
                  ),
                  Divider(height: 24, color: AppColors.border(brightness)),
                  _ActivityItem(
                    icon: Icons.trending_up_rounded,
                    title: 'Match Rate',
                    value: '15% higher',
                    brightness: brightness,
                    isPositive: true,
                  ),
                  Divider(height: 24, color: AppColors.border(brightness)),
                  _ActivityItem(
                    icon: Icons.star_rounded,
                    title: 'Profile Score',
                    value: '85/100',
                    brightness: brightness,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Remove _getGreeting - now using getContextualGreeting() from widgets
}

// ═══════════════════════════════════════════════════════════════════════════
// SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Brightness brightness;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the value for animated counter
    final numericValue = int.tryParse(value) ?? 0;

    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      child: LiquidGlassContainer(
        borderRadius: 20,
        blur: 15,
        tintColor: iconColor.withValues(alpha: 0.05),
        showGlow: true,
        glowColor: iconColor.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              AnimatedCounter(
                value: numericValue,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final Brightness brightness;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchPreviewCard extends StatelessWidget {
  final dynamic match;
  final Brightness brightness;
  final VoidCallback onTap;

  const _MatchPreviewCard({
    required this.match,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.crimson,
                    AppColors.crimson.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface(brightness),
                ),
                child: ClipOval(
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.textSec(brightness),
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Match',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Brightness brightness;
  final bool isPositive;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.brightness,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.crimson, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isPositive ? Colors.green : AppColors.textSec(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isPositive) ...[
          const SizedBox(width: 4),
          const Icon(Icons.trending_up_rounded, color: Colors.green, size: 16),
        ],
      ],
    );
  }
}
