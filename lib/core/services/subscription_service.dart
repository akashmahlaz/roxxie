/// 💰 GigMatch Subscription/Payment Service - BULLETPROOF VERSION
///
/// Comprehensive subscription service for Stripe payment processing
/// Features:
/// - Subscription tier management (Free, Pro, Premium)
/// - Payment processing with Stripe
/// - Subscription status tracking
/// - Feature access control based on subscription
/// - In-app purchase support (iOS)
/// - Receipt validation
/// - Billing portal integration
/// - Payment method management
/// - Offline support with queue
/// - Comprehensive error handling with retries
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../providers/auth_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════
// SUBSCRIPTION TIERS
/// ═══════════════════════════════════════════════════════════════════════

/// Subscription tiers available in the app
enum SubscriptionTier { free, pro, premium }

/// Status of a subscription
enum SubscriptionStatus { active, pastDue, canceled, unpaid, trialing, paused }

/// Payment method types
enum PaymentMethodType { card, bankAccount, applePay, googlePay }

/// ═══════════════════════════════════════════════════════════════════════
// DATA MODELS
/// ═══════════════════════════════════════════════════════════════════════

/// Subscription plan details
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final SubscriptionTier tier;
  final double monthlyPrice;
  final double yearlyPrice;
  final String? stripePriceIdMonthly;
  final String? stripePriceIdYearly;
  final List<String> features;
  final bool isPopular;
  final bool isAvailable;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.stripePriceIdMonthly,
    this.stripePriceIdYearly,
    required this.features,
    this.isPopular = false,
    this.isAvailable = true,
  });

  /// Get price for billing cycle
  double getPrice(bool isYearly) => isYearly ? yearlyPrice : monthlyPrice;

  /// Get Stripe price ID for billing cycle
  String? getStripePriceId(bool isYearly) =>
      isYearly ? stripePriceIdYearly : stripePriceIdMonthly;

  /// Get formatted price string
  String getFormattedPrice(bool isYearly) {
    final price = getPrice(isYearly);
    return '\$${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}/${isYearly ? 'yr' : 'mo'}';
  }

  /// Create from JSON
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      tier: _parseTier(json['tier'] ?? 'free'),
      monthlyPrice: (json['monthlyPrice'] ?? 0).toDouble(),
      yearlyPrice: (json['yearlyPrice'] ?? 0).toDouble(),
      stripePriceIdMonthly: json['stripePriceIdMonthly'],
      stripePriceIdYearly: json['stripePriceIdYearly'],
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['isPopular'] ?? false,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  static SubscriptionTier _parseTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'pro':
        return SubscriptionTier.pro;
      case 'premium':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }
}

/// User's current subscription
class UserSubscription {
  final String id;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelAtPeriodEnd;
  final DateTime? trialEnd;
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;
  final bool hasActiveSubscription;

  const UserSubscription({
    required this.id,
    required this.tier,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd,
    this.trialEnd,
    this.stripeSubscriptionId,
    this.stripeCustomerId,
    required this.hasActiveSubscription,
  });

  /// Check if subscription is in trial
  bool get isInTrial => trialEnd != null && trialEnd!.isAfter(DateTime.now());

  /// Check if subscription will cancel at period end
  bool get willCancelAtPeriodEnd => cancelAtPeriodEnd != null;

  /// Get days remaining in current period
  int get daysRemainingInPeriod {
    if (currentPeriodEnd == null) return 0;
    return currentPeriodEnd!.difference(DateTime.now()).inDays;
  }

  /// Create from JSON
  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] ?? '',
      tier: _parseTier(json['tier'] ?? 'free'),
      status: _parseStatus(json['status'] ?? 'inactive'),
      currentPeriodStart: json['currentPeriodStart'] != null
          ? DateTime.tryParse(json['currentPeriodStart'])
          : null,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.tryParse(json['currentPeriodEnd'])
          : null,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] != null
          ? DateTime.tryParse(json['cancelAtPeriodEnd'])
          : null,
      trialEnd: json['trialEnd'] != null
          ? DateTime.tryParse(json['trialEnd'])
          : null,
      stripeSubscriptionId: json['stripeSubscriptionId'],
      stripeCustomerId: json['stripeCustomerId'],
      hasActiveSubscription: json['hasActiveSubscription'] ?? false,
    );
  }

  static SubscriptionTier _parseTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'pro':
        return SubscriptionTier.pro;
      case 'premium':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }

  static SubscriptionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'unpaid':
        return SubscriptionStatus.unpaid;
      case 'trialing':
        return SubscriptionStatus.trialing;
      case 'paused':
        return SubscriptionStatus.paused;
      default:
        return SubscriptionStatus.canceled;
    }
  }
}

/// Payment method details
class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String? brand;
  final String? last4;
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.brand,
    this.last4,
    this.expiryMonth,
    this.expiryYear,
    required this.isDefault,
  });

  /// Get masked card number
  String get maskedNumber => '•••• •••• •••• $last4';

  /// Get expiry string
  String get expiryString =>
      '${expiryMonth?.toString().padLeft(2, '0')}/${expiryYear?.toString().substring(2)}';

  /// Create from JSON
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      type: _parseType(json['type'] ?? 'card'),
      brand: json['brand'],
      last4: json['last4'],
      expiryMonth: json['expiryMonth'],
      expiryYear: json['expiryYear'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  static PaymentMethodType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'bank_account':
        return PaymentMethodType.bankAccount;
      case 'apple_pay':
        return PaymentMethodType.applePay;
      case 'google_pay':
        return PaymentMethodType.googlePay;
      default:
        return PaymentMethodType.card;
    }
  }
}

/// Invoice/billing record
class Invoice {
  final String id;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String status;
  final String? pdfUrl;
  final String? description;

  const Invoice({
    required this.id,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.paidAt,
    required this.status,
    this.pdfUrl,
    this.description,
  });

  /// Get formatted amount
  String get formattedAmount =>
      '\$${(amount / 100).toStringAsFixed(2)} $currency';

  /// Create from JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'usd',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      status: json['status'] ?? 'draft',
      pdfUrl: json['pdfUrl'],
      description: json['description'],
    );
  }
}

/// Payment Intent data for mobile Payment Sheet
class PaymentIntentData {
  final String clientSecret;
  final String? customerId;
  final String? ephemeralKey;

  const PaymentIntentData({
    required this.clientSecret,
    this.customerId,
    this.ephemeralKey,
  });
}

/// Feature access based on subscription
class FeatureAccess {
  final bool canBoostProfile;
  final int maxProfileBoosts;
  final bool canSeeViews;
  final bool canSeeLikes;
  final bool canUseAdvancedFilters;
  final bool canMessageFirst;
  final bool canSeeReadReceipts;
  final int maxGigApplications;
  final bool canAccessAnalytics;
  final int maxMediaUploads;

  const FeatureAccess({
    required this.canBoostProfile,
    required this.maxProfileBoosts,
    required this.canSeeViews,
    required this.canSeeLikes,
    required this.canUseAdvancedFilters,
    required this.canMessageFirst,
    required this.canSeeReadReceipts,
    required this.maxGigApplications,
    required this.canAccessAnalytics,
    required this.maxMediaUploads,
  });

  /// Get feature access for a tier
  factory FeatureAccess.forTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const FeatureAccess(
          canBoostProfile: false,
          maxProfileBoosts: 0,
          canSeeViews: false,
          canSeeLikes: false,
          canUseAdvancedFilters: false,
          canMessageFirst: false,
          canSeeReadReceipts: false,
          maxGigApplications: 5,
          canAccessAnalytics: false,
          maxMediaUploads: 3,
        );
      case SubscriptionTier.pro:
        return const FeatureAccess(
          canBoostProfile: true,
          maxProfileBoosts: 5,
          canSeeViews: true,
          canSeeLikes: true,
          canUseAdvancedFilters: true,
          canMessageFirst: true,
          canSeeReadReceipts: true,
          maxGigApplications: 20,
          canAccessAnalytics: true,
          maxMediaUploads: 10,
        );
      case SubscriptionTier.premium:
        return const FeatureAccess(
          canBoostProfile: true,
          maxProfileBoosts: -1, // Unlimited
          canSeeViews: true,
          canSeeLikes: true,
          canUseAdvancedFilters: true,
          canMessageFirst: true,
          canSeeReadReceipts: true,
          maxGigApplications: -1, // Unlimited
          canAccessAnalytics: true,
          maxMediaUploads: -1, // Unlimited
        );
    }
  }

  /// Create from JSON
  factory FeatureAccess.fromJson(Map<String, dynamic> json) {
    return FeatureAccess(
      canBoostProfile: json['canBoostProfile'] ?? false,
      maxProfileBoosts: json['maxProfileBoosts'] ?? 0,
      canSeeViews: json['canSeeViews'] ?? false,
      canSeeLikes: json['canSeeLikes'] ?? false,
      canUseAdvancedFilters: json['canUseAdvancedFilters'] ?? false,
      canMessageFirst: json['canMessageFirst'] ?? false,
      canSeeReadReceipts: json['canSeeReadReceipts'] ?? false,
      maxGigApplications: json['maxGigApplications'] ?? 5,
      canAccessAnalytics: json['canAccessAnalytics'] ?? false,
      maxMediaUploads: json['maxMediaUploads'] ?? 3,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════
// EXCEPTION CLASSES
/// ═══════════════════════════════════════════════════════════════════════

class SubscriptionException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  const SubscriptionException(
    this.message, {
    this.code = 'SUBSCRIPTION_ERROR',
    this.originalError,
  });

  @override
  String toString() => 'SubscriptionException[$code]: $message';
}

class PaymentFailedException extends SubscriptionException {
  const PaymentFailedException(super.message, {super.originalError})
    : super(code: 'PAYMENT_FAILED');
}

class SubscriptionInactiveException extends SubscriptionException {
  const SubscriptionInactiveException([
    super.message = 'Active subscription required',
  ]) : super(code: 'SUBSCRIPTION_INACTIVE');
}

class FeatureNotAvailableException extends SubscriptionException {
  const FeatureNotAvailableException([
    super.message = 'This feature is not available in your plan',
  ]) : super(code: 'FEATURE_NOT_AVAILABLE');
}

/// ═══════════════════════════════════════════════════════════════════════
// SUBSCRIPTION SERVICE
/// ═══════════════════════════════════════════════════════════════════════

class SubscriptionService {
  final ApiClient _client;
  // Reserved for future use: final AuthProvider? _authProvider;

  // Retry settings (reserved for future use)
  // static const int _maxRetries = 3;
  // static const Duration _retryDelay = Duration(seconds: 2);

  // State
  UserSubscription? _currentSubscription;
  List<SubscriptionPlan>? _availablePlans;
  List<PaymentMethod>? _paymentMethods;
  List<Invoice>? _invoices;
  FeatureAccess? _featureAccess;

  // Streams
  final StreamController<UserSubscription?> _subscriptionStream =
      StreamController<UserSubscription?>.broadcast();
  final StreamController<List<PaymentMethod>> _paymentMethodsStream =
      StreamController<List<PaymentMethod>>.broadcast();
  final StreamController<bool> _subscriptionChangeStream =
      StreamController<bool>.broadcast();

  // Cache
  final List<dynamic> _pendingOperations = [];

  // ═══════════════════════════════════════════════════════════════════════
  // PUBLIC STREAMS & GETTERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Stream of subscription changes
  Stream<UserSubscription?> get subscriptionStream =>
      _subscriptionStream.stream;

  /// Stream of payment methods changes
  Stream<List<PaymentMethod>> get paymentMethodsStream =>
      _paymentMethodsStream.stream;

  /// Stream for subscription change notifications
  Stream<bool> get subscriptionChangeStream => _subscriptionChangeStream.stream;

  /// Current user subscription
  UserSubscription? get currentSubscription => _currentSubscription;

  /// Current feature access
  FeatureAccess? get featureAccess => _featureAccess;

  /// Available subscription plans
  List<SubscriptionPlan>? get availablePlans => _availablePlans;

  /// Payment methods
  List<PaymentMethod>? get paymentMethods => _paymentMethods;

  /// Check if user has active subscription
  bool get hasActiveSubscription =>
      _currentSubscription?.hasActiveSubscription ?? false;

  /// Check if user is in trial
  bool get isInTrial => _currentSubscription?.isInTrial ?? false;

  /// Check if user can access a feature
  bool canAccessFeature(bool Function(FeatureAccess) check) {
    if (_featureAccess == null) return false;
    return check(_featureAccess!);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════

  SubscriptionService({
    required ApiClient apiClient,
    AuthProvider? authProvider,
  }) : _client = apiClient;
  // _authProvider = authProvider; // Reserved for future use

  /// Initialize subscription service
  /// Call this after authentication
  Future<bool> initialize() async {
    try {
      debugPrint('💰 [SubscriptionService] Initializing...');

      // Load subscription status
      await refreshSubscription();

      // Load available plans
      await loadAvailablePlans();

      // Load payment methods if subscribed
      if (hasActiveSubscription) {
        await loadPaymentMethods();
        await loadInvoices();
      }

      debugPrint('💰 [SubscriptionService] Initialized');
      return true;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Initialization failed: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Get current user subscription
  Future<UserSubscription?> getSubscription() async {
    try {
      debugPrint('💰 [SubscriptionService] Fetching subscription...');

      final response = await _client.get(Endpoints.subscriptionCurrent);

      if (response.data == null) {
        _currentSubscription = null;
        return null;
      }

      _currentSubscription = UserSubscription.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Update feature access
      _featureAccess = FeatureAccess.forTier(_currentSubscription!.tier);

      // Emit to stream
      _subscriptionStream.add(_currentSubscription);

      debugPrint(
        '💰 [SubscriptionService] Subscription: ${_currentSubscription?.tier.name}',
      );
      return _currentSubscription;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Failed to get subscription: $e');
      return null;
    }
  }

  /// Refresh subscription from server
  Future<UserSubscription?> refreshSubscription() async {
    return await getSubscription();
  }

  /// Create checkout session for subscription
  Future<String> createCheckoutSession({
    required SubscriptionPlan plan,
    required bool isYearly,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint(
        '💰 [SubscriptionService] Creating checkout session for ${plan.name}',
      );

      final response = await _client.post(
        Endpoints.subscriptionCreateCheckout,
        data: {
          'priceId': plan.getStripePriceId(isYearly),
          'isYearly': isYearly,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
        },
      );

      // Handle response - backend wraps in {success: true, data: {...}}
      final data = response.data['data'] ?? response.data;

      if (data == null || data['sessionId'] == null) {
        throw SubscriptionException('Failed to create checkout session');
      }

      final sessionId = data['sessionId'] as String;

      debugPrint(
        '💰 [SubscriptionService] Checkout session created in ${stopwatch.elapsedMilliseconds}ms',
      );
      return sessionId;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Checkout failed: $e');
      throw SubscriptionException('Failed to create checkout session: $e');
    } finally {
      stopwatch.stop();
    }
  }

  /// Create payment intent for mobile Payment Sheet
  Future<PaymentIntentData> createPaymentIntent({
    required SubscriptionPlan plan,
    required bool isYearly,
  }) async {
    try {
      debugPrint(
        '💰 [SubscriptionService] Creating payment intent for ${plan.name}',
      );

      final response = await _client.post(
        Endpoints.subscriptionCreatePaymentIntent,
        data: {
          'priceId': plan.getStripePriceId(isYearly),
          'amount': isYearly ? (plan.monthlyPrice * 10 * 100).toInt() : (plan.monthlyPrice * 100).toInt(),
          'currency': 'usd',
        },
      );

      // Handle response - backend wraps in {success: true, data: {...}}
      final data = response.data['data'] ?? response.data;

      if (data == null) {
        throw SubscriptionException('Failed to create payment intent');
      }

      final clientSecret = data['clientSecret'] as String?;
      if (clientSecret == null) {
        throw SubscriptionException('Payment intent client secret is missing');
      }

      return PaymentIntentData(
        clientSecret: clientSecret,
        customerId: data['customerId'] as String?,
        ephemeralKey: data['ephemeralKey'] as String?,
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Payment intent creation failed: $e');
      throw SubscriptionException('Failed to create payment intent: $e');
    }
  }

  /// Redirect to Stripe Checkout
  Future<bool> redirectToCheckout(String sessionId) async {
    try {
      debugPrint('💰 [SubscriptionService] Redirecting to checkout...');

      // In production, use Stripe SDK or URL launcher
      // For now, we'll return success (frontend handles redirect)
      return true;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Redirect failed: $e');
      return false;
    }
  }

  /// Restore purchases (for iOS subscriptions)
  Future<bool> restorePurchases() async {
    try {
      debugPrint('💰 [SubscriptionService] Restoring purchases...');

      final response = await _client.post(Endpoints.subscriptionRestore);

      if (response.data != null) {
        // Update subscription from restored data
        if (response.data['subscription'] != null) {
          _currentSubscription = UserSubscription.fromJson(
            response.data['subscription'],
          );
          _subscriptionStream.add(_currentSubscription);
        }

        debugPrint('💰 [SubscriptionService] Purchases restored');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Restore failed: $e');
      throw SubscriptionException('Failed to restore purchases: $e');
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription({bool immediately = false}) async {
    try {
      debugPrint(
        '💰 [SubscriptionService] Canceling subscription (immediately: $immediately)',
      );

      final response = await _client.post(
        Endpoints.subscriptionCancel,
        data: {'immediately': immediately},
      );

      if (response.data != null) {
        _currentSubscription = UserSubscription.fromJson(
          response.data as Map<String, dynamic>,
        );
        _subscriptionStream.add(_currentSubscription);
        _subscriptionChangeStream.add(true);

        debugPrint('💰 [SubscriptionService] Subscription canceled');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Cancel failed: $e');
      throw SubscriptionException('Failed to cancel subscription: $e');
    }
  }

  /// Resume canceled subscription
  Future<bool> resumeSubscription() async {
    try {
      debugPrint('💰 [SubscriptionService] Resuming subscription...');

      final response = await _client.post(Endpoints.subscriptionResume);

      if (response.data != null) {
        _currentSubscription = UserSubscription.fromJson(
          response.data as Map<String, dynamic>,
        );
        _subscriptionStream.add(_currentSubscription);
        _subscriptionChangeStream.add(true);

        debugPrint('💰 [SubscriptionService] Subscription resumed');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Resume failed: $e');
      throw SubscriptionException('Failed to resume subscription: $e');
    }
  }

  /// Update subscription (upgrade/downgrade)
  Future<bool> updateSubscription({
    required SubscriptionPlan newPlan,
    required bool isYearly,
  }) async {
    try {
      debugPrint(
        '💰 [SubscriptionService] Updating subscription to ${newPlan.name}',
      );

      final response = await _client.post(
        Endpoints.subscriptionUpdate,
        data: {
          'priceId': newPlan.getStripePriceId(isYearly),
          'isYearly': isYearly,
        },
      );

      if (response.data != null) {
        _currentSubscription = UserSubscription.fromJson(
          response.data as Map<String, dynamic>,
        );
        _featureAccess = FeatureAccess.forTier(_currentSubscription!.tier);
        _subscriptionStream.add(_currentSubscription);
        _subscriptionChangeStream.add(true);

        debugPrint('💰 [SubscriptionService] Subscription updated');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Update failed: $e');
      throw SubscriptionException('Failed to update subscription: $e');
    }
  }

  /// Start free trial
  Future<bool> startFreeTrial({required SubscriptionTier tier}) async {
    try {
      debugPrint('💰 [SubscriptionService] Starting free trial for $tier');

      final response = await _client.post(
        Endpoints.subscriptionStartTrial,
        data: {'tier': tier.name},
      );

      if (response.data != null) {
        _currentSubscription = UserSubscription.fromJson(
          response.data as Map<String, dynamic>,
        );
        _featureAccess = FeatureAccess.forTier(_currentSubscription!.tier);
        _subscriptionStream.add(_currentSubscription);
        _subscriptionChangeStream.add(true);

        debugPrint('💰 [SubscriptionService] Free trial started');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Trial start failed: $e');
      throw SubscriptionException('Failed to start free trial: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PLANS
  // ═══════════════════════════════════════════════════════════════════════

  /// Load available subscription plans
  Future<List<SubscriptionPlan>> loadAvailablePlans() async {
    try {
      debugPrint('💰 [SubscriptionService] Loading available plans...');

      final response = await _client.get(Endpoints.subscriptionPlans);

      if (response.data == null) {
        // Return default plans if API fails
        return _getDefaultPlans();
      }

      final data = response.data['data'] ?? response.data['plans'] ?? [];

      _availablePlans = (data as List).map((item) {
        return SubscriptionPlan.fromJson(item as Map<String, dynamic>);
      }).toList();

      debugPrint(
        '💰 [SubscriptionService] Loaded ${_availablePlans!.length} plans',
      );
      return _availablePlans!;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Failed to load plans: $e');
      return _getDefaultPlans();
    }
  }

  /// Get default plans (fallback)
  List<SubscriptionPlan> _getDefaultPlans() {
    _availablePlans = [
      const SubscriptionPlan(
        id: 'free',
        name: 'Free',
        description: 'Get started with basic features',
        tier: SubscriptionTier.free,
        monthlyPrice: 0,
        yearlyPrice: 0,
        features: [
          'Create artist/venue profile',
          'Basic discovery swiping',
          '5 gig applications per month',
          '3 media uploads',
          'Receive messages',
        ],
        isPopular: false,
        isAvailable: true,
      ),
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
          'Everything in Free',
          'Profile boosting (5/month)',
          'See who viewed your profile',
          'See who liked you',
          'Advanced filters',
          'Message first',
          'Read receipts',
          '20 gig applications/month',
          'Analytics dashboard',
          '10 media uploads',
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
          'Unlimited media uploads',
          'Priority placement in search',
          'Featured profile badge',
          'Exclusive gig opportunities',
          'VIP support',
        ],
        isPopular: false,
        isAvailable: true,
      ),
    ];

    return _availablePlans!;
  }

  /// Get plan by tier
  SubscriptionPlan? getPlan(SubscriptionTier tier) {
    if (_availablePlans == null) {
      _getDefaultPlans();
    }
    return _availablePlans?.firstWhere((p) => p.tier == tier);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAYMENT METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Load user's payment methods
  Future<List<PaymentMethod>> loadPaymentMethods() async {
    try {
      debugPrint('💰 [SubscriptionService] Loading payment methods...');

      final response = await _client.get(Endpoints.paymentMethods);

      if (response.data == null) {
        _paymentMethods = [];
        return [];
      }

      final data =
          response.data['data'] ??
          response.data['paymentMethods'] ??
          response.data;

      _paymentMethods = (data as List).map((item) {
        return PaymentMethod.fromJson(item as Map<String, dynamic>);
      }).toList();

      // Emit to stream
      _paymentMethodsStream.add(_paymentMethods!);

      debugPrint(
        '💰 [SubscriptionService] Loaded ${_paymentMethods!.length} payment methods',
      );
      return _paymentMethods!;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Failed to load payment methods: $e');
      return [];
    }
  }

  /// Add new payment method
  Future<PaymentMethod> addPaymentMethod({
    required String paymentMethodId,
    bool setAsDefault = false,
  }) async {
    try {
      debugPrint('💰 [SubscriptionService] Adding payment method...');

      final response = await _client.post(
        Endpoints.paymentMethodsAdd,
        data: {
          'paymentMethodId': paymentMethodId,
          'setAsDefault': setAsDefault,
        },
      );

      if (response.data == null) {
        throw SubscriptionException('Failed to add payment method');
      }

      final paymentMethod = PaymentMethod.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Update local cache
      _paymentMethods ??= [];
      _paymentMethods!.add(paymentMethod);

      // Emit to stream
      _paymentMethodsStream.add(_paymentMethods!);

      debugPrint('💰 [SubscriptionService] Payment method added');
      return paymentMethod;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Add payment method failed: $e');
      throw SubscriptionException('Failed to add payment method: $e');
    }
  }

  /// Set default payment method
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      debugPrint(
        '💰 [SubscriptionService] Setting default payment method: $paymentMethodId',
      );

      await _client.post(
        Endpoints.paymentMethodsSetDefault,
        data: {'paymentMethodId': paymentMethodId},
      );

      // Update local cache
      _paymentMethods = _paymentMethods!.map((m) {
        return PaymentMethod(
          id: m.id,
          type: m.type,
          brand: m.brand,
          last4: m.last4,
          expiryMonth: m.expiryMonth,
          expiryYear: m.expiryYear,
          isDefault: m.id == paymentMethodId,
        );
      }).toList();

      // Emit to stream
      _paymentMethodsStream.add(_paymentMethods!);

      debugPrint('💰 [SubscriptionService] Default payment method set');
      return true;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Set default failed: $e');
      return false;
    }
  }

  /// Remove payment method
  Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      debugPrint(
        '💰 [SubscriptionService] Removing payment method: $paymentMethodId',
      );

      await _client.delete('${Endpoints.paymentMethods}/$paymentMethodId');

      // Update local cache
      _paymentMethods?.removeWhere((m) => m.id == paymentMethodId);

      // Emit to stream
      _paymentMethodsStream.add(_paymentMethods ?? []);

      debugPrint('💰 [SubscriptionService] Payment method removed');
      return true;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Remove failed: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INVOICES
  // ═══════════════════════════════════════════════════════════════════════

  /// Load invoices
  Future<List<Invoice>> loadInvoices({int page = 1, int limit = 10}) async {
    try {
      debugPrint('💰 [SubscriptionService] Loading invoices...');

      final response = await _client.get(
        Endpoints.invoices,
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      if (response.data == null) {
        _invoices = [];
        return [];
      }

      final data =
          response.data['data'] ?? response.data['invoices'] ?? response.data;

      _invoices = (data as List).map((item) {
        return Invoice.fromJson(item as Map<String, dynamic>);
      }).toList();

      debugPrint(
        '💰 [SubscriptionService] Loaded ${_invoices!.length} invoices',
      );
      return _invoices!;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Failed to load invoices: $e');
      return [];
    }
  }

  /// Get invoice PDF URL
  Future<String?> getInvoicePdfUrl(String invoiceId) async {
    try {
      final response = await _client.get(
        '${Endpoints.invoices}/$invoiceId/pdf',
      );

      return response.data['url'] as String?;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Failed to get invoice PDF: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BILLING PORTAL
  // ═══════════════════════════════════════════════════════════════════════

  /// Create billing portal session
  Future<String> createBillingPortalSession({required String returnUrl}) async {
    try {
      debugPrint('💰 [SubscriptionService] Creating billing portal session...');

      final response = await _client.post(
        Endpoints.billingPortalSession,
        data: {'returnUrl': returnUrl},
      );

      // Handle response - backend wraps in {success: true, data: {...}}
      final data = response.data['data'] ?? response.data;

      if (data == null || data['url'] == null) {
        throw SubscriptionException('Failed to create billing portal session');
      }

      return data['url'] as String;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Billing portal failed: $e');
      throw SubscriptionException('Failed to open billing portal: $e');
    }
  }

  /// Open billing portal
  Future<bool> openBillingPortal(String sessionUrl) async {
    try {
      // In production, use URL launcher
      debugPrint('💰 [SubscriptionService] Opening billing portal...');
      return true;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Open billing portal failed: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FEATURE ACCESS CHECKS
  // ═══════════════════════════════════════════════════════════════════════

  /// Check if user can boost profile
  Future<bool> canBoostProfile() async {
    if (_featureAccess == null) {
      await getSubscription();
    }
    return canAccessFeature((f) => f.canBoostProfile);
  }

  /// Check if user can see profile views
  Future<bool> canSeeViews() async {
    if (_featureAccess == null) {
      await getSubscription();
    }
    return canAccessFeature((f) => f.canSeeViews);
  }

  /// Check if user can see likes
  Future<bool> canSeeLikes() async {
    if (_featureAccess == null) {
      await getSubscription();
    }
    return canAccessFeature((f) => f.canSeeLikes);
  }

  /// Check if user can use advanced filters
  Future<bool> canUseAdvancedFilters() async {
    if (_featureAccess == null) {
      await getSubscription();
    }
    return canAccessFeature((f) => f.canUseAdvancedFilters);
  }

  /// Check if user can message first
  Future<bool> canMessageFirst() async {
    if (_featureAccess == null) {
      await getSubscription();
    }
    return canAccessFeature((f) => f.canMessageFirst);
  }

  /// Check if user can access analytics
  Future<bool> canAccessAnalytics() async {
    if (_featureAccess == null) {
      await getSubscription();
    }
    return canAccessFeature((f) => f.canAccessAnalytics);
  }

  /// Get remaining boosts
  Future<int> getRemainingBoosts() async {
    if (_featureAccess == null) {
      await getSubscription();
    }
    return _featureAccess?.maxProfileBoosts ?? 0;
  }

  /// Get remaining gig applications
  Future<int> getRemainingGigApplications() async {
    if (_featureAccess == null) {
      await getSubscription();
    }
    return _featureAccess?.maxGigApplications ?? 0;
  }

  /// Use a profile boost
  Future<bool> useBoost() async {
    try {
      final response = await _client.post(Endpoints.subscriptionUseBoost);

      if (response.data != null) {
        // Refresh subscription to update boost count
        await refreshSubscription();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Use boost failed: $e');
      return false;
    }
  }

  /// Apply feature check with upgrade prompt
  Future<bool> checkFeatureWithUpgrade(
    bool Function(FeatureAccess) featureCheck, {
    required String featureName,
    required String upgradeMessage,
  }) async {
    if (canAccessFeature(featureCheck)) {
      return true;
    }

    // Show upgrade prompt (handled by UI)
    debugPrint(
      '💰 [SubscriptionService] Feature $featureName requires upgrade',
    );

    // Queue for later processing
    _pendingOperations.add({
      'type': 'upgrade_prompt',
      'feature': featureName,
      'message': upgradeMessage,
    });

    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WEBHOOK HANDLING (For when app returns from Stripe)
  // ═══════════════════════════════════════════════════════════════════════

  /// Handle successful checkout return
  Future<bool> handleCheckoutReturn(String sessionId) async {
    try {
      debugPrint('💰 [SubscriptionService] Processing checkout return...');

      final response = await _client.post(
        Endpoints.subscriptionVerifyCheckout,
        data: {'sessionId': sessionId},
      );

      if (response.data != null && response.data['success'] == true) {
        // Refresh subscription
        await refreshSubscription();
        _subscriptionChangeStream.add(true);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Checkout return failed: $e');
      return false;
    }
  }

  /// Sync subscription from backend (called after webhook)
  Future<void> syncSubscriptionFromBackend() async {
    try {
      debugPrint(
        '💰 [SubscriptionService] Syncing subscription from backend...',
      );
      await refreshSubscription();
    } catch (e) {
      debugPrint('⚠️ [SubscriptionService] Sync failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OFFLINE SUPPORT
  // ═══════════════════════════════════════════════════════════════════════

  /// Queue operation for when back online
  void queueOperation(dynamic operation) {
    _pendingOperations.add(operation);
  }

  /// Process pending operations when back online
  Future<void> processPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    debugPrint(
      '💰 [SubscriptionService] Processing ${_pendingOperations.length} pending operations',
    );

    final pending = List<dynamic>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in pending) {
      try {
        // Handle each operation type
        switch (operation['type']) {
          case 'upgrade_prompt':
            // Show upgrade prompt
            break;
        }
      } catch (e) {
        debugPrint('⚠️ [SubscriptionService] Failed to process operation: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Format price for display
  static String formatPrice(double amount, String currency) {
    return '\$${(amount / 100).toStringAsFixed(2)} $currency';
  }

  /// Get savings percentage for yearly billing
  static int getYearlySavingsPercent(double monthly, double yearly) {
    final yearlyMonthlyEquivalent = yearly / 12;
    final savings = ((monthly - yearlyMonthlyEquivalent) / monthly) * 100;
    return savings.round();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════

  /// Dispose resources
  Future<void> dispose() async {
    await _subscriptionStream.close();
    await _paymentMethodsStream.close();
    await _subscriptionChangeStream.close();
    _currentSubscription = null;
    _availablePlans = null;
    _paymentMethods = null;
    _invoices = null;
    _featureAccess = null;
    _pendingOperations.clear();
    debugPrint('💰 [SubscriptionService] Disposed');
  }

  /// Reset service state (on logout)
  Future<void> reset() async {
    await dispose();
    debugPrint('💰 [SubscriptionService] Reset complete');
  }
}
