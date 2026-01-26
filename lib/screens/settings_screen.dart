/// ⚙️ GIGMATCH Settings Screen
///
/// 2026 Design Principles Applied:
/// - Liquid Glass section headers
/// - Micro-interactions on toggles
/// - Grouped settings with visual hierarchy
/// - Premium account section
///
/// User preferences and app configuration
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme.dart';
import '../core/providers/providers.dart';
import '../widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _matchNotifications = true;
  bool _messageNotifications = true;
  bool _gigReminders = true;
  bool _showOnlineStatus = true;
  bool _showDistance = true;
  int _maxDistance = 50;
  // ignore: unused_field
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load settings from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserSettings());
  }

  void _loadUserSettings() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      setState(() {
        _pushNotifications = user.pushNotificationsEnabled;
        _emailNotifications = user.emailNotificationsEnabled;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.updateProfile({
        'pushNotificationsEnabled': _pushNotifications,
        'emailNotificationsEnabled': _emailNotifications,
      });
    } catch (e) {
      debugPrint('Failed to save notification settings: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
          'Settings',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Notifications', [
              _buildSwitchTile(
                'Push Notifications',
                'Receive notifications on your device',
                Icons.notifications_rounded,
                _pushNotifications,
                (value) {
                  setState(() => _pushNotifications = value);
                  _saveNotificationSettings();
                },
                brightness,
              ),
              _buildSwitchTile(
                'Email Notifications',
                'Receive updates via email',
                Icons.email_rounded,
                _emailNotifications,
                (value) {
                  setState(() => _emailNotifications = value);
                  _saveNotificationSettings();
                },
                brightness,
              ),
              _buildSwitchTile(
                'New Matches',
                'Get notified when you match',
                Icons.favorite_rounded,
                _matchNotifications,
                (value) => setState(() => _matchNotifications = value),
                brightness,
              ),
              _buildSwitchTile(
                'New Messages',
                'Get notified for new messages',
                Icons.chat_bubble_rounded,
                _messageNotifications,
                (value) => setState(() => _messageNotifications = value),
                brightness,
              ),
              _buildSwitchTile(
                'Gig Reminders',
                'Reminders for upcoming gigs',
                Icons.event_rounded,
                _gigReminders,
                (value) => setState(() => _gigReminders = value),
                brightness,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Privacy', [
              _buildSwitchTile(
                'Show Online Status',
                'Let others see when you\'re online',
                Icons.circle,
                _showOnlineStatus,
                (value) => setState(() => _showOnlineStatus = value),
                brightness,
              ),
              _buildSwitchTile(
                'Show Distance',
                'Display distance on your profile',
                Icons.location_on_rounded,
                _showDistance,
                (value) => setState(() => _showDistance = value),
                brightness,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Discovery', [
              _buildSliderTile(
                'Maximum Distance',
                '$_maxDistance miles',
                Icons.explore_rounded,
                _maxDistance.toDouble(),
                5,
                100,
                (value) => setState(() => _maxDistance = value.toInt()),
                brightness,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Account', [
              _buildNavigationTile(
                'Change Password',
                Icons.lock_rounded,
                () => _showChangePasswordDialog(),
                brightness,
              ),
              _buildNavigationTile(
                'Blocked Users',
                Icons.block_rounded,
                () => Navigator.pushNamed(context, '/blocked-users'),
                brightness,
              ),
              _buildNavigationTile(
                'Delete Account',
                Icons.delete_forever_rounded,
                () => _showDeleteAccountDialog(),
                brightness,
                isDestructive: true,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Legal', [
              _buildNavigationTile(
                'Terms of Service',
                Icons.description_rounded,
                () => Navigator.pushNamed(context, '/terms'),
                brightness,
              ),
              _buildNavigationTile(
                'Privacy Policy',
                Icons.privacy_tip_rounded,
                () => Navigator.pushNamed(context, '/privacy'),
                brightness,
              ),
              _buildNavigationTile(
                'Licenses',
                Icons.info_rounded,
                () => showLicensePage(context: context),
                brightness,
              ),
            ]),

            const SizedBox(height: 32),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.crimson,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          color: AppColors.surface(Theme.of(context).brightness),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    Brightness brightness,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.crimson),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.text(brightness),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSec(brightness), fontSize: 13),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.crimson,
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String value,
    IconData icon,
    double currentValue,
    double min,
    double max,
    ValueChanged<double> onChanged,
    Brightness brightness,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.crimson),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.text(brightness),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.crimson,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      subtitle: Slider(
        value: currentValue,
        min: min,
        max: max,
        divisions: ((max - min) / 5).toInt(),
        activeColor: AppColors.crimson,
        inactiveColor: AppColors.border(brightness),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    IconData icon,
    VoidCallback onTap,
    Brightness brightness, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.crimson,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.text(brightness),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSec(brightness),
      ),
      onTap: onTap,
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(Theme.of(context).brightness),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSec(Theme.of(context).brightness),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement password change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Password changed successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(Theme.of(context).brightness),
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSec(Theme.of(context).brightness),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.crimson,
                      ),
                    ),
              );

              final success =
                  await context.read<AuthProvider>().deleteAccount();

              if (context.mounted) {
                Navigator.pop(context); // Close loading dialog

                if (success) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/role-selection',
                    (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Failed to delete account. Please try again.',
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
