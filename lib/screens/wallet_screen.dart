/// 💰 GIGMATCH Wallet & Earnings Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass balance card with parallax
/// - Animated counter for earnings
/// - Swipe-to-action on transactions
/// - Pull-to-refresh with haptic feedback
/// - Premium payout tracking
/// - Glass morphism transaction cards
///
/// Complete financial management for artists & venues
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 💰 WALLET SCREEN - Main Widget
// ═══════════════════════════════════════════════════════════════════════════

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _balanceController;
  late AnimationController _cardController;
  late Animation<double> _balanceAnimation;
  late Animation<double> _cardAnimation;

  bool _isLoading = false;
  bool _showBalance = true;

  // Mock wallet data
  final _walletData = WalletData(
    availableBalance: 2847.50,
    pendingBalance: 650.00,
    totalEarnings: 12650.00,
    thisMonth: 1850.00,
    lastPayout: DateTime.now().subtract(const Duration(days: 7)),
    payoutMethod: 'Bank Account ••••4521',
  );

  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      type: TransactionType.earning,
      title: 'Jazz Night Performance',
      venue: 'The Velvet Lounge',
      amount: 350.00,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      status: TransactionStatus.completed,
    ),
    Transaction(
      id: '2',
      type: TransactionType.payout,
      title: 'Bank Transfer',
      venue: '••••4521',
      amount: 1200.00,
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: TransactionStatus.completed,
    ),
    Transaction(
      id: '3',
      type: TransactionType.earning,
      title: 'Corporate Event',
      venue: 'Grand Hotel Ballroom',
      amount: 800.00,
      date: DateTime.now().subtract(const Duration(days: 5)),
      status: TransactionStatus.pending,
    ),
    Transaction(
      id: '4',
      type: TransactionType.earning,
      title: 'Weekend Brunch',
      venue: 'Riverside Café',
      amount: 250.00,
      date: DateTime.now().subtract(const Duration(days: 7)),
      status: TransactionStatus.completed,
    ),
    Transaction(
      id: '5',
      type: TransactionType.fee,
      title: 'Platform Fee',
      venue: 'GigMatch',
      amount: 35.00,
      date: DateTime.now().subtract(const Duration(days: 7)),
      status: TransactionStatus.completed,
    ),
    Transaction(
      id: '6',
      type: TransactionType.payout,
      title: 'Bank Transfer',
      venue: '••••4521',
      amount: 2000.00,
      date: DateTime.now().subtract(const Duration(days: 14)),
      status: TransactionStatus.completed,
    ),
    Transaction(
      id: '7',
      type: TransactionType.earning,
      title: 'Club Night DJ Set',
      venue: 'Electric Dreams',
      amount: 500.00,
      date: DateTime.now().subtract(const Duration(days: 18)),
      status: TransactionStatus.completed,
    ),
    Transaction(
      id: '8',
      type: TransactionType.refund,
      title: 'Cancelled Gig Refund',
      venue: 'Blue Note',
      amount: 150.00,
      date: DateTime.now().subtract(const Duration(days: 21)),
      status: TransactionStatus.completed,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _balanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _balanceAnimation = CurvedAnimation(
      parent: _balanceController,
      curve: Curves.easeOutCubic,
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );

    _balanceController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _balanceController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Custom App Bar
          _buildAppBar(brightness),

          // Balance Card
          SliverToBoxAdapter(
            child: _buildBalanceCard(brightness),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: _buildQuickActions(brightness),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabController,
              brightness: brightness,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTransactionsList(brightness, null),
            _buildTransactionsList(brightness, TransactionType.earning),
            _buildTransactionsList(brightness, TransactionType.payout),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(Brightness brightness) {
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background(brightness),
      elevation: 0,
      leading: AnimatedTapFeedback(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(brightness)),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.text(brightness),
          ),
        ),
      ),
      title: Text(
        'Wallet',
        style: AppTypography.headlineSmall.copyWith(
          color: AppColors.text(brightness),
        ),
      ),
      actions: [
        AnimatedTapFeedback(
          onTap: () {
            HapticFeedback.selectionClick();
            _showPayoutSettings(brightness);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: AppColors.text(brightness),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💳 BALANCE CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBalanceCard(Brightness brightness) {
    return FadeTransition(
      opacity: _cardAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_cardAnimation),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.crimson,
                AppColors.crimson.withValues(alpha: 0.8),
                Colors.purple.shade600,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AnimatedTapFeedback(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showBalance = !_showBalance);
                          },
                          child: Icon(
                            _showBalance
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Balance
                    AnimatedBuilder(
                      animation: _balanceAnimation,
                      builder: (context, child) {
                        final value = _walletData.availableBalance *
                            _balanceAnimation.value;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _showBalance
                                  ? value.toStringAsFixed(2)
                                  : '••••••',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Pending
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            color: Colors.amber.shade200,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showBalance
                                ? '\$${_walletData.pendingBalance.toStringAsFixed(2)} pending'
                                : '•••• pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceStat(
                            'This Month',
                            _showBalance
                                ? '\$${_walletData.thisMonth.toStringAsFixed(0)}'
                                : '••••',
                            Icons.trending_up_rounded,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: _buildBalanceStat(
                            'Total Earnings',
                            _showBalance
                                ? '\$${_walletData.totalEarnings.toStringAsFixed(0)}'
                                : '••••',
                            Icons.account_balance_wallet_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚡ QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.arrow_upward_rounded,
              label: 'Withdraw',
              color: AppColors.success,
              onTap: () => _showWithdrawSheet(brightness),
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.history_rounded,
              label: 'History',
              color: AppColors.info,
              onTap: () {
                HapticFeedback.selectionClick();
                _tabController.animateTo(0);
              },
              brightness: brightness,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.receipt_long_rounded,
              label: 'Invoices',
              color: Colors.orange,
              onTap: () => _showInvoices(brightness),
              brightness: brightness,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 TRANSACTIONS LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTransactionsList(
    Brightness brightness,
    TransactionType? filterType,
  ) {
    final filtered = filterType != null
        ? _transactions.where((t) => t.type == filterType).toList()
        : _transactions;

    if (_isLoading) {
      return const _TransactionSkeletonList();
    }

    if (filtered.isEmpty) {
      return _buildEmptyState(brightness, filterType);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.crimson,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final transaction = filtered[index];
          final showDateHeader = index == 0 ||
              !_isSameDay(filtered[index - 1].date, transaction.date);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateHeader)
                Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : 16,
                    bottom: 8,
                  ),
                  child: Text(
                    _formatDateHeader(transaction.date),
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              _TransactionCard(
                transaction: transaction,
                brightness: brightness,
                onTap: () => _showTransactionDetails(transaction, brightness),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness, TransactionType? type) {
    final icon = type == TransactionType.earning
        ? Icons.payments_rounded
        : type == TransactionType.payout
            ? Icons.account_balance_rounded
            : Icons.receipt_long_rounded;

    final message = type == TransactionType.earning
        ? 'No earnings yet'
        : type == TransactionType.payout
            ? 'No payouts yet'
            : 'No transactions yet';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(brightness)),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.textTert(brightness),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transactions will appear here',
            style: TextStyle(
              color: AppColors.textTert(brightness),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 DATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎭 BOTTOM SHEETS & DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showWithdrawSheet(Brightness brightness) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _WithdrawSheet(
        availableBalance: _walletData.availableBalance,
        payoutMethod: _walletData.payoutMethod,
        brightness: brightness,
      ),
    );
  }

  void _showPayoutSettings(Brightness brightness) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PayoutSettingsSheet(brightness: brightness),
    );
  }

  void _showInvoices(Brightness brightness) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invoices coming soon!'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction, Brightness brightness) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TransactionDetailSheet(
        transaction: transaction,
        brightness: brightness,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Brightness brightness;

  _TabBarDelegate({required this.tabController, required this.brightness});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background(brightness),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.crimson,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.crimson,
        unselectedLabelColor: AppColors.textSec(brightness),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Earnings'),
          Tab(text: 'Payouts'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

// ═══════════════════════════════════════════════════════════════════════════
// 🃏 QUICK ACTION BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Brightness brightness;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💳 TRANSACTION CARD
// ═══════════════════════════════════════════════════════════════════════════

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Brightness brightness;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTypeColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTypeIcon(),
                color: _getTypeColor(),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        transaction.venue,
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 13,
                        ),
                      ),
                      if (transaction.status == TransactionStatus.pending) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Pending',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '${_isPositive() ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: _isPositive() ? AppColors.success : AppColors.text(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isPositive() {
    return transaction.type == TransactionType.earning ||
        transaction.type == TransactionType.refund;
  }

  IconData _getTypeIcon() {
    switch (transaction.type) {
      case TransactionType.earning:
        return Icons.arrow_downward_rounded;
      case TransactionType.payout:
        return Icons.arrow_upward_rounded;
      case TransactionType.fee:
        return Icons.receipt_rounded;
      case TransactionType.refund:
        return Icons.replay_rounded;
    }
  }

  Color _getTypeColor() {
    switch (transaction.type) {
      case TransactionType.earning:
        return AppColors.success;
      case TransactionType.payout:
        return AppColors.info;
      case TransactionType.fee:
        return Colors.orange;
      case TransactionType.refund:
        return Colors.purple;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💀 SKELETON LOADERS
// ═══════════════════════════════════════════════════════════════════════════

class _TransactionSkeletonList extends StatelessWidget {
  const _TransactionSkeletonList();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ShimmerBase(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.skeleton(brightness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBase(
                      child: Container(
                        height: 16,
                        width: 140,
                        decoration: BoxDecoration(
                          color: AppColors.skeleton(brightness),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ShimmerBase(
                      child: Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.skeleton(brightness),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ShimmerBase(
                child: Container(
                  height: 18,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.skeleton(brightness),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📄 WITHDRAW SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _WithdrawSheet extends StatefulWidget {
  final double availableBalance;
  final String payoutMethod;
  final Brightness brightness;

  const _WithdrawSheet({
    required this.availableBalance,
    required this.payoutMethod,
    required this.brightness,
  });

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _withdraw() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const AnimatedSuccessCheck(size: 20, color: Colors.white),
              const SizedBox(width: 12),
              Text('Withdrawal of \$$amount initiated!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(widget.brightness),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(widget.brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdraw Funds',
                  style: TextStyle(
                    color: AppColors.text(widget.brightness),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available: \$${widget.availableBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.textSec(widget.brightness),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                // Amount input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background(widget.brightness),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(widget.brightness)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '\$',
                        style: TextStyle(
                          color: AppColors.text(widget.brightness),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            color: AppColors.text(widget.brightness),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: AppColors.textTert(widget.brightness),
                            ),
                          ),
                        ),
                      ),
                      AnimatedTapFeedback(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _amountController.text =
                              widget.availableBalance.toStringAsFixed(2);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.crimson.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'MAX',
                            style: TextStyle(
                              color: AppColors.crimson,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Payout method
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background(widget.brightness),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(widget.brightness)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        color: AppColors.text(widget.brightness),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payout to',
                              style: TextStyle(
                                color: AppColors.textSec(widget.brightness),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              widget.payoutMethod,
                              style: TextStyle(
                                color: AppColors.text(widget.brightness),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Withdraw button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _withdraw,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Withdraw',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Info text
                Text(
                  'Withdrawals typically arrive within 1-3 business days',
                  style: TextStyle(
                    color: AppColors.textTert(widget.brightness),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ⚙️ PAYOUT SETTINGS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _PayoutSettingsSheet extends StatelessWidget {
  final Brightness brightness;

  const _PayoutSettingsSheet({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payout Settings',
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),

                _PayoutMethodTile(
                  icon: Icons.account_balance_rounded,
                  title: 'Bank Account',
                  subtitle: '••••4521',
                  isSelected: true,
                  brightness: brightness,
                  onTap: () {},
                ),

                const SizedBox(height: 12),

                _PayoutMethodTile(
                  icon: Icons.paypal_rounded,
                  title: 'PayPal',
                  subtitle: 'Not connected',
                  isSelected: false,
                  brightness: brightness,
                  onTap: () {},
                ),

                const SizedBox(height: 12),

                _PayoutMethodTile(
                  icon: Icons.credit_card_rounded,
                  title: 'Debit Card',
                  subtitle: 'Not connected',
                  isSelected: false,
                  brightness: brightness,
                  onTap: () {},
                ),

                const SizedBox(height: 24),

                AnimatedTapFeedback(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.crimson),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: AppColors.crimson),
                        SizedBox(width: 8),
                        Text(
                          'Add Payout Method',
                          style: TextStyle(
                            color: AppColors.crimson,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

class _PayoutMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Brightness brightness;
  final VoidCallback onTap;

  const _PayoutMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.crimson.withValues(alpha: 0.1)
              : AppColors.background(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.crimson : AppColors.border(brightness),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.text(brightness)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.crimson,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📄 TRANSACTION DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;
  final Brightness brightness;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                // Amount
                Text(
                  '${_isPositive() ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _isPositive() ? AppColors.success : AppColors.text(brightness),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  transaction.title,
                  style: TextStyle(
                    color: AppColors.text(brightness),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                // Details
                _DetailRow(
                  label: 'Status',
                  value: transaction.status == TransactionStatus.pending
                      ? 'Pending'
                      : 'Completed',
                  valueColor: transaction.status == TransactionStatus.pending
                      ? Colors.amber
                      : AppColors.success,
                  brightness: brightness,
                ),
                _DetailRow(
                  label: 'Type',
                  value: transaction.type.name[0].toUpperCase() +
                      transaction.type.name.substring(1),
                  brightness: brightness,
                ),
                _DetailRow(
                  label: 'From/To',
                  value: transaction.venue,
                  brightness: brightness,
                ),
                _DetailRow(
                  label: 'Date',
                  value: _formatDate(transaction.date),
                  brightness: brightness,
                ),
                _DetailRow(
                  label: 'Transaction ID',
                  value: 'TXN-${transaction.id.padLeft(8, '0')}',
                  brightness: brightness,
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                        },
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('Receipt'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.text(brightness),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                        },
                        icon: const Icon(Icons.help_outline_rounded),
                        label: const Text('Support'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.text(brightness),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isPositive() {
    return transaction.type == TransactionType.earning ||
        transaction.type == TransactionType.refund;
  }

  IconData _getTypeIcon() {
    switch (transaction.type) {
      case TransactionType.earning:
        return Icons.arrow_downward_rounded;
      case TransactionType.payout:
        return Icons.arrow_upward_rounded;
      case TransactionType.fee:
        return Icons.receipt_rounded;
      case TransactionType.refund:
        return Icons.replay_rounded;
    }
  }

  Color _getTypeColor() {
    switch (transaction.type) {
      case TransactionType.earning:
        return AppColors.success;
      case TransactionType.payout:
        return AppColors.info;
      case TransactionType.fee:
        return Colors.orange;
      case TransactionType.refund:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Brightness brightness;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.text(brightness),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📦 DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class WalletData {
  final double availableBalance;
  final double pendingBalance;
  final double totalEarnings;
  final double thisMonth;
  final DateTime lastPayout;
  final String payoutMethod;

  const WalletData({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarnings,
    required this.thisMonth,
    required this.lastPayout,
    required this.payoutMethod,
  });
}

enum TransactionType { earning, payout, fee, refund }

enum TransactionStatus { pending, completed }

class Transaction {
  final String id;
  final TransactionType type;
  final String title;
  final String venue;
  final double amount;
  final DateTime date;
  final TransactionStatus status;

  const Transaction({
    required this.id,
    required this.type,
    required this.title,
    required this.venue,
    required this.amount,
    required this.date,
    required this.status,
  });
}
