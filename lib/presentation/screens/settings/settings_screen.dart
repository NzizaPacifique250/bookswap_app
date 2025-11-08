import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../auth/welcome_screen.dart';
import 'about_screen.dart';
import 'edit_profile_screen.dart';

/// Settings screen for app preferences and user account
/// 
/// Displays user profile, notification settings, and app information
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationReminders = true;
  bool _emailUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  /// Load user preferences from Firestore
  Future<void> _loadUserPreferences() async {
    // TODO: Load from UserModel when available
    // For now, use default values
    setState(() {
      _notificationReminders = true;
      _emailUpdates = false;
    });
  }

  /// Handle notification reminders toggle
  Future<void> _handleNotificationRemindersToggle(bool value) async {
    setState(() {
      _notificationReminders = value;
    });

    // TODO: Save to Firestore via user repository
    // For now, just show feedback
    SnackbarUtils.showSuccessSnackbar(
      context,
      value 
          ? 'Notification reminders enabled' 
          : 'Notification reminders disabled',
    );
  }

  /// Handle email updates toggle
  Future<void> _handleEmailUpdatesToggle(bool value) async {
    setState(() {
      _emailUpdates = value;
    });

    // TODO: Save to Firestore via user repository
    // For now, just show feedback
    SnackbarUtils.showSuccessSnackbar(
      context,
      value 
          ? 'Email updates enabled' 
          : 'Email updates disabled',
    );
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await ref.read(authNotifierProvider.notifier).signOut();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            'Failed to logout: ${e.toString()}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Column(
      children: [
        AppBar(
          backgroundColor: AppColors.primaryBackground,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: currentUserAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            return _buildSignInPrompt();
          }

          // Get UserModel from Firestore for more complete user info
          final userModelAsync = ref.watch(currentUserModelProvider(currentUser.uid));

          return userModelAsync.when(
            data: (userModel) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile section
                  _buildProfileSection(currentUser, userModel),
                  
                  const SizedBox(height: 24),
                  
                  // Settings section
                  _buildSettingsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Logout button
                  _buildLogoutButton(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
            error: (error, stackTrace) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile section with Firebase User data (fallback)
                  _buildProfileSection(currentUser, null),
                  
                  const SizedBox(height: 24),
                  
                  // Settings section
                  _buildSettingsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Logout button
                  _buildLogoutButton(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading profile',
            style: TextStyle(color: AppColors.error),
          ),
        ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in to view settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an account or sign in to access your profile',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primaryBackground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(dynamic currentUser, dynamic userModel) {
    // Use UserModel displayName if available, otherwise fallback to Firebase User
    final displayName = userModel?.displayName ?? 
                       currentUser.displayName ?? 
                       currentUser.email?.split('@').first ?? 
                       'User';
    
    final email = currentUser.email ?? '';
    
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'U');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.accent,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primaryBackground,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            displayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          // Email
          Text(
            email,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Edit Profile Button
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Notification reminders
          _buildToggleItem(
            label: 'Notification reminders',
            value: _notificationReminders,
            onChanged: _handleNotificationRemindersToggle,
          ),
          
          _buildDivider(),
          
          // Email Updates
          _buildToggleItem(
            label: 'Email Updates',
            value: _emailUpdates,
            onChanged: _handleEmailUpdatesToggle,
          ),
          
          _buildDivider(),
          
          // About
          _buildNavigationItem(
            label: 'About',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withOpacity(0.5),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFF3A3F5C),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

