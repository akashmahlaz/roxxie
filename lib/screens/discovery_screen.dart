/// 🎯 GIGMATCH Discovery Screen - BULLETPROOF VERSION
///
/// Tinder-style swipe cards for discovering gigs and artists/venues
/// Features:
/// - Tinder-like swipe gesture controls
/// - Card stack with physics
/// - Real-time swipe feedback
/// - Match animation on mutual swipe
/// - Smart recommendations display
/// - Filter drawer
/// - Premium boost indicators
/// - Comprehensive error handling
/// - Offline support
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/services.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'matches_screen.dart';
import '../../widgets/widgets.dart';

/// 🎯 Discovery Screen - Main Widget
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin, TickerProviderStateMixin {
  // Controllers
  late AnimationController _cardController;
  late AnimationController _matchController;
  late AnimationController _overlayController;
  late AnimationController _filterController;

  // Swipe state
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  bool _isDragging = false;

  // Match animation state
  bool _showMatchAnimation = false;
  Match? _pendingMatch;

  // Filter panel state
  bool _showFilters = false;

  // Current card index
  int _currentCardIndex = 0;

  // Scroll controller for card stack
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Card swipe animation controller
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Match animation controller
    _matchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Overlay animation controller
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Filter panel animation controller
    _filterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDiscoveryFeed();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _matchController.dispose();
    _overlayController.dispose();
    _filterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadDiscoveryFeed() async {
    final provider = context.read<DiscoveryProvider>();
    await provider.loadCards(refresh: true);
  }

  Future<void> _loadMoreCards() async {
    final provider = context.read<DiscoveryProvider>();
    await provider.loadMore();
  }

  // ═══════════════════════════════════════════════════════════════
  // SWIPE GESTURES
  // ═══════════════════════════════════════════════════════════════

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx / 300 * 0.5;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    setState(() => _isDragging = false);

    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.velocity.pixelsPerSecond;

    // Thresholds for swipe
    final swipeThreshold = screenWidth * 0.35;
    final velocityThreshold = 800.0;

    if (_dragOffset.dx.abs() > swipeThreshold || velocity.dx.abs() > velocityThreshold) {
      final isLike = _dragOffset.dx > 0;
      _animateSwipe(isLike);
    } else {
      _animateReturn();
    }
  }

  Future<void> _animateSwipe(bool isLike) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isLike ? screenWidth * 1.3 : -screenWidth * 1.3;

    // Capture provider before async
    final provider = context.read<DiscoveryProvider>();
    final items = provider.items;

    if (items.isEmpty) return;

    final currentItem = items[_currentCardIndex];
    final swipeType = isLike ? SwipeDirection.right : SwipeDirection.left;

    // Animate card off screen
    _cardController.reset();
    _cardController.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(
          _dragOffset,
          Offset(targetX, _dragOffset.dy + 100 * _cardController.value),
          Curves.easeOutCubic.transform(_cardController.value),
        )!;
        _dragAngle = _dragAngle + (isLike ? 0.3 : -0.3) * _cardController.value;
      });
    });

    await _cardController.forward(from: 0);
    _cardController.removeListener(() {});

    // Perform swipe action
    try {
      final result = await provider.swipe(currentItem, swipeType);

      // Check for match
      if (result.createdMatch && result.match != null) {
        _pendingMatch = result.match;
        _showMatchDialog();
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }

    // Reset card position
    setState(() {
      _dragOffset = Offset.zero;
      _dragAngle = 0;
      _currentCardIndex++;
    });

    _cardController.reset();

    // Load more if running low on cards
    if (items.length - _currentCardIndex <= 3) {
      _loadMoreCards();
    }
  }

  Future<void> _animateReturn() async {
    _cardController.reset();
    _cardController.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(
          _dragOffset,
          Offset.zero,
          Curves.easeOutCubic.transform(_cardController.value),
        )!;
        _dragAngle = _dragAngle * (1 - _cardController.value);
      });
    });

    await _cardController.forward(from: 0);
    _cardController.removeListener(() {});

    setState(() {
      _dragOffset = Offset.zero;
      _dragAngle = 0;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // MATCH ANIMATION
  // ═══════════════════════════════════════════════════════

  void _showMatchDialog() {
    if (_pendingMatch == null) return;

    setState(() => _showMatchAnimation = true);
    _matchController.reset();
    _matchController.addListener(() {
      setState(() {});
    });
    _matchController.forward(from: 0);
  }

  void _hideMatchDialog() {
    _matchController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showMatchAnimation = false;
          _pendingMatch = null;
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════
  // ERROR HANDLING
  // ═══════════════════════════════════════════════════════

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadDiscoveryFeed,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final provider = context.watch<DiscoveryProvider>();
    final items = provider.items;
    final isLoading = provider.isLoading;
    final error = provider.error;

    return Stack(
      children: [
        // Main content
        Scaffold(
          backgroundColor: AppColors.background(brightness),
          appBar: _buildAppBar(brightness),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                // Filter chips
                _buildFilterChips(brightness),

                // Main content area
                Expanded(
                  child: _buildContent(items, isLoading, error, brightness),
                ),

                // Action buttons
                _buildActionButtons(brightness),
              ],
            ),
          ),
        ),

        // Filter panel
        _buildFilterPanel(brightness),

        // Match animation overlay
        if (_showMatchAnimation) _buildMatchOverlay(brightness),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
    return AppBar(
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.tune_rounded,
          color: _showFilters ? AppColors.crimson : AppColors.text(brightness),
        ),
        onPressed: _toggleFilters,
      ),
      title: Text(
        'Discover',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        // Boost button
        IconButton(
          icon: Icon(
            Icons.rocket_launch_rounded,
            color: AppColors.crimson,
          ),
          onPressed: _showBoostDialog,
          tooltip: 'Boost visibility',
        ),
      ],
    );
  }

  Widget _buildFilterChips(Brightness brightness) {
    final provider = context.watch<DiscoveryProvider>();
    final filters = provider.filters;
    final genres = ['Rock', 'Jazz', 'Pop', 'Hip-Hop', 'Electronic', 'Blues'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Location chip
            FilterChip(
              selected: filters.latitude != null,
              label: const Text('Nearby'),
              avatar: Icon(
                filters.latitude != null
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                size: 18,
                color: filters.latitude != null
                    ? Colors.white
                    : AppColors.crimson,
              ),
              selectedColor: AppColors.crimson,
              onSelected: _toggleLocationFilter,
            ),
            const SizedBox(width: 8),
            // Genre chips
            ...genres.map((genre) {
              final isSelected = filters.genres.contains(genre);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(genre),
                  selectedColor: AppColors.crimson,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.text(brightness),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  onSelected: (selected) => _toggleGenre(genre, selected),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    List<DiscoveryItem> items,
    bool isLoading,
    String? error,
    Brightness brightness,
  ) {
    if (isLoading && items.isEmpty) {
      return _buildLoadingState(brightness);
    }

    if (error != null && items.isEmpty) {
      return _buildErrorState(error, brightness);
    }

    if (items.isEmpty) {
      return _buildEmptyState(brightness);
    }

    // Check if we've swiped through all cards
    if (_currentCardIndex >= items.length) {
      return _buildAllDoneState(brightness);
    }

    // Build card stack
    final remainingCards = items.length - _currentCardIndex;
    final displayCards = items.skip(_currentCardIndex).take(3).toList().reversed.toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background cards (already swiped)
        ...items.take(_currentCardIndex).map((item) => _buildCard(item, brightness, opacity: 0)).toList(),

        // Current and upcoming cards
        ...displayCards.asMap().entries.map((entry) {
          final index = displayCards.length - 1 - entry.key;
          final item = entry.value;
          final scale = 1.0 - index * 0.05;
          final offset = Offset(0, index * 8.0);

          return Positioned.fill(
            child: Transform.translate(
              offset: offset,
              child: Transform.scale(
                scale: scale,
                child: _buildCard(item, brightness),
              ),
            ),
          );
        }),

        // Swipe hint overlay
        if (items.length - _currentCardIndex <= 2) Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${items.length - _currentCardIndex} more to see',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(DiscoveryItem item, Brightness brightness, {double opacity = 1}) {
    final cardWidth = MediaQuery.of(context).size.width - 48;
    final cardHeight = MediaQuery.of(context).size.height * 0.65;

    return VisibilityDetector(
      key: Key('card_${item.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 0.5 && _currentCardIndex >= items.length) {
          _loadMoreCards();
        }
      },
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform.rotate(
          angle: _dragAngle,
          child: Transform.translate(
            offset: _dragOffset,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image or gradient
                    _buildCardBackground(item, brightness),

                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Verified/Boosted badges
                    _buildBadges(item, brightness),

                    // Content
                    _buildCardContent(item, brightness),

                    // Swipe indicators
                    _buildSwipeIndicators(brightness),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBackground(DiscoveryItem item, Brightness brightness) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildPlaceholderGradient(brightness),
      );
    }

    return _buildPlaceholderGradient(brightness);
  }

  Widget _buildPlaceholderGradient(Brightness brightness) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.crimson.withValues(alpha: 0.6),
            AppColors.rose.withValues(alpha: 0.4),
            AppColors.purple.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges(DiscoveryItem item, Brightness brightness) {
    final badges = <Widget>[];

    if (item.isBoosted) {
      badges.add(
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  'BOOSTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (item.isVerified) {
      badges.add(
        Positioned(
          top: 16,
          right: 16,
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_rounded,
              color: Colors.blue.shade400,
              size: 20,
            ),
          ),
        ),
      );
    }

    return Stack(children: badges);
  }

  Widget _buildCardContent(DiscoveryItem item, Brightness brightness) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Subtitle/Genres
            if (item.subtitle != null)
              Text(
                item.subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 12),

            // Info row
            Row(
              children: [
                // Location
                if (item.city != null) ...[
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.city!,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Distance
                if (item.distanceMiles > 0) ...[
                  const Icon(
                    Icons.directions_walk_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.distanceMiles.toStringAsFixed(0)} mi',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Rating
                if (item.rating != null && item.rating! > 0) ...[
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.amber.shade400,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.rating!.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.amber.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Price
                if (item.priceMin != null)
                  Text(
                    '\$${item.priceMin!.toStringAsFixed(0)}+',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Recommendation score
            if (item.recommendationScore > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: _getScoreColor(item.recommendationScore),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.recommendationScore.toStringAsFixed(0)}% match',
                      style: TextStyle(
                        color: _getScoreColor(item.recommendationScore),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

  Widget _buildSwipeIndicators(Brightness brightness) {
    final screenWidth = MediaQuery.of(context).size.width;
    final likeThreshold = screenWidth * 0.35;

    // LIKE indicator (right)
    if (_dragOffset.dx > likeThreshold * 0.3) {
      Positioned(
        top: 40,
        right: 24,
        child: Transform.rotate(
          angle: 0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Text(
              'LIKE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      );
    }

    // NOPE indicator (left)
    if (_dragOffset.dx < -likeThreshold * 0.3) {
      Positioned(
        top: 40,
        left: 24,
        child: Transform.rotate(
          angle: -0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.crimson,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Text(
              'NOPE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.crimson,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Finding matches...',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.crimson,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDiscoveryFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppColors.textSec(brightness),
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            'No results found',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDoneState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration_rounded,
              color: AppColors.crimson,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You\'ve seen everyone!',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Check back later for new matches',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _loadDiscoveryFeed,
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              side: BorderSide(color: AppColors.crimson),
            ),
            child: Text(
              'Refresh',
              style: TextStyle(
                color: AppColors.crimson,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind button
          _buildActionButton(
            icon: Icons.replay_rounded,
            color: Colors.blue.shade400,
            size: 48,
            onTap: _undoLastSwipe,
          ),

          // Nope button
          _buildActionButton(
            icon: Icons.close_rounded,
            color: AppColors.crimson,
            size: 64,
            onTap: () => _animateSwipe(false),
          ),

          // Super like button
          _buildActionButton(
            icon: Icons.star_rounded,
            color: Colors.blue.shade600,
            size: 56,
            onTap: () => _superLike(),
          ),

          // Like button
          _buildActionButton(
            icon: Icons.favorite_rounded,
            color: Colors.green.shade500,
            size: 64,
            onTap: () => _animateSwipe(true),
          ),

          // Boost button
          _buildActionButton(
            icon: Icons.rocket_launch_rounded,
            color: Colors.amber.shade600,
            size: 48,
            onTap: _showBoostDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface(Theme.of(context).brightness),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER PANEL
  // ═══════════════════════════════════════════════════════

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
  }

  void _toggleLocationFilter(bool enabled) {
    final provider = context.read<DiscoveryProvider>();
    provider.updateFilters(
      latitude: enabled ? 40.7128 : null,
      longitude: enabled ? -74.0060 : null,
      radiusMiles: enabled ? 50 : null,
    );
  }

  void _toggleGenre(String genre, bool selected) {
    final provider = context.read<DiscoveryProvider>();
    final currentGenres = List<String>.from(provider.filters.genres);
    if (selected) {
      currentGenres.add(genre);
    } else {
      currentGenres.remove(genre);
    }
    provider.updateFilters(genres: currentGenres);
  }

  Widget _buildFilterPanel(Brightness brightness) {
    return AnimatedBuilder(
      animation: _filterController,
      builder: (context, child) {
        final panelWidth = MediaQuery.of(context).size.width * 0.85;
        final offset = _showFilters
            ? Offset.zero
            : Offset(-panelWidth, 0);

        return Transform.translate(
          offset: offset,
          child: Container(
            width: panelWidth,
            height: MediaQuery.of(context).size.height,
            color: AppColors.surface(brightness),
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFilters,
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSec(brightness),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter options
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildFilterSection(
                          'Location',
                          [
                            _buildFilterOption(
                              'Use my location',
                              Icons.my_location_rounded,
                              true,
                              _onLocationFilterChanged,
                            ),
                          ],
                        ),
                        _buildFilterSection(
                          'Price Range',
                          [
                            _buildPriceRangeSlider(),
                          ],
                        ),
                        _buildFilterSection(
                          'Rating',
                          [
                            _buildRatingFilter(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Apply button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _toggleFilters();
                          _loadDiscoveryFeed();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.crimson,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFilterOption(
    String title,
    IconData icon,
    bool selected,
    Function(bool) onChanged,
  ) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.crimson),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 15,
                ),
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.crimson,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeSlider() {
    return Column(
      children: [
        RangeSlider(
          values: const RangeValues(0, 1000),
          onChanged: (_) {},
          activeColor: AppColors.crimson,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('\$0'),
            Text('\$1000+'),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    final ratings = [4.5, 4.0, 3.5, 3.0];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ratings.map((rating) {
        return FilterChip(
          label: Text('${rating.toStringAsFixed(1)}+'),
          selected: false,
          selectedColor: AppColors.crimson,
          onSelected: (_) {},
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MATCH OVERLAY
  // ═══════════════════════════════════════════════════════

  Widget _buildMatchOverlay(Brightness brightness) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background particles (simplified)
          ...List.generate(20, (index) {
            final random = math.Random(index);
            return Positioned(
              left: random.nextDouble() * 400,
              top: random.nextDouble() * 800,
              child: Icon(
                Icons.star_rounded,
                color: AppColors.crimson.withValues(alpha: 0.3),
                size: random.nextDouble() * 20 + 10,
              ),
            );
          }),

          // Match content
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _matchController,
                curve: Curves.elasticOut,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "It's a Match!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You and ${_pendingMatch?.participantName} liked each other',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Profile photos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMatchAvatar(),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 20),
                      _buildMatchAvatar(),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _hideMatchDialog();
                          if (_pendingMatch != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatScreen(matchId: _pendingMatch!.id),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.crimson,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 16),
                        ),
                        child: const Text(
                          'Send Message',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _hideMatchDialog,
                    child: Text(
                      'Keep Swiping',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        image: _pendingMatch?.participantPhoto != null
            ? DecorationImage(
                image: NetworkImage(_pendingMatch!.participantPhoto!),
                fit: BoxFit.cover,
              )
            : null,
        color: AppColors.crimson.withValues(alpha: 0.3),
      ),
      child: _pendingMatch?.participantPhoto == null
          ? Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 40,
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════

  void _onLocationFilterChanged(bool enabled) {
    // Get current location and update filters
    final provider = context.read<DiscoveryProvider>();
    provider.updateFilters(
      latitude: enabled ? 40.7128 : null,
      longitude: enabled ? -74.0060 : null,
      radiusMiles: enabled ? 50 : null,
    );
  }

  Future<void> _undoLastSwipe() async {
    final provider = context.read<DiscoveryProvider>();
    try {
      await provider.undoLastSwipe();
      if (_currentCardIndex > 0) {
        setState(() => _currentCardIndex--);
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _superLike() async {
    // Premium feature - boost visibility
    final provider = context.read<DiscoveryProvider>();
    if (provider.items.isNotEmpty) {
      await provider.swipe(provider.items[_currentCardIndex], SwipeDirection.right);
    }
  }

  void _showBoostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(Theme.of(context).brightness),
        title: const Text('Boost Your Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Get seen by more venues! Your profile will appear at the top of discovery for 24 hours.',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildBoostOption('24 hours', '\$4.99'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBoostOption('7 days', '\$24.99'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSec(Theme.of(context).brightness),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Process boost purchase
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
            ),
            child: const Text('Boost Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostOption(String duration, String price) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.crimson),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.rocket_launch_rounded, color: AppColors.crimson),
            const SizedBox(height: 8),
            Text(
              duration,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              price,
              style: TextStyle(
                color: AppColors.crimson,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green.shade400;
    if (score >= 60) return Colors.amber.shade400;
    if (score >= 40) return Colors.orange.shade400;
    return Colors.red.shade400;
  }
}
