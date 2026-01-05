/// 📝 GIGMATCH Register Screen
/// User registration with role selection

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  UserRole _selectedRole = UserRole.artist;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _selectedRole,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/profile-setup');
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.crimson,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.offWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Create Account',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.offWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join the community',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.mediumGray,
                ),
              ),

              const SizedBox(height: 32),

              // Role selection
              Text(
                'I am a...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.offWhite,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.music_note,
                      title: 'Artist',
                      description: 'Looking for gigs',
                      isSelected: _selectedRole == UserRole.artist,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.artist),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.business,
                      title: 'Venue',
                      description: 'Hiring artists',
                      isSelected: _selectedRole == UserRole.venue,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.venue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name
                    GlassTextField(
                      controller: _nameController,
                      labelText: _selectedRole == UserRole.artist
                          ? 'Full Name'
                          : 'Venue Name',
                      hintText: _selectedRole == UserRole.artist
                          ? 'Enter your name'
                          : 'Enter venue name',
                      prefixIcon: _selectedRole == UserRole.artist
                          ? Icons.person_outline
                          : Icons.business_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email
                    GlassTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password
                    GlassTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Create a password',
                      prefixIcon: Icons.lock_outlined,
                      obscureText: _obscurePassword,
                      suffixIcon: _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      onSuffixTap: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Confirm Password
                    GlassTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: Icons.lock_outlined,
                      obscureText: _obscureConfirm,
                      suffixIcon: _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      onSuffixTap: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Register button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return GradientButton(
                          text: 'Create Account',
                          isLoading: auth.isLoading,
                          onPressed: _handleRegister,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Login link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.mediumGray),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Terms
              Center(
                child: Text(
                  'By signing up, you agree to our Terms of Service\nand Privacy Policy',
                  style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Role Selection Card
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.crimson.withValues(alpha: 0.1)
              : AppColors.charcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.crimson : AppColors.slate,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.crimson : AppColors.graphite,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.mediumGray,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.crimson : AppColors.offWhite,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
