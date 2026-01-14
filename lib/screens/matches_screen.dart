/// 💕 GIGMATCH Matches Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass card effects
/// - Micro-interactions on all cards
/// - Shimmer loading states
/// - Premium match indicators
///
/// Shows all matched artists/venues with dynamic theming
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../widgets/widgets.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load matches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().loadMatches(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.background(brightness),
        elevation: 0,
        title: Text(
          'Matches',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.text(brightness),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.crimson,
          labelColor: AppColors.crimson,
          unselectedLabelColor: AppColors.textSec(brightness),
          tabs: const [
            Tab(text: 'New Matches'),
            Tab(text: 'Messages'),
          ],
        ),
      ),
      body: Consumer<MatchProvider>(
        builder: (context, provider, child) {
          if (provider.status == MatchListStatus.loading &&
              provider.matches.isEmpty) {
            // 2026: Premium skeleton loading
            return const MatchGridSkeletonScreen();
          }

          if (provider.matches.isEmpty) {
            return _buildEmptyState(brightness);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNewMatchesTab(provider, brightness),
              _buildMessagesTab(provider, brightness),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewMatchesTab(MatchProvider provider, Brightness brightness) {
    final newMatches = provider.newMatches;

    if (newMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 60,
              color: AppColors.textTert(brightness),
            ),
            const SizedBox(height: 16),
            Text(
              'No new matches yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSec(brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep swiping to find your gig!',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSec(brightness),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadMatches(refresh: true),
      color: AppColors.crimson,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: newMatches.length,
        itemBuilder: (context, index) {
          return _MatchCard(
            match: newMatches[index],
            onTap: () => _openChat(newMatches[index]),
            brightness: brightness,
          );
        },
      ),
    );
  }

  Widget _buildMessagesTab(MatchProvider provider, Brightness brightness) {
    final conversations = provider.conversationMatches;

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppColors.textTert(brightness),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSec(brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting with your matches!',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSec(brightness),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadMatches(refresh: true),
      color: AppColors.crimson,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          return _ConversationTile(
            match: conversations[index],
            onTap: () => _openChat(conversations[index]),
            brightness: brightness,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.textTert(brightness),
          ),
          const SizedBox(height: 20),
          Text(
            'No matches yet',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.text(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start swiping to find gigs!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSec(brightness),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Start Discovering',
            onPressed: () {
              // Navigate to discovery tab
              // This would typically be handled by bottom nav
            },
            width: 200,
          ),
        ],
      ),
    );
  }

  void _openChat(Match match) {
    Navigator.pushNamed(context, '/chat', arguments: match.id);
  }
}

/// Match Card Widget (for grid view)
class _MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final Brightness brightness;

  const _MatchCard({
    required this.match, 
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isArtist = authProvider.isArtist;
    final name = match.getOtherPartyName(isArtist);
    final photo = match.getOtherPartyPhoto(isArtist);

    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              if (photo.isNotEmpty)
                Image.network(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => Container(
                    color: AppColors.surface(brightness),
                    child: Icon(
                      Icons.person_rounded,
                      size: 44,
                      color: AppColors.textSec(brightness),
                    ),
                  ),
                )
              else
                Container(
                  color: AppColors.surface(brightness),
                  child: Icon(
                    Icons.person_rounded,
                    size: 44,
                    color: AppColors.textSec(brightness),
                  ),
                ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              // Name & details
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 12,
                          color: AppColors.crimson,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Matched',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // New badge with animation
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.crimson, Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conversation Tile Widget (for list view)
class _ConversationTile extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final Brightness brightness;

  const _ConversationTile({
    required this.match, 
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isArtist = authProvider.isArtist;
    final name = match.getOtherPartyName(isArtist);
    final photo = match.getOtherPartyPhoto(isArtist);

    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: match.unreadCount > 0
              ? AppColors.crimson.withValues(alpha: 0.05)
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: match.unreadCount > 0
                ? AppColors.crimson.withValues(alpha: 0.2)
                : AppColors.border(brightness),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: match.unreadCount > 0
                        ? const LinearGradient(
                            colors: [AppColors.crimson, Color(0xFFFF6B6B)],
                          )
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.surface(brightness),
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty
                        ? Icon(Icons.person_rounded, color: AppColors.textSec(brightness))
                        : null,
                  ),
                ),
                if (match.unreadCount > 0)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.crimson, Color(0xFFFF6B6B)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface(brightness),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          match.unreadCount > 9 ? '9+' : '${match.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 15,
                            fontWeight: match.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (match.lastMessageAt != null)
                        Text(
                          _formatTime(match.lastMessageAt!),
                          style: TextStyle(
                            color: match.unreadCount > 0
                                ? AppColors.crimson
                                : AppColors.textSec(brightness),
                            fontSize: 12,
                            fontWeight: match.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    match.lastMessagePreview ?? 'Start the conversation!',
                    style: TextStyle(
                      color: match.unreadCount > 0
                          ? AppColors.text(brightness)
                          : AppColors.textSec(brightness),
                      fontSize: 13,
                      fontWeight: match.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTert(brightness),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }
}
