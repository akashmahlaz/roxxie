/// 💰 GIGMATCH Wallet Service
///
/// Handles all wallet and payout related operations:
/// - Balance retrieval (available, pending, total earnings)
/// - Transaction history with filtering
/// - Payout/withdrawal requests
/// - Stripe Connect integration for artist payouts
/// - Payout method management
library;

import '../api/api_client.dart';
import '../api/endpoints.dart';

/// Wallet balance and summary
class WalletBalance {
  final double availableBalance;
  final double pendingBalance;
  final double totalEarnings;
  final double thisMonth;
  final double thisWeek;
  final DateTime? lastPayoutDate;
  final String? defaultPayoutMethod;
  final bool stripeConnected;
  final String? stripeAccountStatus;

  const WalletBalance({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarnings,
    required this.thisMonth,
    required this.thisWeek,
    this.lastPayoutDate,
    this.defaultPayoutMethod,
    required this.stripeConnected,
    this.stripeAccountStatus,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      availableBalance: (json['availableBalance'] ?? 0).toDouble(),
      pendingBalance: (json['pendingBalance'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      thisMonth: (json['thisMonth'] ?? 0).toDouble(),
      thisWeek: (json['thisWeek'] ?? 0).toDouble(),
      lastPayoutDate: json['lastPayoutDate'] != null
          ? DateTime.tryParse(json['lastPayoutDate'])
          : null,
      defaultPayoutMethod: json['defaultPayoutMethod'],
      stripeConnected: json['stripeConnected'] ?? false,
      stripeAccountStatus: json['stripeAccountStatus'],
    );
  }

  /// Empty/default wallet balance
  factory WalletBalance.empty() => const WalletBalance(
        availableBalance: 0,
        pendingBalance: 0,
        totalEarnings: 0,
        thisMonth: 0,
        thisWeek: 0,
        stripeConnected: false,
      );
}

/// Transaction type
enum WalletTransactionType {
  earning,
  payout,
  fee,
  refund,
  adjustment;

  static WalletTransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'earning':
        return WalletTransactionType.earning;
      case 'payout':
        return WalletTransactionType.payout;
      case 'fee':
        return WalletTransactionType.fee;
      case 'refund':
        return WalletTransactionType.refund;
      case 'adjustment':
        return WalletTransactionType.adjustment;
      default:
        return WalletTransactionType.earning;
    }
  }

  String get displayName {
    switch (this) {
      case WalletTransactionType.earning:
        return 'Earning';
      case WalletTransactionType.payout:
        return 'Payout';
      case WalletTransactionType.fee:
        return 'Fee';
      case WalletTransactionType.refund:
        return 'Refund';
      case WalletTransactionType.adjustment:
        return 'Adjustment';
    }
  }
}

/// Transaction status
enum WalletTransactionStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled;

  static WalletTransactionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return WalletTransactionStatus.pending;
      case 'processing':
        return WalletTransactionStatus.processing;
      case 'completed':
        return WalletTransactionStatus.completed;
      case 'failed':
        return WalletTransactionStatus.failed;
      case 'cancelled':
        return WalletTransactionStatus.cancelled;
      default:
        return WalletTransactionStatus.pending;
    }
  }
}

/// Wallet transaction
class WalletTransaction {
  final String id;
  final WalletTransactionType type;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final WalletTransactionStatus status;
  final String? bookingId;
  final String? gigId;
  final String? venueName;
  final Map<String, dynamic>? metadata;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    this.bookingId,
    this.gigId,
    this.venueName,
    this.metadata,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? json['_id'] ?? '',
      type: WalletTransactionType.fromString(json['type'] ?? 'earning'),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
      status: WalletTransactionStatus.fromString(json['status'] ?? 'pending'),
      bookingId: json['bookingId'],
      gigId: json['gigId'],
      venueName: json['venueName'],
      metadata: json['metadata'],
    );
  }

  /// Is this a positive transaction (adds money)
  bool get isCredit =>
      type == WalletTransactionType.earning ||
      type == WalletTransactionType.refund;

  /// Is this a negative transaction (removes money)
  bool get isDebit =>
      type == WalletTransactionType.payout ||
      type == WalletTransactionType.fee;
}

/// Payout method (bank account or card)
class PayoutMethod {
  final String id;
  final String type; // 'bank_account', 'card', 'instant'
  final String last4;
  final String? bankName;
  final String? routingNumber;
  final bool isDefault;
  final String displayName;

  const PayoutMethod({
    required this.id,
    required this.type,
    required this.last4,
    this.bankName,
    this.routingNumber,
    required this.isDefault,
    required this.displayName,
  });

  factory PayoutMethod.fromJson(Map<String, dynamic> json) {
    return PayoutMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? 'bank_account',
      last4: json['last4'] ?? '****',
      bankName: json['bankName'],
      routingNumber: json['routingNumber'],
      isDefault: json['isDefault'] ?? false,
      displayName: json['displayName'] ?? 'Bank Account ••••${json['last4'] ?? '****'}',
    );
  }
}

/// Payout request response
class PayoutResponse {
  final String payoutId;
  final double amount;
  final String status;
  final DateTime estimatedArrival;
  final String? message;

  const PayoutResponse({
    required this.payoutId,
    required this.amount,
    required this.status,
    required this.estimatedArrival,
    this.message,
  });

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    return PayoutResponse(
      payoutId: json['payoutId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.tryParse(json['estimatedArrival']) ?? DateTime.now().add(const Duration(days: 3))
          : DateTime.now().add(const Duration(days: 3)),
      message: json['message'],
    );
  }
}

/// Stripe onboarding link response
class StripeOnboardingLink {
  final String url;
  final DateTime expiresAt;

  const StripeOnboardingLink({
    required this.url,
    required this.expiresAt,
  });

  factory StripeOnboardingLink.fromJson(Map<String, dynamic> json) {
    return StripeOnboardingLink(
      url: json['url'] ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt']) ?? DateTime.now().add(const Duration(hours: 1))
          : DateTime.now().add(const Duration(hours: 1)),
    );
  }
}

/// Wallet Service
class WalletService {
  final ApiClient _apiClient = ApiClient();

  WalletService();

  /// Get wallet balance and summary
  Future<WalletBalance> getBalance() async {
    try {
      final response = await _apiClient.get(Endpoints.walletBalance);
      return WalletBalance.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      // Return empty balance on error
      return WalletBalance.empty();
    }
  }

  /// Get transaction history
  Future<List<WalletTransaction>> getTransactions({
    WalletTransactionType? type,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (type != null) {
        queryParams['type'] = type.name;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _apiClient.get(
        Endpoints.walletTransactions,
        queryParameters: queryParams,
      );
      final data = response.data;
      final List<dynamic> transactions = data is Map
          ? (data['transactions'] ?? [])
          : (data is List ? data : []);
      return transactions
          .map((json) => WalletTransaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get single transaction details
  Future<WalletTransaction?> getTransaction(String id) async {
    try {
      final response = await _apiClient.get(Endpoints.walletTransaction(id));
      return WalletTransaction.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Request a payout/withdrawal
  Future<PayoutResponse> requestPayout({
    required double amount,
    String? payoutMethodId,
    bool instant = false,
  }) async {
    final response = await _apiClient.post(
      Endpoints.walletRequestPayout,
      data: {
        'amount': amount,
        if (payoutMethodId != null) 'payoutMethodId': payoutMethodId,
        'instant': instant,
      },
    );
    return PayoutResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get payout history
  Future<List<WalletTransaction>> getPayoutHistory({
    int page = 1,
    int limit = 20,
  }) async {
    return getTransactions(
      type: WalletTransactionType.payout,
      page: page,
      limit: limit,
    );
  }

  /// Get payout methods
  Future<List<PayoutMethod>> getPayoutMethods() async {
    try {
      final response = await _apiClient.get(Endpoints.walletPayoutMethods);
      final data = response.data;
      final List<dynamic> methods = data is Map
          ? (data['methods'] ?? [])
          : (data is List ? data : []);
      return methods.map((json) => PayoutMethod.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a payout method
  Future<PayoutMethod> addPayoutMethod({
    required String token,
    bool setAsDefault = false,
  }) async {
    final response = await _apiClient.post(
      Endpoints.walletAddPayoutMethod,
      data: {
        'token': token,
        'setAsDefault': setAsDefault,
      },
    );
    return PayoutMethod.fromJson(response.data as Map<String, dynamic>);
  }

  /// Set default payout method
  Future<void> setDefaultPayoutMethod(String methodId) async {
    await _apiClient.post(
      Endpoints.walletSetDefaultPayoutMethod,
      data: {'methodId': methodId},
    );
  }

  /// Remove a payout method
  Future<void> removePayoutMethod(String methodId) async {
    await _apiClient.delete(Endpoints.walletRemovePayoutMethod(methodId));
  }

  /// Get Stripe Connect onboarding link
  /// Call this when artist needs to set up payouts
  Future<StripeOnboardingLink> getStripeOnboardingLink() async {
    final response = await _apiClient.post(
      Endpoints.walletStripeOnboarding,
      data: {},
    );
    return StripeOnboardingLink.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get Stripe Express dashboard link
  /// For artists to view their full payout dashboard
  Future<String> getStripeDashboardLink() async {
    final response = await _apiClient.post(
      Endpoints.walletStripeDashboard,
      data: {},
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String? ?? '';
  }
}
