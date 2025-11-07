import 'package:flutter/material.dart';
import '../../screens/browse/browse_screen.dart';
import '../../screens/my_listings/my_listings_screen.dart';
import '../../screens/chats/chats_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../common/app_bottom_navigation.dart';

/// Main navigation wrapper with persistent bottom navigation
/// 
/// Uses IndexedStack to maintain state across tab switches
class MainNavigation extends StatefulWidget {
  /// Initial tab index to show (defaults to 0 - Home)
  final int initialIndex;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  /// Pages for each navigation tab
  final List<Widget> _pages = const [
    BrowseScreen(),
    MyListingsScreen(),
    ChatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button - go to home if not already there
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

/// Alternative main navigation using PageView for swipe gestures
class MainNavigationWithSwipe extends StatefulWidget {
  /// Initial tab index to show (defaults to 0 - Home)
  final int initialIndex;

  const MainNavigationWithSwipe({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationWithSwipe> createState() =>
      _MainNavigationWithSwipeState();
}

class _MainNavigationWithSwipeState extends State<MainNavigationWithSwipe> {
  late int _currentIndex;
  late PageController _pageController;

  /// Pages for each navigation tab
  final List<Widget> _pages = const [
    BrowseScreen(),
    MyListingsScreen(),
    ChatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button - go to home if not already there
        if (_currentIndex != 0) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _pages,
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

