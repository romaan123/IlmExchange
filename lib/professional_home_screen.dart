import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'professional_marketplace_screen.dart';
import 'post_offer_request_screen.dart';
import 'contacts_screen.dart';
import 'notifications_screen.dart';
import 'sessions_screen.dart';
import 'user_profile_screen.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      label: 'Marketplace',
      title: 'Skill Marketplace',
    ),
    NavigationItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Post', title: 'Post Skills'),
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Messages',
      title: 'Messages',
    ),
    NavigationItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      label: 'Notifications',
      title: 'Notifications',
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Sessions',
      title: 'My Sessions',
    ),
    NavigationItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', title: 'Profile'),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      const ProfessionalMarketplaceScreen(),
      const PostOfferRequestScreen(),
      const ContactsScreen(),
      const NotificationsScreen(),
      const SessionsScreen(),
      const UserProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 1200;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // Sidebar
          if (isWideScreen)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSidebarExpanded ? 280 : 80,
              child: _buildSidebar(),
            ),

          // Main content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: IndexedStack(index: _selectedIndex, children: _screens),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom navigation for mobile
      bottomNavigationBar: !isWideScreen ? _buildBottomNavigation() : null,
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Logo section
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'IlmExchange',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) => _buildNavigationItem(index),
            ),
          ),

          const Divider(height: 1),

          // User section
          _buildUserSection(),

          // Collapse button
          Container(
            padding: const EdgeInsets.all(16),
            child: IconButton(
              onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
              icon: Icon(_isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(int index) {
    final item = _navigationItems[index];
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.lightGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                  size: 24,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryGreen,
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isSidebarExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Online', style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen)),
                ],
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [Icon(Icons.logout, size: 20), SizedBox(width: 12), Text('Logout')]),
                    ),
                  ],
              onSelected: (value) {
                if (value == 'logout') {
                  _handleLogout();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Page title
          Text(
            _navigationItems[_selectedIndex].title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),

          const Spacer(),

          // Search button
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppTheme.textSecondary),
            tooltip: 'Search',
          ),

          const SizedBox(width: 8),

          // Notifications button
          Stack(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedIndex = 3),
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
                tooltip: 'Notifications',
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppTheme.errorRed, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items:
            _navigationItems
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    activeIcon: Icon(item.activeIcon),
                    label: item.label,
                  ),
                )
                .toList(),
      ),
    );
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  navigator.pop(); // Close dialog first
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    navigator.pushReplacementNamed('/login');
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String title;

  NavigationItem({required this.icon, required this.activeIcon, required this.label, required this.title});
}
