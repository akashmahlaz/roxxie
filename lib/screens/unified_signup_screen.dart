/// 🚀 UNIFIED SIGNUP SCREEN V3 - MODERN UX
///
/// Key Improvements:
/// ✅ Role selection integrated (no separate screen)
/// ✅ Social authentication buttons (Google, Apple)
/// ✅ Smart location detection
/// ✅ Live password validation
/// ✅ Reduced form fields (essential only)
/// ✅ No confirm password (uses show/hide toggle)
/// ✅ Mobile-first design
/// ✅ Autofill support
/// ✅ Progressive profiling (collect details later)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../widgets/widgets.dart';
import 'artist/artist_profile_setup_screen.dart';
import 'venue/venue_profile_setup_screen.dart';
import 'login_screen.dart';

class UnifiedSignupScreen extends StatefulWidget {
  const UnifiedSignupScreen({super.key});

  @override
  State<UnifiedSignupScreen> createState() => _UnifiedSignupScreenState();
}

class _UnifiedSignupScreenState extends State<UnifiedSignupScreen>
    with SingleTickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════
  // FORM CONTROLLERS - MINIMAL ESSENTIAL FIELDS ONLY
  // ═══════════════════════════════════════════════════════════════════════
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ═══════════════════════════════════════════════════════════════════════
  // STATE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════
  UserRole? _selectedRole;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // Location state
  String? _city;
  String? _country;
  double? _latitude;
  double? _longitude;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SIGNUP HANDLER - WITH SOCIAL AUTH SUPPORT
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _handleSignup() async {
    if (_isLoading) return;

    // Validate role selection
    if (_selectedRole == null) {
      _showError('Please select if you\'re an Artist or Venue');
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate terms
    if (!_acceptTerms) {
      _showError('Please accept the Terms & Conditions');
      return;
    }

    // Validate location
    if (_city == null || _city!.isEmpty) {
      _showError('Please provide your location');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.register(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole!,
        city: _city,
        country: _country,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;

      if (success) {
        _showSuccess('Account created successfully!');

        // Navigate to appropriate profile setup
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _selectedRole == UserRole.artist
                ? const ArtistProfileSetupScreen()
                : const VenueProfileSetupScreen(),
          ),
        );
      } else {
        throw Exception(authProvider.errorMessage ?? 'Registration failed');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SOCIAL AUTHENTICATION HANDLERS (TODO: Implement)
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _handleGoogleSignIn() async {
    _showError('Google Sign-In coming soon!');
    // TODO: Implement Google Sign-In
    // final authProvider = context.read<AuthProvider>();
    // await authProvider.signInWithGoogle();
  }

  Future<void> _handleAppleSignIn() async {
    _showError('Apple Sign-In coming soon!');
    // TODO: Implement Apple Sign-In
    // final authProvider = context.read<AuthProvider>();
    // await authProvider.signInWithApple();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.text(brightness),
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),

                  const SizedBox(height: 8),

                  // Header
                  Text(
                    'Create Account',
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Join thousands of artists and venues',
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ═══════════════════════════════════════════════════
                  // SOCIAL AUTHENTICATION
                  // ═══════════════════════════════════════════════════
                  _buildSocialButtons(brightness),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: AppColors.border(brightness)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with email',
                          style: TextStyle(
                            color: AppColors.textSec(brightness),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: AppColors.border(brightness)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════
                  // ROLE SELECTION (INTEGRATED)
                  // ═══════════════════════════════════════════════════
                  _buildRoleSelector(brightness),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════════════
                  // ESSENTIAL FORM FIELDS
                  // ═══════════════════════════════════════════════════

                  // Name
                  _buildTextField(
                    controller: _nameController,
                    label: _selectedRole == UserRole.venue
                        ? 'Venue Name'
                        : 'Your Name',
                    hint: _selectedRole == UserRole.venue
                        ? 'e.g., The Blue Note Jazz Club'
                        : 'e.g., Sarah Johnson',
                    icon: _selectedRole == UserRole.venue
                        ? Icons.storefront_rounded
                        : Icons.person_outline_rounded,
                    brightness: brightness,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    autofillHints: [AutofillHints.name],
                  ),

                  const SizedBox(height: 16),

                  // Email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'your@email.com',
                    icon: Icons.email_outlined,
                    brightness: brightness,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    autofillHints: [AutofillHints.email],
                  ),

                  const SizedBox(height: 16),

                  // Location (Smart Picker)
                  SmartLocationPicker(
                    autoDetect: true,
                    onLocationSelected: (city, country, lat, lng) {
                      setState(() {
                        _city = city;
                        _country = country;
                        _latitude = lat;
                        _longitude = lng;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password
                  _buildPasswordField(brightness),

                  const SizedBox(height: 12),

                  // Password strength indicator
                  PasswordStrengthIndicator(
                    password: _passwordController.text,
                    showRequirements: _passwordController.text.isNotEmpty,
                  ),

                  const SizedBox(height: 20),

                  // Terms & Conditions
                  _buildTermsCheckbox(brightness),

                  const SizedBox(height: 24),

                  // Create Account Button
                  _buildSignupButton(brightness),

                  const SizedBox(height: 20),

                  // Login link
                  _buildLoginLink(brightness),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons(Brightness brightness) {
    return Column(
      children: [
        // Google Sign-In
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: Image.asset(
              'assets/images/google_logo.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.g_mobiledata_rounded,
                size: 28,
                color: AppColors.text(brightness),
              ),
            ),
            label: Text(
              'Continue with Google',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border(brightness)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Apple Sign-In
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleAppleSignIn,
            icon: Icon(
              Icons.apple_rounded,
              color: AppColors.text(brightness),
              size: 24,
            ),
            label: Text(
              'Continue with Apple',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border(brightness)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I\'m signing up as:',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: UserRole.artist,
                icon: Icons.music_note_rounded,
                label: 'Artist/Band',
                isSelected: _selectedRole == UserRole.artist,
                brightness: brightness,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                role: UserRole.venue,
                icon: Icons.stadium_rounded,
                label: 'Venue/Organizer',
                isSelected: _selectedRole == UserRole.venue,
                brightness: brightness,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Brightness brightness,
  }) {
    final color = role == UserRole.artist ? AppColors.crimson : AppColors.cyan;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border(brightness),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSec(brightness),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? color : AppColors.text(brightness),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Brightness brightness,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<String>? autofillHints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          style: TextStyle(color: AppColors.text(brightness), fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTert(brightness)),
            prefixIcon: Icon(icon, color: AppColors.crimson, size: 20),
            filled: true,
            fillColor: AppColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(brightness)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(brightness)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.crimson, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autofillHints: [AutofillHints.newPassword],
          onChanged: (value) {
            setState(() {}); // Rebuild password strength indicator
          },
          style: TextStyle(color: AppColors.text(brightness), fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Create a strong password',
            hintStyle: TextStyle(color: AppColors.textTert(brightness)),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.crimson,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textTert(brightness),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: AppColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(brightness)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(brightness)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.crimson, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(Brightness brightness) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _acceptTerms ? AppColors.crimson : Colors.transparent,
              border: Border.all(
                color: _acceptTerms
                    ? AppColors.crimson
                    : AppColors.border(brightness),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: _acceptTerms
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton(Brightness brightness) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.crimson.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink(Brightness brightness) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        ),
        child: Text.rich(
          TextSpan(
            text: 'Already have an account? ',
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: 'Log In',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
