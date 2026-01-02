import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedGenre;

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
    _fadeController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGenre == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select your main genre'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);

      // TODO: Implement actual signup logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Artist signup coming soon!'),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                            ? AppColors.crimson.withOpacity(0.2)
                            : AppColors.surfaceSecondary(
                                brightness,
                              ).withOpacity(0.5),
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
                            color: AppColors.crimson.withOpacity(0.4),
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

                  const SizedBox(height: 14),

                  // Genre selector
                  GestureDetector(
                    onTap: _showGenrePicker,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill(brightness),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(brightness)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            color: AppColors.textTert(brightness),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedGenre ?? 'Main Genre',
                            style: TextStyle(
                              color: _selectedGenre != null
                                  ? AppColors.text(brightness)
                                  : AppColors.textTert(brightness),
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textTert(brightness),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
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
                        borderRadius: BorderRadius.circular(28),
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
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.border(brightness)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.crimson, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
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
              ? const Color(0xFF1DB954).withOpacity(0.15)
              : AppColors.surfaceSecondary(brightness).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSpotify
                ? const Color(0xFF1DB954).withOpacity(0.4)
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
