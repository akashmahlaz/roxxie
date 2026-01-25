part of '../edit_profile_v2_screen.dart';

/// Pricing Tab
/// - Price range with slider
/// - Currency selection
/// - Price per (hour/show/night)
/// - Special packages
class _PricingTab extends StatelessWidget {
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final String pricePer;
  final String currency;
  final Function(String) onPricePerChanged;
  final Function(String) onCurrencyChanged;
  final bool isArtist;

  const _PricingTab({
    required this.minPriceController,
    required this.maxPriceController,
    required this.pricePer,
    required this.currency,
    required this.onPricePerChanged,
    required this.onCurrencyChanged,
    required this.isArtist,
  });

  static const List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'INR',
  ];
  static const List<Map<String, dynamic>> _pricePerOptions = [
    {'value': 'show', 'label': 'Per Show', 'icon': Icons.event_rounded},
    {'value': 'hour', 'label': 'Per Hour', 'icon': Icons.schedule_rounded},
    {'value': 'night', 'label': 'Per Night', 'icon': Icons.nightlife_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Price Range Section
        _buildSectionHeader(context, 'Your Rate', Icons.attach_money_rounded),
        const SizedBox(height: 8),
        Text(
          'Set a competitive price range for your services',
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Currency Selection
        _buildCurrencySelector(context),
        const SizedBox(height: 24),

        // Price Range Inputs
        Row(
          children: [
            Expanded(
              child: _buildPriceInput(
                context,
                controller: minPriceController,
                label: 'Minimum',
                hint: '100',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'to',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: _buildPriceInput(
                context,
                controller: maxPriceController,
                label: 'Maximum',
                hint: '500',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Price Per Selection
        _buildPricePerSelector(context),

        const SizedBox(height: 32),

        // Pricing Tips
        _buildPricingTips(context),

        const SizedBox(height: 32),

        // Market Insights
        _buildMarketInsights(context),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final brightness = Theme.of(context).brightness;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.crimson.withValues(alpha: 0.2),
                AppColors.rose.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.crimson, size: 20),
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

  Widget _buildCurrencySelector(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _currencies.map((curr) {
              final isSelected = currency == curr;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(curr),
                  selected: isSelected,
                  onSelected: (_) => onCurrencyChanged(curr),
                  backgroundColor: AppColors.surface(brightness),
                  selectedColor: AppColors.crimson.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.crimson
                        : AppColors.textSec(brightness),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.crimson
                          : Colors.transparent,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            color: AppColors.text(brightness),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSec(brightness).withValues(alpha: 0.5),
            ),
            prefixText: _getCurrencySymbol(currency),
            prefixStyle: TextStyle(
              color: AppColors.crimson,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            filled: true,
            fillColor: AppColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.crimson, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
      case 'CAD':
      case 'AUD':
        return '\$ ';
      case 'EUR':
        return '€ ';
      case 'GBP':
        return '£ ';
      case 'INR':
        return '₹ ';
      default:
        return '\$ ';
    }
  }

  Widget _buildPricePerSelector(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate Type',
          style: TextStyle(
            color: AppColors.textSec(brightness),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _pricePerOptions.map((option) {
            final isSelected = pricePer == option['value'];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: option != _pricePerOptions.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => onPricePerChanged(option['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.rose.withValues(alpha: 0.1)
                          : AppColors.surface(brightness),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.rose : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          color: isSelected
                              ? AppColors.rose
                              : AppColors.textSec(brightness),
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.rose
                                : AppColors.textSec(brightness),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPricingTips(BuildContext context) {
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
              Icon(
                Icons.tips_and_updates_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pricing Tips',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip(context, '💡', 'Research local rates for similar artists'),
          _buildTip(context, '📊', 'Price range signals flexibility to venues'),
          _buildTip(context, '⚡', 'Competitive pricing gets 2x more bookings'),
          _buildTip(context, '🎯', 'Consider travel & equipment costs'),
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

  Widget _buildMarketInsights(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.crimson.withValues(alpha: 0.05),
            AppColors.rose.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.crimson, size: 20),
              const SizedBox(width: 8),
              Text(
                'Market Insights',
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Premium',
                  style: TextStyle(
                    color: AppColors.rose,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            context,
            label: 'Average in your area',
            value: '\$250-\$400',
            trend: '+12% this month',
            trendUp: true,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            context,
            label: 'Your genre average',
            value: '\$200-\$350',
            trend: 'Based on 150 artists',
            trendUp: null,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            context,
            label: 'Booking success rate',
            value: '73%',
            trend: 'Above average',
            trendUp: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context, {
    required String label,
    required String value,
    required String trend,
    bool? trendUp,
  }) {
    final brightness = Theme.of(context).brightness;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (trendUp != null)
                    Icon(
                      trendUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: trendUp ? AppColors.success : AppColors.crimson,
                      size: 16,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: TextStyle(
                      color: trendUp == true
                          ? AppColors.success
                          : trendUp == false
                          ? AppColors.crimson
                          : AppColors.textSec(brightness),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
}
