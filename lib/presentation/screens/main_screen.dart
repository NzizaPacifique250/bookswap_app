import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/common/app_bottom_navigation.dart';
import '../providers/auth_provider.dart';
import 'browse/browse_screen.dart';
import 'my_listings/my_listings_screen.dart';
import 'chats/chats_screen.dart';
import 'settings/settings_screen.dart';
import 'auth/welcome_screen.dart';

/// Main screen managing bottom navigation and screen state
/// 
/// Holds 4 main screens with persistent state using IndexedStack:
/// - Browse Listings (Home)
/// - My Listings
/// - Chats
/// - Settings (Profile)
class MainScreen extends ConsumerStatefulWidget {
  /// Initial tab index to show (defaults to 0 - Browse)
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex;

  /// Pages for each navigation tab
  /// Using const constructors to prevent unnecessary rebuilds
  final List<Widget> _screens = const [
    BrowseScreen(),       // Index 0: Home
    MyListingsScreen(),   // Index 1: My Listings
    ChatsScreen(),        // Index 2: Chats
    SettingsScreen(),     // Index 3: Profile/Settings
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupAuthListener();
  }

  /// Listen to auth state and redirect to welcome if logged out
  void _setupAuthListener() {
    ref.listenManual(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user == null && mounted) {
          // User logged out, redirect to welcome screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            ),
            (route) => false,
          );
        }
      });
    });
  }

  /// Handle tab tap
  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    // If on home tab, show exit dialog
    if (_currentIndex == 0) {
      final shouldExit = await _showExitDialog();
      return shouldExit ?? false;
    }

    // Otherwise, navigate to home tab
    setState(() {
      _currentIndex = 0;
    });
    return false;
  }

  /// Show exit app confirmation dialog
  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Exit App',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit BookSwap?',
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
            onPressed: () {
              Navigator.of(context).pop(true);
              SystemNavigator.pop(); // Exit app
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryBackground,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

