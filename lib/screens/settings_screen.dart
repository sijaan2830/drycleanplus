import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../widgets/bottom_navigation.dart';
import '../utils/route_helpers.dart';
import '../widgets/persistent_footer_app.dart';
import '../services/auth_service.dart';
import '../utils/guest_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 3;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;
  final AuthService _authService = AuthService();

  Future<void> _signOut() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.signOut();
      await GuestHelper.setGuestStatus(false);
      
      // Navigate to onboarding screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding',
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Delete user from Firebase
        if (_authService.currentUser != null) {
          await _authService.currentUser!.delete();
        }
        await _authService.signOut();
        await GuestHelper.setGuestStatus(false);
        
        // Navigate to onboarding screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/onboarding',
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 30),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/more');
            }
          },
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Account Settings
            _buildSectionHeader('Account Settings'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlueDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.person,
                    title: 'Personal Information',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.location_on,
                    title: 'Delivery Addresses',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.payment,
                    title: 'Payment Methods',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.lock,
                    title: 'Privacy & Security',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Settings
            _buildSectionHeader('App Settings'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlueDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildSwitchItem(
                    icon: Icons.notifications,
                    title: 'Push Notifications',
                    subtitle: 'Receive updates about your orders',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  _buildSwitchItem(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme across the app',
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                  ),
                  _buildSwitchItem(
                    icon: Icons.location_on,
                    title: 'Location Services',
                    subtitle: 'Allow app to access your location',
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationEnabled = value;
                      });
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Support
            _buildSectionHeader('Support'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlueDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.help,
                    title: 'Help Center',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.chat,
                    title: 'Contact Support',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.rate_review,
                    title: 'Rate App',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.info,
                    title: 'About',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Danger Zone
            _buildSectionHeader('Danger Zone'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlueDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    onTap: _signOut,
                    textColor: Colors.red,
                  ),
                  _buildSettingsItem(
                    icon: Icons.delete,
                    title: 'Delete Account',
                    onTap: _deleteAccount,
                    textColor: Colors.red,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF0066FF),
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor == Colors.red ? Colors.red : AppColors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.white.withOpacity(0.6),
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.white.withOpacity(0.3),
        size: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF0066FF),
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.gold,
      ),
    );
  }
}
