import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'steps/basic_info_step.dart';
import 'steps/media_upload_step.dart';
import 'steps/contact_location_step.dart';
import 'steps/availability_pricing_step.dart';
import 'steps/profile_preview_step.dart';

/// 🎸 ARTIST PROFILE SETUP WIZARD
///
/// Multi-step onboarding flow for artists:
/// Step 1: Basic Info (name, stage name, bio, genres, influences)
/// Step 2: Media Upload (photos, audio samples, videos)
/// Step 3: Contact & Location (phone, social links, location, travel radius)
/// Step 4: Availability & Pricing (calendar, price range)
/// Step 5: Profile Preview & Complete

class ArtistProfileSetupScreen extends StatefulWidget {
  const ArtistProfileSetupScreen({super.key});

  @override
  State<ArtistProfileSetupScreen> createState() =>
      _ArtistProfileSetupScreenState();
}

class _ArtistProfileSetupScreenState extends State<ArtistProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

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

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _completeSetup() {
    // TODO: Save profile data to backend
    // Navigate to artist home/dashboard
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground(Theme.of(context).brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              'Profile Complete!',
              style: TextStyle(
                color: AppColors.text(Theme.of(context).brightness),
              ),
            ),
          ],
        ),
        content: Text(
          'Your artist profile is ready. Venues can now discover you!',
          style: TextStyle(
            color: AppColors.textSec(Theme.of(context).brightness),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to ArtistHomeScreen
            },
            child: Text(
              'Go to Dashboard',
              style: TextStyle(color: AppColors.crimson),
            ),
          ),
        ],
      ),
    );
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
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  BasicInfoStep(profileData: _profileData, onNext: _nextStep),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Back button (only if not on first step)
          if (_currentStep > 0)
            GestureDetector(
              onTap: _previousStep,
              child: Container(
                padding: const EdgeInsets.all(8),
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
            )
          else
            const SizedBox(width: 36),

          const Spacer(),

          // Step counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.crimson.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: TextStyle(
                color: AppColors.crimson,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Spacer(),

          // Skip button (optional for some steps)
          if (_currentStep < _totalSteps - 1)
            TextButton(
              onPressed: _nextStep,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(width: 36),
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
                  color: AppColors.crimson.withOpacity(0.1),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _stepSubtitles[_currentStep],
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 14,
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
}

/// Data model to hold all profile information across steps
class ArtistProfileData {
  // Basic Info
  String? displayName;
  String? stageName;
  String? bio;
  List<String> genres = [];
  List<String> influences = [];

  // Media
  String? profilePhotoPath;
  List<String> photoPaths = [];
  List<AudioSample> audioSamples = [];
  List<VideoSample> videoSamples = [];

  // Contact & Location
  String? phone;
  String? email;
  String? instagram;
  String? spotify;
  String? youtube;
  String? website;
  double? latitude;
  double? longitude;
  String? city;
  String? country;
  int travelRadius = 50; // miles

  // Availability & Pricing
  List<AvailabilitySlot> availability = [];
  double minPrice = 100;
  double maxPrice = 500;
  String currency = 'USD';

  // Computed
  bool get isBasicInfoComplete =>
      displayName != null && displayName!.isNotEmpty && genres.isNotEmpty;

  bool get isMediaComplete => profilePhotoPath != null;

  bool get isContactComplete => phone != null || email != null;

  bool get isAvailabilityComplete => availability.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'stageName': stageName,
    'bio': bio,
    'genres': genres,
    'influences': influences,
    'media': {
      'profilePhoto': profilePhotoPath,
      'photos': photoPaths,
      'audioSamples': audioSamples.map((e) => e.toJson()).toList(),
      'videos': videoSamples.map((e) => e.toJson()).toList(),
    },
    'contact': {
      'phone': phone,
      'email': email,
      'instagram': instagram,
      'spotify': spotify,
      'youtube': youtube,
      'website': website,
    },
    'location': {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'travelRadius': travelRadius,
    },
    'pricing': {'min': minPrice, 'max': maxPrice, 'currency': currency},
    'availability': availability.map((e) => e.toJson()).toList(),
  };
}

class AudioSample {
  final String title;
  final String filePath;
  final Duration? duration;

  AudioSample({required this.title, required this.filePath, this.duration});

  Map<String, dynamic> toJson() => {
    'title': title,
    'filePath': filePath,
    'duration': duration?.inSeconds,
  };
}

class VideoSample {
  final String title;
  final String filePath;
  final String? thumbnailPath;

  VideoSample({
    required this.title,
    required this.filePath,
    this.thumbnailPath,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'filePath': filePath,
    'thumbnail': thumbnailPath,
  };
}

class AvailabilitySlot {
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  bool isBooked;

  AvailabilitySlot({
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'startTime': '${startTime.hour}:${startTime.minute}',
    'endTime': '${endTime.hour}:${endTime.minute}',
    'isBooked': isBooked,
  };
}
