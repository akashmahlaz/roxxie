/// 🔍 GIGMATCH Explore & Search Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass search bar
/// - Animated filter pills
/// - Trending section with gradient cards
/// - Category grid with icons
/// - Recent searches with swipe-to-delete
/// - Smart suggestions
///
/// Advanced search and explore functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../widgets/widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🔍 EXPLORE SCREEN - Main Widget
// ═══════════════════════════════════════════════════════════════════════════

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _isSearching = false;
  String _searchQuery = '';
  bool _showResults = false;

  // Static categories (genre-based)
  final List<SearchCategory> _categories = [
    SearchCategory(
      name: 'Jazz',
      icon: Icons.music_note_rounded,
      color: Colors.blue,
      count: 0,
    ),
    SearchCategory(
      name: 'Rock',
      icon: Icons.electric_bolt_rounded,
      color: Colors.red,
      count: 0,
    ),
    SearchCategory(
      name: 'Classical',
      icon: Icons.piano_rounded,
      color: Colors.purple,
      count: 0,
    ),
    SearchCategory(
      name: 'Pop',
      icon: Icons.star_rounded,
      color: Colors.pink,
      count: 0,
    ),
    SearchCategory(
      name: 'Electronic',
      icon: Icons.graphic_eq_rounded,
      color: Colors.cyan,
      count: 0,
    ),
    SearchCategory(
      name: 'Hip Hop',
      icon: Icons.headphones_rounded,
      color: Colors.orange,
      count: 0,
    ),
    SearchCategory(
      name: 'Country',
      icon: Icons.landscape_rounded,
      color: Colors.amber,
      count: 0,
    ),
    SearchCategory(
      name: 'R&B/Soul',
      icon: Icons.favorite_rounded,
      color: Colors.indigo,
      count: 0,
    ),
  ];

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
    _animationController.forward();

    _searchFocusNode.addListener(() {
      setState(() => _isSearching = _searchFocusNode.hasFocus);
    });

    // Load trending from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().loadTrending();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _showResults = false);
      context.read<ExploreProvider>().clearResults();
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _searchQuery = query;
      _showResults = true;
    });
    
    // Perform API search
    context.read<ExploreProvider>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<ExploreProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                // App Bar with Search
                _buildAppBar(brightness),

                // Quick Filters
                if (!_showResults)
                  SliverToBoxAdapter(child: _buildQuickFilters(brightness)),

                // Content
                if (_showResults)
                  _buildSearchResults(brightness, provider)
                else if (_isSearching)
                  _buildSearchSuggestions(brightness, provider)
                else ...[
                  // Trending Section
                  SliverToBoxAdapter(
                    child: _buildTrendingSection(brightness, provider),
                  ),

                  // Categories
                  SliverToBoxAdapter(child: _buildCategoriesSection(brightness)),

                  // Recent Searches
                  if (provider.recentSearches.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildRecentSearches(brightness, provider),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 APP BAR WITH SEARCH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(Brightness brightness) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedTapFeedback(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface(brightness),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(brightness)),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.text(brightness),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Explore',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.text(brightness),
                      ),
                    ),
                  ),
                  AnimatedTapFeedback(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showFiltersSheet(brightness);
                    },
                    child: Container(
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
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSearching
                        ? AppColors.crimson
                        : AppColors.border(brightness),
                    width: _isSearching ? 2 : 1,
                  ),
                  boxShadow: _isSearching
                      ? [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: _isSearching
                          ? AppColors.crimson
                          : AppColors.textSec(brightness),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          if (value.isEmpty) {
                            setState(() => _showResults = false);
                          }
                        },
                        onSubmitted: _performSearch,
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search artists, venues, genres...',
                          hintStyle: TextStyle(
                            color: AppColors.textTert(brightness),
                          ),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      AnimatedTapFeedback(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _showResults = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.textTert(
                              brightness,
                            ).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSec(brightness),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏷️ QUICK FILTERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickFilters(Brightness brightness) {
    final filters = [
      ('Near Me', Icons.location_on_rounded),
      ('Top Rated', Icons.star_rounded),
      ('New', Icons.fiber_new_rounded),
      ('Verified', Icons.verified_rounded),
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
          return AnimatedTapFeedback(
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Row(
                children: [
                  Icon(filter.$2, size: 16, color: AppColors.crimson),
                  const SizedBox(width: 6),
                  Text(
                    filter.$1,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
  // 🔥 TRENDING SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTrendingSection(Brightness brightness, ExploreProvider provider) {
    final trending = provider.trending;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.crimson,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Trending Now',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (provider.isLoading && trending.isEmpty)
          SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.crimson,
                strokeWidth: 2,
              ),
            ),
          )
        else if (trending.isEmpty)
          SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.textTert(brightness),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No trending artists yet',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: trending.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = trending[index];
                return _TrendingCardReal(item: item, brightness: brightness);
              },
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📂 CATEGORIES SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoriesSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Browse by Genre',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AnimatedTapFeedback(
                onTap: () => HapticFeedback.selectionClick(),
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return _CategoryCard(
              category: category,
              brightness: brightness,
              onTap: () {
                HapticFeedback.selectionClick();
                _searchController.text = category.name;
                _performSearch(category.name);
              },
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🕐 RECENT SEARCHES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentSearches(Brightness brightness, ExploreProvider provider) {
    final recentSearches = provider.recentSearches;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AnimatedTapFeedback(
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.clearRecentSearches();
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(recentSearches.length, (index) {
          final search = recentSearches[index];
          return Dismissible(
            key: Key(search),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Icon(Icons.delete_rounded, color: AppColors.error),
            ),
            onDismissed: (_) {
              HapticFeedback.lightImpact();
              provider.removeRecentSearch(search);
            },
            child: AnimatedTapFeedback(
              onTap: () {
                HapticFeedback.selectionClick();
                _searchController.text = search;
                _performSearch(search);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: AppColors.textSec(brightness),
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        search,
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.north_west_rounded,
                      color: AppColors.textTert(brightness),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💡 SEARCH SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchSuggestions(Brightness brightness, ExploreProvider provider) {
    // Combine recent searches with generic suggestions
    final recentSearches = provider.recentSearches.take(3).toList();
    final suggestions = [
      ...recentSearches,
      if (recentSearches.length < 3) ...[
        'Jazz bands near me',
        'Wedding musicians',
        'DJ for party',
        'Live acoustic',
        'Corporate event entertainment',
      ].take(5 - recentSearches.length),
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              recentSearches.isNotEmpty ? 'Recent & Suggestions' : 'Suggestions',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        if (index > suggestions.length) return null;
        
        final suggestion = suggestions[index - 1];
        final isRecent = recentSearches.contains(suggestion);
        
        return AnimatedTapFeedback(
          onTap: () {
            HapticFeedback.selectionClick();
            _searchController.text = suggestion;
            _performSearch(suggestion);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isRecent ? Icons.history_rounded : Icons.search_rounded,
                  color: AppColors.textSec(brightness),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.north_west_rounded,
                  color: AppColors.textTert(brightness),
                  size: 18,
                ),
              ],
            ),
          ),
        );
      }, childCount: suggestions.length + 1),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔎 SEARCH RESULTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchResults(Brightness brightness, ExploreProvider provider) {
    final results = provider.results;
    final status = provider.status;
    
    // Loading state
    if (status == ExploreStatus.loading && results.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.crimson),
        ),
      );
    }
    
    // Error state
    if (status == ExploreStatus.error) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ?? 'Search failed',
                style: TextStyle(color: AppColors.textSec(brightness)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => provider.search(_searchQuery),
                icon: const Icon(Icons.refresh, color: AppColors.crimson),
                label: const Text('Retry', style: TextStyle(color: AppColors.crimson)),
              ),
            ],
          ),
        ),
      );
    }
    
    // Empty results
    if (results.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.textTert(brightness),
              ),
              const SizedBox(height: 16),
              Text(
                'No results for "$_searchQuery"',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords',
                style: TextStyle(color: AppColors.textSec(brightness)),
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${results.length} results for "$_searchQuery"',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                  ),
                ),
                // Type filter chips
                Row(
                  children: [
                    _SearchTypeChip(
                      label: 'All',
                      isSelected: provider.searchType == SearchResultType.all,
                      onTap: () => provider.setSearchType(SearchResultType.all),
                      brightness: brightness,
                    ),
                    const SizedBox(width: 8),
                    _SearchTypeChip(
                      label: 'Artists',
                      isSelected: provider.searchType == SearchResultType.artist,
                      onTap: () => provider.setSearchType(SearchResultType.artist),
                      brightness: brightness,
                    ),
                    const SizedBox(width: 8),
                    _SearchTypeChip(
                      label: 'Venues',
                      isSelected: provider.searchType == SearchResultType.venue,
                      onTap: () => provider.setSearchType(SearchResultType.venue),
                      brightness: brightness,
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (index > results.length) return null;

        final result = results[index - 1];
        return _SearchResultCardReal(result: result, brightness: brightness);
      }, childCount: results.length + 2),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚙️ FILTERS SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  void _showFiltersSheet(Brightness brightness) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FiltersSheet(brightness: brightness),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 TRENDING CARD
// ═══════════════════════════════════════════════════════════════════════════

/* class _TrendingCard extends StatelessWidget {
  final TrendingItem item;
  final Brightness brightness;

  const _TrendingCard({required this.item, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.crimson,
              AppColors.crimson.withValues(alpha: 0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rank badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${item.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (item.isHot)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),

                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        item.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Name
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Type
                  Text(
                    item.type,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.rating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} */

// ═══════════════════════════════════════════════════════════════════════════
// 📂 CATEGORY CARD
// ═══════════════════════════════════════════════════════════════════════════

class _CategoryCard extends StatelessWidget {
  final SearchCategory category;
  final Brightness brightness;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: category.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${category.count}',
              style: TextStyle(
                color: AppColors.textTert(brightness),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔎 SEARCH RESULT CARD
// ═══════════════════════════════════════════════════════════════════════════

/*
class _SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final Brightness brightness;

  const _SearchResultCard({required this.result, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppColors.crimson,
                    AppColors.crimson.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  result.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.type} • ${result.location}',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${result.rating}',
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${result.reviews} reviews)',
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
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
*/

// ═══════════════════════════════════════════════════════════════════════════
// ⚙️ FILTERS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _FiltersSheet extends StatefulWidget {
  final Brightness brightness;

  const _FiltersSheet({required this.brightness});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  RangeValues _priceRange = const RangeValues(0, 500);
  double _distance = 25;
  double _minRating = 4.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(widget.brightness),
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
              color: AppColors.border(widget.brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        color: AppColors.text(widget.brightness),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    AnimatedTapFeedback(
                      onTap: () {
                        setState(() {
                          _priceRange = const RangeValues(0, 500);
                          _distance = 25;
                          _minRating = 4.0;
                        });
                      },
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Price Range
                Text(
                  'Price Range',
                  style: TextStyle(
                    color: AppColors.text(widget.brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${_priceRange.start.toInt()}',
                      style: TextStyle(
                        color: AppColors.textSec(widget.brightness),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${_priceRange.end.toInt()}+',
                      style: TextStyle(
                        color: AppColors.textSec(widget.brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 500,
                  divisions: 10,
                  activeColor: AppColors.crimson,
                  onChanged: (values) => setState(() => _priceRange = values),
                ),

                const SizedBox(height: 16),

                // Distance
                Text(
                  'Distance',
                  style: TextStyle(
                    color: AppColors.text(widget.brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_distance.toInt()} miles',
                      style: TextStyle(
                        color: AppColors.textSec(widget.brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _distance,
                  min: 1,
                  max: 100,
                  divisions: 20,
                  activeColor: AppColors.crimson,
                  onChanged: (value) => setState(() => _distance = value),
                ),

                const SizedBox(height: 16),

                // Minimum Rating
                Text(
                  'Minimum Rating',
                  style: TextStyle(
                    color: AppColors.text(widget.brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final rating = i + 1;
                    return Expanded(
                      child: AnimatedTapFeedback(
                        onTap: () =>
                            setState(() => _minRating = rating.toDouble()),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _minRating == rating
                                ? AppColors.crimson
                                : AppColors.background(widget.brightness),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _minRating == rating
                                  ? AppColors.crimson
                                  : AppColors.border(widget.brightness),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: _minRating == rating
                                    ? Colors.white
                                    : Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$rating',
                                style: TextStyle(
                                  color: _minRating == rating
                                      ? Colors.white
                                      : AppColors.text(widget.brightness),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
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
// 🆕 REAL DATA WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _TrendingCardReal extends StatelessWidget {
  final TrendingResult item;
  final Brightness brightness;

  const _TrendingCardReal({required this.item, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
        // Navigate to artist/venue profile
        if (item.isArtist) {
          Navigator.pushNamed(context, '/artist/${item.id}');
        } else {
          Navigator.pushNamed(context, '/venue/${item.id}');
        }
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.crimson,
              AppColors.crimson.withValues(alpha: 0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo if available
              if (item.photo != null && item.photo!.isNotEmpty)
                Image.network(
                  item.photo!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.crimson.withValues(alpha: 0.8),
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
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${item.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.isHot)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Name
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Type
                    Text(
                      item.type,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    // Rating
                    if (item.rating != null)
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }
}

class _SearchResultCardReal extends StatelessWidget {
  final ExploreResult result;
  final Brightness brightness;

  const _SearchResultCardReal({
    required this.result,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
        if (result.isArtist) {
          Navigator.pushNamed(context, '/artist/${result.id}');
        } else {
          Navigator.pushNamed(context, '/venue/${result.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            // Photo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.crimson.withValues(alpha: 0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: result.photo != null && result.photo!.isNotEmpty
                    ? Image.network(
                        result.photo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          result.isArtist ? Icons.person : Icons.business,
                          color: AppColors.crimson,
                          size: 28,
                        ),
                      )
                    : Icon(
                        result.isArtist ? Icons.person : Icons.business,
                        color: AppColors.crimson,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result.name,
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (result.rating != null)
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              result.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                color: AppColors.text(brightness),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.type,
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 13,
                    ),
                  ),
                  if (result.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textSec(brightness),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          result.location!,
                          style: TextStyle(
                            color: AppColors.textSec(brightness),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (result.genres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: result.genres.take(3).map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface(brightness),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border(brightness),
                            ),
                          ),
                          child: Text(
                            genre,
                            style: TextStyle(
                              color: AppColors.textSec(brightness),
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTert(brightness),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Brightness brightness;

  const _SearchTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.crimson
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.crimson
                : AppColors.border(brightness),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : AppColors.textSec(brightness),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📦 DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class SearchCategory {
  final String name;
  final IconData icon;
  final Color color;
  final int count;

  const SearchCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
  });
}

class TrendingItem {
  final int rank;
  final String name;
  final String type;
  final String image;
  final double rating;
  final bool isHot;

  const TrendingItem({
    required this.rank,
    required this.name,
    required this.type,
    required this.image,
    required this.rating,
    required this.isHot,
  });
}

class SearchResult {
  final String id;
  final String name;
  final String type;
  final String location;
  final double rating;
  final int reviews;
  final String image;

  const SearchResult({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.image,
  });
}
