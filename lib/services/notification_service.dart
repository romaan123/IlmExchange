import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize FCM
  static Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
          debugPrint('🔔 FCM Token: $token');
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

        // Configure message handlers
        _configureMessageHandlers();
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  // Save FCM token to Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Use set with merge to avoid errors if user document doesn't exist
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('🔔 FCM token saved to Firestore for user: ${user.uid}');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
      // Don't throw error as this is not critical for app functionality
    }
  }

  // Configure message handlers
  static void _configureMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground message received: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Background message tapped: ${message.notification?.title}');
      _handleMessageTap(message);
    });

    // Handle app launch from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 App launched from notification: ${message.notification?.title}');
        _handleMessageTap(message);
      }
    });
  }

  // Handle foreground messages (show in-app notification)
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground notification: ${message.notification?.body}');

    // Show local notification for foreground messages
    _showLocalNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new message',
      data: message.data,
    );
  }

  // Show local notification
  static void _showLocalNotification({required String title, required String body, Map<String, dynamic>? data}) {
    // In a real app, you would use flutter_local_notifications
    // For now, we'll just log it
    debugPrint('🔔 Local notification: $title - $body');
  }

  // Handle message tap (navigate to relevant screen)
  static void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    debugPrint('🔔 Notification tapped - Type: $type, Data: $data');

    // Navigate based on notification type
    switch (type) {
      case 'chat':
        // Navigate to chat screen
        final chatId = data['relatedId'];
        debugPrint('🔔 Navigate to chat: $chatId');
        break;
      case 'skill':
        // Navigate to skill marketplace
        debugPrint('🔔 Navigate to skill marketplace');
        break;
      case 'session':
        // Navigate to sessions screen
        debugPrint('🔔 Navigate to sessions');
        break;
      case 'rating':
        // Navigate to profile
        debugPrint('🔔 Navigate to profile');
        break;
      default:
        debugPrint('🔔 Unknown notification type: $type');
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('🔔 Attempting to send notification to user: $userId');

      // Create notification data with all required fields
      final notificationData = {
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': _auth.currentUser?.uid,
        'read': false, // Always initialize as unread
        ...?data,
      };

      // Use a separate Firestore instance to avoid conflicts with streams
      final separateFirestore = FirebaseFirestore.instance;

      // Save to Firestore notifications collection with error handling
      await separateFirestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .add(notificationData)
          .timeout(const Duration(seconds: 10));

      debugPrint('✅ Notification saved successfully for user: $userId');

      // Don't fetch FCM token to avoid additional Firestore queries that might conflict
      debugPrint('📝 Notification saved to Firestore only (FCM disabled to prevent conflicts)');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      // Don't rethrow to prevent breaking the main functionality
    }
  }

  // Send chat notification
  static Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: 'New message from $senderName',
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      type: 'chat',
      data: {'relatedId': chatId, 'senderId': _auth.currentUser?.uid},
    );
  }

  // Send skill notification
  static Future<void> sendSkillNotification({
    required String receiverId,
    required String title,
    required String skillTitle,
    required String skillId,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: title,
      body: 'Regarding: $skillTitle',
      type: 'skill',
      data: {'relatedId': skillId},
    );
  }

  // Send session notification
  static Future<void> sendSessionNotification({
    required String receiverId,
    required String title,
    required String sessionDetails,
    required String sessionId,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: title,
      body: sessionDetails,
      type: 'session',
      data: {'relatedId': sessionId},
    );
  }

  // Send rating notification
  static Future<void> sendRatingNotification({
    required String receiverId,
    required String raterName,
    required double rating,
    required String reviewId,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: 'New rating from $raterName',
      body: 'You received a ${rating.toStringAsFixed(1)} star rating!',
      type: 'rating',
      data: {'relatedId': reviewId, 'rating': rating},
    );
  }

  // Send marketplace notification for new skill posts
  static Future<void> sendMarketplaceNotification({
    required String receiverId,
    required String title,
    required String skillTitle,
    required String category,
    required String skillId,
    required bool isOffer,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: title,
      body: 'New ${isOffer ? 'skill offer' : 'skill request'}: $skillTitle in $category category',
      type: 'marketplace',
      data: {'relatedId': skillId, 'skillTitle': skillTitle, 'category': category, 'isOffer': isOffer},
    );
  }

  // Clear all notifications for current user
  static Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        final notifications = await _firestore.collection('notifications').doc(user.uid).collection('items').get();

        for (final doc in notifications.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        debugPrint('🔔 All notifications cleared');
      }
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  // Get notification count
  static Stream<int> getNotificationCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .doc(user.uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.notification?.title}');
}
