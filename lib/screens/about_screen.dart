/// ℹ️ GIGMATCH About Screen
/// App information and credits
library;

import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        leading: GlassBackButton(),
        title: Text(
          'About',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.crimson,
                    Colors.purple.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),

            const SizedBox(height: 24),

            // App Name
            const Text(
              'GigMatch',
              style: TextStyle(
                color: AppColors.offWhite,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Where Artists Meet Stages',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 4),

            // Version
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: AppColors.textTert(brightness),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),

            // Description
            Text(
              'GigMatch is the premium platform connecting talented artists with amazing venues. Whether you\'re a musician looking for your next gig or a venue searching for the perfect act, we\'ve got you covered.',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('10K+', 'Artists', brightness),
                _buildStatCard('5K+', 'Venues', brightness),
                _buildStatCard('50K+', 'Matches', brightness),
              ],
            ),

            const SizedBox(height: 32),

            // Features
            _buildFeatureItem(
              'Smart Matching',
              'Our AI-powered algorithm finds the perfect matches',
              Icons.auto_awesome_rounded,
              brightness,
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              'Secure Chat',
              'End-to-end encrypted messaging for privacy',
              Icons.security_rounded,
              brightness,
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              'Easy Booking',
              'Streamlined process from match to gig',
              Icons.event_available_rounded,
              brightness,
            ),

            const SizedBox(height: 32),

            // Social Links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(Icons.public, () {}, brightness),
                const SizedBox(width: 16),
                _buildSocialButton(Icons.facebook, () {}, brightness),
                const SizedBox(width: 16),
                _buildSocialButton(Icons.message, () {}, brightness),
                const SizedBox(width: 16),
                _buildSocialButton(Icons.mail_rounded, () {}, brightness),
              ],
            ),

            const SizedBox(height: 32),

            // Legal
            Text(
              '© 2025 GigMatch Inc. All rights reserved.',
              style: TextStyle(
                color: AppColors.textTert(brightness),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/terms'),
                  child: Text(
                    'Terms',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '•',
                  style: TextStyle(
                    color: AppColors.textTert(brightness),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/privacy'),
                  child: Text(
                    'Privacy',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.crimson,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSec(brightness),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    String title,
    String description,
    IconData icon,
    Brightness brightness,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.crimson,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
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
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textSec(brightness),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    IconData icon,
    VoidCallback onPressed,
    Brightness brightness,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border(brightness),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.text(brightness),
          size: 20,
        ),
      ),
    );
  }
}
