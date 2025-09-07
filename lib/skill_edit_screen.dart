import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SkillEditScreen extends StatefulWidget {
  final DocumentSnapshot skillDoc;

  const SkillEditScreen({super.key, required this.skillDoc});

  @override
  State<SkillEditScreen> createState() => _SkillEditScreenState();
}

class _SkillEditScreenState extends State<SkillEditScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _locationController;

  String? _selectedCategory;
  String? _selectedMode;
  String? _selectedLevel;
  bool _isLoading = false;

  // Options
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
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final data = widget.skillDoc.data() as Map<String, dynamic>;

    _titleController = TextEditingController(text: data['title'] ?? '');
    _descriptionController = TextEditingController(text: data['description'] ?? '');
    _durationController = TextEditingController(text: data['duration'] ?? '');
    _locationController = TextEditingController(text: data['location'] ?? '');

    _selectedCategory = data['category'];
    _selectedMode = data['mode'];
    _selectedLevel = data['experienceLevel'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final data = widget.skillDoc.data() as Map<String, dynamic>;
    final skillType = data['type'] ?? 'offer';

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Edit ${skillType == 'offer' ? 'Skill Offer' : 'Skill Request'}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      skillType == 'offer' ? Icons.volunteer_activism : Icons.help_outline,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Editing ${skillType == 'offer' ? 'Skill Offer' : 'Skill Request'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g., "Learn Python Programming"',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 20),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe the skill in detail...',
                icon: Icons.description,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 20),

              // Category
              _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: _categories,
                onChanged: (value) => setState(() => _selectedCategory = value),
                icon: Icons.category,
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 20),

              // Duration
              _buildTextField(
                controller: _durationController,
                label: 'Duration',
                hint: 'e.g., "1 hour per session"',
                icon: Icons.schedule,
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 20),

              // Location
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'e.g., "Karachi, Pakistan"',
                icon: Icons.location_on,
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 20),

              // Mode
              _buildDropdown(
                label: 'Mode',
                value: _selectedMode,
                items: _modes,
                onChanged: (value) => setState(() => _selectedMode = value),
                icon: Icons.computer,
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 20),

              // Experience Level
              _buildDropdown(
                label: 'Experience Level',
                value: _selectedLevel,
                items: _levels,
                onChanged: (value) => setState(() => _selectedLevel = value),
                icon: Icons.star,
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveChanges,
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                          : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    int maxLines = 1,
    String? Function(String?)? validator,
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
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a $label';
        }
        return null;
      },
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'duration': _durationController.text.trim(),
        'location': _locationController.text.trim(),
        'mode': _selectedMode,
        'experienceLevel': _selectedLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('skills').doc(widget.skillDoc.id).update(updateData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Skill updated successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating skill: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
