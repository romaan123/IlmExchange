import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_stream_service.dart';

class PostOfferRequestScreen extends StatefulWidget {
  const PostOfferRequestScreen({super.key});

  @override
  State<PostOfferRequestScreen> createState() => _PostOfferRequestScreenState();
}

class _PostOfferRequestScreenState extends State<PostOfferRequestScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // Tab Controller for Offer/Request tabs
  late TabController _tabController;

  // Form keys for both tabs
  final _offerFormKey = GlobalKey<FormState>();

  // Controllers for Offer form
  final _offerTitleController = TextEditingController();
  final _offerDescController = TextEditingController();
  final _offerDurationController = TextEditingController();
  final _offerLocationController = TextEditingController();

  // Controllers for Request form
  final _requestTitleController = TextEditingController();
  final _requestDescController = TextEditingController();
  final _requestDurationController = TextEditingController();
  final _requestLocationController = TextEditingController();

  // Note: Exchange skill data comes from offer form (no separate controllers needed)

  // Dropdown values for Offer
  String? _offerSelectedCategory;
  String? _offerSelectedMode;
  String? _offerSelectedLevel;

  // Dropdown values for Request
  String? _requestSelectedCategory;
  String? _requestSelectedMode;
  String? _requestSelectedLevel;

  // Loading and animation states
  bool _isLoading = false;
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;

  // Skill categories as specified in requirements
  final List<String> _categories = [
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

  final List<String> _modes = ['Online', 'In-person', 'Hybrid'];
  final List<String> _levels = ['Beginner', 'Intermediate', 'Expert'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadingAnimationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _loadingAnimationController, curve: Curves.easeInOut));

    // Add listeners to update form completion status
    _addFormListeners();
  }

  void _addFormListeners() {
    // Offer form listeners
    _offerTitleController.addListener(_updateFormStatus);
    _offerDescController.addListener(_updateFormStatus);
    _offerDurationController.addListener(_updateFormStatus);
    _offerLocationController.addListener(_updateFormStatus);

    // Request form listeners
    _requestTitleController.addListener(_updateFormStatus);
    _requestDescController.addListener(_updateFormStatus);
    _requestDurationController.addListener(_updateFormStatus);
    _requestLocationController.addListener(_updateFormStatus);

    // Note: Exchange skill data comes from offer form, so no separate listeners needed
  }

  void _updateFormStatus() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild and update the tab indicators
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loadingAnimationController.dispose();

    // Dispose Offer controllers
    _offerTitleController.dispose();
    _offerDescController.dispose();
    _offerDurationController.dispose();
    _offerLocationController.dispose();

    // Dispose Request controllers
    _requestTitleController.dispose();
    _requestDescController.dispose();
    _requestDurationController.dispose();
    _requestLocationController.dispose();

    // Note: No separate exchange controllers to dispose

    super.dispose();
  }

  void _showSnackbar(String message, [Color? color]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Validation functions
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    return null;
  }

  String? _validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Duration is required';
    }
    // Check if it contains a number and unit
    final regex = RegExp(r'^\d+\s*(hour|hours|week|weeks|day|days|minute|minutes)$', caseSensitive: false);
    if (!regex.hasMatch(value.trim())) {
      return 'Format: "2 hours" or "3 weeks"';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    return null;
  }

  String? _validateDropdown(String? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }
    return null;
  }

  // Check if both forms are complete
  bool _areBothFormsComplete() {
    return _checkOfferFormComplete() && _checkRequestFormComplete();
  }

  bool _checkOfferFormComplete() {
    final isComplete =
        _offerTitleController.text.trim().isNotEmpty &&
        _offerDescController.text.trim().isNotEmpty &&
        _offerDurationController.text.trim().isNotEmpty &&
        _offerLocationController.text.trim().isNotEmpty &&
        _offerSelectedCategory != null &&
        _offerSelectedMode != null &&
        _offerSelectedLevel != null;

    debugPrint('🔍 Offer form complete check: $isComplete');
    debugPrint('  - Title: "${_offerTitleController.text.trim()}" (${_offerTitleController.text.trim().isNotEmpty})');
    debugPrint(
      '  - Description: "${_offerDescController.text.trim()}" (${_offerDescController.text.trim().isNotEmpty})',
    );
    debugPrint(
      '  - Duration: "${_offerDurationController.text.trim()}" (${_offerDurationController.text.trim().isNotEmpty})',
    );
    debugPrint(
      '  - Location: "${_offerLocationController.text.trim()}" (${_offerLocationController.text.trim().isNotEmpty})',
    );
    debugPrint('  - Category: $_offerSelectedCategory (${_offerSelectedCategory != null})');
    debugPrint('  - Mode: $_offerSelectedMode (${_offerSelectedMode != null})');
    debugPrint('  - Level: $_offerSelectedLevel (${_offerSelectedLevel != null})');

    return isComplete;
  }

  bool _checkRequestFormComplete() {
    final isComplete =
        _requestTitleController.text.trim().isNotEmpty &&
        _requestDescController.text.trim().isNotEmpty &&
        _requestDurationController.text.trim().isNotEmpty &&
        _requestLocationController.text.trim().isNotEmpty &&
        _requestSelectedCategory != null &&
        _requestSelectedMode != null &&
        _requestSelectedLevel != null;

    debugPrint('🔍 Request form complete check: $isComplete');
    debugPrint(
      '  - Title: "${_requestTitleController.text.trim()}" (${_requestTitleController.text.trim().isNotEmpty})',
    );
    debugPrint(
      '  - Description: "${_requestDescController.text.trim()}" (${_requestDescController.text.trim().isNotEmpty})',
    );
    debugPrint(
      '  - Duration: "${_requestDurationController.text.trim()}" (${_requestDurationController.text.trim().isNotEmpty})',
    );
    debugPrint(
      '  - Location: "${_requestLocationController.text.trim()}" (${_requestLocationController.text.trim().isNotEmpty})',
    );
    debugPrint('  - Category: $_requestSelectedCategory (${_requestSelectedCategory != null})');
    debugPrint('  - Mode: $_requestSelectedMode (${_requestSelectedMode != null})');
    debugPrint('  - Level: $_requestSelectedLevel (${_requestSelectedLevel != null})');

    return isComplete;
  }

  // Unified submit function for skill exchange
  Future<void> _submitSkillExchange() async {
    debugPrint('🔄 Submit Skill Exchange button pressed');

    if (!_offerFormKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    // Check if both forms are complete (mandatory for skill barter)
    if (!_areBothFormsComplete()) {
      debugPrint('❌ Both forms not complete');
      _showSnackbar(
        'Please complete both "I Can Teach" and "I Want to Learn" sections for fair skill exchange',
        Colors.orange,
      );
      return;
    }

    debugPrint('✅ Both forms validation passed, submitting skill exchange...');

    // Submit both offer and request as a skill exchange
    await _submitBothToFirestore();
  }

  // Submit both offer and request as a unified skill exchange
  Future<void> _submitBothToFirestore() async {
    // Prevent multiple submissions
    if (_isLoading) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadingAnimationController.repeat();
      });
    }

    try {
      debugPrint('🔥 Starting unified skill exchange submission...');
      debugPrint('📊 Offer complete: ${_checkOfferFormComplete()}');
      debugPrint('📊 Request complete: ${_checkRequestFormComplete()}');
      debugPrint('📊 Both complete: ${_areBothFormsComplete()}');

      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('🔐 No user logged in, attempting anonymous sign-in...');
        try {
          final credential = await FirebaseAuth.instance.signInAnonymously();
          user = credential.user;
          debugPrint('✅ Anonymous sign-in successful: ${user?.uid}');
        } catch (e) {
          debugPrint('❌ Anonymous sign-in failed: $e');
          _showSnackbar('Authentication failed. Please try logging in.', Colors.red);
          return;
        }
      }

      debugPrint('👤 User authenticated: ${user?.uid}');

      // Submit offer first
      debugPrint('📤 Submitting offer...');
      debugPrint('📝 Offer data: Title="${_offerTitleController.text}", Category=$_offerSelectedCategory');

      // Test if we can reach this point
      debugPrint('🔥 CHECKPOINT 1: About to submit offer');

      // Try a simple test first - just print something
      debugPrint('🔥 CHECKPOINT 2: Testing execution flow');

      // Test if the function exists
      debugPrint('🔥 CHECKPOINT 3: Function exists: true');

      // Try calling the function
      debugPrint('🔥 CHECKPOINT 4: Calling _submitToFirestore(true)');
      try {
        await _submitToFirestore(true);
        debugPrint('🔥 CHECKPOINT 5: Offer submitted successfully');
      } catch (e) {
        debugPrint('🔥 CHECKPOINT ERROR: $e');
        rethrow;
      }

      // Wait a moment to avoid conflicts
      await Future.delayed(const Duration(milliseconds: 1000));

      // Submit request
      debugPrint('📤 Submitting request...');
      debugPrint('📝 Request data: Title="${_requestTitleController.text}", Category=$_requestSelectedCategory');

      // Test if we can reach this point
      debugPrint('🔥 CHECKPOINT 6: About to submit request');

      // Try calling the function
      debugPrint('🔥 CHECKPOINT 7: Calling _submitToFirestore(false)');
      try {
        await _submitToFirestore(false);
        debugPrint('🔥 CHECKPOINT 8: Request submitted successfully');
      } catch (e) {
        debugPrint('🔥 CHECKPOINT ERROR: $e');
        rethrow;
      }

      _showSnackbar('🎉 Skill Exchange Posted Successfully! Both your offer and request are now live.', Colors.green);

      // Reset both forms after successful submission
      _resetBothForms();

      // Add a longer delay to ensure Firestore indexing is complete
      await Future.delayed(const Duration(milliseconds: 2000));

      // Force refresh of any cached streams
      debugPrint('🔄 Forcing stream refresh after skill submission...');

      // Import and use the stream service to refresh streams
      final streamService = FirestoreStreamService();
      streamService.refreshSkillStreams();

      // Navigate to home with a flag to refresh skill management
      if (mounted) {
        try {
          // Navigate to home and then immediately to profile to see the skills
          Navigator.of(context).pushReplacementNamed('/home');

          // Add a small delay and then show a dialog to guide user to check their skills
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _showSkillsPostedDialog();
            }
          });
        } catch (navError) {
          debugPrint('Navigation error: $navError');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('❌ Error submitting skill exchange: $e');
      _showSnackbar('Failed to submit skill exchange: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _loadingAnimationController.stop();
        _loadingAnimationController.reset();
      }
    }
  }

  void _resetBothForms() {
    _resetForm(true); // Reset offer form
    _resetForm(false); // Reset request form
  }

  void _showSkillsPostedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Skills Posted Successfully!'),
              ],
            ),
            content: const Text(
              'Your skills have been posted successfully!\n\n'
              'You can view and manage them by:\n'
              '• Going to your Profile tab\n'
              '• Clicking "Manage My Skills"\n'
              '• Or check the Marketplace to see them live',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it!')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to profile tab (index 4 in bottom navigation)
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text('View Profile', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  Future<void> _submitToFirestore(bool isOffer) async {
    debugPrint('🔥 _submitToFirestore called for ${isOffer ? 'offer' : 'request'}');

    // Don't check _isLoading here since unified submission manages loading state
    // if (_isLoading) return;

    // Don't set loading state here since unified submission manages it
    // if (mounted) {
    //   setState(() {
    //     _isLoading = true;
    //     _loadingAnimationController.repeat();
    //   });
    // }

    try {
      // Check Firebase initialization
      debugPrint('🔥 Checking Firebase initialization...');

      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('🔐 No user logged in, attempting anonymous sign-in...');
        try {
          final credential = await FirebaseAuth.instance.signInAnonymously();
          user = credential.user;
          debugPrint('✅ Anonymous sign-in successful: ${user?.uid}');
        } catch (e) {
          debugPrint('❌ Anonymous sign-in failed: $e');
          _showSnackbar('Authentication failed. Please try logging in.', Colors.red);
          return;
        }
      }

      debugPrint('🔥 Starting Firestore submission...');
      debugPrint('User: ${user?.email ?? 'No email'} (${user?.uid ?? 'No UID'})');
      debugPrint('Type: ${isOffer ? 'offer' : 'request'}');

      // Ensure Firestore network is enabled
      await FirebaseFirestore.instance.enableNetwork();

      // Get the appropriate controllers based on tab
      final titleController = isOffer ? _offerTitleController : _requestTitleController;
      final descController = isOffer ? _offerDescController : _requestDescController;
      final durationController = isOffer ? _offerDurationController : _requestDurationController;
      final locationController = isOffer ? _offerLocationController : _requestLocationController;
      final selectedCategory = isOffer ? _offerSelectedCategory : _requestSelectedCategory;
      final selectedMode = isOffer ? _offerSelectedMode : _requestSelectedMode;
      final selectedLevel = isOffer ? _offerSelectedLevel : _requestSelectedLevel;

      final data = {
        'type': isOffer ? 'offer' : 'request',
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'category': selectedCategory,
        'duration': durationController.text.trim(),
        'location': locationController.text.trim(),
        'mode': selectedMode,
        'experienceLevel': selectedLevel,
        'userId': user?.uid,
        'userEmail': user?.email ?? 'anonymous@example.com',
        // Use both for instant visibility and server accuracy
        'timestamp': DateTime.now(),
        'serverTimestamp': FieldValue.serverTimestamp(),
        // Add exchange skill for requests (skill-for-skill exchange)
        if (!isOffer) ...{
          'exchangeSkill': _offerTitleController.text.trim(),
          'exchangeDescription': _offerDescController.text.trim(),
          'exchangeCategory': _offerSelectedCategory,
        },
      };

      debugPrint('📝 Data to submit: $data');

      // Try to save to 'skills' collection with enhanced error handling
      DocumentReference? docRef;

      try {
        // First, try to get the Firestore instance and test permissions
        final firestore = FirebaseFirestore.instance;

        // Enable offline persistence for better reliability
        await firestore.enableNetwork();

        debugPrint('🔥 Attempting to write to Firestore...');

        // Add document with timeout and retry logic
        try {
          docRef = await firestore
              .collection('skills') // Save to 'skills' collection for marketplace visibility
              .add(data)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () => throw TimeoutException('Firestore write timeout', const Duration(seconds: 15)),
              );
        } catch (e) {
          if (e.toString().contains('Target ID already exists')) {
            debugPrint('⚠️ Target ID conflict, retrying with delay...');
            await Future.delayed(const Duration(milliseconds: 500));
            docRef = await firestore.collection('skills').add(data).timeout(const Duration(seconds: 15));
          } else {
            rethrow;
          }
        }

        debugPrint('✅ Document added with ID: ${docRef.id}');
        debugPrint('📊 Skill type: ${isOffer ? 'OFFER' : 'REQUEST'}');
        debugPrint('👤 User ID: ${user?.uid}');
        debugPrint('📝 Title: ${data['title']}');

        // Send notifications in background without blocking UI
        _sendNotificationsInBackground(user!.uid, data, docRef.id, isOffer);
      } on FirebaseException catch (e) {
        debugPrint('❌ Firebase Exception: ${e.code} - ${e.message}');

        if (e.code == 'permission-denied') {
          throw Exception(
            'Permission denied: Please check Firestore security rules. You may need to enable authentication or update rules.',
          );
        } else if (e.code == 'unavailable') {
          throw Exception('Firestore is currently unavailable. Please check your internet connection and try again.');
        } else {
          throw Exception('Firebase error (${e.code}): ${e.message}');
        }
      } on TimeoutException catch (e) {
        debugPrint('❌ Timeout Exception: ${e.message}');
        throw Exception('Request timed out. Please check your internet connection and try again.');
      }

      // Don't show individual success messages since unified submission handles it
      // _showSnackbar(
      //   isOffer ? 'Skill Offer Posted Successfully!' : 'Skill Request Submitted Successfully!',
      //   Colors.green,
      // );

      // Don't reset individual forms since unified submission handles it
      // _resetForm(isOffer);

      // Don't navigate here since unified submission handles it
      // Add a small delay to show success message
      // await Future.delayed(const Duration(milliseconds: 1500));

      // Navigate to home instead of popping
      // if (mounted) {
      //   try {
      //     Navigator.of(context).pushReplacementNamed('/home');
      //   } catch (navError) {
      //     debugPrint('Navigation error: $navError');
      //     // Fallback: just pop the current screen
      //     Navigator.of(context).pop();
      //   }
      // }
    } catch (e) {
      debugPrint('❌ Error submitting to Firestore: $e');
      // Don't show snackbar here since unified submission handles it
      // _showSnackbar('Failed to submit: ${e.toString()}', Colors.red);
      rethrow; // Re-throw so unified submission can handle the error
    }
    // Don't manage loading state here since unified submission handles it
    // finally {
    //   if (mounted) {
    //     setState(() => _isLoading = false);
    //     _loadingAnimationController.stop();
    //     _loadingAnimationController.reset();
    //   }
    // }
  }

  void _resetForm(bool isOffer) {
    if (isOffer) {
      _offerTitleController.clear();
      _offerDescController.clear();
      _offerDurationController.clear();
      _offerLocationController.clear();
      if (mounted) {
        setState(() {
          _offerSelectedCategory = null;
          _offerSelectedMode = null;
          _offerSelectedLevel = null;
        });
      }
    } else {
      _requestTitleController.clear();
      _requestDescController.clear();
      _requestDurationController.clear();
      _requestLocationController.clear();
      if (mounted) {
        setState(() {
          _requestSelectedCategory = null;
          _requestSelectedMode = null;
          _requestSelectedLevel = null;
        });
      }
    }
  }

  // Send notifications in background to avoid blocking UI
  void _sendNotificationsInBackground(String posterId, Map<String, dynamic> skillData, String skillId, bool isOffer) {
    // Run in background without awaiting to avoid blocking UI
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // Create post notification directly in Firestore to avoid service conflicts
        await FirebaseFirestore.instance.collection('notifications').doc(posterId).collection('items').add({
          'title': isOffer ? 'Skill Offer Posted!' : 'Skill Request Posted!',
          'body':
              isOffer
                  ? 'Your "${skillData['title']}" skill offer is now live and visible to other users.'
                  : 'Your "${skillData['title']}" skill request is posted.',
          'type': 'skill_posted',
          'relatedId': skillId,
          'skillTitle': skillData['title'],
          'skillType': isOffer ? 'offer' : 'request',
          'category': skillData['category'],
          'senderId': posterId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        debugPrint('✅ Background notification sent successfully');
      } catch (e) {
        debugPrint('❌ Error sending background notifications: $e');
        // Don't rethrow to avoid affecting UI
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Post Skill'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading ? _buildLoadingOverlay() : _buildUnifiedForm(isDarkMode),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_loadingAnimation.value * 0.4),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    strokeWidth: 4,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Posting your skill...',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedForm(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _offerFormKey, // Use one form key for validation
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            _buildSkillExchangeBanner(isDarkMode),
            const SizedBox(height: 24),

            // I CAN TEACH SECTION
            _buildSectionHeader('I Can Teach', Icons.school, Colors.green, isDarkMode),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _offerTitleController,
              label: 'Skill Title',
              hint: 'e.g., "Python Programming"',
              icon: Icons.title,
              validator: _validateTitle,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _offerDescController,
              label: 'Description',
              hint: 'Describe what you can teach...',
              icon: Icons.description,
              validator: _validateDescription,
              isDarkMode: isDarkMode,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    value: _offerSelectedCategory,
                    label: 'Category',
                    icon: Icons.category,
                    items: _categories,
                    onChanged: (value) => setState(() => _offerSelectedCategory = value),
                    validator: (value) => _validateDropdown(value, 'Category'),
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    controller: _offerDurationController,
                    label: 'Duration',
                    hint: 'e.g., "2 hours"',
                    icon: Icons.access_time,
                    validator: _validateDuration,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    value: _offerSelectedMode,
                    label: 'Mode',
                    icon: Icons.location_on,
                    items: _modes,
                    onChanged: (value) => setState(() => _offerSelectedMode = value),
                    validator: (value) => _validateDropdown(value, 'Mode'),
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    value: _offerSelectedLevel,
                    label: 'Experience Level',

                    icon: Icons.star,
                    items: _levels,
                    onChanged: (value) => setState(() => _offerSelectedLevel = value),
                    validator: (value) => _validateDropdown(value, 'Experience Level'),
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _offerLocationController,
              label: 'Location',
              hint: 'e.g., "Online" or "New York"',
              icon: Icons.place,
              validator: _validateLocation,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 32),
            Divider(color: Colors.grey.shade300, thickness: 2),
            const SizedBox(height: 32),

            // I WANT TO LEARN SECTION
            _buildSectionHeader('I Want to Learn', Icons.lightbulb_outline, Colors.blue, isDarkMode),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _requestTitleController,
              label: 'Skill Title',
              hint: 'e.g., "Web Design"',
              icon: Icons.title,
              validator: _validateTitle,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _requestDescController,
              label: 'Description',
              hint: 'Describe what you want to learn...',
              icon: Icons.description,
              validator: _validateDescription,
              isDarkMode: isDarkMode,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    value: _requestSelectedCategory,
                    label: 'Category',

                    icon: Icons.category,
                    items: _categories,
                    onChanged: (value) => setState(() => _requestSelectedCategory = value),
                    validator: (value) => _validateDropdown(value, 'Category'),
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    controller: _requestDurationController,
                    label: 'Duration',
                    hint: 'e.g., "1 hour"',
                    icon: Icons.access_time,
                    validator: _validateDuration,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    value: _requestSelectedMode,
                    label: 'Mode',

                    icon: Icons.location_on,
                    items: _modes,
                    onChanged: (value) => setState(() => _requestSelectedMode = value),
                    validator: (value) => _validateDropdown(value, 'Mode'),
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    value: _requestSelectedLevel,
                    label: 'Experience Level',

                    icon: Icons.star,
                    items: _levels,
                    onChanged: (value) => setState(() => _requestSelectedLevel = value),
                    validator: (value) => _validateDropdown(value, 'Experience Level'),
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _requestLocationController,
              label: 'Location',
              hint: 'e.g., "Online" or "New York"',
              icon: Icons.place,
              validator: _validateLocation,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 40),

            // SINGLE SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Post Skill Exchange'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          debugPrint('🔄 Post Skill Exchange button clicked');
                          _submitSkillExchange();
                        },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillExchangeBanner(bool isDarkMode) {
    final bothComplete = _areBothFormsComplete();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              bothComplete
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(bothComplete ? Icons.check_circle : Icons.swap_horiz, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            bothComplete ? '✅ Ready to Exchange Skills!' : '🔄 Skill Barter Exchange',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            bothComplete
                ? 'Both sections completed. You can now post your skill exchange.'
                : 'Fill both sections to create a fair skill exchange. Teach something, learn something!',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  title.contains('Teach') ? 'Share your expertise with others' : 'What would you like to learn?',
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required bool isDarkMode,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
        hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
    required bool isDarkMode,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
      ),
    );
  }
}
