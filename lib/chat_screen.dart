import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/notification_service.dart';
import 'services/firestore_stream_service.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String contactId;

  const ChatScreen({super.key, required this.contactName, required this.contactId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreStreamService _streamService = FirestoreStreamService();

  late String _chatId;
  late String _currentUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final user = _auth.currentUser;
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }

    _currentUserId = user.uid;
    _chatId = _getChatId(_currentUserId, widget.contactId);

    debugPrint('🔥 Chat initialized: $_chatId');
    debugPrint('Current user: $_currentUserId');
    debugPrint('Contact: ${widget.contactId}');
  }

  String _getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  void dispose() {
    // Don't dispose streams in dispose() to prevent affecting other screens
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final messageData = {
        'senderId': _currentUserId,
        'receiverId': widget.contactId,
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('chats').doc(_chatId).collection('messages').add(messageData);

      // Update chat document with last message info
      await _firestore.collection('chats').doc(_chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      _messageController.clear();
      _scrollToBottom();

      // Send notification to receiver
      await _sendNotification(text);
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      _showSnackbar('Failed to send message. Please try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendNotification(String message) async {
    try {
      // Add a small delay to prevent Firestore conflicts
      await Future.delayed(const Duration(milliseconds: 500));

      // Use the NotificationService to send chat notification
      await NotificationService.sendChatNotification(
        receiverId: widget.contactId,
        senderName: _auth.currentUser?.displayName ?? widget.contactName,
        message: message,
        chatId: _chatId,
      );

      debugPrint('✅ Chat notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      // Don't show error to user as this is not critical
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  Widget _buildMessage(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == _currentUserId;
    final message = data['message'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isMe ? Colors.deepPurple : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
          ),
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_formatTimestamp(timestamp), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text("Chat with ${widget.contactName}"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamService.getMessagesStream('chat_${widget.contactId}', _chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages', style: TextStyle(color: Colors.red)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
                  );
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Start the conversation!', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(messages[index]);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                border: Border(top: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isLoading,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: "Type your message...",
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey : Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child:
                        _isLoading
                            ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                            : IconButton(
                              icon: const Icon(Icons.send, color: Colors.white, size: 20),
                              onPressed: _sendMessage,
                              padding: EdgeInsets.zero,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
