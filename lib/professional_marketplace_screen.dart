import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'services/firestore_stream_service.dart';
import 'chat_screen.dart';
import 'session_scheduling_screen.dart';

class ProfessionalMarketplaceScreen extends StatefulWidget {
  const ProfessionalMarketplaceScreen({super.key});

  @override
  State<ProfessionalMarketplaceScreen> createState() => _ProfessionalMarketplaceScreenState();
}

class _ProfessionalMarketplaceScreenState extends State<ProfessionalMarketplaceScreen>
    with AutomaticKeepAliveClientMixin {
  final FirestoreStreamService _streamService = FirestoreStreamService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedMode;
  String? _selectedLevel;
  bool _showFilters = false;

  final List<String> _categories = [
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

  final List<String> _modes = ['Online', 'In-person', 'Both'];
  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced', 'All levels'];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _streamService.disposeStream('marketplace');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(children: [_buildHeader(), if (_showFilters) _buildFilters(), Expanded(child: _buildSkillsList())]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Find Your Perfect Learning Match',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showFilters = !_showFilters),
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: _hasActiveFilters ? AppTheme.primaryGreen : AppTheme.textSecondary,
                ),
                tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search skills, categories, or instructors...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              if (_hasActiveFilters) TextButton(onPressed: _clearFilters, child: const Text('Clear All')),
            ],
          ),
          const SizedBox(height: 16),

          // Filter chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFilterDropdown(
                'Category',
                _selectedCategory,
                _categories,
                (value) => setState(() => _selectedCategory = value),
              ),
              _buildFilterDropdown('Mode', _selectedMode, _modes, (value) => setState(() => _selectedMode = value)),
              _buildFilterDropdown('Level', _selectedLevel, _levels, (value) => setState(() => _selectedLevel = value)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('All $label', style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          ...options.map((option) => DropdownMenuItem<String>(value: option, child: Text(option))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSkillsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _streamService.getSkillsStream('marketplace', excludeCurrentUser: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        final skills = snapshot.data?.docs ?? [];
        final groupedSkills = _groupSkillsByUser(skills);
        final filteredSkills = _filterSkills(groupedSkills);

        if (filteredSkills.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filteredSkills.length,
          itemBuilder: (context, index) => _buildUserCard(filteredSkills[index]),
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData) {
    final userName = userData['userEmail'].toString().split('@')[0];
    final offers = userData['offers'] as List<Map<String, dynamic>>;
    final requests = userData['requests'] as List<Map<String, dynamic>>;
    final userId = userData['userId'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
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
                          // Remove fake rating - show real user stats instead
                          Icon(Icons.school, color: AppTheme.primaryGreen, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${offers.length} teaching • ${requests.length} learning',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openChat(userId, userName),
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _scheduleSession(userData),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Book'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    ),
                  ],
                ),
              ],
            ),

            // Combined skills section showing both teaching and learning
            if (offers.isNotEmpty || requests.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildCombinedSkillsSection(offers, requests),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedSkillsSection(List<Map<String, dynamic>> offers, List<Map<String, dynamic>> requests) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teaching section
          if (offers.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Can Teach',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                ),
                const Spacer(),
                Text(
                  '${offers.length} skill${offers.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: offers.take(3).map((skill) => _buildSkillChip(skill, AppTheme.primaryGreen)).toList(),
            ),
            if (offers.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '+${offers.length - 3} more teaching skills',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ],

          // Divider between sections
          if (offers.isNotEmpty && requests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 16),
          ],

          // Learning section
          if (requests.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(color: AppTheme.accentBlue, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Wants to Learn',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.accentBlue),
                ),
                const Spacer(),
                Text(
                  '${requests.length} skill${requests.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: requests.take(3).map((skill) => _buildSkillChip(skill, AppTheme.accentBlue)).toList(),
            ),
            if (requests.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '+${requests.length - 3} more learning requests',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSkillChip(Map<String, dynamic> skill, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCategoryIcon(skill['category']), size: 16, color: color),
          const SizedBox(width: 6),
          Text(skill['title'], style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14)),
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
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => setState(() {}), child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text('No skills found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Try adjusting your search or filters', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _clearFilters, child: const Text('Clear Filters')),
        ],
      ),
    );
  }

  bool get _hasActiveFilters {
    return _selectedCategory != null || _selectedMode != null || _selectedLevel != null;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedMode = null;
      _selectedLevel = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Map<String, Map<String, dynamic>> _groupSkillsByUser(List<QueryDocumentSnapshot> skills) {
    final Map<String, Map<String, dynamic>> userSkills = {};

    for (final doc in skills) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] ?? '';

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
      }
    }

    return userSkills;
  }

  List<Map<String, dynamic>> _filterSkills(Map<String, Map<String, dynamic>> userSkills) {
    var filtered =
        userSkills.values.where((user) {
          final offers = user['offers'] as List<Map<String, dynamic>>;
          final requests = user['requests'] as List<Map<String, dynamic>>;

          if (offers.isEmpty && requests.isEmpty) return false;

          // Search filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
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
          if (_selectedCategory != null) {
            final hasMatchingCategory =
                offers.any((skill) => skill['category'] == _selectedCategory) ||
                requests.any((skill) => skill['category'] == _selectedCategory);
            if (!hasMatchingCategory) return false;
          }

          // Mode filter
          if (_selectedMode != null) {
            final hasMatchingMode =
                offers.any((skill) => skill['mode'] == _selectedMode) ||
                requests.any((skill) => skill['mode'] == _selectedMode);
            if (!hasMatchingMode) return false;
          }

          // Level filter
          if (_selectedLevel != null) {
            final hasMatchingLevel =
                offers.any((skill) => skill['experienceLevel'] == _selectedLevel) ||
                requests.any((skill) => skill['experienceLevel'] == _selectedLevel);
            if (!hasMatchingLevel) return false;
          }

          return true;
        }).toList();

    return filtered;
  }

  void _openChat(String userId, String userName) async {
    try {
      // Create or ensure chat document exists
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final chatId = _generateChatId(currentUserId, userId);

      // Create chat document if it doesn't exist
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUserId, userId],
        'participantNames': {currentUserId: FirebaseAuth.instance.currentUser?.displayName ?? 'User', userId: userName},
        'lastMessage': 'Chat started from marketplace',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'unreadCount': {currentUserId: 0, userId: 0},
      }, SetOptions(merge: true));

      debugPrint('✅ Chat document created/updated: $chatId');

      // Navigate to chat
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(contactName: userName, contactId: userId)),
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to open chat. Please try again.')));
      }
    }
  }

  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  void _scheduleSession(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SessionSchedulingScreen(
              skillId: 'skill_id',
              skillTitle: 'Skill Session',
              providerId: userData['userId'],
              providerName: userData['userEmail'].toString().split('@')[0],
            ),
      ),
    );
  }
}
