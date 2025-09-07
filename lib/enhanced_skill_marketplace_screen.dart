import 'package:flutter/material.dart';

// Skill data model
class SkillData {
  final String id;
  final String name;
  final String skill;
  final String description;
  final double rating;
  final int reviewCount;
  final String category;
  final String location;
  final bool isOnline;
  final String avatarUrl;
  final List<String> tags;
  final DateTime lastActive;
  final bool isVerified;

  SkillData({
    required this.id,
    required this.name,
    required this.skill,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.location,
    required this.isOnline,
    required this.avatarUrl,
    required this.tags,
    required this.lastActive,
    required this.isVerified,
  });
}

// Filter options
class FilterOptions {
  String category;
  double minRating;
  bool showOnlineOnly;
  String sortBy;

  FilterOptions({this.category = 'All', this.minRating = 0.0, this.showOnlineOnly = false, this.sortBy = 'newest'});
}

class EnhancedSkillMarketplaceScreen extends StatefulWidget {
  const EnhancedSkillMarketplaceScreen({super.key});

  @override
  State<EnhancedSkillMarketplaceScreen> createState() => _EnhancedSkillMarketplaceScreenState();
}

class _EnhancedSkillMarketplaceScreenState extends State<EnhancedSkillMarketplaceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Controllers and animations
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State variables
  bool _isLoading = false;
  bool _isGridView = false;
  String _searchQuery = '';
  final FilterOptions _filters = FilterOptions();

  // Categories for filtering
  final List<String> _categories = [
    'All',
    'Technology',
    'Design',
    'Music',
    'Language',
    'Marketing',
    'Art',
    'Business',
    'Science',
  ];

  // Sort options
  final List<Map<String, String>> _sortOptions = [
    {'key': 'newest', 'label': 'Newest First'},
    {'key': 'rating', 'label': 'Highest Rated'},
    {'key': 'reviews', 'label': 'Most Reviews'},
    {'key': 'active', 'label': 'Recently Active'},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    _loadData();
  }

  void _initializeAnimations() {
    _tabController = TabController(length: 2, vsync: this);

    _fadeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _slideController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);

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

  void _initializeControllers() {
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _triggerAnimation();
      }
    });
  }

  void _triggerAnimation() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Sample data - enhanced with more fields
  List<SkillData> get _offers => [
    SkillData(
      id: '1',
      name: 'Ayesha Khan',
      skill: 'Graphic Design',
      description:
          'Expert in Figma, Adobe Creative Suite, UI/UX design. 5+ years experience working with startups and enterprises.',
      rating: 4.9,
      reviewCount: 127,
      category: 'Design',
      location: 'Karachi, Pakistan',
      isOnline: true,
      avatarUrl: '',
      tags: ['Figma', 'Adobe', 'UI/UX', 'Branding'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
      isVerified: true,
    ),
    SkillData(
      id: '2',
      name: 'Zain Ahmed',
      skill: 'Guitar Lessons',
      description:
          'Classical and modern guitar instructor. Beginner to advanced levels. Online and in-person sessions available.',
      rating: 4.7,
      reviewCount: 89,
      category: 'Music',
      location: 'Lahore, Pakistan',
      isOnline: true,
      avatarUrl: '',
      tags: ['Classical', 'Modern', 'Acoustic', 'Electric'],
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      isVerified: true,
    ),
    SkillData(
      id: '3',
      name: 'Sara Ali',
      skill: 'Python Programming',
      description:
          'Full-stack developer with expertise in Django, Flask, FastAPI. Industry experience in fintech and e-commerce.',
      rating: 4.8,
      reviewCount: 156,
      category: 'Technology',
      location: 'Islamabad, Pakistan',
      isOnline: true,
      avatarUrl: '',
      tags: ['Python', 'Django', 'Flask', 'FastAPI', 'Backend'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      isVerified: true,
    ),
    SkillData(
      id: '4',
      name: 'Omar Hassan',
      skill: 'Arabic Language',
      description:
          'Native Arabic speaker offering conversational and formal Arabic lessons. Specializing in business Arabic.',
      rating: 4.6,
      reviewCount: 73,
      category: 'Language',
      location: 'Dubai, UAE',
      isOnline: true,
      avatarUrl: '',
      tags: ['Conversational', 'Business', 'Grammar', 'Writing'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
      isVerified: false,
    ),
    SkillData(
      id: '5',
      name: 'Fatima Malik',
      skill: 'Digital Marketing',
      description:
          'Social media marketing expert with 4+ years experience. Specializing in Instagram, Facebook, and LinkedIn campaigns.',
      rating: 4.5,
      reviewCount: 92,
      category: 'Marketing',
      location: 'Karachi, Pakistan',
      isOnline: true,
      avatarUrl: '',
      tags: ['Social Media', 'Instagram', 'Facebook', 'LinkedIn', 'Campaigns'],
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
      isVerified: true,
    ),
  ];

  List<SkillData> get _requests => [
    SkillData(
      id: '6',
      name: 'Ahmed Khan',
      skill: 'Data Science',
      description:
          'Looking for help with machine learning algorithms and statistical analysis. Preparing for data science career transition.',
      rating: 4.5,
      reviewCount: 23,
      category: 'Technology',
      location: 'Karachi, Pakistan',
      isOnline: true,
      avatarUrl: '',
      tags: ['Machine Learning', 'Statistics', 'Python', 'R'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 45)),
      isVerified: false,
    ),
    SkillData(
      id: '7',
      name: 'Ali Raza',
      skill: 'English Speaking',
      description:
          'Need practice partner for IELTS preparation. Looking for conversational English practice and pronunciation help.',
      rating: 4.3,
      reviewCount: 15,
      category: 'Language',
      location: 'Lahore, Pakistan',
      isOnline: true,
      avatarUrl: '',
      tags: ['IELTS', 'Conversation', 'Pronunciation', 'Grammar'],
      lastActive: DateTime.now().subtract(const Duration(hours: 3)),
      isVerified: false,
    ),
    SkillData(
      id: '8',
      name: 'Maryam Khan',
      skill: 'Web Development',
      description:
          'Want to learn React.js and modern frontend frameworks. Have basic HTML/CSS knowledge, need guidance on JavaScript.',
      rating: 4.4,
      reviewCount: 8,
      category: 'Technology',
      location: 'Islamabad, Pakistan',
      isOnline: true,
      avatarUrl: '',
      tags: ['React', 'JavaScript', 'Frontend', 'HTML', 'CSS'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 20)),
      isVerified: false,
    ),
    SkillData(
      id: '9',
      name: 'Hassan Ali',
      skill: 'Photography',
      description:
          'Beginner seeking guidance in portrait and landscape photography. Have basic camera, need help with composition and editing.',
      rating: 4.2,
      reviewCount: 12,
      category: 'Art',
      location: 'Karachi, Pakistan',
      isOnline: false,
      avatarUrl: '',
      tags: ['Portrait', 'Landscape', 'Composition', 'Editing'],
      lastActive: DateTime.now().subtract(const Duration(hours: 5)),
      isVerified: false,
    ),
  ];

  // Get filtered and sorted data
  List<SkillData> get _filteredData {
    List<SkillData> data = _tabController.index == 0 ? _offers : _requests;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      data =
          data
              .where(
                (skill) =>
                    skill.skill.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    skill.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    skill.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    skill.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase())),
              )
              .toList();
    }

    // Apply category filter
    if (_filters.category != 'All') {
      data = data.where((skill) => skill.category == _filters.category).toList();
    }

    // Apply rating filter
    if (_filters.minRating > 0) {
      data = data.where((skill) => skill.rating >= _filters.minRating).toList();
    }

    // Apply online filter
    if (_filters.showOnlineOnly) {
      data = data.where((skill) => skill.isOnline).toList();
    }

    // Apply sorting
    switch (_filters.sortBy) {
      case 'rating':
        data.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'reviews':
        data.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case 'active':
        data.sort((a, b) => b.lastActive.compareTo(a.lastActive));
        break;
      case 'newest':
      default:
        data.sort((a, b) => b.lastActive.compareTo(a.lastActive));
        break;
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      child: Column(
        children: [
          _buildSearchAndFilterBar(isDarkMode),
          _buildTabBar(isDarkMode),
          _buildViewToggleAndSort(isDarkMode, isTablet),
          Expanded(child: _isLoading ? _buildLoadingState() : _buildContent(isDarkMode, isTablet)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search skills, names, or tags...",
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.deepPurple),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.grey.shade500),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: IconButton(
              onPressed: () => _showFilterBottomSheet(),
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              tooltip: 'Filters',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(12)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9C27B0), // Purple for offers
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Skill Offers'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800), // Orange for requests
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Skill Requests'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleAndSort(bool isDarkMode, bool isTablet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // View toggle (List/Grid)
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => setState(() => _isGridView = false),
                  icon: Icon(Icons.view_list_rounded, color: !_isGridView ? Colors.deepPurple : Colors.grey.shade500),
                  tooltip: 'List View',
                ),
                if (isTablet)
                  IconButton(
                    onPressed: () => setState(() => _isGridView = true),
                    icon: Icon(Icons.grid_view_rounded, color: _isGridView ? Colors.deepPurple : Colors.grey.shade500),
                    tooltip: 'Grid View',
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filters.sortBy,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.deepPurple),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
                dropdownColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                items:
                    _sortOptions.map((option) {
                      return DropdownMenuItem<String>(value: option['key'], child: Text(option['label']!));
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _filters.sortBy = value;
                    });
                    _triggerAnimation();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
          SizedBox(height: 16),
          Text('Loading skills...', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDarkMode, bool isTablet) {
    return TabBarView(
      controller: _tabController,
      children: [_buildSkillList(isDarkMode, isTablet), _buildSkillList(isDarkMode, isTablet)],
    );
  }

  Widget _buildSkillList(bool isDarkMode, bool isTablet) {
    final filteredData = _filteredData;

    if (filteredData.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child:
            _isGridView && isTablet
                ? _buildGridView(filteredData, isDarkMode)
                : _buildListView(filteredData, isDarkMode),
      ),
    );
  }

  Widget _buildListView(List<SkillData> data, bool isDarkMode) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), // Added bottom padding to prevent overflow
      itemCount: data.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: _buildSkillCard(data[index], isDarkMode, false),
        );
      },
    );
  }

  Widget _buildGridView(List<SkillData> data, bool isDarkMode) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), // Added bottom padding to prevent overflow
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: _buildSkillCard(data[index], isDarkMode, true),
        );
      },
    );
  }

  Widget _buildSkillCard(SkillData data, bool isDarkMode, bool isGridView) {
    return Hero(
      tag: 'skill_${data.id}',
      child: Container(
        margin: EdgeInsets.only(bottom: isGridView ? 0 : 12),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => _showSkillDetails(data),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with avatar and status
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: isGridView ? 20 : 25,
                            backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                            child:
                                data.avatarUrl.isEmpty
                                    ? Text(
                                      data.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isGridView ? 16 : 18,
                                      ),
                                    )
                                    : ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: Image.network(
                                        data.avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) => Text(
                                              data.name[0].toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.deepPurple,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isGridView ? 16 : 18,
                                              ),
                                            ),
                                      ),
                                    ),
                          ),
                          if (data.isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: isGridView ? 12 : 14,
                                height: isGridView ? 12 : 14,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data.name,
                                    style: TextStyle(
                                      fontSize: isGridView ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (data.isVerified)
                                  Icon(Icons.verified_rounded, size: isGridView ? 16 : 18, color: Colors.blue),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.star_rounded, size: isGridView ? 14 : 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${data.rating}',
                                  style: TextStyle(
                                    fontSize: isGridView ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${data.reviewCount})',
                                  style: TextStyle(
                                    fontSize: isGridView ? 11 : 12,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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

                  // Skill title
                  Text(
                    data.skill,
                    style: TextStyle(
                      fontSize: isGridView ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    data.description,
                    style: TextStyle(
                      fontSize: isGridView ? 12 : 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: isGridView ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Tags
                  if (!isGridView || data.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children:
                          data.tags.take(isGridView ? 2 : 4).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: isGridView ? 10 : 11,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                    ),

                  if (!isGridView) ...[
                    const SizedBox(height: 12),

                    // Location and last active
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _getTimeAgo(data.lastActive),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
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
            _tabController.index == 0 ? Icons.search_off_rounded : Icons.help_outline_rounded,
            size: 64,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No ${_tabController.index == 0 ? 'offers' : 'requests'} available'
                : 'No results found for "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Check back later for new ${_tabController.index == 0 ? 'skill offers' : 'skill requests'}'
                : 'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _filters.category = 'All';
                _filters.minRating = 0.0;
                _filters.showOnlineOnly = false;
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _showSkillDetails(SkillData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSkillDetailsSheet(data),
    );
  }

  Widget _buildSkillDetailsSheet(SkillData data) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                                child:
                                    data.avatarUrl.isEmpty
                                        ? Text(
                                          data.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                          ),
                                        )
                                        : ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: Image.network(
                                            data.avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) => Text(
                                                  data.name[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.deepPurple,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 24,
                                                  ),
                                                ),
                                          ),
                                        ),
                              ),
                              if (data.isOnline)
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (data.isVerified)
                                      const Icon(Icons.verified_rounded, size: 24, color: Colors.blue),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${data.rating}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${data.reviewCount} reviews)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 16,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data.location,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Skill title
                      Text(
                        data.skill,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        data.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tags
                      if (data.tags.isNotEmpty) ...[
                        Text(
                          'Skills & Expertise',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              data.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Contact button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showContactDialog(data);
                          },
                          icon: const Icon(Icons.message_rounded),
                          label: Text(_tabController.index == 0 ? 'Contact for Service' : 'Offer Help'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Report button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Report feature coming soon!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.flag_rounded,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          label: Text(
                            'Report this listing',
                            style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      ),

                      // Bottom padding for safe area
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContactDialog(SkillData data) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Contact ${data.name}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This feature will allow you to send a message to ${data.name} about their ${data.skill} skills.',
                  style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Messaging feature coming soon!',
                          style: TextStyle(color: Colors.deepPurple, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Messaging feature coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                child: const Text('Send Message'),
              ),
            ],
          ),
    );
  }

  void _showFilterBottomSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _filters.category = 'All';
                                _filters.minRating = 0.0;
                                _filters.showOnlineOnly = false;
                                _filters.sortBy = 'newest';
                              });
                            },
                            child: const Text('Reset', style: TextStyle(color: Colors.deepPurple)),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category filter
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _categories.map((category) {
                                    final isSelected = _filters.category == category;
                                    return FilterChip(
                                      label: Text(category),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setModalState(() {
                                          _filters.category = category;
                                        });
                                      },
                                      selectedColor: Colors.deepPurple.withValues(alpha: 0.2),
                                      checkmarkColor: Colors.deepPurple,
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.deepPurple
                                                : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    );
                                  }).toList(),
                            ),

                            const SizedBox(height: 24),

                            // Rating filter
                            Text(
                              'Minimum Rating',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _filters.minRating,
                                    min: 0.0,
                                    max: 5.0,
                                    divisions: 10,
                                    activeColor: Colors.deepPurple,
                                    inactiveColor: Colors.deepPurple.withValues(alpha: 0.3),
                                    onChanged: (value) {
                                      setModalState(() {
                                        _filters.minRating = value;
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, size: 16, color: Colors.deepPurple),
                                      const SizedBox(width: 4),
                                      Text(
                                        _filters.minRating.toStringAsFixed(1),
                                        style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Online only filter
                            Row(
                              children: [
                                Text(
                                  'Show Online Only',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                Switch(
                                  value: _filters.showOnlineOnly,
                                  activeColor: Colors.deepPurple,
                                  onChanged: (value) {
                                    setModalState(() {
                                      _filters.showOnlineOnly = value;
                                    });
                                  },
                                ),
                              ],
                            ),

                            // Bottom padding for safe area
                            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                          ],
                        ),
                      ),
                    ),

                    // Apply button
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              // Filters are already applied through setModalState
                            });
                            _triggerAnimation();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
