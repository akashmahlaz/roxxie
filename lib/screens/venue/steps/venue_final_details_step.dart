import 'package:flutter/material.dart';
import '../../../core/models/venues_models.dart';
import '../../../core/theme/theme.dart';

/// 🏢 STEP 7: FINAL DETAILS
///
/// Collects:
/// - Venue description (detailed textarea)
/// - Primary contact name
/// - Pro tips & final touches

class VenueFinalDetailsStep extends StatefulWidget {
  final VenueProfileData profileData;
  final VoidCallback onDataChanged;
  final VoidCallback onComplete;

  const VenueFinalDetailsStep({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    required this.onComplete,
  });

  @override
  State<VenueFinalDetailsStep> createState() => _VenueFinalDetailsStepState();
}

class _VenueFinalDetailsStepState extends State<VenueFinalDetailsStep> {
  late TextEditingController _descriptionController;
  late TextEditingController _contactNameController;
  static const int _maxDescriptionLength = 500;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.profileData.description ?? '',
    );
    _contactNameController = TextEditingController(
      text: widget.profileData.contactPerson ?? '',
    );
  }

  @override
  void didUpdateWidget(VenueFinalDetailsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync when data updates
    if (widget.profileData.description != null &&
        widget.profileData.description != _descriptionController.text &&
        widget.profileData.description!.isNotEmpty) {
      _descriptionController.text = widget.profileData.description!;
    }
    if (widget.profileData.contactPerson != null &&
        widget.profileData.contactPerson != _contactNameController.text) {
      _contactNameController.text = widget.profileData.contactPerson!;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  int get _descriptionLength => _descriptionController.text.length;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // SUCCESS HEADER
          // ═══════════════════════════════════════════════════════════════════
          Center(
            child: Column(
              children: [
                // Celebration icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 48,
                    color: AppColors.crimson,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Final Details',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'You\'re almost there! Let\'s polish your profile for musicians to see.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : const Color(0xFF876464),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════════
          // VENUE DESCRIPTION
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Venue Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text(brightness),
                      ),
                    ),
                    Text(
                      '$_descriptionLength/$_maxDescriptionLength',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : const Color(0xFF876464),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.white,
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
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 6,
                    maxLength: _maxDescriptionLength,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.text(brightness),
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tell musicians about your house rules, technical gear (PA, lighting), stage size, and the general vibe of your venue...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : const Color(0xFF876464),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      setState(() {});
                      widget.profileData.description = value;
                      widget.onDataChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════════
          // CONTACT PERSON
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Contact Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text(brightness),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.graphite.withValues(alpha: 0.5) : Colors.white,
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
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: isDark ? Colors.grey[400] : const Color(0xFF876464),
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _contactNameController,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.text(brightness),
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. John Smith',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : const Color(0xFF876464),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 18,
                            ),
                          ),
                          onChanged: (value) {
                            widget.profileData.contactPerson = value;
                            widget.onDataChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════════
          // PRO TIP
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.crimson.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.crimson,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[300] : AppColors.text(brightness),
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: 'Pro-tip: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(brightness),
                            ),
                          ),
                          const TextSpan(
                            text: 'Venues with detailed technical specs get matched with the right talent 40% faster.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom padding for safe area
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
