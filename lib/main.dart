import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/presence_service.dart';
import 'theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'professional_login_screen.dart';
import 'forgot_password_screen.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'professional_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialized successfully');

    // Initialize Firebase Messaging background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize notification service
    await NotificationService.initialize();
    debugPrint('✅ Notification service initialized');

    // Initialize presence service
    await PresenceService.initialize();
    debugPrint('✅ Presence service initialized');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }

  runApp(const IlmExchangeApp());
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Background message received: ${message.notification?.title}');
}

class IlmExchangeApp extends StatelessWidget {
  const IlmExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IlmExchange',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Start with splash screen
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/auth': (context) => const AuthWrapper(),
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const ProfessionalLoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const ProfessionalHomeScreen(),
      },
    );
  }
}

// Authentication wrapper to handle login state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_onboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // If user is logged in, go to home
        if (snapshot.hasData) {
          return const ProfessionalHomeScreen();
        }

        // If not logged in, check if onboarding was seen
        return FutureBuilder<bool>(
          future: _hasSeenOnboarding(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Show login if onboarding was already seen
            if (onboardingSnapshot.data == true) {
              return const LoginScreen();
            }

            // Show onboarding for first-time users
            return const OnboardingScreen();
          },
        );
      },
    );
  }
}
