/// 🎯 GIGMATCH Discovery Screen — Red & White Bento Design
///
/// Tinder-style swipe cards for discovering gigs (artists) or artists (venues).
/// Matching the calendar's crimson + white bento design language.
///
/// Features:
/// - Gesture-driven card swipe with physics
/// - 3-card visual stack with scale + offset
/// - Match celebration overlay
/// - Filter drawer (genre, location, price, rating, passport)
/// - Super Like / Undo / Boost (Pro)
/// - Server-side recommendation score badge
/// - Image prefetch for buttery scrolling
library;

import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/exceptions.dart';
import '../core/models/models.dart';
import '../core/providers/providers.dart';
import '../core/services/location_service.dart';
import '../core/services/chat_manager.dart';
import '../core/theme/theme.dart';

import 'chat_screen_v2.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _cardCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final AnimationController _matchCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _filterCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  // ── Swipe state ──────────────────────────────────────────────────────────
  Offset _drag = Offset.zero;
  double _angle = 0;
  bool _dragging = false;

  // ── UI state ─────────────────────────────────────────────────────────────
  bool _showFilters = false;
  bool _showMatch = false;
  Match? _pendingMatch;

  // ── Filter state ─────────────────────────────────────────────────────────
  final Set<String> _selectedGenres = {};
  bool _useLocation = false;
  RangeValues _priceRange = const RangeValues(0, 2000);
  double _minRating = 0;
  static const double _maxPrice = 2000;

  static const List<String> _genres = [
    'Rock', 'Jazz', 'Pop', 'Hip-Hop', 'Electronic', 'Blues',
    'Country', 'R&B', 'Classical', 'Metal', 'Folk', 'Indie',
    'Soul', 'Funk', 'Reggae', 'Latin', 'Acoustic',
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeed());
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _matchCtrl.dispose();
    _filterCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadFeed() async {
    final provider = context.read<DiscoveryProvider>();
    final auth = context.read<AuthProvider>();
    provider.setUserRole(auth.isArtist);
    debugPrint('🎯 [Discovery] Loading feed — isArtist: ${auth.isArtist}');
    await provider.loadCards(refresh: true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SWIPE GESTURES
  // ═══════════════════════════════════════════════════════════════════════════

  void _onPanStart(DragStartDetails _) {
    setState(() => _dragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_dragging) { return; }
    setState(() {
      _drag += d.delta;
      _angle = _drag.dx / 300 * 0.5;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_dragging) { return; }
    setState(() => _dragging = false);

    final w = MediaQuery.of(context).size.width;
    final vel = d.velocity.pixelsPerSecond;
    final thresh = w * 0.35;

    if (_drag.dx.abs() > thresh || vel.dx.abs() > 800) {
      _animateSwipe(_drag.dx > 0);
    } else {
      _animateReturn();
    }
  }

  Future<void> _animateSwipe(bool isLike) async {
    final w = MediaQuery.of(context).size.width;
    final targetX = isLike ? w * 1.3 : -w * 1.3;

    final provider = context.read<DiscoveryProvider>();
    if (provider.cards.isEmpty) { return; }

    final startDrag = _drag;
    final startAngle = _angle;

    void tick() {
      final t = Curves.easeOutCubic.transform(_cardCtrl.value);
      setState(() {
        _drag = Offset.lerp(startDrag, Offset(targetX, startDrag.dy + 100), t)!;
        _angle = startAngle + (isLike ? 0.3 : -0.3) * t;
      });
    }

    _cardCtrl.addListener(tick);
    await _cardCtrl.forward(from: 0);
    _cardCtrl.removeListener(tick);

    // Perform API action
    try {
      bool isMatch = false;
      if (isLike) {
        isMatch = await provider.like();
      } else {
        await provider.pass();
      }
      debugPrint('🎯 [Discovery] Swipe ${isLike ? "LIKE" : "PASS"} — match: $isMatch');
      if (isMatch && provider.lastMatch != null) {
        _pendingMatch = provider.lastMatch;
        _openMatchOverlay();
      }
    } catch (e) {
      debugPrint('⚠️ [Discovery] Swipe error: $e');
      _snack(e.toString(), isError: true);
    }

    setState(() {
      _drag = Offset.zero;
      _angle = 0;
    });
    _cardCtrl.reset();

    if (provider.remainingCards <= 3) {
      provider.loadCards();
    }
  }

  Future<void> _animateReturn() async {
    final startDrag = _drag;
    final startAngle = _angle;

    void tick() {
      final t = Curves.easeOutCubic.transform(_cardCtrl.value);
      setState(() {
        _drag = Offset.lerp(startDrag, Offset.zero, t)!;
        _angle = startAngle * (1 - t);
      });
    }

    _cardCtrl.addListener(tick);
    await _cardCtrl.forward(from: 0);
    _cardCtrl.removeListener(tick);

    setState(() {
      _drag = Offset.zero;
      _angle = 0;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS (Super Like, Undo, Boost)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _superLike() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isPaidUser) {
      _premiumUpsell('Super Likes', 'Stand out and get noticed. Upgrade to Pro!');
      return;
    }

    final provider = context.read<DiscoveryProvider>();
    if (provider.cards.isEmpty) { return; }

    HapticFeedback.mediumImpact();

    try {
      final isMatch = await provider.superLike();
      debugPrint('🎯 [Discovery] Super like — match: $isMatch');
      if (isMatch && provider.lastMatch != null) {
        _pendingMatch = provider.lastMatch;
        _openMatchOverlay();
      } else {
        _snack("Super liked! They'll be notified.", icon: Icons.star_rounded);
      }
    } catch (e) {
      debugPrint('⚠️ [Discovery] Super like error: $e');
      _snack('Failed to super like.', isError: true);
    }
  }

  Future<void> _undo() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isPaidUser) {
      _premiumUpsell('Unlimited Rewinds', 'Go back and change your last swipe with Pro.');
      return;
    }

    final provider = context.read<DiscoveryProvider>();

    try {
      final ok = await provider.undo();
      debugPrint('🎯 [Discovery] Undo — success: $ok');
      if (ok) {
        _snack('Swipe undone', icon: Icons.undo_rounded);
      } else {
        _snack('Nothing to undo', isError: true);
      }
    } catch (e) {
      debugPrint('⚠️ [Discovery] Undo error: $e');
      _snack('Failed to undo.', isError: true);
    }
  }

  void _showBoostDialog() {
    final auth = context.read<AuthProvider>();
    if (!auth.isPaidUser) {
      _premiumUpsell('Profile Boost', 'Get 10x more views! Upgrade to Pro to use boosts.');
      return;
    }

    final br = Theme.of(context).brightness;
    final isDark = br == Brightness.dark;
    String? selected;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.charcoal : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Boost Your Profile',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: AppColors.text(br),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Appear at the top of discovery for more bookings.',
                  style: TextStyle(color: AppColors.textSec(br), fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _boostOption('24', '24 hours', '\$4.99', selected, (v) => setDlg(() => selected = v), br, isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _boostOption('7', '7 days', '\$24.99', selected, (v) => setDlg(() => selected = v), br, isDark)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: AppColors.textSec(br))),
              ),
              GestureDetector(
                onTap: selected == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _processBoost(selected!);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected != null
                        ? (isDark ? Colors.white : AppColors.crimson)
                        : AppColors.textSec(br).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Boost Now',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: selected != null
                          ? (isDark ? AppColors.crimson : Colors.white)
                          : AppColors.textSec(br),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _boostOption(String val, String dur, String price, String? selected, ValueChanged<String> onTap, Brightness br, bool isDark) {
    final isSel = selected == val;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(val);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSel
              ? AppColors.crimson.withValues(alpha: isDark ? 0.15 : 0.06)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F8F8)),
          border: Border.all(
            color: isSel ? AppColors.crimson : AppColors.border(br),
            width: isSel ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(Icons.rocket_launch_rounded, color: isSel ? AppColors.crimson : AppColors.crimson.withValues(alpha: 0.4), size: 26),
            const SizedBox(height: 8),
            Text(dur, style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, color: AppColors.text(br), fontSize: 13)),
            const SizedBox(height: 2),
            Text(price, style: TextStyle(fontFamily: 'Satoshi', color: AppColors.crimson, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Future<void> _processBoost(String duration) async {
    const durations = {'24': '24 hours', '7': '7 days'};
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        const SizedBox(width: 12),
        const Text('Processing boost...'),
      ]),
      backgroundColor: AppColors.crimson,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));

    // Simulated — real implementation would call SubscriptionService
    await Future.delayed(const Duration(seconds: 1));

    messenger.hideCurrentSnackBar();
    _snack('Boost activated for ${durations[duration]}!', icon: Icons.check_circle_rounded);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATCH OVERLAY
  // ═══════════════════════════════════════════════════════════════════════════

  void _openMatchOverlay() {
    if (_pendingMatch == null) { return; }
    debugPrint('🎯 [Discovery] Match overlay opened');
    setState(() => _showMatch = true);
    _matchCtrl.forward(from: 0);
  }

  void _closeMatchOverlay() {
    _matchCtrl.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showMatch = false;
          _pendingMatch = null;
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterCtrl.forward();
    } else {
      _filterCtrl.reverse();
    }
  }

  void _toggleGenre(String g, bool on) {
    setState(() {
      if (on) { _selectedGenres.add(g); } else { _selectedGenres.remove(g); }
    });
    context.read<DiscoveryProvider>().setGenreFilter(_selectedGenres.toList());
  }

  void _toggleLocation(bool on) async {
    final provider = context.read<DiscoveryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _useLocation = on);

    if (!on) {
      provider.clearLocationFilter();
      return;
    }

    try {
      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 12),
          const Text('Getting your location...'),
        ]),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));

      final pos = await LocationService().getCurrentLocation();
      provider.setLocationFilter(latitude: pos.latitude, longitude: pos.longitude, radiusMiles: 50);

      messenger.hideCurrentSnackBar();
      _snack('Showing within 50 miles', icon: Icons.location_on_rounded);
    } catch (e) {
      setState(() => _useLocation = false);
      provider.clearLocationFilter();
      messenger.hideCurrentSnackBar();

      String msg = 'Could not get your location';
      if (e is PermissionException) {
        msg = 'Location permission denied. Enable in Settings.';
      } else if (e is ServiceDisabledException) {
        msg = 'Location services are disabled.';
      }
      _snack(msg, isError: true);
    }
  }

  void _clearAllFilters() {
    context.read<DiscoveryProvider>().clearFilters();
    setState(() {
      _selectedGenres.clear();
      _useLocation = false;
      _priceRange = const RangeValues(0, _maxPrice);
      _minRating = 0;
    });
  }

  void _applyFilters() {
    final provider = context.read<DiscoveryProvider>();
    provider.setPriceAndRatingFilters(
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < _maxPrice ? _priceRange.end : null,
      minRating: _minRating > 0 ? _minRating : null,
    );
    _toggleFilters();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  void _snack(String msg, {IconData? icon, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 12)],
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      action: isError
          ? SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _loadFeed)
          : null,
    ));
  }

  void _premiumUpsell(String feature, String message) {
    final br = Theme.of(context).brightness;
    final isDark = br == Brightness.dark;
    final nav = Navigator.of(context, rootNavigator: true);
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.charcoal : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: AppColors.text(br),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ]),
        content: Text(
          message,
          style: TextStyle(color: AppColors.textSec(br), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later', style: TextStyle(color: AppColors.textSec(br))),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              nav.pushNamed('/premium');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : AppColors.crimson,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.diamond_rounded, size: 16, color: isDark ? AppColors.crimson : Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: isDark ? AppColors.crimson : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

  Color _scoreColor(double s) {
    if (s >= 80) { return AppColors.success; }
    if (s >= 60) { return Colors.amber.shade400; }
    if (s >= 40) { return Colors.orange.shade400; }
    return AppColors.crimson;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final br = Theme.of(context).brightness;
    final provider = context.watch<DiscoveryProvider>();
    final auth = context.watch<AuthProvider>();

    return Stack(children: [
      Scaffold(
        backgroundColor: AppColors.background(br),
        body: SafeArea(
          child: Column(children: [
            _buildHeader(br, auth.isArtist),
            _buildFilterChips(br),
            Expanded(child: _buildContent(provider, br)),
            _buildActionBar(br),
          ]),
        ),
      ),
      _buildFilterPanel(br),
      if (_showMatch) _buildMatchOverlay(br),
    ]);
  }

  // ─── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(Brightness br, bool isArtist) {
    final isDark = br == Brightness.dark;
    final hasPF = _priceRange.start > 0 || _priceRange.end < _maxPrice;
    final hasRF = _minRating > 0;
    final cnt = _selectedGenres.length + (_useLocation ? 1 : 0) + (hasPF ? 1 : 0) + (hasRF ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(
        children: [
          // Filter button
          GestureDetector(
            onTap: _toggleFilters,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cnt > 0
                    ? AppColors.crimson.withValues(alpha: isDark ? 0.15 : 0.08)
                    : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: cnt > 0 || _showFilters ? AppColors.crimson : AppColors.text(br),
                    size: 20,
                  ),
                  if (cnt > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(color: AppColors.crimson, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(
                          '$cnt',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArtist ? 'Discover Gigs' : 'Discover Artists',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text(br),
                    letterSpacing: -0.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArtist ? 'Find your next performance' : 'Book talented artists',
                  style: TextStyle(
                    color: AppColors.textSec(br),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Boost button
          if (isArtist)
            GestureDetector(
              onTap: _showBoostDialog,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.rocket_launch_rounded, color: AppColors.crimson, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Filter Chips ───────────────────────────────────────────────────────

  Widget _buildFilterChips(Brightness br) {
    final isDark = br == Brightness.dark;
    final disc = context.watch<DiscoveryProvider>();
    final auth = context.watch<AuthProvider>();

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _bentoChip('Passport', Icons.public_rounded, disc.passportMode, br, isDark, (on) {
            if (!auth.isPaidUser) {
              _premiumUpsell('Passport Mode', 'Discover worldwide — no location limits. Upgrade to Pro!');
              return;
            }
            disc.togglePassportMode(on);
          }),
          const SizedBox(width: 8),
          _bentoChip('Nearby', _useLocation ? Icons.location_on_rounded : Icons.location_off_rounded, _useLocation, br, isDark, _toggleLocation),
          const SizedBox(width: 8),
          ..._genres.take(5).map((g) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _bentoChip(g, null, _selectedGenres.contains(g), br, isDark, (on) => _toggleGenre(g, on)),
              )),
          _bentoChip('More', Icons.filter_list_rounded, false, br, isDark, (_) => _toggleFilters()),
        ],
      ),
    );
  }

  Widget _bentoChip(String label, IconData? icon, bool sel, Brightness br, bool isDark, ValueChanged<bool> onSel) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSel(!sel);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? (isDark ? Colors.white : AppColors.crimson)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: sel
              ? null
              : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEEEEE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: sel ? (isDark ? AppColors.crimson : Colors.white) : AppColors.crimson),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: sel
                    ? (isDark ? AppColors.crimson : Colors.white)
                    : AppColors.text(br),
                fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Content ───────────────────────────────────────────────────────

  Widget _buildContent(DiscoveryProvider prov, Brightness br) {
    final cards = prov.cards;
    final idx = prov.currentIndex;
    final isArtist = context.watch<AuthProvider>().isArtist;

    if (prov.isLoading && cards.isEmpty) {
      return _buildStateView(br, title: 'Finding matches...', loading: true);
    }
    if (cards.isEmpty) {
      if (prov.errorMessage != null) {
        return _buildStateView(br, icon: Icons.error_outline_rounded, title: 'Something went wrong', subtitle: prov.errorMessage, retry: true);
      }
      return _buildStateView(
        br,
        icon: isArtist ? Icons.business_rounded : Icons.mic_rounded,
        title: isArtist ? 'No gigs yet' : 'No artists yet',
        subtitle: 'Check back soon — we\'re growing fast!',
        retry: true,
      );
    }
    if (idx >= cards.length) {
      return _buildStateView(br, icon: Icons.celebration_rounded, title: 'You\'ve seen everyone!', subtitle: 'Check back later for new matches', retry: true);
    }

    // Build card stack (max 3 visible)
    final end = math.min(idx + 3, cards.length);
    final stack = <Widget>[];

    for (int i = end - 1; i >= idx; i--) {
      final depth = i - idx;
      final scale = 1.0 - depth * 0.05;
      final yOff = depth * 8.0;
      final isTop = depth == 0;
      final card = cards[i];

      Widget child = _buildCardBody(card, br);

      if (isTop) {
        child = GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform.rotate(
            angle: _angle,
            child: Transform.translate(offset: _drag, child: child),
          ),
        );
      }

      stack.add(Positioned.fill(
        child: Transform.translate(
          offset: Offset(0, yOff),
          child: Transform.scale(scale: scale, child: child),
        ),
      ));
    }

    // Remaining cards badge
    if (cards.length - idx <= 5) {
      stack.add(Positioned(
        top: 16,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${cards.length - idx} left',
              style: const TextStyle(
                fontFamily: 'Satoshi',
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ));
    }

    return Stack(fit: StackFit.expand, children: stack);
  }

  Widget _buildStateView(Brightness br, {IconData? icon, required String title, String? subtitle, bool loading = false, bool retry = false}) {
    final isDark = br == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            CircularProgressIndicator(color: AppColors.crimson, strokeWidth: 2.5)
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.crimson.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(icon, color: AppColors.crimson, size: 52),
            ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: AppColors.text(br),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textSec(br), fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
          if (retry) ...[
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _loadFeed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : AppColors.crimson,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: isDark ? AppColors.crimson : Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: isDark ? AppColors.crimson : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ─── Card ────────────────────────────────────────────────────────────────

  Widget _buildCardBody(DiscoveryCard card, Brightness br) {
    final item = _Item.fromCard(card);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(fit: StackFit.expand, children: [
          // Background image
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: item.imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => _buildGradient(),
            )
          else
            _buildGradient(),

          // Scrim
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 0.7, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // Badges
          _buildBadges(item),

          // Info
          _buildCardInfo(item, br),

          // Swipe indicator
          _buildSwipeIndicator(),
        ]),
      ),
    );
  }

  Widget _buildGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.crimson.withValues(alpha: 0.6),
            AppColors.rose.withValues(alpha: 0.4),
            AppColors.crimson.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges(_Item item) {
    return Stack(children: [
      if (item.isBoosted)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              const Text(
                'BOOSTED',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ]),
          ),
        ),
      if (item.isVerified)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
          ),
        ),
    ]);
  }

  Widget _buildCardInfo(_Item item, Brightness br) {
    final chips = <Widget>[
      if (item.city != null && item.city!.isNotEmpty)
        _buildInfoChip(Icons.location_on_rounded, item.city!),
      if (item.distance > 0)
        _buildInfoChip(Icons.directions_walk_rounded, '${item.distance.toStringAsFixed(0)} mi'),
      if (item.rating != null && item.rating! > 0)
        _buildInfoChip(Icons.star_rounded, item.rating!.toStringAsFixed(1), iconColor: Colors.amber.shade400),
      if (item.price != null)
        _buildInfoChip(Icons.attach_money_rounded, '${item.price!.toStringAsFixed(0)}+'),
    ];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Text(
                item.typeLabel.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              item.title,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Subtitle
            if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Info chips
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],

            // Recommendation score
            if (item.score > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome_rounded, color: _scoreColor(item.score), size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '${item.score.toStringAsFixed(0)}% match',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      color: _scoreColor(item.score),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color iconColor = Colors.white70}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: iconColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }

  Widget _buildSwipeIndicator() {
    final w = MediaQuery.of(context).size.width;
    final thresh = w * 0.35 * 0.3;
    final showLike = _drag.dx > thresh;
    final showNope = _drag.dx < -thresh;

    if (!showLike && !showNope) { return const SizedBox.shrink(); }

    return Stack(children: [
      if (showLike)
        Positioned(
          top: 50,
          right: 28,
          child: Transform.rotate(
            angle: 0.3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Text(
                'LIKE',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      if (showNope)
        Positioned(
          top: 50,
          left: 28,
          child: Transform.rotate(
            angle: -0.3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Text(
                'NOPE',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  // ─── Action Bar (Bento style) ───────────────────────────────────────────

  Widget _buildActionBar(Brightness br) {
    final isDark = br == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind
          _buildActionButton(
            icon: Icons.replay_rounded,
            color: Colors.blue.shade400,
            size: 44,
            label: 'Rewind',
            br: br,
            isDark: isDark,
            isSmall: true,
            onTap: _undo,
          ),
          // Pass
          _buildActionButton(
            icon: Icons.close_rounded,
            color: AppColors.crimson,
            size: 58,
            label: 'Pass',
            br: br,
            isDark: isDark,
            onTap: () => _animateSwipe(false),
          ),
          // Super Like
          _buildActionButton(
            icon: Icons.star_rounded,
            color: Colors.blue.shade600,
            size: 48,
            label: 'Super',
            br: br,
            isDark: isDark,
            isSmall: true,
            onTap: _superLike,
          ),
          // Like
          _buildActionButton(
            icon: Icons.favorite_rounded,
            color: AppColors.success,
            size: 58,
            label: 'Like',
            br: br,
            isDark: isDark,
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
    required String label,
    required Brightness br,
    required bool isDark,
    bool isSmall = false,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isSmall
                  ? color.withValues(alpha: isDark ? 0.15 : 0.08)
                  : (isDark ? AppColors.charcoal : Colors.white),
              shape: BoxShape.circle,
              border: isSmall
                  ? null
                  : Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 2,
                    ),
              boxShadow: isSmall
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: size * 0.45, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: AppColors.textSec(br),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Filter Panel (Bento Redesign) ──────────────────────────────────────

  Widget _buildFilterPanel(Brightness br) {
    final isDark = br == Brightness.dark;
    final panelW = MediaQuery.of(context).size.width * 0.85;
    final hasPF = _priceRange.start > 0 || _priceRange.end < _maxPrice;
    final hasRF = _minRating > 0;
    final cnt = _selectedGenres.length + (_useLocation ? 1 : 0) + (hasPF ? 1 : 0) + (hasRF ? 1 : 0);

    return AnimatedBuilder(
      animation: _filterCtrl,
      builder: (context, _) {
        final offset = _showFilters ? Offset.zero : Offset(-panelW, 0);
        return Transform.translate(
          offset: offset,
          child: Container(
            width: panelW,
            height: MediaQuery.of(context).size.height,
            color: isDark ? AppColors.charcoal : Colors.white,
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Filters',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  color: AppColors.text(br),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (cnt > 0) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.crimson,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$cnt',
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _clearAllFilters,
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: AppColors.crimson,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleFilters,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.close_rounded, color: AppColors.textSec(br), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildFilterSection('Location', br, [
                          _buildFilterToggle('Use my location', Icons.my_location_rounded, _useLocation, (v) => _toggleLocation(v), br, isDark),
                        ]),
                        _buildFilterSection('Genres', br, [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _genres.map((g) {
                              final on = _selectedGenres.contains(g);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _toggleGenre(g, !on);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: on
                                        ? (isDark ? Colors.white : AppColors.crimson)
                                        : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F8F8)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: on ? null : Border.all(color: AppColors.border(br)),
                                  ),
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      color: on
                                          ? (isDark ? AppColors.crimson : Colors.white)
                                          : AppColors.text(br),
                                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ]),
                        _buildFilterSection('Price Range', br, [
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.crimson,
                              inactiveTrackColor: AppColors.border(br),
                              thumbColor: AppColors.crimson,
                              overlayColor: AppColors.crimson.withValues(alpha: 0.1),
                              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                            ),
                            child: RangeSlider(
                              values: _priceRange,
                              min: 0,
                              max: _maxPrice,
                              divisions: 40,
                              onChanged: (v) => setState(() => _priceRange = v),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${_priceRange.start.toInt()}',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    color: AppColors.crimson,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '\$${_priceRange.end.toInt()}',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    color: AppColors.crimson,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                        _buildFilterSection('Minimum Rating', br, [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [4.5, 4.0, 3.5, 3.0].map((r) {
                              final on = _minRating == r;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _minRating = on ? 0 : r);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: on
                                        ? (isDark ? Colors.white : AppColors.crimson)
                                        : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F8F8)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: on ? null : Border.all(color: AppColors.border(br)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: on
                                            ? (isDark ? AppColors.crimson : Colors.white)
                                            : Colors.amber.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${r.toStringAsFixed(1)}+',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          color: on
                                              ? (isDark ? AppColors.crimson : Colors.white)
                                              : AppColors.text(br),
                                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  // Apply button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: GestureDetector(
                      onTap: _applyFilters,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : AppColors.crimson,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: isDark ? AppColors.crimson : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
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

  Widget _buildFilterSection(String title, Brightness br, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.text(br),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFilterToggle(String title, IconData icon, bool on, ValueChanged<bool> onChange, Brightness br, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChange(!on);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: on
              ? AppColors.crimson.withValues(alpha: isDark ? 0.12 : 0.06)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F8F8)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: on ? AppColors.crimson.withValues(alpha: 0.2) : AppColors.border(br),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.crimson, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: AppColors.text(br),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                color: on ? AppColors.crimson : AppColors.textSec(br).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Match Overlay ──────────────────────────────────────────────────────

  Widget _buildMatchOverlay(Brightness br) {
    final isArtist = context.read<AuthProvider>().isArtist;
    final isDark = br == Brightness.dark;

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(fit: StackFit.expand, children: [
        // Subtle particle effect
        ...List.generate(15, (i) {
          final r = math.Random(i);
          return Positioned(
            left: r.nextDouble() * 400,
            top: r.nextDouble() * 800,
            child: Icon(
              Icons.star_rounded,
              color: AppColors.crimson.withValues(alpha: 0.2 + r.nextDouble() * 0.15),
              size: r.nextDouble() * 18 + 8,
            ),
          );
        }),

        Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _matchCtrl, curve: Curves.elasticOut),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Match title
                Text(
                  "It's a Match!",
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You and ${_pendingMatch?.getOtherPartyName(isArtist)} liked each other',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // Avatars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMatchAvatar(isArtist),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 20),
                    _buildMatchAvatar(isArtist),
                  ],
                ),
                const SizedBox(height: 44),

                // Send Message button
                GestureDetector(
                  onTap: () {
                    _closeMatchOverlay();
                    if (_pendingMatch != null) {
                      final match = _pendingMatch!;
                      final target = ChatTarget(
                        matchId: match.id,
                        participantId: match.otherUserProfileId ?? (isArtist ? match.venueId : match.artistId),
                        participantName: match.otherUserName ?? (isArtist ? match.venue?.name : match.artist?.stageName) ?? 'Chat',
                        participantPhoto: match.otherUserPhoto ?? (isArtist ? match.venue?.profilePhotoUrl : match.artist?.profilePhoto),
                        isParticipantArtist: match.otherUserType == 'artist' || !isArtist,
                        isMuted: match.isMuted,
                      );
                      ChatManager.instance.cacheFromMatches([match], isCurrentUserArtist: isArtist);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreenV2.fromTarget(target)));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppColors.crimson,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.white : AppColors.crimson).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'Send Message',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: isDark ? AppColors.crimson : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _closeMatchOverlay,
                  child: Text(
                    'Keep Swiping',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildMatchAvatar(bool isArtist) {
    final photo = _pendingMatch?.getOtherPartyPhoto(isArtist);
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        image: hasPhoto
            ? DecorationImage(image: CachedNetworkImageProvider(photo), fit: BoxFit.cover)
            : null,
        color: hasPhoto ? null : AppColors.crimson.withValues(alpha: 0.3),
      ),
      child: hasPhoto ? null : const Icon(Icons.person_rounded, color: Colors.white, size: 40),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VIEW MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Lightweight view model extracted from [DiscoveryCard] for the card UI.
class _Item {
  final String? imageUrl;
  final bool isBoosted;
  final bool isVerified;
  final String typeLabel;
  final String title;
  final String? subtitle;
  final String? city;
  final double distance;
  final double? rating;
  final double? price;
  final double score;

  const _Item({
    this.imageUrl,
    required this.isBoosted,
    required this.isVerified,
    required this.typeLabel,
    required this.title,
    this.subtitle,
    this.city,
    required this.distance,
    this.rating,
    this.price,
    required this.score,
  });

  factory _Item.fromCard(DiscoveryCard card) {
    final artist = card.artist;
    final venue = card.venue;
    final gig = card.gig;

    final img = card.primaryPhotoUrl.isNotEmpty
        ? card.primaryPhotoUrl
        : (card.galleryUrls.isNotEmpty ? card.galleryUrls.first : null);

    final priceMin = artist?.minPrice ?? venue?.gigPreferences?.minBudget ?? gig?.budget;

    final sub = card.genres.isNotEmpty
        ? card.genres.take(3).join(' • ')
        : (card.bio ?? gig?.description);

    final score = card.recommendationScore > 0
        ? card.recommendationScore
        : (card.isBoosted ? 95.0 : (card.rating > 0 ? (card.rating / 5) * 100 : 0.0));

    return _Item(
      imageUrl: img,
      isBoosted: card.isBoosted,
      isVerified: card.isVerified,
      typeLabel: card.typeLabel,
      title: card.name,
      subtitle: sub,
      city: card.location ?? gig?.location.venueAddress ?? gig?.location.city,
      distance: card.distance ?? 0,
      rating: card.rating > 0 ? card.rating : null,
      price: priceMin,
      score: score,
    );
  }
}
