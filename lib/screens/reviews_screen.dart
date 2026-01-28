/// ⭐ GIGMATCH Reviews Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass review cards
/// - Animated star ratings
/// - Pull-to-refresh with shimmer
/// - Sentiment analysis indicators
/// - Photo review gallery
/// - Reply functionality
///
/// View and manage all reviews - NOW WITH REAL API DATA
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/services/services.dart' as services;
import '../core/providers/providers.dart';
import '../widgets/widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ⭐ REVIEWS SCREEN - Main Widget
// ═══════════════════════════════════════════════════════════════════════════

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final services.ReviewService _reviewService = services.ReviewService();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  ReviewStats _stats = const ReviewStats(
    averageRating: 0,
    totalReviews: 0,
    fiveStarCount: 0,
    fourStarCount: 0,
    threeStarCount: 0,
    twoStarCount: 0,
    oneStarCount: 0,
    responseRate: 0,
    averageResponseTime: 'N/A',
  );

  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final auth = context.read<AuthProvider>();
      final userId = auth.artistProfile?.id ?? auth.venueProfile?.id;
      final isArtist = auth.isArtist;

      if (userId == null) {
        setState(() {
          _errorMessage = 'Please complete your profile first';
          _isLoading = false;
        });
        return;
      }

      // Fetch reviews and stats based on user role
      if (isArtist) {
        final reviewsResponse = await _reviewService.getArtistReviews(
          userId,
          limit: 50,
        );
        final statsResponse = await _reviewService.getArtistStats(userId);

        _mapReviewsAndStats(reviewsResponse, statsResponse);
      } else {
        final reviewsResponse = await _reviewService.getVenueReviews(
          userId,
          limit: 50,
        );
        final statsResponse = await _reviewService.getVenueStats(userId);

        _mapReviewsAndStats(reviewsResponse, statsResponse);
      }

      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load reviews. Please try again.';
        _isLoading = false;
      });
      debugPrint('Error loading reviews: $e');
    }
  }

  void _mapReviewsAndStats(
    services.ReviewsResponse reviewsResponse,
    services.ReviewStats statsResponse,
  ) {
    setState(() {
      // Map API reviews to local Review model
      _reviews = reviewsResponse.reviews.map((r) {
        final sentiment = _determineSentiment(r.overallRating.toDouble());
        return Review(
          id: r.id,
          authorName: r.reviewerName,
          authorImage: r.reviewerPhoto ?? '',
          rating: r.overallRating,
          date: r.createdAt,
          content: r.content,
          sentiment: sentiment,
          hasResponse: r.response != null,
          response: r.response,
          responseDate: r.responseDate,
          photos: r.photos,
          isVerified: r.isVerifiedBooking,
        );
      }).toList();

      // Map stats
      _stats = ReviewStats(
        averageRating: statsResponse.averageRating,
        totalReviews: statsResponse.totalReviews,
        fiveStarCount: statsResponse.ratingDistribution[5] ?? 0,
        fourStarCount: statsResponse.ratingDistribution[4] ?? 0,
        threeStarCount: statsResponse.ratingDistribution[3] ?? 0,
        twoStarCount: statsResponse.ratingDistribution[2] ?? 0,
        oneStarCount: statsResponse.ratingDistribution[1] ?? 0,
        responseRate: statsResponse.responseRate ?? 0.0,
        averageResponseTime: statsResponse.averageResponseTime ?? 'N/A',
      );

      _isLoading = false;
    });
  }

  ReviewSentiment _determineSentiment(double rating) {
    if (rating >= 4) return ReviewSentiment.positive;
    if (rating >= 3) return ReviewSentiment.neutral;
    return ReviewSentiment.negative;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    HapticFeedback.mediumImpact();
    await _loadReviews();
  }

  List<Review> get _filteredReviews {
    switch (_selectedFilter) {
      case '5':
        return _reviews.where((r) => r.rating == 5).toList();
      case '4':
        return _reviews.where((r) => r.rating == 4).toList();
      case '3':
        return _reviews.where((r) => r.rating == 3).toList();
      case '2':
        return _reviews.where((r) => r.rating == 2).toList();
      case '1':
        return _reviews.where((r) => r.rating == 1).toList();
      case 'unanswered':
        return _reviews.where((r) => !r.hasResponse).toList();
      default:
        return _reviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (_errorMessage != null && !_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background(brightness),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.text(brightness)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Reviews',
            style: TextStyle(color: AppColors.text(brightness)),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border_rounded,
                  size: 64,
                  color: AppColors.textSec(brightness),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSec(brightness),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadReviews,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // App Bar
            _buildAppBar(brightness),

            // Stats Card
            SliverToBoxAdapter(child: _buildStatsCard(brightness)),

            // Rating Breakdown
            SliverToBoxAdapter(child: _buildRatingBreakdown(brightness)),

            // Filter Chips
            SliverToBoxAdapter(child: _buildFilterChips(brightness)),

            // Reviews List
            _isLoading
                ? SliverToBoxAdapter(child: _ReviewSkeletonList())
                : _filteredReviews.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState(brightness))
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == _filteredReviews.length) {
                        return const SizedBox(height: 100);
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: _ReviewCard(
                          review: _filteredReviews[index],
                          brightness: brightness,
                          onReply: () => _showReplySheet(
                            _filteredReviews[index],
                            brightness,
                          ),
                        ),
                      );
                    }, childCount: _filteredReviews.length + 1),
                  ),
          ],
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
        'Reviews',
        style: AppTypography.headlineSmall.copyWith(
          color: AppColors.text(brightness),
        ),
      ),
      actions: [
        AnimatedTapFeedback(
          onTap: () => HapticFeedback.selectionClick(),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Icon(
              Icons.sort_rounded,
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
  // 📊 STATS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsCard(Brightness brightness) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade600, Colors.orange.shade700],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rating Circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _stats.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < _stats.averageRating.floor()
                            ? Icons.star_rounded
                            : (i < _stats.averageRating
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded),
                        color: Colors.white,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_stats.totalReviews} Reviews',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(_stats.responseRate * 100).toInt()}% response rate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Avg response: ${_stats.averageResponseTime}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 RATING BREAKDOWN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRatingBreakdown(Brightness brightness) {
    final max = [
      _stats.fiveStarCount,
      _stats.fourStarCount,
      _stats.threeStarCount,
      _stats.twoStarCount,
      _stats.oneStarCount,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Breakdown',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildRatingBar(5, _stats.fiveStarCount, max, brightness),
          _buildRatingBar(4, _stats.fourStarCount, max, brightness),
          _buildRatingBar(3, _stats.threeStarCount, max, brightness),
          _buildRatingBar(2, _stats.twoStarCount, max, brightness),
          _buildRatingBar(1, _stats.oneStarCount, max, brightness),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int max, Brightness brightness) {
    final percentage = max > 0 ? count / max : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$stars',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.border(brightness),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 13,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏷️ FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFilterChips(Brightness brightness) {
    final filters = [
      ('all', 'All'),
      ('5', '5 ⭐'),
      ('4', '4 ⭐'),
      ('3', '3 ⭐'),
      ('unanswered', 'Unanswered'),
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter.$1;

          return AnimatedTapFeedback(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = filter.$1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.crimson
                    : AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.border(brightness),
                ),
              ),
              child: Center(
                child: Text(
                  filter.$2,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Icon(
              Icons.star_outline_rounded,
              size: 48,
              color: AppColors.textTert(brightness),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews found',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different filter',
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
  // 💬 REPLY SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  void _showReplySheet(Review review, Brightness brightness) {
    HapticFeedback.mediumImpact();
    AppBottomSheet.show(
      context,
      isScrollControlled: true,
      child: _ReplySheet(
        review: review,
        brightness: brightness,
        onReplySuccess: () {
          // Refresh the reviews list after successful reply
          _loadReviews();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🃏 REVIEW CARD
// ═══════════════════════════════════════════════════════════════════════════

class _ReviewCard extends StatelessWidget {
  final Review review;
  final Brightness brightness;
  final VoidCallback onReply;

  const _ReviewCard({
    required this.review,
    required this.brightness,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
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
                    review.authorName.isNotEmpty
                        ? review.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.authorName,
                            style: TextStyle(
                              color: AppColors.text(brightness),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            color: AppColors.info,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(review.date),
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${review.rating}',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Text(
            review.content,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 14,
              height: 1.5,
            ),
          ),

          // Sentiment badge
          if (review.sentiment != ReviewSentiment.neutral) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: review.sentiment == ReviewSentiment.positive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    review.sentiment == ReviewSentiment.positive
                        ? Icons.sentiment_satisfied_alt_rounded
                        : Icons.sentiment_dissatisfied_rounded,
                    color: review.sentiment == ReviewSentiment.positive
                        ? AppColors.success
                        : AppColors.error,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    review.sentiment == ReviewSentiment.positive
                        ? 'Positive'
                        : 'Needs attention',
                    style: TextStyle(
                      color: review.sentiment == ReviewSentiment.positive
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Response
          if (review.hasResponse && review.response != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background(brightness),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        color: AppColors.crimson,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your response',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (review.responseDate != null)
                        Text(
                          _formatDate(review.responseDate!),
                          style: TextStyle(
                            color: AppColors.textTert(brightness),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.response!,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Reply button
          if (!review.hasResponse) ...[
            const SizedBox(height: 12),
            AnimatedTapFeedback(
              onTap: onReply,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.crimson),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      color: AppColors.crimson,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reply',
                      style: TextStyle(
                        color: AppColors.crimson,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💬 REPLY SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _ReplySheet extends StatefulWidget {
  final Review review;
  final Brightness brightness;
  final VoidCallback? onReplySuccess;

  const _ReplySheet({
    required this.review,
    required this.brightness,
    this.onReplySuccess,
  });

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  final _controller = TextEditingController();
  final services.ReviewService _reviewService = services.ReviewService();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await _reviewService.respondToReview(
        widget.review.id,
        _controller.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReplySuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const AnimatedSuccessCheck(size: 20, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Reply sent!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(widget.brightness),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(widget.brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reply to ${widget.review.authorName}',
                  style: TextStyle(
                    color: AppColors.text(widget.brightness),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                // Original review snippet
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background(widget.brightness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: AppColors.textTert(widget.brightness),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.review.content.length > 60
                              ? '${widget.review.content.substring(0, 60)}...'
                              : widget.review.content,
                          style: TextStyle(
                            color: AppColors.textSec(widget.brightness),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Reply input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background(widget.brightness),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border(widget.brightness),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    style: TextStyle(
                      color: AppColors.text(widget.brightness),
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Write a thoughtful reply...',
                      hintStyle: TextStyle(
                        color: AppColors.textTert(widget.brightness),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tips
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.textTert(widget.brightness),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tip: Be professional and thank them for their feedback',
                      style: TextStyle(
                        color: AppColors.textTert(widget.brightness),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Send button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendReply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Send Reply',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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
// 💀 SKELETON
// ═══════════════════════════════════════════════════════════════════════════

class _ReviewSkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBase(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.skeleton(brightness),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBase(
                          child: Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.skeleton(brightness),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ShimmerBase(
                          child: Container(
                            height: 10,
                            width: 80,
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
              const SizedBox(height: 12),
              ShimmerBase(
                child: Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.skeleton(brightness),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ShimmerBase(
                child: Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.skeleton(brightness),
                    borderRadius: BorderRadius.circular(4),
                  ),
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
// 📦 DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final double responseRate;
  final String averageResponseTime;

  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
    required this.responseRate,
    required this.averageResponseTime,
  });
}

enum ReviewSentiment { positive, neutral, negative }

class Review {
  final String id;
  final String authorName;
  final String authorImage;
  final int rating;
  final DateTime date;
  final String content;
  final ReviewSentiment sentiment;
  final bool hasResponse;
  final String? response;
  final DateTime? responseDate;
  final List<String> photos;
  final bool isVerified;

  const Review({
    required this.id,
    required this.authorName,
    required this.authorImage,
    required this.rating,
    required this.date,
    required this.content,
    required this.sentiment,
    required this.hasResponse,
    this.response,
    this.responseDate,
    required this.photos,
    required this.isVerified,
  });
}
