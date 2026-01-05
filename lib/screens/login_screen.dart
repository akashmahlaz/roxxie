import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import 'artist_signup_screen.dart';
import 'venue_signup_screen.dart';

/// 🔐 LOGIN SCREEN
///
/// Clean, light-themed login experience
/// Matches the GigMatch branding

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authProvider = context.read<AuthProvider>();
        final success = await authProvider.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (success) {
          // Navigate based on profile completion
          if (authProvider.isProfileComplete) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Navigate to appropriate profile setup
            if (authProvider.isArtist) {
              Navigator.pushReplacementNamed(context, '/artist-setup');
            } else {
              Navigator.pushReplacementNamed(context, '/venue-setup');
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Login failed'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToSignup() {
    // Navigate back to role selection or show a bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSignupTypeSheet(),
    );
  }

  Widget _buildSignupTypeSheet() {
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.sheetBackground(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTert(brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sign up as...',
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _buildSignupOption(
            icon: Icons.headphones_rounded,
            title: 'Artist / Band',
            subtitle: 'Find gigs & get booked',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArtistSignupScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSignupOption(
            icon: Icons.storefront_rounded,
            title: 'Venue / Host',
            subtitle: 'Book talent for your stage',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VenueSignupScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSignupOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary(brightness).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.crimson, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
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
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSec(brightness),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary(brightness),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.text(brightness),
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Logo
                  Center(child: _buildLogo()),

                  const SizedBox(height: 48),

                  // Title
                  Text(
                    'Welcome back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Log in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Email field
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textTert(brightness),
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Implement forgot password
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Forgot password coming soon!'),
                            backgroundColor: AppColors.crimson,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.crimson,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login button
                  GestureDetector(
                    onTap: _isLoading ? null : _handleLogin,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.crimson, const Color(0xFFB91C1C)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: AppColors.divider(brightness)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: AppColors.textTert(brightness),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: AppColors.divider(brightness)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social login buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          icon: 'G',
                          label: 'Google',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSocialButton(
                          icon: '',
                          label: 'Apple',
                          onTap: () {},
                          isApple: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?  ",
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToSignup,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.crimson,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.crimson, const Color(0xFFB91C1C)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 44),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final brightness = Theme.of(context).brightness;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: AppColors.text(brightness), fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.textTert(brightness),
          fontSize: 16,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.textTert(brightness),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.inputFill(brightness),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.crimson, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isApple = false,
  }) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isApple)
              Icon(Icons.apple, color: AppColors.text(brightness), size: 24)
            else
              Text(
                icon,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(brightness),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
