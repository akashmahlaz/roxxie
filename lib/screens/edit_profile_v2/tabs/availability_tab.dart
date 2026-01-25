part of '../edit_profile_v2_screen.dart';

/// Availability & Equipment Tab
/// - Travel distance
/// - Equipment list
/// - Availability preferences
class _AvailabilityTab extends StatefulWidget {
  final int maxTravelDistance;
  final List<String> equipment;
  final Function(int) onTravelDistanceChanged;
  final Function(List<String>) onEquipmentChanged;
  final bool isArtist;

  const _AvailabilityTab({
    required this.maxTravelDistance,
    required this.equipment,
    required this.onTravelDistanceChanged,
    required this.onEquipmentChanged,
    required this.isArtist,
  });

  @override
  State<_AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends State<_AvailabilityTab> {
  final _equipmentController = TextEditingController();

  static const List<String> _commonEquipment = [
    'PA System',
    'Microphones',
    'Mixing Board',
    'Stage Monitors',
    'Lighting Rig',
    'DJ Controller',
    'Guitar Amp',
    'Bass Amp',
    'Drum Kit',
    'Keyboard/Piano',
    'In-Ear Monitors',
    'Cables & Stands',
  ];

  void _addEquipment(String item) {
    if (item.isNotEmpty && !widget.equipment.contains(item)) {
      widget.onEquipmentChanged([...widget.equipment, item]);
      _equipmentController.clear();
    }
  }

  void _removeEquipment(String item) {
    widget.onEquipmentChanged(
      widget.equipment.where((e) => e != item).toList(),
    );
  }

  @override
  void dispose() {
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Travel Distance Section
        _buildSectionHeader(context, 'Travel Distance', Icons.directions_car_rounded),
        const SizedBox(height: 8),
        Text(
          'How far are you willing to travel for gigs?',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        
        _buildTravelDistanceSlider(context),

        const SizedBox(height: 32),

        // Equipment Section
        _buildSectionHeader(context, 'Your Equipment', Icons.speaker_rounded),
        const SizedBox(height: 8),
        Text(
          'What gear can you bring to gigs?',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),

        // Quick add chips
        _buildQuickAddChips(context),
        const SizedBox(height: 16),

        // Custom equipment input
        _buildEquipmentInput(context),
        const SizedBox(height: 16),

        // Selected equipment list
        if (widget.equipment.isNotEmpty) ...[
          _buildSelectedEquipment(context),
        ],

        const SizedBox(height: 32),

        // Availability Tips
        _buildAvailabilityTips(context),

        const SizedBox(height: 32),

        // Calendar Link
        _buildCalendarLink(context),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final brightness = Theme.of(context).brightness;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cyan.withValues(alpha: 0.2),
                AppColors.rose.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.cyan, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTravelDistanceSlider(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: AppColors.cyan,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                widget.maxTravelDistance >= 200 
                    ? 'Anywhere' 
                    : '${widget.maxTravelDistance} miles',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.maxTravelDistance >= 200
                ? 'Willing to travel anywhere'
                : 'Maximum travel radius',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.cyan,
              inactiveTrackColor: AppColors.divider(brightness),
              thumbColor: AppColors.cyan,
              overlayColor: AppColors.cyan.withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: widget.maxTravelDistance.toDouble(),
              min: 10,
              max: 200,
              divisions: 19,
              onChanged: (v) => widget.onTravelDistanceChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10 mi',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              Text(
                '100 mi',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              Text(
                '200+ mi',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddChips(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _commonEquipment.map((item) {
        final isSelected = widget.equipment.contains(item);
        
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _addEquipment(item);
            } else {
              _removeEquipment(item);
            }
          },
          backgroundColor: AppColors.surface(brightness),
          selectedColor: AppColors.rose.withValues(alpha: 0.2),
          checkmarkColor: AppColors.rose,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.rose : AppColors.textSec(brightness),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? AppColors.rose : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentInput(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _equipmentController,
            style: TextStyle(color: AppColors.text(brightness)),
            decoration: InputDecoration(
              hintText: 'Add custom equipment...',
              hintStyle: TextStyle(
                color: AppColors.textSec(brightness).withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.add_rounded, color: AppColors.textSec(brightness)),
              filled: true,
              fillColor: AppColors.surface(brightness),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cyan, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onFieldSubmitted: (value) {
              _addEquipment(value.trim());
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: () {
            _addEquipment(_equipmentController.text.trim());
          },
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.cyan,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedEquipment(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'Your Equipment (${widget.equipment.length})',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.equipment.map((item) {
              return Chip(
                label: Text(item),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => _removeEquipment(item),
                backgroundColor: AppColors.cyan.withValues(alpha: 0.1),
                deleteIconColor: AppColors.cyan,
                labelStyle: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.3)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTips(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pro Tips',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip(context, '🎸', 'Having your own equipment increases booking chances by 40%'),
          _buildTip(context, '🚗', 'Artists who travel 50+ miles get 2x more gig opportunities'),
          _buildTip(context, '📅', 'Keep your calendar updated for accurate availability'),
        ],
      ),
    );
  }

  Widget _buildTip(BuildContext context, String emoji, String text) {
    final brightness = Theme.of(context).brightness;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLink(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).pushNamed('/calendar');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cyan.withValues(alpha: 0.1),
              AppColors.rose.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyan, AppColors.rose],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Availability',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Set your available dates and times',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.cyan,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
