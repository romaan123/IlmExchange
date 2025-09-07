import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'chat_screen.dart';
import 'session_scheduling_screen.dart';
import 'services/firestore_stream_service.dart';
import 'services/presence_service.dart';
import 'services/profile_photo_service.dart';
import 'widgets/enhanced_avatar.dart';
import 'widgets/skeleton_loading.dart';

class ComprehensiveSkillMarketplaceScreen extends StatefulWidget {
  const ComprehensiveSkillMarketplaceScreen({super.key});

  @override
  State<ComprehensiveSkillMarketplaceScreen> createState() => _ComprehensiveSkillMarketplaceScreenState();
}

class _ComprehensiveSkillMarketplaceScreenState extends State<ComprehensiveSkillMarketplaceScreen>
    with AutomaticKeepAliveClientMixin {
  final FirestoreStreamService _streamService = FirestoreStreamService();
  String searchQuery = '';
  String? selectedCategory;
  String? selectedMode;
  String? selectedLevel;
  bool showFilters = false;

  final List<String> categories = [
    'Programming',
    'Design',
    'Languages',
    'Music',
    'Sports',
    'Cooking',
    'Photography',
    'Writing',
    'Mathematics',
    'Science',
    'Art',
    'Other',
  ];

  final List<String> modes = ['Online', 'In-person', 'Both'];
  final List<String> levels = ['Beginner', 'Intermediate', 'Advanced', 'All levels'];

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

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          if (showFilters) _buildFilterPanel(false),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamService.getSkillsStream('comprehensive_marketplace', excludeCurrentUser: true),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Marketplace StreamBuilder Error: ${snapshot.error}');
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonMarketplace();
                }

                final skills = snapshot.data?.docs ?? [];
                debugPrint('🔍 Marketplace: Found ${skills.length} total skills in database');

                final groupedSkills = _groupSkillsByUser(skills);
                debugPrint('🔍 Marketplace: Grouped into ${groupedSkills.length} user groups');

                final filteredSkills = _filterSkills(groupedSkills);
                debugPrint('🔍 Marketplace: After filtering: ${filteredSkills.length} skills to display');

                if (filteredSkills.isEmpty) {
                  debugPrint('🔍 Marketplace: No skills to display - showing empty state');
                  return _buildEmptyState(false);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredSkills.length,
                  itemBuilder: (context, index) => _buildUserSkillCard(filteredSkills[index], false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters {
    return selectedCategory != null || selectedMode != null || selectedLevel != null;
  }

  void _clearFilters() {
    setState(() {
      selectedCategory = null;
      selectedMode = null;
      selectedLevel = null;
      searchQuery = '';
      // Optionally, you can also reset showFilters if needed:
      // showFilters = false;
    });
  }

  Widget _buildFilterPanel(bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: Text('Clear All', style: TextStyle(color: Colors.red.shade400)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter dropdowns in a row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Category',
                  selectedCategory,
                  categories,
                  (value) => setState(() => selectedCategory = value),
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Mode',
                  selectedMode,
                  modes,
                  (value) => setState(() => selectedMode = value),
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Level',
                  selectedLevel,
                  levels,
                  (value) => setState(() => selectedLevel = value),
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
    bool isDarkMode,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('All', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ),
        ...options.map(
          (option) =>
              DropdownMenuItem<String>(value: option, child: Text(option, style: const TextStyle(fontSize: 14))),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Map<String, Map<String, dynamic>> _groupSkillsByUser(List<QueryDocumentSnapshot> skills) {
    final Map<String, Map<String, dynamic>> userSkills = {};

    for (final doc in skills) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] ?? '';
      final userEmail = data['userEmail'] ?? '';
      final type = data['type'] ?? '';
      final title = data['title'] ?? '';

      debugPrint('🔍 Processing skill: "$title" by $userEmail (type: $type, userId: $userId)');

      // Skip empty user IDs but allow current user's skills to be visible
      if (userId.isEmpty) {
        debugPrint('⚠️ Skipping skill with empty userId');
        continue;
      }

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
        'duration': data['duration'] ?? 'Not specified',
        'location': data['location'] ?? 'Not specified',
        'mode': data['mode'] ?? 'Not specified',
        'experienceLevel': data['experienceLevel'] ?? 'Any level',
        'timestamp': data['timestamp'],
      };

      if (data['type'] == 'offer') {
        userSkills[userId]!['offers'].add(skillData);
      } else if (data['type'] == 'request') {
        userSkills[userId]!['requests'].add(skillData);

        // Add exchange skill to offers if available
        if (data['exchangeSkill'] != null && data['exchangeSkill'].toString().isNotEmpty) {
          userSkills[userId]!['offers'].add({
            ...skillData,
            'id': '${doc.id}_exchange',
            'title': data['exchangeSkill'],
            'description': data['exchangeDescription'] ?? 'Exchange skill for ${skillData['title']}',
            'category': data['exchangeCategory'] ?? skillData['category'],
            'isExchange': true,
          });
        }
      }
    }

    return userSkills;
  }

  List<Map<String, dynamic>> _filterSkills(Map<String, Map<String, dynamic>> userSkills) {
    debugPrint('🔍 Filtering ${userSkills.length} user groups');

    var filtered =
        userSkills.values.where((user) {
          final offers = user['offers'] as List<Map<String, dynamic>>;
          final requests = user['requests'] as List<Map<String, dynamic>>;
          final userEmail = user['userEmail'] ?? 'Unknown';

          debugPrint('🔍 Checking user $userEmail: ${offers.length} offers, ${requests.length} requests');

          // Must have at least one skill
          if (offers.isEmpty && requests.isEmpty) {
            debugPrint('⚠️ Filtering out $userEmail - no skills');
            return false;
          }

          // Search filter
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            final userEmail = user['userEmail'].toString().toLowerCase();

            final matchesUser = userEmail.contains(query);
            final matchesOffers = offers.any(
              (skill) =>
                  skill['title'].toString().toLowerCase().contains(query) ||
                  skill['description'].toString().toLowerCase().contains(query) ||
                  skill['category'].toString().toLowerCase().contains(query),
            );
            final matchesRequests = requests.any(
              (skill) =>
                  skill['title'].toString().toLowerCase().contains(query) ||
                  skill['description'].toString().toLowerCase().contains(query) ||
                  skill['category'].toString().toLowerCase().contains(query),
            );

            if (!matchesUser && !matchesOffers && !matchesRequests) return false;
          }

          // Category filter
          if (selectedCategory != null) {
            final hasMatchingCategory =
                offers.any((skill) => skill['category'] == selectedCategory) ||
                requests.any((skill) => skill['category'] == selectedCategory);
            if (!hasMatchingCategory) return false;
          }

          // Mode filter
          if (selectedMode != null) {
            final hasMatchingMode =
                offers.any((skill) => skill['mode'] == selectedMode) ||
                requests.any((skill) => skill['mode'] == selectedMode);
            if (!hasMatchingMode) return false;
          }

          // Level filter
          if (selectedLevel != null) {
            final hasMatchingLevel =
                offers.any((skill) => skill['experienceLevel'] == selectedLevel) ||
                requests.any((skill) => skill['experienceLevel'] == selectedLevel);
            if (!hasMatchingLevel) return false;
          }

          return true;
        }).toList();

    // Sort by most recent activity
    filtered.sort((a, b) {
      final aOffers = a['offers'] as List<Map<String, dynamic>>;
      final aRequests = a['requests'] as List<Map<String, dynamic>>;
      final bOffers = b['offers'] as List<Map<String, dynamic>>;
      final bRequests = b['requests'] as List<Map<String, dynamic>>;

      final aLatest = [...aOffers, ...aRequests]
          .map((skill) => skill['timestamp'] as Timestamp?)
          .where((t) => t != null)
          .map((t) => t!.toDate())
          .fold<DateTime?>(null, (latest, date) => latest == null || date.isAfter(latest) ? date : latest);

      final bLatest = [...bOffers, ...bRequests]
          .map((skill) => skill['timestamp'] as Timestamp?)
          .where((t) => t != null)
          .map((t) => t!.toDate())
          .fold<DateTime?>(null, (latest, date) => latest == null || date.isAfter(latest) ? date : latest);

      if (aLatest == null && bLatest == null) return 0;
      if (aLatest == null) return 1;
      if (bLatest == null) return -1;
      return bLatest.compareTo(aLatest);
    });

    return filtered;
  }

  Widget _buildUserSkillCard(Map<String, dynamic> userData, bool isDarkMode) {
    final userName = userData['userEmail'].toString().split('@')[0];
    final offers = userData['offers'] as List<Map<String, dynamic>>;
    final requests = userData['requests'] as List<Map<String, dynamic>>;
    final userId = userData['userId'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced User header with rating and status
            Row(
              children: [
                StreamBuilder<bool>(
                  stream: PresenceService.getUserOnlineStatus(userId),
                  builder: (context, presenceSnapshot) {
                    final isOnline = presenceSnapshot.data ?? false;
                    return FutureBuilder<String?>(
                      future: ProfilePhotoService.getProfilePhotoUrl(userId),
                      builder: (context, photoSnapshot) {
                        return EnhancedAvatar(
                          userId: userId,
                          name: userName,
                          radius: 28,
                          showOnlineStatus: true,
                          isOnline: isOnline,
                          photoUrl: photoSnapshot.data,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) =>
                                  Icon(Icons.star, size: 16, color: index < 4 ? Colors.amber : Colors.grey.shade300),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('4.8', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Text('(23 reviews)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${offers.length} skills offered • ${requests.length} learning',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.lightGreen, borderRadius: BorderRadius.circular(20)),
                      child: const Text(
                        'Pro',
                        style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.message_outlined,
                          label: 'Message',
                          onPressed: () => _openChat(userId, userName),
                          isPrimary: false,
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.calendar_today,
                          label: 'Book',
                          onPressed: () => _scheduleSession(userData),
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Enhanced Skills sections
            if (offers.isNotEmpty) ...[
              _buildEnhancedSkillSection('Teaching', offers, AppTheme.primaryGreen, Icons.school),
              if (requests.isNotEmpty) const SizedBox(height: 16),
            ],

            if (requests.isNotEmpty) ...[
              _buildEnhancedSkillSection('Learning', requests, AppTheme.accentBlue, Icons.lightbulb_outline),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      height: 36,
      child:
          isPrimary
              ? ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 16),
                label: Text(label),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              )
              : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 16),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
    );
  }

  Widget _buildEnhancedSkillSection(String title, List<Map<String, dynamic>> skills, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
            const Spacer(),
            if (skills.length > 3)
              Text('+${skills.length - 3} more', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.take(3).map((skill) => _buildEnhancedSkillChip(skill, color)).toList(),
        ),
      ],
    );
  }

  Widget _buildEnhancedSkillChip(Map<String, dynamic> skill, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCategoryIcon(skill['category']), size: 14, color: color),
          const SizedBox(width: 6),
          Text(skill['title'], style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Text(
              skill['experienceLevel'] ?? 'Any',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'programming':
        return Icons.code;
      case 'design':
        return Icons.palette;
      case 'languages':
        return Icons.language;
      case 'music':
        return Icons.music_note;
      case 'sports':
        return Icons.sports;
      case 'cooking':
        return Icons.restaurant;
      case 'photography':
        return Icons.camera_alt;
      case 'writing':
        return Icons.edit;
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'art':
        return Icons.brush;
      default:
        return Icons.school;
    }
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
          Text(
            searchQuery.isNotEmpty ? 'Try adjusting your search or filters' : 'Be the first to share your skills!',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openChat(String contactId, String contactName) async {
    try {
      // Create or ensure chat document exists
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final chatId = _generateChatId(currentUserId, contactId);
      final currentUserName =
          FirebaseAuth.instance.currentUser?.displayName ??
          FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
          'User';

      // Create chat document if it doesn't exist
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUserId, contactId],
        'participantNames': {currentUserId: currentUserName, contactId: contactName},
        'lastMessage': 'Chat started from marketplace',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'unreadCount': {currentUserId: 0, contactId: 0},
      }, SetOptions(merge: true));

      // Also create user documents for contact list visibility
      await FirebaseFirestore.instance.collection('users').doc(contactId).set({
        'name': contactName,
        'email': '',
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': false,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
        'name': currentUserName,
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      }, SetOptions(merge: true));

      debugPrint('✅ Chat document and user profiles created/updated: $chatId');

      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => ChatScreen(contactName: contactName, contactId: contactId)));
      }
    } catch (e) {
      debugPrint('❌ Error creating chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start chat. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
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

    // Use the first non-exchange skill for scheduling
    final firstSkill = offers.firstWhere((skill) => skill['isExchange'] != true, orElse: () => offers.first);

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
