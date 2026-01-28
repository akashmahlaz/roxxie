/// 💬 GIGMATCH Messages List Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass conversation cards
/// - Real-time typing indicators
/// - Swipe-to-action (archive/delete)
/// - Animated unread badges
/// - Smart search with filters
/// - Online status indicators
///
/// All conversations in one place
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 💬 MESSAGES LIST SCREEN - Main Widget
// ═══════════════════════════════════════════════════════════════════════════

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';

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
    Conversation(
      id: '6',
      participantName: 'Sunset Rooftop Bar',
      participantImage: '',
      lastMessage: 'Thanks for the amazing acoustic set!',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 5)),
      unreadCount: 0,
      isOnline: false,
      isTyping: false,
      isPinned: false,
      isVerified: false,
      conversationType: ConversationType.venue,
    ),
  ];

  final List<Conversation> _archivedConversations = [
    Conversation(
      id: '7',
      participantName: 'Jazz Corner',
      participantImage: '',
      lastMessage: 'Thanks for your interest but we found someone else.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 30)),
      unreadCount: 0,
      isOnline: false,
      isTyping: false,
      isPinned: false,
      isVerified: false,
      conversationType: ConversationType.venue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

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

  int get _totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // App Bar
          _buildAppBar(brightness),

          // Search Bar
          SliverToBoxAdapter(child: _buildSearchBar(brightness)),

          // Filter Chips
          SliverToBoxAdapter(child: _buildFilterChips(brightness)),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabController,
              brightness: brightness,
              unreadCount: _totalUnread,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildConversationsList(brightness, _filteredConversations, false),
            _buildConversationsList(brightness, _archivedConversations, true),
          ],
        ),
      ),
      floatingActionButton: AnimatedTapFeedback(
        onTap: () {
          HapticFeedback.mediumImpact();
          _showNewMessageSheet(brightness);
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.crimson, Color(0xFFFF6B6B)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(Brightness brightness) {
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      leading: AnimatedTapFeedback(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.text(brightness),
          ),
        ),
      ),
      title: Text(
        'Messages',
        style: AppTypography.headlineSmall.copyWith(
          color: AppColors.text(brightness),
        ),
      ),
      actions: [
        if (_totalUnread > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.crimson,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_totalUnread unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        AnimatedTapFeedback(
          onTap: () {
            HapticFeedback.selectionClick();
            _showSettingsSheet(brightness);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: AppColors.text(brightness),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔍 SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.textSec(brightness),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _isSearching = value.isNotEmpty;
                  });
                },
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(color: AppColors.textTert(brightness)),
                ),
              ),
            ),
            if (_isSearching)
              AnimatedTapFeedback(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _isSearching = false;
                  });
                },
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textSec(brightness),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏷️ FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFilterChips(Brightness brightness) {
    final filters = [
      ('All', null),
      ('Unread', Icons.mark_email_unread_rounded),
      ('Online', Icons.circle),
      ('Venues', Icons.business_rounded),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = index == 0;

          return AnimatedTapFeedback(
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.crimson.withValues(alpha: 0.1)
                    : AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.border(brightness),
                ),
              ),
              child: Row(
                children: [
                  if (filter.$2 != null) ...[
                    Icon(
                      filter.$2,
                      size: 14,
                      color: isSelected
                          ? AppColors.crimson
                          : AppColors.textSec(brightness),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    filter.$1,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.crimson
                          : AppColors.text(brightness),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💬 CONVERSATIONS LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConversationsList(
    Brightness brightness,
    List<Conversation> conversations,
    bool isArchived,
  ) {
    if (_isLoading) {
      return const _ConversationSkeletonList();
    }

    if (conversations.isEmpty) {
      return _buildEmptyState(brightness, isArchived);
    }

    // Sort by pinned first, then by time
    final sorted = List<Conversation>.from(conversations);
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.lastMessageTime.compareTo(a.lastMessageTime);
    });

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.crimson,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final conversation = sorted[index];
          return _ConversationTile(
            conversation: conversation,
            brightness: brightness,
            onTap: () => _openChat(conversation),
            onArchive: () => _archiveConversation(conversation),
            onDelete: () => _deleteConversation(conversation, brightness),
            isArchived: isArchived,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness, bool isArchived) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Icon(
              isArchived
                  ? Icons.archive_rounded
                  : Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.textTert(brightness),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isArchived ? 'No archived messages' : 'No messages yet',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArchived
                ? 'Archived conversations will appear here'
                : 'Start matching to begin conversations',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎬 ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _openChat(Conversation conversation) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matchId: conversation.id,
          participantName: conversation.participantName,
          participantPhoto: conversation.participantImage,
        ),
      ),
    );
  }

  void _archiveConversation(Conversation conversation) {
    HapticFeedback.mediumImpact();
    setState(() {
      _conversations.remove(conversation);
      _archivedConversations.add(conversation);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Conversation archived'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _archivedConversations.remove(conversation);
              _conversations.add(conversation);
            });
          },
        ),
      ),
    );
  }

  void _deleteConversation(Conversation conversation, Brightness brightness) {
    HapticFeedback.mediumImpact();
    AppDialog.destructive(
      context,
      title: 'Delete conversation?',
      content:
          'This will permanently delete all messages with ${conversation.participantName}.',
      confirmText: 'Delete',
      onConfirm: () {
        setState(() {
          _conversations.remove(conversation);
          _archivedConversations.remove(conversation);
        });
      },
    );
  }

  void _showNewMessageSheet(Brightness brightness) {
    AppBottomSheet.show(
      context,
      child: _NewMessageSheet(brightness: brightness),
    );
  }

  void _showSettingsSheet(Brightness brightness) {
    AppBottomSheet.show(
      context,
      isScrollControlled: false,
      child: _MessageSettingsSheet(brightness: brightness),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Brightness brightness;
  final int unreadCount;

  _TabBarDelegate({
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
    return Container(
      color: AppColors.background(brightness),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.crimson,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.crimson,
        unselectedLabelColor: AppColors.textSec(brightness),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Inbox'),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.crimson,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: 'Archived'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

// ═══════════════════════════════════════════════════════════════════════════
// 💬 CONVERSATION TILE
// ═══════════════════════════════════════════════════════════════════════════

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final Brightness brightness;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final bool isArchived;

  const _ConversationTile({
    required this.conversation,
    required this.brightness,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
    required this.isArchived,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      background: _buildSwipeBackground(
        Colors.orange,
        Icons.archive_rounded,
        Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        AppColors.error,
        Icons.delete_rounded,
        Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          onArchive();
          return false;
        } else {
          onDelete();
          return false;
        }
      },
      child: AnimatedTapFeedback(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: conversation.unreadCount > 0
                ? AppColors.crimson.withValues(alpha: 0.05)
                : AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: conversation.unreadCount > 0
                  ? AppColors.crimson.withValues(alpha: 0.2)
                  : AppColors.border(brightness),
            ),
          ),
          child: Row(
            children: [
              // Avatar with online status
              Stack(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.crimson,
                          AppColors.crimson.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        conversation.participantName.isNotEmpty
                            ? conversation.participantName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
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
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface(brightness),
                            width: 3,
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
                        if (conversation.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: AppColors.crimson,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            conversation.participantName,
                            style: TextStyle(
                              color: AppColors.text(brightness),
                              fontSize: 15,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.info,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (conversation.isTyping) ...[
                          _TypingIndicator(brightness: brightness),
                        ] else ...[
                          Expanded(
                            child: Text(
                              conversation.lastMessage,
                              style: TextStyle(
                                color: conversation.unreadCount > 0
                                    ? AppColors.text(brightness)
                                    : AppColors.textSec(brightness),
                                fontSize: 13,
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Time and badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(conversation.lastMessageTime),
                    style: TextStyle(
                      color: conversation.unreadCount > 0
                          ? AppColors.crimson
                          : AppColors.textTert(brightness),
                      fontSize: 12,
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (conversation.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(
    Color color,
    IconData icon,
    Alignment alignment,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: Colors.white),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${time.day}/${time.month}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ⏳ TYPING INDICATOR
// ═══════════════════════════════════════════════════════════════════════════

class _TypingIndicator extends StatefulWidget {
  final Brightness brightness;

  const _TypingIndicator({required this.brightness});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'typing',
          style: TextStyle(
            color: AppColors.crimson,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = (_controller.value * 3 - i).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(
                    alpha: 0.3 + offset * 0.7,
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💀 SKELETON LIST
// ═══════════════════════════════════════════════════════════════════════════

class _ConversationSkeletonList extends StatelessWidget {
  const _ConversationSkeletonList();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ShimmerBase(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.skeleton(brightness),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBase(
                      child: Container(
                        height: 14,
                        width: 140,
                        decoration: BoxDecoration(
                          color: AppColors.skeleton(brightness),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShimmerBase(
                      child: Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: AppColors.skeleton(brightness),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ✉️ NEW MESSAGE SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _NewMessageSheet extends StatelessWidget {
  final Brightness brightness;

  const _NewMessageSheet({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Message',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation with a matched venue or artist',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background(brightness),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(brightness)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.textSec(brightness),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: AppColors.text(brightness)),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search matches...',
                            hintStyle: TextStyle(
                              color: AppColors.textTert(brightness),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recent Matches',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'No recent matches to message',
                    style: TextStyle(
                      color: AppColors.textTert(brightness),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ⚙️ MESSAGE SETTINGS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _MessageSettingsSheet extends StatelessWidget {
  final Brightness brightness;

  const _MessageSettingsSheet({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message Settings',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                _SettingsTile(
                  icon: Icons.mark_email_read_rounded,
                  title: 'Mark all as read',
                  brightness: brightness,
                  onTap: () => Navigator.pop(context),
                ),
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  title: 'Notification settings',
                  brightness: brightness,
                  onTap: () => Navigator.pop(context),
                ),
                _SettingsTile(
                  icon: Icons.block_rounded,
                  title: 'Blocked users',
                  brightness: brightness,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Brightness brightness;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.text(brightness)),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSec(brightness),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📦 DATA MODELS
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
