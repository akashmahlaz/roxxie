/// 👤 ULTRA-PREMIUM PROFILE SCREEN V2 - 2026 DESIGN
/// 
/// Features:
/// ✅ Liquid Glass Profile Card
/// ✅ Animated Background Particles
/// ✅ Holographic Premium Badge
/// ✅ Staggered List Animations
/// ✅ Micro-interactions on Stats
/// ✅ Dynamic Gradient Themes

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';

class ProfileScreenV2 extends StatefulWidget {
  const ProfileScreenV2({super.key});

  @override
  State<ProfileScreenV2> createState() => _ProfileScreenV2State();
}

class _ProfileScreenV2State extends State<ProfileScreenV2> with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _floatController;
  late AnimationController _slideController;
  
  final List<_ProfileParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initParticles();
  }

  void _initAnimations() {
    _particleController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 40)
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4)
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800)
    );
    _slideController.forward();
  }

  void _initParticles() {
    for (int i = 0; i < 25; i++) {
      _particles.add(_ProfileParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.1 + 0.05,
        opacity: _random.nextDouble() * 0.4 + 0.1
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _floatController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              painter: _ProfileParticlePainter(
                particles: _particles,
                progress: _particleController.value,
                color: isDark ? Colors.white : AppColors.crimson,
              ),
              size: Size.infinite,
            ),
          ),

          // Main Content
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.user;
              final isArtist = auth.isArtist;
              
              return SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App Bar
                    _buildSliverAppBar(brightness),

                    // Profile Header Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildGlassProfileCard(
                          context, 
                          user?.name ?? 'User', 
                          user?.profilePhotoUrl ?? '',
                          isArtist ? 'Artist' : 'Venue',
                          brightness
                        ),
                      ),
                    ),

                    // Stats Row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard('4.9', 'Rating', Icons.star_rounded, Colors.amber, brightness, 0)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('128', 'Reviews', Icons.rate_review_rounded, Colors.purple, brightness, 1)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(isArtist ? '15' : '500', isArtist ? 'Gigs' : 'Cap', isArtist ? Icons.music_note_rounded : Icons.people_rounded, AppColors.crimson, brightness, 2)),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Menu Items - wrapped in SliverToBoxAdapter
                    SliverToBoxAdapter(child: _buildMenuItem(context, 'Edit Profile', Icons.edit_rounded, '/edit-profile', brightness, 3)),
                    SliverToBoxAdapter(child: _buildMenuItem(context, 'Wallet', Icons.account_balance_wallet_rounded, '/wallet', brightness, 4)),
                    SliverToBoxAdapter(child: _buildMenuItem(context, 'Settings', Icons.settings_rounded, '/settings', brightness, 5)),
                    SliverToBoxAdapter(child: _buildMenuItem(context, 'Help & Support', Icons.help_outline_rounded, '/support', brightness, 6)),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    
                    // Logout
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextButton(
                          onPressed: () => _showLogoutDialog(context, brightness),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.crimson,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppColors.crimson.withValues(alpha: 0.3)),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded),
                              SizedBox(width: 8),
                              Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 50)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Brightness brightness) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 50,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {}, 
          icon: Icon(Icons.qr_code_rounded, color: AppColors.text(brightness)),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: Icon(Icons.settings_outlined, color: AppColors.text(brightness)),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildGlassProfileCard(BuildContext context, String name, String photo, String role, Brightness brightness) {
     return TweenAnimationBuilder<double>(
       tween: Tween(begin: 0.8, end: 1.0),
       duration: const Duration(milliseconds: 800),
       curve: Curves.easeOutBack,
       builder: (context, value, child) {
         return Transform.scale(scale: value, child: child);
       },
       child: ClipRRect(
         borderRadius: BorderRadius.circular(30),
         child: BackdropFilter(
           filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
           child: Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: AppColors.surface(brightness).withValues(alpha: 0.6),
               borderRadius: BorderRadius.circular(30),
               border: Border.all(color: AppColors.border(brightness).withValues(alpha: 0.3)),
               boxShadow: [
                 BoxShadow(
                   color: AppColors.crimson.withValues(alpha: 0.1),
                   blurRadius: 30,
                   spreadRadius: 0,
                   offset: const Offset(0, 10),
                 ),
               ],
             ),
             child: Column(
               children: [
                 // Avatar with Glow
                 Stack(
                   alignment: Alignment.center,
                   children: [
                     Container(
                       width: 110, height: 110,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         gradient: LinearGradient(
                           colors: [AppColors.crimson, Colors.purple.shade400],
                           begin: Alignment.topLeft, end: Alignment.bottomRight
                         ),
                         boxShadow: [
                            BoxShadow(color: AppColors.crimson.withValues(alpha: 0.4), blurRadius: 20),
                         ]
                       ),
                     ),
                     CircleAvatar(
                       radius: 50,
                       backgroundColor: AppColors.background(brightness),
                       backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                       child: photo.isEmpty ? const Icon(Icons.person, size: 40) : null,
                     ),
                     Positioned(
                       bottom: 0, right: 0,
                       child: Container(
                         padding: const EdgeInsets.all(6),
                         decoration: BoxDecoration(color: AppColors.crimson, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                         child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(brightness))),
                 const SizedBox(height: 4),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                   decoration: BoxDecoration(
                     color: AppColors.text(brightness).withValues(alpha: 0.05),
                     borderRadius: BorderRadius.circular(20)
                   ),
                   child: Text(role.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSec(brightness), letterSpacing: 1.2)),
                 ),
                 const SizedBox(height: 20),
                 ElevatedButton(
                   onPressed: () => Navigator.pushNamed(context, '/premium'),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.transparent,
                     shadowColor: Colors.transparent,
                     padding: EdgeInsets.zero,
                   ),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(colors: [Color(0xFFDAA520), Color(0xFFB8860B)]),
                       borderRadius: BorderRadius.circular(25),
                       boxShadow: [
                         BoxShadow(color: const Color(0xFFDAA520).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                       ],
                     ),
                     child: const Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(Icons.diamond_rounded, color: Colors.white, size: 18),
                         SizedBox(width: 8),
                         Text('Upgrade to Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                 ),
               ],
             ),
           ),
         ),
       ),
     );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, Brightness brightness, int index) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Interval(0.2 + (index * 0.1), 0.8, curve: Curves.easeOutBack))
    );

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(brightness).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(brightness))),
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSec(brightness))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, String route, Brightness brightness, int index) {
      final animation = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Interval(0.4 + (index * 0.1), 1.0, curve: Curves.easeOutCubic))
    );
     final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Interval(0.4 + (index * 0.1), 0.8))
    );

    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) => FadeTransition(
        opacity: opacity,
        child: SlideTransition(position: animation, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface(brightness).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(brightness).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.text(brightness).withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: Icon(icon, color: AppColors.text(brightness), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text(brightness)))),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSec(brightness), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, Brightness brightness) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         backgroundColor: AppColors.surface(brightness),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         title: const Text('Sign Out'),
         content: const Text('Are you sure you want to sign out?'),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: AppColors.textSec(brightness)))),
           TextButton(onPressed: () async {
             Navigator.pop(context);
             await context.read<AuthProvider>().logout();
             Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
           }, child: const Text('Sign Out', style: TextStyle(color: AppColors.crimson, fontWeight: FontWeight.bold))),
         ],
       )
     );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _ProfileParticle {
  double x, y, size, speed, opacity;
  _ProfileParticle({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

class _ProfileParticlePainter extends CustomPainter {
  final List<_ProfileParticle> particles;
  final double progress;
  final Color color;
  _ProfileParticlePainter({required this.particles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - progress * p.speed) % 1.0;
      final x = p.x + math.sin(progress * 2 * math.pi + p.x * 10) * 0.02;
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, Paint()..color = color.withValues(alpha: p.opacity * 0.15)..style = PaintingStyle.fill);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
