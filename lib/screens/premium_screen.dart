/// ⭐ GIGMATCH Premium Subscription Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass cards with premium feel
/// - Micro-interactions on plan selection
/// - Animated success states
/// - Optimistic button for subscription
/// - REAL API integration with SubscriptionService
///
/// Upgrade to premium features
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';import 'package:flutter_stripe/flutter_stripe.dart';import '../core/theme/theme.dart';
import '../core/api/api.dart';
import '../core/services/services.dart';
import '../widgets/widgets.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlanIndex = 1; // Default to monthly (yearly = 0, monthly = 1)
  bool _isYearly = false; // Billing toggle
  bool _isLoading = true;
  bool _isProcessing = false;

  late final SubscriptionService _subscriptionService;

  List<SubscriptionPlan> _plans = [];
  final List<PremiumFeature> _features = [
    PremiumFeature(
      icon: Icons.visibility_rounded,
      title: 'Unlimited Likes',
      description: 'Swipe right as much as you want',
    ),
    PremiumFeature(
      icon: Icons.star_rounded,
      title: 'See Who Likes You',
      description: 'Match faster by seeing who already liked you',
    ),
    PremiumFeature(
      icon: Icons.rocket_launch_rounded,
      title: 'Profile Boost',
      description: 'Get 10x more profile views',
    ),
    PremiumFeature(
      icon: Icons.replay_rounded,
      title: 'Unlimited Rewinds',
      description: 'Go back and change your last swipe',
    ),
    PremiumFeature(
      icon: Icons.location_off_rounded,
      title: 'Passport Mode',
      description: 'Match with anyone, anywhere in the world',
    ),
    PremiumFeature(
      icon: Icons.message_rounded,
      title: 'Priority Messages',
      description: 'Your messages appear first',
    ),
    PremiumFeature(
      icon: Icons.block_rounded,
      title: 'Ad-Free Experience',
      description: 'Enjoy GigMatch without interruptions',
    ),
    PremiumFeature(
      icon: Icons.verified_rounded,
      title: 'Verified Badge',
      description: 'Get the blue checkmark on your profile',
    ),
    PremiumFeature(
      icon: Icons.analytics_rounded,
      title: 'Advanced Analytics',
      description: 'See detailed insights about your profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService(apiClient: ApiClient());
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      _plans = await _subscriptionService.loadAvailablePlans();
      // Filter out free plan and sort by price
      _plans = _plans.where((p) => p.tier != SubscriptionTier.free).toList()
        ..sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));

      // Set default to middle plan (Pro)
      if (_plans.length > 1) {
        _selectedPlanIndex = 1;
      }
    } catch (e) {
      debugPrint('Failed to load plans: $e');
      _plans = _getDefaultPlans();
    }
    setState(() => _isLoading = false);
  }

  List<SubscriptionPlan> _getDefaultPlans() {
    return [
      const SubscriptionPlan(
        id: 'pro',
        name: 'Pro',
        description: 'For serious musicians and venues',
        tier: SubscriptionTier.pro,
        monthlyPrice: 9.99,
        yearlyPrice: 99.99,
        stripePriceIdMonthly: 'price_pro_monthly',
        stripePriceIdYearly: 'price_pro_yearly',
        features: [
          'Profile boosting (5/month)',
          'See who viewed your profile',
          'See who liked you',
          'Advanced filters',
          'Message first',
          'Read receipts',
          '20 gig applications/month',
          'Analytics dashboard',
        ],
        isPopular: true,
        isAvailable: true,
      ),
      const SubscriptionPlan(
        id: 'premium',
        name: 'Premium',
        description: 'For professional artists and venues',
        tier: SubscriptionTier.premium,
        monthlyPrice: 19.99,
        yearlyPrice: 199.99,
        stripePriceIdMonthly: 'price_premium_monthly',
        stripePriceIdYearly: 'price_premium_yearly',
        features: [
          'Everything in Pro',
          'Unlimited profile boosting',
          'Unlimited gig applications',
          'Priority placement in search',
          'Featured profile badge',
          'Exclusive gig opportunities',
          'VIP support',
        ],
        isPopular: false,
        isAvailable: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.crimson),
                  const SizedBox(height: 16),
                  Text(
                    'Loading plans...',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColors.surface(brightness),
                  leading: const GlassBackButton(),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.crimson,
                            AppColors.crimson.withValues(alpha: 0.7),
                            Colors.purple.shade600,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 64,
                              color: Colors.amber.shade300,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'GigMatch Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Supercharge your gig matching',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Billing Toggle
                      _buildBillingToggle(brightness),
                      const SizedBox(height: 16),

                      // Plans
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              'Choose Your Plan',
                              style: TextStyle(
                                color: AppColors.text(brightness),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isYearly
                                  ? 'Save up to 50% with yearly billing'
                                  : 'Cancel anytime. All plans include a 3-day trial.',
                              style: TextStyle(
                                color: AppColors.textSec(brightness),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Plan cards
                            ..._plans.asMap().entries.map((entry) {
                              final index = entry.key;
                              final plan = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildPlanCard(plan, index, brightness),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Features
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Features',
                              style: TextStyle(
                                color: AppColors.text(brightness),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),

                            ..._features.map((feature) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child:
                                    _buildFeatureItem(feature, brightness),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Subscribe button
                      _buildSubscribeButton(brightness),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBillingToggle(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedTapFeedback(
                onTap: () {
                  if (_isYearly) {
                    HapticFeedback.selectionClick();
                    setState(() => _isYearly = false);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isYearly ? AppColors.crimson : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Monthly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: !_isYearly
                          ? Colors.white
                          : AppColors.textSec(brightness),
                      fontWeight: !_isYearly ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedTapFeedback(
                onTap: () {
                  if (!_isYearly) {
                    HapticFeedback.selectionClick();
                    setState(() => _isYearly = true);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isYearly ? AppColors.success : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Yearly',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isYearly
                              ? Colors.white
                              : AppColors.textSec(brightness),
                          fontWeight:
                              _isYearly ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      if (!_isYearly)
                        Text(
                          'Save 50%',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, int index, Brightness brightness) {
    final isSelected = _selectedPlanIndex == index;
    final price = _isYearly ? plan.yearlyPrice : plan.monthlyPrice;
    final pricePerMonth = _isYearly
        ? (plan.yearlyPrice / 12)
        : plan.monthlyPrice;
    final savings = _isYearly
        ? ((1 - (plan.yearlyPrice / (plan.monthlyPrice * 12))) * 100)
            .round()
        : 0;

    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPlanIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.crimson.withValues(alpha: 0.05)
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.crimson
                : AppColors.border(brightness),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Radio button
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.crimson
                            : AppColors.border(brightness),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppColors.crimson,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // Plan details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                color: AppColors.text(brightness),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (plan.isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'POPULAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${pricePerMonth.toStringAsFixed(2)}/mo',
                          style: TextStyle(
                            color: AppColors.textSec(brightness),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _isYearly ? '/year' : '/month',
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 12,
                        ),
                      ),
                      if (savings > 0)
                        Text(
                          'Save $savings%',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(PremiumFeature feature, Brightness brightness) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, color: AppColors.crimson, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: TextStyle(
                  color: AppColors.text(brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                feature.description,
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(Brightness brightness) {
    if (_plans.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedPlan = _plans[_selectedPlanIndex];
    final price = _isYearly ? selectedPlan.yearlyPrice : selectedPlan.monthlyPrice;
    final period = _isYearly ? 'year' : 'month';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _subscribe(selectedPlan),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: AppColors.crimson.withValues(alpha: 0.5),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Start Free Trial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Then \$${price.toStringAsFixed(2)} per $period',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By continuing, you agree to our Terms of Service',
            style: TextStyle(
              color: AppColors.textTert(brightness),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final brightness = Theme.of(context).brightness;

    try {
      // Create payment intent for mobile Payment Sheet
      final paymentData = await _subscriptionService.createPaymentIntent(
        plan: plan,
        isYearly: _isYearly,
      );

      debugPrint('💳 Payment intent created: ${paymentData.clientSecret.substring(0, 20)}...');

      // Initialize the Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentData.clientSecret,
          merchantDisplayName: 'GigMatch',
          customerId: paymentData.customerId,
          customerEphemeralKeySecret: paymentData.ephemeralKey,
          style: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppColors.crimson,
            ),
            shapes: const PaymentSheetShape(
              borderRadius: 16,
            ),
          ),
        ),
      );

      // Present the Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful!
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Welcome to ${plan.name}! 🎉'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Refresh subscription status and go back
      await _subscriptionService.refreshSubscription();
      if (mounted) {
        navigator.pop(true); // Return success
      }
    } on StripeException catch (e) {
      // User cancelled or payment failed
      if (e.error.code == FailureCode.Canceled) {
        debugPrint('💳 Payment cancelled by user');
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Payment cancelled'),
            backgroundColor: AppColors.textSec(brightness),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        debugPrint('💳 Stripe error: ${e.error.message}');
        messenger.showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.error.message ?? 'Unknown error'}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Subscription error: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Subscription failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class PremiumFeature {
  final IconData icon;
  final String title;
  final String description;

  PremiumFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}
