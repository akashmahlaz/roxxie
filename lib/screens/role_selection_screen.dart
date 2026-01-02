import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

/// 🎭 ROLE SELECTION SCREEN
///
/// User chooses: Artist/Band or Venue/Organizer
/// Premium card-based selection with hover effects

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _continue() {
    if (_selectedRole == null) return;

    // TODO: Navigate to signup based on role
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: $_selectedRole - Next screen coming soon!'),
        backgroundColor: AppColors.charcoal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          const AuroraBackground(),

          // Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(position: _slideUp, child: child),
                );
              },
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),

                    // Header
                    Text(
                      'How will you\nuse Roxxie?',
                      style: AppTypography.displaySmall,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Choose your role to get started',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const Spacer(),

                    // Role Cards
                    _buildRoleCard(
                      role: 'artist',
                      icon: Icons.music_note_rounded,
                      title: "I'm an Artist",
                      description:
                          'Showcase your music and find gigs at amazing venues',
                      gradient: AppColors.primaryGradient,
                      isSelected: _selectedRole == 'artist',
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    _buildRoleCard(
                      role: 'venue',
                      icon: Icons.stadium_rounded,
                      title: "I'm a Venue",
                      description:
                          'Discover talented artists for your events and venues',
                      gradient: AppColors.venueGradient,
                      isSelected: _selectedRole == 'venue',
                    ),

                    const Spacer(),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        text: 'Continue',
                        onPressed: _selectedRole != null ? _continue : null,
                        enabled: _selectedRole != null,
                        icon: Icons.arrow_forward_rounded,
                        iconAfter: true,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: AppSpacing.cardPaddingLarge,
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: AppSpacing.borderRadiusXl,
          border: Border.all(
            color: isSelected
                ? (role == 'artist' ? AppColors.crimson : AppColors.cyan)
                : AppColors.slate,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? (role == 'artist'
                    ? AppShadows.crimsonGlow
                    : AppShadows.cyanGlow)
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: AppSpacing.borderRadiusLg,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              (role == 'artist'
                                      ? AppColors.crimson
                                      : AppColors.cyan)
                                  .withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, size: 32, color: AppColors.pureWhite),
            ),

            const SizedBox(width: AppSpacing.lg),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? (role == 'artist' ? AppColors.crimson : AppColors.cyan)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.slate,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.pureWhite,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
