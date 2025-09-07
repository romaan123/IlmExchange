import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'skill_management_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Removed image-related services as requested

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _hasChanges = false;
  // Removed image-related variables as requested

  // Profile data
  List<String> _skillsOffered = [];
  List<String> _skillsRequested = [];
  double _averageRating = 0.0;
  int _totalRatings = 0;

  // Available skills for selection
  final List<String> _availableSkills = [
    'Art',
    'Music',
    'Coding',
    'Language',
    'Math',
    'Science',
    'Business',
    'Writing',
    'Photography',
    'Cooking',
    'Sports',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load basic auth data
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';

      // Load extended profile data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        _bioController.text = data['bio'] ?? '';
        _averageRating = (data['averageRating'] ?? 0.0).toDouble();
        // Removed image URL loading as requested

        // Calculate total ratings
        await _calculateRatings(user.uid);
      } else {
        // Create initial user document
        await _createUserDocument(user);
      }

      // Load skills from posts (offers and requests)
      await _loadUserSkillsFromPosts(user.uid);

      // Add listeners to detect changes
      _nameController.addListener(_onFieldChanged);
      _bioController.addListener(_onFieldChanged);
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      _showSnackbar('Error loading profile data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'bio': '',
        'skillsOffered': [],
        'skillsRequested': [],
        'photoUrl': user.photoURL,
        'averageRating': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error creating user document: $e');
    }
  }

  Future<void> _calculateRatings(String userId) async {
    try {
      final ratingsSnapshot = await _firestore.collection('users').doc(userId).collection('ratings').get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalStars = 0;
        for (final doc in ratingsSnapshot.docs) {
          totalStars += (doc.data()['stars'] ?? 0).toDouble();
        }

        setState(() {
          _totalRatings = ratingsSnapshot.docs.length;
          _averageRating = totalStars / _totalRatings;
        });
      }
    } catch (e) {
      debugPrint('❌ Error calculating ratings: $e');
    }
  }

  // Load skills from posts (offers and requests)
  Future<void> _loadUserSkillsFromPosts(String userId) async {
    try {
      // Load all skills (offers and requests) created by the user from Firestore
      final postsSnapshot = await _firestore.collection('skills').where('userId', isEqualTo: userId).get();
      final offeredSkills = <String>[];
      final requestedSkills = <String>[];
      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String?;
        final title = data['title'] as String?;
        if (title != null) {
          if (type == 'offer') {
            offeredSkills.add(title);
          } else if (type == 'request') {
            requestedSkills.add(title);
          }
        }
      }
      setState(() {
        _skillsOffered = offeredSkills.toSet().toList();
        _skillsRequested = requestedSkills.toSet().toList();
      });
      debugPrint('✅ Loaded ${_skillsOffered.length} offered skills and ${_skillsRequested.length} requested skills');
    } catch (e) {
      debugPrint('❌ Error loading user skills from posts: $e');
    }
  }

  void _onFieldChanged() {
    final user = _auth.currentUser;
    final hasNameChanged = _nameController.text != (user?.displayName ?? '');
    final hasBioChanged = _bioController.text.isNotEmpty;

    setState(() {
      _hasChanges = hasNameChanged || hasBioChanged;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Removed image picking method as requested

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update Firebase Auth profile
      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
        debugPrint('✅ Display name updated in Firebase Auth');
      }

      // Update Firestore document with merge to preserve existing data
      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': user.email,
        'bio': _bioController.text.trim(),
        'skillsOffered': _skillsOffered,
        'skillsRequested': _skillsRequested,
        'averageRating': _averageRating,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Reload user to get updated data
      await user.reload();

      debugPrint('✅ Profile saved successfully to Firestore');

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });

        _showSnackbar('Profile updated successfully!', Colors.green.shade600);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth error: ${e.message}');
      if (mounted) {
        _showSnackbar('Failed to update profile: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      if (mounted) {
        _showSnackbar('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Removed image upload method as requested

  void _cancelChanges() {
    _loadUserData();
    setState(() {
      _hasChanges = false;
    });
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Logout'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await _auth.signOut();
                if (mounted) {
                  navigator.pushReplacementNamed('/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: label == 'Bio' ? 3 : 1,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor:
            enabled
                ? (isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade50)
                : (isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.1) : Colors.grey.shade100),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildSkillsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Skills Offered
        _buildSkillCategory(
          title: 'Skills I Offer',
          skills: _skillsOffered,
          color: Colors.green,
          onAdd: () => _showSkillSelector(true),
          onRemove: (skill) => _removeSkill(skill, true),
        ),

        const SizedBox(height: 16),

        // Skills Requested
        _buildSkillCategory(
          title: 'Skills I Want to Learn',
          skills: _skillsRequested,
          color: Colors.blue,
          onAdd: () => _showSkillSelector(false),
          onRemove: (skill) => _removeSkill(skill, false),
        ),
      ],
    );
  }

  Widget _buildSkillCategory({
    required String title,
    required List<String> skills,
    required Color color,
    required VoidCallback onAdd,
    required Function(String) onRemove,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(onPressed: onAdd, icon: Icon(Icons.add, color: color), iconSize: 20),
            ],
          ),
          const SizedBox(height: 8),
          if (skills.isEmpty)
            Text('No skills added yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 14))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  skills
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          backgroundColor: color.withValues(alpha: 0.1),
                          labelStyle: TextStyle(color: color),
                          deleteIcon: Icon(Icons.close, size: 16, color: color),
                          onDeleted: () => onRemove(skill),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  const SizedBox(width: 8),
                  Text('($_totalRatings reviews)', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < _averageRating.floor() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _showSkillSelector(bool isOffered) async {
    final selectedSkills = isOffered ? _skillsOffered : _skillsRequested;
    final availableSkills = _availableSkills.where((skill) => !selectedSkills.contains(skill)).toList();

    if (availableSkills.isEmpty) {
      _showSnackbar('All skills have been added!', Colors.orange);
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isOffered ? 'Add Skill You Offer' : 'Add Skill You Want to Learn'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableSkills.length,
                itemBuilder: (context, index) {
                  final skill = availableSkills[index];
                  return ListTile(title: Text(skill), onTap: () => Navigator.of(context).pop(skill));
                },
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
          ),
    );

    if (result != null) {
      setState(() {
        if (isOffered) {
          _skillsOffered.add(result);
        } else {
          _skillsRequested.add(result);
        }
        _hasChanges = true;
      });
    }
  }

  void _removeSkill(String skill, bool isOffered) {
    setState(() {
      if (isOffered) {
        _skillsOffered.remove(skill);
      } else {
        _skillsRequested.remove(skill);
      }
      _hasChanges = true;
    });
  }

  Widget _buildSkillManagementButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SkillManagementScreen()));
        },
        icon: const Icon(Icons.manage_accounts, size: 20),
        label: const Text(
          'Manage My Skills',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
          foregroundColor: Colors.deepPurple,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [IconButton(onPressed: _showLogoutDialog, icon: Icon(Icons.logout, color: Colors.red.shade400))],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDarkMode
                  ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  )
                  : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFF8FAFC)],
                  ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Profile Avatar (display only)
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (value.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Email Field (Read-only)
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Your email address',
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),

                        const SizedBox(height: 20),

                        // Bio Field
                        _buildTextField(
                          controller: _bioController,
                          label: 'Bio',
                          hint: 'Tell others about yourself...',
                          icon: Icons.info_outline,
                          validator: (value) {
                            if (value != null && value.length > 500) {
                              return 'Bio must be less than 500 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // Skills Section
                        _buildSkillsSection(),

                        const SizedBox(height: 30),

                        // Ratings Section
                        _buildRatingsSection(),

                        const SizedBox(height: 30),

                        // Skill Management Button
                        _buildSkillManagementButton(isDarkMode),

                        const SizedBox(height: 40),

                        // Action Buttons
                        Row(
                          children: [
                            // Cancel Button
                            if (_hasChanges) ...[
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _cancelChanges,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey.shade400),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],

                            // Save Button
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: Colors.deepPurple.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    disabledBackgroundColor: Colors.grey.shade400,
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                          : Text(
                                            _hasChanges ? 'Save Changes' : 'No Changes',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
