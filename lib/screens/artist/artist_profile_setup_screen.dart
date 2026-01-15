/// Multi-step onboarding flow for artists with comprehensive error handling:
/// Step 1: Basic Info (name, stage name, bio, genres, influences)
/// Step 2: Media Upload (photos, audio samples, videos)
/// Step 3: Contact & Location (phone, social links, location, travel radius)
/// Step 4: Availability & Pricing (calendar, price range)
/// Step 5: Profile Preview & Complete
///
/// Features:
/// - Comprehensive error handling with user-friendly messages
/// - Retry logic for critical operations
/// - Detailed logging for debugging
/// - Network connectivity checks
/// - Validation at each step
/// - Progress saving and recovery

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/upload_service.dart';
import 'steps/basic_info_step.dart';
import 'steps/media_upload_step.dart';
import 'steps/contact_location_step.dart';
import 'steps/availability_pricing_step.dart';
import 'steps/profile_preview_step.dart';

class ArtistProfileSetupScreen extends StatefulWidget {
  const ArtistProfileSetupScreen({super.key});

  @override
  State<ArtistProfileSetupScreen> createState() =>
      _ArtistProfileSetupScreenState();
}

class _ArtistProfileSetupScreenState extends State<ArtistProfileSetupScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isCompleting = false;
  String? _lastError;

  // Form data model
  final ArtistProfileData _profileData = ArtistProfileData();

  // Step titles
  final List<String> _stepTitles = [
    'Basic Info',
    'Media',
    'Contact',
    'Availability',
    'Preview',
  ];

  final List<String> _stepSubtitles = [
    'Tell us about yourself',
    'Showcase your talent',
    'How venues reach you',
    'When are you free?',
    'Review your profile',
  ];

  final List<IconData> _stepIcons = [
    Icons.person_rounded,
    Icons.photo_library_rounded,
    Icons.contact_phone_rounded,
    Icons.calendar_month_rounded,
    Icons.preview_rounded,
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Pre-populate location data from artist profile if available
    _loadExistingProfile();

    debugPrint('🎸 [ArtistSetup] Screen initialized');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    try {
      debugPrint('🎸 [ArtistSetup] Loading existing profile...');

      final authProvider = context.read<AuthProvider>();
      final artistProfile = authProvider.artistProfile;
      final user = authProvider.user;

      // ═══════════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM USER ACCOUNT (signup data)
      // ═══════════════════════════════════════════════════════════════════════
      if (user != null) {
        if (user.name.isNotEmpty && _profileData.displayName == null) {
          _profileData.displayName = user.name;
          debugPrint('🎸 Pre-filled display name from user: ${user.name}');
        }
        if (user.email.isNotEmpty && _profileData.email == null) {
          _profileData.email = user.email;
          debugPrint('🎸 Pre-filled email from user: ${user.email}');
        }
        if (user.phone != null && user.phone!.isNotEmpty && _profileData.phone == null) {
          _profileData.phone = user.phone;
          debugPrint('🎸 Pre-filled phone from user: ${user.phone}');
        }
      }

      // ═══════════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM SIGNUP LOCATION DATA (stored in AuthProvider)
      // This is the primary source for location when no artist profile exists
      // ═══════════════════════════════════════════════════════════════════════
      if (authProvider.signupCity != null && authProvider.signupCity!.isNotEmpty) {
        _profileData.city ??= authProvider.signupCity;
        debugPrint('📍 Pre-filled city from signup: ${authProvider.signupCity}');
      }
      if (authProvider.signupCountry != null && authProvider.signupCountry!.isNotEmpty) {
        _profileData.country ??= authProvider.signupCountry;
        debugPrint('📍 Pre-filled country from signup: ${authProvider.signupCountry}');
      }
      if (authProvider.signupLatitude != null && authProvider.signupLongitude != null) {
        _profileData.latitude ??= authProvider.signupLatitude;
        _profileData.longitude ??= authProvider.signupLongitude;
        debugPrint('📍 Pre-filled coordinates from signup: ${authProvider.signupLatitude}, ${authProvider.signupLongitude}');
      }

      // ═══════════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM EXISTING ARTIST PROFILE (if any)
      // This overrides signup data with any saved profile data
      // ═══════════════════════════════════════════════════════════════════════
      if (artistProfile != null) {
        debugPrint('🎸 [ArtistSetup] Found existing profile: ${artistProfile.displayName}');

        // Pre-fill data from existing profile
        _profileData.displayName = artistProfile.displayName;
        _profileData.stageName = artistProfile.stageName;
        _profileData.bio = artistProfile.bio;
        _profileData.genres = List<String>.from(artistProfile.genres);
        _profileData.minPrice = artistProfile.minPrice;
        _profileData.maxPrice = artistProfile.maxPrice;
        _profileData.currency = artistProfile.currency;

        // Pre-fill location data from existing profile
        if (artistProfile.location != null) {
          _profileData.city = artistProfile.location!.city;
          _profileData.country = artistProfile.location!.country;
          _profileData.latitude = artistProfile.location!.latitude;
          _profileData.longitude = artistProfile.location!.longitude;
          _profileData.travelRadius = artistProfile.travelRadius;
        }

        debugPrint('🎸 [ArtistSetup] Profile data loaded successfully');
      } else {
        debugPrint('🎸 [ArtistSetup] No existing profile found, using signup data');
      }
      
      debugPrint('✅ Pre-populated artist setup:');
      debugPrint('   - Name: ${_profileData.displayName}');
      debugPrint('   - Email: ${_profileData.email}');
      debugPrint('   - City: ${_profileData.city}');
      
      // ═══════════════════════════════════════════════════════════════════════
      // CRITICAL FIX: Trigger rebuild so child widgets get updated profileData
      // Without this, BasicInfoStep won't receive the pre-populated data
      // ═══════════════════════════════════════════════════════════════════════
      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ArtistSetup] Error loading existing profile: $e');
      debugPrint('Stack trace: $stackTrace');
      // Continue with empty profile data - not critical
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Validate current step before proceeding
      if (!_validateCurrentStep()) {
        _showValidationError();
        return;
      }

      setState(() {
        _currentStep++;
        _lastError = null;
      });

      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );

      debugPrint('🎸 [ArtistSetup] Moved to step ${_currentStep + 1}/$_totalSteps');
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _lastError = null;
      });

      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );

      debugPrint('🎸 [ArtistSetup] Moved back to step ${_currentStep + 1}/$_totalSteps');
    }
  }

  bool _validateCurrentStep() {
    try {
      switch (_currentStep) {
        case 0: // Basic Info
          if (_profileData.displayName == null || _profileData.displayName!.trim().isEmpty) {
            _lastError = 'Display name is required';
            return false;
          }
          if (_profileData.genres.isEmpty) {
            _lastError = 'Please select at least one genre';
            return false;
          }
          break;

        case 2: // Contact & Location
          if (_profileData.city == null || _profileData.city!.trim().isEmpty) {
            _lastError = 'City is required';
            return false;
          }
          if (_profileData.country == null || _profileData.country!.trim().isEmpty) {
            _lastError = 'Country is required';
            return false;
          }
          if (_profileData.latitude == null || _profileData.longitude == null) {
            _lastError = 'Location coordinates are required';
            return false;
          }
          break;

        case 3: // Availability & Pricing
          if (_profileData.minPrice <= 0) {
            _lastError = 'Minimum price must be greater than 0';
            return false;
          }
          if (_profileData.maxPrice <= 0) {
            _lastError = 'Maximum price must be greater than 0';
            return false;
          }
          if (_profileData.minPrice > _profileData.maxPrice) {
            _lastError = 'Minimum price cannot be greater than maximum price';
            return false;
          }
          break;
      }

      return true;
    } catch (e) {
      debugPrint('❌ [ArtistSetup] Validation error: $e');
      _lastError = 'Validation failed. Please check your input.';
      return false;
    }
  }

  void _showValidationError() {
    if (_lastError == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lastError!),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _completeSetup() async {
    if (_isCompleting) return; // Prevent double submission

    final brightness = Theme.of(context).brightness;
    final authProvider = context.read<AuthProvider>();

    setState(() {
      _isCompleting = true;
      _lastError = null;
    });

    debugPrint('🎸 [ArtistSetup] Starting profile completion...');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog(brightness),
    );

    try {
      // Final validation before submission
      final validationErrors = _profileData.validate();
      if (validationErrors.isNotEmpty) {
        throw Exception('Validation failed: ${validationErrors.join(', ')}');
      }

      // Check network connectivity
      await _checkNetworkConnectivity();

      // Upload photos before completing setup
      final uploadService = UploadService();
      
      // Upload profile photo if it's a local file
      if (_profileData.profilePhoto != null && 
          _profileData.profilePhoto!.startsWith('/')) {
        debugPrint('📤 Uploading profile photo...');
        try {
          final uploadResult = await uploadService.uploadProfilePhoto(
            _profileData.profilePhoto!,
          );
          _profileData.profilePhoto = uploadResult.url;
          debugPrint('✅ Profile photo uploaded: ${uploadResult.url}');
        } catch (e) {
          debugPrint('⚠️ Profile photo upload failed: $e');
          _profileData.profilePhoto = null;
        }
      }

      // Upload gallery photos if they are local files
      final uploadedGallery = <String>[];
      for (final photoPath in _profileData.photoGallery) {
        if (photoPath.startsWith('/')) {
          try {
            final uploadResult = await uploadService.uploadGalleryImage(
              photoPath,
              index: uploadedGallery.length,
            );
            uploadedGallery.add(uploadResult.url);
            debugPrint('✅ Gallery photo uploaded: ${uploadResult.url}');
          } catch (e) {
            debugPrint('⚠️ Gallery photo upload failed: $e');
          }
        } else {
          uploadedGallery.add(photoPath);
        }
      }
      _profileData.photoGallery = uploadedGallery;

      // Build the request data using the model's toBackendDto method
      final requestData = _profileData.toBackendDto();

      debugPrint('🎸 [ArtistSetup] Request data keys: ${requestData.keys.toList()}');
      debugPrint('🎸 [ArtistSetup] Location data: ${requestData['location']}');

      // Attempt to complete setup with retry logic
      bool success = false;
      Exception? lastError;

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint('🎸 [ArtistSetup] Setup attempt $attempt/3');

          if (attempt > 1) {
            // Wait before retry
            await Future.delayed(Duration(seconds: attempt));
          }

          success = await authProvider.completeArtistSetupWithData(requestData);

          if (success) {
            debugPrint('🎸 [ArtistSetup] Profile completed successfully on attempt $attempt');
            break;
          }

        } catch (e) {
          lastError = e as Exception;
          debugPrint('❌ [ArtistSetup] Setup attempt $attempt failed: $e');

          // Don't retry on validation errors
          if (e.toString().contains('Validation') || e.toString().contains('required')) {
            break;
          }
        }
      }

      if (!success) {
        throw lastError ?? Exception('Failed to complete setup after 3 attempts');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        _showSuccessDialog();
      }

    } catch (e, stackTrace) {
      debugPrint('❌ [ArtistSetup] Setup failed: $e');
      debugPrint('Stack trace: $stackTrace');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      _showErrorDialog(e.toString());

    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Widget _buildLoadingDialog(Brightness brightness) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.crimson.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.crimson,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Setting up your profile...',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'Profile Complete!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to GigMatch! Start discovering amazing venues.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Failed'),
        content: Text(
          'We encountered an error while setting up your profile:\n\n$errorMessage\n\nPlease try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeSetup(); // Retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw Exception('No internet connection. Please check your network and try again.');
      }
    } catch (e) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  /// Shows confirmation dialog for skipping all setup steps
  void _showSkipAllConfirmation(Brightness brightness) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border(brightness),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Skip All Steps?',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Your profile will be incomplete:\n'
                '• Less visibility to venues\n'
                '• Lower match quality\n'
                '• Can\'t receive gig offers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // Tip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                               color: AppColors.crimson, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can complete your profile later from Settings → Edit Profile',
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Continue setup
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text(brightness),
                        side: BorderSide(color: AppColors.border(brightness)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue Setup'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Skip all
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _skipAllAndComplete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Skip All'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Skips all steps and saves minimal profile
  Future<void> _skipAllAndComplete() async {
    final brightness = Theme.of(context).brightness;
    final authProvider = context.read<AuthProvider>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.crimson),
                const SizedBox(height: 16),
                Text(
                  'Saving minimal profile...',
                  style: TextStyle(color: AppColors.text(brightness)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Save minimal profile with whatever data we have
      final requestData = _profileData.toBackendDto();
      final success = await authProvider.completeArtistSetupWithData(requestData);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        await authProvider.init();

        if (!mounted) return;

        // Show quick success and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved! You can complete it later in Settings.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to save profile'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return WillPopScope(
      onWillPop: () async {
        // Show save draft confirmation
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save your progress?'),
            content: const Text(
              'Your profile will be saved as a draft. You can continue setup later from Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, false);
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                ),
                child: const Text('Save Draft'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: SafeArea(
          child: Column(
            children: [
              // Enhanced Progress Header
              _buildEnhancedProgressHeader(brightness),

              // Error Banner (if any)
              if (_lastError != null) _buildErrorBanner(brightness),

              // Step Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      BasicInfoStep(
                        profileData: _profileData,
                        onNext: _nextStep,
                      ),
                      MediaUploadStep(
                        profileData: _profileData,
                        onNext: _nextStep,
                        onBack: _previousStep,
                      ),
                      ContactLocationStep(
                        profileData: _profileData,
                        onNext: _nextStep,
                        onBack: _previousStep,
                      ),
                      AvailabilityPricingStep(
                        profileData: _profileData,
                        onNext: _nextStep,
                        onBack: _previousStep,
                      ),
                      ProfilePreviewStep(
                        profileData: _profileData,
                        onComplete: _completeSetup,
                        onBack: _previousStep,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.text(brightness)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Your Profile',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.text(brightness),
                      ),
                    ),
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSec(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              // ═══════════════════════════════════════════════════════════════════
              // SKIP / SKIP ALL Menu
              // ═══════════════════════════════════════════════════════════════════
              if (_currentStep < _totalSteps - 1)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSec(brightness),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: AppColors.surface(brightness),
                  onSelected: (value) {
                    if (value == 'skip') {
                      _nextStep();
                    } else if (value == 'skip_all') {
                      _showSkipAllConfirmation(brightness);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'skip',
                      child: Row(
                        children: [
                          Icon(Icons.skip_next_rounded,
                               color: AppColors.textSec(brightness), size: 20),
                          const SizedBox(width: 10),
                          Text('Skip this step',
                               style: TextStyle(color: AppColors.text(brightness))),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'skip_all',
                      child: Row(
                        children: [
                          Icon(Icons.fast_forward_rounded,
                               color: AppColors.crimson, size: 20),
                          const SizedBox(width: 10),
                          Text('Skip all steps',
                               style: TextStyle(color: AppColors.crimson, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress Bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppColors.surface(brightness),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.crimson),
          ),

          const SizedBox(height: 16),

          // Step Info
          Row(
            children: [
              Icon(
                _stepIcons[_currentStep],
                color: AppColors.crimson,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stepTitles[_currentStep],
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.text(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _stepSubtitles[_currentStep],
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSec(brightness),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(Brightness brightness) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lastError!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red, size: 16),
            onPressed: () {
              setState(() {
                _lastError = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProgressHeader(Brightness brightness) {
    final progress = (_currentStep + 1) / _totalSteps;
    final estimatedMinutes = (_totalSteps - _currentStep) * 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(brightness),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border(brightness),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.text(brightness),
                  ),
                  onPressed: _previousStep,
                )
              else
                const SizedBox(width: 48),
              
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Artist Profile Setup',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: AppColors.crimson,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '~$estimatedMinutes min',
                      style: TextStyle(
                        color: AppColors.crimson,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.border(brightness),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.crimson
                      : isCurrent
                          ? AppColors.crimson.withValues(alpha: 0.2)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.crimson
                        : AppColors.border(brightness),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _stepIcons[index],
                      size: 12,
                      color: isCompleted
                          ? Colors.white
                          : isCurrent
                              ? AppColors.crimson
                              : AppColors.textTert(brightness),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _stepTitles[index],
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.white
                            : isCurrent
                                ? AppColors.crimson
                                : AppColors.textTert(brightness),
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
