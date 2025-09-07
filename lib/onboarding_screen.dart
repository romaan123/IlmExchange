import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data model for onboarding pages
class OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Welcome to IlmExchange",
      subtitle: "Connect with learners and teachers worldwide.\nShare knowledge, grow together!",
      icon: Icons.school_outlined,
      color: const Color(0xFF6366F1),
      description: "Join a community where everyone teaches and everyone learns.",
    ),
    OnboardingPageData(
      title: "Share Your Skills",
      subtitle: "Post what you can teach or what you want to learn.\nFind the perfect skill match!",
      icon: Icons.lightbulb_outline,
      color: const Color(0xFF8B5CF6),
      description: "Turn your expertise into opportunities to help others grow.",
    ),
    OnboardingPageData(
      title: "Connect & Learn",
      subtitle: "Chat with skill partners and start learning.\nBuild meaningful connections!",
      icon: Icons.people_outline,
      color: const Color(0xFF06B6D4),
      description: "Real conversations lead to real learning experiences.",
    ),
    OnboardingPageData(
      title: "Start Your Journey",
      subtitle: "Ready to exchange knowledge and grow?\nLet's begin your learning adventure!",
      icon: Icons.rocket_launch_outlined,
      color: const Color(0xFF10B981),
      description: "Your next skill is just a conversation away.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  void _resetAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _startAnimations();
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      _resetAnimations();
    } else {
      _goToLogin();
    }
  }

  Future<void> _goToLogin() async {
    // Mark onboarding as seen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildPageContent(OnboardingPageData pageData) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenSize.height * 0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top spacer
                  SizedBox(height: screenSize.height * 0.03),

                  // Animated Icon Container
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Container(
                          width: screenSize.width * 0.25,
                          height: screenSize.width * 0.25,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [pageData.color.withValues(alpha: 0.2), pageData.color.withValues(alpha: 0.1)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: pageData.color.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(pageData.icon, size: screenSize.width * 0.1, color: pageData.color),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenSize.height * 0.03),

                  // Title
                  Text(
                    pageData.title,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.055,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenSize.height * 0.02),

                  // Subtitle
                  Text(
                    pageData.subtitle,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.035,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenSize.height * 0.02),

                  // Description
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: pageData.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: pageData.color.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(
                      pageData.description,
                      style: TextStyle(
                        fontSize: screenSize.width * 0.035,
                        color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Bottom spacer
                  SizedBox(height: screenSize.height * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 10,
          width: isActive ? 30 : 10,
          decoration: BoxDecoration(
            gradient:
                isActive
                    ? LinearGradient(
                      colors: [_pages[_currentPage].color, _pages[_currentPage].color.withValues(alpha: 0.7)],
                    )
                    : null,
            color: isActive ? null : Colors.grey.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(15),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: _pages[_currentPage].color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _goToLogin,
              child: Text(
                "Skip",
                style: TextStyle(color: _pages[_currentPage].color, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDarkMode
                  ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  )
                  : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFF8FAFC)],
                  ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _resetAnimations();
                  },
                  itemBuilder: (context, index) {
                    return _buildPageContent(_pages[index]);
                  },
                ),
              ),

              // Page indicator
              Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: _buildPageIndicator()),

              // Bottom button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onNextPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: _pages[_currentPage].color.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Icon(_currentPage == _pages.length - 1 ? Icons.rocket_launch : Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
