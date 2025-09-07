import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PresenceService {
  static FirebaseDatabase? _database;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static StreamSubscription? _presenceSubscription;
  static StreamSubscription? _authSubscription;
  static Timer? _heartbeatTimer;

  // Initialize presence system
  static Future<void> initialize() async {
    try {
      debugPrint('🔄 Initializing presence service...');

      // Temporarily disable Realtime Database to avoid Firebase URL error
      // This allows the app to work without presence features
      _database = null;
      debugPrint('⚠️ Presence service disabled (Realtime Database not configured)');

      // Still update Firestore for basic online status
      final user = _auth.currentUser;
      if (user != null) {
        await _updateFirestoreOnlineStatus(user.uid, true);
      }

      // Listen to auth state changes for Firestore updates only
      _authSubscription = _auth.authStateChanges().listen((user) {
        if (user != null) {
          _updateFirestoreOnlineStatus(user.uid, true);
        } else {
          _cleanup();
        }
      });

      debugPrint('✅ Presence service initialized (Firestore only)');
    } catch (e) {
      debugPrint('❌ Error initializing presence service: $e');
      _database = null;
    }
  }

  // Update only Firestore online status (fallback when Realtime DB is not available)
  static Future<void> _updateFirestoreOnlineStatus(String userId, bool isOnline) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.set({'isOnline': isOnline, 'lastSeen': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      debugPrint('✅ Updated Firestore online status for $userId: $isOnline');
    } catch (e) {
      debugPrint('❌ Error updating Firestore online status: $e');
    }
  }

  // Set user as offline
  static Future<void> setUserOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Update Firestore (always available)
      final userRef = _firestore.collection('users').doc(user.uid);
      await userRef.update({'isOnline': false, 'lastSeen': FieldValue.serverTimestamp()});

      // Update Realtime Database if available
      if (_database != null) {
        final presenceRef = _database!.ref('presence/${user.uid}');
        await presenceRef.set({'online': false, 'lastSeen': ServerValue.timestamp, 'timestamp': ServerValue.timestamp});
      }

      debugPrint('User ${user.uid} set as offline');
    } catch (e) {
      debugPrint('Error setting user offline: $e');
    }
  }

  // Get user online status (fallback to Firestore when Realtime DB not available)
  static Stream<bool> getUserOnlineStatus(String userId) {
    if (_database == null) {
      // Fallback to Firestore
      return _firestore.collection('users').doc(userId).snapshots().map((doc) {
        if (doc.exists) {
          final data = doc.data();
          return data?['isOnline'] as bool? ?? false;
        }
        return false;
      });
    }

    return _database!.ref('presence/$userId/online').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  // Get multiple users' online status (fallback to Firestore)
  static Stream<Map<String, bool>> getMultipleUsersStatus(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value({});
    }

    if (_database == null) {
      // Fallback to Firestore - return static false for now
      return Stream.value(Map.fromEntries(userIds.map((id) => MapEntry(id, false))));
    }

    return _database!.ref('presence').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final result = <String, bool>{};

      for (final userId in userIds) {
        final userPresence = data[userId] as Map<dynamic, dynamic>?;
        result[userId] = userPresence?['online'] as bool? ?? false;
      }

      return result;
    });
  }

  // Get last seen timestamp (fallback to Firestore)
  static Future<DateTime?> getLastSeen(String userId) async {
    try {
      if (_database == null) {
        // Fallback to Firestore
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          final data = doc.data();
          final timestamp = data?['lastSeen'] as Timestamp?;
          return timestamp?.toDate();
        }
        return null;
      }

      final snapshot = await _database!.ref('presence/$userId/lastSeen').get();
      final timestamp = snapshot.value as int?;
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      debugPrint('Error getting last seen: $e');
      return null;
    }
  }

  // Format last seen for display
  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Long time ago';
    }
  }

  // Cleanup resources
  static void _cleanup() {
    _presenceSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _presenceSubscription = null;
    _heartbeatTimer = null;
  }

  // Dispose all resources
  static void dispose() {
    _authSubscription?.cancel();
    _cleanup();
  }
}
