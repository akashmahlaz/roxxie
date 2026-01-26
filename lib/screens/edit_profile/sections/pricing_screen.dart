/// 💰 PRICING SCREEN - Edit Profile Sub-Screen
///
/// Role-aware pricing/budget editing:
/// - Artist: Min/max price, currency
/// - Venue: Budget range, capacity
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

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();
    _capacityController = TextEditingController();
    _initializeData();
  }

  void _initializeData() {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    if (auth.isArtist && profile.artist != null) {
      final artist = profile.artist!;
      _minPriceController.text = artist.minPrice.toStringAsFixed(0);
      _maxPriceController.text = artist.maxPrice.toStringAsFixed(0);
      _currency = artist.currency;
    } else if (!auth.isArtist && profile.venue != null) {
      final venue = profile.venue!;
      _minPriceController.text = (venue.gigPreferences?.minBudget ?? 0).toStringAsFixed(0);
      _maxPriceController.text = (venue.gigPreferences?.maxBudget ?? 0).toStringAsFixed(0);
      _capacityController.text = (venue.capacity ?? 0).toString();
      _currency = venue.gigPreferences?.currency ?? 'USD';
    }
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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final minPrice = double.tryParse(_minPriceController.text) ?? 0;
    final maxPrice = double.tryParse(_maxPriceController.text) ?? 0;

    if (minPrice > maxPrice && maxPrice > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Minimum price cannot be greater than maximum'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        );

        await _artistService.updateMyProfile(
          UpdateArtistRequest(
            priceRange: priceRange,
            minPrice: minPrice,
            maxPrice: maxPrice,
          ),
        );
      } else {
        final capacity = int.tryParse(_capacityController.text);

        await _venueService.updateMyProfile(
          UpdateVenueRequest(
            minBudget: minPrice,
            maxBudget: maxPrice,
            currency: _currency,
            capacity: capacity,
          ),
        );
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Pricing updated successfully!'),
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
              // Info Card
              _buildInfoCard(brightness, isArtist),

              const SizedBox(height: 28),

              // Currency Selector
              _buildCurrencySelector(brightness),

              const SizedBox(height: 24),

              // Price Fields
              _buildPriceFields(brightness, isArtist),

              // Capacity (Venue only)
              if (!isArtist) ...[
                const SizedBox(height: 24),
                _buildCapacityField(brightness),
              ],

              const SizedBox(height: 32),

              // Price Summary
              _buildPriceSummary(brightness, isArtist),

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

  Widget _buildInfoCard(Brightness brightness, bool isArtist) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.cyan,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArtist
                  ? 'Set your performance rate range. Venues will see this when browsing artists.'
                  : 'Set your budget range for hiring artists. This helps match you with artists in your price range.',
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

  Widget _buildCurrencySelector(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border(brightness),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currency,
              isExpanded: true,
              dropdownColor: AppColors.surface(brightness),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSec(brightness),
              ),
              items: _currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency['code'],
                  child: Row(
                    children: [
                      Text(
                        currency['symbol']!,
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${currency['code']} - ${currency['name']}',
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currency = value);
                  _markChanged();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceFields(Brightness brightness, bool isArtist) {
    final currencySymbol = _currencies.firstWhere(
      (c) => c['code'] == _currency,
      orElse: () => {'symbol': '\$'},
    )['symbol']!;

    return Row(
      children: [
        // Minimum Price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArtist ? 'Min Rate' : 'Min Budget',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  prefixText: '$currencySymbol ',
                  prefixStyle: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: AppColors.textSec(brightness),
                  ),
                  filled: true,
                  fillColor: AppColors.surface(brightness),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.border(brightness),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.border(brightness),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.crimson,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => _markChanged(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Maximum Price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArtist ? 'Max Rate' : 'Max Budget',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  prefixText: '$currencySymbol ',
                  prefixStyle: TextStyle(
                    color: AppColors.crimson,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: AppColors.textSec(brightness),
                  ),
                  filled: true,
                  fillColor: AppColors.surface(brightness),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.border(brightness),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.border(brightness),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.crimson,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => _markChanged(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityField(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue Capacity',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Maximum number of guests',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _capacityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.people_outline,
              color: AppColors.textSec(brightness),
            ),
            hintText: 'e.g. 200',
            hintStyle: TextStyle(
              color: AppColors.textSec(brightness),
            ),
            filled: true,
            fillColor: AppColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border(brightness),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border(brightness),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.crimson,
                width: 2,
              ),
            ),
          ),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(Brightness brightness, bool isArtist) {
    final currencySymbol = _currencies.firstWhere(
      (c) => c['code'] == _currency,
      orElse: () => {'symbol': '\$'},
    )['symbol']!;

    final minPrice = double.tryParse(_minPriceController.text) ?? 0;
    final maxPrice = double.tryParse(_maxPriceController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.crimson.withValues(alpha: 0.1),
            AppColors.crimson.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.crimson.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isArtist ? Icons.attach_money : Icons.account_balance_wallet,
            color: AppColors.crimson,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            isArtist ? 'Your Rate Range' : 'Your Budget Range',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${minPrice.toStringAsFixed(0)} - $currencySymbol${maxPrice.toStringAsFixed(0)}',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArtist ? 'per performance' : 'per artist',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
