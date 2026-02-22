/// 💬 GIGMATCH Messages Screen - Material 3 Design
///
/// Unified messages hub with:
/// - New Matches (horizontal scroll)
/// - Conversations list (vertical)
/// - Quick filters (FilterChips)
/// - Search functionality
/// - Swipe actions
///
/// Clean, performant Material 3 design
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import 'chat_screen_v2.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📊 FILTER ENUM
// ═══════════════════════════════════════════════════════════════════════════

enum MessageFilter { all, unread, venues, artists }

// ═══════════════════════════════════════════════════════════════════════════
// 💬 MESSAGES SCREEN - Main Widget
// ═══════════════════════════════════════════════════════════════════════════

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();

  MessageFilter _activeFilter = MessageFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _onFocusChange() {
    setState(() {}); // Rebuild to update border color on focus change
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final matchProvider = context.read<MatchProvider>();
    await matchProvider.loadMatches(refresh: true);
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final isArtist = context.watch<AuthProvider>().isArtist;

    _ensureValidFilter(isArtist);

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.crimson,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar with Search
              _buildAppBar(theme, colorScheme, brightness),

              // Quick Filters
              SliverToBoxAdapter(
                child: _buildFilters(colorScheme, brightness, isArtist),
              ),

              // New Matches Section
              SliverToBoxAdapter(child: _buildNewMatchesSection(brightness)),

              // Conversations Header
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Conversations',
                  Icons.chat_bubble_rounded,
                  brightness,
                ),
              ),

              // Conversations List
              _buildConversationsList(brightness),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔝 APP BAR WITH BIG ROUNDED SEARCH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.background(brightness),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Big rounded search bar
          Expanded(
            child: GestureDetector(
              onTap: () {
                _searchFocusNode.requestFocus();
                HapticFeedback.lightImpact();
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _searchFocusNode.hasFocus
                        ? AppColors.crimson
                        : AppColors.border(brightness),
                    width: _searchFocusNode.hasFocus ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.textSec(brightness),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search messages...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTert(brightness),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          filled: false,
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.text(brightness),
                        ),
                        cursorColor: AppColors.crimson,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          context.read<MatchProvider>().setSearchQuery(value);
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          context.read<MatchProvider>().setSearchQuery('');
                          HapticFeedback.lightImpact();
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSec(brightness),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // More options button
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: IconButton(
              onPressed: () => _showOptionsMenu(brightness),
              icon: Icon(
                Icons.more_horiz_rounded,
                color: AppColors.text(brightness),
              ),
              tooltip: 'More options',
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏷️ QUICK FILTERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _ensureValidFilter(bool isArtist) {
    final invalidFilter = isArtist
        ? _activeFilter == MessageFilter.artists
        : _activeFilter == MessageFilter.venues;
    if (!invalidFilter) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _activeFilter = MessageFilter.all);
    });
  }

  Widget _buildFilters(
    ColorScheme colorScheme,
    Brightness brightness,
    bool isArtist,
  ) {
    // Get unread count for badge
    final unreadCount = context.watch<MatchProvider>().unreadCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(MessageFilter.all, 'All', brightness),
          const SizedBox(width: 8),
          _buildFilterChip(
            MessageFilter.unread,
            'Unread',
            brightness,
            badgeCount: unreadCount,
          ),
          const SizedBox(width: 8),
          if (isArtist) ...[
            _buildFilterChip(MessageFilter.venues, 'Venues', brightness),
          ] else ...[
            _buildFilterChip(MessageFilter.artists, 'Artists', brightness),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    MessageFilter filter,
    String label,
    Brightness brightness, {
    int badgeCount = 0,
  }) {
    final isSelected = _activeFilter == filter;

    // Material 3 FilterChip
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badgeCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.crimson,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
      onSelected: (selected) {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = filter);
      },
      selectedColor: AppColors.crimson,
      backgroundColor: AppColors.surface(brightness),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.text(brightness),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.crimson
              : AppColors.border(brightness),
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💕 NEW MATCHES SECTION (Horizontal Scroll)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNewMatchesSection(Brightness brightness) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        final newMatches = provider.newMatches;
        final auth = context.watch<AuthProvider>();
        final isArtist = auth.isArtist;

        if (newMatches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            _buildSectionHeader(
              'New Matches',
              Icons.favorite_rounded,
              brightness,
              count: newMatches.length,
            ),

            // Horizontal scroll of match avatars
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: newMatches.length,
                itemBuilder: (context, index) {
                  final match = newMatches[index];
                  return _NewMatchAvatar(
                    match: match,
                    isArtist: isArtist,
                    onTap: () => _openChat(match),
                    brightness: brightness,
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📝 SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Brightness brightness, {
    int? count,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.crimson),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.text(brightness),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Badge(
              label: Text('$count'),
              backgroundColor: AppColors.crimson.withValues(alpha: 0.15),
              textColor: AppColors.crimson,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💬 CONVERSATIONS LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConversationsList(Brightness brightness) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        // Show loading on first load
        if (provider.status == MatchListStatus.loading) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.crimson),
            ),
          );
        }

        final auth = context.watch<AuthProvider>();
        final isArtist = auth.isArtist;

        // Get conversations (matches with messages)
        List<Match> conversations = provider.conversationMatches;

        // Apply filters
        conversations = _applyFilters(conversations, isArtist);

        // Apply search
        if (_searchQuery.isNotEmpty) {
          conversations = conversations.where((m) {
            final otherName = (m.otherUserName ?? '').toLowerCase();
            final name = isArtist
                ? (m.venue?.name ?? '')
                : (m.artist?.stageName ?? '');
            final combined = '$otherName $name'.toLowerCase();
            return combined.contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (conversations.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(brightness),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final match = conversations[index];
            return _ConversationTile(
              match: match,
              isArtist: isArtist,
              onTap: () => _openChat(match),
              onArchive: () => _archiveConversation(match),
              onDelete: () => _deleteConversation(match),
              brightness: brightness,
            );
          }, childCount: conversations.length),
        );
      },
    );
  }

  List<Match> _applyFilters(List<Match> matches, bool isArtist) {
    switch (_activeFilter) {
      case MessageFilter.all:
        return matches;
      case MessageFilter.unread:
        return matches.where((m) => m.unreadCount > 0).toList();
      case MessageFilter.venues:
        // For artists, show venue conversations
        return isArtist ? matches : [];
      case MessageFilter.artists:
        // For venues, show artist conversations
        return !isArtist ? matches : [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📭 EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.crimson,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.text(brightness),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start matching to begin chatting!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSec(brightness),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed('/discovery');
            },
            icon: const Icon(Icons.explore_rounded),
            label: const Text('Discover'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.crimson,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎬 ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _openChat(Match match) {
    final auth = context.read<AuthProvider>();
    final isArtist = auth.isArtist;

    // Get correct participant info - use otherUser fields as primary (new backend format)
    // Fall back to artist/venue objects if otherUser not available
    final participantId = match.otherUserProfileId ?? 
        (isArtist ? match.venueId : match.artistId);
    final participantName = match.otherUserName ?? 
        (isArtist ? match.venue?.name : match.artist?.stageName);
    final participantPhoto = match.otherUserPhoto ?? 
        (isArtist ? match.venue?.profilePhotoUrl : match.artist?.profilePhoto);
    // Determine if participant is artist based on otherUserType or current user role
    final isParticipantArtist = match.otherUserType == 'artist' || !isArtist;

    HapticFeedback.lightImpact();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreenV2(
          matchId: match.id,
          participantId: participantId,
          participantName: participantName,
          participantPhoto: participantPhoto,
          isParticipantArtist: isParticipantArtist,
        ),
      ),
    );
  }

  void _archiveConversation(Match match) {
    HapticFeedback.mediumImpact();
    context.read<MatchProvider>().archiveMatch(match.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversation archived'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            context.read<MatchProvider>().unarchiveMatch(match.id);
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _deleteConversation(Match match) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text(
          'This will permanently delete all messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MatchProvider>().unmatch(match.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(Brightness brightness) {
    final matchProvider = context.read<MatchProvider>();
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffold = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Mark all as read
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: Colors.blue,
                ),
              ),
              title: const Text('Mark all as read'),
              subtitle: Text(
                'Clear all unread message badges',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();

                // Mark all conversations as read
                final matches = matchProvider.conversationMatches;
                for (final match in matches) {
                  if (match.unreadCount > 0) {
                    await matchProvider.markAsViewed(match.id);
                  }
                }
                await matchProvider.refreshUnreadCount();

                scaffold.showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('All messages marked as read'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),

            // Archived chats
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.archive_rounded, color: Colors.orange),
              ),
              title: const Text('Archived chats'),
              subtitle: Text(
                'View conversations you\'ve archived',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              trailing: Consumer<MatchProvider>(
                builder: (context, provider, _) {
                  final archivedCount = provider.archivedMatches.length;
                  if (archivedCount == 0) return const SizedBox.shrink();
                  return Badge(
                    label: Text('$archivedCount'),
                    backgroundColor: Colors.orange,
                  );
                },
              ),
              onTap: () {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                _showArchivedChats(brightness);
              },
            ),

            // Message settings
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune_rounded, color: AppColors.crimson),
              ),
              title: const Text('Message settings'),
              subtitle: Text(
                'Notifications, privacy, and more',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
                navigator.pushNamed('/settings');
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showArchivedChats(Brightness brightness) {
    final matchProvider = context.read<MatchProvider>();
    final archivedMatches = matchProvider.archivedMatches;
    final auth = context.read<AuthProvider>();
    final isArtist = auth.isArtist;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(brightness),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.archive_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    'Archived Chats',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.text(brightness),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: archivedMatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.archive_outlined,
                            size: 64,
                            color: AppColors.textTert(brightness),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No archived chats',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textSec(brightness),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Swipe left on a conversation to archive it',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTert(brightness),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: archivedMatches.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final match = archivedMatches[index];
                        final name = isArtist
                            ? (match.venue?.name ?? 'Venue')
                            : (match.artist?.stageName ?? 'Artist');
                        final photo = isArtist
                            ? match.venue?.profilePhotoUrl
                            : match.artist?.profilePhoto;

                        return Card.outlined(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: photo != null
                                  ? CachedNetworkImageProvider(photo)
                                  : null,
                              child: photo == null
                                  ? Icon(
                                      isArtist
                                          ? Icons.location_city
                                          : Icons.music_note,
                                      color: AppColors.textSec(brightness),
                                    )
                                  : null,
                            ),
                            title: Text(name),
                            subtitle: Text(
                              match.lastMessagePreview ?? 'No messages',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: FilledButton.tonal(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                matchProvider.unarchiveMatch(match.id);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name unarchived'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              child: const Text('Restore'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💕 NEW MATCH AVATAR (Horizontal Scroll Item)
// ═══════════════════════════════════════════════════════════════════════════

class _NewMatchAvatar extends StatelessWidget {
  final Match match;
  final bool isArtist;
  final VoidCallback onTap;
  final Brightness brightness;

  const _NewMatchAvatar({
    required this.match,
    required this.isArtist,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    // Use otherUser fields first (new backend format), fall back to old format
    final name = match.otherUserName ?? 
        (isArtist ? (match.venue?.name ?? 'Venue') : (match.artist?.stageName ?? 'Artist'));
    final photo = match.otherUserPhoto ?? 
        (isArtist ? match.venue?.profilePhotoUrl : match.artist?.profilePhoto);
    final isVenue = match.otherUserType == 'venue' || isArtist;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            // Avatar with gradient border
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.crimson,
                    AppColors.crimson.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background(brightness),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.surface(brightness),
                  backgroundImage: photo != null && photo.isNotEmpty
                      ? CachedNetworkImageProvider(photo)
                      : null,
                  child: photo == null || photo.isEmpty
                      ? Icon(
                          isVenue
                              ? Icons.location_city_rounded
                              : Icons.music_note_rounded,
                          color: AppColors.textSec(brightness),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Name
            SizedBox(
              width: 72,
              child: Text(
                name,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💬 CONVERSATION TILE (List Item with Swipe)
// ═══════════════════════════════════════════════════════════════════════════

class _ConversationTile extends StatelessWidget {
  final Match match;
  final bool isArtist;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final Brightness brightness;

  const _ConversationTile({
    required this.match,
    required this.isArtist,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    // Use otherUser fields first (new backend format), fall back to old format
    final name = match.otherUserName ?? 
        (isArtist ? (match.venue?.name ?? 'Venue') : (match.artist?.stageName ?? 'Artist'));
    final photo = match.otherUserPhoto ?? 
        (isArtist ? match.venue?.profilePhotoUrl : match.artist?.profilePhoto);
    final isVenue = match.otherUserType == 'venue' || isArtist;
    final rawLastMessage = match.lastMessagePreview ?? 'Start a conversation';
    // Sanitize stale URL previews on the client side
    final lastMessage = _formatMessagePreview(rawLastMessage);
    final unread = match.unreadCount;
    final time = match.lastMessageAt ?? match.matchedAt;

    debugPrint('💬 [ConversationTile] name=$name photo=${photo != null} '
        'lastMsg="$rawLastMessage" unread=$unread matchId=${match.id}');

    return Dismissible(
      key: Key('conversation_${match.id}'),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: Colors.orange,
        icon: Icons.archive_rounded,
        label: 'Archive',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete_rounded,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onArchive();
          return false;
        } else {
          onDelete();
          return false;
        }
      },
      child: Card.outlined(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: unread > 0
                ? AppColors.crimson.withValues(alpha: 0.3)
                : AppColors.border(brightness),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surface(brightness),
                  backgroundImage: photo != null && photo.isNotEmpty
                      ? CachedNetworkImageProvider(photo)
                      : null,
                  child: photo == null || photo.isEmpty
                      ? Icon(
                          isVenue
                              ? Icons.location_city_rounded
                              : Icons.music_note_rounded,
                          color: AppColors.textSec(brightness),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and time
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.text(brightness),
                                fontWeight: unread > 0
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(time),
                            style: AppTypography.labelSmall.copyWith(
                              color: unread > 0
                                  ? AppColors.crimson
                                  : AppColors.textSec(brightness),
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Last message and unread badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: AppTypography.bodySmall.copyWith(
                                color: unread > 0
                                    ? AppColors.text(brightness)
                                    : AppColors.textSec(brightness),
                                fontWeight: unread > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0)
                            Badge(
                              label: Text('$unread'),
                              backgroundColor: AppColors.crimson,
                              textColor: Colors.white,
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
    );
  }

  /// Sanitize stale URL previews — detect raw URLs and replace with friendly text
  String _formatMessagePreview(String preview) {
    if (preview.startsWith('http://') || preview.startsWith('https://')) {
      final lower = preview.toLowerCase();
      if (RegExp(r'\.(jpg|jpeg|png|gif|webp|heic|avif)').hasMatch(lower)) {
        return '📷 Photo';
      }
      if (RegExp(r'\.(mp3|wav|m4a|aac|ogg|opus)').hasMatch(lower)) {
        return '🎵 Audio message';
      }
      if (RegExp(r'\.(mp4|mov|avi|webm)').hasMatch(lower)) {
        return '🎬 Video';
      }
      return '📎 Attachment';
    }
    return preview;
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: Colors.white),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
