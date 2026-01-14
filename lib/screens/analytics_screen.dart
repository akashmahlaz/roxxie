/// 📊 Analytics & Insights Screen — Enterprise Edition
///
/// 2026 Design Principles Applied:
/// - Animated chart visualizations
/// - Liquid Glass stat cards with gradients
/// - Interactive time period selector
/// - Pull-down details on tap
/// - Trend indicators with micro-animations
/// - Skeleton loading during data fetch
/// - Role-based metrics (Artist vs Venue)
///
/// Comprehensive analytics dashboard
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

enum TimePeriod { week, month, quarter, year }

class AnalyticsScreen extends StatefulWidget {
  final bool isArtist;

  const AnalyticsScreen({super.key, this.isArtist = true});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  TimePeriod _selectedPeriod = TimePeriod.month;
  bool _isLoading = true;
  late AnimationController _chartController;
  late AnimationController _countController;
  
  // Analytics data
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadAnalytics();
  }

  @override
  void dispose() {
    _chartController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    // Reset animations
    _chartController.reset();
    _countController.reset();
    
    await Future.delayed(const Duration(milliseconds: 900));
    
    // Mock data based on role
    setState(() {
      _analytics = widget.isArtist ? _getArtistAnalytics() : _getVenueAnalytics();
      _isLoading = false;
    });
    
    // Start animations
    _countController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _chartController.forward();
    });
  }

  Map<String, dynamic> _getArtistAnalytics() {
    return {
      'profileViews': 1247,
      'profileViewsTrend': 12.5,
      'swipeRights': 89,
      'swipeRightsTrend': 8.2,
      'matches': 34,
      'matchesTrend': 15.7,
      'gigsBooked': 8,
      'gigsBookedTrend': -5.3,
      'earnings': 3850,
      'earningsTrend': 22.1,
      'responseRate': 98,
      'avgResponseTime': '< 1 hr',
      'weeklyViews': [45, 62, 38, 75, 92, 84, 67],
      'topGenres': [
        {'name': 'Jazz', 'count': 42, 'percent': 38},
        {'name': 'Soul', 'count': 28, 'percent': 25},
        {'name': 'R&B', 'count': 21, 'percent': 19},
        {'name': 'Funk', 'count': 12, 'percent': 11},
        {'name': 'Blues', 'count': 8, 'percent': 7},
      ],
      'peakHours': [18, 19, 20, 21, 22],
      'venueTypes': [
        {'name': 'Jazz Clubs', 'percent': 45},
        {'name': 'Restaurants', 'percent': 30},
        {'name': 'Private Events', 'percent': 15},
        {'name': 'Festivals', 'percent': 10},
      ],
    };
  }

  Map<String, dynamic> _getVenueAnalytics() {
    return {
      'gigPosts': 12,
      'gigPostsTrend': 25.0,
      'applications': 156,
      'applicationsTrend': 18.3,
      'bookings': 8,
      'bookingsTrend': 33.3,
      'avgApplications': 13,
      'avgApplicationsTrend': 5.2,
      'totalSpent': 4200,
      'totalSpentTrend': 15.8,
      'responseRate': 95,
      'avgResponseTime': '< 2 hrs',
      'weeklyApplications': [12, 18, 22, 15, 28, 35, 26],
      'topGenres': [
        {'name': 'Jazz', 'count': 45, 'percent': 35},
        {'name': 'Rock', 'count': 32, 'percent': 25},
        {'name': 'Acoustic', 'count': 26, 'percent': 20},
        {'name': 'Blues', 'count': 15, 'percent': 12},
        {'name': 'Pop', 'count': 10, 'percent': 8},
      ],
      'peakDays': ['Friday', 'Saturday', 'Thursday'],
      'artistRatings': [
        {'stars': 5, 'percent': 65},
        {'stars': 4, 'percent': 28},
        {'stars': 3, 'percent': 5},
        {'stars': 2, 'percent': 2},
        {'stars': 1, 'percent': 0},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: _isLoading
          ? _buildSkeleton(brightness)
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: AppColors.crimson,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(brightness),
                    const SizedBox(height: 24),
                    _buildMainStats(brightness),
                    const SizedBox(height: 24),
                    _buildChart(brightness),
                    const SizedBox(height: 24),
                    _buildSecondaryStats(brightness),
                    const SizedBox(height: 24),
                    _buildGenreBreakdown(brightness),
                    const SizedBox(height: 24),
                    _buildInsights(brightness),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
    return AppBar(
      backgroundColor: AppColors.surface(brightness),
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(brightness)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Analytics',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share_rounded, color: AppColors.text(brightness)),
          onPressed: () => HapticFeedback.lightImpact(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSkeleton(Brightness brightness) {
    return ShimmerBase(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Row(
        children: TimePeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: AnimatedTapFeedback(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPeriod = period);
                  _loadAnalytics();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.crimson : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _periodLabel(period),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSec(brightness),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _periodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.week:
        return '7 Days';
      case TimePeriod.month:
        return '30 Days';
      case TimePeriod.quarter:
        return '90 Days';
      case TimePeriod.year:
        return 'Year';
    }
  }

  Widget _buildMainStats(Brightness brightness) {
    if (widget.isArtist) {
      return Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.visibility_rounded,
              label: 'Profile Views',
              value: _analytics['profileViews'] ?? 0,
              trend: _analytics['profileViewsTrend'] ?? 0,
              color: AppColors.crimson,
              controller: _countController,
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.favorite_rounded,
              label: 'Matches',
              value: _analytics['matches'] ?? 0,
              trend: _analytics['matchesTrend'] ?? 0,
              color: AppColors.success,
              controller: _countController,
              brightness: brightness,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.inbox_rounded,
              label: 'Applications',
              value: _analytics['applications'] ?? 0,
              trend: _analytics['applicationsTrend'] ?? 0,
              color: AppColors.info,
              controller: _countController,
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_rounded,
              label: 'Bookings',
              value: _analytics['bookings'] ?? 0,
              trend: _analytics['bookingsTrend'] ?? 0,
              color: AppColors.success,
              controller: _countController,
              brightness: brightness,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildChart(Brightness brightness) {
    final data = widget.isArtist
        ? _analytics['weeklyViews'] as List<dynamic>? ?? []
        : _analytics['weeklyApplications'] as List<dynamic>? ?? [];

    return LiquidGlassContainer(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.isArtist ? 'Profile Views' : 'Applications',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '+${(widget.isArtist ? _analytics['profileViewsTrend'] : _analytics['applicationsTrend'])?.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: AnimatedBuilder(
                animation: _chartController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(double.infinity, 150),
                    painter: _ChartPainter(
                      data: data.map((e) => (e as num).toDouble()).toList(),
                      progress: _chartController.value,
                      color: AppColors.crimson,
                      brightness: brightness,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => Text(
                        day,
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 11,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryStats(Brightness brightness) {
    if (widget.isArtist) {
      return Row(
        children: [
          Expanded(
            child: _MiniStatCard(
              icon: Icons.thumb_up_rounded,
              label: 'Swipe Rights',
              value: '${_analytics['swipeRights']}',
              color: AppColors.info,
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStatCard(
              icon: Icons.event_available_rounded,
              label: 'Gigs Booked',
              value: '${_analytics['gigsBooked']}',
              color: AppColors.warning,
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStatCard(
              icon: Icons.attach_money_rounded,
              label: 'Earnings',
              value: '\$${_analytics['earnings']}',
              color: AppColors.success,
              brightness: brightness,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _MiniStatCard(
              icon: Icons.post_add_rounded,
              label: 'Gigs Posted',
              value: '${_analytics['gigPosts']}',
              color: AppColors.crimson,
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStatCard(
              icon: Icons.people_rounded,
              label: 'Avg. Apps',
              value: '${_analytics['avgApplications']}/gig',
              color: AppColors.info,
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStatCard(
              icon: Icons.payments_rounded,
              label: 'Total Spent',
              value: '\$${_analytics['totalSpent']}',
              color: AppColors.success,
              brightness: brightness,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildGenreBreakdown(Brightness brightness) {
    final genres = _analytics['topGenres'] as List<dynamic>? ?? [];

    return LiquidGlassContainer(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isArtist ? 'Venue Genre Interest' : 'Artist Genre Mix',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...genres.map((genre) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GenreBar(
                name: genre['name'] as String,
                percent: genre['percent'] as int,
                controller: _chartController,
                brightness: brightness,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.lightbulb_rounded,
          title: widget.isArtist
              ? 'Peak Activity Hours'
              : 'Best Posting Days',
          description: widget.isArtist
              ? 'Your profile gets the most views between 6-10 PM. Consider updating your bio during these hours.'
              : 'Friday and Saturday gigs get 45% more applications. Post early in the week for best results.',
          color: AppColors.warning,
          brightness: brightness,
        ),
        const SizedBox(height: 10),
        _InsightCard(
          icon: Icons.trending_up_rounded,
          title: widget.isArtist
              ? 'Genre Demand'
              : 'Popular Genres',
          description: widget.isArtist
              ? 'Jazz venues in your area are up 23% this month. Great time to highlight your jazz experience!'
              : 'Jazz and Acoustic artists are trending. Consider more gigs in these genres.',
          color: AppColors.success,
          brightness: brightness,
        ),
        const SizedBox(height: 10),
        _InsightCard(
          icon: Icons.flash_on_rounded,
          title: 'Quick Tip',
          description: widget.isArtist
              ? 'Artists with video portfolios get 3x more matches. Add a performance clip to boost visibility!'
              : 'Gigs with clear payment info get 2x more quality applications.',
          color: AppColors.crimson,
          brightness: brightness,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final double trend;
  final Color color;
  final AnimationController controller;
  final Brightness brightness;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
    required this.controller,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = trend >= 0;

    return LiquidGlassContainer(
      borderRadius: 18,
      tintColor: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isPositive ? AppColors.success : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final animatedValue = (value * controller.value).round();
                return AnimatedCounter(
                  value: animatedValue,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Brightness brightness;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GenreBar extends StatelessWidget {
  final String name;
  final int percent;
  final AnimationController controller;
  final Brightness brightness;

  const _GenreBar({
    required this.name,
    required this.percent,
    required this.controller,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return LinearProgressIndicator(
                value: (percent / 100) * controller.value,
                backgroundColor: AppColors.border(brightness),
                valueColor: AlwaysStoppedAnimation(AppColors.crimson),
                minHeight: 6,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Brightness brightness;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHART PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color color;
  final Brightness brightness;

  _ChartPainter({
    required this.data,
    required this.progress,
    required this.color,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final pointWidth = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final normalizedValue = range == 0 ? 0.5 : (data[i] - minValue) / range;
      final x = i * pointWidth;
      final y = size.height - (normalizedValue * size.height * 0.8 + size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Smooth curve using cubic bezier
        final prevX = (i - 1) * pointWidth;
        final prevNormalized = range == 0 ? 0.5 : (data[i - 1] - minValue) / range;
        final prevY = size.height - (prevNormalized * size.height * 0.8 + size.height * 0.1);
        
        final controlX1 = prevX + (x - prevX) / 2;
        final controlX2 = prevX + (x - prevX) / 2;
        
        path.cubicTo(controlX1, prevY, controlX2, y, x, y);
        fillPath.cubicTo(controlX1, prevY, controlX2, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Animate the path
    final animatedPath = _extractPathSegment(path, progress);
    final animatedFillPath = _extractPathSegment(fillPath, progress);

    // Draw gradient fill
    canvas.drawPath(animatedFillPath, gradientPaint);
    
    // Draw line
    canvas.drawPath(animatedPath, paint);

    // Draw dots
    final dotPaint = Paint()..color = color;
    final dotOutlinePaint = Paint()
      ..color = brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < data.length; i++) {
      if (i / (data.length - 1) <= progress) {
        final normalizedValue = range == 0 ? 0.5 : (data[i] - minValue) / range;
        final x = i * pointWidth;
        final y = size.height - (normalizedValue * size.height * 0.8 + size.height * 0.1);
        
        canvas.drawCircle(Offset(x, y), 5, dotOutlinePaint);
        canvas.drawCircle(Offset(x, y), 4, dotPaint);
      }
    }
  }

  Path _extractPathSegment(Path path, double progress) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return Path();

    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final targetLength = totalLength * progress;

    final newPath = Path();
    var currentLength = 0.0;

    for (final metric in metrics) {
      if (currentLength + metric.length <= targetLength) {
        newPath.addPath(metric.extractPath(0, metric.length), Offset.zero);
        currentLength += metric.length;
      } else {
        final remaining = targetLength - currentLength;
        if (remaining > 0) {
          newPath.addPath(metric.extractPath(0, remaining), Offset.zero);
        }
        break;
      }
    }

    return newPath;
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}
