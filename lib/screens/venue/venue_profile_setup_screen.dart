import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/venues_models.dart';
import '../../core/services/upload_service.dart';
import '../../widgets/setup_loading_overlay.dart';
// Minimal 2-step flow
import 'steps/step1_location_music.dart';
import 'steps/step2_budget.dart';

/// 🏢 VENUE PROFILE SETUP WIZARD - MINIMAL 2-STEP FLOW
///
/// Ultra-minimal onboarding collecting only essential matching info:
/// Step 1: Location & Music (city, genres) → For matching
/// Step 2: Budget (min-max range) → For price matching
///
/// BOTH STEPS ARE SKIPPABLE - User can skip entire flow
/// Additional info (capacity, venue type, amenities) can be added in Profile/Me tab

class VenueProfileSetupScreen extends StatefulWidget {
  const VenueProfileSetupScreen({super.key});

  @override
  State<VenueProfileSetupScreen> createState() =>
      _VenueProfileSetupScreenState();
}

class _VenueProfileSetupScreenState extends State<VenueProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2;
  bool _isInitialized = false;

  // Form data model
  final VenueProfileData _profileData = VenueProfileData();

  // Step titles
  final List<String> _stepTitles = ['Location & Music', 'Budget'];

  final List<String> _stepSubtitles = [
    'Help musicians find you',
    'Set your budget range',
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

  /// Pre-populate venue setup with data from user signup & existing venue profile
  void _prePopulateFromUserData() {
    if (_isInitialized) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final existingVenue = auth.venueProfile;

    debugPrint('🏢 [VenueSetup] Pre-populating data...');
    debugPrint('   - User: ${user?.name}, ${user?.email}');
    debugPrint('   - Existing venue: ${existingVenue?.name}');
    debugPrint(
      '   - Venue location: ${existingVenue?.location?.city}, ${existingVenue?.location?.country}',
    );
    debugPrint(
      '   - Signup location: ${auth.signupCity}, ${auth.signupCountry}',
    );

    setState(() {
      // ═══════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM USER ACCOUNT (signup data)
      // ═══════════════════════════════════════════════════════════════════

      // Venue name from user's name (they entered venue name during signup)
      // CRITICAL: This is REQUIRED for backend validation
      if (user?.name != null && user!.name.isNotEmpty) {
        _profileData.venueName = user.name; // Always set, not ??=
        debugPrint('✅ Set venueName from user.name: ${user.name}');
      } else {
        debugPrint('⚠️ user.name is null or empty! User: $user');
      }

      // Email from user account
      if (user?.email != null && user!.email.isNotEmpty) {
        _profileData.contactEmail ??= user.email;
      }

      // Phone from user account
      if (user?.phone != null && user!.phone!.isNotEmpty) {
        _profileData.phone ??= user.phone;
      }

      // Profile photo from user account
      if (user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty) {
        _profileData.profilePhotoUrl ??= user.profilePhotoUrl;
      }

      // ═══════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM SIGNUP LOCATION DATA (stored in AuthProvider)
      // This is the primary source for location when no venue profile exists
      // ═══════════════════════════════════════════════════════════════════
      if (auth.signupCity != null && auth.signupCity!.isNotEmpty) {
        _profileData.location.city ??= auth.signupCity;
        debugPrint('📍 Pre-filled city from signup: ${auth.signupCity}');
      }
      if (auth.signupCountry != null && auth.signupCountry!.isNotEmpty) {
        _profileData.location.country ??= auth.signupCountry;
        debugPrint('📍 Pre-filled country from signup: ${auth.signupCountry}');
      }
      if (auth.signupLatitude != null && auth.signupLongitude != null) {
        // Use GeoJSON format [longitude, latitude]
        _profileData.location.coordinates = [
          auth.signupLongitude!,
          auth.signupLatitude!,
        ];
        debugPrint(
          '📍 Pre-filled coordinates from signup: ${auth.signupLatitude}, ${auth.signupLongitude}',
        );
      }

      // ═══════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM EXISTING VENUE PROFILE (if any)
      // This overrides signup data with any saved profile data
      // ═══════════════════════════════════════════════════════════════════

      if (existingVenue != null) {
        debugPrint('🏢 [VenueSetup] Found existing venue profile!');

        // Basic info
        _profileData.venueName ??= existingVenue.name;
        _profileData.venueType ??= existingVenue.venueType;
        _profileData.description ??= existingVenue.description;
        _profileData.capacity = existingVenue.capacity ?? 100;

        // Location (from signup!)
        if (existingVenue.location != null) {
          debugPrint(
            '🏢 [VenueSetup] Pre-filling location: ${existingVenue.location!.city}',
          );
          _profileData.location.city ??= existingVenue.location!.city;
          _profileData.location.country ??= existingVenue.location!.country;
          _profileData.location.streetAddress ??=
              existingVenue.location!.streetAddress;

          if (existingVenue.location!.hasValidCoordinates) {
            _profileData.location.coordinates =
                existingVenue.location!.coordinates;
          }
        }

        // Media
        _profileData.profilePhotoUrl ??= existingVenue.profilePhotoUrl;
        if (existingVenue.galleryUrls != null &&
            existingVenue.galleryUrls!.isNotEmpty) {
          _profileData.photoGallery = existingVenue.galleryUrls!
              .map((url) => VenuePhoto(url: url))
              .toList();
        }

        // Gig preferences
        if (existingVenue.gigPreferences != null) {
          _profileData.gigPreferences = existingVenue.gigPreferences!;
        }
      } else {
        debugPrint('🏢 [VenueSetup] No existing venue profile found');
      }

      _isInitialized = true;
    });

    debugPrint('✅ Pre-populated venue setup with user data:');
    debugPrint('   - Name: ${_profileData.venueName}');
    debugPrint('   - Email: ${_profileData.contactEmail}');
    debugPrint('   - Phone: ${_profileData.phone}');
    debugPrint('   - City: ${_profileData.location.city}');
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

    // MINIMAL FLOW: All fields are optional - skip validation
    // Venue name is pre-populated from signup, so we don't need to validate
    // User can skip all steps and complete with minimal/no data

    // Show professional loading overlay
    SetupLoadingOverlay.show(
      context,
      title: 'Setting up your venue',
      subtitle: 'This will only take a moment...',
      icon: Icons.storefront_rounded,
    );

    try {
      // Upload profile photo if it's a local file
      if (_profileData.profilePhotoUrl != null &&
          !isRemoteUrl(_profileData.profilePhotoUrl)) {
        debugPrint('📤 Uploading profile photo...');
        try {
          final uploadResult = await uploadService.uploadProfilePhoto(
            _profileData.profilePhotoUrl!,
          );
          _profileData.profilePhotoUrl = uploadResult.url;
          debugPrint('✅ Profile photo uploaded: ${uploadResult.url}');
        } catch (e) {
          debugPrint('⚠️ Profile photo upload failed: $e');
          // Continue without profile photo
          _profileData.profilePhotoUrl = null;
        }
      }

      // Upload gallery photos if they are local files
      final galleryUrls = <String>[];
      for (final photoPath in _profileData.venuePhotos) {
        if (!isRemoteUrl(photoPath)) {
          try {
            final uploadResult = await uploadService.uploadGalleryImage(
              photoPath,
              index: galleryUrls.length,
            );
            galleryUrls.add(uploadResult.url);
            debugPrint('✅ Gallery photo uploaded: ${uploadResult.url}');
          } catch (e) {
            debugPrint('⚠️ Gallery photo upload failed: $e');
          }
        } else {
          galleryUrls.add(photoPath);
        }
      }
      _profileData.venuePhotos = galleryUrls;
    } catch (e) {
      debugPrint('❌ Photo upload error: $e');
    }

    // Build the update request from profile data (DTO-safe payload)
    //
    // Backend expects (UpdateVenueDto):
    // - venueName, venueType, description
    // - gigPreferences.preferredGenres (inside gigPreferences object)
    // - location { city, country, coordinates:[lng,lat], ... }
    // - contactEmail, phone, showPhoneOnProfile
    // - capacity
    // - minBudget, maxBudget, currency (inside gigPreferences)
    //
    // NOTE:
    // - Do NOT send legacy keys like `name`, `bio`, `contactPhone`, `isActive` (not whitelisted).
    // - Keep coordinates ordering: [longitude, latitude].

    // Sync convenience properties (for backward compatibility with UI)
    _profileData.showPhone = _profileData.showPhoneOnProfile;
    _profileData.email = _profileData.bookingEmail;
    _profileData.minBudget = _profileData.gigPreferences.minBudget;
    _profileData.maxBudget = _profileData.gigPreferences.maxBudget;
    _profileData.currency = _profileData.gigPreferences.currency;

    // ═══════════════════════════════════════════════════════════════════
    // CRITICAL: Ensure venueName is set (from user's signup name)
    // ═══════════════════════════════════════════════════════════════════
    if (_profileData.venueName == null || _profileData.venueName!.isEmpty) {
      final user = authProvider.user;
      if (user != null && user.name.isNotEmpty) {
        _profileData.venueName = user.name;
        debugPrint(
          '🏢 [VenueSetup] Setting venueName from user.name: ${user.name}',
        );
      } else {
        // Last resort fallback - use email prefix
        final email = user?.email ?? authProvider.user?.email ?? '';
        _profileData.venueName = email.split('@').first.isNotEmpty
            ? email.split('@').first
            : 'My Venue';
        debugPrint(
          '⚠️ [VenueSetup] Using email fallback for venueName: ${_profileData.venueName}',
        );
      }
    }

    assert(() {
      final dto = _profileData.toBackendDto();
      debugPrint('🏢 [VenueSetup] DTO keys: ${dto.keys.toList()}');
      debugPrint('🏢 [VenueSetup] venueName: ${_profileData.venueName}');
      debugPrint(
        '🏢 [VenueSetup] Genres: ${_profileData.gigPreferences.preferredGenres.length}, photos: ${_profileData.venuePhotos.length}',
      );
      return true;
    }());

    final success = await authProvider.completeVenueSetup(_profileData);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      // NOTE: Do NOT call authProvider.init() here!
      // completeVenueSetup() already sets _status = AuthStatus.authenticated
      // Calling init() would re-fetch user from backend which may have stale data
      // and could reset status to profileIncomplete

      if (!mounted) return;

      // Navigate to a beautiful full-screen success experience
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              _VenueSetupSuccessScreen(brightness: brightness),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to save profile'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            border: Border.all(color: AppColors.border(brightness)),
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
                '• Less visibility to artists\n'
                '• Lower match quality\n'
                '• Can\'t receive booking requests',
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
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.crimson,
                      size: 20,
                    ),
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
    final authProvider = context.read<AuthProvider>();

    // Show minimal loading overlay
    MinimalLoadingOverlay.show(context, message: 'Saving profile...');

    // Save minimal profile with whatever data we have
    final success = await authProvider.completeVenueSetup(_profileData);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      // NOTE: Do NOT call authProvider.init() here - it would reset status

      if (!mounted) return;

      // Show quick success and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile saved! You can complete it later in Settings.',
          ),
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
          content: Text(
            'Skipped for now. You can complete your profile later in Settings.',
          ),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Show save draft confirmation
        final shouldPop =
            await showDialog<bool>(
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
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                    ),
                    child: const Text('Save Draft'),
                  ),
                ],
              ),
            ) ??
            false;
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background(brightness),
        body: SafeArea(
          child: Column(
            children: [
              // Enhanced Header with progress
              _buildEnhancedHeader(brightness),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Step 1: Location & Music Preferences
                    Step1LocationMusic(
                      profileData: _profileData,
                      onDataChanged: () => setState(() {}),
                      onNext: _nextStep,
                      onSkip: _skipToEnd,
                    ),
                    // Step 2: Budget
                    Step2Budget(
                      profileData: _profileData,
                      onDataChanged: () => setState(() {}),
                      onComplete: _completeSetup,
                      onSkip: _skipToEnd,
                    ),
                  ],
                ),
              ),

              // Fixed Bottom Navigation Button
              _buildBottomNavigation(brightness),
            ],
          ),
        ),
      ),
    );
  }

  /// Skip all steps and complete setup with minimal data
  void _skipToEnd() {
    _skipAllAndComplete();
  }

  /// Build the fixed bottom navigation with Continue button
  Widget _buildBottomNavigation(Brightness brightness) {
    final isLastStep = _currentStep == _totalSteps - 1;
    final buttonText = isLastStep ? 'Complete Profile' : 'Continue';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background(brightness).withValues(alpha: 0),
            AppColors.background(brightness),
            AppColors.background(brightness),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main action button
            ElevatedButton(
              onPressed: () {
                if (isLastStep) {
                  _completeSetup();
                } else {
                  _nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 8,
                shadowColor: AppColors.crimson.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastStep
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Skip button
            TextButton(
              onPressed: _skipToEnd,
              child: Text(
                'Skip for now',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Consistent header matching Artist profile setup style
  Widget _buildEnhancedHeader(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

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

              // Step indicator (dot style matching artist)
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
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

          // Step title with icon
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
              // Step counter (matching artist format)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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

  // ignore: unused_element
  Widget _buildHeader(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 16, 0),
      child: Row(
        children: [
          // Back button (only if not on first step)
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.text(brightness),
              ),
            )
          else
            const SizedBox(width: 48),

          // Title
          Expanded(
            child: Center(
              child: Text(
                'Venue Setup',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Skip / Skip All buttons
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
                      Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.textSec(brightness),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Skip this step',
                        style: TextStyle(color: AppColors.text(brightness)),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'skip_all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.fast_forward_rounded,
                        color: AppColors.crimson,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Skip all steps',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStepIndicator(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < _totalSteps - 1 ? 8 : 0,
                  ),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive
                        ? AppColors.crimson
                        : AppColors.border(brightness),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Current step info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _stepIcons[_currentStep],
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
                      _stepTitles[_currentStep],
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
}

/// ⏰ Operating Hours Model
class OperatingHours {
  bool isOpen;
  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  OperatingHours({this.isOpen = false, this.openTime, this.closeTime});
}

/// 🎵 Venue Types
class VenueTypes {
  static const List<String> types = [
    'Bar',
    'Nightclub',
    'Restaurant',
    'Concert Hall',
    'Theater',
    'Festival',
    'Wedding Venue',
    'Corporate Event',
    'Private Party',
    'Outdoor Venue',
    'Hotel/Resort',
    'Brewery/Winery',
    'Coffee Shop',
    'Art Gallery',
    'Other',
  ];
}

/// 🎛️ Venue Amenities
class VenueAmenities {
  static const List<String> amenities = [
    'Professional Stage',
    'Sound System',
    'Lighting Rig',
    'Backline Available',
    'Green Room',
    'Parking',
    'Loading Dock',
    'WiFi',
    'AC/Heating',
    'Dressing Rooms',
    'Security',
    'Food Service',
    'Bar Service',
    'Outdoor Area',
    'Wheelchair Access',
  ];
}

/// 🕐 Typical Performance Slots
class PerformanceSlots {
  static const List<String> slots = [
    'Afternoon (12-5pm)',
    'Early Evening (5-8pm)',
    'Prime Time (8-11pm)',
    'Late Night (11pm+)',
    'Weekday',
    'Weekend',
    'Brunch',
    'Happy Hour',
    'Dinner Service',
    'Special Events',
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎉 VENUE SETUP SUCCESS SCREEN
// Beautiful full-screen success experience
// ═══════════════════════════════════════════════════════════════════════════

class _VenueSetupSuccessScreen extends StatefulWidget {
  final Brightness brightness;

  const _VenueSetupSuccessScreen({required this.brightness});

  @override
  State<_VenueSetupSuccessScreen> createState() =>
      _VenueSetupSuccessScreenState();
}

class _VenueSetupSuccessScreenState extends State<_VenueSetupSuccessScreen>
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

                  // Success Icon with animation
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
                      "You're All Set! 🎉",
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
                      'Your venue profile is live.\nStart discovering talented artists!',
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
                              'Discover Artists',
                              'Find the perfect performers for your venue',
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureRow(
                              Icons.favorite_rounded,
                              'Save Favorites',
                              'Swipe right to save artists you love',
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureRow(
                              Icons.message_rounded,
                              'Connect & Book',
                              'Message artists and book performances',
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

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.crimson, size: 24),
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
