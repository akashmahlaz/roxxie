import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/venues_models.dart';
import '../../core/services/upload_service.dart';
import 'steps/venue_basic_info_step.dart';
import 'steps/venue_media_step.dart';
import 'steps/venue_details_step.dart';
import 'steps/gig_preferences_step.dart';
import 'steps/venue_preview_step.dart';

/// 🏢 VENUE PROFILE SETUP WIZARD
///
/// Multi-step onboarding flow for venues/event organizers:
/// Step 1: Basic Info (venue name, type, capacity, description)
/// Step 2: Media (photos of venue, past events)
/// Step 3: Details (location, contact, operating hours)
/// Step 4: Gig Preferences (genres, budget range, typical slots)
/// Step 5: Profile Preview & Complete

class VenueProfileSetupScreen extends StatefulWidget {
  const VenueProfileSetupScreen({super.key});

  @override
  State<VenueProfileSetupScreen> createState() =>
      _VenueProfileSetupScreenState();
}

class _VenueProfileSetupScreenState extends State<VenueProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isInitialized = false;

  // Form data model
  final VenueProfileData _profileData = VenueProfileData();

  // Step titles
  final List<String> _stepTitles = [
    'Venue Info',
    'Media',
    'Details',
    'Preferences',
    'Preview',
  ];

  final List<String> _stepSubtitles = [
    'Tell us about your venue',
    'Show off your space',
    'Location & contact',
    'What artists do you want?',
    'Review your profile',
  ];

  final List<IconData> _stepIcons = [
    Icons.storefront_rounded,
    Icons.photo_library_rounded,
    Icons.location_on_rounded,
    Icons.tune_rounded,
    Icons.preview_rounded,
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
    debugPrint('   - Venue location: ${existingVenue?.location?.city}, ${existingVenue?.location?.country}');
    debugPrint('   - Signup location: ${auth.signupCity}, ${auth.signupCountry}');
    
    setState(() {
      // ═══════════════════════════════════════════════════════════════════
      // PRE-POPULATE FROM USER ACCOUNT (signup data)
      // ═══════════════════════════════════════════════════════════════════
      
      // Venue name from user's name (they entered venue name during signup)
      if (user?.name != null && user!.name.isNotEmpty) {
        _profileData.venueName ??= user.name;
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
        _profileData.location.coordinates = [auth.signupLongitude!, auth.signupLatitude!];
        debugPrint('📍 Pre-filled coordinates from signup: ${auth.signupLatitude}, ${auth.signupLongitude}');
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
          debugPrint('🏢 [VenueSetup] Pre-filling location: ${existingVenue.location!.city}');
          _profileData.location.city ??= existingVenue.location!.city;
          _profileData.location.country ??= existingVenue.location!.country;
          _profileData.location.streetAddress ??= existingVenue.location!.streetAddress;
          
          if (existingVenue.location!.hasValidCoordinates) {
            _profileData.location.coordinates = existingVenue.location!.coordinates;
          }
        }
        
        // Media
        _profileData.profilePhotoUrl ??= existingVenue.profilePhotoUrl;
        if (existingVenue.galleryUrls != null && existingVenue.galleryUrls!.isNotEmpty) {
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
    final authProvider = context.read<AuthProvider>();
    final uploadService = UploadService();

    bool isRemoteUrl(String? value) {
      if (value == null) return false;
      return value.startsWith('http://') || value.startsWith('https://');
    }

    // Validate before doing any long-running uploads.
    final validationErrors = _profileData.validate();
    if (validationErrors.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationErrors.first),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.crimson,
        ),
      );
      return;
    }

    // Require valid location before completing venue setup
    final hasCity = (_profileData.city ?? '').trim().isNotEmpty;
    final hasCountry = (_profileData.country ?? '').trim().isNotEmpty;
    final lat = _profileData.location.latitude;
    final lng = _profileData.location.longitude;
    final hasValidCoords = lat.abs() > 0.000001 && lng.abs() > 0.000001;

    if (!hasCity || !hasCountry || !hasValidCoords) {
      if (!mounted) return;

      final message = !hasCity || !hasCountry
          ? 'Please set your venue city and country to continue.'
          : 'Please enable location and select your venue location to continue.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.crimson,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(brightness),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.crimson),
              const SizedBox(height: 16),
              Text(
                'Uploading photos...',
                style: TextStyle(color: AppColors.text(brightness)),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Upload profile photo if it's a local file
      if (_profileData.profilePhotoUrl != null && !isRemoteUrl(_profileData.profilePhotoUrl)) {
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

    assert(() {
      final dto = _profileData.toBackendDto();
      debugPrint('🏢 [VenueSetup] DTO keys: ${dto.keys.toList()}');
      debugPrint(
        '🏢 [VenueSetup] Genres: ${_profileData.gigPreferences.preferredGenres.length}, photos: ${_profileData.venuePhotos.length}',
      );
      return true;
    }());

    final success = await authProvider.completeVenueSetup(_profileData);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      // Reload the venue profile to show updated data
      await authProvider.init();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface(brightness),
                  AppColors.surface(brightness).withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Profile Complete! 🎉',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Your venue profile is live! Start discovering talented artists and bands ready to perform.',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Start Discovering Artists',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    // Save minimal profile with whatever data we have
    final success = await authProvider.completeVenueSetup(_profileData);

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              // Enhanced Header with progress
              _buildEnhancedHeader(brightness),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    VenueBasicInfoStep(
                      profileData: _profileData,
                      onDataChanged: () => setState(() {}),
                      onNext: _nextStep,
                    ),
                    VenueMediaStep(
                      profileData: _profileData,
                      onDataChanged: () => setState(() {}),
                      onNext: _nextStep,
                      onBack: _previousStep,
                    ),
                    VenueDetailsStep(
                      profileData: _profileData,
                      onDataChanged: () => setState(() {}),
                      onNext: _nextStep,
                      onBack: _previousStep,
                    ),
                    GigPreferencesStep(
                      profileData: _profileData,
                      onDataChanged: () => setState(() {}),
                      onNext: _nextStep,
                      onBack: _previousStep,
                    ),
                    VenuePreviewStep(
                      profileData: _profileData,
                      onBack: _previousStep,
                      onComplete: _completeSetup,
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

  Widget _buildEnhancedHeader(Brightness brightness) {
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
                      'Venue Profile Setup',
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
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

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
