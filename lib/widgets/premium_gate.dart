/// 🔒 Premium Gate Widget
///
/// Widget for gating features behind premium subscriptions.
/// Shows a locked state with upgrade prompt when user doesn't have access.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/user_models.dart' show SubscriptionTier;

/// Gate a feature behind a subscription tier
class PremiumGate extends StatelessWidget {
  final Widget child;
  final String featureName;
  final String? message;
  final bool requirePro;
  final bool requirePremium;
  final VoidCallback? onUpgradePressed;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
    this.message,
    this.requirePro = false,
    this.requirePremium = false,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final hasAccess = _checkAccess(authProvider);

    if (hasAccess) {
      return child;
    }

    return _buildLockedState(context);
  }

  bool _checkAccess(AuthProvider authProvider) {
    final tier = authProvider.subscriptionTier;

    if (requirePremium) {
      return tier == SubscriptionTier.premium;
    }

    if (requirePro) {
      return tier == SubscriptionTier.pro ||
          tier == SubscriptionTier.premium;
    }

    // Default: any paid tier
    return authProvider.isPaidUser;
  }

  Widget _buildLockedState(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final requiredTier = requirePremium ? 'Premium' : 'Pro';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.crimson.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.crimson.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: AppColors.crimson,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            featureName,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Upgrade to $requiredTier to unlock this feature',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUpgradePressed ?? () => _navigateToPremium(context),
              icon: const Icon(Icons.star_rounded, size: 20),
              label: Text('Upgrade to $requiredTier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPremium(BuildContext context) {
    // Cache navigator before async gap
    final nav = Navigator.of(context);
    nav.pushNamed('/premium');
  }
}

/// Inline premium badge for indicating locked features
class PremiumBadge extends StatelessWidget {
  final String? label;
  final bool mini;

  const PremiumBadge({
    super.key,
    this.label,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mini) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.crimson, Colors.purple],
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.star_rounded,
          size: 12,
          color: Colors.white,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.crimson, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: Colors.white,
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget that shows content only if user has the required subscription
class PremiumOnly extends StatelessWidget {
  final Widget child;
  final Widget? placeholder;
  final bool requirePro;
  final bool requirePremium;

  const PremiumOnly({
    super.key,
    required this.child,
    this.placeholder,
    this.requirePro = false,
    this.requirePremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final tier = authProvider.subscriptionTier;

    bool hasAccess = false;
    if (requirePremium) {
      hasAccess = tier == SubscriptionTier.premium;
    } else if (requirePro) {
      hasAccess = tier == SubscriptionTier.pro ||
          tier == SubscriptionTier.premium;
    } else {
      hasAccess = authProvider.isPaidUser;
    }

    if (hasAccess) {
      return child;
    }

    return placeholder ?? const SizedBox.shrink();
  }
}
