import 'package:flutter/material.dart';
import '../../../core/models/venue_models.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/services.dart';


/// 📍 STEP 3: VENUE DETAILS
///
/// Collects:
/// - Address & Location
/// - Contact Info (phone, email)
/// - Website & Social Links
/// - Operating Hours

class VenueDetailsStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const VenueDetailsStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<VenueDetailsStep> createState() => _VenueDetailsStepState();
}

class _VenueDetailsStepState extends State<VenueDetailsStep> {
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  bool _isGettingLocation = false;
  final LocationService _locationService = LocationService();

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: widget.profileData.address,
    );
    _cityController = TextEditingController(text: widget.profileData.city);
    _phoneController = TextEditingController(text: widget.profileData.phone);
    _emailController = TextEditingController(text: widget.profileData.email);
    _websiteController = TextEditingController(
      text: widget.profileData.website,
    );
    _instagramController = TextEditingController(
      text: widget.profileData.instagram,
    );

    // Initialize operating hours if empty
    if (widget.profileData.operatingHours.isEmpty) {
      for (final day in _weekDays) {
        widget.profileData.operatingHours[day] = OperatingHours();
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      widget.profileData.address.isNotEmpty &&
      widget.profileData.city.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Section
          _buildSectionHeader(
            'Location',
            Icons.location_on_rounded,
            brightness,
          ),
          const SizedBox(height: 16),
          _buildLocationSection(brightness),

          const SizedBox(height: 32),

          // Contact Section
          _buildSectionHeader(
            'Contact Info',
            Icons.contact_phone_rounded,
            brightness,
          ),
          const SizedBox(height: 16),
          _buildContactSection(brightness),

          const SizedBox(height: 32),

          // Online Presence Section
          _buildSectionHeader(
            'Online Presence',
            Icons.language_rounded,
            brightness,
          ),
          const SizedBox(height: 16),
          _buildOnlineSection(brightness),

          const SizedBox(height: 32),

          // Operating Hours Section
          _buildSectionHeader(
            'Operating Hours',
            Icons.schedule_rounded,
            brightness,
          ),
          const SizedBox(height: 16),
          _buildOperatingHoursSection(brightness),

          const SizedBox(height: 40),

          // Navigation Buttons
          _buildNavigationButtons(brightness),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Brightness brightness,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.crimson, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(Brightness brightness) {
    return Column(
      children: [
        // Use current location
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _isGettingLocation ? null : () => _fillFromCurrentLocation(brightness),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.crimson),
          ),
        ),

        // Address
        _buildTextField(
          controller: _addressController,
          label: 'Street Address *',
          hint: '123 Music Street',
          icon: Icons.home_rounded,
          brightness: brightness,
          onChanged: (value) {
            widget.profileData.address = value;
            widget.onDataChanged();
          },
        ),

        const SizedBox(height: 14),

        // City
        _buildTextField(
          controller: _cityController,
          label: 'City *',
          hint: 'Los Angeles',
          icon: Icons.location_city_rounded,
          brightness: brightness,
          onChanged: (value) {
            widget.profileData.city = value;
            widget.onDataChanged();
          },
        ),

        const SizedBox(height: 14),

        // Country Dropdown
        _buildCountrySelector(brightness),

        const SizedBox(height: 16),

        // Map Placeholder
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_rounded,
                color: AppColors.textSec(brightness),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Map preview coming soon',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _fillFromCurrentLocation(Brightness brightness) async {
    setState(() => _isGettingLocation = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _locationService.getCurrentLocationWithAddress();
      if (result == null) {
        final state = await _locationService.getPermissionState();
        final isPermissionIssue = state == LocationPermissionState.deniedForever ||
            state == LocationPermissionState.denied;

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isPermissionIssue
                  ? 'Location permission is turned off. Enable it in Settings to auto-fill your venue location.'
                  : 'Location services are off. Turn on Location to auto-fill your venue location.',
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

      // Update controllers + model
      _addressController.text = result.address;
      widget.profileData.address = result.address;

      if (result.city?.isNotEmpty == true) {
        _cityController.text = result.city!;
        widget.profileData.city = result.city!;
      }
      if (result.country?.isNotEmpty == true) {
        widget.profileData.country = result.country!;
      }
      widget.profileData.latitude = result.latitude;
      widget.profileData.longitude = result.longitude;

      widget.onDataChanged();

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

  Widget _buildContactSection(Brightness brightness) {
    return Column(
      children: [
        // Phone with visibility toggle
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+1 (555) 123-4567',
          icon: Icons.phone_rounded,
          brightness: brightness,
          keyboardType: TextInputType.phone,
          onChanged: (value) {
            widget.profileData.phone = value;
            widget.onDataChanged();
          },
        ),

        const SizedBox(height: 10),

        // Show phone toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                color: AppColors.crimson,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show on profile',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Let artists call you directly',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.profileData.showPhone,
                onChanged: (value) {
                  setState(() {
                    widget.profileData.showPhone = value;
                  });
                  widget.onDataChanged();
                },
                activeThumbColor: AppColors.crimson,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Email
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'bookings@venue.com',
          icon: Icons.email_rounded,
          brightness: brightness,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            widget.profileData.email = value;
            widget.onDataChanged();
          },
        ),
      ],
    );
  }

  Widget _buildOnlineSection(Brightness brightness) {
    return Column(
      children: [
        _buildTextField(
          controller: _websiteController,
          label: 'Website',
          hint: 'www.yourvenue.com',
          icon: Icons.language_rounded,
          brightness: brightness,
          keyboardType: TextInputType.url,
          onChanged: (value) {
            widget.profileData.website = value;
            widget.onDataChanged();
          },
        ),

        const SizedBox(height: 14),

        _buildTextField(
          controller: _instagramController,
          label: 'Instagram',
          hint: '@yourvenue',
          icon: Icons.camera_alt_rounded,
          brightness: brightness,
          onChanged: (value) {
            widget.profileData.instagram = value;
            widget.onDataChanged();
          },
        ),
      ],
    );
  }

  Widget _buildOperatingHoursSection(Brightness brightness) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        children: _weekDays.map((day) {
          final hours = widget.profileData.operatingHours[day]!;
          return _buildDayRow(day, hours, brightness);
        }).toList(),
      ),
    );
  }

  Widget _buildDayRow(String day, OperatingHours hours, Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: day != 'Sunday'
              ? BorderSide(color: AppColors.border(brightness))
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Day Name
          SizedBox(
            width: 80,
            child: Text(
              day.substring(0, 3),
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Open Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                hours.isOpen = !hours.isOpen;
                if (hours.isOpen) {
                  hours.openTime ??= const TimeOfDay(hour: 18, minute: 0);
                  hours.closeTime ??= const TimeOfDay(hour: 2, minute: 0);
                }
              });
              widget.onDataChanged();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hours.isOpen
                    ? AppColors.crimson.withValues(alpha: 0.15)
                    : AppColors.background(brightness),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hours.isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  color: hours.isOpen
                      ? AppColors.crimson
                      : AppColors.textSec(brightness),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Time Pickers
          if (hours.isOpen) ...[
            GestureDetector(
              onTap: () => _pickTime(day, true, brightness),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background(brightness),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: Text(
                  hours.openTime?.format(context) ?? '--:--',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '-',
                style: TextStyle(color: AppColors.textSec(brightness)),
              ),
            ),
            GestureDetector(
              onTap: () => _pickTime(day, false, brightness),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background(brightness),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border(brightness)),
                ),
                child: Text(
                  hours.closeTime?.format(context) ?? '--:--',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickTime(
    String day,
    bool isOpenTime,
    Brightness brightness,
  ) async {
    final hours = widget.profileData.operatingHours[day]!;
    final initialTime = isOpenTime
        ? hours.openTime
        : hours.closeTime ?? const TimeOfDay(hour: 18, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime!,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.crimson,
              surface: AppColors.surface(brightness),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          hours.openTime = picked;
        } else {
          hours.closeTime = picked;
        }
      });
      widget.onDataChanged();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Brightness brightness,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (value) {
              onChanged(value);
              setState(() {});
            },
            style: TextStyle(color: AppColors.text(brightness)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textSec(brightness)),
              prefixIcon: Icon(icon, color: AppColors.crimson, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountrySelector(Brightness brightness) {
    final countries = [
      'United States',
      'United Kingdom',
      'Canada',
      'Australia',
      'India',
      'Germany',
      'France',
      'Spain',
      'Other',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.profileData.country.isEmpty
                  ? null
                  : widget.profileData.country,
              hint: Text(
                'Select country',
                style: TextStyle(color: AppColors.textSec(brightness)),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSec(brightness),
              ),
              dropdownColor: AppColors.surface(brightness),
              items: countries.map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(
                    country,
                    style: TextStyle(color: AppColors.text(brightness)),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  widget.profileData.country = value ?? '';
                });
                widget.onDataChanged();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(Brightness brightness) {
    return Row(
      children: [
        // Back Button
        Expanded(
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(brightness)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.text(brightness),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Continue Button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _isValid ? widget.onNext : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _isValid
                    ? const LinearGradient(
                        colors: [AppColors.crimson, Color(0xFFFF4D6D)],
                      )
                    : null,
                color: _isValid ? null : AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isValid
                      ? Colors.transparent
                      : AppColors.border(brightness),
                ),
                boxShadow: _isValid
                    ? [
                        BoxShadow(
                          color: AppColors.crimson.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: _isValid
                          ? Colors.white
                          : AppColors.textSec(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: _isValid
                        ? Colors.white
                        : AppColors.textSec(brightness),
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
