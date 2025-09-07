import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_stream_service.dart';
import 'services/notification_service.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreStreamService _streamService = FirestoreStreamService();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // Don't dispose streams in dispose() to prevent affecting other screens
    // Streams will be cleaned up when the app closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50,
        body: const Center(child: Text('Please log in to view your sessions')),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'My Sessions',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your upcoming skill exchange sessions',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Sessions List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamService.getSessionsStream('sessions_screen'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Improved error handling with debug information
                  debugPrint('Sessions StreamBuilder Error: ${snapshot.error}');

                  // Handle specific "target already exists" error
                  final errorMessage = snapshot.error.toString();
                  if (errorMessage.contains('target already exists') ||
                      errorMessage.contains('Target ID already exists')) {
                    // This is a temporary Firestore issue, show loading instead
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
                        Text(
                          'Error loading sessions',
                          style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try again in a moment',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
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

                final sessions = snapshot.data?.docs ?? [];
                final now = DateTime.now();

                // Filter sessions for current user and upcoming only
                final upcomingSessions =
                    sessions.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
                      final providerId = data['providerId'] ?? '';
                      final requesterId = data['requesterId'] ?? '';

                      // Check if user is involved in this session and it's upcoming
                      final isUserInvolved = providerId == user.uid || requesterId == user.uid;
                      final isUpcoming = dateTime != null && dateTime.isAfter(now);

                      return isUserInvolved && isUpcoming;
                    }).toList();

                if (upcomingSessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No upcoming sessions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Schedule a session from the skill marketplace',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: upcomingSessions.length,
                  itemBuilder: (context, index) {
                    return _buildSessionCard(upcomingSessions[index], isDarkMode, user.uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(DocumentSnapshot doc, bool isDarkMode, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;
    final skillTitle = data['skillTitle'] ?? 'Unknown Skill';
    final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
    final status = data['status'] ?? 'pending';
    final notes = data['notes'] ?? '';
    final providerId = data['providerId'] ?? '';
    final providerName = data['providerName'] ?? 'Unknown';
    final requesterName = data['requesterName'] ?? 'Unknown';

    // Determine if current user is provider or requester
    final isProvider = currentUserId == providerId;
    final otherPersonName = isProvider ? requesterName : providerName;
    final role = isProvider ? 'Teaching' : 'Learning';

    // Format date and time
    final formattedDate = dateTime != null ? '${dateTime.day}/${dateTime.month}/${dateTime.year}' : 'Date TBD';
    final formattedTime =
        dateTime != null
            ? '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
            : 'Time TBD';

    // Status color
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with skill and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    skillTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Role and partner info
            Row(
              children: [
                Icon(isProvider ? Icons.school : Icons.person, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$role with $otherPersonName',
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date and time
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 8),
                Text(
                  formattedTime,
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                ),
              ],
            ),

            // Notes if available
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, color: Colors.grey.shade500, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateSessionStatus(doc.id, 'cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateSessionStatus(doc.id, 'confirmed'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateSessionStatus(String sessionId, String newStatus) async {
    try {
      // Get session data first to send notification
      final sessionDoc = await _firestore.collection('sessions').doc(sessionId).get();
      final sessionData = sessionDoc.data();

      if (sessionData == null) {
        throw Exception('Session not found');
      }

      // Update session status
      await _firestore.collection('sessions').doc(sessionId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to the other party
      final currentUserId = _auth.currentUser?.uid;
      final providerId = sessionData['providerId'] as String?;
      final requesterId = sessionData['requesterId'] as String?;
      final skillTitle = sessionData['skillTitle'] as String? ?? 'Unknown Skill';

      // Determine who to notify (the other party)
      String? notifyUserId;
      if (currentUserId == providerId) {
        notifyUserId = requesterId;
      } else if (currentUserId == requesterId) {
        notifyUserId = providerId;
      }

      if (notifyUserId != null) {
        String title;
        String details;

        // More detailed notification messages based on status and user role
        if (newStatus == 'confirmed') {
          title = 'Session Confirmed! 🎉';
          if (currentUserId == providerId) {
            details = 'You confirmed the session for "$skillTitle". The requester has been notified.';
          } else {
            details = 'Great news! Your session request for "$skillTitle" has been confirmed by the provider.';
          }
        } else if (newStatus == 'cancelled') {
          title = 'Session Cancelled';
          if (currentUserId == providerId) {
            details = 'You cancelled the session for "$skillTitle". The requester has been notified.';
          } else {
            details = 'The session for "$skillTitle" has been cancelled by the provider.';
          }
        } else {
          title = 'Session Status Updated';
          details = 'The session for "$skillTitle" status has been updated to $newStatus.';
        }

        await NotificationService.sendSessionNotification(
          receiverId: notifyUserId,
          title: title,
          sessionDetails: details,
          sessionId: sessionId,
        );

        debugPrint('✅ Session notification sent to user: $notifyUserId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session ${newStatus == 'confirmed' ? 'confirmed' : 'cancelled'}'),
            backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating session status: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating session: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
