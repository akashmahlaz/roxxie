import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 📊 PROFILE COMPLETION TRACKER
///
/// Shows user progress and motivates completion with:
/// - Visual percentage progress
/// - Benefits of completion
/// - Non-blocking prompts
/// - Gamification elements

class ProfileCompletionTracker extends StatelessWidget {
  final int completedSteps;
  final int totalSteps;
  final List<String> missingSteps;
  final VoidCallback? onCompleteProfile;

  const ProfileCompletionTracker({
    super.key,
    required this.completedSteps,
    required this.totalSteps,
    this.missingSteps = const [],
    this.onCompleteProfile,
  });

  double get percentage => (completedSteps / totalSteps * 100).clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (completedSteps == totalSteps) {
      // Profile complete - show celebration
      return _buildCompleteCard(brightness);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.crimson.withValues(alpha: 0.1),
            AppColors.cyan.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(brightness),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Strength',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedSteps of $totalSteps completed',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStrengthColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    color: _getStrengthColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.border(brightness),
              valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 16),

          // Benefits callout
          _buildBenefitCallout(brightness),

          if (missingSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Missing steps
            Text(
              'Complete these to boost visibility:',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...missingSteps.take(3).map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.textTert(brightness),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        step,
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          if (onCompleteProfile != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCompleteProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitCallout(Brightness brightness) {
    final benefit = _getBenefitMessage();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border(brightness),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_rounded,
            color: AppColors.crimson,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteCard(Brightness brightness) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Complete! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'re ready to get discovered!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStrengthColor() {
    if (percentage < 30) return Colors.red;
    if (percentage < 60) return Colors.orange;
    if (percentage < 80) return Colors.amber;
    return Colors.green;
  }

  String _getBenefitMessage() {
    if (percentage < 30) {
      return 'Complete your profile to appear in search results!';
    } else if (percentage < 60) {
      return 'You\'re making progress! Add photos to get 3x more views.';
    } else if (percentage < 80) {
      return 'Almost there! Complete profiles get 5x more matches.';
    } else {
      return 'Looking great! Just a few more details to stand out.';
    }
  }
}
