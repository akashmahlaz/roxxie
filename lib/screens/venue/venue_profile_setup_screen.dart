import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/models.dart';
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
                'Saving your venue profile...',
                style: TextStyle(color: AppColors.text(brightness)),
              ),
            ],
          ),
        ),
      ),
    );

    // Require valid location before completing venue setup (marketplace quality).
    // Avoid sending invalid 0,0 coordinates which breaks geo discovery and causes server-side errors.
    final hasCity = _profileData.city.trim().isNotEmpty;
    final hasCountry = _profileData.country.trim().isNotEmpty;
    final lat = _profileData.latitude;
    final lng = _profileData.longitude;

    // VenueProfileData.latitude/longitude are non-nullable doubles (default 0).
    // Treat near-zero as "not set" to avoid sending invalid 0,0 coordinates.
    final hasValidCoords =
        lat.abs() > 0.000001 && lng.abs() > 0.000001;

    if (!hasCity || !hasCountry || !hasValidCoords) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

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

    // Build the update request from profile data (DTO-safe payload)
    //
    // Backend expects (UpdateVenueDto):
    // - venueName, venueType, description
    // - preferredGenres
    // - location { city, country, coordinates:[lng,lat], ... }
    // - contactEmail, phone, showPhoneOnProfile
    // - capacity
    // - minBudget, maxBudget, currency
    //
    // NOTE:
    // - Do NOT send legacy keys like `name`, `bio`, `contactPhone`, `isActive` (not whitelisted).
    // - Keep coordinates ordering: [longitude, latitude].

    // Use the gigPreferences object for budget and other preferences
    final request = UpdateVenueRequest(
      venueName: _profileData.venueName,
      description: _profileData.description,
      venueType: _profileData.venueType,
      capacity: _profileData.capacity,
      preferredGenres: _profileData.gigPreferences.preferredGenres,
      location: _profileData.location,
      phone: _profileData.phone,
      showPhoneOnProfile: _profileData.showPhoneOnProfile,
      bookingEmail: _profileData.bookingEmail,
      minBudget: _profileData.gigPreferences.minBudget,
      maxBudget: _profileData.gigPreferences.maxBudget,
      currency: _profileData.gigPreferences.currency,
      equipment: _profileData.equipment,
      socialLinks: _profileData.socialLinks,
      gigPreferences: _profileData.gigPreferences,
      isActive: _profileData.isActive,
      isVisible: _profileData.isVisible,
    );

    final success = await authProvider.completeVenueSetup(_profileData);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface(brightness),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.crimson,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Profile Complete! 🎉'),
            ],
          ),
          content: const Text(
            'Your venue profile is ready! You can now start discovering amazing artists and bands.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text(
                'Start Discovering',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to save profile'),
          backgroundColor: Colors.red.shade400,
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

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            _buildHeader(brightness),

            // Step indicator
            _buildStepIndicator(brightness),

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

          // Skip button (optional for some steps)
          if (_currentStep < _totalSteps - 1)
            TextButton(
              onPressed: _nextStep,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontWeight: FontWeight.w500,
                ),
              ),
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

/// 📊 VENUE PROFILE DATA MODEL
///
/// Complete data structure for venue profile
class VenueProfileData {
  // Basic Info
  String venueName = '';
  String venueType = ''; // Bar, Club, Restaurant, Concert Hall, etc.
  String description = '';
  int capacity = 0;
  List<String> amenities = []; // Stage, Sound System, Parking, etc.

  // Media
  String? coverPhoto;
  List<String> venuePhotos = [];
  List<String> pastEventPhotos = [];

  // Contact & Location
  String? phone;
  bool showPhone = true; // For artists to call directly
  String? email;
  String? website;
  String? instagram;
  String address = '';
  String city = '';
  String country = '';
  double latitude = 0;
  double longitude = 0;

  // Operating Hours
  Map<String, OperatingHours> operatingHours = {};

  // Gig Preferences
  List<String> preferredGenres = [];
  double minBudget = 100;
  double maxBudget = 5000;
  String currency = 'USD';
  List<String> typicalSlots = []; // Evening, Night, Weekend, etc.
  int typicalSetLength = 60; // in minutes
  bool providesAccommodation = false;
  bool providesMeals = false;
  bool providesEquipment = false;

  // Verification
  bool isVerified = false;
  String? verificationDocument;
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
