import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'skill_edit_screen.dart';
import 'services/firestore_stream_service.dart';

class SkillManagementScreen extends StatefulWidget {
  const SkillManagementScreen({super.key});

  @override
  State<SkillManagementScreen> createState() => _SkillManagementScreenState();
}

class _SkillManagementScreenState extends State<SkillManagementScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreStreamService _streamService = FirestoreStreamService();
  late TabController _tabController;

  // Add refresh key to force stream rebuild
  int _refreshKey = 0;

  void _refreshSkills() {
    setState(() {
      _refreshKey++;
    });
    debugPrint('🔄 Refreshing skills list (key: $_refreshKey)');
  }

  // Debug method to manually check Firestore data
  Future<void> _debugCheckFirestoreData(String userId, String type) async {
    try {
      debugPrint('🔍 Manual Firestore check for userId=$userId, type=$type');

      // Check all skills in the collection
      final allSkills = await _firestore.collection('skills').get();
      debugPrint('📊 Total skills in collection: ${allSkills.docs.length}');

      // Check skills for this user
      final userSkills = await _firestore.collection('skills').where('userId', isEqualTo: userId).get();
      debugPrint('📊 Skills for user $userId: ${userSkills.docs.length}');

      // Check skills for this user and type
      final userTypeSkills =
          await _firestore.collection('skills').where('userId', isEqualTo: userId).where('type', isEqualTo: type).get();
      debugPrint('📊 Skills for user $userId with type $type: ${userTypeSkills.docs.length}');

      // Print details of user's skills
      for (final doc in userSkills.docs) {
        final data = doc.data();
        debugPrint('  - User skill: "${data['title']}" (type: ${data['type']}, id: ${doc.id})');
      }
    } catch (e) {
      debugPrint('❌ Error in manual Firestore check: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _streamService.disposeStream('management_offer');
    _streamService.disposeStream('management_request');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Skills'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please log in to manage your skills')),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Manage My Skills'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshSkills, tooltip: 'Refresh Skills')],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Offers', icon: Icon(Icons.volunteer_activism)),
            Tab(text: 'My Requests', icon: Icon(Icons.help_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSkillsList('offer', user.uid, isDarkMode), _buildSkillsList('request', user.uid, isDarkMode)],
      ),
    );
  }

  Widget _buildSkillsList(String type, String userId, bool isDarkMode) {
    debugPrint('🔍 Skill Management: Querying for type=$type, userId=$userId (refresh: $_refreshKey)');
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('skills_${type}_${userId}_$_refreshKey'), // Force rebuild on refresh
      stream:
          FirebaseFirestore.instance
              .collection('skills')
              .where('userId', isEqualTo: userId)
              .where('type', isEqualTo: type)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Skill Management Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading skills',
                  style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade400),
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

        final skills = snapshot.data?.docs ?? [];
        debugPrint('📊 Skill Management: Found ${skills.length} skills for type=$type (refresh: $_refreshKey)');

        // Debug: Print each skill with more details
        for (final skill in skills) {
          final data = skill.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'];
          debugPrint(
            '  - Skill: "${data['title']}" (type: ${data['type']}, userId: ${data['userId']}, timestamp: $timestamp)',
          );
        }

        // Additional debug: Check if we have any skills at all in the collection
        if (skills.isEmpty) {
          debugPrint('⚠️ No skills found - checking if this is a data issue or query issue');
          // Trigger a manual check
          _debugCheckFirestoreData(userId, type);
        }

        // Sort skills manually by timestamp (newest first)
        skills.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['timestamp'] as Timestamp?;
          final bTimestamp = bData['timestamp'] as Timestamp?;

          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          return bTimestamp.compareTo(aTimestamp);
        });

        if (skills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'offer' ? Icons.volunteer_activism : Icons.help_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  type == 'offer' ? 'No skill offers yet' : 'No skill requests yet',
                  style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  type == 'offer' ? 'Share your expertise with others' : 'Request skills you want to learn',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: skills.length,
          itemBuilder: (context, index) {
            return _buildSkillCard(skills[index], isDarkMode, type);
          },
        );
      },
    );
  }

  Widget _buildSkillCard(DocumentSnapshot doc, bool isDarkMode, String type) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Unknown Skill';
    final description = data['description'] ?? 'No description available';
    final category = data['category'] ?? 'Other';
    final timestamp = data['timestamp'] as Timestamp?;
    final createdAt = timestamp?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and category
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
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
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(color: Colors.deepPurple, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            if (createdAt != null) ...[
              const SizedBox(height: 12),
              Text('Posted ${_formatDate(createdAt)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editSkill(doc),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteSkill(doc, title),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _editSkill(DocumentSnapshot doc) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SkillEditScreen(skillDoc: doc)));
  }

  void _deleteSkill(DocumentSnapshot doc, String title) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Delete Skill'),
            content: Text('Are you sure you want to delete "$title"? This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performDelete(doc.id, title);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _performDelete(String docId, String title) async {
    try {
      await _firestore.collection('skills').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted "$title" successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting skill: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
