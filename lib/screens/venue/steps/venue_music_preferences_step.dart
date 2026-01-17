import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 2: MUSIC PREFERENCES & GENRES
///
/// Collects:
/// - Preferred music genres (chips)
/// - Location search and map preview

class VenueMusicPreferencesStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;

  const VenueMusicPreferencesStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
  });

  @override
  State<VenueMusicPreferencesStep> createState() => _VenueMusicPreferencesStepState();
}

class _VenueMusicPreferencesStepState extends State<VenueMusicPreferencesStep> {
  late TextEditingController _addressController;
  
  // Genre options
  final List<String> _genreOptions = [
    'Jazz', 'Rock', 'EDM', 'Indie', 'Pop', 'Blues',
    'Hip Hop', 'Country', 'Classical', 'Folk', 'Reggae', 
    'Metal', 'R&B', 'Soul', 'Funk', 'Electronic'
  ];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: widget.profileData.location.formattedAddress ?? 
            widget.profileData.location.streetAddress ?? '',
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _toggleGenre(String genre) {
    HapticFeedback.selectionClick();
    setState(() {
      if (widget.profileData.gigPreferences.preferredGenres.contains(genre)) {
        widget.profileData.gigPreferences.preferredGenres.remove(genre);
      } else {
        widget.profileData.gigPreferences.preferredGenres.add(genre);
      }
    });
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
    final selectedGenres = widget.profileData.gigPreferences.preferredGenres;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // MUSIC PREFERENCES SECTION
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's your vibe?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Select the genres that fit your venue's atmosphere.",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Genre Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _genreOptions.map((genre) {
                final isSelected = selectedGenres.contains(genre);
                return GestureDetector(
                  onTap: () => _toggleGenre(genre),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.crimson 
                          : (isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.crimson 
                            : (isDark ? AppColors.slate : Colors.transparent),
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.crimson.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          genre,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected 
                                ? Colors.white 
                                : AppColors.text(brightness),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: isDark ? AppColors.slate : Colors.grey[200],
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // LOCATION SECTION
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where are you located?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Musicians will see this to calculate travel distance.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.text(brightness),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search address...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (value) {
                        widget.profileData.location.streetAddress = value;
                        widget.onDataChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Map Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                            ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
                            : [const Color(0xFFE8E8E8), const Color(0xFFD0D0D0)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Custom Map Pin
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse effect
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.crimson.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Pin
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.crimson,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.charcoal : Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.charcoal : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.slate : Colors.grey[200]!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'YOUR VENUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: AppColors.text(brightness),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Map Controls
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      children: [
                        _buildMapControl(Icons.add_rounded, isDark, () {}),
                        const SizedBox(height: 8),
                        _buildMapControl(Icons.remove_rounded, isDark, () {}),
                        const SizedBox(height: 8),
                        _buildMapControlPrimary(Icons.my_location_rounded, _useCurrentLocation),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Address Preview
          if (widget.profileData.location.city != null || 
              widget.profileData.location.streetAddress != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: AppColors.crimson,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.profileData.location.streetAddress ?? 
                                widget.profileData.location.city ?? 
                                'Set your address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(brightness),
                            ),
                          ),
                          if (widget.profileData.location.city != null)
                            Text(
                              '${widget.profileData.location.city}, ${widget.profileData.location.country ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom padding
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildMapControl(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
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
      ),
    );
  }

  Widget _buildMapControlPrimary(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.crimson,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}
