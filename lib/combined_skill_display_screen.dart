import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'session_scheduling_screen.dart';
import 'services/firestore_stream_service.dart';

class CombinedSkillDisplayScreen extends StatefulWidget {
  const CombinedSkillDisplayScreen({super.key});

  @override
  State<CombinedSkillDisplayScreen> createState() => _CombinedSkillDisplayScreenState();
}

class _CombinedSkillDisplayScreenState extends State<CombinedSkillDisplayScreen> with AutomaticKeepAliveClientMixin {
  final FirestoreStreamService _streamService = FirestoreStreamService();
  String searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // Don't dispose streams in dispose() to prevent affecting other screens
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      child: Column(
        children: [
          _buildSearchBar(isDarkMode),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamService.getSkillsStream('combined_skills_display'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
                  );
                }

                final skills = snapshot.data?.docs ?? [];
                final combinedSkills = _combineSkills(skills);
                final filteredSkills = _filterSkills(combinedSkills);

                if (filteredSkills.isEmpty) {
                  return _buildEmptyState(isDarkMode);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredSkills.length,
                  itemBuilder: (context, index) => _buildCombinedSkillCard(filteredSkills[index], isDarkMode),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search skills...',
          prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
          filled: true,
          fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _combineSkills(List<QueryDocumentSnapshot> skills) {
    final Map<String, Map<String, dynamic>> userSkills = {};

    for (final doc in skills) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] ?? '';
      final type = data['type'] ?? '';

      if (userId.isEmpty) continue;

      if (!userSkills.containsKey(userId)) {
        userSkills[userId] = {
          'userId': userId,
          'userEmail': data['userEmail'] ?? 'Unknown',
          'offers': <Map<String, dynamic>>[],
          'requests': <Map<String, dynamic>>[],
        };
      }

      final skillData = {
        'id': doc.id,
        'title': data['title'] ?? 'Unknown Skill',
        'description': data['description'] ?? 'No description',
        'category': data['category'] ?? 'Other',
        'timestamp': data['timestamp'],
      };

      if (type == 'offer') {
        userSkills[userId]!['offers'].add(skillData);
      } else if (type == 'request') {
        userSkills[userId]!['requests'].add(skillData);
        // Add exchange skill to offers if available
        if (data['exchangeSkill'] != null && data['exchangeSkill'].toString().isNotEmpty) {
          userSkills[userId]!['offers'].add({
            'id': '${doc.id}_exchange',
            'title': data['exchangeSkill'],
            'description': data['exchangeDescription'] ?? 'Exchange skill',
            'category': data['exchangeCategory'] ?? 'Other',
            'timestamp': data['timestamp'],
            'isExchange': true,
          });
        }
      }
    }

    return userSkills.values
        .where((user) => (user['offers'] as List).isNotEmpty || (user['requests'] as List).isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _filterSkills(List<Map<String, dynamic>> skills) {
    if (searchQuery.isEmpty) return skills;

    return skills.where((user) {
      final userEmail = user['userEmail'].toString().toLowerCase();
      final offers = user['offers'] as List<Map<String, dynamic>>;
      final requests = user['requests'] as List<Map<String, dynamic>>;

      final matchesUser = userEmail.contains(searchQuery.toLowerCase());
      final matchesOffers = offers.any(
        (skill) =>
            skill['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            skill['description'].toString().toLowerCase().contains(searchQuery.toLowerCase()),
      );
      final matchesRequests = requests.any(
        (skill) =>
            skill['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            skill['description'].toString().toLowerCase().contains(searchQuery.toLowerCase()),
      );

      return matchesUser || matchesOffers || matchesRequests;
    }).toList();
  }

  Widget _buildCombinedSkillCard(Map<String, dynamic> userData, bool isDarkMode) {
    final userName = userData['userEmail'].toString().split('@')[0];
    final offers = userData['offers'] as List<Map<String, dynamic>>;
    final requests = userData['requests'] as List<Map<String, dynamic>>;
    final userId = userData['userId'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _openChat(userId, userName),
                      icon: const Icon(Icons.message, color: Colors.deepPurple),
                      tooltip: 'Message',
                    ),
                    IconButton(
                      onPressed: () => _scheduleSession(userData),
                      icon: const Icon(Icons.schedule, color: Colors.green),
                      tooltip: 'Schedule',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Skills offered
            if (offers.isNotEmpty) ...[
              _buildSkillSection('Skills Offered', offers, Colors.green, isDarkMode),
              const SizedBox(height: 12),
            ],

            // Skills requested
            if (requests.isNotEmpty) ...[_buildSkillSection('Skills Wanted', requests, Colors.blue, isDarkMode)],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillSection(String title, List<Map<String, dynamic>> skills, Color color, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(title.contains('Offered') ? Icons.volunteer_activism : Icons.help_outline, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) => _buildSkillChip(skill, color, isDarkMode)).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillChip(Map<String, dynamic> skill, Color color, bool isDarkMode) {
    final isExchange = skill['isExchange'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExchange) ...[Icon(Icons.swap_horiz, size: 14, color: color), const SizedBox(width: 4)],
          Text(skill['title'], style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text('Error loading skills', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: Colors.red.shade400), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No skills found', style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Be the first to share your skills!', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  void _openChat(String contactId, String contactName) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ChatScreen(contactName: contactName, contactId: contactId)));
  }

  void _scheduleSession(Map<String, dynamic> userData) {
    final userName = userData['userEmail'].toString().split('@')[0];
    final userId = userData['userId'] as String;
    final offers = userData['offers'] as List<Map<String, dynamic>>;

    if (offers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No skills available for scheduling'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Use the first skill for scheduling
    final firstSkill = offers.first;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SessionSchedulingScreen(
              skillId: firstSkill['id'],
              skillTitle: firstSkill['title'],
              providerId: userId,
              providerName: userName,
            ),
      ),
    );
  }
}
