/// 💰 GIGMATCH Wallet Provider
///
/// State management for wallet and earnings:
/// - Balance management (available, pending, total)
/// - Transaction history with filtering
/// - Payout requests
/// - Stripe Connect status
/// - Loading and error states
library;

import 'package:flutter/foundation.dart';
import '../services/wallet_service.dart';

/// Transaction filter type
enum WalletFilterType {
  all,
  earnings,
  payouts,
  fees,
}

/// Provider state
enum WalletState {
  initial,
  loading,
  loaded,
  error,
  submitting,
}

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════

  WalletState _state = WalletState.initial;
  WalletState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  WalletBalance _balance = WalletBalance.empty();
  WalletBalance get balance => _balance;

  List<WalletTransaction> _transactions = [];
  List<WalletTransaction> get transactions => _transactions;

  List<PayoutMethod> _payoutMethods = [];
  List<PayoutMethod> get payoutMethods => _payoutMethods;

  WalletFilterType _filterType = WalletFilterType.all;
  WalletFilterType get filterType => _filterType;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _currentPage = 1;
  static const int _pageSize = 20;

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool get isLoading => _state == WalletState.loading;
  bool get isSubmitting => _state == WalletState.submitting;
  bool get hasError => _state == WalletState.error;

  /// Filtered transactions based on current filter
  List<WalletTransaction> get filteredTransactions {
    switch (_filterType) {
      case WalletFilterType.all:
        return _transactions;
      case WalletFilterType.earnings:
        return _transactions
            .where((t) => t.type == WalletTransactionType.earning)
            .toList();
      case WalletFilterType.payouts:
        return _transactions
            .where((t) => t.type == WalletTransactionType.payout)
            .toList();
      case WalletFilterType.fees:
        return _transactions
            .where((t) => t.type == WalletTransactionType.fee)
            .toList();
    }
  }

  /// Transactions grouped by date
  Map<String, List<WalletTransaction>> get transactionsByDate {
    final grouped = <String, List<WalletTransaction>>{};
    for (final transaction in filteredTransactions) {
      final key = _formatDateKey(transaction.date);
      grouped.putIfAbsent(key, () => []).add(transaction);
    }
    return grouped;
  }

  /// Default payout method
  PayoutMethod? get defaultPayoutMethod {
    try {
      return _payoutMethods.firstWhere((m) => m.isDefault);
    } catch (e) {
      return _payoutMethods.isNotEmpty ? _payoutMethods.first : null;
    }
  }

  /// Is Stripe Connect set up
  bool get isStripeConnected => _balance.stripeConnected;

  /// Can request payout
  bool get canRequestPayout =>
      _balance.availableBalance > 0 && isStripeConnected;

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize wallet data
  Future<void> initialize() async {
    if (_state == WalletState.loading) return;

    _state = WalletState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _walletService.getBalance(),
        _walletService.getTransactions(limit: _pageSize),
        _walletService.getPayoutMethods(),
      ]);

      _balance = results[0] as WalletBalance;
      _transactions = results[1] as List<WalletTransaction>;
      _payoutMethods = results[2] as List<PayoutMethod>;
      _currentPage = 1;
      _hasMore = _transactions.length >= _pageSize;
      _state = WalletState.loaded;
    } catch (e) {
      _state = WalletState.error;
      _errorMessage = 'Failed to load wallet data';
    }

    notifyListeners();
  }

  /// Refresh all wallet data
  Future<void> refresh() async {
    _currentPage = 1;
    await initialize();
  }

  /// Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    if (!_hasMore || _state == WalletState.loading) return;

    _currentPage++;
    try {
      WalletTransactionType? typeFilter;
      if (_filterType == WalletFilterType.earnings) {
        typeFilter = WalletTransactionType.earning;
      } else if (_filterType == WalletFilterType.payouts) {
        typeFilter = WalletTransactionType.payout;
      } else if (_filterType == WalletFilterType.fees) {
        typeFilter = WalletTransactionType.fee;
      }

      final moreTransactions = await _walletService.getTransactions(
        type: typeFilter,
        page: _currentPage,
        limit: _pageSize,
      );

      _transactions.addAll(moreTransactions);
      _hasMore = moreTransactions.length >= _pageSize;
      notifyListeners();
    } catch (e) {
      _currentPage--;
    }
  }

  /// Set filter type
  Future<void> setFilterType(WalletFilterType type) async {
    if (_filterType == type) return;

    _filterType = type;
    _currentPage = 1;
    _state = WalletState.loading;
    notifyListeners();

    try {
      WalletTransactionType? typeFilter;
      if (type == WalletFilterType.earnings) {
        typeFilter = WalletTransactionType.earning;
      } else if (type == WalletFilterType.payouts) {
        typeFilter = WalletTransactionType.payout;
      } else if (type == WalletFilterType.fees) {
        typeFilter = WalletTransactionType.fee;
      }

      _transactions = await _walletService.getTransactions(
        type: typeFilter,
        page: 1,
        limit: _pageSize,
      );
      _hasMore = _transactions.length >= _pageSize;
      _state = WalletState.loaded;
    } catch (e) {
      _state = WalletState.error;
      _errorMessage = 'Failed to load transactions';
    }

    notifyListeners();
  }

  /// Request a payout
  Future<PayoutResponse?> requestPayout({
    required double amount,
    String? payoutMethodId,
    bool instant = false,
  }) async {
    if (_state == WalletState.submitting) return null;

    _state = WalletState.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _walletService.requestPayout(
        amount: amount,
        payoutMethodId: payoutMethodId,
        instant: instant,
      );

      // Refresh balance after payout
      _balance = await _walletService.getBalance();
      _state = WalletState.loaded;
      notifyListeners();

      return response;
    } catch (e) {
      _state = WalletState.loaded;
      _errorMessage = 'Failed to request payout';
      notifyListeners();
      rethrow;
    }
  }

  /// Get Stripe onboarding link
  Future<String?> getStripeOnboardingLink() async {
    try {
      final link = await _walletService.getStripeOnboardingLink();
      return link.url;
    } catch (e) {
      _errorMessage = 'Failed to get Stripe onboarding link';
      notifyListeners();
      return null;
    }
  }

  /// Get Stripe dashboard link
  Future<String?> getStripeDashboardLink() async {
    try {
      return await _walletService.getStripeDashboardLink();
    } catch (e) {
      _errorMessage = 'Failed to get Stripe dashboard link';
      notifyListeners();
      return null;
    }
  }

  /// Add a payout method
  Future<PayoutMethod?> addPayoutMethod({
    required String token,
    bool setAsDefault = false,
  }) async {
    try {
      final method = await _walletService.addPayoutMethod(
        token: token,
        setAsDefault: setAsDefault,
      );
      _payoutMethods.add(method);
      notifyListeners();
      return method;
    } catch (e) {
      _errorMessage = 'Failed to add payout method';
      notifyListeners();
      return null;
    }
  }

  /// Set default payout method
  Future<void> setDefaultPayoutMethod(String methodId) async {
    try {
      await _walletService.setDefaultPayoutMethod(methodId);
      // Update local state
      for (int i = 0; i < _payoutMethods.length; i++) {
        final method = _payoutMethods[i];
        _payoutMethods[i] = PayoutMethod(
          id: method.id,
          type: method.type,
          last4: method.last4,
          bankName: method.bankName,
          routingNumber: method.routingNumber,
          isDefault: method.id == methodId,
          displayName: method.displayName,
        );
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to set default payout method';
      notifyListeners();
    }
  }

  /// Remove a payout method
  Future<void> removePayoutMethod(String methodId) async {
    try {
      await _walletService.removePayoutMethod(methodId);
      _payoutMethods.removeWhere((m) => m.id == methodId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to remove payout method';
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
