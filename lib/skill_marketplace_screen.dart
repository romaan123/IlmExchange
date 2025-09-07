import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'session_scheduling_screen.dart';
import 'chat_screen.dart';
import 'combined_skill_display_screen.dart';
import 'services/firestore_stream_service.dart';

class SkillMarketplaceScreen extends StatefulWidget {
  const SkillMarketplaceScreen({super.key});

  @override
  State<SkillMarketplaceScreen> createState() => _SkillMarketplaceScreenState();
}

class _SkillMarketplaceScreenState extends State<SkillMarketplaceScreen> with AutomaticKeepAliveClientMixin {
  bool showOffers = true;
  bool showCombinedView = false;
  String searchQuery = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreStreamService _streamService = FirestoreStreamService();

  // Advanced filter options
  String? selectedCategory;
  String? selectedLocation;
  String? selectedMode;
  String? selectedExperienceLevel;
  double? minRating;

  // Filter options
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

  final List<String> modes = ['Online', 'In-person', 'Hybrid'];
  final List<String> experienceLevels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];

  bool showFilters = false;

  final List<Map<String, String>> offers = [
    {
      'name': 'Ayesha Khan',
      'skill': 'Graphic Design',
      'desc': 'Expert in Figma, Adobe Creative Suite. 5+ years experience.',
      'rating': '4.9',
    },
    {
      'name': 'Zain Ahmed',
      'skill': 'Guitar Lessons',
      'desc': 'Classical and modern guitar. Beginner to advanced levels.',
      'rating': '4.7',
    },
    {
      'name': 'Sara Ali',
      'skill': 'Python Programming',
      'desc': 'Full-stack development, Django, Flask. Industry experience.',
      'rating': '4.8',
    },
    {
      'name': 'Omar Hassan',
      'skill': 'Arabic Language',
      'desc': 'Native speaker. Conversational and formal Arabic lessons.',
      'rating': '4.6',
    },
  ];

  final List<Map<String, String>> requests = [
    {
      'name': 'Fatima Sheikh',
      'skill': 'Data Science',
      'desc': 'Looking for help with machine learning and statistics.',
      'rating': '4.5',
    },
    {
      'name': 'Ali Raza',
      'skill': 'English Speaking',
      'desc': 'Need practice partner for IELTS preparation.',
      'rating': '4.3',
    },
    {
      'name': 'Maryam Khan',
      'skill': 'Web Development',
      'desc': 'Want to learn React.js and modern frontend frameworks.',
      'rating': '4.4',
    },
    {
      'name': 'Hassan Ali',
      'skill': 'Photography',
      'desc': 'Beginner seeking guidance in portrait and landscape photography.',
      'rating': '4.2',
    },
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _streamService.disposeStream('marketplace');
    super.dispose();
  }

  List<Map<String, String>> getFilteredList() {
    List<Map<String, String>> list = showOffers ? offers : requests;
    if (searchQuery.isEmpty) return list;
    return list
        .where(
          (item) =>
              item['skill']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
              item['name']!.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  // Filter Firestore documents based on search query
  List<DocumentSnapshot> _filterSkills(List<DocumentSnapshot> skills) {
    final user = _auth.currentUser;
    final filteredSkills =
        skills.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userId = data['userId']?.toString();
          // Exclude current user's own posts from marketplace
          if (user != null && userId != null && userId == user.uid) return false;

          final title = (data['title'] ?? '').toString().toLowerCase();
          final description = (data['description'] ?? '').toString().toLowerCase();
          final category = (data['category'] ?? '').toString();
          final location = (data['location'] ?? '').toString();
          final mode = (data['mode'] ?? '').toString();
          final experienceLevel = (data['experienceLevel'] ?? '').toString();
          final userEmail = (data['userEmail'] ?? '').toString().toLowerCase();

          // Search query filter
          bool matchesSearch =
              searchQuery.isEmpty ||
              title.contains(searchQuery.toLowerCase()) ||
              description.contains(searchQuery.toLowerCase()) ||
              category.toLowerCase().contains(searchQuery.toLowerCase()) ||
              userEmail.contains(searchQuery.toLowerCase());

          // Category filter
          bool matchesCategory = selectedCategory == null || category == selectedCategory;

          // Location filter (partial match)
          bool matchesLocation =
              selectedLocation == null || location.toLowerCase().contains(selectedLocation!.toLowerCase());

          // Mode filter
          bool matchesMode = selectedMode == null || mode == selectedMode;

          // Experience level filter
          bool matchesExperience = selectedExperienceLevel == null || experienceLevel == selectedExperienceLevel;

          return matchesSearch && matchesCategory && matchesLocation && matchesMode && matchesExperience;
        }).toList();

    // Sort by timestamp (newest first)
    filteredSkills.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      final aTimestamp = aData['timestamp'] as Timestamp?;
      final bTimestamp = bData['timestamp'] as Timestamp?;

      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;

      return bTimestamp.compareTo(aTimestamp); // Descending order (newest first)
    });

    return filteredSkills;
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      selectedCategory = null;
      selectedLocation = null;
      selectedMode = null;
      selectedExperienceLevel = null;
      minRating = null;
      searchQuery = '';
    });
  }

  // Check if any filters are active
  bool get _hasActiveFilters {
    return selectedCategory != null ||
        selectedLocation != null ||
        selectedMode != null ||
        selectedExperienceLevel != null ||
        minRating != null ||
        searchQuery.isNotEmpty;
  }

  // Build Firestore skill card
  Widget _buildFirestoreSkillCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final title = data['title'] ?? 'Unknown Skill';
    final description = data['description'] ?? 'No description available';
    final category = data['category'] ?? 'Other';
    final userEmail = data['userEmail'] ?? 'Anonymous';
    final duration = data['duration'] ?? 'Not specified';
    final location = data['location'] ?? 'Not specified';
    final mode = data['mode'] ?? 'Not specified';
    final experienceLevel = data['experienceLevel'] ?? 'Any level';

    // Extract name from email or use email
    final userName = userEmail.contains('@') ? userEmail.split('@')[0] : userEmail;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey.shade500, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: showOffers ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    showOffers ? 'OFFER' : 'REQUEST',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: showOffers ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildInfoChip(Icons.category, category, isDarkMode),
                _buildInfoChip(Icons.schedule, duration, isDarkMode),
                _buildInfoChip(Icons.computer, mode, isDarkMode),
                _buildInfoChip(Icons.trending_up, experienceLevel, isDarkMode),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showFirestoreContactDialog(data),
                    icon: const Icon(Icons.message_rounded, size: 18),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _scheduleSession(data),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error loading skills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(fontSize: 14, color: Colors.red.shade400), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFirestoreContactDialog(Map<String, dynamic> data) async {
    final userName = data['userEmail']?.toString().split('@')[0] ?? 'User';
    final userId = data['userId'] ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start chat - user information missing'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Create or ensure chat document exists
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final chatId = _generateChatId(currentUserId, userId);
      final currentUserName =
          FirebaseAuth.instance.currentUser?.displayName ??
          FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
          'User';

      // Create chat document if it doesn't exist
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUserId, userId],
        'participantNames': {currentUserId: currentUserName, userId: userName},
        'lastMessage': 'Chat started from marketplace',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'unreadCount': {currentUserId: 0, userId: 0},
      }, SetOptions(merge: true));

      // Also create user documents for contact list visibility
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': userName,
        'email': data['userEmail'] ?? '',
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

      // Navigate directly to chat screen
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => ChatScreen(contactName: userName, contactId: userId)));
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

  void _scheduleSession(Map<String, dynamic> data) {
    final userName = data['userEmail']?.toString().split('@')[0] ?? 'User';
    final title = data['title'] ?? 'skill';
    final userId = data['userId'] ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to schedule session - user information missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SessionSchedulingScreen(
              skillId: 'skill_id', // Would be actual skill ID in production
              skillTitle: title,
              providerId: userId,
              providerName: userName,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      child: Column(
        children: [
          _buildToggleBar(isDarkMode),
          _buildViewToggle(isDarkMode),
          if (showFilters) _buildFilterPanel(isDarkMode),
          Expanded(child: showCombinedView ? const CombinedSkillDisplayScreen() : _buildSeparateView()),
        ],
      ),
    );
  }

  Widget _buildSeparateView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: _streamService.getSkillsStream(
        'marketplace_${showOffers ? 'offer' : 'request'}',
        type: showOffers ? 'offer' : 'request',
        excludeCurrentUser: true, // Enforce query-level filtering
      ),
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
        final filteredSkills = _filterSkills(skills);

        if (filteredSkills.isEmpty) {
          // Show static data as fallback if no Firestore data
          final staticList = getFilteredList();
          if (staticList.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: staticList.length,
              itemBuilder: (context, index) => _buildSkillCard(staticList[index], isDarkMode),
            );
          }
          return _buildEmptyState(isDarkMode);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredSkills.length,
          itemBuilder: (context, index) => _buildFirestoreSkillCard(filteredSkills[index]),
        );
      },
    );
  }

  Widget _buildViewToggle(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showCombinedView = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !showCombinedView ? Colors.deepPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Separate View',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !showCombinedView ? Colors.white : Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showCombinedView = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: showCombinedView ? Colors.deepPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Combined View',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: showCombinedView ? Colors.white : Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
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

  Widget _buildToggleBar(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => showOffers = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: showOffers ? Colors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Skill Offers",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: showOffers ? Colors.white : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    fontWeight: showOffers ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => showOffers = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !showOffers ? Colors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Skill Requests",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !showOffers ? Colors.white : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                    fontWeight: !showOffers ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
              Icon(Icons.tune, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Advanced Filters',
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

          // Category Filter
          _buildFilterDropdown(
            'Category',
            selectedCategory,
            categories,
            (value) => setState(() => selectedCategory = value),
            isDarkMode,
          ),

          const SizedBox(height: 12),

          // Mode Filter
          _buildFilterDropdown(
            'Mode',
            selectedMode,
            modes,
            (value) => setState(() => selectedMode = value),
            isDarkMode,
          ),

          const SizedBox(height: 12),

          // Experience Level Filter
          _buildFilterDropdown(
            'Experience Level',
            selectedExperienceLevel,
            experienceLevels,
            (value) => setState(() => selectedExperienceLevel = value),
            isDarkMode,
          ),

          const SizedBox(height: 12),

          // Location Filter
          TextField(
            decoration: InputDecoration(
              labelText: 'Location',
              hintText: 'Enter location...',
              prefixIcon: Icon(Icons.location_on, color: Colors.deepPurple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            ),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            onChanged: (value) => setState(() => selectedLocation = value.isEmpty ? null : value),
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
      value: (selectedValue != null && options.contains(selectedValue)) ? selectedValue : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
      ),
      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('All ${label}s', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ...options.map((option) => DropdownMenuItem<String>(value: option, child: Text(option))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSkillCard(Map<String, String> data, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                  child: Text(
                    data['name']![0],
                    style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            data['rating']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data['skill']!,
                style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['desc']!,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // This is demo data, show info message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This is demo data. Real messaging is available in the main marketplace.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: const Icon(Icons.message_rounded, size: 18),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRequestDialog(data),
                    icon: Icon(showOffers ? Icons.handshake_rounded : Icons.volunteer_activism_rounded, size: 18),
                    label: Text(showOffers ? 'Request' : 'Offer Help'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showOffers ? Icons.search_off_rounded : Icons.help_outline_rounded,
            size: 64,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No ${showOffers ? 'offers' : 'requests'} available'
                : 'No results found for "$searchQuery"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Check back later for new ${showOffers ? 'skill offers' : 'skill requests'}'
                : 'Try adjusting your search terms',
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRequestDialog(Map<String, String> data) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(showOffers ? 'Request Skill' : 'Offer Help'),
            content: Text(
              showOffers
                  ? 'Send a request to ${data['name']} for ${data['skill']} lessons?'
                  : 'Offer to help ${data['name']} with ${data['skill']}?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${showOffers ? 'Request' : 'Offer'} sent successfully!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: Text(showOffers ? 'Send Request' : 'Offer Help'),
              ),
            ],
          ),
    );
  }
}
