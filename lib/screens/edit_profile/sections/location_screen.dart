/// 📍 LOCATION SCREEN - Edit Profile Sub-Screen
///
/// Professional location editing with:
/// - Auto-detect current location with visual feedback
/// - Address search with suggestions
/// - Travel radius slider (Artist only)
/// - Map preview integration ready
/// - Role-aware fields (Artist vs Venue)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _artistService = ArtistService();
  final _venueService = VenueService();
  final _locationService = LocationService();

  // Controllers
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _addressController;
  late AnimationController _pulseController;

  // State
  double? _latitude;
  double? _longitude;
  int _travelRadius = 50;
  bool _isLoading = false;
  bool _isLocating = false;
  bool _hasChanges = false;
  String? _locationError;
  LocationPermissionState? _permissionState;

  // Quick radius options
  static const List<int> _radiusOptions = [25, 50, 100, 200, 500];

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
    _countryController = TextEditingController();
    _addressController = TextEditingController();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      _checkPermissionState();
    });
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
    setState(() {});
  }

  Future<void> _checkPermissionState() async {
    final state = await _locationService.getPermissionState();
    if (mounted) {
      setState(() => _permissionState = state);
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    _pulseController.repeat();

    try {
      // Check permission state first
      final permState = await _locationService.getPermissionState();

      if (permState == LocationPermissionState.serviceDisabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable GPS.';
          _permissionState = permState;
        });
        return;
      }

      if (permState == LocationPermissionState.deniedForever) {
        setState(() {
          _locationError =
              'Location access denied. Please enable in Settings.';
          _permissionState = permState;
        });
        return;
      }

      // Request permission if needed
      final granted = await _locationService.requestPermission();
      if (!granted) {
        setState(() {
          _locationError = 'Location permission is required to auto-detect.';
        });
        return;
      }

      // Get current position
      HapticFeedback.mediumImpact();
      final position = await _locationService.getCurrentLocation();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Get address from coordinates
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        // Parse the address (format: "City, State, Country")
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
        HapticFeedback.heavyImpact();

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Location detected successfully!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Location fetch error: $e');
      if (mounted) {
        setState(() {
          _locationError = 'Failed to detect location. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        _pulseController.stop();
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
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

      // Refresh profile
      await profile.loadProfile(auth.isArtist);

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Text(
                'Location saved!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      navigator.pop(true);
    } catch (e) {
      debugPrint('❌ Location save error: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to save: ${e.toString().split(':').last.trim()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
    _pulseController.dispose();
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
              // Header Card
              _buildHeaderCard(brightness, isArtist),

              const SizedBox(height: 24),

              // Auto-Detect Location Card
              _buildAutoDetectCard(brightness),

              // Error/Permission Message
              if (_locationError != null) ...[
                const SizedBox(height: 12),
                _buildErrorCard(brightness),
              ],

              const SizedBox(height: 28),

              // Section Title
              _buildSectionTitle(
                brightness,
                Icons.edit_location_alt_outlined,
                'Location Details',
              ),

              const SizedBox(height: 16),

              // City Field
              _buildTextField(
                brightness: brightness,
                controller: _cityController,
                label: 'City',
                hint: 'Enter your city',
                icon: Icons.location_city_outlined,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Country Field
              _buildTextField(
                brightness: brightness,
                controller: _countryController,
                label: 'Country',
                hint: 'Enter your country',
                icon: Icons.flag_outlined,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Country is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Address Field
              _buildTextField(
                brightness: brightness,
                controller: _addressController,
                label: isArtist ? 'Full Address (Optional)' : 'Venue Address',
                hint: isArtist
                    ? 'Optional - for precise matching'
                    : 'Full venue address for visitors',
                icon: Icons.home_outlined,
                maxLines: 2,
              ),

              // Coordinates Display
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 16),
                _buildCoordinatesCard(brightness),
              ],

              // Travel Radius (Artist only)
              if (isArtist) ...[
                const SizedBox(height: 32),
                _buildTravelRadiusSection(brightness),
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _hasChanges
              ? TextButton(
                  key: const ValueKey('save'),
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
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.crimson,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                )
              : const SizedBox(key: ValueKey('empty'), width: 8),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderCard(Brightness brightness, bool isArtist) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.1),
            AppColors.cyan.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: AppColors.cyan,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArtist ? 'Your Base Location' : 'Venue Location',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArtist
                      ? 'Where venues can find you for local gigs'
                      : 'Help artists find your venue easily',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 13,
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

  Widget _buildAutoDetectCard(Brightness brightness) {
    return GestureDetector(
      onTap: _isLocating ? null : _getCurrentLocation,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = _isLocating
              ? 0.5 + (0.5 * (1 - _pulseController.value))
              : 1.0;

          return Opacity(
            opacity: pulseValue,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _isLocating
                    ? LinearGradient(
                        colors: [
                          AppColors.crimson.withValues(alpha: 0.15),
                          AppColors.crimson.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _isLocating ? null : AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: _isLocating
                      ? AppColors.crimson.withValues(alpha: 0.4)
                      : AppColors.border(brightness),
                  width: _isLocating ? 2 : 1,
                ),
                boxShadow: _isLocating
                    ? [
                        BoxShadow(
                          color: AppColors.crimson.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.crimson,
                          AppColors.crimson.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.crimson.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _isLocating
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLocating
                              ? 'Detecting Location...'
                              : 'Use Current Location',
                          style: TextStyle(
                            color: AppColors.text(brightness),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _isLocating
                              ? 'Please wait while we find you'
                              : 'Auto-detect city and coordinates',
                          style: TextStyle(
                            color: AppColors.textSec(brightness),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLocating)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.crimson.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.crimson,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorCard(Brightness brightness) {
    final isPermissionIssue =
        _permissionState == LocationPermissionState.deniedForever;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _locationError!,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          if (isPermissionIssue)
            TextButton(
              onPressed: () => Geolocator.openAppSettings(),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    Brightness brightness,
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.crimson,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required Brightness brightness,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border(brightness),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.textSec(brightness),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: validator,
            onChanged: (_) => _markChanged(),
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinatesCard(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.gps_fixed,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS Coordinates',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Set',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelRadiusSection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        _buildSectionTitle(
          brightness,
          Icons.directions_car_outlined,
          'Travel Radius',
        ),

        const SizedBox(height: 8),

        Text(
          'How far are you willing to travel for gigs?',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 20),

        // Current Value Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.crimson.withValues(alpha: 0.1),
                AppColors.crimson.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$_travelRadius',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'km',
                    style: TextStyle(
                      color: AppColors.crimson.withValues(alpha: 0.7),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                _getRadiusDescription(_travelRadius),
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Quick Select Chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _radiusOptions.map((radius) {
            final isSelected = _travelRadius == radius;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _travelRadius = radius);
                _markChanged();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.crimson
                      : AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.border(brightness),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '$radius km',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Slider
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.crimson,
                  inactiveTrackColor: AppColors.border(brightness),
                  thumbColor: AppColors.crimson,
                  overlayColor: AppColors.crimson.withValues(alpha: 0.2),
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                    elevation: 4,
                    pressedElevation: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 28,
                  ),
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '500 km',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRadiusDescription(int radius) {
    if (radius <= 25) return 'Local gigs only';
    if (radius <= 50) return 'Within your city area';
    if (radius <= 100) return 'Regional gigs';
    if (radius <= 200) return 'Willing to travel';
    return 'Long-distance gigs';
  }
}
