import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _gradientController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    _navigateAfterDelay();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _scaleController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));

    _gradientController = AnimationController(duration: const Duration(seconds: 3), vsync: this);
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut));
  }

  void _startAnimationSequence() {
    _gradientController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _scaleController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  void _navigateAfterDelay() {
    // Navigate to auth flow after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: screenSize.height,
          child: AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDarkMode
                            ? [
                              Color.lerp(const Color(0xFF1A1A2E), const Color(0xFF16213E), _gradientAnimation.value)!,
                              Color.lerp(const Color(0xFF0F3460), const Color(0xFF533483), _gradientAnimation.value)!,
                            ]
                            : [
                              Color.lerp(const Color(0xFF667eea), const Color(0xFF764ba2), _gradientAnimation.value)!,
                              Color.lerp(const Color(0xFFf093fb), const Color(0xFFf5576c), _gradientAnimation.value)!,
                            ],
                  ),
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: screenSize.height * 0.8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Section with Hero Animation
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Hero(
                                tag: 'app_logo',
                                child: Container(
                                  width: screenSize.width * 0.25,
                                  height: screenSize.width * 0.25,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.school_outlined, size: 60, color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: screenSize.height * 0.02),

                        // App Name with Fade Animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'IlmExchange',
                            style: TextStyle(
                              fontSize: screenSize.width * 0.08,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: screenSize.height * 0.015),

                        // Tagline with Fade Animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Learn. Teach. Barter.',
                            style: TextStyle(
                              fontSize: screenSize.width * 0.04,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: screenSize.height * 0.03),

                        // Loading indicator
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
