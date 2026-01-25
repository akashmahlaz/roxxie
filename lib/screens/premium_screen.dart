/// ⭐ GIGMATCH Premium Subscription Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass cards with premium feel
/// - Micro-interactions on plan selection
/// - Animated success states
/// - Optimistic button for subscription
///
/// Upgrade to premium features
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlanIndex = 1; // Default to monthly

  final List<PremiumPlan> _plans = [
    PremiumPlan(
      name: 'Weekly',
      duration: '1 week',
      price: '\$4.99',
      pricePerMonth: '\$19.96/mo',
      savings: null,
    ),
    PremiumPlan(
      name: 'Monthly',
      duration: '1 month',
      price: '\$14.99',
      pricePerMonth: '\$14.99/mo',
      savings: null,
      isPopular: true,
    ),
    PremiumPlan(
      name: 'Yearly',
      duration: '12 months',
      price: '\$99.99',
      pricePerMonth: '\$8.33/mo',
      savings: 'Save 44%',
      isBestValue: true,
    ),
  ];

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
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: CustomScrollView(
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
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
                        'Cancel anytime. All plans include a 3-day trial.',
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
                          child: _buildFeatureItem(feature, brightness),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Subscribe button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _subscribe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.crimson,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Start 3-Day Free Trial',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Then ${_plans[_selectedPlanIndex].price} per ${_plans[_selectedPlanIndex].duration}',
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
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PremiumPlan plan, int index, Brightness brightness) {
    final isSelected = _selectedPlanIndex == index;

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
                          plan.pricePerMonth,
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
                        plan.price,
                        style: TextStyle(
                          color: AppColors.text(brightness),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (plan.savings != null)
                        Text(
                          plan.savings!,
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

            // Best value badge
            if (plan.isBestValue)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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

  void _subscribe() {
    // TODO: Implement actual subscription logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Subscription feature coming soon!'),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class PremiumPlan {
  final String name;
  final String duration;
  final String price;
  final String pricePerMonth;
  final String? savings;
  final bool isPopular;
  final bool isBestValue;

  PremiumPlan({
    required this.name,
    required this.duration,
    required this.price,
    required this.pricePerMonth,
    this.savings,
    this.isPopular = false,
    this.isBestValue = false,
  });
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
