import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'services/firestore_stream_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreStreamService _streamService = FirestoreStreamService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    // Don't dispose streams in dispose() to prevent affecting other screens
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Contacts"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please log in to view contacts')),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Contacts"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Contacts list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamService.getContactsStream('contacts_screen'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading contacts', style: TextStyle(color: Colors.red)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
                  );
                }

                final chats = snapshot.data?.docs ?? [];
                final filteredChats =
                    chats.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final participantNames = Map<String, dynamic>.from(data['participantNames'] ?? {});
                      final participants = List<String>.from(data['participants'] ?? []);

                      // Find the other participant (not current user)
                      final otherUserId = participants.firstWhere((id) => id != user.uid, orElse: () => '');

                      if (otherUserId.isEmpty) return false;

                      final contactName = (participantNames[otherUserId] ?? '').toString().toLowerCase();

                      // Filter by search query
                      return contactName.contains(_searchQuery);
                    }).toList();

                if (filteredChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No conversations yet' : 'No matching contacts',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation from the marketplace!',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    return _buildChatCard(filteredChats[index], isDarkMode, user.uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(DocumentSnapshot chatDoc, bool isDarkMode, String currentUserId) {
    final data = chatDoc.data() as Map<String, dynamic>;
    final participants = List<String>.from(data['participants'] ?? []);
    final participantNames = Map<String, dynamic>.from(data['participantNames'] ?? {});
    final lastMessage = data['lastMessage'] ?? '';
    final lastMessageTime = data['lastMessageTime'] as Timestamp?;

    // Find the other participant (not current user)
    final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    final contactName = participantNames[otherUserId] ?? 'Unknown User';
    final timeAgo = lastMessageTime != null ? _formatTimeAgo(lastMessageTime.toDate()) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
          child: Text(
            contactName.isNotEmpty ? contactName[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        title: Text(
          contactName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastMessage.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                lastMessage,
                style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (timeAgo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(timeAgo, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ],
        ),
        trailing: IconButton(
          onPressed: () => _openChat(otherUserId, contactName),
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.deepPurple),
          tooltip: 'Open chat',
        ),
        onTap: () => _openChat(otherUserId, contactName),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
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

  void _openChat(String contactId, String contactName) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ChatScreen(contactName: contactName, contactId: contactId)));
  }
}
