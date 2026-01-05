/// 🎯 GIGMATCH Discovery Screen
/// Tinder-like swipe cards for finding gigs

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../widgets/widgets.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _matchController;
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _matchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Load cards on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryProvider>().loadCards(refresh: true);
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _matchController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx / 300 * 0.4; // Max 0.4 radians rotation
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.velocity.pixelsPerSecond;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_dragOffset.dx.abs() > screenWidth * 0.4 || velocity.dx.abs() > 800) {
      // Swipe action
      if (_dragOffset.dx > 0) {
        _animateSwipe(true); // Like
      } else {
        _animateSwipe(false); // Pass
      }
    } else {
      // Return to center
      _animateReturn();
    }
  }

  Future<void> _animateSwipe(bool isLike) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isLike ? screenWidth * 1.5 : -screenWidth * 1.5;

    final startOffset = _dragOffset;
    final startAngle = _dragAngle;

    _cardController.reset();
    _cardController.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(
          startOffset,
          Offset(targetX, startOffset.dy + 100),
          _cardController.value,
        )!;
        _dragAngle = startAngle + (isLike ? 0.3 : -0.3) * _cardController.value;
      });
    });

    await _cardController.forward();

    // Perform swipe action
    final provider = context.read<DiscoveryProvider>();
    bool isMatch = false;

    if (isLike) {
      isMatch = await provider.like();
    } else {
      await provider.pass();
    }

    // Reset for next card
    setState(() {
      _dragOffset = Offset.zero;
      _dragAngle = 0;
    });

    // Show match animation if matched
    if (isMatch && provider.lastMatch != null) {
      _showMatchDialog(provider.lastMatch!);
    }
  }

  void _animateReturn() {
    final startOffset = _dragOffset;
    final startAngle = _dragAngle;

    _cardController.reset();
    _cardController.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(
          startOffset,
          Offset.zero,
          _cardController.value,
        )!;
        _dragAngle = startAngle * (1 - _cardController.value);
      });
    });
    _cardController.forward();
  }

  void _onLikePressed() {
    setState(() {
      _dragOffset = const Offset(50, 0);
      _dragAngle = 0.1;
    });
    _animateSwipe(true);
  }

  void _onPassPressed() {
    setState(() {
      _dragOffset = const Offset(-50, 0);
      _dragAngle = -0.1;
    });
    _animateSwipe(false);
  }

  Future<void> _onSuperLikePressed() async {
    final provider = context.read<DiscoveryProvider>();
    final isMatch = await provider.superLike();

    if (isMatch && provider.lastMatch != null) {
      _showMatchDialog(provider.lastMatch!);
    }
  }

  void _showMatchDialog(Match match) {
    final authProvider = context.read<AuthProvider>();
    final isArtist = authProvider.isArtist;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MatchDialog(
        match: match,
        isCurrentUserArtist: isArtist,
        onSendMessage: () {
          Navigator.pop(context);
          // Navigate to chat
          Navigator.pushNamed(context, '/chat', arguments: match.id);
        },
        onKeepSwiping: () {
          Navigator.pop(context);
          context.read<DiscoveryProvider>().clearLastMatch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: SafeArea(
        child: Consumer<DiscoveryProvider>(
          builder: (context, provider, child) {
            if (provider.status == DiscoveryStatus.loading &&
                !provider.hasCards) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.crimson),
              );
            }

            if (provider.status == DiscoveryStatus.empty) {
              return _buildEmptyState();
            }

            if (provider.status == DiscoveryStatus.error) {
              return _buildErrorState(provider.errorMessage);
            }

            return Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildCardStack(provider)),
                _buildActionButtons(provider),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Profile button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.slate),
              ),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final photoUrl = auth.user?.profilePhotoUrl;
                  if (photoUrl != null && photoUrl.isNotEmpty) {
                    return ClipOval(
                      child: Image.network(photoUrl, fit: BoxFit.cover),
                    );
                  }
                  return const Icon(Icons.person, color: AppColors.mediumGray);
                },
              ),
            ),
          ),
          const Spacer(),
          // Logo
          Text(
            'GigMatch',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.crimson,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Filters
          GestureDetector(
            onTap: () => _showFilters(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.slate),
              ),
              child: const Icon(
                Icons.tune,
                color: AppColors.mediumGray,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(DiscoveryProvider provider) {
    if (!provider.hasCards) {
      return _buildEmptyState();
    }

    final cards = provider.cards;
    final currentIndex = provider.currentIndex;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background cards (max 2)
        for (
          int i = math.min(currentIndex + 2, cards.length - 1);
          i > currentIndex;
          i--
        )
          Positioned(
            top: 20.0 * (i - currentIndex),
            child: Transform.scale(
              scale: 1.0 - 0.05 * (i - currentIndex),
              child: Opacity(
                opacity: 1.0 - 0.3 * (i - currentIndex),
                child: _buildCard(cards[i], isInteractive: false),
              ),
            ),
          ),

        // Current card (interactive)
        if (currentIndex < cards.length)
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: _dragAngle,
                child: _buildCard(
                  cards[currentIndex],
                  isInteractive: true,
                  swipeProgress: _dragOffset.dx / 200,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(
    DiscoveryCard card, {
    bool isInteractive = false,
    double swipeProgress = 0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 40;
    final cardHeight = cardWidth * 1.4;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (card.primaryPhotoUrl.isNotEmpty)
              Image.network(
                card.primaryPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.charcoal,
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: AppColors.mediumGray,
                  ),
                ),
              )
            else
              Container(
                color: AppColors.charcoal,
                child: Icon(
                  card.isArtist ? Icons.music_note : Icons.business,
                  size: 80,
                  color: AppColors.mediumGray,
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
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Like/Nope stamps
            if (isInteractive && swipeProgress.abs() > 0.3) ...[
              Positioned(
                top: 40,
                left: swipeProgress > 0 ? 20 : null,
                right: swipeProgress < 0 ? 20 : null,
                child: Transform.rotate(
                  angle: swipeProgress > 0 ? -0.3 : 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: swipeProgress > 0
                            ? Colors.green
                            : AppColors.crimson,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      swipeProgress > 0 ? 'LIKE' : 'NOPE',
                      style: TextStyle(
                        color: swipeProgress > 0
                            ? Colors.green
                            : AppColors.crimson,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: card.isArtist
                            ? AppColors.crimson
                            : AppColors.wine,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        card.typeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            card.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (card.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                      ],
                    ),

                    // Location & Distance
                    if (card.location != null || card.distance != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              [
                                    if (card.location != null) card.location,
                                    if (card.distance != null)
                                      card.distanceLabel,
                                  ]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join(' • '),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Genres
                    if (card.genres.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: card.genres.take(3).map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                genre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Rating
                    if (card.rating > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${card.rating.toStringAsFixed(1)} (${card.reviewCount})',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Boosted badge
            if (card.isBoosted)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(DiscoveryProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo button
          _ActionButton(
            icon: Icons.replay,
            size: 50,
            color: Colors.amber,
            onPressed: () async {
              final success = await provider.undo();
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium feature')),
                );
              }
            },
          ),

          // Pass button
          _ActionButton(
            icon: Icons.close,
            size: 60,
            color: AppColors.crimson,
            onPressed: provider.hasCards ? _onPassPressed : null,
          ),

          // Super like button
          _ActionButton(
            icon: Icons.star,
            size: 50,
            color: Colors.blue,
            onPressed: provider.hasCards ? _onSuperLikePressed : null,
          ),

          // Like button
          _ActionButton(
            icon: Icons.favorite,
            size: 60,
            color: Colors.green,
            onPressed: provider.hasCards ? _onLikePressed : null,
          ),

          // Boost button
          _ActionButton(
            icon: Icons.bolt,
            size: 50,
            color: Colors.purple,
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Premium feature')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.mediumGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No more profiles',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.offWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new matches',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Expand Search',
            onPressed: _showFilters,
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.crimson.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text(
            message ?? 'Something went wrong',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Try Again',
            onPressed: () {
              context.read<DiscoveryProvider>().loadCards(refresh: true);
            },
            width: 160,
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _FiltersSheet(),
    );
  }
}

/// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.size,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.charcoal,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}

/// Match Dialog Widget
class _MatchDialog extends StatelessWidget {
  final Match match;
  final bool isCurrentUserArtist;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepSwiping;

  const _MatchDialog({
    required this.match,
    required this.isCurrentUserArtist,
    required this.onSendMessage,
    required this.onKeepSwiping,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = match.getOtherPartyName(isCurrentUserArtist);
    final otherPhoto = match.getOtherPartyPhoto(isCurrentUserArtist);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation area
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.crimson, width: 3),
                image: otherPhoto.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(otherPhoto),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: otherPhoto.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.mediumGray,
                    )
                  : null,
            ),
            const SizedBox(height: 20),

            // Title
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                "It's a Match!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'You and $otherName liked each other!',
              style: const TextStyle(color: AppColors.mediumGray, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Actions
            GradientButton(
              text: 'Send a Message',
              onPressed: onSendMessage,
              icon: Icons.message,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onKeepSwiping,
              child: const Text(
                'Keep Swiping',
                style: TextStyle(color: AppColors.mediumGray, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filters Sheet Widget
class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  double _maxDistance = 50;
  List<String> _selectedGenres = [];

  final List<String> _genres = [
    'Rock',
    'Jazz',
    'Blues',
    'Pop',
    'Hip Hop',
    'R&B',
    'Country',
    'Electronic',
    'Classical',
    'Folk',
    'Metal',
    'Indie',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
                color: AppColors.slate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Search Filters',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.offWhite,
            ),
          ),
          const SizedBox(height: 24),

          // Distance
          Text(
            'Maximum Distance: ${_maxDistance.round()} miles',
            style: const TextStyle(color: AppColors.offWhite, fontSize: 16),
          ),
          Slider(
            value: _maxDistance,
            min: 5,
            max: 200,
            activeColor: AppColors.crimson,
            inactiveColor: AppColors.slate,
            onChanged: (value) => setState(() => _maxDistance = value),
          ),
          const SizedBox(height: 20),

          // Genres
          const Text(
            'Genres',
            style: TextStyle(color: AppColors.offWhite, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genres.map((genre) {
              final isSelected = _selectedGenres.contains(genre);
              return FilterChip(
                label: Text(genre),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedGenres.add(genre);
                    } else {
                      _selectedGenres.remove(genre);
                    }
                  });
                },
                selectedColor: AppColors.crimson,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.offWhite,
                ),
                backgroundColor: AppColors.graphite,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Apply button
          GradientButton(
            text: 'Apply Filters',
            onPressed: () {
              final provider = context.read<DiscoveryProvider>();
              if (_selectedGenres.isNotEmpty) {
                provider.setGenreFilter(_selectedGenres);
              }
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                context.read<DiscoveryProvider>().clearFilters();
                Navigator.pop(context);
              },
              child: const Text(
                'Clear Filters',
                style: TextStyle(color: AppColors.mediumGray),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
