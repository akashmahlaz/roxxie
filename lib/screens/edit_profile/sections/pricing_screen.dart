/// 💰 PRICING SCREEN - Edit Profile Sub-Screen
///
/// Clean, modern pricing editor with:
/// - Minimal hero display with animated value
/// - Inline currency & rate type selectors
/// - Responsive price inputs
/// - Smart presets for quick selection
/// - Context-aware tips
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _artistService = ArtistService();
  final _venueService = VenueService();

  // Controllers
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _capacityController;
  late AnimationController _pulseController;

  // State
  String _currency = 'USD';
  String _rateType = 'show';
  double _capacity = 100;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Currency data
  static const List<Map<String, String>> _currencies = [
    {'code': 'USD', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'GBP', 'symbol': '£', 'flag': '🇬🇧'},
    {'code': 'CAD', 'symbol': 'C\$', 'flag': '🇨🇦'},
    {'code': 'AUD', 'symbol': 'A\$', 'flag': '🇦🇺'},
    {'code': 'INR', 'symbol': '₹', 'flag': '🇮🇳'},
  ];

  // Quick presets
  static const List<Map<String, dynamic>> _pricePresets = [
    {'label': 'Starter', 'min': 100, 'max': 300},
    {'label': 'Pro', 'min': 300, 'max': 800},
    {'label': 'Premium', 'min': 800, 'max': 2000},
    {'label': 'Elite', 'min': 2000, 'max': 5000},
  ];

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    _capacityController = TextEditingController();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    if (auth.isArtist && profile.artist != null) {
      final artist = profile.artist!;
      _minPriceController.text = artist.minPrice.toStringAsFixed(0);
      _maxPriceController.text = artist.maxPrice.toStringAsFixed(0);
      _currency = artist.currency;
      _rateType = artist.priceRange?.per ?? 'show';
    } else if (!auth.isArtist && profile.venue != null) {
      final venue = profile.venue!;
      _minPriceController.text =
          (venue.gigPreferences?.minBudget ?? 0).toStringAsFixed(0);
      _maxPriceController.text =
          (venue.gigPreferences?.maxBudget ?? 0).toStringAsFixed(0);
      _currency = venue.gigPreferences?.currency ?? 'USD';
      final cap = venue.capacity ?? 100;
      _capacity = cap.toDouble();
      _capacityController.text = cap.toString();
    }
    setState(() {});
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _applyPreset(Map<String, dynamic> preset) {
    HapticFeedback.mediumImpact();
    setState(() {
      _minPriceController.text = preset['min'].toString();
      _maxPriceController.text = preset['max'].toString();
    });
    _markChanged();
  }

  String _getCurrencySymbol() {
    return _currencies.firstWhere((c) => c['code'] == _currency)['symbol']!;
  }

  String _getPricingTip() {
    final max = double.tryParse(_maxPriceController.text) ?? 0;
    if (max == 0) {
      return 'Set your rates to start getting matched';
    }
    if (max < 300) {
      return 'Great for building your portfolio';
    }
    if (max < 800) {
      return 'Competitive rates for experienced artists';
    }
    if (max < 2000) {
      return 'Premium pricing attracts quality venues';
    }
    return 'Elite tier pricing for top performers';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final minPrice = double.tryParse(_minPriceController.text) ?? 0;
    final maxPrice = double.tryParse(_maxPriceController.text) ?? 0;

    if (minPrice > maxPrice && maxPrice > 0) {
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
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Text('Min cannot exceed max price'),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (auth.isArtist) {
        final priceRange = PriceRange(
          min: minPrice,
          max: maxPrice,
          currency: _currency,
          per: _rateType,
        );

        await _artistService.updateMyProfile(
          UpdateArtistRequest(
            priceRange: priceRange,
            minPrice: minPrice,
            maxPrice: maxPrice,
          ),
        );
      } else {
        await _venueService.updateMyProfile(
          UpdateVenueRequest(
            minBudget: minPrice,
            maxBudget: maxPrice,
            currency: _currency,
            capacity: _capacity.round(),
          ),
        );
      }

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
                'Pricing updated!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      navigator.pop(true);
    } catch (e) {
      debugPrint('❌ Pricing save error: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed: ${e.toString().split(':').last.trim()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          ),
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
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _capacityController.dispose();
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
      appBar: _buildAppBar(brightness, isArtist),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Price Display
              _buildHeroCard(brightness, isArtist),

              const SizedBox(height: 28),

              // Settings Section
              _buildSectionTitle(brightness, Icons.settings_rounded, 'Settings'),
              const SizedBox(height: 16),
              _buildSettingsCard(brightness, isArtist),

              const SizedBox(height: 28),

              // Price Range Section
              _buildSectionTitle(
                brightness,
                Icons.tune_rounded,
                isArtist ? 'Your Rate Range' : 'Budget Range',
              ),
              const SizedBox(height: 16),
              _buildPriceInputs(brightness),

              // Quick Presets (Artist only)
              if (isArtist) ...[
                const SizedBox(height: 28),
                _buildSectionTitle(brightness, Icons.bolt_rounded, 'Quick Presets'),
                const SizedBox(height: 16),
                _buildPresets(brightness),
              ],

              // Capacity Section (Venue only)
              if (!isArtist) ...[
                const SizedBox(height: 28),
                _buildCapacitySection(brightness),
              ],

              // Smart Tip
              if (isArtist) ...[
                const SizedBox(height: 28),
                _buildTipCard(brightness),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Brightness brightness, bool isArtist) {
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
        isArtist ? 'Pricing' : 'Budget & Capacity',
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

  Widget _buildSectionTitle(Brightness brightness, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.crimson, size: 20),
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

  Widget _buildHeroCard(Brightness brightness, bool isArtist) {
    final symbol = _getCurrencySymbol();
    final min = double.tryParse(_minPriceController.text) ?? 0;
    final max = double.tryParse(_maxPriceController.text) ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.crimson.withValues(alpha: 0.12),
            AppColors.crimson.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.crimson.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          // Icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.crimson,
                      AppColors.crimson.withValues(alpha: 0.85),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crimson.withValues(
                        alpha: 0.25 + (_pulseController.value * 0.15),
                      ),
                      blurRadius: 16 + (_pulseController.value * 8),
                      spreadRadius: _pulseController.value * 2,
                    ),
                  ],
                ),
                child: Icon(
                  isArtist ? Icons.attach_money_rounded : Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Price display - using FittedBox to prevent overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$symbol${min.toInt()}',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '–',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                Text(
                  '$symbol${max.toInt()}',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Rate type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.text(brightness).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isArtist
                  ? (_rateType == 'hour' ? 'per hour' : 'per show')
                  : 'budget range',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(Brightness brightness, bool isArtist) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        children: [
          // Currency Row
          _buildSettingRow(
            brightness: brightness,
            icon: Icons.language_rounded,
            iconColor: AppColors.cyan,
            label: 'Currency',
            child: _buildCurrencyPicker(brightness),
          ),

          if (isArtist) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: AppColors.border(brightness),
                height: 1,
              ),
            ),

            // Rate Type Row
            _buildSettingRow(
              brightness: brightness,
              icon: Icons.schedule_rounded,
              iconColor: AppColors.success,
              label: 'Rate Type',
              child: _buildRateTypePicker(brightness),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required Brightness brightness,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        child,
      ],
    );
  }

  Widget _buildCurrencyPicker(Brightness brightness) {
    final current = _currencies.firstWhere((c) => c['code'] == _currency);

    return PopupMenuButton<String>(
      onSelected: (value) {
        HapticFeedback.selectionClick();
        setState(() => _currency = value);
        _markChanged();
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface(brightness),
      itemBuilder: (context) => _currencies.map((c) {
        return PopupMenuItem<String>(
          value: c['code'],
          child: Row(
            children: [
              Text(c['flag']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                c['code']!,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.crimson.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current['flag']!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              current['code']!,
              style: TextStyle(
                color: AppColors.crimson,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.crimson,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateTypePicker(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRateOption(brightness, 'show', 'Show'),
          _buildRateOption(brightness, 'hour', 'Hour'),
        ],
      ),
    );
  }

  Widget _buildRateOption(Brightness brightness, String value, String label) {
    final isSelected = _rateType == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _rateType = value);
        _markChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.crimson : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSec(brightness),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInputs(Brightness brightness) {
    final symbol = _getCurrencySymbol();

    return Row(
      children: [
        Expanded(
          child: _buildPriceField(
            brightness: brightness,
            controller: _minPriceController,
            label: 'Min',
            symbol: symbol,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.textSec(brightness),
            size: 18,
          ),
        ),
        Expanded(
          child: _buildPriceField(
            brightness: brightness,
            controller: _maxPriceController,
            label: 'Max',
            symbol: symbol,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required Brightness brightness,
    required TextEditingController controller,
    required String label,
    required String symbol,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textSec(brightness).withValues(alpha: 0.5),
                    ),
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) {
                    _markChanged();
                    setState(() {}); // Update hero display
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresets(Brightness brightness) {
    final min = double.tryParse(_minPriceController.text) ?? 0;
    final max = double.tryParse(_maxPriceController.text) ?? 0;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _pricePresets.map((preset) {
        final isActive = min == preset['min'] && max == preset['max'];

        return GestureDetector(
          onTap: () => _applyPreset(preset),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        AppColors.crimson,
                        AppColors.crimson.withValues(alpha: 0.85),
                      ],
                    )
                  : null,
              color: isActive ? null : AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? AppColors.crimson : AppColors.border(brightness),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  preset['label'],
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.text(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${preset['min']} - \$${preset['max']}',
                  style: TextStyle(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSec(brightness),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCapacitySection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(brightness, Icons.people_alt_rounded, 'Venue Capacity'),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Column(
            children: [
              // Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan.withValues(alpha: 0.1),
                      AppColors.cyan.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _capacity.round().toString(),
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'guests maximum',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.cyan,
                  inactiveTrackColor: AppColors.border(brightness),
                  thumbColor: AppColors.cyan,
                  overlayColor: AppColors.cyan.withValues(alpha: 0.2),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                    elevation: 4,
                  ),
                ),
                child: Slider(
                  value: _capacity.clamp(0, 5000),
                  min: 0,
                  max: 5000,
                  divisions: 100,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _capacity = value;
                      _capacityController.text = value.round().toString();
                    });
                    _markChanged();
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '5000+',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.success.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _getPricingTip(),
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
