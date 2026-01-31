/// 📱 GIGMATCH Feed Home Screen
///
/// Instagram-style feed with stories and posts
/// Clean, professional UI with no borders, rounded elements
/// 2026 Design: Minimal header, stories row, vertical feed
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final feedProvider = context.read<FeedProvider>();
      if (!feedProvider.isLoading && feedProvider.hasMorePosts) {
        feedProvider.loadPosts();
      }
    }
  }

  Future<void> _loadFeed() async {
    await context.read<FeedProvider>().loadFeed(refresh: true);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final feedProvider = context.watch<FeedProvider>();

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.crimson,
        backgroundColor: AppColors.surface(brightness),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Minimal Header
            _buildHeader(brightness),

            // Stories Row
            SliverToBoxAdapter(
              child: _StoriesSection(
                stories: feedProvider.stories,
                status: feedProvider.storiesStatus,
              ),
            ),

            // Divider
            SliverToBoxAdapter(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.border(brightness),
              ),
            ),

            // Posts Feed
            if (feedProvider.postsStatus == FeedStatus.loading &&
                feedProvider.posts.isEmpty)
              const SliverToBoxAdapter(child: _PostsLoadingShimmer())
            else if (feedProvider.posts.isEmpty)
              SliverToBoxAdapter(child: _EmptyFeedState(brightness: brightness))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= feedProvider.posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.crimson,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    return _PostCard(
                      post: feedProvider.posts[index],
                      brightness: brightness,
                    );
                  },
                  childCount:
                      feedProvider.posts.length +
                      (feedProvider.hasMorePosts ? 1 : 0),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Brightness brightness) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background(brightness),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      title: Row(
        children: [
          // Logo / Brand Name
          Text(
            'Roxxie',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.crimson,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        // Create Post Button (red + icon, no background)
        IconButton(
          onPressed: _onCreatePost,
          icon: Icon(
            Icons.add_circle_outline_rounded,
            color: AppColors.crimson,
            size: 28,
          ),
          tooltip: 'Create Post',
        ),
        // Notifications
        IconButton(
          onPressed: _onNotifications,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppColors.text(brightness),
                size: 26,
              ),
              // Notification badge (if needed)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.crimson,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background(brightness),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _onCreatePost() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/create-post');
  }

  void _onNotifications() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/notifications');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STORIES SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _StoriesSection extends StatelessWidget {
  final List<Story> stories;
  final FeedStatus status;

  const _StoriesSection({required this.stories, required this.status});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();

    if (status == FeedStatus.loading && stories.isEmpty) {
      return _buildLoadingShimmer(brightness);
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: stories.length + 1, // +1 for "Your Story"
        itemBuilder: (context, index) {
          if (index == 0) {
            // Your Story (Add new)
            return _YourStoryAvatar(
              profilePhoto: auth.isArtist
                  ? auth.artistProfile?.profilePhoto
                  : auth.venueProfile?.profilePhotoUrl,
              brightness: brightness,
            );
          }

          final story = stories[index - 1];
          return _StoryAvatar(story: story, brightness: brightness);
        },
      ),
    );
  }

  Widget _buildLoadingShimmer(Brightness brightness) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            width: 72,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface(brightness),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 48,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.surface(brightness),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _YourStoryAvatar extends StatelessWidget {
  final String? profilePhoto;
  final Brightness brightness;

  const _YourStoryAvatar({this.profilePhoto, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/create-story');
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                // Profile photo
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface(brightness),
                    border: Border.all(
                      color: AppColors.border(brightness),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: profilePhoto != null
                        ? CachedNetworkImage(
                            imageUrl: profilePhoto!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: AppColors.surface(brightness)),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person_rounded,
                              color: AppColors.textSec(brightness),
                              size: 32,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            color: AppColors.textSec(brightness),
                            size: 32,
                          ),
                  ),
                ),
                // Add button
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.crimson,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background(brightness),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Your Story',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSec(brightness),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final Story story;
  final Brightness brightness;

  const _StoryAvatar({required this.story, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final hasUnviewed = story.hasUnviewed;
    final profilePhoto = story.author?.profilePhoto;
    final name = story.author?.name ?? 'User';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openStoryViewer(context);
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // Story ring
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? const LinearGradient(
                        colors: [
                          AppColors.crimson,
                          AppColors.rose,
                          AppColors.crimsonLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: hasUnviewed
                    ? null
                    : Border.all(color: AppColors.border(brightness), width: 2),
              ),
              child: Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background(brightness),
                ),
                child: ClipOval(
                  child: profilePhoto != null
                      ? CachedNetworkImage(
                          imageUrl: profilePhoto,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: AppColors.surface(brightness)),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surface(brightness),
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.textSec(brightness),
                              size: 28,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surface(brightness),
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.textSec(brightness),
                            size: 28,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSec(brightness),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _openStoryViewer(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/story-viewer',
      arguments: {'storyId': story.id, 'userId': story.userId},
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POST CARD
// ═══════════════════════════════════════════════════════════════════════════

class _PostCard extends StatefulWidget {
  final Post post;
  final Brightness brightness;

  const _PostCard({required this.post, required this.brightness});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  bool _showLikeAnimation = false;
  int _currentMediaIndex = 0;
  final PageController _mediaPageController = PageController();

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    _mediaPageController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (!widget.post.isLiked) {
      context.read<FeedProvider>().toggleLike(widget.post.id);
    }
    setState(() => _showLikeAnimation = true);
    _likeController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _likeController.reverse().then((_) {
            if (mounted) {
              setState(() => _showLikeAnimation = false);
            }
          });
        }
      });
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final brightness = widget.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(post, brightness),

        // Media
        GestureDetector(
          onDoubleTap: _onDoubleTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildMedia(post, brightness),
              // Like animation
              if (_showLikeAnimation)
                ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.2).animate(
                    CurvedAnimation(
                      parent: _likeController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 100,
                    shadows: [Shadow(blurRadius: 20, color: Colors.black38)],
                  ),
                ),
            ],
          ),
        ),

        // Actions
        _buildActions(post, brightness),

        // Like count
        if (!post.likesHidden && post.likeCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_formatCount(post.likeCount)} likes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text(brightness),
              ),
            ),
          ),

        // Caption
        if (post.caption != null && post.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: _buildCaption(post, brightness),
          ),

        // Comments preview
        if (post.commentCount > 0 && !post.commentsDisabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: GestureDetector(
              onTap: () => _openComments(context, post),
              child: Text(
                'View all ${post.commentCount} comments',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSec(brightness),
                ),
              ),
            ),
          ),

        // Timestamp
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Text(
            _formatTimeAgo(post.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTert(brightness),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Post post, Brightness brightness) {
    final author = post.author;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _openProfile(context, post),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface(brightness),
              ),
              child: ClipOval(
                child: author?.profilePhoto != null
                    ? CachedNetworkImage(
                        imageUrl: author!.profilePhoto!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.surface(brightness)),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person_rounded,
                          color: AppColors.textSec(brightness),
                          size: 20,
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        color: AppColors.textSec(brightness),
                        size: 20,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & Location
          Expanded(
            child: GestureDetector(
              onTap: () => _openProfile(context, post),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        author?.name ?? 'User',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text(brightness),
                        ),
                      ),
                      if (author?.isVerified ?? false) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.crimson,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  if (post.locationName != null)
                    Text(
                      post.locationName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec(brightness),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // More options
          IconButton(
            onPressed: () => _showPostOptions(context, post),
            icon: Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textSec(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(Post post, Brightness brightness) {
    if (post.media.isEmpty) {
      return const SizedBox.shrink();
    }

    final aspectRatio = post.media.first.aspectRatio.clamp(0.5, 2.0);

    if (post.media.length == 1) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: _buildMediaItem(post.media.first, brightness),
      );
    }

    // Multiple media - carousel
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          PageView.builder(
            controller: _mediaPageController,
            itemCount: post.media.length,
            onPageChanged: (index) {
              setState(() => _currentMediaIndex = index);
            },
            itemBuilder: (context, index) {
              return _buildMediaItem(post.media[index], brightness);
            },
          ),
          // Page indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentMediaIndex + 1}/${post.media.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(PostMedia media, Brightness brightness) {
    if (media.type == MediaType.video) {
      // Video thumbnail with play button
      return Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: media.thumbnailUrl ?? media.url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) =>
                Container(color: AppColors.surface(brightness)),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surface(brightness),
              child: const Icon(Icons.error_outline),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      );
    }

    return CachedNetworkImage(
      imageUrl: media.url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: AppColors.surface(brightness),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.crimson,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surface(brightness),
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textSec(brightness),
        ),
      ),
    );
  }

  Widget _buildActions(Post post, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          // Like
          _ActionButton(
            icon: post.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: post.isLiked ? AppColors.crimson : null,
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<FeedProvider>().toggleLike(post.id);
            },
          ),
          // Comment
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => _openComments(context, post),
          ),
          // Share
          _ActionButton(
            icon: Icons.send_outlined,
            onTap: () => _sharePost(context, post),
          ),
          const Spacer(),
          // Save
          _ActionButton(
            icon: post.isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: post.isSaved ? AppColors.crimson : null,
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<FeedProvider>().toggleSave(post.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCaption(Post post, Brightness brightness) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: AppColors.text(brightness),
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: '${post.author?.name ?? 'User'} ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: post.caption ?? ''),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _openProfile(BuildContext context, Post post) {
    final route = post.author?.role == 'venue'
        ? '/venue/${post.venueId ?? post.userId}'
        : '/artist/${post.artistId ?? post.userId}';
    Navigator.pushNamed(context, route);
  }

  void _openComments(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(post: post),
    );
  }

  void _sharePost(BuildContext context, Post post) {
    HapticFeedback.lightImpact();
    // Implement share functionality
  }

  void _showPostOptions(BuildContext context, Post post) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostOptionsSheet(post: post),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTION BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color ?? AppColors.text(brightness), size: 26),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING SHIMMER
// ═══════════════════════════════════════════════════════════════════════════

class _PostsLoadingShimmer extends StatelessWidget {
  const _PostsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface(brightness),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.surface(brightness),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.surface(brightness),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Image shimmer
              AspectRatio(
                aspectRatio: 1,
                child: Container(color: AppColors.surface(brightness)),
              ),
              // Actions shimmer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(3, (i) {
                    return Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface(brightness),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyFeedState extends StatelessWidget {
  final Brightness brightness;

  const _EmptyFeedState({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: AppColors.textSec(brightness),
          ),
          const SizedBox(height: 24),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something amazing',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSec(brightness),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/create-post'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Post'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMMENTS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _CommentsSheet extends StatefulWidget {
  final Post post;

  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<FeedProvider>().addComment(widget.post.id, text);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.border(brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Comments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text(brightness),
              ),
            ),
          ),
          const Divider(height: 1),
          // Comments list
          Expanded(
            child: widget.post.comments.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(color: AppColors.textSec(brightness)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.post.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.post.comments[index];
                      return _CommentTile(comment: comment);
                    },
                  ),
          ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              border: Border(
                top: BorderSide(color: AppColors.border(brightness)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: AppColors.textSec(brightness),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.background(brightness),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: TextStyle(color: AppColors.text(brightness)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.crimson,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: AppColors.crimson,
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

class _CommentTile extends StatelessWidget {
  final PostComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background(brightness),
            ),
            child: ClipOval(
              child: comment.author?.profilePhoto != null
                  ? CachedNetworkImage(
                      imageUrl: comment.author!.profilePhoto!,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: AppColors.textSec(brightness),
                      size: 18,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text(brightness),
                    ),
                    children: [
                      TextSpan(
                        text: '${comment.author?.name ?? 'User'} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: comment.text),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(comment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTert(brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POST OPTIONS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _PostOptionsSheet extends StatelessWidget {
  final Post post;

  const _PostOptionsSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.read<AuthProvider>();
    final isOwner = post.userId == auth.user?.id;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwner) ...[
              _OptionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Post',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit
                },
              ),
              _OptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Post',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
            _OptionTile(
              icon: Icons.share_outlined,
              title: 'Share',
              onTap: () {
                Navigator.pop(context);
                // Share
              },
            ),
            _OptionTile(
              icon: Icons.link_outlined,
              title: 'Copy Link',
              onTap: () {
                Navigator.pop(context);
                // Copy link
              },
            ),
            if (!isOwner)
              _OptionTile(
                icon: Icons.flag_outlined,
                title: 'Report',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  // Report
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FeedProvider>().deletePost(post.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.crimson),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = isDestructive
        ? AppColors.crimson
        : AppColors.text(brightness);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
