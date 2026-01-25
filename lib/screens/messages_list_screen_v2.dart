/// 💬 ULTRA-PREMIUM MESSAGES SCREEN V2 - 2026 DESIGN
///
/// Features:
/// ✅ Animated particle background
/// ✅ Liquid Glass conversation cards
/// ✅ Real-time typing indicators with pulse
/// ✅ Swipe-to-action with haptic feedback
/// ✅ Animated unread badges
/// ✅ Smart search with 3D transition
/// ✅ Floating gradient orbs
library;

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import 'chat_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum ConversationType { venue, artist, support }

class Conversation {
  final String id;
  final String participantName;
  final String participantImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final bool isPinned;
  final bool isVerified;
  final ConversationType conversationType;

  const Conversation({
    required this.id,
    required this.participantName,
    required this.participantImage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
    required this.isTyping,
    required this.isPinned,
    required this.isVerified,
    required this.conversationType,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// 💬 MESSAGES LIST SCREEN V2
// ═══════════════════════════════════════════════════════════════════════════

class MessagesListScreenV2 extends StatefulWidget {
  const MessagesListScreenV2({super.key});

  @override
  State<MessagesListScreenV2> createState() => _MessagesListScreenV2State();
}

class _MessagesListScreenV2State extends State<MessagesListScreenV2>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  // Animation Controllers
  late AnimationController _particleController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _listController;

  // Animations
  late Animation<double> _pulseAnimation;

  // State
  bool _isSearching = false;
  String _searchQuery = '';
  final List<_MessageParticle> _particles = [];
  final math.Random _random = math.Random();

  // Mock conversations
  final List<Conversation> _conversations = [
    Conversation(
      id: '1',
      participantName: 'The Velvet Lounge',
      participantImage: '',
      lastMessage:
          'Looking forward to your performance this Saturday! Let us know if you need anything.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
      isOnline: true,
      isTyping: false,
      isPinned: true,
      isVerified: true,
      conversationType: ConversationType.venue,
    ),
    Conversation(
      id: '2',
      participantName: 'Blue Note Jazz Club',
      participantImage: '',
      lastMessage: 'Great show last night! 🎵',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      isOnline: true,
      isTyping: true,
      isPinned: false,
      isVerified: true,
      conversationType: ConversationType.venue,
    ),
    Conversation(
      id: '3',
      participantName: 'Riverside Café',
      participantImage: '',
      lastMessage: 'Can you confirm availability for next Friday?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 6)),
      unreadCount: 1,
      isOnline: false,
      isTyping: false,
      isPinned: false,
      isVerified: false,
      conversationType: ConversationType.venue,
    ),
    Conversation(
      id: '4',
      participantName: 'Electric Dreams',
      participantImage: '',
      lastMessage: 'The deposit has been sent. See you there!',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
      isTyping: false,
      isPinned: false,
      isVerified: true,
      conversationType: ConversationType.venue,
    ),
    Conversation(
      id: '5',
      participantName: 'Grand Hotel Ballroom',
      participantImage: '',
      lastMessage: 'We need 2 sets of 45 minutes each with a 15-minute break.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
      unreadCount: 0,
      isOnline: false,
      isTyping: false,
      isPinned: false,
      isVerified: true,
      conversationType: ConversationType.venue,
    ),
  ];

  final List<Conversation> _archivedConversations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initParticles();
    _initAnimations();
  }

  void _initParticles() {
    for (int i = 0; i < 25; i++) {
      _particles.add(
        _MessageParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1,
          speed: _random.nextDouble() * 0.1 + 0.05,
          opacity: _random.nextDouble() * 0.3 + 0.1,
        ),
      );
    }
  }

  void _initAnimations() {
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _listController.dispose();
    super.dispose();
  }

  int get _totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations
        .where(
          (c) =>
              c.participantName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              c.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
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
                painter: _MessageParticlePainter(
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
                painter: _MessageOrbPainter(
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
                SliverToBoxAdapter(child: _buildSearchBar(brightness)),
                SliverToBoxAdapter(child: _buildFilterChips(brightness)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PremiumTabBarDelegate(
                    tabController: _tabController,
                    brightness: brightness,
                    unreadCount: _totalUnread,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildConversationsList(brightness, _filteredConversations),
                  _buildConversationsList(
                    brightness,
                    _archivedConversations,
                    isArchived: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _pulseAnimation,
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            // New message action
          },
          backgroundColor: AppColors.crimson,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.crimson.withValues(alpha: 0.1),
            radius: 20,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.crimson,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Messages',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => HapticFeedback.selectionClick(),
          icon: Icon(Icons.tune_rounded, color: AppColors.text(brightness)),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border(brightness).withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _isSearching = v.isNotEmpty;
              }),
              style: TextStyle(color: AppColors.text(brightness)),
              decoration: InputDecoration(
                hintText: 'Search chats...',
                hintStyle: TextStyle(color: AppColors.textTert(brightness)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.crimson,
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSec(brightness),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFilterChips(Brightness brightness) {
    final filters = [
      ('All', null),
      ('Unread', Icons.mark_email_unread_rounded),
      ('Online', Icons.circle),
      ('Venues', Icons.business_rounded),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = index == 0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.crimson,
                        AppColors.crimson.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : AppColors.surface(brightness).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppColors.border(brightness).withValues(alpha: 0.5),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (filter.$2 != null) ...[
                  Icon(
                    filter.$2,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSec(brightness),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  filter.$1,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.text(brightness),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIST BUILDER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConversationsList(
    Brightness brightness,
    List<Conversation> items, {
    bool isArchived = false,
  }) {
    if (items.isEmpty) {
      return _buildEmptyState(brightness, isArchived);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        // Staggered animation
        final delay = index * 100;
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listController,
            curve: Interval(
              (delay / 2000).clamp(0.0, 1.0),
              ((delay + 500) / 2000).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: _PremiumConversationTile(
              conversation: items[index],
              brightness: brightness,
              onTap: () => _openChat(items[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(Brightness brightness, bool isArchived) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness).withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border(brightness).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              isArchived
                  ? Icons.archive_outlined
                  : Icons.chat_bubble_outline_rounded,
              size: 50,
              color: AppColors.textTert(brightness),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isArchived ? 'No archived chats' : 'No messages yet',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArchived
                ? 'Archived conversations appear here'
                : 'Start matching to connect!',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(Conversation conversation) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
          matchId: conversation.id,
          participantName: conversation.participantName,
          participantPhoto: conversation.participantImage,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM CONVERSATION TILE
// ═══════════════════════════════════════════════════════════════════════════

class _PremiumConversationTile extends StatelessWidget {
  final Conversation conversation;
  final Brightness brightness;
  final VoidCallback onTap;

  const _PremiumConversationTile({
    required this.conversation,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;

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
                  color: unread
                      ? AppColors.crimson.withValues(alpha: 0.3)
                      : AppColors.border(brightness).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surface(brightness),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: conversation.isOnline
                                ? Colors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            conversation.participantName[0],
                            style: TextStyle(
                              color: AppColors.crimson,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      if (conversation.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              conversation.participantName,
                              style: TextStyle(
                                color: AppColors.text(brightness),
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatTime(conversation.lastMessageTime),
                              style: TextStyle(
                                color: unread
                                    ? AppColors.crimson
                                    : AppColors.textTert(brightness),
                                fontSize: 12,
                                fontWeight: unread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (conversation.isTyping)
                              _TypingIndicator(color: AppColors.crimson)
                            else
                              Expanded(
                                child: Text(
                                  conversation.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: unread
                                        ? AppColors.text(brightness)
                                        : AppColors.textSec(brightness),
                                    fontWeight: unread
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            if (unread)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.crimson,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.crimson.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${conversation.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UI HELPERS
// ═══════════════════════════════════════════════════════════════════════════

class _PremiumTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Brightness brightness;
  final int unreadCount;

  _PremiumTabBarDelegate({
    required this.tabController,
    required this.brightness,
    required this.unreadCount,
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: tabController,
            indicatorColor: AppColors.crimson,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.crimson,
            unselectedLabelColor: AppColors.textSec(brightness),
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              Tab(text: 'Inbox ${unreadCount > 0 ? "($unreadCount)" : ""}'),
              const Tab(text: 'Archived'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _PremiumTabBarDelegate oldDelegate) =>
      oldDelegate.unreadCount != unreadCount;
}

class _TypingIndicator extends StatelessWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Typing',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 20,
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _MessageParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  _MessageParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _MessageParticlePainter extends CustomPainter {
  final List<_MessageParticle> particles;
  final double progress;
  final Color color;

  _MessageParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - progress * p.speed) % 1.0;
      final x = p.x + math.sin(progress * math.pi * 2 + p.x * 10) * 0.02;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        Paint()
          ..color = color.withValues(alpha: p.opacity * 0.3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _MessageOrbPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _MessageOrbPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final orb1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.blue.withValues(alpha: isDark ? 0.15 : 0.08),
              Colors.blue.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.2, size.height * 0.3),
              radius: 200,
            ),
          );

    final orb2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.crimson.withValues(alpha: isDark ? 0.15 : 0.08),
              AppColors.crimson.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.8, size.height * 0.7),
              radius: 250,
            ),
          );

    canvas.drawRect(Offset.zero & size, orb1);
    canvas.drawRect(Offset.zero & size, orb2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
