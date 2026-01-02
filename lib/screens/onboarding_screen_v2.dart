import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/theme/theme.dart';
import 'role_selection_screen.dart';

/// 🎠 PREMIUM ONBOARDING SCREEN V2
///
/// Immersive carousel with 4 unique screen designs
/// Screen 1: Full-bleed hero with FAB navigation
/// Screen 2: Circular hero image with floating badge
/// Screen 3: Artist profile card showcase
/// Screen 4: Swipe card stack visual

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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Local asset images
  static const String _screen2Image = 'assets/images/onboarding/image4.png';

  static const String _screen3Avatar =
      'assets/images/onboarding/Artist avatar(image5).png';

  static const String _screen3Video =
      'assets/images/onboarding/performance preview(image6).png';

  static const String _screen4Venue =
      'assets/images/onboarding/Venue card image(image7).png';

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
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
    return Scaffold(
      backgroundColor: const Color(0xFF211111),
      body: Stack(
        children: [
          // PageView
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: [
              _buildScreen1(),
              _buildScreen2(),
              _buildScreen3(),
              _buildScreen4(),
            ],
          ),

          // Top navigation (Skip button) - only show on non-first pages
          if (_currentPage > 0 && _currentPage < 3)
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
                            color: const Color(0xFFC89393),
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
  // 🌟 SCREEN 1: Full-Bleed Hero (Keep Original)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScreen1() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen background image
        Image.asset(
          'assets/images/onboarding/image1.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.crimson.withOpacity(0.3),
                    const Color(0xFF211111),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unleash',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'Your Sound',
                      style: TextStyle(
                        color: AppColors.crimson,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description (left-aligned)
                Text(
                  'Connect with the perfect venues and let the world hear you. No agents, just music.',
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
  // 🎯 SCREEN 2: Circular Hero Image
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScreen2() {
    return Container(
      color: const Color(0xFF211111),
      child: SafeArea(
        child: Column(
          children: [
            // Skip button at top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _goToRoleSelection,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: const Color(0xFFC89393),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hero Visual with circular image
                    _buildCircularHeroImage(),

                    const SizedBox(height: 32),

                    // Text Content
                    Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            children: [
                              TextSpan(
                                text: 'Book Your\n',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'Next Gig',
                                style: TextStyle(color: AppColors.crimson),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'GigMatch bridges the gap between local talent and live venues. No agents, just music.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  // Page indicators
                  _buildPageIndicators(),

                  const SizedBox(height: 32),

                  // Next button
                  _buildPrimaryButton(
                    text: 'Next',
                    onPressed: _nextPage,
                    showArrow: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularHeroImage() {
    final size = MediaQuery.of(context).size.width * 0.65;

    return SizedBox(
      height: size + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow behind
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: size * _pulseAnimation.value,
                height: size * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.crimson.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crimson.withOpacity(0.3),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              );
            },
          ),

          // Main circular image
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF211111), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _screen2Image,
                    fit: BoxFit.cover,
                  ),
                          size: 60,
                          color: AppColors.crimson.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay at bottom
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF211111).withOpacity(0.6),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating music note badge
          Positioned(
            bottom: 0,
            right: (MediaQuery.of(context).size.width - size) / 2 - 10,
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_floatAnimation.value),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF211111),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.crimson,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎴 SCREEN 3: Artist Profile Showcase
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScreen3() {
    return Container(
      color: const Color(0xFF211111),
      child: SafeArea(
        child: Column(
          children: [
            // Top Section: Logo & Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                children: [
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.equalizer_rounded,
                        color: AppColors.crimson,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GigMatch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Progress bars
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.crimson,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main content: Profile Card + Bottom Section (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildProfileShowcaseCard(),
                    ),

                    const SizedBox(height: 24),

                    // Bottom Section: Text & Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                          Text(
                            'Showcase Your Sound',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a stunning artist profile. Upload high-quality audio samples, performance videos, and a bio that gets you booked.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFC89393),
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Continue button
                          _buildPrimaryButton(
                            text: 'Continue',
                            onPressed: _nextPage,
                            showArrow: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileShowcaseCard() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value * 0.5),
          child: Transform.rotate(
            angle: -0.035, // ~-2 degrees
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Glow behind card
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.crimson.withOpacity(0.15),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // Main card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Card Header: Profile
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.crimson,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                _screen3Avatar,
                                fit: BoxFit.cover,
                              ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The Velvet Tones',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Jazz • Soul • R&B',
                                  style: TextStyle(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.more_vert,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Video preview
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          children: [
                            // Video thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                _screen3Video,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              ),
                            ),
                            // Overlay
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                            // Play button
                            Center(
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.crimson.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            // Label
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Live at Blue Note',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Audio waveform section
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.music_note_rounded,
                                    size: 16,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Latest Demo',
                                    style: TextStyle(
                                      color: const Color(0xFF9CA3AF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '2:45',
                                style: TextStyle(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildWaveform(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Floating star badge
                Positioned(
                  top: -12,
                  right: -12,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value * 0.5),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: AppColors.crimson,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveform() {
    final bars = [
      0.4,
      0.7,
      1.0,
      0.6,
      0.3,
      0.5,
      0.8,
      0.9,
      0.5,
      0.3,
      0.6,
      0.4,
      0.2,
      0.5,
      0.85,
      0.65,
      0.35,
    ];

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((height) {
          return Container(
            width: 4,
            height: 32 * height,
            decoration: BoxDecoration(
              color: AppColors.crimson.withOpacity(height),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🃏 SCREEN 4: Swipe Card Stack
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScreen4() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF211111)),
      child: Stack(
        children: [
          // Background decorations
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.crimson.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.crimson.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withOpacity(0.2),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Login button
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to login
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card stack
                  Expanded(flex: 50, child: _buildCardStack()),

                  // Page indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _buildPageIndicators(),
                  ),

                  // Text content
                  Text(
                    'Swipe. Match. Play.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Venues post the gig. You bring the talent. Our smart matching system puts you in front of the right organizers instantly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Start button
                  _buildPrimaryButton(
                    text: 'Start Gigging',
                    onPressed: _goToRoleSelection,
                    showArrow: true,
                  ),

                  const SizedBox(height: 12),

                  // Terms text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text.rich(
                      TextSpan(
                        text: 'By joining, you agree to our ',
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms',
                            style: TextStyle(
                              color: const Color(0xFFD1D5DB),
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF6B7280),
                            ),
                          ),
                          TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: const Color(0xFFD1D5DB),
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildCardStack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.95;
        final cardHeight = constraints.maxHeight * 0.95;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Background card (furthest back)
            Transform.translate(
              offset: const Offset(0, 16),
              child: Transform.rotate(
                angle: -0.1, // ~-6 degrees
                child: Container(
                  width: cardWidth * 0.85,
                  height: cardHeight * 0.85,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A1A).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
              ),
            ),

            // Middle card
            Transform.translate(
              offset: const Offset(0, 8),
              child: Transform.rotate(
                angle: -0.05, // ~-3 degrees
                child: Container(
                  width: cardWidth * 0.9,
                  height: cardHeight * 0.9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A1A).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main active card (front)
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_floatAnimation.value * 0.3),
                  child: Container(
                    width: cardWidth * 0.95,
                    height: cardHeight * 0.95,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          // Card image (65%)
                          Expanded(
                            flex: 65,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  _screen4Venue,
                                  fit: BoxFit.cover,
                                ),
                                // Gradient overlay
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFF2A1A1A),
                                      ],
                                      stops: const [0.5, 1.0],
                                    ),
                                  ),
                                ),
                                // Genre tag
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.music_note_rounded,
                                              size: 14,
                                              color: AppColors.crimson,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'JAZZ',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Card details (35%)
                          Expanded(
                            flex: 35,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'The Blue Note',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 14,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Downtown, NY • 0.8mi',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'OFFER',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: '\$250',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '/set',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.6),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              'View Details',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Heart badge
                                Positioned(
                                  top: -24,
                                  right: 24,
                                  child: Transform.rotate(
                                    angle: 0.2, // ~12 degrees
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.crimson,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.crimson
                                                .withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
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
              },
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🧩 REUSABLE COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPageIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? AppColors.crimson : Colors.white.withOpacity(0.2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.crimson.withOpacity(0.6),
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
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.crimson,
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withOpacity(0.4),
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

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool showArrow = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.crimson,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withOpacity(0.3),
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
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
