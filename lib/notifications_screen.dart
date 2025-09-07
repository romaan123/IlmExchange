import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'services/firestore_stream_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreStreamService _streamService = FirestoreStreamService();

  @override
  void initState() {
    super.initState();
    _markNotificationsAsRead();
  }

  @override
  void dispose() {
    // Don't dispose streams in dispose() to prevent affecting other screens
    // Streams will be cleaned up when the app closes
    super.dispose();
  }

  Future<void> _markNotificationsAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final notifications =
          await _firestore
              .collection('notifications')
              .doc(user.uid)
              .collection('items')
              .where('read', isEqualTo: false)
              .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ Error marking notifications as read: $e');
    }
  }

  String _formatTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} hrs ago";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else {
      return "${diff.inDays} days ago";
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.message;
      case 'skill':
      case 'skill_posted':
        return Icons.school;
      case 'marketplace':
        return Icons.store;
      case 'rating':
        return Icons.star;
      case 'session':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'chat':
        return Colors.deepPurple;
      case 'skill':
      case 'skill_posted':
        return Colors.blue;
      case 'marketplace':
        return Colors.orange;
      case 'rating':
        return Colors.amber;
      case 'session':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final type = notification['type'] as String?;
    final relatedId = notification['relatedId'] as String?;
    final senderId = notification['senderId'] as String?;

    switch (type) {
      case 'chat':
        if (relatedId != null && senderId != null) {
          // Get sender's name from users collection
          try {
            final senderDoc = await _firestore.collection('users').doc(senderId).get();
            final senderName = senderDoc.data()?['name'] ?? 'Unknown User';

            if (mounted) {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => ChatScreen(contactName: senderName, contactId: senderId)));
            }
          } catch (e) {
            debugPrint('❌ Error getting sender info: $e');
            _showSnackbar('Error opening chat', Colors.red);
          }
        }
        break;
      case 'skill':
      case 'skill_posted':
        _showSnackbar('Opening skill details...', Colors.blue);
        break;
      case 'marketplace':
        // Navigate to marketplace to see the new skill
        if (mounted) {
          Navigator.of(context).pushNamed('/home'); // Navigate to home which has marketplace
          _showSnackbar('Check out the new skill in marketplace!', Colors.orange);
        }
        break;
      case 'session':
        // Navigate to sessions screen
        if (mounted) {
          Navigator.of(context).pushNamed('/home'); // Navigate to home, user can check sessions tab
          _showSnackbar('Check your sessions for updates', Colors.green);
        }
        break;
      case 'rating':
        _showSnackbar('Opening ratings...', Colors.amber);
        break;
      default:
        _showSnackbar('Notification opened', Colors.grey);
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  Widget _buildNotificationItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final type = data['type'] ?? 'default';
    final isRead = data['read'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isRead ? 1 : 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(type),
          child: Icon(_getNotificationIcon(type), color: Colors.white, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_formatTime(timestamp), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ),
          ],
        ),
        trailing:
            !isRead
                ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                )
                : null,
        onTap: () => _handleNotificationTap(data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Notifications"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamService.getNotificationsStream('notifications_screen', user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Notifications StreamBuilder Error: ${snapshot.error}');

            // Handle specific errors gracefully
            final errorMessage = snapshot.error.toString();
            if (errorMessage.contains('target already exists') ||
                errorMessage.contains('Target ID already exists') ||
                errorMessage.contains('permission-denied')) {
              // Show loading for temporary issues
              return const Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text('Error loading notifications', style: TextStyle(color: Colors.red.shade600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Please try again in a moment', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}), // Retry by rebuilding
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when you receive messages or updates',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationItem(notifications[index]);
            },
          );
        },
      ),
    );
  }
}
