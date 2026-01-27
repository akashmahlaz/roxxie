/// 💰 PRICING SCREEN - Edit Profile Sub-Screen
///
/// Professional pricing/budget editing with:
/// - Visual currency selector
/// - Smart rate type switching (Hour vs Show) for Artists
/// - Budget range configuration for Venues
/// - Capacity slider for Venues
/// - Gradient UI elements matching app theme
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

class _PricingScreenState extends State<PricingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artistService = ArtistService();
  final _venueService = VenueService();

  // Controllers
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _capacityController;

  // State
  String _currency = 'USD';
  String _rateType = 'show'; // 'show', 'hour'
  double _capacity = 100;
  bool _isLoading = false;
  bool _hasChanges = false;

  static const List<Map<String, String>> _currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  ];

  static const List<Map<String, dynamic>> _rateTypes = [
    {'id': 'show', 'label': 'Per Show', 'icon': Icons.mic_external_on_outlined},
    {'id': 'hour', 'label': 'Per Hour', 'icon': Icons.access_time_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    _capacityController = TextEditingController();
    
    // Defer initialization to access context safely
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
      _minPriceController.text = (venue.gigPreferences?.minBudget ?? 0).toStringAsFixed(0);
      _maxPriceController.text = (venue.gigPreferences?.maxBudget ?? 0).toStringAsFixed(0);
      _currency = venue.gigPreferences?.currency ?? 'USD';
      
      final cap = venue.capacity ?? 0;
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
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Minimum price cannot be higher than maximum'),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusInput)),
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
                'Pricing updated successfully!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusInput)),
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
                  'Failed to save: ${e.toString().split(':').last.trim()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusInput)),
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
              // Header Card
              _buildHeaderCard(brightness, isArtist),

              const SizedBox(height: 28),

              // Currency Selection
              _buildSectionTitle(
                brightness,
                Icons.currency_exchange_rounded,
                'Currency',
              ),
              const SizedBox(height: 16),
              _buildCurrencySelector(brightness),

              const SizedBox(height: 32),

              // Rate Type (Artist Only)
              if (isArtist) ...[
                _buildSectionTitle(
                  brightness,
                  Icons.tune_rounded,
                  'Rate Type',
                ),
                const SizedBox(height: 16),
                _buildRateTypeSelector(brightness),
                const SizedBox(height: 32),
              ],

              // Price Range Input
              _buildSectionTitle(
                brightness,
                isArtist ? Icons.payments_outlined : Icons.account_balance_wallet_outlined,
                isArtist ? 'Price Range' : 'Budget Range',
              ),
              const SizedBox(height: 16),
              _buildPriceRangeInputs(brightness, isArtist),

              // Capacity Slider (Venue Only)
              if (!isArtist) ...[
                const SizedBox(height: 32),
                _buildCapacitySection(brightness),
              ],

              const SizedBox(height: 32),

              // Summary Card
              _buildSummaryCard(brightness, isArtist),

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

  Widget _buildHeaderCard(Brightness brightness, bool isArtist) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.success.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
            ),
            child: Icon(
              isArtist ? Icons.monetization_on_rounded : Icons.storefront_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArtist ? 'Set Your Rates' : 'Budget & Capacity',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArtist
                      ? 'Define your expected earnings range per show or hour'
                      : 'Help artists match with your venue size and budget',
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

  Widget _buildCurrencySelector(Brightness brightness) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _currencies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final currency = _currencies[index];
          final isSelected = _currency == currency['code'];
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _currency = currency['code']!);
              _markChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.crimson : AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.crimson : AppColors.border(brightness),
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
              alignment: Alignment.center,
              child: Row(
                children: [
                  Text(
                    currency['symbol']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text(brightness),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currency['code']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.textSec(brightness),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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

  Widget _buildRateTypeSelector(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Row(
        children: _rateTypes.map((type) {
          final isSelected = _rateType == type['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _rateType = type['id']);
                _markChanged();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.crimson : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusInput - 4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type['icon'],
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.textSec(brightness),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSec(brightness),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceRangeInputs(Brightness brightness, bool isArtist) {
    final symbol = _currencies.firstWhere((c) => c['code'] == _currency)['symbol']!;
    
    return Row(
      children: [
        Expanded(
          child: _buildPriceField(
            brightness: brightness,
            controller: _minPriceController,
            label: 'Minimum',
            symbol: symbol,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.arrow_right_alt_rounded, color: Colors.grey),
        ),
        Expanded(
          child: _buildPriceField(
            brightness: brightness,
            controller: _maxPriceController,
            label: 'Maximum',
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
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: AppColors.border(brightness))),
                ),
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    hintText: '0',
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) => _markChanged(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapacitySection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          brightness,
          Icons.people_alt_outlined,
          'Capacity',
        ),
        const SizedBox(height: 8),
        Text(
          'Maximum number of guests',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        
        // Large Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cyan.withValues(alpha: 0.1),
                AppColors.cyan.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _capacity.round().toString(),
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'people',
                    style: TextStyle(
                      color: AppColors.cyan.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: _capacity,
            min: 0,
            max: 5000,
            divisions: 50,
            onChanged: (value) {
              setState(() => _capacity = value);
              _capacityController.text = value.round().toString();
              _markChanged();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Brightness brightness, bool isArtist) {
    final currencySymbol = _currencies.firstWhere((c) => c['code'] == _currency)['symbol']!;
    final min = double.tryParse(_minPriceController.text) ?? 0;
    final max = double.tryParse(_maxPriceController.text) ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.text(brightness).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.visibility_outlined,
              color: AppColors.textSec(brightness),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArtist ? 'Visible on Profile' : 'Search Range',
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currencySymbol${min.toInt()} - $currencySymbol${max.toInt()} ${isArtist ? (_rateType == 'hour' ? '/ hr' : '/ show') : ''}',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
