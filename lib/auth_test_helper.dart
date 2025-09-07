import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthTestHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Test Firebase Authentication connectivity
  static Future<bool> testFirebaseAuth() async {
    try {
      // Check if Firebase Auth is initialized
      final currentUser = _auth.currentUser;
      if (kDebugMode) {
        print('🔥 Firebase Auth Status: ${currentUser != null ? 'Logged In' : 'Not Logged In'}');
        if (currentUser != null) {
          print('🔥 Current User: ${currentUser.email}');
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth test failed: $e');
      }
      return false;
    }
  }

  /// Test email/password sign up
  static Future<bool> testEmailSignUp(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      
      if (kDebugMode) {
        print('✅ Email Sign-Up successful: ${userCredential.user?.email}');
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Email Sign-Up failed: ${e.message}');
      }
      return false;
    }
  }

  /// Test email/password login
  static Future<bool> testEmailLogin(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        print('✅ Email Login successful: ${userCredential.user?.email}');
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Email Login failed: ${e.message}');
      }
      return false;
    }
  }

  /// Test password reset
  static Future<bool> testPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      if (kDebugMode) {
        print('✅ Password reset email sent to: $email');
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Password reset failed: ${e.message}');
      }
      return false;
    }
  }

  /// Test Google Sign-In
  static Future<bool> testGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        if (kDebugMode) {
          print('⚠️ Google Sign-In cancelled by user');
        }
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (kDebugMode) {
        print('✅ Google Sign-In successful: ${userCredential.user?.email}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Sign-In failed: $e');
      }
      return false;
    }
  }

  /// Test logout
  static Future<bool> testLogout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      if (kDebugMode) {
        print('✅ Logout successful');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Logout failed: $e');
      }
      return false;
    }
  }

  /// Get current authentication state
  static String getAuthState() {
    final user = _auth.currentUser;
    if (user == null) {
      return 'Not authenticated';
    }
    
    return '''
Authentication Status: ✅ Logged In
Email: ${user.email ?? 'N/A'}
Display Name: ${user.displayName ?? 'N/A'}
Email Verified: ${user.emailVerified ? '✅' : '❌'}
Provider: ${user.providerData.isNotEmpty ? user.providerData.first.providerId : 'Unknown'}
UID: ${user.uid}
''';
  }

  /// Run all authentication tests
  static Future<void> runAllTests() async {
    if (kDebugMode) {
      print('🧪 Starting Authentication Tests...\n');
      
      print('1. Testing Firebase Auth connectivity...');
      await testFirebaseAuth();
      
      print('\n2. Current Auth State:');
      print(getAuthState());
      
      print('\n🧪 Authentication Tests Complete!');
    }
  }
}
