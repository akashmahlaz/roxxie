/// 🎯 GIGMATCH Discovery Screen
///
/// Tinder-style swipe cards for discovering gigs (artists) or artists (venues).
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

import '../../core/exceptions.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/location_service.dart';
import '../../core/services/chat_manager.dart';
import '../../core/theme/theme.dart';

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
      if (isMatch && provider.lastMatch != null) {
        _pendingMatch = provider.lastMatch;
        _openMatchOverlay();
      }
    } catch (e) {
      debugPrint('⚠️ [Discovery] Swipe error: $e');
      _snack(e.toString(), isError: true);
    }

    // Reset
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

    String? selected;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final brightness = Theme.of(ctx).brightness;
          return AlertDialog(
            backgroundColor: AppColors.surface(brightness),
            title: const Text('Boost Your Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your profile will appear at the top of discovery.'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _boostOption('24', '24 hours', '\$4.99', selected, (v) => setDlg(() => selected = v))),
                    const SizedBox(width: 12),
                    Expanded(child: _boostOption('7', '7 days', '\$24.99', selected, (v) => setDlg(() => selected = v))),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: AppColors.textSec(brightness))),
              ),
              ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _processBoost(selected!);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Boost Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _boostOption(String val, String dur, String price, String? selected, ValueChanged<String> onTap) {
    final isSel = selected == val;
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(val);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSel ? AppColors.crimson : AppColors.border(brightness),
            width: isSel ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSel ? AppColors.crimson.withValues(alpha: 0.1) : null,
        ),
        child: Column(
          children: [
            Icon(Icons.rocket_launch_rounded, color: isSel ? AppColors.crimson : AppColors.crimson.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text(dur, style: TextStyle(fontWeight: FontWeight.w600, color: isSel ? AppColors.crimson : null)),
            Text(price, style: TextStyle(color: isSel ? AppColors.crimson : AppColors.crimson.withValues(alpha: 0.6), fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Future<void> _processBoost(String duration) async {
    const durations = {'24': '24 hours', '7': '7 days'};
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(SnackBar(
      content: const Row(children: [
        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        SizedBox(width: 12),
        Text('Processing boost...'),
      ]),
      backgroundColor: AppColors.crimson,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        content: const Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Getting your location...'),
        ]),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      action: isError
          ? SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _loadFeed)
          : null,
    ));
  }

  void _premiumUpsell(String feature, String message) {
    final brightness = Theme.of(context).brightness;
    final nav = Navigator.of(context, rootNavigator: true);
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 28),
          const SizedBox(width: 8),
          Expanded(child: Text(feature, style: TextStyle(color: AppColors.text(brightness), fontWeight: FontWeight.w700))),
        ]),
        content: Text(message, style: TextStyle(color: AppColors.textSec(brightness), fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later', style: TextStyle(color: AppColors.textSec(brightness))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              nav.pushNamed('/premium');
            },
            icon: const Icon(Icons.diamond_rounded, size: 18),
            label: const Text('Upgrade to Pro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 80) { return Colors.green.shade400; }
    if (s >= 60) { return Colors.amber.shade400; }
    if (s >= 40) { return Colors.orange.shade400; }
    return Colors.red.shade400;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final provider = context.watch<DiscoveryProvider>();
    final auth = context.watch<AuthProvider>();

    return Stack(children: [
      Scaffold(
        backgroundColor: AppColors.background(brightness),
        appBar: _appBar(brightness, auth.isArtist),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(children: [
            _filterChips(brightness),
            Expanded(child: _content(provider, brightness)),
            _actionBar(brightness),
          ]),
        ),
      ),
      _filterPanel(brightness),
      if (_showMatch) _matchOverlay(brightness),
    ]);
  }

  // ── App Bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _appBar(Brightness brightness, bool isArtist) {
    final hasPF = _priceRange.start > 0 || _priceRange.end < _maxPrice;
    final hasRF = _minRating > 0;
    final cnt = _selectedGenres.length + (_useLocation ? 1 : 0) + (hasPF ? 1 : 0) + (hasRF ? 1 : 0);

    return AppBar(
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      leading: Stack(children: [
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: _showFilters || cnt > 0 ? AppColors.crimson : AppColors.text(brightness),
          ),
          onPressed: _toggleFilters,
        ),
        if (cnt > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.crimson, shape: BoxShape.circle),
              child: Text('$cnt', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
      title: Text(
        isArtist ? 'Discover Gigs' : 'Discover Artists',
        style: TextStyle(color: AppColors.text(brightness), fontSize: 22, fontWeight: FontWeight.w800),
      ),
      actions: [
        if (isArtist)
          IconButton(
            icon: Icon(Icons.rocket_launch_rounded, color: AppColors.crimson),
            onPressed: _showBoostDialog,
            tooltip: 'Boost visibility',
          ),
      ],
    );
  }

  // ── Filter Chips ─────────────────────────────────────────────────────────

  Widget _filterChips(Brightness brightness) {
    final disc = context.watch<DiscoveryProvider>();
    final auth = context.watch<AuthProvider>();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('Passport', Icons.public_rounded, disc.passportMode, brightness, (on) {
            if (!auth.isPaidUser) {
              _premiumUpsell('Passport Mode', 'Discover worldwide — no location limits. Upgrade to Pro!');
              return;
            }
            disc.togglePassportMode(on);
          }),
          const SizedBox(width: 8),
          _chip('Nearby', _useLocation ? Icons.location_on_rounded : Icons.location_off_rounded, _useLocation, brightness, _toggleLocation),
          const SizedBox(width: 8),
          ..._genres.take(5).map((g) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(g, null, _selectedGenres.contains(g), brightness, (on) => _toggleGenre(g, on)),
              )),
          _chip('More', Icons.filter_list_rounded, false, brightness, (_) => _toggleFilters()),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData? icon, bool sel, Brightness brightness, ValueChanged<bool> onSel) {
    return FilterChip(
      label: Text(label),
      selected: sel,
      onSelected: onSel,
      avatar: icon != null ? Icon(icon, size: 18, color: sel ? Colors.white : AppColors.crimson) : null,
      selectedColor: AppColors.crimson,
      labelStyle: TextStyle(color: sel ? Colors.white : AppColors.text(brightness), fontWeight: sel ? FontWeight.w600 : FontWeight.w500),
      backgroundColor: AppColors.surface(brightness),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: sel ? AppColors.crimson : AppColors.border(brightness), width: 1.5),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  // ── Main Content ─────────────────────────────────────────────────────────

  Widget _content(DiscoveryProvider prov, Brightness brightness) {
    final cards = prov.cards;
    final idx = prov.currentIndex;

    if (prov.isLoading && cards.isEmpty) {
      return _stateView(brightness, icon: null, title: 'Finding matches...', loading: true);
    }
    if (cards.isEmpty) {
      if (prov.errorMessage != null) {
        return _stateView(brightness, icon: Icons.error_outline_rounded, title: 'Something went wrong', subtitle: prov.errorMessage, retry: true);
      }
      final isArtist = context.watch<AuthProvider>().isArtist;
      return _stateView(
        brightness,
        icon: isArtist ? Icons.business_rounded : Icons.mic_rounded,
        title: isArtist ? 'No gigs yet' : 'No artists yet',
        subtitle: 'Check back soon — we\'re growing fast!',
        retry: true,
      );
    }
    if (idx >= cards.length) {
      return _stateView(brightness, icon: Icons.celebration_rounded, title: 'You\'ve seen everyone!', subtitle: 'Check back later for new matches', retry: true);
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

      Widget child = _cardBody(card, brightness);

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
            child: Text('${cards.length - idx} left', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ),
      ));
    }

    return Stack(fit: StackFit.expand, children: stack);
  }

  Widget _stateView(Brightness brightness, {IconData? icon, required String title, String? subtitle, bool loading = false, bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            CircularProgressIndicator(color: AppColors.crimson, strokeWidth: 3)
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surface(brightness), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.crimson, size: 64),
            ),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(color: AppColors.text(brightness), fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(subtitle, style: TextStyle(color: AppColors.textSec(brightness), fontSize: 15, height: 1.5), textAlign: TextAlign.center),
          ],
          if (retry) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadFeed,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────

  Widget _cardBody(DiscoveryCard card, Brightness brightness) {
    final item = _Item.fromCard(card);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(fit: StackFit.expand, children: [
          // Background image
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover, errorWidget: (_, _, _) => _gradient(brightness))
          else
            _gradient(brightness),

          // Scrim
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                ),
              ),
            ),
          ),

          // Badges
          _badges(item),

          // Info
          _cardInfo(item, brightness),

          // Swipe indicator
          _swipeIndicator(brightness),
        ]),
      ),
    );
  }

  Widget _gradient(Brightness brightness) {
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

  Widget _badges(_Item item) {
    return Stack(children: [
      if (item.isBoosted)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('BOOSTED', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      if (item.isVerified)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
          ),
        ),
    ]);
  }

  Widget _cardInfo(_Item item, Brightness brightness) {
    final chips = <Widget>[
      if (item.city != null && item.city!.isNotEmpty)
        _infoChip(Icons.location_on_rounded, item.city!),
      if (item.distance > 0)
        _infoChip(Icons.directions_walk_rounded, '${item.distance.toStringAsFixed(0)} mi'),
      if (item.rating != null && item.rating! > 0)
        _infoChip(Icons.star_rounded, item.rating!.toStringAsFixed(1), iconColor: Colors.amber.shade400),
      if (item.price != null)
        _infoChip(Icons.attach_money_rounded, '${item.price!.toStringAsFixed(0)}+'),
    ];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // Type label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(item.typeLabel.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          ),
          const SizedBox(height: 8),

          // Title
          Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),

          // Subtitle
          if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],

          // Info chips
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],

          // Recommendation score
          if (item.score > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_rounded, color: _scoreColor(item.score), size: 16),
                const SizedBox(width: 6),
                Text('${item.score.toStringAsFixed(0)}% match', style: TextStyle(color: _scoreColor(item.score), fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color iconColor = Colors.white70}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _swipeIndicator(Brightness brightness) {
    final w = MediaQuery.of(context).size.width;
    final thresh = w * 0.35 * 0.3;
    final showLike = _drag.dx > thresh;
    final showNope = _drag.dx < -thresh;

    if (!showLike && !showNope) { return const SizedBox.shrink(); }

    return Stack(children: [
      if (showLike)
        Positioned(
          top: 40,
          right: 24,
          child: Transform.rotate(angle: 0.3, child: _swipeLabel('LIKE', Colors.green)),
        ),
      if (showNope)
        Positioned(
          top: 40,
          left: 24,
          child: Transform.rotate(angle: -0.3, child: _swipeLabel('NOPE', AppColors.crimson)),
        ),
    ]);
  }

  Widget _swipeLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  // ── Action Bar ───────────────────────────────────────────────────────────

  Widget _actionBar(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _actionBtn(Icons.replay_rounded, Colors.blue.shade400, 44, 'Rewind', brightness, tonal: true, onTap: _undo),
        _actionBtn(Icons.close_rounded, AppColors.crimson, 58, 'Pass', brightness, onTap: () => _animateSwipe(false)),
        _actionBtn(Icons.star_rounded, Colors.blue.shade600, 52, 'Super', brightness, tonal: true, onTap: _superLike),
        _actionBtn(Icons.favorite_rounded, Colors.green.shade500, 58, 'Like', brightness, onTap: () => _animateSwipe(true)),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, Color color, double size, String label, Brightness brightness, {bool tonal = false, required VoidCallback onTap}) {
    final style = tonal
        ? IconButton.styleFrom(backgroundColor: color.withValues(alpha: 0.15), foregroundColor: color)
        : IconButton.styleFrom(backgroundColor: AppColors.surface(brightness), foregroundColor: color);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: size,
        height: size,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: size * 0.55),
          style: style.copyWith(
            elevation: WidgetStatePropertyAll(tonal ? 0 : 2),
            shadowColor: WidgetStatePropertyAll(color.withValues(alpha: 0.3)),
            shape: const WidgetStatePropertyAll(CircleBorder()),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(color: AppColors.textSec(brightness), fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }

  // ── Filter Panel ─────────────────────────────────────────────────────────

  Widget _filterPanel(Brightness brightness) {
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
            color: AppColors.surface(brightness),
            child: SafeArea(
              right: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Text('Filters', style: TextStyle(color: AppColors.text(brightness), fontSize: 20, fontWeight: FontWeight.w700)),
                      if (cnt > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(12)),
                          child: Text('$cnt applied', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                    Row(children: [
                      TextButton(onPressed: _clearAllFilters, child: Text('Clear', style: TextStyle(color: AppColors.textSec(brightness), fontWeight: FontWeight.w600))),
                      IconButton(onPressed: _toggleFilters, icon: Icon(Icons.close_rounded, color: AppColors.textSec(brightness))),
                    ]),
                  ]),
                ),

                // Body
                Expanded(
                  child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                    _filterSection('Location', [
                      _filterToggle('Use my location', Icons.my_location_rounded, _useLocation, (v) => _toggleLocation(v)),
                    ]),
                    _filterSection('Genres', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _genres.map((g) {
                          final on = _selectedGenres.contains(g);
                          return FilterChip(
                            label: Text(g),
                            selected: on,
                            selectedColor: AppColors.crimson,
                            checkmarkColor: Colors.white,
                            onSelected: (v) => _toggleGenre(g, v),
                          );
                        }).toList(),
                      ),
                    ]),
                    _filterSection('Price Range', [
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: _maxPrice,
                        divisions: 40,
                        onChanged: (v) => setState(() => _priceRange = v),
                        activeColor: AppColors.crimson,
                        inactiveColor: AppColors.border(brightness),
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('\$${_priceRange.start.toInt()}'),
                        Text('\$${_priceRange.end.toInt()}'),
                      ]),
                    ]),
                    _filterSection('Rating', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [4.5, 4.0, 3.5, 3.0].map((r) {
                          return FilterChip(
                            label: Text('${r.toStringAsFixed(1)}+'),
                            selected: _minRating == r,
                            selectedColor: AppColors.crimson,
                            checkmarkColor: Colors.white,
                            onSelected: (v) => setState(() => _minRating = v ? r : 0),
                          );
                        }).toList(),
                      ),
                    ]),
                  ]),
                ),

                // Apply
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _filterSection(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 12),
      ...children,
      const SizedBox(height: 24),
    ]);
  }

  Widget _filterToggle(String title, IconData icon, bool on, ValueChanged<bool> onChange) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: () => onChange(!on),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, color: AppColors.crimson),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(color: AppColors.text(brightness), fontSize: 15))),
          Checkbox(value: on, onChanged: (v) => onChange(v ?? false), activeColor: AppColors.crimson),
        ]),
      ),
    );
  }

  // ── Match Overlay ────────────────────────────────────────────────────────

  Widget _matchOverlay(Brightness brightness) {
    final isArtist = context.read<AuthProvider>().isArtist;

    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Stack(fit: StackFit.expand, children: [
        // Particles
        ...List.generate(20, (i) {
          final r = math.Random(i);
          return Positioned(
            left: r.nextDouble() * 400,
            top: r.nextDouble() * 800,
            child: Icon(Icons.star_rounded, color: AppColors.crimson.withValues(alpha: 0.3), size: r.nextDouble() * 20 + 10),
          );
        }),

        Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _matchCtrl, curve: Curves.elasticOut),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("It's a Match!", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(
                'You and ${_pendingMatch?.getOtherPartyName(isArtist)} liked each other',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 40),

              // Avatars
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _matchAvatar(isArtist),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 20),
                _matchAvatar(isArtist),
              ]),
              const SizedBox(height: 48),

              // Action
              ElevatedButton(
                onPressed: () {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: const Text('Send Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _closeMatchOverlay,
                child: const Text('Keep Swiping', style: TextStyle(color: Colors.white70)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _matchAvatar(bool isArtist) {
    final photo = _pendingMatch?.getOtherPartyPhoto(isArtist);
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        image: hasPhoto ? DecorationImage(image: CachedNetworkImageProvider(photo), fit: BoxFit.cover) : null,
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
