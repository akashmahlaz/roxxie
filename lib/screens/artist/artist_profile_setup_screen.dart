// 🎸 ARTIST PROFILE SETUP WIZARD - MINIMAL 2-STEP FLOW
//
// Ultra-minimal onboarding collecting only essential matching info:
// Step 1: Location & Music (GPS, genres) → For venue matching
// Step 2: Budget & Type (price tier, act type) → For gig matching
//
// BOTH STEPS ARE SKIPPABLE - User can skip entire flow
// Additional info (bio, photos, availability) can be added in Profile/Me tab

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/upload_service.dart';
import '../../widgets/setup_loading_overlay.dart';
import 'steps/step1_location_music.dart';
import 'steps/step2_budget_type.dart';

class ArtistProfileSetupScreen extends StatefulWidget {
  const ArtistProfileSetupScreen({super.key});

  @override
  State<ArtistProfileSetupScreen> createState() =>
      _ArtistProfileSetupScreenState();
}

class _ArtistProfileSetupScreenState extends State<ArtistProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2;
  bool _isInitialized = false;

  // Form data model
  final ArtistProfileData _profileData = ArtistProfileData();

  // Step titles
  final List<String> _stepTitles = [
    'Location & Music',
    'Rate & Type',
  ];

  final List<String> _stepSubtitles = [
    'Help venues find you',
    'Set your typical rate',
  ];

  final List<IconData> _stepIcons = [
    Icons.location_on_rounded,
    Icons.payments_rounded,
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate data from user account after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prePopulateFromUserData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Pre-populate artist setup with data from user signup & existing artist profile
  void _prePopulateFromUserData() {
    if (_isInitialized) return;
    
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final existingArtist = auth.artistProfile;
    
    debugPrint('🎸 [ArtistSetup] Pre-populating data...');
    debugPrint('   - User: ${user?.name}, ${user?.email}');
    debugPrint('   - Existing artist: ${existingArtist?.stageName}');
    debugPrint('   - Signup location: ${auth.signupCity}, ${auth.signupCountry}');
    
    setState(() {
      // ═══════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM USER ACCOUNT (signup data)
      // ═══════════════════════════════════════════════════════════════════
      
      // Display name / Stage name from user's name (they entered during signup)
      if (user?.name != null && user!.name.isNotEmpty) {
        _profileData.displayName = user.name;
        _profileData.stageName = user.name;
        debugPrint('✅ Set displayName from user.name: ${user.name}');
      }
      
      // Email from user account
      if (user?.email != null && user!.email.isNotEmpty) {
        _profileData.email = user.email;
      }
      
      // Phone from user account
      if (user?.phone != null && user!.phone!.isNotEmpty) {
        _profileData.phone = user.phone;
      }
      
      // ═══════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM SIGNUP LOCATION DATA (stored in AuthProvider)
      // ═══════════════════════════════════════════════════════════════════
      if (auth.signupCity != null && auth.signupCity!.isNotEmpty) {
        _profileData.city ??= auth.signupCity;
        debugPrint('📍 Pre-filled city from signup: ${auth.signupCity}');
      }
      if (auth.signupCountry != null && auth.signupCountry!.isNotEmpty) {
        _profileData.country ??= auth.signupCountry;
        debugPrint('📍 Pre-filled country from signup: ${auth.signupCountry}');
      }
      if (auth.signupLatitude != null && auth.signupLongitude != null) {
        _profileData.latitude ??= auth.signupLatitude;
        _profileData.longitude ??= auth.signupLongitude;
        debugPrint('📍 Pre-filled coordinates from signup');
      }
      
      // ═══════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM EXISTING ARTIST PROFILE (if any)
      // ═══════════════════════════════════════════════════════════════════
      if (existingArtist != null) {
        debugPrint('🎸 [ArtistSetup] Found existing artist profile!');
        
        _profileData.displayName ??= existingArtist.displayName;
        _profileData.stageName ??= existingArtist.stageName;
        _profileData.bio ??= existingArtist.bio;
        
        if (existingArtist.genres.isNotEmpty) {
          _profileData.genres = List.from(existingArtist.genres);
        }
        
        final location = existingArtist.location;
        if (location != null) {
          _profileData.city ??= location.city;
          _profileData.country ??= location.country;
          final coords = location.coordinates;
          if (coords.length >= 2) {
            _profileData.longitude = coords[0];
            _profileData.latitude = coords[1];
          }
        }
        
        _profileData.minPrice = existingArtist.minPrice;
        _profileData.maxPrice = existingArtist.maxPrice;
      }
      
      _isInitialized = true;
    });
    
    debugPrint('✅ Pre-populated artist setup:');
    debugPrint('   - Name: ${_profileData.displayName}');
    debugPrint('   - City: ${_profileData.city}');
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _completeSetup() async {
    final brightness = Theme.of(context).brightness;
    // brightness used below for color theming
    final authProvider = context.read<AuthProvider>();
    final uploadService = UploadService();

    bool isRemoteUrl(String? value) {
      if (value == null) return false;
      return value.startsWith('http://') || value.startsWith('https://');
    }

    // Show professional loading overlay
    SetupLoadingOverlay.show(
      context,
      title: 'Setting up your profile',
      subtitle: 'This will only take a moment...',
      icon: Icons.music_note_rounded,
    );

    try {
      // Upload profile photo if exists and is local
      if (_profileData.profilePhoto != null && !isRemoteUrl(_profileData.profilePhoto)) {
        try {
          final uploadResult = await uploadService.uploadProfilePhoto(
            _profileData.profilePhoto!,
          );
          _profileData.profilePhoto = uploadResult.url;
        } catch (e) {
          debugPrint('⚠️ Profile photo upload failed: $e');
          _profileData.profilePhoto = null;
        }
      }
    } catch (e) {
      debugPrint('❌ Photo upload error: $e');
    }

    // ═══════════════════════════════════════════════════════════════════
    // CRITICAL: Ensure displayName is set (from user's signup name)
    // ═══════════════════════════════════════════════════════════════════
    if (_profileData.displayName == null || _profileData.displayName!.isEmpty) {
      final user = authProvider.user;
      if (user != null && user.name.isNotEmpty) {
        _profileData.displayName = user.name;
        _profileData.stageName = user.name;
        debugPrint('🎸 [ArtistSetup] Setting displayName from user.name: ${user.name}');
      } else {
        // Last resort fallback
        final email = user?.email ?? '';
        _profileData.displayName = email.split('@').first.isNotEmpty 
            ? email.split('@').first 
            : 'Artist';
        _profileData.stageName = _profileData.displayName;
        debugPrint('⚠️ [ArtistSetup] Using email fallback for displayName');
      }
    }

    // Build the request data
    final requestData = _profileData.toBackendDto();
    
    debugPrint('🎸 [ArtistSetup] DTO keys: ${requestData.keys.toList()}');
    debugPrint('🎸 [ArtistSetup] displayName: ${_profileData.displayName}');
    debugPrint('🎸 [ArtistSetup] Genres: ${_profileData.genres.length}');

    final success = await authProvider.completeArtistSetupWithData(requestData);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      // NOTE: Do NOT call authProvider.init() here!
      // completeArtistSetupWithData() already sets _status = AuthStatus.authenticated
      // Calling init() would re-fetch user from backend which may have stale data
      // and could reset status to profileIncomplete
      
      if (!mounted) return;
      
      // Navigate to success screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              _ArtistSetupSuccessScreen(brightness: brightness),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Setup failed. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _skipToEnd() {
    _skipAllAndComplete();
  }

  Future<void> _skipAllAndComplete() async {
    final authProvider = context.read<AuthProvider>();

    // Show minimal loading overlay
    MinimalLoadingOverlay.show(context, message: 'Saving profile...');

    // Try to save minimal profile
    final success = await authProvider.completeArtistSetupWithData(
      _profileData.toBackendDto(),
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved! You can complete it later in Settings.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      // Fallback: allow skip even if backend fails
      await authProvider.markOnboardingSkipped();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skipped for now. You can complete your profile later in Settings.'),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            _buildHeader(brightness, isDark),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Location & Music
                  ArtistStep1LocationMusic(
                    profileData: _profileData,
                    onDataChanged: () => setState(() {}),
                    onNext: _nextStep,
                    onSkip: _skipToEnd,
                  ),
                  // Step 2: Budget & Type
                  ArtistStep2BudgetType(
                    profileData: _profileData,
                    onDataChanged: () => setState(() {}),
                    onComplete: _completeSetup,
                    onSkip: _skipToEnd,
                  ),
                ],
              ),
            ),
            
            // Bottom Navigation Button
            _buildBottomNavigation(brightness),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Brightness brightness, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          // Top row with back/skip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              if (_currentStep > 0)
                GestureDetector(
                  onTap: _previousStep,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.graphite : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.text(brightness),
                      size: 22,
                    ),
                  ),
                )
              else
                const SizedBox(width: 42),
              
              // Step indicator
              Row(
                children: List.generate(_totalSteps, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 32 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted 
                          ? AppColors.crimson 
                          : (isDark ? AppColors.slate : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
              
              // Skip button
              GestureDetector(
                onTap: _skipToEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.graphite : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Step title
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepIcons[_currentStep],
                  color: AppColors.crimson,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stepTitles[_currentStep],
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _stepSubtitles[_currentStep],
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Step counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: Text(
                  '${_currentStep + 1}/$_totalSteps',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(Brightness brightness) {
    final isLastStep = _currentStep == _totalSteps - 1;
    final buttonText = isLastStep ? 'Complete Profile' : 'Continue';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.background(brightness),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLastStep ? _completeSetup : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isLastStep) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎉 ARTIST SETUP SUCCESS SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class _ArtistSetupSuccessScreen extends StatefulWidget {
  final Brightness brightness;
  
  const _ArtistSetupSuccessScreen({required this.brightness});

  @override
  State<_ArtistSetupSuccessScreen> createState() => _ArtistSetupSuccessScreenState();
}

class _ArtistSetupSuccessScreenState extends State<_ArtistSetupSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );
    
    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.background(widget.brightness),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1A1A1A), const Color(0xFF0D0D0D)]
                    : [Colors.white, const Color(0xFFF5F5F5)],
              ),
            ),
          ),
          
          // Animated background circles
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.crimson.withValues(alpha: 0.15),
                          AppColors.crimson.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: -150,
            left: -100,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.1 - (_pulseController.value * 0.1),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.crimson.withValues(alpha: 0.1),
                          AppColors.crimson.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  
                  // Success Icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.4),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      "You're All Set! 🎸",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text(widget.brightness),
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Your artist profile is live.\nStart discovering amazing gigs!',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.textSec(widget.brightness),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Features list
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_slideAnimation),
                    child: FadeTransition(
                      opacity: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.1) 
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              Icons.search_rounded,
                              'Discover Gigs',
                              'Find gigs that match your style',
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureRow(
                              Icons.favorite_rounded,
                              'Get Matched',
                              'Swipe right on venues you like',
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureRow(
                              Icons.message_rounded,
                              'Book & Perform',
                              'Chat with venues and book gigs',
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // CTA Button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(_slideAnimation),
                    child: FadeTransition(
                      opacity: _slideAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.crimson,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start Discovering',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: AppColors.crimson,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
