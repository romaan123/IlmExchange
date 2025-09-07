import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your existing screens
import 'skill_marketplace_screen.dart';
import 'post_offer_request_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'user_profile_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _bottomNavController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Enhanced screen configuration with icons and actions
  static const List<Map<String, dynamic>> _screenConfig = [
    {
      'title': 'Skill Marketplace',
      'icon': Icons.storefront_outlined,
      'activeIcon': Icons.storefront,
      'hasSearch': true,
      'hasFilter': true,
      'label': 'Marketplace',
    },
    {
      'title': 'Post Offer',
      'icon': Icons.add_circle_outline,
      'activeIcon': Icons.add_circle,
      'hasSearch': false,
      'hasFilter': false,
      'label': 'Post',
    },
    {
      'title': 'Messages',
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble,
      'hasSearch': true,
      'hasFilter': false,
      'label': 'Chat',
    },
    {
      'title': 'Notifications',
      'icon': Icons.notifications_outlined,
      'activeIcon': Icons.notifications,
      'hasSearch': false,
      'hasFilter': true,
      'label': 'Notifications',
    },
    {
      'title': 'Profile',
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'hasSearch': false,
      'hasFilter': false,
      'label': 'Profile',
    },
  ];

  // Screen instances with state preservation
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeScreens();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _bottomNavController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
    _bottomNavController.forward();
  }

  void _initializeScreens() {
    _screens = [
      const SkillMarketplaceScreen(),
      const PostOfferRequestScreen(),
      const ChatScreen(contactName: "Messages", contactId: "demo_contact"),
      NotificationsScreen(),
      const UserProfileScreen(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _bottomNavController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _animationController.forward();
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    // Add haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _selectedIndex = index;
    });

    // Trigger animations
    _animationController.reset();
    _animationController.forward();
  }

  // Action handlers
  void _handleSearch() {
    _showSnackbar('Search functionality coming soon!');
  }

  void _handleFilter() {
    _showSnackbar('Filter functionality coming soon!');
  }

  void _handleLogout() async {
    final shouldLogout = await _showLogoutDialog();
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentConfig = _screenConfig[_selectedIndex];

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _selectedIndex != 0) {
          _onItemTapped(0);
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
        appBar: _buildAppBar(context, currentConfig, isDarkMode),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavigationBar(isDarkMode),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Map<String, dynamic> config, bool isDarkMode) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: Text(
          config['title'],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      centerTitle: true,
      actions: _buildAppBarActions(config),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600]),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(Map<String, dynamic> config) {
    List<Widget> actions = [];

    if (config['hasSearch'] == true) {
      actions.add(IconButton(icon: const Icon(Icons.search_rounded), onPressed: _handleSearch, tooltip: 'Search'));
    }

    if (config['hasFilter'] == true) {
      actions.add(IconButton(icon: const Icon(Icons.tune_rounded), onPressed: _handleFilter, tooltip: 'Filter'));
    }

    // Add logout for profile tab (removed settings button as requested)
    if (_selectedIndex == 4) {
      actions.add(IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _handleLogout, tooltip: 'Logout'));
    }

    return actions;
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(scale: _scaleAnimation, child: IndexedStack(index: _selectedIndex, children: _screens)),
    );
  }

  Widget _buildBottomNavigationBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_screenConfig.length, (index) => _buildNavItem(index, isDarkMode)),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDarkMode) {
    final config = _screenConfig[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? config['activeIcon'] : config['icon'],
                key: ValueKey('$index-$isSelected'),
                color: isSelected ? Colors.deepPurple : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.deepPurple : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              child: Text(config['label'], maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
