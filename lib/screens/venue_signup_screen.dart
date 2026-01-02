import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import 'login_screen.dart';
import 'artist_signup_screen.dart';

/// 🏛️ VENUE SIGNUP SCREEN
///
/// Venue/Host registration flow
/// Fields: Venue name, Location, Email, Password
/// "Let's put you on the map."

class VenueSignupScreen extends StatefulWidget {
  const VenueSignupScreen({super.key});

  @override
  State<VenueSignupScreen> createState() => _VenueSignupScreenState();
}

class _VenueSignupScreenState extends State<VenueSignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGettingLocation = false;

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
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);

      // TODO: Implement actual signup logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Venue signup coming soon!'),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    // Simulate getting location
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Implement actual location fetching
    _locationController.text = 'New York, NY';

    setState(() => _isGettingLocation = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location detection coming soon!'),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Header with back button and logo
                  Row(
                    children: [
                      GestureDetector(
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
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.equalizer_rounded,
                            color: AppColors.crimson,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GigMatch',
                            style: TextStyle(
                              color: AppColors.text(brightness),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 52), // Balance the back button
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Icon
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.crimson, const Color(0xFFB91C1C)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(
                          text: "Let's put you ",
                          style: TextStyle(color: AppColors.text(brightness)),
                        ),
                        TextSpan(
                          text: 'on the map.',
                          style: TextStyle(color: AppColors.crimson),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Create your venue profile to find talented artists',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Venue name field
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Venue Name',
                    prefixIcon: Icons.storefront_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your venue name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // Location field with GPS button
                  Stack(
                    children: [
                      _buildTextField(
                        controller: _locationController,
                        hintText: 'Location',
                        prefixIcon: Icons.location_on_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your location';
                          }
                          return null;
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        bottom: 8,
                        child: GestureDetector(
                          onTap: _isGettingLocation
                              ? null
                              : _getCurrentLocation,
                          child: Container(
                            width: 40,
                            decoration: BoxDecoration(
                              color: AppColors.crimson.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: _isGettingLocation
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: AppColors.crimson,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.my_location_rounded,
                                      color: AppColors.crimson,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

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

                  const SizedBox(height: 14),

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
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Sign up button
                  GestureDetector(
                    onTap: _isLoading ? null : _handleSignup,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.crimson, const Color(0xFFB91C1C)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withOpacity(0.4),
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
                                'Sign Up as Venue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?  ',
                        style: TextStyle(
                          color: AppColors.textSec(brightness),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: AppColors.crimson,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Switch to artist
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary(
                        brightness,
                      ).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border(brightness)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.iconSecondary(
                              brightness,
                            ).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.headphones_rounded,
                            color: AppColors.icon(brightness),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Looking for gigs instead?',
                                style: TextStyle(
                                  color: AppColors.textSec(brightness),
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ArtistSignupScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign up as a Musician',
                                  style: TextStyle(
                                    color: AppColors.crimson,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTert(brightness),
                          size: 16,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms
                  Text(
                    'By signing up, you agree to our Terms of Service\nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textTert(brightness),
                      fontSize: 12,
                      height: 1.5,
                    ),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.crimson, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        errorStyle: TextStyle(color: Colors.red.shade300, fontSize: 12),
      ),
    );
  }
}
