import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable bottom navigation bar matching all screenshots
/// 
/// Provides consistent navigation across the app with 4 main sections:
/// - Feed/Home
/// - My Listings
/// - Chats
/// - Settings/Profile
class AppBottomNavigation extends StatelessWidget {
  /// Current selected tab index (0-3)
  final int currentIndex;
  
  /// Callback when a tab is tapped
  final ValueChanged<int> onTap;
  
  /// Optional custom labels (defaults to standard labels)
  final List<String>? customLabels;
  
  /// Optional custom icons (defaults to standard icons)
  final List<IconData>? customIcons;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.customLabels,
    this.customIcons,
  });

  /// Default labels for navigation items
  static const List<String> defaultLabels = [
    'Home',
    'My listings',
    'Chats',
    'Profile',
  ];

  /// Default icons for navigation items
  static const List<IconData> defaultIcons = [
    Icons.home,
    Icons.book,
    Icons.chat_bubble,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final labels = customLabels ?? defaultLabels;
    final icons = customIcons ?? defaultIcons;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: BottomNavigationBar(
            backgroundColor: AppColors.primaryBackground,
            selectedItemColor: AppColors.bottomNavActive,
            unselectedItemColor: AppColors.bottomNavInactive,
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            selectedIconTheme: const IconThemeData(
              size: 28,
            ),
            unselectedIconTheme: const IconThemeData(
              size: 24,
            ),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: List.generate(
              4,
              (index) => BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(icons[index]),
                ),
                label: labels[index],
              ),
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

/// Navigation bar item data class
class NavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;

  const NavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
  });
}

/// Pre-defined navigation configurations
class AppNavConfig {
  /// Standard 4-tab navigation (Home, My Listings, Chats, Profile)
  static const standard = [
    NavItem(label: 'Home', icon: Icons.home),
    NavItem(label: 'My listings', icon: Icons.book),
    NavItem(label: 'Chats', icon: Icons.chat_bubble),
    NavItem(label: 'Profile', icon: Icons.person),
  ];

  /// Alternative 4-tab navigation with different icons
  static const alternative = [
    NavItem(label: 'Feed', icon: Icons.feed),
    NavItem(label: 'My listings', icon: Icons.library_books),
    NavItem(label: 'Chats', icon: Icons.chat),
    NavItem(label: 'Settings', icon: Icons.settings),
  ];

  /// 3-tab navigation (used in some screens)
  static const compact = [
    NavItem(label: 'Home', icon: Icons.home),
    NavItem(label: 'My listings', icon: Icons.book),
    NavItem(label: 'Chats', icon: Icons.chat_bubble),
  ];
}

