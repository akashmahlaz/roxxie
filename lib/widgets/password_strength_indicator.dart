import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// 🔐 REAL-TIME PASSWORD STRENGTH INDICATOR
///
/// Modern UX pattern with:
/// - Live validation as user types
/// - Visual checkmarks for requirements
/// - Strength meter (weak, medium, strong)
/// - No "confirm password" needed

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final strength = _calculateStrength();
    final requirements = _getRequirements();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength meter
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength.value,
                  backgroundColor: AppColors.border(brightness),
                  valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strength.label,
              style: TextStyle(
                color: strength.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        if (showRequirements && password.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Requirements checklist
          ...requirements.map((req) => _buildRequirement(req, brightness)),
        ],
      ],
    );
  }

  Widget _buildRequirement(_Requirement req, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            req.met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: req.met ? Colors.green : AppColors.textTert(brightness),
          ),
          const SizedBox(width: 8),
          Text(
            req.label,
            style: TextStyle(
              color: req.met ? AppColors.text(brightness) : AppColors.textSec(brightness),
              fontSize: 12,
              fontWeight: req.met ? FontWeight.w500 : FontWeight.w400,
              decoration: req.met ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  _PasswordStrength _calculateStrength() {
    if (password.isEmpty) {
      return _PasswordStrength(0.0, 'No password', Colors.grey);
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[@$!%*?&]'))) score++;
    if (password.length >= 12) score++;

    if (score <= 2) {
      return _PasswordStrength(0.33, 'Weak', Colors.red);
    } else if (score <= 4) {
      return _PasswordStrength(0.66, 'Medium', Colors.orange);
    } else {
      return _PasswordStrength(1.0, 'Strong', Colors.green);
    }
  }

  List<_Requirement> _getRequirements() {
    return [
      _Requirement(
        'At least 8 characters',
        password.length >= 8,
      ),
      _Requirement(
        'One uppercase letter (A-Z)',
        password.contains(RegExp(r'[A-Z]')),
      ),
      _Requirement(
        'One lowercase letter (a-z)',
        password.contains(RegExp(r'[a-z]')),
      ),
      _Requirement(
        'One number (0-9)',
        password.contains(RegExp(r'[0-9]')),
      ),
      _Requirement(
        'One special character (@\$!%*?&)',
        password.contains(RegExp(r'[@$!%*?&]')),
      ),
    ];
  }

  bool get isValid {
    return _getRequirements().every((req) => req.met);
  }
}

class _PasswordStrength {
  final double value;
  final String label;
  final Color color;

  _PasswordStrength(this.value, this.label, this.color);
}

class _Requirement {
  final String label;
  final bool met;

  _Requirement(this.label, this.met);
}
