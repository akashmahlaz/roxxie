import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';
import 'role_selection_screen.dart';

/// 🎠 ONBOARDING SCREEN
///
/// Premium carousel introducing app features
/// Features:
/// - Smooth page transitions
/// - Gradient background
/// - Premium illustrations
/// - Skip & navigation controls

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.explore_rounded,
      title: 'Discover Local Gigs',
      description:
          'Find the perfect venues and events that match your style. Swipe through opportunities near you.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.crimson.withValues(alpha: 0.3),
          AppColors.rose.withValues(alpha: 0.1),
        ],
      ),
    ),
    OnboardingPage(
      icon: Icons.favorite_rounded,
      title: 'Match with Venues',
      description:
          'Connect with venues that love your music. When it\'s mutual, the conversation begins.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.rose.withValues(alpha: 0.3),
          AppColors.wine.withValues(alpha: 0.1),
        ],
      ),
    ),
    OnboardingPage(
      icon: Icons.calendar_today_rounded,
      title: 'Book & Perform',
      description:
          'Manage your gigs seamlessly. Accept bookings, track payments, and build your reputation.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.wine.withValues(alpha: 0.3),
          AppColors.success.withValues(alpha: 0.1),
        ],
      ),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
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
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          const AnimatedGradientBackground(opacity: 0.4),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: AppSpacing.screenPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _goToRoleSelection,
                        child: Text(
                          'Skip',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),

                // Bottom section
                Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => _buildDotIndicator(index),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Next/Get Started button
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          text: _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          onPressed: _nextPage,
                          icon: _currentPage == _pages.length - 1
                              ? Icons.arrow_forward_rounded
                              : null,
                          iconAfter: true,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),
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

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: AppSpacing.screenPaddingHorizontal,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: page.gradient,
              boxShadow: AppShadows.crimsonGlow,
            ),
            child: Icon(page.icon, size: 80, color: AppColors.textPrimary),
          ),

          const SizedBox(height: AppSpacing.huge),

          // Title
          Text(
            page.title,
            style: AppTypography.headlineLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              page.description,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive ? AppColors.crimson : AppColors.slate,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.crimson.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
