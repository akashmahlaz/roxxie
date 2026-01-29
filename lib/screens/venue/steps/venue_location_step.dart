import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 4: VENUE LOCATION
///
/// Collects:
/// - Venue address (street, city, postcode)
/// - Map preview with location pin
/// - Logistics: Parking available, Public transport access

class VenueLocationStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;

  const VenueLocationStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
  });

  @override
  State<VenueLocationStep> createState() => _VenueLocationStepState();
}

class _VenueLocationStepState extends State<VenueLocationStep> {
  late TextEditingController _addressController;
  bool _parkingAvailable = false;
  bool _publicTransportAccess = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text:
          widget.profileData.location.formattedAddress ??
          widget.profileData.location.streetAddress ??
          '',
    );
    _parkingAvailable = widget.profileData.amenities.contains('parking');
    _publicTransportAccess = widget.profileData.amenities.contains(
      'public_transport',
    );
  }

  @override
  void didUpdateWidget(VenueLocationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync when data updates asynchronously
    final currentAddress =
        widget.profileData.location.formattedAddress ??
        widget.profileData.location.streetAddress ??
        '';
    if (currentAddress.isNotEmpty &&
        _addressController.text != currentAddress) {
      _addressController.text = currentAddress;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _updateAmenities() {
    final amenities = <String>[];
    if (_parkingAvailable) amenities.add('parking');
    if (_publicTransportAccess) amenities.add('public_transport');

    // Preserve other amenities
    for (final amenity in widget.profileData.amenities) {
      if (amenity != 'parking' && amenity != 'public_transport') {
        amenities.add(amenity);
      }
    }

    widget.profileData.amenities = amenities;
    widget.onDataChanged();
  }

  void _useCurrentLocation() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Getting your location...'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.crimson,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════════════════
          Text(
            'Where is your venue located?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text(brightness),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps musicians calculate travel time and equipment logistics.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSec(brightness),
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // ADDRESS SEARCH FIELD
          // ═══════════════════════════════════════════════════════════════════
          Text(
            'Venue Address',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.graphite : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Search icon
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.grey[400] : const Color(0xFF876464),
                    size: 24,
                  ),
                ),
                // Text field
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.text(brightness),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Street, City, Postcode',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey[500]
                            : const Color(0xFF876464),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      widget.profileData.location.streetAddress = value;
                      widget.onDataChanged();
                    },
                  ),
                ),
                // Location button
                GestureDetector(
                  onTap: _useCurrentLocation,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.crimson.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: AppColors.crimson,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════════
          // MAP PREVIEW
          // ═══════════════════════════════════════════════════════════════════
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.slate : const Color(0xFFE5DCDC),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Map placeholder
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [AppColors.graphite, AppColors.charcoal]
                          : [const Color(0xFFF0F0F0), const Color(0xFFE0E0E0)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 48,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Map Preview',
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Location pin overlay
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.crimson,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.crimson.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                // Zoom controls
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      _buildZoomButton(Icons.add_rounded, isDark),
                      const SizedBox(height: 8),
                      _buildZoomButton(Icons.remove_rounded, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // LOGISTICS SECTION
          // ═══════════════════════════════════════════════════════════════════
          Text(
            'LOGISTICS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text(brightness),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Parking Available
          _buildLogisticsOption(
            icon: Icons.local_parking_rounded,
            iconColor: Colors.blue,
            iconBgColor: isDark
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.blue.withValues(alpha: 0.1),
            title: 'Parking available',
            subtitle: 'Dedicated space for load-in',
            isChecked: _parkingAvailable,
            isDark: isDark,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _parkingAvailable = value ?? false);
              _updateAmenities();
            },
          ),
          const SizedBox(height: 12),

          // Public Transport
          _buildLogisticsOption(
            icon: Icons.directions_bus_rounded,
            iconColor: Colors.green,
            iconBgColor: isDark
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.green.withValues(alpha: 0.1),
            title: 'Public transport',
            subtitle: 'Easy access for guests',
            isChecked: _publicTransportAccess,
            isDark: isDark,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _publicTransportAccess = value ?? false);
              _updateAmenities();
            },
          ),

          // Bottom padding for safe area
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.graphite : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 20,
        color: AppColors.text(isDark ? Brightness.dark : Brightness.light),
      ),
    );
  }

  Widget _buildLogisticsOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool isChecked,
    required bool isDark,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.graphite : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isChecked
                ? AppColors.crimson.withValues(alpha: 0.5)
                : (isDark ? AppColors.slate : const Color(0xFFE5DCDC)),
            width: isChecked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text(
                        isDark ? Brightness.dark : Brightness.light,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey[500]
                          : const Color(0xFF876464).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.crimson : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isChecked
                      ? AppColors.crimson
                      : (isDark ? AppColors.slate : const Color(0xFFE5DCDC)),
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
