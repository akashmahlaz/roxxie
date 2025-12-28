import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/theme/theme.dart';
import 'role_selection_screen.dart';

/// 🎠 PREMIUM ONBOARDING SCREEN V2
///
/// Immersive carousel with full-bleed imagery
/// Inspired by world-class music apps
///
/// Screen 1: Full-bleed hero with FAB navigation
/// Screen 2-3: Card-based with floating info cards

class OnboardingScreenV2 extends StatefulWidget {
  const OnboardingScreenV2({super.key});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  final List<OnboardingPageData> _pages = [
    // First screen - Full bleed, no floating card
    OnboardingPageData(
      imagePath: 'assets/images/onboarding/image1.png',
      titleWhite: 'Unleash',
      titleAccent: 'Your Sound',
      description:
          'Connect with the perfect venues and let the world hear you. No agents, just music.',
      isFullBleed: true, // Full-bleed layout
      floatingCard: null, // No floating card on first screen
    ),
    // Second screen - Card with floating info
    OnboardingPageData(
      imagePath: 'assets/images/onboarding/image2.png',
      titleWhite: 'Match with',
      titleAccent: 'Local Venues',
      description:
          'Stop cold-calling. Let Roxxie pair you with the best spots in town based on your genre and availability.',
      isFullBleed: false,
      floatingCard: FloatingCardData(
        icon: Icons.location_on_rounded,
        title: 'The Blue Note Jazz Club',
        subtitle: '0.8 mi away • Match 98%',
        showCheckmark: true,
      ),
    ),
    // Third screen - Card with floating info
    OnboardingPageData(
      imagePath: 'assets/images/onboarding/image3.png',
      titleWhite: 'Build Your',
      titleAccent: 'Fame',
      description:
          'Automatic invoicing, verified reviews, and a portfolio that grows with every gig.',
      isFullBleed: false,
      floatingCard: FloatingCardData(
        icon: Icons.verified_rounded,
        iconColor: AppColors.electricViolet,
        title: 'Top Rated Artist',
        subtitle: 'Verified by 12 Venues',
      ),
      imageAlignment: Alignment.topCenter, // Fix person cutoff
      floatingCardBottomOffset:180, // Position card higher so stars are visible
      floatingCardLeftOffset: 60, // Shift to the right
    ),
  ];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToRoleSelection();
    }
  }

  void _goToRoleSelection() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RoleSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFirstPage = _currentPage == 0;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [
          // PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              if (page.isFullBleed) {
                return _buildFullBleedPage(page, index);
              } else {
                return _buildCardPage(page, index);
              }
            },
          ),

          // Top navigation (Skip button) - only show on non-first pages
          if (!isFirstPage)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      _buildGlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                      // Skip button
                      TextButton(
                        onPressed: _goToRoleSelection,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌟 FULL-BLEED PAGE (First Screen)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFullBleedPage(OnboardingPageData page, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen background image
        Image.asset(
          page.imagePath,
          fit: BoxFit.cover,
          alignment: page.imageAlignment ?? Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.electricViolet.withOpacity(0.3),
                    AppColors.obsidian,
                  ],
                ),
              ),
            );
          },
        ),

        // Gradient overlay for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.95),
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ),
          ),
        ),

        // Content at bottom
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                // Split-color title (left-aligned)
                _buildSplitTitleLeftAligned(page.titleWhite, page.titleAccent),

                const SizedBox(height: 16),

                // Description (left-aligned)
                Text(
                  page.description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 32),

                // Bottom row: Page indicators + FAB
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Page indicators (left)
                    _buildPageIndicators(),

                    // Glassmorphic FAB (right)
                    _buildGlassFAB(onPressed: _nextPage),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎴 CARD-BASED PAGE (Screen 2 & 3)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCardPage(OnboardingPageData page, int index) {
    final isLastPage = index == _pages.length - 1;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1020), AppColors.obsidian, AppColors.obsidian],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
          child: Column(
            children: [
              // Hero image card
              Expanded(flex: 58, child: _buildHeroImageCard(page, index)),

              const SizedBox(height: 20),

              // Text content (centered)
              Expanded(
                flex: 42,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Split-color title
                    _buildSplitTitle(page.titleWhite, page.titleAccent),

                    const SizedBox(height: 12),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        page.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Page indicators (centered)
                    _buildPageIndicators(),

                    const SizedBox(height: 20),

                    // CTA Button
                    _buildPremiumButton(
                      text: isLastPage ? 'Get Started' : 'Next',
                      onPressed: _nextPage,
                    ),

                    // Login link on last page
                    if (isLastPage) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: Navigate to login
                            },
                            child: Text(
                              'Log in',
                              style: TextStyle(
                                color: AppColors.electricViolet,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImageCard(OnboardingPageData page, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main image container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricViolet.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                Image.asset(
                  page.imagePath,
                  fit: BoxFit.cover,
                  alignment: page.imageAlignment ?? Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.electricViolet.withOpacity(0.4),
                            AppColors.neonMagenta.withOpacity(0.3),
                            AppColors.obsidian,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 80,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),

                // Purple tint
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.5,
                      colors: [
                        AppColors.electricViolet.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating card
        if (page.floatingCard != null)
          Positioned(
            left: page.floatingCardLeftOffset ?? 16,
            bottom: page.floatingCardBottomOffset ?? 20,
            right: page.floatingCardRightOffset ?? 50,
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_floatAnimation.value),
                  child: _buildFloatingInfoCard(page.floatingCard!),
                );
              },
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🧩 REUSABLE COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFloatingInfoCard(FloatingCardData data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (data.iconColor ?? AppColors.electricViolet)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data.icon,
                  color: data.iconColor ?? AppColors.electricViolet,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkmark
              if (data.showCheckmark)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.electricViolet,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitTitle(String white, String accent) {
    return Column(
      children: [
        Text(
          white,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        Text(
          accent,
          style: TextStyle(
            color: AppColors.electricViolet,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitTitleLeftAligned(String white, String accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          white,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            height: 1.0,
          ),
        ),
        Text(
          accent,
          style: TextStyle(
            color: AppColors.electricViolet,
            fontSize: 42,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 28 : 8,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isActive
                ? AppColors.electricViolet
                : AppColors.textSecondary.withOpacity(0.4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.electricViolet.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildGlassFAB({required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.electricViolet,
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricViolet.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.electricViolet, AppColors.deepViolet],
          ),
          borderRadius: BorderRadius.circular(29),
          boxShadow: [
            BoxShadow(
              color: AppColors.electricViolet.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
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

class OnboardingPageData {
  final String imagePath;
  final String titleWhite;
  final String titleAccent;
  final String description;
  final bool isFullBleed;
  final FloatingCardData? floatingCard;
  final Alignment? imageAlignment;
  final double? floatingCardBottomOffset;
  final double? floatingCardLeftOffset;
  final double? floatingCardRightOffset;

  OnboardingPageData({
    required this.imagePath,
    required this.titleWhite,
    required this.titleAccent,
    required this.description,
    this.isFullBleed = false,
    this.floatingCard,
    this.imageAlignment,
    this.floatingCardBottomOffset,
    this.floatingCardLeftOffset,
    this.floatingCardRightOffset,
  });
}

class FloatingCardData {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool showCheckmark;
  final bool showProgress;

  FloatingCardData({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.showCheckmark = false,
    this.showProgress = false,
  });
}
