import 'package:flutter/material.dart';

class AdminCommunityManagementPage extends StatefulWidget {
  const AdminCommunityManagementPage({super.key});

  @override
  State<AdminCommunityManagementPage> createState() =>
      _AdminCommunityManagementPageState();
}

class _AdminCommunityManagementPageState
    extends State<AdminCommunityManagementPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _headerSlideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sample admin communities - in real app, this would come from backend
  final List<AdminCommunity> _adminCommunities = [
    AdminCommunity(
      id: '1',
      name: 'Dhanmondi',
      description:
          'A vibrant residential area known for its cultural heritage and green spaces.',
      memberCount: 1248,
      location: 'Dhaka, Bangladesh',
      image: 'assets/images/Image1.jpg',
      tags: ['Residential', 'Cultural', 'Safe'],
      createdDate: DateTime(2023, 6, 15),
      status: CommunityStatus.active,
      totalPosts: 342,
      totalEvents: 28,
      pendingRequests: 5,
    ),
    AdminCommunity(
      id: '2',
      name: 'Gulshan',
      description:
          'Upscale commercial and residential area with modern amenities.',
      memberCount: 2156,
      location: 'Dhaka, Bangladesh',
      image: 'assets/images/Image2.jpg',
      tags: ['Commercial', 'Upscale', 'Modern'],
      createdDate: DateTime(2022, 3, 10),
      status: CommunityStatus.active,
      totalPosts: 789,
      totalEvents: 45,
      pendingRequests: 12,
    ),
    AdminCommunity(
      id: '3',
      name: 'Bashundhara',
      description: 'Modern planned residential area with excellent facilities.',
      memberCount: 1876,
      location: 'Dhaka, Bangladesh',
      image: 'assets/images/Image3.jpg',
      tags: ['Modern', 'Planned', 'Facilities'],
      createdDate: DateTime(2023, 1, 20),
      status: CommunityStatus.active,
      totalPosts: 456,
      totalEvents: 32,
      pendingRequests: 8,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerSlideController,
        curve: Curves.easeOutBack,
      ),
    );
    _fadeController.forward();
    _headerSlideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerSlideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AdminCommunity> _getFilteredCommunities() {
    if (_searchQuery.isEmpty) return _adminCommunities;
    return _adminCommunities
        .where(
          (community) =>
              community.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              community.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              community.tags.any(
                (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
              ),
        )
        .toList();
  }

  void _editCommunity(AdminCommunity community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityEditPage(community: community),
      ),
    ).then((updatedCommunity) {
      if (updatedCommunity != null) {
        setState(() {
          final index = _adminCommunities.indexWhere(
            (c) => c.id == updatedCommunity.id,
          );
          if (index != -1) {
            _adminCommunities[index] = updatedCommunity;
          }
        });
      }
    });
  }

  Widget _buildStatsOverview() {
    final totalMembers = _adminCommunities.fold(
      0,
      (sum, community) => sum + community.memberCount,
    );
    final totalPosts = _adminCommunities.fold(
      0,
      (sum, community) => sum + community.totalPosts,
    );
    final totalEvents = _adminCommunities.fold(
      0,
      (sum, community) => sum + community.totalEvents,
    );
    final pendingRequests = _adminCommunities.fold(
      0,
      (sum, community) => sum + community.pendingRequests,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF71BB7B), Color(0xFF5EA968), Color(0xFF4A9B5A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF71BB7B).withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Communities Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Communities',
                  '${_adminCommunities.length}',
                  Icons.groups,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Members',
                  totalMembers.toString(),
                  Icons.people,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Posts',
                  totalPosts.toString(),
                  Icons.post_add,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending Requests',
                  pendingRequests.toString(),
                  Icons.pending_actions,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(AdminCommunity community) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with image and basic info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    community.image,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
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
                              community.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                community.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              community.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(community.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${community.memberCount} members • ${community.location}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created ${_formatDate(community.createdDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF71BB7B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              community.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5D6D7E),
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  community.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF71BB7B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71BB7B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'Posts',
                    community.totalPosts.toString(),
                    Icons.post_add,
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Expanded(
                  child: _buildMiniStat(
                    'Events',
                    community.totalEvents.toString(),
                    Icons.event,
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Expanded(
                  child: _buildMiniStat(
                    'Pending',
                    community.pendingRequests.toString(),
                    Icons.pending_actions,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _editCommunity(community),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Manage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF71BB7B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF71BB7B)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Color _getStatusColor(CommunityStatus status) {
    switch (status) {
      case CommunityStatus.active:
        return Colors.green;
      case CommunityStatus.inactive:
        return Colors.orange;
      case CommunityStatus.suspended:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCommunities = _getFilteredCommunities();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: SlideTransition(
          position: _headerSlideAnimation,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Community Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Statistics Overview - will collapse when scrolling up
          SliverToBoxAdapter(
            child: Column(
              children: [const SizedBox(height: 20), _buildStatsOverview()],
            ),
          ),

          // Sticky Search Section
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchDelegate(
              minHeight: 80,
              maxHeight: 80,
              child: Container(
                color: const Color(0xFFF8F9FA),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search your communities...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF71BB7B),
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Community List
          _buildSliverCommunityList(),
        ],
      ),
    );
  }

  Widget _buildSliverCommunityList() {
    final filteredCommunities = _getFilteredCommunities();

    if (filteredCommunities.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No communities found'
                      : 'No communities match your search',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return _buildCommunityCard(filteredCommunities[index]);
      }, childCount: filteredCommunities.length),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search your communities...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF71BB7B)),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.grey),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// Sticky Search Bar Delegate
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickySearchDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickySearchDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// Community Edit Page
class CommunityEditPage extends StatefulWidget {
  final AdminCommunity community;

  const CommunityEditPage({super.key, required this.community});

  @override
  State<CommunityEditPage> createState() => _CommunityEditPageState();
}

class _CommunityEditPageState extends State<CommunityEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late List<String> _tags;
  late CommunityStatus _status;
  String _selectedImage = '';

  final List<String> _availableImages = [
    'assets/images/Image1.jpg',
    'assets/images/Image2.jpg',
    'assets/images/Image3.jpg',
  ];

  final List<String> _availableTags = [
    'Residential',
    'Commercial',
    'Cultural',
    'Safe',
    'Modern',
    'Traditional',
    'Upscale',
    'Planned',
    'Facilities',
    'Active',
    'Peaceful',
    'Diverse',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.community.name);
    _descriptionController = TextEditingController(
      text: widget.community.description,
    );
    _locationController = TextEditingController(
      text: widget.community.location,
    );
    _tags = List.from(widget.community.tags);
    _status = widget.community.status;
    _selectedImage = widget.community.image;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveCommunity() {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedCommunity = AdminCommunity(
      id: widget.community.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      memberCount: widget.community.memberCount,
      location: _locationController.text.trim(),
      image: _selectedImage,
      tags: _tags,
      createdDate: widget.community.createdDate,
      status: _status,
      totalPosts: widget.community.totalPosts,
      totalEvents: widget.community.totalEvents,
      pendingRequests: widget.community.pendingRequests,
    );

    Navigator.pop(context, updatedCommunity);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Community updated successfully!'),
        backgroundColor: Color(0xFF71BB7B),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Image',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableImages.length,
            itemBuilder: (context, index) {
              final image = _availableImages[index];
              final isSelected = image == _selectedImage;

              return GestureDetector(
                onTap: () => setState(() => _selectedImage = image),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? const Color(0xFF71BB7B)
                              : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _availableTags.map((tag) {
                final isSelected = _tags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _tags.remove(tag);
                      } else {
                        _tags.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF71BB7B)
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF71BB7B)
                                : Colors.grey[400]!,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: Text(
          'Edit ${widget.community.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveCommunity,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSelector(),
            const SizedBox(height: 24),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Community Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            _buildTagsSection(),
            const SizedBox(height: 24),

            const Text(
              'Community Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CommunityStatus>(
                  value: _status,
                  isExpanded: true,
                  onChanged: (CommunityStatus? newValue) {
                    if (newValue != null) {
                      setState(() => _status = newValue);
                    }
                  },
                  items:
                      CommunityStatus.values.map((CommunityStatus status) {
                        return DropdownMenuItem<CommunityStatus>(
                          value: status,
                          child: Text(status.name.toUpperCase()),
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Data Models
class AdminCommunity {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String location;
  final String image;
  final List<String> tags;
  final DateTime createdDate;
  final CommunityStatus status;
  final int totalPosts;
  final int totalEvents;
  final int pendingRequests;

  AdminCommunity({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.location,
    required this.image,
    required this.tags,
    required this.createdDate,
    required this.status,
    required this.totalPosts,
    required this.totalEvents,
    required this.pendingRequests,
  });
}

enum CommunityStatus { active, inactive, suspended }
