import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/theme/theme.dart';
import 'role_selection_screen.dart';

/// 🎠 PREMIUM ONBOARDING SCREEN V2
///
/// Immersive carousel with full-bleed imagery and floating cards
/// Inspired by world-class music apps
///
/// Features:
/// - Full-screen hero images with gradient overlays
/// - Floating glassmorphic info cards
/// - Split-color headlines
/// - Animated page indicators with glow
/// - Premium pill-shaped buttons

class OnboardingScreenV2 extends StatefulWidget {
  const OnboardingScreenV2({super.key});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      imagePath: 'assets/images/onboarding/image1.png',
      titleWhite: 'Unleash',
      titleAccent: 'Your Sound',
      description:
          'Connect with the perfect venues and let the world hear you. No agents, just music.',
      floatingCard: FloatingCardData(
        icon: Icons.location_on_rounded,
        title: 'The Blue Note Jazz Club',
        subtitle: '0.8 mi away • Match 98%',
        showCheckmark: true,
      ),
    ),
    OnboardingPageData(
      imagePath: 'assets/images/onboarding/image2.png',
      titleWhite: 'Match with',
      titleAccent: 'Local Venues',
      description:
          'Stop cold-calling. Let Roxxie pair you with the best spots in town based on your genre and availability.',
      floatingCard: FloatingCardData(
        icon: Icons.verified_rounded,
        iconColor: AppColors.electricViolet,
        title: 'Top Rated Artist',
        subtitle: 'Verified by 12 Venues',
      ),
    ),
    OnboardingPageData(
      imagePath: 'assets/images/onboarding/image3.png',
      titleWhite: 'Build Your',
      titleAccent: 'Fame',
      description:
          'Automatic invoicing, verified reviews, and a portfolio that grows with every gig. Let the venues come to you.',
      floatingCard: FloatingCardData(
        icon: Icons.calendar_today_rounded,
        iconColor: AppColors.neonMagenta,
        title: 'Gig Request',
        subtitle: 'The Jazz Corner • Pending',
        showProgress: true,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

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
    _fadeController.dispose();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1020), // Dark purple tint
                  AppColors.obsidian,
                  AppColors.obsidian,
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (visible after first page)
                      AnimatedOpacity(
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          onPressed: _currentPage > 0
                              ? () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              : null,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
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

                // PageView with hero images
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index);
                    },
                  ),
                ),

                // Bottom section with indicators and button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Column(
                    children: [
                      // Page indicators
                      _buildPageIndicators(),

                      const SizedBox(height: 32),

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

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Hero image container
          Expanded(flex: 55, child: _buildHeroImageCard(page, index)),

          const SizedBox(height: 32),

          // Text content
          Expanded(
            flex: 35,
            child: Column(
              children: [
                // Split-color title
                _buildSplitTitle(page.titleWhite, page.titleAccent),

                const SizedBox(height: 16),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
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
                // Image with fallback
                _buildImageWithFallback(page.imagePath),

                // Gradient overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.4, 0.7, 1.0],
                    ),
                  ),
                ),

                // Subtle purple tint overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
                      colors: [
                        AppColors.electricViolet.withOpacity(0.2),
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
            left: 16,
            bottom: 20,
            right: 60,
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

  Widget _buildImageWithFallback(String imagePath) {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback gradient with icon when image not found
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Add your image',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                    if (data.showProgress) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: 0.6,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.neonMagenta,
                                ),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pending',
                            style: TextStyle(
                              color: AppColors.neonMagenta,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else
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

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? AppColors.electricViolet
                : AppColors.textSecondary.withOpacity(0.3),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.electricViolet.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
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
          borderRadius: BorderRadius.circular(29), // Pill shape
          boxShadow: [
            BoxShadow(
              color: AppColors.electricViolet.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.electricViolet.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 16),
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
  final FloatingCardData? floatingCard;

  OnboardingPageData({
    required this.imagePath,
    required this.titleWhite,
    required this.titleAccent,
    required this.description,
    this.floatingCard,
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
