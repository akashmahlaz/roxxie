/// 💕 ULTRA-PREMIUM MATCHES SCREEN V2 - 2026 DESIGN
///
/// Features:
/// ✅ Animated particle background
/// ✅ Liquid Glass UI effects
/// ✅ 3D Match Cards with tilt
/// ✅ Premium Conversation Tiles
/// ✅ Animated Tab Switcher
/// ✅ Haptic Feedback
/// ✅ Dynamic Gradient Text
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import 'chat_screen_v2.dart';

class MatchesScreenV2 extends StatefulWidget {
  const MatchesScreenV2({super.key});

  @override
  State<MatchesScreenV2> createState() => _MatchesScreenV2State();
}

class _MatchesScreenV2State extends State<MatchesScreenV2>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _particleController;
  late AnimationController _floatController;
  late AnimationController _badgePulseController;
  // Reserved for badge pulse effect: late Animation<double> _badgePulseAnimation;

  final List<_MatchParticle> _particles = [];
  final math.Random _random = math.Random();

  // Search controller
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    // Reserved for future badge animation
    // _badgePulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
    //   CurvedAnimation(parent: _badgePulseController, curve: Curves.easeInOut),
    // );

    _initParticles();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MatchProvider>();
      provider.loadMatches(refresh: true);
      provider.loadWhoLikedMe();
    });

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<MatchProvider>().setSearchQuery(_searchController.text);
  }

  void _initParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(
        _MatchParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1,
          speed: _random.nextDouble() * 0.1 + 0.05,
          opacity: _random.nextDouble() * 0.4 + 0.1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    _badgePulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Layer 1: Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _MatchParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  color: isDark ? Colors.white : AppColors.crimson,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 2: Gradient Orbs
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return CustomPaint(
                painter: _MatchOrbPainter(
                  progress: _floatController.value,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 3: Main Content
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(brightness),
                SliverToBoxAdapter(child: const SizedBox(height: 10)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PremiumTabHeaderDelegate(
                    tabController: _tabController,
                    brightness: brightness,
                  ),
                ),
              ],
              body: Consumer<MatchProvider>(
                builder: (context, provider, child) {
                  // Loading state
                  if (provider.status == MatchListStatus.loading &&
                      provider.matches.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.crimson,
                      ),
                    );
                  }

                  // Error state with retry
                  if (provider.status == MatchListStatus.error) {
                    return _buildErrorState(provider, brightness);
                  }

                  // Empty state with CTA
                  if (provider.matches.isEmpty) {
                    return _buildEmptyState(brightness);
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNewMatchesGrid(provider, brightness),
                      _buildMessagesList(provider, brightness),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(Brightness brightness) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppColors.background(brightness).withValues(alpha: 0.7),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, color: AppColors.crimson),
          ),
          const SizedBox(width: 12),
          Text(
            'Matches',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
      actions: [
        // Search toggle
        IconButton(
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
              }
            });
          },
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: AppColors.text(brightness),
          ),
        ),
        // Filter button
        IconButton(
          onPressed: () => _showFilterSheet(brightness),
          icon: Icon(Icons.tune_rounded, color: AppColors.text(brightness)),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEW MATCHES TAB (GRID)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNewMatchesGrid(MatchProvider provider, Brightness brightness) {
    final matches = provider.filteredNewMatches;
    final whoLikedMe = provider.whoLikedMe;
    final whoLikedMeCount = provider.whoLikedMeCount;

    return RefreshIndicator(
      onRefresh: () => provider.refreshAll(),
      color: AppColors.crimson,
      child: CustomScrollView(
        slivers: [
          // Search bar (conditional)
          if (_showSearch)
            SliverToBoxAdapter(child: _buildSearchBar(brightness)),

          // Who Liked Me Section (Premium Teaser)
          if (whoLikedMeCount > 0 || provider.whoLikedMeLoading)
            SliverToBoxAdapter(
              child: _buildWhoLikedMeSection(
                whoLikedMe,
                whoLikedMeCount,
                provider.whoLikedMeLoading,
                provider.isPremiumFeature,
                brightness,
              ),
            ),

          // New Matches Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'New Matches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(brightness),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.crimson.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${matches.length}',
                      style: const TextStyle(
                        color: AppColors.crimson,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Matches Grid or Empty State
          if (matches.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildTabEmptyState(
                'No new matches',
                Icons.favorite_border,
                brightness,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _PremiumMatchCard(
                    match: matches[index],
                    onTap: () => _openChat(matches[index]),
                    brightness: brightness,
                    index: index,
                  );
                }, childCount: matches.length),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGES TAB (LIST)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMessagesList(MatchProvider provider, Brightness brightness) {
    final matches = provider.filteredConversationMatches;

    return RefreshIndicator(
      onRefresh: () => provider.refreshAll(),
      color: AppColors.crimson,
      child: CustomScrollView(
        slivers: [
          // Search bar (conditional)
          if (_showSearch)
            SliverToBoxAdapter(child: _buildSearchBar(brightness)),

          // Messages Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(brightness),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (provider.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${provider.unreadCount} new',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Messages List or Empty State
          if (matches.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildTabEmptyState(
                'No conversations started',
                Icons.chat_bubble_outline,
                brightness,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _PremiumMessageTile(
                  match: matches[index],
                  brightness: brightness,
                  onTap: () => _openChat(matches[index]),
                  index: index,
                );
              }, childCount: matches.length),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.crimson.withValues(alpha: 0.2),
                    AppColors.crimson.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 64,
                color: AppColors.crimson.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Matches Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text(brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start swiping to find your perfect gig!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // Navigate to discovery/swipe screen (tab 1)
                if (context.mounted) {
                  // Assuming bottom nav uses index 1 for Discover
                  DefaultTabController.of(context).animateTo(1);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.explore, color: Colors.white),
              label: const Text(
                'Start Discovering',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(MatchProvider provider, Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text(brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Failed to load matches',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSec(brightness)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => provider.loadMatches(refresh: true),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.crimson),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh, color: AppColors.crimson),
              label: const Text(
                'Try Again',
                style: TextStyle(color: AppColors.crimson),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppColors.text(brightness)),
        decoration: InputDecoration(
          hintText: 'Search matches...',
          hintStyle: TextStyle(color: AppColors.textTert(brightness)),
          prefixIcon: Icon(Icons.search, color: AppColors.textTert(brightness)),
          filled: true,
          fillColor: AppColors.surface(brightness),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildWhoLikedMeSection(
    List<DiscoveryCard> profiles,
    int count,
    bool isLoading,
    bool isPremium,
    Brightness brightness,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.2),
            AppColors.crimson.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Who Liked You',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.text(brightness),
                      ),
                    ),
                    if (count > 0)
                      Text(
                        '$count people want to match!',
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gold, AppColors.crimson],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: SizedBox(
                height: 60,
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (profiles.isEmpty && count > 0)
            // Blurred preview for non-premium
            _buildBlurredPreview(count, brightness)
          else if (profiles.isNotEmpty)
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: math.min(profiles.length, 5),
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to profile or swipe screen
                        HapticFeedback.lightImpact();
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: profile.primaryPhotoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(profile.primaryPhotoUrl)
                                : null,
                            backgroundColor: AppColors.surface(brightness),
                            child: profile.primaryPhotoUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    color: AppColors.textTert(brightness),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.name.split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSec(brightness),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlurredPreview(int count, Brightness brightness) {
    return Stack(
      children: [
        SizedBox(
          height: 70,
          child: Row(
            children: List.generate(math.min(count, 4), (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.crimson.withValues(alpha: 0.5),
                    child: const Icon(Icons.person, color: Colors.white38),
                  ),
                ),
              );
            }),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: FilledButton(
              onPressed: () {
                // Navigate to premium upgrade
                HapticFeedback.lightImpact();
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed('/subscription');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Unlock with Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(Brightness brightness) {
    HapticFeedback.lightImpact();
    final provider = context.read<MatchProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(brightness),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Filter Matches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text(brightness),
              ),
            ),
            const SizedBox(height: 20),
            _FilterOption(
              title: 'All Matches',
              icon: Icons.people,
              isSelected: provider.filterType == MatchFilterType.all,
              onTap: () {
                provider.setFilterType(MatchFilterType.all);
                Navigator.pop(context);
              },
              brightness: brightness,
            ),
            _FilterOption(
              title: 'Unread',
              icon: Icons.mark_email_unread,
              isSelected: provider.filterType == MatchFilterType.unread,
              onTap: () {
                provider.setFilterType(MatchFilterType.unread);
                Navigator.pop(context);
              },
              brightness: brightness,
            ),
            _FilterOption(
              title: 'Archived',
              icon: Icons.archive,
              isSelected: provider.filterType == MatchFilterType.archived,
              onTap: () {
                provider.setFilterType(MatchFilterType.archived);
                Navigator.pop(context);
              },
              brightness: brightness,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTabEmptyState(String msg, IconData icon, Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness).withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border(brightness).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, size: 40, color: AppColors.textTert(brightness)),
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(Match match) {
    HapticFeedback.lightImpact();

    // Determine the other party's info
    final currentUserIsArtist = context.read<AuthProvider>().user?.role == UserRole.artist;
    final participantName = match.getOtherPartyName(currentUserIsArtist);
    final participantPhoto = match.getOtherPartyPhoto(currentUserIsArtist);

    // Use constructor-based navigation (consistent with messages_screen.dart)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreenV2(
          matchId: match.id,
          participantName: participantName,
          participantPhoto: participantPhoto,
          isParticipantArtist: !currentUserIsArtist,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTER OPTION WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _FilterOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Brightness brightness;

  const _FilterOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.crimson.withValues(alpha: 0.1)
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.crimson : AppColors.textSec(brightness),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.crimson : AppColors.text(brightness),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.crimson)
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UI COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _PremiumMatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final Brightness brightness;
  final int index;

  const _PremiumMatchCard({
    required this.match,
    required this.onTap,
    required this.brightness,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isArtist = auth.isArtist;
    final name = match.getOtherPartyName(isArtist);
    final photo = match.getOtherPartyPhoto(isArtist);

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 600 + (index * 100)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: photo,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) =>
                      Container(color: AppColors.surface(brightness)),
                ),

                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),

                // Content
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.crimson,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumMessageTile extends StatelessWidget {
  final Match match;
  final Brightness brightness;
  final VoidCallback onTap;
  final int index;

  const _PremiumMessageTile({
    required this.match,
    required this.brightness,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isArtist = auth.isArtist;
    final name = match.getOtherPartyName(isArtist);
    final photo = match.getOtherPartyPhoto(isArtist);
    final lastMsg = 'Start chatting!';
    final unread = match.unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: unread
                    ? AppColors.crimson.withValues(alpha: 0.05)
                    : AppColors.surface(brightness).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border(brightness).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surface(brightness),
                    backgroundImage: photo.isNotEmpty
                        ? CachedNetworkImageProvider(photo)
                        : null,
                    child: photo.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            color: AppColors.textTert(brightness),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread
                                ? AppColors.text(brightness)
                                : AppColors.textSec(brightness),
                            fontWeight: unread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.crimson,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Brightness brightness;

  _PremiumTabHeaderDelegate({
    required this.tabController,
    required this.brightness,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: AppColors.background(brightness).withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Theme(
            data: Theme.of(context).copyWith(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: tabController,
                indicator: BoxDecoration(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSec(brightness),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'New Matches'),
                  Tab(text: 'Messages'),
                ],
                dividerColor: Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 70;
  @override
  double get minExtent => 70;
  @override
  bool shouldRebuild(covariant _PremiumTabHeaderDelegate oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTERS (Simplified from MessagesListScreenV2)
// ═══════════════════════════════════════════════════════════════════════════

class _MatchParticle {
  double x, y, size, speed, opacity;
  _MatchParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _MatchParticlePainter extends CustomPainter {
  final List<_MatchParticle> particles;
  final double progress;
  final Color color;

  _MatchParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - progress * p.speed) % 1.0;
      final x = p.x + math.sin(progress * 2 * math.pi + p.x * 10) * 0.02;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        Paint()
          ..color = color.withValues(alpha: p.opacity * 0.2)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _MatchOrbPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _MatchOrbPainter({required this.progress, required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.purple.withValues(alpha: isDark ? 0.1 : 0.05),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.8, size.height * 0.2),
              radius: 200,
            ),
          );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
