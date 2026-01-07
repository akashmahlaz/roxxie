import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/services.dart';
import '../artist_profile_setup_screen.dart';

/// Step 3: Contact & Location
/// - Phone Number (for quick calls - important feature!)
/// - Email
/// - Social Links (Instagram, Spotify, YouTube, Website)
/// - Location (City, Country)
/// - Travel Radius

class ContactLocationStep extends StatefulWidget {
  final ArtistProfileData profileData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ContactLocationStep({
    super.key,
    required this.profileData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ContactLocationStep> createState() => _ContactLocationStepState();
}

class _ContactLocationStepState extends State<ContactLocationStep> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _instagramController = TextEditingController();
  final _spotifyController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  bool _showPhoneInProfile = true;
  bool _isGettingLocation = false;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // Pre-fill existing data
    _phoneController.text = widget.profileData.phone ?? '';
    _emailController.text = widget.profileData.email ?? '';
    _instagramController.text = widget.profileData.instagram ?? '';
    _spotifyController.text = widget.profileData.spotify ?? '';
    _youtubeController.text = widget.profileData.youtube ?? '';
    _websiteController.text = widget.profileData.website ?? '';
    _cityController.text = widget.profileData.city ?? '';
    _countryController.text = widget.profileData.country ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _instagramController.dispose();
    _spotifyController.dispose();
    _youtubeController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      // Save data
      widget.profileData.phone = _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null;
      widget.profileData.email = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null;
      widget.profileData.instagram = _instagramController.text.trim().isNotEmpty
          ? _instagramController.text.trim()
          : null;
      widget.profileData.spotify = _spotifyController.text.trim().isNotEmpty
          ? _spotifyController.text.trim()
          : null;
      widget.profileData.youtube = _youtubeController.text.trim().isNotEmpty
          ? _youtubeController.text.trim()
          : null;
      widget.profileData.website = _websiteController.text.trim().isNotEmpty
          ? _websiteController.text.trim()
          : null;
      widget.profileData.city = _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : null;
      widget.profileData.country = _countryController.text.trim().isNotEmpty
          ? _countryController.text.trim()
          : null;

      // Validate at least one contact method
      if (widget.profileData.phone == null &&
          widget.profileData.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please provide at least a phone or email'),
            backgroundColor: AppColors.crimson,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Important notice about phone
            _buildPhoneNotice(brightness),

            const SizedBox(height: 20),

            // Phone Number Section
            _buildSectionTitle(
              'Phone Number',
              brightness,
              icon: Icons.phone_rounded,
              subtitle: 'For quick venue calls',
            ),
            const SizedBox(height: 12),
            _buildPhoneField(brightness),

            const SizedBox(height: 8),
            _buildPhoneVisibilityToggle(brightness),

            const SizedBox(height: 24),

            // Email
            _buildSectionTitle(
              'Email Address',
              brightness,
              icon: Icons.email_rounded,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              hint: 'your@email.com',
              brightness: brightness,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // Social Links Section
            _buildSectionTitle(
              'Social Links',
              brightness,
              icon: Icons.share_rounded,
              subtitle: 'Help venues find your music',
              isOptional: true,
            ),
            const SizedBox(height: 12),

            // Instagram
            _buildSocialField(
              controller: _instagramController,
              platform: 'Instagram',
              hint: '@yourusername',
              icon: Icons.camera_alt_rounded,
              brightness: brightness,
            ),
            const SizedBox(height: 12),

            // Spotify
            _buildSocialField(
              controller: _spotifyController,
              platform: 'Spotify',
              hint: 'Spotify artist link',
              icon: Icons.music_note_rounded,
              brightness: brightness,
            ),
            const SizedBox(height: 12),

            // YouTube
            _buildSocialField(
              controller: _youtubeController,
              platform: 'YouTube',
              hint: 'YouTube channel link',
              icon: Icons.play_circle_rounded,
              brightness: brightness,
            ),
            const SizedBox(height: 12),

            // Website
            _buildSocialField(
              controller: _websiteController,
              platform: 'Website',
              hint: 'www.yourwebsite.com',
              icon: Icons.language_rounded,
              brightness: brightness,
            ),

            const SizedBox(height: 28),

            // Location Section
            _buildSectionTitle(
              'Location',
              brightness,
              icon: Icons.location_on_rounded,
              subtitle: 'For local gig matching',
            ),
            const SizedBox(height: 12),

            // Use current location
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isGettingLocation ? null : _fillFromCurrentLocation,
                icon: _isGettingLocation
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.crimson,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Use current location'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.crimson,
                ),
              ),
            ),

            // City & Country
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _cityController,
                    hint: 'City',
                    brightness: brightness,
                    prefixIcon: Icons.location_city_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _countryController,
                    hint: 'Country',
                    brightness: brightness,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Travel Radius Slider
            _buildTravelRadiusSlider(brightness),

            const SizedBox(height: 32),

            // Navigation Buttons
            _buildNavigationButtons(brightness),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _fillFromCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    // Capture messenger before async gap
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _locationService.getCurrentLocationWithAddress();
      if (result == null) {
        final state = await _locationService.getPermissionState();
        final isPermissionIssue = state == LocationPermissionState.deniedPreviously ||
            state == LocationPermissionState.deniedForever ||
            state == LocationPermissionState.denied;

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isPermissionIssue
                  ? 'Location permission is turned off. Enable it in Settings to auto-fill your city/country.'
                  : 'Location services are off. Turn on Location to auto-fill your city/country.',
            ),
            backgroundColor: AppColors.crimson,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => isPermissionIssue
                  ? _locationService.openLocationSettings()
                  : _locationService.openDeviceLocationSettings(),
            ),
          ),
        );
        return;
      }

      // Update controllers + data model
      if (result.city?.isNotEmpty == true) {
        _cityController.text = result.city!;
        widget.profileData.city = result.city;
      }
      if (result.country?.isNotEmpty == true) {
        _countryController.text = result.country!;
        widget.profileData.country = result.country;
      }
      widget.profileData.latitude = result.latitude;
      widget.profileData.longitude = result.longitude;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Location detected!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Widget _buildPhoneNotice(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.crimson.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.crimson,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Contact Tip',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Venues often prefer to call for last-minute bookings. Adding your phone number increases your chances!',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    Brightness brightness, {
    IconData? icon,
    String? subtitle,
    bool isOptional = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.crimson, size: 20),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isOptional) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.border(brightness),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Optional',
                        style: TextStyle(
                          color: AppColors.textTert(brightness),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(Brightness brightness) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: TextStyle(color: AppColors.text(brightness), fontSize: 15),
      decoration: InputDecoration(
        hintText: '+1 (555) 123-4567',
        hintStyle: TextStyle(
          color: AppColors.textTert(brightness),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          Icons.phone_rounded,
          color: AppColors.textSec(brightness),
        ),
        filled: true,
        fillColor: AppColors.inputFill(brightness),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.crimson, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPhoneVisibilityToggle(Brightness brightness) {
    return GestureDetector(
      onTap: () => setState(() => _showPhoneInProfile = !_showPhoneInProfile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            Icon(
              _showPhoneInProfile
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: _showPhoneInProfile
                  ? AppColors.crimson
                  : AppColors.textTert(brightness),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Show phone number on profile',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 14,
                ),
              ),
            ),
            Switch(
              value: _showPhoneInProfile,
              onChanged: (value) => setState(() => _showPhoneInProfile = value),
              activeThumbColor: AppColors.crimson,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Brightness brightness,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.text(brightness), fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textTert(brightness),
          fontSize: 15,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textSec(brightness))
            : null,
        filled: true,
        fillColor: AppColors.inputFill(brightness),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.crimson, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String platform,
    required String hint,
    required IconData icon,
    required Brightness brightness,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSec(brightness), size: 18),
                const SizedBox(width: 8),
                Text(
                  platform,
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: AppColors.text(brightness), fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.textTert(brightness),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelRadiusSlider(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Travel Radius',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.profileData.travelRadius} miles',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.crimson,
            inactiveTrackColor: AppColors.border(brightness),
            thumbColor: AppColors.crimson,
            overlayColor: AppColors.crimson.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 6,
          ),
          child: Slider(
            value: widget.profileData.travelRadius.toDouble(),
            min: 10,
            max: 200,
            divisions: 19,
            onChanged: (value) {
              setState(() {
                widget.profileData.travelRadius = value.toInt();
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '10 mi',
              style: TextStyle(
                color: AppColors.textTert(brightness),
                fontSize: 11,
              ),
            ),
            Text(
              '200 mi',
              style: TextStyle(
                color: AppColors.textTert(brightness),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(Brightness brightness) {
    return Row(
      children: [
        // Back button
        Expanded(
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Center(
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Continue button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _validateAndContinue,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.crimson,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
