/// 💕 GIGMATCH Matches Screen
/// Shows all matched artists/venues

import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(
        backgroundColor: AppColors.obsidian,
        elevation: 0,
        title: Text(
          'Matches',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.offWhite,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.crimson,
          labelColor: AppColors.crimson,
          unselectedLabelColor: AppColors.mediumGray,
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.crimson),
            );
          }

          if (provider.matches.isEmpty) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNewMatchesTab(provider),
              _buildMessagesTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewMatchesTab(MatchProvider provider) {
    final newMatches = provider.newMatches;

    if (newMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 60,
              color: AppColors.mediumGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No new matches yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep swiping to find your gig!',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.mediumGray,
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
          );
        },
      ),
    );
  }

  Widget _buildMessagesTab(MatchProvider provider) {
    final conversations = provider.conversationMatches;

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppColors.mediumGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting with your matches!',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.mediumGray,
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
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.mediumGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No matches yet',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.offWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start swiping to find gigs!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.mediumGray,
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

  const _MatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isArtist = authProvider.isArtist;
    final name = match.getOtherPartyName(isArtist);
    final photo = match.getOtherPartyPhoto(isArtist);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              if (photo.isNotEmpty)
                Image.network(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.charcoal,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.mediumGray,
                    ),
                  ),
                )
              else
                Container(
                  color: AppColors.charcoal,
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.mediumGray,
                  ),
                ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // Name
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // New badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
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

  const _ConversationTile({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isArtist = authProvider.isArtist;
    final name = match.getOtherPartyName(isArtist);
    final photo = match.getOtherPartyPhoto(isArtist);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.charcoal,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? const Icon(Icons.person, color: AppColors.mediumGray)
                : null,
          ),
          if (match.unreadCount > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.crimson,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    match.unreadCount > 9 ? '9+' : '${match.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          color: AppColors.offWhite,
          fontWeight: match.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        match.lastMessagePreview ?? 'Start the conversation!',
        style: TextStyle(
          color: match.unreadCount > 0
              ? AppColors.offWhite
              : AppColors.mediumGray,
          fontWeight: match.unreadCount > 0
              ? FontWeight.w500
              : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (match.lastMessageAt != null)
            Text(
              _formatTime(match.lastMessageAt!),
              style: TextStyle(
                color: match.unreadCount > 0
                    ? AppColors.crimson
                    : AppColors.mediumGray,
                fontSize: 12,
              ),
            ),
        ],
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
