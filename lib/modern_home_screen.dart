import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import your existing screens
import 'comprehensive_skill_marketplace_screen.dart';
import 'post_offer_request_screen.dart';
import 'contacts_screen.dart';
import 'notifications_screen.dart';
import 'sessions_screen.dart';
import 'user_profile_screen.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Tab configuration exactly as requested
  static const List<Map<String, dynamic>> _tabConfig = [
    {'title': 'Skill Marketplace', 'icon': Icons.search, 'label': 'Marketplace'},
    {'title': 'Post Offer', 'icon': Icons.add_box, 'label': 'Post'},
    {'title': 'Messages', 'icon': Icons.chat_bubble, 'label': 'Chat'},
    {'title': 'Notifications', 'icon': Icons.notifications, 'label': 'Notifications'},
    {'title': 'My Sessions', 'icon': Icons.calendar_today, 'label': 'Sessions'},
    {'title': 'Profile', 'icon': Icons.person, 'label': 'Profile'},
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  void _initializeScreens() {
    _screens = [
      const ComprehensiveSkillMarketplaceScreen(),
      const PostOfferRequestScreen(),
      const ContactsScreen(),
      NotificationsScreen(),
      const SessionsScreen(),
      const UserProfileScreen(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _animationController.forward();
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // Double-tap to scroll to top (bonus feature)
      _scrollToTop();
      return;
    }

    // Add haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _selectedIndex = index;
    });

    // Trigger smooth animations
    _animationController.reset();
    _animationController.forward();
  }

  void _scrollToTop() {
    // Bonus feature: Double-tap to scroll to top
    // This would be implemented in individual screens
    HapticFeedback.mediumImpact();
  }

  // Handle back button behavior
  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      // Navigate to marketplace tab instead of exiting
      _onItemTapped(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentTab = _tabConfig[_selectedIndex];

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
        appBar: _buildAppBar(currentTab, isDarkMode),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavigationBar(isDarkMode),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> currentTab, bool isDarkMode) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: Text(
          currentTab['title'],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      centerTitle: true,
      actions: _buildAppBarActions(),
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

  List<Widget> _buildAppBarActions() {
    List<Widget> actions = [];

    // Context-aware actions based on selected tab
    switch (_selectedIndex) {
      case 0: // Marketplace
        actions.addAll([
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSnackbar('Search functionality'),
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showSnackbar('Filter functionality'),
            tooltip: 'Filter',
          ),
        ]);
        break;
      case 2: // Chat
        actions.add(
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSnackbar('Search chats'),
            tooltip: 'Search Chats',
          ),
        );
        break;
      case 3: // Notifications
        actions.add(
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            onPressed: () => _showSnackbar('Clear all notifications'),
            tooltip: 'Clear All',
          ),
        );
        break;
      case 4: // Profile
        // Removed settings button as requested
        break;
    }

    return actions;
  }

  Widget _buildBody() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabConfig.length, (index) => _buildNavItem(index, isDarkMode)),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDarkMode) {
    final config = _tabConfig[index];
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        onLongPress: () => _showTooltip(config['label']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isSelected ? 3 : 0),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  config['icon'],
                  color: isSelected ? Colors.deepPurple : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                  size: isSelected ? 24 : 22,
                ),
              ),

              const SizedBox(height: 1),

              // Label with animation
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.deepPurple : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                  child: Text(
                    config['label'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTooltip(String label) {
    // Long-press tooltip (bonus feature)
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
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
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
