import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseTestHelper {
  static Future<bool> testFirebaseConnection() async {
    try {
      // Test anonymous sign-in to verify Firebase connection
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      
      if (userCredential.user != null) {
        // Sign out the anonymous user immediately
        await FirebaseAuth.instance.signOut();
        if (kDebugMode) {
          print('✅ Firebase connection successful');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase connection failed: $e');
      }
      return false;
    }
  }

  static Future<void> testAuthenticationMethods() async {
    try {
      // Test if Firebase Auth is properly initialized
      final auth = FirebaseAuth.instance;
      if (kDebugMode) {
        print('🔥 Firebase Auth initialized: ${auth.app.name}');
        print('🔥 Current user: ${auth.currentUser?.uid ?? 'None'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth test failed: $e');
      }
    }
  }
}
