import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../core/models/models.dart';
import '../core/services/services.dart';
import 'login_screen.dart';

/// 🎸 ARTIST SIGNUP SCREEN
///
/// Artist/Band registration flow
/// Fields: Band name, Genre, Email, Password
/// Social login options

class ArtistSignupScreen extends StatefulWidget {
  const ArtistSignupScreen({super.key});

  @override
  State<ArtistSignupScreen> createState() => _ArtistSignupScreenState();
}

class _ArtistSignupScreenState extends State<ArtistSignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _genreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String? _selectedGenre;
  double? _latitude;
  double? _longitude;

  late AnimationController _fadeController;

  final List<String> _genres = [
    'Rock',
    'Pop',
    'Jazz',
    'Hip-Hop',
    'Electronic',
    'R&B',
    'Country',
    'Classical',
    'Folk',
    'Metal',
    'Indie',
    'Blues',
    'Reggae',
    'Latin',
    'Soul',
    'Funk',
    'Other',
  ];

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
    _genreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    // Capture ScaffoldMessenger before async gap
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Get actual location using location service
      final locationResult = await _locationService.getCurrentLocationWithAddress();

      if (locationResult != null) {
        setState(() {
          _cityController.text = locationResult.city ?? '';
          _countryController.text = locationResult.country ?? '';
          _latitude = locationResult.latitude;
          _longitude = locationResult.longitude;
        });

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Location detected!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Permission denied or location unavailable
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Could not get location. Please enable location services.',
            ),
            backgroundColor: AppColors.crimson,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => _locationService.openLocationSettings(),
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      // Genre selection removed - will be collected during profile setup

      setState(() => _isLoading = true);

      try {
        final authProvider = context.read<AuthProvider>();
        final success = await authProvider.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: UserRole.artist,
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );

        if (!mounted) return;

        if (success) {
          // Navigate to artist profile setup
          Navigator.pushReplacementNamed(context, '/artist-setup');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Registration failed'),
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

  void _showGenrePicker() {
    final brightness = Theme.of(context).brightness;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: AppColors.sheetBackground(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTert(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Your Genre',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _genres.length,
                itemBuilder: (context, index) {
                  final genre = _genres[index];
                  final isSelected = genre == _selectedGenre;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedGenre = genre);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.crimson.withValues(alpha: 0.2)
                            : AppColors.surfaceSecondary(
                                brightness,
                              ).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.crimson
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            genre,
                            style: TextStyle(
                              color: AppColors.text(brightness),
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
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
                },
              ),
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
                            color: AppColors.crimson.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.headphones_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Create Artist Profile',
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
                    'Get discovered by venues looking for talent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Band/Artist name field
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Band / Artist Name',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name or band name';
                      }
                      return null;
                    },
                  ),

                  // Genre selector removed - will be collected during profile setup
                  // const SizedBox(height: 14),

                  // Location section with GPS button
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          hintText: 'City (optional)',
                          prefixIcon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isGettingLocation ? null : _getCurrentLocation,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.crimson.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.crimson.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: _isGettingLocation
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.crimson,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.my_location_rounded,
                                        color: AppColors.crimson,
                                        size: 20,
                                      ),
                                      Text(
                                        'GPS',
                                        style: TextStyle(
                                          color: AppColors.crimson,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Country field
                  _buildTextField(
                    controller: _countryController,
                    hintText: 'Country (optional)',
                    prefixIcon: Icons.public_outlined,
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
                      // Check for uppercase
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Password must contain at least one uppercase letter';
                      }
                      // Check for lowercase
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Password must contain at least one lowercase letter';
                      }
                      // Check for number
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Password must contain at least one number';
                      }
                      // Check for special character
                      if (!value.contains(RegExp(r'[@$!%*?&]'))) {
                        return 'Password must contain a special character (@\$!%*?&)';
                      }
                      return null;
                    },
                  ),

                  // Password hint
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Min 8 chars: uppercase, lowercase, number & special (@\$!%*?&)',
                      style: TextStyle(
                        color: AppColors.textTert(brightness),
                        fontSize: 11,
                      ),
                    ),
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
                                'Sign Up & Start Booking',
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

                  const SizedBox(height: 28),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.divider(brightness),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or sign up with',
                          style: TextStyle(
                            color: AppColors.textTert(brightness),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.divider(brightness),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: _buildSocialButton(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Google',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildSocialButton(
                          icon: Icons.apple,
                          label: 'Apple',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildSocialButton(
                          icon: Icons.music_note,
                          label: 'Spotify',
                          onTap: () {},
                          isSpotify: true,
                        ),
                      ),
                    ],
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
                          'Log in',
                          style: TextStyle(
                            color: AppColors.crimson,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSpotify = false,
  }) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSpotify
              ? const Color(0xFF1DB954).withValues(alpha: 0.15)
              : AppColors.surfaceSecondary(brightness).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSpotify
                ? const Color(0xFF1DB954).withValues(alpha: 0.4)
                : AppColors.border(brightness),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSpotify
                  ? const Color(0xFF1DB954)
                  : AppColors.text(brightness),
              size: 20,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSpotify
                      ? const Color(0xFF1DB954)
                      : AppColors.text(brightness),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
