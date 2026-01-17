import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 1: LOCATION & MUSIC PREFERENCES
/// 
/// Minimal step collecting only essential matching info:
/// - Location (city, map pin) → For distance-based matching
/// - Preferred genres → For music style matching
/// 
/// This step is SKIPPABLE - user can proceed without filling

class Step1LocationMusic extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const Step1LocationMusic({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<Step1LocationMusic> createState() => _Step1LocationMusicState();
}

class _Step1LocationMusicState extends State<Step1LocationMusic> {
  late TextEditingController _cityController;
  
  // Available genres for selection
  final List<String> _allGenres = [
    'Jazz', 'Rock', 'Pop', 'EDM', 'Hip Hop', 'R&B',
    'Country', 'Blues', 'Classical', 'Indie', 'Folk', 
    'Reggae', 'Metal', 'Soul', 'Funk', 'Latin',
  ];

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(
      text: widget.profileData.location.city ?? '',
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _toggleGenre(String genre) {
    HapticFeedback.selectionClick();
    setState(() {
      final genres = widget.profileData.gigPreferences.preferredGenres;
      if (genres.contains(genre)) {
        genres.remove(genre);
      } else {
        genres.add(genre);
      }
    });
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final selectedGenres = widget.profileData.gigPreferences.preferredGenres;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════════════
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.crimson,
                    AppColors.crimson.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: Text(
              'Where are you located?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text(brightness),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Help musicians find gigs near them',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // LOCATION INPUT
          // ═══════════════════════════════════════════════════════════════
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.graphite : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.slate : Colors.grey[300]!,
              ),
            ),
            child: TextField(
              controller: _cityController,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your city',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  size: 24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
              ),
              onChanged: (value) {
                widget.profileData.location.city = value;
                widget.onDataChanged();
              },
            ),
          ),
          const SizedBox(height: 16),

          // Map Preview Placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? AppColors.graphite : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.slate : Colors.grey[300]!,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Map preview',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Location pin overlay
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.crimson,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // ═══════════════════════════════════════════════════════════════
          // MUSIC PREFERENCES
          // ═══════════════════════════════════════════════════════════════
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.music_note_rounded,
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
                      "What's your vibe?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(brightness),
                      ),
                    ),
                    Text(
                      'Select genres you prefer',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Genre Chips
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: _allGenres.map((genre) {
              final isSelected = selectedGenres.contains(genre);
              return GestureDetector(
                onTap: () => _toggleGenre(genre),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.crimson 
                        : (isDark ? AppColors.graphite : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.crimson 
                          : (isDark ? AppColors.slate : Colors.grey[300]!),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        genre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
          
          // Bottom spacing for button
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
