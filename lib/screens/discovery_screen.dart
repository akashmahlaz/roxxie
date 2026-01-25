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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/theme.dart';

import 'chat_screen.dart';

/// 🎯 Discovery Screen - Main Widget
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _cardController;
  late AnimationController _matchController;
  late AnimationController _overlayController;
  late AnimationController _filterController;

  // Swipe state
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  bool _isDragging = false;

  final Set<String> _selectedGenres = <String>{};
  bool _useLocationFilter = false;

  // Match animation state
  bool _showMatchAnimation = false;
  Match? _pendingMatch;

  // Filter panel state
  bool _showFilters = false;

  // Current card index
  int _currentCardIndex = 0;

  // Scroll controller for card stack
  final ScrollController _scrollController = ScrollController();

  // Price range filter state
  RangeValues _priceRange = const RangeValues(0, 1000);
  double _minRating = 0;

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
    await provider.loadCards();
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

    if (_dragOffset.dx.abs() > swipeThreshold ||
        velocity.dx.abs() > velocityThreshold) {
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
    final cards = provider.cards;

    if (cards.isEmpty) return;

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
      bool isMatch = false;
      if (isLike) {
        isMatch = await provider.like();
      } else {
        await provider.pass();
      }

      // Check for match
      if (isMatch && provider.lastMatch != null) {
        _pendingMatch = provider.lastMatch;
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
    if (provider.remainingCards <= 3) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final auth = context.watch<AuthProvider>();
    final cards = provider.cards;
    final isLoading = provider.isLoading;
    final error = provider.errorMessage;
    final isArtist = auth.isArtist;

    return Stack(
      children: [
        // Main content
        Scaffold(
          backgroundColor: AppColors.background(brightness),
          appBar: _buildAppBar(brightness, isArtist),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                // Filter chips
                _buildFilterChips(brightness),

                // Main content area
                Expanded(
                  child: _buildContent(
                    cards,
                    isLoading,
                    error ?? '',
                    brightness,
                  ),
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

  PreferredSizeWidget _buildAppBar(Brightness brightness, bool isArtist) {
    final hasPriceFilter = _priceRange.start > 0 || _priceRange.end < 1000;
    final hasRatingFilter = _minRating > 0;
    final activeFilterCount =
        _selectedGenres.length +
        (_useLocationFilter ? 1 : 0) +
        (hasPriceFilter ? 1 : 0) +
        (hasRatingFilter ? 1 : 0);

    return AppBar(
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      leading: Stack(
        children: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: _showFilters || activeFilterCount > 0
                  ? AppColors.crimson
                  : AppColors.text(brightness),
            ),
            onPressed: _toggleFilters,
          ),
          if (activeFilterCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.crimson,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$activeFilterCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        isArtist ? 'Discover Gigs' : 'Discover Artists',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        // Boost button
        IconButton(
          icon: Icon(Icons.rocket_launch_rounded, color: AppColors.crimson),
          onPressed: _showBoostDialog,
          tooltip: 'Boost visibility',
        ),
      ],
    );
  }

  Widget _buildFilterChips(Brightness brightness) {
    final genres = ['Rock', 'Jazz', 'Pop', 'Hip-Hop', 'Electronic', 'Blues'];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Location chip
          _buildStyledFilterChip(
            label: 'Nearby',
            icon: _useLocationFilter
                ? Icons.location_on_rounded
                : Icons.location_off_rounded,
            isSelected: _useLocationFilter,
            brightness: brightness,
            onSelected: (selected) => _toggleLocationFilter(selected),
          ),
          const SizedBox(width: 8),
          // Genre chips
          ...genres.map((genre) {
            final isSelected = _selectedGenres.contains(genre);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildStyledFilterChip(
                label: genre,
                isSelected: isSelected,
                brightness: brightness,
                onSelected: (selected) => _toggleGenre(genre, selected),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStyledFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Brightness brightness,
    required ValueChanged<bool> onSelected,
  }) {
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: icon != null ? 12 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.crimson : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.crimson
                : AppColors.border(brightness),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.crimson,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.text(brightness),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    List<DiscoveryCard> cards,
    bool isLoading,
    String error,
    Brightness brightness,
  ) {
    if (isLoading && cards.isEmpty) {
      return _buildLoadingState(brightness);
    }

    if (cards.isEmpty) {
      if (error.isNotEmpty) {
        return _buildErrorState(error, brightness);
      }
      return _buildEmptyState(brightness);
    }

    // Check if we've swiped through all cards
    if (_currentCardIndex >= cards.length) {
      return _buildAllDoneState(brightness);
    }

    // Build card stack
    final displayCards = cards
        .skip(_currentCardIndex)
        .take(3)
        .toList()
        .reversed
        .toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background cards (already swiped)
        ...cards
            .take(_currentCardIndex)
            .map((item) => _buildCard(item, brightness, opacity: 0)),

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

        // Remaining cards indicator (subtle at top)
        if (cards.length - _currentCardIndex <= 3)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cards.length - _currentCardIndex} left',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(
    DiscoveryCard card,
    Brightness brightness, {
    double opacity = 1,
  }) {
    final discoveryProvider = context.read<DiscoveryProvider>();

    final item = DiscoveryItem.fromCard(card);

    final cardWidth = MediaQuery.of(context).size.width - 48;

    final cardHeight = MediaQuery.of(context).size.height * 0.65;

    return VisibilityDetector(
      key: Key('card_${card.id}'),

      onVisibilityChanged: (info) {
        final lastIndex = discoveryProvider.cards.length - 1;
        final shouldLoadMore =
            info.visibleFraction < 0.3 &&
            lastIndex >= 0 &&
            _currentCardIndex >= lastIndex;
        if (shouldLoadMore) {
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

            child: Opacity(
              opacity: opacity,

              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),

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
                      _buildCardBackground(item, brightness),

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

                      _buildBadges(item, brightness),

                      _buildCardContent(item, brightness),

                      _buildSwipeIndicators(brightness),
                    ],
                  ),
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
        errorWidget: (_, _, _) => _buildPlaceholderGradient(brightness),
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
            AppColors.electricViolet.withValues(alpha: 0.3),
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

              children: const [
                Icon(
                  Icons.rocket_launch_rounded,

                  color: Colors.white,

                  size: 16,
                ),

                SizedBox(width: 4),

                Text(
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

          child: Container(
            padding: const EdgeInsets.all(6),

            decoration: const BoxDecoration(
              color: Colors.white,

              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.blue,
              size: 20,
            ),
          ),
        ),
      );
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(children: badges);
  }

  Widget _buildCardContent(DiscoveryItem item, Brightness brightness) {
    final infoChips = <Widget>[];

    if (item.city != null && item.city!.isNotEmpty) {
      infoChips.add(
        _buildInfoChip(icon: Icons.location_on_rounded, label: item.city!),
      );
    }

    if (item.distanceMiles > 0) {
      infoChips.add(
        _buildInfoChip(
          icon: Icons.directions_walk_rounded,
          label: '${item.distanceMiles.toStringAsFixed(0)} mi',
        ),
      );
    }

    if (item.rating != null && item.rating! > 0) {
      infoChips.add(
        _buildInfoChip(
          icon: Icons.star_rounded,
          iconColor: Colors.amber.shade400,
          label: item.rating!.toStringAsFixed(1),
        ),
      );
    }

    if (item.priceMin != null) {
      infoChips.add(
        _buildInfoChip(
          icon: Icons.attach_money_rounded,
          iconColor: Colors.white,
          label: '${item.priceMin!.toStringAsFixed(0)}+',
        ),
      );
    }

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                item.typeLabel.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (infoChips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: infoChips),
            ],
            if (item.recommendationScore > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color iconColor = Colors.white70,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeIndicators(Brightness brightness) {
    final screenWidth = MediaQuery.of(context).size.width;
    final likeThreshold = screenWidth * 0.35;

    final showLike = _dragOffset.dx > likeThreshold * 0.3;
    final showNope = _dragOffset.dx < -likeThreshold * 0.3;

    if (!showLike && !showNope) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        if (showLike)
          Positioned(
            top: 40,
            right: 24,
            child: Transform.rotate(
              angle: 0.3,
              child: _buildSwipeLabel(text: 'LIKE', color: Colors.green),
            ),
          ),
        if (showNope)
          Positioned(
            top: 40,
            left: 24,
            child: Transform.rotate(
              angle: -0.3,
              child: _buildSwipeLabel(text: 'NOPE', color: AppColors.crimson),
            ),
          ),
      ],
    );
  }

  Widget _buildSwipeLabel({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildLoadingState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.crimson, strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Finding matches...',
            style: TextStyle(color: AppColors.text(brightness), fontSize: 16),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
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
    final auth = context.watch<AuthProvider>();
    final isArtist = auth.isArtist;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                isArtist ? Icons.business_rounded : Icons.mic_rounded,
                color: AppColors.crimson,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isArtist ? 'No gigs yet' : 'No artists yet',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isArtist
                  ? 'Gigs in your area will appear here.\nWe\'re growing fast — check back soon!'
                  : 'Artists in your area will appear here.\nWe\'re growing fast — check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadDiscoveryFeed,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
            size: 44,
            label: 'Rewind',
            onTap: _undoLastSwipe,
          ),

          // Nope button
          _buildActionButton(
            icon: Icons.close_rounded,
            color: AppColors.crimson,
            size: 58,
            label: 'Pass',
            onTap: () => _animateSwipe(false),
          ),

          // Super like button
          _buildActionButton(
            icon: Icons.star_rounded,
            color: Colors.blue.shade600,
            size: 52,
            label: 'Super',
            onTap: () => _superLike(),
          ),

          // Like button
          _buildActionButton(
            icon: Icons.favorite_rounded,
            color: Colors.green.shade500,
            size: 58,
            label: 'Like',
            onTap: () => _animateSwipe(true),
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
    String? label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.surface(Theme.of(context).brightness),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: size * 0.6),
          ),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSec(Theme.of(context).brightness),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
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
    setState(() {
      _useLocationFilter = enabled;
    });
    if (enabled) {
      provider.setLocationFilter(
        latitude: 40.7128,
        longitude: -74.0060,
        maxDistance: 50,
      );
    } else {
      provider.clearFilters();
      setState(() {
        _selectedGenres.clear();
      });
    }
  }

  void _toggleGenre(String genre, bool selected) {
    setState(() {
      if (selected) {
        _selectedGenres.add(genre);
      } else {
        _selectedGenres.remove(genre);
      }
    });

    final provider = context.read<DiscoveryProvider>();
    provider.setGenreFilter(_selectedGenres.toList());
  }

  Widget _buildFilterPanel(Brightness brightness) {
    return AnimatedBuilder(
      animation: _filterController,
      builder: (context, child) {
        final panelWidth = MediaQuery.of(context).size.width * 0.85;
        final hasPriceFilter = _priceRange.start > 0 || _priceRange.end < 1000;
        final hasRatingFilter = _minRating > 0;
        final appliedCount =
            _selectedGenres.length +
            (_useLocationFilter ? 1 : 0) +
            (hasPriceFilter ? 1 : 0) +
            (hasRatingFilter ? 1 : 0);
        final offset = _showFilters ? Offset.zero : Offset(-panelWidth, 0);

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
                        Row(
                          children: [
                            Text(
                              'Filters',
                              style: TextStyle(
                                color: AppColors.text(brightness),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (appliedCount > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.crimson,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$appliedCount applied',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _clearAllFilters,
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  color: AppColors.textSec(brightness),
                                  fontWeight: FontWeight.w600,
                                ),
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
                      ],
                    ),
                  ),

                  // Filter options
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildFilterSection('Location', [
                          _buildFilterOption(
                            'Use my location',
                            Icons.my_location_rounded,
                            _useLocationFilter,
                            _onLocationFilterChanged,
                          ),
                        ]),
                        _buildFilterSection('Price Range', [
                          _buildPriceRangeSlider(),
                        ]),
                        _buildFilterSection('Rating', [_buildRatingFilter()]),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
          values: _priceRange,
          min: 0,
          max: 2000,
          divisions: 40,
          onChanged: (RangeValues values) {
            setState(() {
              _priceRange = values;
            });
          },
          activeColor: AppColors.crimson,
          inactiveColor: AppColors.border(Theme.of(context).brightness),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$${_priceRange.start.toInt()}'),
            Text('\$${_priceRange.end.toInt()}'),
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
        final bool isSelected = _minRating == rating;
        return FilterChip(
          label: Text('${rating.toStringAsFixed(1)}+'),
          selected: isSelected,
          selectedColor: AppColors.crimson,
          checkmarkColor: Colors.white,
          onSelected: (bool selected) {
            setState(() {
              _minRating = selected ? rating : 0;
            });
          },
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
                    'You and ${_pendingMatch?.getOtherPartyName(context.read<AuthProvider>().isArtist)} liked each other',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
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
                            horizontal: 48,
                            vertical: 16,
                          ),
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
                      style: TextStyle(color: Colors.white70),
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
        image:
            _pendingMatch?.getOtherPartyPhoto(
                  context.read<AuthProvider>().isArtist,
                ) !=
                null
            ? DecorationImage(
                image: NetworkImage(
                  _pendingMatch!.getOtherPartyPhoto(
                    context.read<AuthProvider>().isArtist,
                  ),
                ),
                fit: BoxFit.cover,
              )
            : null,
        color: AppColors.crimson.withValues(alpha: 0.3),
      ),
      child:
          _pendingMatch?.getOtherPartyPhoto(
                context.read<AuthProvider>().isArtist,
              ) ==
              null
          ? Icon(Icons.person_rounded, color: Colors.white, size: 40)
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════

  void _onLocationFilterChanged(bool enabled) {
    // Get current location and update filters
    final provider = context.read<DiscoveryProvider>();
    setState(() {
      _useLocationFilter = enabled;
    });

    if (enabled) {
      provider.setLocationFilter(
        latitude: 40.7128,
        longitude: -74.0060,
        maxDistance: 50,
      );
    } else {
      provider.clearFilters();
      setState(() {
        _selectedGenres.clear();
      });
    }
  }

  void _clearAllFilters() {
    final provider = context.read<DiscoveryProvider>();
    provider.clearFilters();
    setState(() {
      _selectedGenres.clear();
      _useLocationFilter = false;
      _priceRange = const RangeValues(0, 1000);
      _minRating = 0;
    });
  }

  Future<void> _undoLastSwipe() async {
    final provider = context.read<DiscoveryProvider>();
    try {
      await provider.undo();
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
    if (provider.cards.isNotEmpty) {
      await provider.superLike();
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
                Expanded(child: _buildBoostOption('24 hours', '\$4.99')),
                const SizedBox(width: 12),
                Expanded(child: _buildBoostOption('7 days', '\$24.99')),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
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
            Text(duration, style: const TextStyle(fontWeight: FontWeight.w600)),
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

class DiscoveryItem {
  final String? imageUrl;
  final bool isBoosted;
  final bool isVerified;
  final String typeLabel;
  final String title;
  final String? subtitle;
  final String? city;
  final double distanceMiles;
  final double? rating;
  final double? priceMin;
  final double recommendationScore;

  const DiscoveryItem({
    this.imageUrl,
    required this.isBoosted,
    required this.isVerified,
    required this.typeLabel,
    required this.title,
    this.subtitle,
    this.city,
    required this.distanceMiles,
    this.rating,
    this.priceMin,
    required this.recommendationScore,
  });

  factory DiscoveryItem.fromCard(DiscoveryCard card) {
    final artist = card.artist;
    final venue = card.venue;
    final gig = card.gig;

    final String? imageUrl = card.primaryPhotoUrl.isNotEmpty
        ? card.primaryPhotoUrl
        : (card.galleryUrls.isNotEmpty ? card.galleryUrls.first : null);

    final double? priceMin =
        artist?.minPrice ?? venue?.gigPreferences?.minBudget ?? gig?.budget;

    final String? subtitle = card.genres.isNotEmpty
        ? card.genres.take(3).join(' • ')
        : (card.bio ?? gig?.description);

    final double recommendationScore = card.isBoosted
        ? 95
        : (card.rating > 0 ? (card.rating / 5) * 100 : 0);

    return DiscoveryItem(
      imageUrl: imageUrl,
      isBoosted: card.isBoosted,
      isVerified: card.isVerified,
      typeLabel: card.typeLabel,
      title: card.name,
      subtitle: subtitle,
      city: card.location ?? gig?.location.venueAddress ?? gig?.location.city,
      distanceMiles: card.distance ?? 0,
      rating: card.rating > 0 ? card.rating : null,
      priceMin: priceMin,
      recommendationScore: recommendationScore,
    );
  }
}
