/// 📍 LOCATION SCREEN - Edit Profile Sub-Screen
///
/// Role-aware location editing:
/// - Artist: City, country, travel radius
/// - Venue: Full address, city, coordinates
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../widgets/edit_profile_widgets.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artistService = ArtistService();
  final _venueService = VenueService();
  final _locationService = LocationService();

  // Controllers
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _addressController;

  // State
  double? _latitude;
  double? _longitude;
  int _travelRadius = 50;
  bool _isLoading = false;
  bool _isLocating = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
    _countryController = TextEditingController();
    _addressController = TextEditingController();
    _initializeData();
  }

  void _initializeData() {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    if (auth.isArtist && profile.artist != null) {
      final artist = profile.artist!;
      _cityController.text = artist.location?.city ?? '';
      _countryController.text = artist.location?.country ?? '';
      _addressController.text = artist.location?.formattedAddress ?? '';
      _latitude = artist.location?.latitude;
      _longitude = artist.location?.longitude;
      _travelRadius = artist.maxTravelDistance;
    } else if (!auth.isArtist && profile.venue != null) {
      final venue = profile.venue!;
      _cityController.text = venue.location?.city ?? '';
      _countryController.text = venue.location?.country ?? '';
      _addressController.text = venue.location?.formattedAddress ?? '';
      _latitude = venue.location?.latitude;
      _longitude = venue.location?.longitude;
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      final permission = await _locationService.requestPermission();
      if (!permission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission is required'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final position = await _locationService.getCurrentLocation();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Get address from coordinates - returns formatted String
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        // Parse address string (format: "City, State, Country")
        final parts = address.split(', ');
        setState(() {
          _addressController.text = address;
          if (parts.isNotEmpty) {
            _cityController.text = parts.first;
          }
          if (parts.length >= 2) {
            _countryController.text = parts.last;
          }
        });
        _markChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    try {
      if (auth.isArtist) {
        final location = Location(
          coordinates: [_longitude ?? 0.0, _latitude ?? 0.0],
          city: _cityController.text.trim(),
          country: _countryController.text.trim(),
          formattedAddress: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );

        await _artistService.updateMyProfile(
          UpdateArtistRequest(
            location: location,
            maxTravelDistance: _travelRadius,
          ),
        );
      } else {
        final location = VenueLocation(
          coordinates: [_longitude ?? 0.0, _latitude ?? 0.0],
          city: _cityController.text.trim(),
          country: _countryController.text.trim(),
          formattedAddress: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );

        await _venueService.updateMyProfile(
          UpdateVenueRequest(location: location),
        );
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Location updated successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final auth = context.watch<AuthProvider>();
    final isArtist = auth.isArtist;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: _buildAppBar(brightness),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-detect Location Button
              _buildLocationButton(brightness),

              const SizedBox(height: 24),

              // City Field
              EditProfileTextField(
                label: 'City',
                controller: _cityController,
                hint: 'Enter your city',
                prefixIcon: Icons.location_city,
                isRequired: true,
                onChanged: (_) => _markChanged(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Country Field
              EditProfileTextField(
                label: 'Country',
                controller: _countryController,
                hint: 'Enter your country',
                prefixIcon: Icons.flag_outlined,
                isRequired: true,
                onChanged: (_) => _markChanged(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Country is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Address Field (optional)
              EditProfileTextField(
                label: 'Address',
                controller: _addressController,
                hint: isArtist ? 'Optional' : 'Full venue address',
                prefixIcon: Icons.home_outlined,
                maxLines: 2,
                onChanged: (_) => _markChanged(),
              ),

              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 20),
                _buildCoordinatesDisplay(brightness),
              ],

              // Travel Radius (Artist only)
              if (isArtist) ...[
                const SizedBox(height: 32),
                _buildTravelRadiusSlider(brightness),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness) {
    return AppBar(
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: AppColors.text(brightness),
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Location',
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_hasChanges)
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.crimson,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLocationButton(Brightness brightness) {
    return GestureDetector(
      onTap: _isLocating ? null : _getCurrentLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.crimson.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.crimson.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.crimson,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLocating
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use Current Location',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Auto-detect your city and coordinates',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.crimson,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatesDisplay(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(brightness),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.gps_fixed,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Set',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_travelRadius km',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'How far are you willing to travel for gigs?',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.crimson,
            inactiveTrackColor: AppColors.border(brightness),
            thumbColor: AppColors.crimson,
            overlayColor: AppColors.crimson.withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _travelRadius.toDouble(),
            min: 10,
            max: 500,
            divisions: 49,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _travelRadius = value.round());
              _markChanged();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10 km',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              Text(
                '500 km',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
